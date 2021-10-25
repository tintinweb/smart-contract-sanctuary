/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity 0.8.4;

contract Storage{
    mapping (address => uint) numbers;
    
    function set(uint number) external{
        numbers[msg.sender]=number;
    }
    
    function get(address addr) external view returns(uint){
        return numbers[addr];
    }
}