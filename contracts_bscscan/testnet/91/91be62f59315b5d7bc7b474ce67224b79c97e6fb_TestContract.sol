/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

pragma solidity ^0.5.8;

contract TestContract{

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    // Variables
    address payable public owner;

    /***********************************|
    |            Constsructor           |
    |__________________________________*/

    /**
     * @dev constructor 
     */
    constructor() public {
	owner = msg.sender;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    function getCaller() public view returns (address) {
        return msg.sender;
    }

}