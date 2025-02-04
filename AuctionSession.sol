// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./UserManagement.sol";
import "./CommodityListing.sol";

contract AuctionSession {
    struct Auction {
        uint commodityId;
        uint startTime;
        uint endTime;
        bool isActive;
    }

    mapping(uint => Auction) public auctions;
    uint public auctionCount;
    bool public auctionActive; 

    UserManagement public userManagement;
    CommodityListing public commodityListing;

    event AuctionStarted(uint auctionId, uint commodityId, uint startTime, uint endTime);
    event AuctionEnded(uint auctionId, uint commodityId);

    constructor(address _userManagement, address _commodityListing) {
        userManagement = UserManagement(_userManagement);
        commodityListing = CommodityListing(_commodityListing);
    }

    modifier onlyAuctioneer() {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _;
    }

    function startAuction(uint _commodityId, uint _duration) external onlyAuctioneer {
        (, , uint quantity, , , ) = commodityListing.commodities(_commodityId);
        require(quantity > 0, "Invalid commodity.");
        require(!auctionActive, "Another auction is already active.");

        auctionCount++;
        auctions[auctionCount] = Auction(_commodityId, block.timestamp, block.timestamp + _duration, true);
        auctionActive = true;

        emit AuctionStarted(auctionCount, _commodityId, block.timestamp, block.timestamp + _duration);
    }

    function endAuction(uint _auctionId) external onlyAuctioneer {
        require(auctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp >= auctions[_auctionId].endTime, "Auction still running.");

        auctions[_auctionId].isActive = false;
        auctionActive = false;

        emit AuctionEnded(_auctionId, auctions[_auctionId].commodityId);
    }

    function getAuction(uint _id) external view returns (Auction memory) {
        return auctions[_id];
    }
}
