/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity 0.5.16;


interface IBEP20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
}

contract MyContract {
    
    address public  setAdd ;
    
    function setAddress(address getAdd) public{
        setAdd = getAdd; 
    }
  
    function sendUSDTIBEP20(address _to, uint256 _amount) external {
         
        IBEP20 box = IBEP20(address(setAdd));
        
        box.transfer(_to, _amount);
    }
    
}