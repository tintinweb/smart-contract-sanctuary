/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Will {
    address _admin;
    mapping(address => address) _inheritor;
    mapping(address => uint) _balance;
    event Create(address indexed owner, address indexed inheritor, uint amount);
    event DeathReport(address indexed owner, address indexed inheritor, uint amount);

    // A constructor code is executed once when a contract is created
    constructor() {
        // the admin will be assigned to the contract creator
        _admin = msg.sender;
    }

    function create(address inheritor) public payable {
        require(msg.value > 0, "Amount must not be zero" );
        require(_balance[msg.sender] > 0, "Already exist" );

        _inheritor[msg.sender] = inheritor;
        _balance[msg.sender] = msg.value;
        emit Create(msg.sender, inheritor, msg.value);
    }

    function reportDeath(address owner) public {
        require(msg.sender == _admin, "unautherized");
        require(_balance[owner] > 0, "no testament");

        payable(_inheritor[owner]).transfer(_balance[owner]);
        emit DeathReport(owner, _inheritor[owner], _balance[owner]);
        _inheritor[owner] = address(0);
        _balance[owner] = 0;
    }

    function contracts(address owner) public view returns(address inheritor, uint amount) {
        return (_inheritor[owner], _balance[owner]);
    }

}