pragma solidity ^0.4.24;


contract F3DexternalSettings {

    
    constructor() 
        public
    {
        //constructor does nothing.
    }
    
    function()
        public
        payable
    {
        revert(); 
    }

    function getFastGap() external pure returns(uint256){
        return 2 minutes;
    }

    function getLongGap() external pure returns(uint256){
        return 2 minutes;
    }

    function getFastExtra() external pure returns(uint256){
        return 10 minutes;
    }

    function getLongExtra() external pure returns(uint256){
        return 10 minutes;
    }

}