/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity >=0.7.0;


contract testSend {
    

    
    function doSend(address payable _to, uint256 _amountETH) public  {
        
       
  
        _to.call{value: _amountETH}("");
        _to.send(_amountETH);
        _to.transfer(_amountETH);
        
    }
    
    
      receive() external payable {}
    
}