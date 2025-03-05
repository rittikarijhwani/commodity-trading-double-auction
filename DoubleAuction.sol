// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./UserManagement.sol";
import "./CommodityListing.sol";

contract DoubleAuction 
{

    struct Bid //stores information about a buyer bid
    {
        bytes32 commitment; //hash commitment of the bid (bid value + secret)
        bool revealed;      //flag indicating whether the bid has been revealed
        uint value;         //actual bid value (populated upon reveal)
        address bidder;     //address of the buyer
    }

    //maps commodity ID to bids (bid structures) made for commodity, internally mapping bidder address to bid as cannot have multiple keys with the same ID
    mapping(uint => mapping(address => Bid)) public bids; //PUT BUYER ADDRESS AND COMMODITY ID WHILE TESTING

    mapping(uint => address[]) public bidders; //mapping commodity ID to total bidder addresses
    mapping(uint => address) public highestBidder; //mapping commodity ID to highest bidder address - PUT COMMODITY ID WHILE TESTING
    mapping(uint => uint) public highestBid; //mapping commodity ID to highest bid - PUT COMMODITY ID WHILE TESTING

    mapping(address => uint[]) public buyerBids; //mapping commodity IDs to buyer who has bid on it - PUT BUYER ADDRESS AND COMMODITY ID WHILE TESTING

    //mappings to track buyer and auctioneer metrics.
    mapping(address => uint) public totalSpentByBuyer; //PUT BUYER ADDRESS WHILE TESTING
    mapping(address => uint) public auctionsWonByBuyer; //PUT BUYER ADDRESS WHILE TESTING
    mapping(address => uint) public totalVolumeByAuctioneer; //PUT AUCTIONEER ADDRESS WHILE TESTING

    //to store contract instances / external contract references
    UserManagement public userManagement;
    CommodityListing public commodityListing;

    event BidCommitted(uint indexed commodityId, address indexed bidder); //declares bid being committed
    event BidRevealed(uint indexed commodityId, address indexed bidder, uint value); //declares bid being revealed
    event AuctionFinalized(uint indexed commodityId, address winner, uint winningBid); //declares auction end

    constructor(address userManagementAddress, address commodityListingAddress) 
    { //to take contract addresses during deployment to "connect" them
        userManagement = UserManagement(userManagementAddress);
        commodityListing = CommodityListing(commodityListingAddress);
    }

    modifier onlyBuyer() 
    { //verifies role of buyer before executing attached function, same working as in other contracts
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Buyer, "Not a registered buyer.");
        _;
    }

    modifier onlyAuctioneer() 
    { //verifies role of auctioneer before executing attached function, same working as in other contracts
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _;
    }

   
    function commitBid(uint commodityId, bytes32 commitment) external onlyBuyer 
    {
        (, , uint quantity, , , bool isSold) = commodityListing.commodities(commodityId); //getting commodity details using ID

        //checking if there is an active auction, if commodity is available and if the bidder has not bid on this item before
        require(quantity > 0, "No active auction for this commodity.");
        require(!isSold, "Commodity already sold.");
        require(bids[commodityId][msg.sender].commitment == bytes32(0), "Bid already committed.");
        
        //stores bid commitment (whole bid structure) as value to commodity ID mapping - defined above
        bids[commodityId][msg.sender] = Bid(commitment, false, 0, msg.sender);
        bidders[commodityId].push(msg.sender);

        buyerBids[msg.sender].push(commodityId); //adds commodity ID to buyer's list of bids
       
        emit BidCommitted(commodityId, msg.sender);
    }

    
    function revealBid(uint commodityId, uint value, string memory secret) external onlyBuyer 
    {
        Bid storage bid = bids[commodityId][msg.sender]; //gets bid from bid mapping
        
        //checks if bid exists and has not been revealed yet
        require(bid.commitment != bytes32(0), "No bid found.");
        require(!bid.revealed, "Bid already revealed.");
        
        //checks if bid committed (in the form of hash) matches the reveal
        require(sha256(abi.encodePacked(value, secret)) == bid.commitment, "Invalid bid reveal.");
        
        //changes bid structure - updates revealed value and flips reveal flag
        bid.revealed = true;
        bid.value = value;

        if (bid.value > highestBid[commodityId]) 
        { //compares revealed bid value to the highest bid, updates highest bid and bidder accordingly
            highestBid[commodityId] = bid.value;
            highestBidder[commodityId] = bid.bidder;
        }

        emit BidRevealed(commodityId, msg.sender, value); //triggers event
    }

   
    function finalizeAuction(uint commodityId) external returns (address winner, uint winningBid)  
    { //returns highest bidder and amount for commodity

        //gets all bidders for commodity
        address[] memory bidderAddresses = bidders[commodityId];
        require(bidderAddresses.length > 0, "No bids found for this commodity.");
        
        
        for (uint i = 0; i < bidderAddresses.length; i++) 
        { //ensures all bids are revealed
            require(bids[commodityId][bidderAddresses[i]].revealed, "All bids must be revealed before finalizing the auction.");
        }
        
        //determines winner and winning bid
        winner = highestBidder[commodityId];
        winningBid = highestBid[commodityId];

        emit AuctionFinalized(commodityId, winner, winningBid); //triggers event
       
        if (winner != address(0)) 
        { //updates winner buyer statistics
            totalSpentByBuyer[winner] += winningBid;
            auctionsWonByBuyer[winner] += 1;
        }
        
        return (winner, winningBid);
    }


    function getBidsByBuyer(address buyer) external view returns (Bid[] memory) 
    { //gets all bids placed by a buyer and stores in array
        uint count = buyerBids[buyer].length; //gets number of bids placed
        Bid[] memory result = new Bid[](count); //creates array

        for (uint i = 0; i < count; i++) 
        { //populate array with bid information
            uint commodityId = buyerBids[buyer][i];
            result[i] = bids[commodityId][buyer];
        }
        return result;
    }
}
