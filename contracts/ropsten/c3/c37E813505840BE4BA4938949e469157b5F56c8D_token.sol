pragma solidity ^0.5.0;

import "./DividendPayingToken.sol";


contract token is DividendPayingToken{

     
  //string internal _symbol;
  //uint256 internal _totalSupply;
 // uint256 internal _decimal;
  string internal _name;
  string private _symbol;
  
       function name() public view returns(string memory)
    {
      
      return _name;
      
    }
       function symbol() public view returns (string memory)
    {
        return _symbol;
    }

constructor() public {
    _name = 'Bitrock';
    
    _symbol = 'BRC';
   
    _totalSupply = 6000000;
    
    //100000*(10**18);
   // _decimal=18;
    
    _balances[msg.sender] = _totalSupply;
}



}