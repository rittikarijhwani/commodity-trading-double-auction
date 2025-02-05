// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;


contract UserManagement 
{
    enum Role { None, Buyer, Seller, Auctioneer } //4 types of roles
    //None = 0, Buyer = 1, Seller = 2, Auctioneer = 3

    mapping(address => Role) public userRoles; //basically dictionary where key = user address and value = role
    //stores role assigned to each user^, public because referenced in other contracts

    event UserRegistered(address indexed user, Role role); //kinda declares user acc and role to front-end and blockchain
    //indexed to make it easier to track^

    function registerUser(address _user, Role _role) external //registers a user with a role and prevents duplicates
    {
        require(userRoles[_user] == Role.None, "This user is already registered."); //checks for duplicates
        userRoles[_user] = _role; //assigns role
        emit UserRegistered(_user, _role); //triggers event
    }


    function getUserRole(address _user) external view returns (Role) //to check user role
    {
        return userRoles[_user];
    }
}
