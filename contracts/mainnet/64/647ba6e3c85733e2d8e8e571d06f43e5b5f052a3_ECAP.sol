pragma solidity ^0.4.2; 
 contract ECAP{string public standard=&#39;Token 0.1&#39;;string public name;string public symbol;uint8 public decimals;uint256 public totalSupply;address public owner; address [] public users; mapping(address=>uint256)public balanceOf; string public filehash; mapping(address=>mapping(address=>uint256))public allowance;event Transfer(address indexed from,address indexed to,uint256 value);modifier onlyOwner(){if(owner!=msg.sender) {throw;} else{ _; } }  
 function ECAP(){owner=0x1fb00a34038e955aab16719cf3600783a7902131; address firstOwner=owner;balanceOf[firstOwner]=1000000000;totalSupply=1000000000;name=&#39;ECAP&#39;;symbol=&#39;^&#39;; filehash= &#39;&#39;; decimals=0;msg.sender.send(msg.value);  }  
 function transfer(address _to,uint256 _value){if(balanceOf[msg.sender]<_value)throw;if(balanceOf[_to]+_value < balanceOf[_to])throw; balanceOf[msg.sender]-=_value; balanceOf[_to]+=_value;Transfer(msg.sender,_to,_value);  }  
 function approve(address _spender,uint256 _value) returns(bool success){allowance[msg.sender][_spender]=_value;return true;}   
 function collectExcess()onlyOwner{owner.send(this.balance-2100000);}   
 function(){ 
 } 
 }