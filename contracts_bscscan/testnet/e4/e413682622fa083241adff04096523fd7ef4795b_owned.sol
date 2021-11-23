/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

pragma solidity ^0.4.21;
contract owned {
    address public owner; 
    address public tworker;
    function owned() public {
     owner = msg.sender; 
    }
 
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
contract token { function transfer(address receiver, uint amount){ receiver; amount; } } 
contract workerLiquidity is owned {
    function setWorker(address _usraddress) public returns (bool success) {
        require (tworker != _usraddress);
     if(msg.sender == owner)
       {
           tworker=_usraddress;
	      return true;
	   }
	   else 
	   {
        	return false;
	   }
    }
      function getWorker() public view returns (address) {
       return tworker;
    }
    function relaseLiquidityPoolByAddress(token _ctaddress, address _usraddress,uint _uamt) public returns (bool success) {
       if(msg.sender == tworker)
       { 
	       _ctaddress.transfer(_usraddress,_uamt); 
	      return true;
	   }
	   else 
	   {
        	return false;
	   }
    } 
}