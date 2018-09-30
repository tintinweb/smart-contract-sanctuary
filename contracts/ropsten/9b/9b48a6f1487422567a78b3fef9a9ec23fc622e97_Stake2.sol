pragma solidity ^0.4.23;

contract Stake2{
     
     event Transfer(address indexed from, address indexed to, uint256 value);
    
     function transfer(address _to, uint256 _value) public  {
  
        _value = _value * 1000000000000000000 wei;
         _to.transfer(_value);
    }
}