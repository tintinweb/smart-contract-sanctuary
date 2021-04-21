/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity >=0.6.0 <0.8.0;

contract LoanNFT {

     // Token name
    string private _name;

   // Token symbol
    string private _symbol;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function getName() public view returns(string memory) {
        return _name;
    }
    
    function getSymbol() public view returns(string memory) {
        return _symbol;
    }
    
    function setName(string memory name_) public {
        _name = name_;
    }
    
    function setSymbol(string memory symbol_) public {
        _symbol = symbol_;
    }
}