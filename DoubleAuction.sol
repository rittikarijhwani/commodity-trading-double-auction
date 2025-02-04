// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./UserManagement.sol";
import "./CommodityListing.sol";

contract DoubleAuction {
    struct Bid {
        bytes32 commitment;
        bool revealed;
        uint value;
        address bidder;
    }

    mapping(uint => mapping(address => Bid)) public bids;
    mapping(uint => address[]) public bidders;
    mapping(uint => address) public highestBidder;
    mapping(uint => uint) public highestBid;

    UserManagement public userManagement;
    CommodityListing public commodityListing;

    event BidCommitted(uint indexed commodityId, address indexed bidder);
    event BidRevealed(uint indexed commodityId, address indexed bidder, uint value);
    event AuctionFinalized(uint indexed commodityId, address winner, uint winningBid);

    constructor(address _userManagement, address _commodityListing) {
        userManagement = UserManagement(_userManagement);
        commodityListing = CommodityListing(_commodityListing);
    }

    modifier onlyBuyer() {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Buyer, "Not a registered buyer.");
        _;
    }

    modifier onlyAuctioneer() {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _;
    }

    function commitBid(uint _commodityId, bytes32 _commitment) external onlyBuyer {
        (, , uint quantity, , , bool isSold) = commodityListing.commodities(_commodityId);
        require(quantity > 0, "No active auction for this commodity.");
        require(!isSold, "Commodity already sold.");
        require(bids[_commodityId][msg.sender].commitment == bytes32(0), "Bid already committed.");

        bids[_commodityId][msg.sender] = Bid(_commitment, false, 0, msg.sender);
        bidders[_commodityId].push(msg.sender);

        emit BidCommitted(_commodityId, msg.sender);
    }

    function revealBid(uint _commodityId, uint _value, string memory _secret) external onlyBuyer {
        Bid storage bid = bids[_commodityId][msg.sender];
        require(bid.commitment != bytes32(0), "No bid found.");
        require(!bid.revealed, "Bid already revealed.");
        require(keccak256(abi.encodePacked(_value, _secret)) == bid.commitment, "Invalid bid reveal.");

        bid.revealed = true;
        bid.value = _value;

        if (bid.value > highestBid[_commodityId]) {
            highestBid[_commodityId] = bid.value;
            highestBidder[_commodityId] = bid.bidder;
        }

        emit BidRevealed(_commodityId, msg.sender, _value);
    }

    function finalizeAuction(uint _commodityId) external {
        address winner = highestBidder[_commodityId];
        uint winningBid = highestBid[_commodityId];
        emit AuctionFinalized(_commodityId, winner, winningBid);

        // Execute the transaction (this could be an additional step)
    }
}
