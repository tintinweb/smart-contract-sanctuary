/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity >= 0.6.0;


contract Pool {

    uint256 public base_timestamp ;

    constructor() public {
    }


    function swap () public payable  {

        require ( base_timestamp < block.timestamp, "Not started.");

    }
    
    function setBaseTimestamp(uint256 t) public {
        base_timestamp = t;
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    } 




}