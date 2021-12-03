/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity^0.8.2;
// SPDX-License-Identifier: MIT
contract ERC20Token{
    string public tokenName = 'ShoneCoin';
    string public symbol = "SC";
    mapping(address => uint) public ledger;
    address contractOwner;
    address payable wallet;

    constructor() {
        contractOwner = msg.sender;
    }

    function buyToken() public payable{
        wallet.transfer(msg.value);
        ledger[msg.sender] ++;
    }

}