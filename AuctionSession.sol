// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./UserManagement.sol";
import "./CommodityListing.sol";

contract AuctionSession 
{
    struct Auction //defines an auction session
    {
        uint commodityId; //ID of commodity being auctioned
        uint startTime;
        uint endTime;
        bool isActive;
        address auctioneer; //auctioneer who started the auction
    }

    mapping(uint => Auction) public auctions; //maps an ID to an auction structure //PUT AUCTION WHILE TESTING

    uint public auctionCount; //counts total number of auctions created
    bool public auctionActive; //tracks if an auction is currently active

    mapping(address => uint) public completedAuctionsByAuctioneer; //mapping for auctioneer completed auctions count - //PUT AUCTIONEER ADDRESS WHILE TESTING

    //declares contract variables so we can interact with them
    UserManagement public userManagement;
    CommodityListing public commodityListing;

    event AuctionStarted(uint auctionId, uint commodityId, uint startTime, uint endTime); //declares auction start
    event AuctionEnded(uint auctionId, uint commodityId); //declares auction end

    constructor(address _userManagement, address _commodityListing) 
    { //takes user management and commodity listing contracts address during deployment
        userManagement = UserManagement(_userManagement);
        commodityListing = CommodityListing(_commodityListing);
    }

    modifier onlyAuctioneer() 
    { //ensures only auctioneer can call the function this modifier is attached to using user management contract
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _; //function body executes if check is valid
    }

    function startAuction(uint _commodityId, uint _duration) external onlyAuctioneer 
    {
        (, , uint quantity, , , ) = commodityListing.commodities(_commodityId); //gets commodity details using ID
        require(quantity > 0, "Invalid commodity. Commodity does not exist."); //ensures commodity exits
        require(!auctionActive, "Another auction is already active."); //ensures auction is valid

        auctionCount++; 
       
        auctions[auctionCount] = Auction(_commodityId, block.timestamp, block.timestamp + _duration, true, msg.sender); 
        //creates and stores auction in auction mapping using auction count as key with value as other auction structure variables^
        
        auctionActive = true; //for checks later

        emit AuctionStarted(auctionCount, _commodityId, block.timestamp, block.timestamp + _duration); //triggers event
    }

    function endAuction(uint _auctionId) external onlyAuctioneer 
    {
        require(auctions[_auctionId].isActive, "Auction is not active."); //ensures auction exists and is active

        auctions[_auctionId].isActive = false; //marks auction inactive
        auctionActive = false; //for checks

        //updating completed auctions count for the auctioneer who started this auction
        completedAuctionsByAuctioneer[auctions[_auctionId].auctioneer] += 1;

        emit AuctionEnded(_auctionId, auctions[_auctionId].commodityId); //triggers event
    }

    function getAuction(uint _auctionid) external view returns (Auction memory) 
    {//gives auction structure information using ID as input
        return auctions[_auctionid];
    }
}
