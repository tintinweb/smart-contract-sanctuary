/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 public number;
    address public msgsender;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        msgsender = msg.sender;
    }

    function test0(uint256 num) public{
        store(num);
    }

    function test1(address b, uint256 num) public {
        b.delegatecall(abi.encodeWithSignature("testb1(uint256)", num));
    }

    function test2(address b, uint256 num) public {
        b.delegatecall(abi.encodeWithSignature("testb2(address, uint256)", this, num));
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (address, uint256){
        return (msgsender, number);
    }
}