// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AgriculturalAuction {
    address public admin;
    
    enum Role { None, Farmer, Buyer }
    enum AuctionStatus { Inactive, Active, Completed }
    
    struct User {
        address userAddress;
        Role role;
        bool isRegistered;
    }
    
    struct Ask {
        address farmer;
        uint256 quantity;
        uint256 price;
        uint256 timestamp;
    }
    
    struct Bid {
        address buyer;
        uint256 quantity;
        uint256 price;
        uint256 timestamp;
    }
    
    struct MatchedTrade {
        address farmer;
        address buyer;
        uint256 quantity;
        uint256 price;
        uint256 timestamp;
    }
    
    struct Auction {
        string id;
        string commodityName;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 startTime;
        uint256 endTime;
        AuctionStatus status;
        Ask[] asks;
        Bid[] bids;
        MatchedTrade[] matchedTrades;
    }
    
    mapping(address => User) public users;
    mapping(string => Auction) public auctions;
    string[] public auctionIds;
    string public currentAuctionId;
    
    event UserRegistered(address user, Role role);
    event AuctionCreated(string auctionId, string commodityName);
    event AskSubmitted(string auctionId, address farmer, uint256 quantity, uint256 price);
    event BidSubmitted(string auctionId, address buyer, uint256 quantity, uint256 price);
    event AuctionEnded(string auctionId);
    event TradeMatched(string auctionId, address farmer, address buyer, uint256 quantity, uint256 price);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User not registered");
        _;
    }
    
    modifier onlyFarmer() {
        require(users[msg.sender].role == Role.Farmer, "Only farmers can perform this action");
        _;
    }
    
    modifier onlyBuyer() {
        require(users[msg.sender].role == Role.Buyer, "Only buyers can perform this action");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function registerUser(Role role) public {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(role == Role.Farmer || role == Role.Buyer, "Invalid role");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            role: role,
            isRegistered: true
        });
        
        emit UserRegistered(msg.sender, role);
    }
    
    function createAuction(
        string memory auctionId,
        string memory commodityName,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 durationInMinutes
    ) public onlyAdmin {
        require(bytes(currentAuctionId).length == 0 || auctions[currentAuctionId].status != AuctionStatus.Active, "An auction is already active");
        
        auctions[auctionId] = Auction({
            id: auctionId,
            commodityName: commodityName,
            minPrice: minPrice,
            maxPrice: maxPrice,
            startTime: block.timestamp,
            endTime: block.timestamp + (durationInMinutes * 1 minutes),
            status: AuctionStatus.Active,
            asks: new Ask[](0),
            bids: new Bid[](0),
            matchedTrades: new MatchedTrade[](0)
        });
        
        auctionIds.push(auctionId);
        currentAuctionId = auctionId;
        
        emit AuctionCreated(auctionId, commodityName);
    }
    
    function submitAsk(uint256 quantity, uint256 price) public onlyRegistered onlyFarmer {
        require(bytes(currentAuctionId).length > 0, "No active auction");
        require(auctions[currentAuctionId].status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auctions[currentAuctionId].endTime, "Auction has ended");
        require(price >= auctions[currentAuctionId].minPrice && price <= auctions[currentAuctionId].maxPrice, "Price out of range");
        require(quantity > 0, "Quantity must be positive");
        
        // Check if farmer has already submitted an ask in this auction
        for(uint i = 0; i < auctions[currentAuctionId].asks.length; i++) {
            require(auctions[currentAuctionId].asks[i].farmer != msg.sender, "You already submitted an ask");
        }
        
        auctions[currentAuctionId].asks.push(Ask({
            farmer: msg.sender,
            quantity: quantity,
            price: price,
            timestamp: block.timestamp
        }));
        
        emit AskSubmitted(currentAuctionId, msg.sender, quantity, price);
    }
    
    function submitBid(uint256 quantity, uint256 price) public onlyRegistered onlyBuyer {
        require(bytes(currentAuctionId).length > 0, "No active auction");
        require(auctions[currentAuctionId].status == AuctionStatus.Active, "Auction not active");
        require(block.timestamp < auctions[currentAuctionId].endTime, "Auction has ended");
        require(price >= auctions[currentAuctionId].minPrice && price <= auctions[currentAuctionId].maxPrice, "Price out of range");
        require(quantity > 0, "Quantity must be positive");
        
        // Check if buyer has already submitted a bid in this auction
        for(uint i = 0; i < auctions[currentAuctionId].bids.length; i++) {
            require(auctions[currentAuctionId].bids[i].buyer != msg.sender, "You already submitted a bid");
        }
        
        auctions[currentAuctionId].bids.push(Bid({
            buyer: msg.sender,
            quantity: quantity,
            price: price,
            timestamp: block.timestamp
        }));
        
        emit BidSubmitted(currentAuctionId, msg.sender, quantity, price);
    }
    
    function endAuction() public onlyAdmin {
        require(bytes(currentAuctionId).length > 0, "No active auction");
        require(auctions[currentAuctionId].status == AuctionStatus.Active, "Auction not active");
        
        auctions[currentAuctionId].status = AuctionStatus.Completed;
        
        // Match bids and asks
        matchBidsAndAsks(currentAuctionId);
        
        // Reset current auction id
        currentAuctionId = "";
        
        emit AuctionEnded(currentAuctionId);
    }
    
    function matchBidsAndAsks(string memory auctionId) private {
        // Create arrays in memory to work with
        Bid[] memory bidsArray = auctions[auctionId].bids;
        Ask[] memory asksArray = auctions[auctionId].asks;
        
        // Sort bids by price (descending) using a simple bubble sort
        for (uint i = 0; i < bidsArray.length; i++) {
            for (uint j = 0; j < bidsArray.length - i - 1; j++) {
                if (bidsArray[j].price < bidsArray[j + 1].price) {
                    Bid memory temp = bidsArray[j];
                    bidsArray[j] = bidsArray[j + 1];
                    bidsArray[j + 1] = temp;
                }
            }
        }
        
        // Arrays to track which bids and asks have been matched
        bool[] memory bidMatched = new bool[](bidsArray.length);
        bool[] memory askMatched = new bool[](asksArray.length);
        
        // Sort asks by price (ascending) and then by timestamp for same prices
        Ask[] memory sortedAsks = new Ask[](asksArray.length);
        for (uint i = 0; i < asksArray.length; i++) {
            sortedAsks[i] = asksArray[i];
        }
        
        // Sort asks by price (ascending)
        for (uint i = 0; i < sortedAsks.length; i++) {
            for (uint j = 0; j < sortedAsks.length - i - 1; j++) {
                if (sortedAsks[j].price > sortedAsks[j + 1].price) {
                    Ask memory temp = sortedAsks[j];
                    sortedAsks[j] = sortedAsks[j + 1];
                    sortedAsks[j + 1] = temp;
                }
            }
        }
        
        // For asks with same price, sort by timestamp (FIFO)
        for (uint i = 0; i < sortedAsks.length; i++) {
            for (uint j = 0; j < sortedAsks.length - i - 1; j++) {
                if (sortedAsks[j].price == sortedAsks[j + 1].price && 
                    sortedAsks[j].timestamp > sortedAsks[j + 1].timestamp) {
                    Ask memory temp = sortedAsks[j];
                    sortedAsks[j] = sortedAsks[j + 1];
                    sortedAsks[j + 1] = temp;
                }
            }
        }
        
        // Perform matching
        for (uint i = 0; i < bidsArray.length; i++) {
            if (bidMatched[i]) continue;
            
            Bid memory bid = bidsArray[i];
            
            for (uint j = 0; j < sortedAsks.length; j++) {
                if (askMatched[j]) continue;
                
                Ask memory ask = sortedAsks[j];
                
                // Check if bid price >= ask price AND quantities match exactly
                if (bid.price >= ask.price && bid.quantity == ask.quantity) {
                    // Match found! Add to matchedTrades array
                    auctions[auctionId].matchedTrades.push(MatchedTrade({
                        farmer: ask.farmer,
                        buyer: bid.buyer,
                        quantity: bid.quantity,
                        price: (bid.price + ask.price) / 2, // Execute at the average price
                        timestamp: block.timestamp
                    }));
                    
                    bidMatched[i] = true;
                    askMatched[j] = true;
                    
                    emit TradeMatched(auctionId, ask.farmer, bid.buyer, bid.quantity, (bid.price + ask.price) / 2);
                    break;
                }
            }
        }
    }
    
    function getAuctionDetails(string memory auctionId) public view returns (
        string memory commodityName,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 startTime,
        uint256 endTime,
        AuctionStatus status,
        uint256 asksCount,
        uint256 bidsCount,
        uint256 matchedTradesCount
    ) {
        Auction storage auction = auctions[auctionId];
        return (
            auction.commodityName,
            auction.minPrice,
            auction.maxPrice,
            auction.startTime,
            auction.endTime,
            auction.status,
            auction.asks.length,
            auction.bids.length,
            auction.matchedTrades.length
        );
    }
    
    function getAuctionHistory() public view returns (string[] memory) {
        return auctionIds;
    }
    
    function getUserRole(address userAddress) public view returns (Role) {
        return users[userAddress].role;
    }
}
