/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.5.16;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Test {

    uint256 number;
    uint256 public infinity = uint256(-1);
    event setNumber(uint indexed n,bytes32 indexed hn,uint indexed bn);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function getCallData(address[] memory addrArray,uint[] memory uArray) public{
        
    }
    
    function setMod() public{
        bytes32 bh = blockhash(block.number - 1);
        number = uint(bh)%100;
        emit setNumber(number,bh,uint(bh));
    }
    
    function getBlockNumber() view public returns(uint){
        return block.number;
    }
    
    function getBlockHash() view public returns(bytes32){
        return blockhash(block.number - 1);
    }
}