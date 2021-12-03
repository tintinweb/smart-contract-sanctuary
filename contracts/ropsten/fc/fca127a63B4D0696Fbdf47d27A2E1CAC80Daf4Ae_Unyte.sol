/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//SPDX-License-Identifier :MIT

pragma solidity >=0.5.0 <=0.7.0;

contract Unyte {

    address public minter;
    mapping (address => uint ) public balances;
    event Sent (address to, address from, uint amount);

    constructor () public {
        minter = msg.sender;
    }

    function mint ( address receiver, uint amount) public {
    require (minter == msg.sender );
    require( amount < 1e60);
    balances [receiver] += amount;
    }
    
    function send ( address receiver, uint amount) public {
    require (amount <= balances [msg.sender], "IN Funds");
    balances [msg.sender] -= amount;
    balances [receiver] += amount;
    emit Sent (msg.sender,receiver, amount);


    }



}