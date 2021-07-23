/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity >=0.7.0 <0.9.0;
contract CT {

  string private _name;
  string private _symbol;

  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;
  }

 
  function name() external view returns (string memory tokenName){

    return _name;
  }

  function symbol() external view returns (string memory tokenSymbol){
    return _symbol;
  }


}