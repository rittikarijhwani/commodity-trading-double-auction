// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

//web3.utils.keccak256(web3.utils.encodePacked("5", "mysecret"));


import "./UserManagement.sol";
import "./CommodityListing.sol";

contract DoubleAuction 
{
    struct Bid //stores information about a buyer bid
    {
        bytes32 commitment;
        bool revealed;
        uint value;
        address bidder;
    }

    //maps commodity ID to bids (bid structures) made for commodity, internally mapping bidder address to bid as cannot have multiple keys with the same ID
    mapping(uint => mapping(address => Bid)) public bids;  

    mapping(uint => address[]) public bidders; //mapping commodity ID to total bidder addresses
    mapping(uint => address) public highestBidder; //mapping commodity ID to highest bidder address
    mapping(uint => uint) public highestBid; //mapping commodity ID to highest bid

    //to store contract instances / external contract references
    UserManagement public userManagement;
    CommodityListing public commodityListing;

    event BidCommitted(uint indexed commodityId, address indexed bidder); //declares bid being committed
    event BidRevealed(uint indexed commodityId, address indexed bidder, uint value); //declares bid being revealed
    event AuctionFinalized(uint indexed commodityId, address winner, uint winningBid); //declares auction end

    constructor(address _userManagement, address _commodityListing) 
    { //to take contract addresses during deployment to "connect" them
        userManagement = UserManagement(_userManagement);
        commodityListing = CommodityListing(_commodityListing);
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

    function commitBid(uint _commodityId, bytes32 _commitment) external onlyBuyer 
    {
        (, , uint quantity, , , bool isSold) = commodityListing.commodities(_commodityId); //getting commodity details using ID

        //checking if there is an active auction, if commodity is available and if the bidder has not bid on this item before
        require(quantity > 0, "No active auction for this commodity.");
        require(!isSold, "Commodity already sold.");
        require(bids[_commodityId][msg.sender].commitment == bytes32(0), "Bid already committed.");

        //stores bid commitment (whole bid structure) as value to commodity ID mapping - defined above
        bids[_commodityId][msg.sender] = Bid(_commitment, false, 0, msg.sender); //value is 0 as we don't know it until it is revealed
        bidders[_commodityId].push(msg.sender); //adds bidder address to list of bidders mapped to commodity ID

        emit BidCommitted(_commodityId, msg.sender); //triggers event
    }

    function revealBid(uint _commodityId, uint _value, string memory _secret) external onlyBuyer 
    {
        Bid storage bid = bids[_commodityId][msg.sender]; //gets bid from bid mapping

        //checks if bid exists and has not been revealed yet
        require(bid.commitment != bytes32(0), "No bid found.");
        require(!bid.revealed, "Bid already revealed.");

        //checks if bid committed (in the form of hash) matches the reveal
        require(keccak256(abi.encodePacked(_value, _secret)) == bid.commitment, "Invalid bid reveal.");

        //changes bid structure - updates revealed value and flips reveal flag
        bid.revealed = true;
        bid.value = _value;

        if (bid.value > highestBid[_commodityId]) 
        { //compares revealed bid value to the highest bid, updates highest bid and bidder accordingly
            highestBid[_commodityId] = bid.value;
            highestBidder[_commodityId] = bid.bidder;
        }

        emit BidRevealed(_commodityId, msg.sender, _value); //triggers event
    }

    function finalizeAuction(uint _commodityId) external 
    {
        //retrieves bid winner address and amount
        address winner = highestBidder[_commodityId];
        uint winningBid = highestBid[_commodityId];

        emit AuctionFinalized(_commodityId, winner, winningBid); //triggers event

        //execute the transaction - exchange goods and money
    }
}
