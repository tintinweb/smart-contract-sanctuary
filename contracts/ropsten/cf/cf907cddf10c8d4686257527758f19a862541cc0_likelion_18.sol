/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//noh younwoo

pragma solidity 0.8.0;

contract likelion_18 {
    
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    uint a = 100;
    uint b = 200;
    uint c = 500;
    uint d = 1000;

    function withdraw1() public {
        for(d=0; d<=10; d++) {
        owner = msg.sender;
        }
    }
    
    function withrdraw2() public {
        
    }
}