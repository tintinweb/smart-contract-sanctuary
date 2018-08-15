pragma solidity ^0.4.24;

contract WhiteList{
    
    // mapping of exchange groups with address and their token values
    // address -> exchange group address
    // uint -> value of token against 1 ether
    mapping (address => uint) exchangeGroupValue;
    
    /*
        Function to validate if exchange group is valid or not
        Params @_exchangeGroupKeys: array of addresses values with desired exchange Group names
        Returns: True if all of the groups are available, False otherwise
    */
    function validateInvestmentGroups(address[] _exchangeGroupKeys) 
        public 
        view
        returns(bool) {
        for(uint i=0; i<_exchangeGroupKeys.length; ++i){
            if(exchangeGroupValue[_exchangeGroupKeys[i]] == 0){
                return false;
            }
        }
        return true;
    }
    
    /*
        Function to set values of exchange groups and address for exchange Group Keys/names
        Params @_exchangeGroupAddress: address of the exchange group
        Params @_exchangeGroupValue: value of tokens against a crypto currency
    */
    function setExchangeGroup(address _exchangeGroupAddress, uint _exchangeGroupValue) 
        public {
        require(_exchangeGroupValue != 0);
        exchangeGroupValue[_exchangeGroupAddress] = _exchangeGroupValue;
    }
    
    /*
        Function to get value of tokens for desired exchange keys
        Params @_exchangeGroupKey: array of desired exchange keys
        Returns: Total value of token of exchange group for an ether
     */
    function getRespectiveValue(address _exchangeGroupKey) 
        public
        view
        returns(uint) {
        return exchangeGroupValue[_exchangeGroupKey];
    }
}