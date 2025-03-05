// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract HashGenerator 
{
    function generateHash(uint256 _value, string memory _secret) public pure returns (bytes32) 
    {
        return sha256(abi.encodePacked(_value, _secret));
    }
}
