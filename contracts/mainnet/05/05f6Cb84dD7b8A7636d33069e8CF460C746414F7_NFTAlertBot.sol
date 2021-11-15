// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title NFTAlertBot
 * NFTAlertBot - a payment contract for NFTAlert Bot
 */
contract NFTAlertBot {

    address public owner;
    uint256 public price;

    constructor() {
        owner = msg.sender;
    }

    struct Account {
        string guild;
        string collection;
        bool active;
    }

    modifier onlyOwner() {
      require(owner == msg.sender, "Function can only be invoked by owner.");
      _;
    }

    mapping(string => Account) public accounts;

    function _setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _updateAccount(string memory _id, string memory _guild, string memory _collection, bool _active) public onlyOwner {
        accounts[_id].collection = _collection;
        accounts[_id].guild = _guild;
        accounts[_id].active = _active;
	}

    function getAccount(string memory _id) public view returns (string memory guild, string memory collection, bool active) {
		return (accounts[_id].guild, accounts[_id].collection, accounts[_id].active);
	}

    function activate(string memory _id, string memory _guild, string memory _collection) public payable {
        require(price <= msg.value, "Ether value sent is not correct");
        accounts[_id] = Account(_collection, _guild, true);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}

