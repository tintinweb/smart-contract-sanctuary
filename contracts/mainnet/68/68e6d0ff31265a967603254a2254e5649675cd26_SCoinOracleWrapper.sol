// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

interface oracleInterface {
    function latestAnswer() external view returns (int256);
}

contract SCoinOracleWrapper is Ownable{
    
    mapping(string=>address) public  currencyToOracle;
    
    function setCurrencyOracle(string memory _currencySymbol, address _oracle) external onlyOwner() {
      require(_oracle!=address(0),'Invalid oracle address.');
      currencyToOracle[_currencySymbol]= _oracle;
    }
    
    function getPrice(string memory _currencySymbol) public  view returns(int256){
        require(currencyToOracle[_currencySymbol]!=address(0),'Invalid currency symbol.');
        address oracleAddress= currencyToOracle[_currencySymbol];
        oracleInterface currentOracleObj =  oracleInterface(oracleAddress);
        return currentOracleObj.latestAnswer();
    }
    
    function doesCurrencyExists (string memory _currencySymbol) public view returns(bool){
        return (currencyToOracle[_currencySymbol]!=address(0));
    }
    
}