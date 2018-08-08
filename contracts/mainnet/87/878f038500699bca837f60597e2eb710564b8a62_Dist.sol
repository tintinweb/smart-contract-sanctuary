// version 0.8

pragma solidity ^0.4.15;

//abstract of token interface
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Dist{

    // public    
    address public owner;
    address public tokenAddress; // 0x6781a0F84c7E9e846DCb84A9a5bd49333067b104 ZAP token mainnet address
    uint public unlockTime;

    // internal
    ERC20Basic token;

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    // 01/01/2019 @ 12:00am (UTC) = 1546300800
    // ex.
    // "0xca35b7d915458ef540ade6068dfe2f44e8fa733c",1514411898,"0x6781a0F84c7E9e846DCb84A9a5bd49333067b104"
    
    function Dist(address _owner, uint _unlockTime, address _tokenAddress){
        owner = _owner;
        tokenAddress = _tokenAddress;
        token = ERC20Basic(_tokenAddress);
        unlockTime = _unlockTime;
    }

    function balance() constant returns(uint _balance){
    
        return token.balanceOf(this);
    }

    function isLocked() constant returns (bool) {

        return (now < unlockTime);       
    }

    function withdraw() onlyOwner {

        if(!isLocked()){        
            token.transfer(owner, balance());
        }
    }

}