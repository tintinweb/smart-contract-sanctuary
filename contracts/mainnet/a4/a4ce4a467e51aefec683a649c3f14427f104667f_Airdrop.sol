/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface Token {
    function transfer(address _to, uint _amount) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
}

contract Airdrop is Ownable {
    address public tokenAddr;

    constructor(address _tokenAddr) {
        tokenAddr = _tokenAddr;
    }

    function dropTokens(address[] memory _recipients, uint256[] memory _amount) public onlyOwner returns (bool) {
        require(_recipients.length == _amount.length);

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
            require(Token(tokenAddr).transfer(_recipients[i], _amount[i]));
        }

        return true;
    }

    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
    }

    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(tokenAddr).transfer(beneficiary, Token(tokenAddr).balanceOf(owner)));
    }
}