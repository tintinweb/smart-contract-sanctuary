/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.4.24;

contract WinnerList{
    address owner;
    struct Richman{
        address who;
        uint balance;
    }
    
    function note(address _addr, uint _value) public{
        Richman rm;
        rm.who = _addr;
        rm.balance = _value;
    }
}

contract Millionaire{
    mapping(address => uint256) public balances;
    WinnerList public wlist;
    
    constructor(address _addr) public{
	    wlist = WinnerList(_addr);
	}
    
    function play(uint bet) public returns(bool){
        balances[tx.origin] = 0;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.number)))+uint256(keccak256(abi.encodePacked(block.timestamp)));
        uint256 lucky = uint256(keccak256(abi.encodePacked(seed))) % 100;
        if(lucky == bet){
            balances[tx.origin] = 1000000;
            wlist.note(tx.origin,balances[tx.origin]);
            return true;
        }
        return false;
    }
}