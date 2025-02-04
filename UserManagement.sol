// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;


contract UserManagement {
    enum Role { None, Buyer, Seller, Auctioneer }


    mapping(address => Role) public userRoles;


    event UserRegistered(address indexed user, Role role);


    function registerUser(address _user, Role _role) external {
        require(userRoles[_user] == Role.None, "User already registered.");
        userRoles[_user] = _role;
        emit UserRegistered(_user, _role);
    }


    function getUserRole(address _user) external view returns (Role) {
        return userRoles[_user];
    }
}
