pragma solidity ^0.4.24;
// 看不到代码 合约地址:  0x32967D6c142c2F38AB39235994e2DDF11c37d590
// 根据链上的数据把结果放在这里

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

    function getFastGap() external view returns(uint256){
        return 2 minutes;
    }

    function getLongGap() external view returns(uint256){
        return 2 minutes;
    }

    function getFastExtra() external view returns(uint256){
        return 10 minutes;
    }

    function getLongExtra() external view returns(uint256){
        return 10 minutes;
    }

}