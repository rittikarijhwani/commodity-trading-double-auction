// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;


import "./UserManagement.sol";


contract CommodityListing {
    struct Commodity {
        uint id;
        string name;
        uint quantity;
        uint basePrice;
        address seller;
        bool isSold;
    }


    mapping(uint => Commodity) public commodities;
    uint public commodityCount;
    UserManagement public userManagement;


    event CommodityListed(uint indexed id, string name, uint quantity, uint basePrice, address seller);
    event CommoditySold(uint indexed id, address buyer);


    constructor(address _userManagement) {
        userManagement = UserManagement(_userManagement);
    }


    modifier onlySeller() {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Seller, "Not a registered seller.");
        _;
    }


    modifier onlyAuctioneer() {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _;
    }


    function listCommodity(string memory _name, uint _quantity, uint _basePrice) external onlySeller {
        commodityCount++;
        commodities[commodityCount] = Commodity(commodityCount, _name, _quantity, _basePrice, msg.sender, false);
        emit CommodityListed(commodityCount, _name, _quantity, _basePrice, msg.sender);
    }


    function markAsSold(uint _commodityId) external onlyAuctioneer {
        require(commodities[_commodityId].id != 0, "Commodity does not exist.");
        require(!commodities[_commodityId].isSold, "Commodity already sold.");


        commodities[_commodityId].isSold = true;
        emit CommoditySold(_commodityId, msg.sender);
    }


    function getCommodity(uint _id) external view returns (Commodity memory) {
        require(commodities[_id].id != 0, "Invalid commodity Id.");
        return commodities[_id];
    }
}
