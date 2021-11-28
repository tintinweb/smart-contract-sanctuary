/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Will {
    address _admin; // address ของผู้เขียนพินัยกรรม
    mapping(address => address) _heirs; // addresses ของผู้รับมรดก
    mapping(address => uint) _balances; // ยอดเงินที่ admin (ผู้เขียนพินัยกรรม) จะให้ผู้รับมรดก

    event Create(address indexed owner, address indexed heir, uint amount);
    event Deceased(address indexed owner, address indexed heir, uint amount);

    constructor() {
        _admin = msg.sender;
    }

    function create(address heir) public payable {
        require(msg.value > 0, "amount must not be zero");
        require(_balances[msg.sender] <= 0, "already axists. the will can be created just once.");

        _heirs[msg.sender] = heir;
        _balances[msg.sender] = msg.value;

        emit Create(msg.sender, heir, msg.value);
    }

    function deceased(address owner) public {
        require(msg.sender == _admin, "unauthorised ");
        require(_balances[owner] > 0, "no will found");

        emit Deceased(owner, _heirs[owner], _balances[owner]);

        payable(_heirs[owner]).transfer(_balances[owner]);

        _heirs[owner] = address(0); // Clear address
        _balances[owner] = 0;
    }

    function viewContract(address owner) public view returns(address heir, uint balance) {
        return (_heirs[owner], _balances[owner]);
    }
}