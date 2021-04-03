/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    //data-type
    int num;
    uint256 number;
    string name;
    bool boolean;
    mapping(uint256 => string) a; //like dictionary
    address adr; 
    mapping(uint256 => address) nft; // number 1 => addres 0x... core code of NFT
    mapping(address => uint256) balance; //address balance
    
    //constructor : be called autometically when deploy
    uint256 s;
    constructor(uint256 init) public{
       s = init;
    }
    
    //function 
    function add(uint256 vol) public {
        s += vol;
    }

}