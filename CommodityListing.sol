// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./UserManagement.sol";

contract CommodityListing 
{
    struct Commodity 
    {
        uint id; //commodity ID
        string name; //commodity name, set by seller
        uint quantity; //available amount, set by seller
        uint basePrice; //minimum price, set by seller
        address seller; //seller address
        bool isSold; //to check if it has been sold
    }

    //PUT COMMODITY ID WHILE TESTING
    mapping(uint => Commodity) public commodities; //stores commodity as dictionary, using ID as key

    uint public commodityCount; //tracks total number of commodities listed

    UserManagement public userManagement; //used to store an instance of user management contract to verify roles

    event CommodityListed(uint indexed id, string name, uint quantity, uint basePrice, address seller); //when seller lists a commodity

    event CommoditySold(uint indexed id, address auctioneer); //when auctioneer marks commodity as sold

    //mappings for seller sales tracking (dialog boxes content)
    mapping(address => uint) public totalSalesBySeller; //PUT SELLER ADDRESS WHILE TESTING
    mapping(address => uint) public itemsSoldBySeller; //PUT SELLER ADDRESS WHILE TESTING
    mapping(address => uint[]) public sellerListings; //PUT SELLER ADDRESS WHILE TESTING

    constructor(address _userManagement) 
    {//to get address of deployed user management contract when this contract is deployed (to connect them basically)
        userManagement = UserManagement(_userManagement);
    }

    modifier onlySeller() //verifies using user management contract if function caller is a seller
    {
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Seller, "Not a registered seller."); //does not execute function body
        _; //executes function body after role check is complete (if the caller is a registered seller)
    }

    //modifiers are basically attached to other functions to make sure only authorised roles can call those functions

    modifier onlyAuctioneer() //verifies using user management contract if function caller is an auctioneer
    { //same working as onlySeller
        require(userManagement.getUserRole(msg.sender) == UserManagement.Role.Auctioneer, "Not an auctioneer.");
        _;
    }

    function listCommodity(string memory _name, uint _quantity, uint _basePrice) external onlySeller 
    { //first ensures caller is seller
        commodityCount++; 
        commodities[commodityCount] = Commodity(commodityCount, _name, _quantity, _basePrice, msg.sender, false); 
        //lists commodity (stores in commodity mapping) by putting ID as key and rest of the features as values^, commodity count is used as ID
        
        sellerListings[msg.sender].push(commodityCount); //adding to listings for front-end
        
        emit CommodityListed(commodityCount, _name, _quantity, _basePrice, msg.sender); //triggers event
    }

    function markAsSold(uint _commodityId, uint _salePrice) external onlyAuctioneer 
    { //first ensures caller is auctioneer
        require(commodities[_commodityId].id != 0, "Commodity does not exist."); //checks if commodity exists by checking key in mapping(dictionary)
        require(!commodities[_commodityId].isSold, "Commodity already sold."); //checks if commodity is already sold

        commodities[_commodityId].isSold = true; //marks as sold if commodity exists and is not sold yet

        //update seller totals automatically
        totalSalesBySeller[commodities[_commodityId].seller] += _salePrice;
        itemsSoldBySeller[commodities[_commodityId].seller] += 1;

        emit CommoditySold(_commodityId, msg.sender); //triggers event
    }

    function getCommodity(uint _id) external view returns (Commodity memory) 
    { //to get commodity information (structure)
        require(commodities[_id].id != 0, "Invalid commodity Id."); //checks for existance
        return commodities[_id]; //returns values of key (ID)
    }
    
    //get all listings for a seller using sellerListings mapping - for front end
    function getListingsBySeller(address _seller) external view returns (Commodity[] memory) {
        uint[] memory listingIds = sellerListings[_seller]; //gets listing IDs of listings made by a seller
        Commodity[] memory listings = new Commodity[](listingIds.length); //stores listings
        for (uint i = 0; i < listingIds.length; i++) //gets commodity structure for each listing, stores in listing array
        {
            listings[i] = commodities[listingIds[i]];
        }
        return listings; //stored like Commodity("Wheat",100,5000), Commodity("Corn", 5, 200)
    }
}
