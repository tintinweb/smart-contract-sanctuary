pragma solidity ^0.4.17;

contract ENS {
    address public owner;
    mapping(string=>address)  ensmap;
    mapping(address=>string)  addressmap;
    
    constructor() public {
        owner = msg.sender;
    }
     //设置域名
     function setEns(string newEns,address addr) onlyOwner public{
          ensmap[newEns] = addr;
          addressmap[addr] = newEns;
     }
     
    //通过ens获取0x地址
     function getAddress(string aens) view public returns(address) {
           return ensmap[aens];
     }
	 //通过address获取域名
     function getEns(address addr) view public returns(string) {
           return addressmap[addr];
     }
    //设置拥有者
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

     //仅仅拥有者 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
}