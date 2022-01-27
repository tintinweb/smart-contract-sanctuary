/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// long sang contract tua laek
contract MyContract {

    // // ni yarm tua pae
    // bool status = false; // ni yarm pen boolean
    // string public name = "Yothin Boubpha";  // ni yarm pen string
    // int amount = 500; // ni yarm kep tua lek jum nuan tem beab tid buak tid lop dai
    // uint private _balance = 1000; // ni yarm kep tua lek jum nuan tem dai sa phc kha buak thao nun

    // khong sang kan ni yarm tua pae / type, access_modifier, name

    // private
    string _name;
    uint _balance;

    constructor (string memory name, uint balance){
        // kam nod kha lerm ton baeb ngeuan khai
        require(balance>=500, "blance greater zero (money>=500)");
        _name = name;
        _balance = balance;
    }


    // // pen function deung kha ork ma
    function getBalance() public view returns (uint balance) {
        return _balance;
    }

    // function deposite(uint amount) public   {
    //     _balance+=amount;
    // }

}