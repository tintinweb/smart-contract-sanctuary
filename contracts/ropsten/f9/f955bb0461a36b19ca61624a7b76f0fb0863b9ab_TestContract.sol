/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity >=0.7.0;


contract TestContract {
    
    function pass() external pure returns (bool) { return true; }
    
    function fail() external pure { revert("Fail"); }
    
    function proxyCall(address _to, bytes calldata _calldata, uint _val) external payable returns (bool, bytes memory) {
        return payable(_to).call{value: _val}(_calldata);
    }
    
    function spendGas(uint _maxAmount) external view {
        require(_maxAmount > 23e3, 'Spend more gas!');
        _maxAmount -= 22000;
        uint initialGas = gasleft();
        while (true) {
            if (initialGas-gasleft() >= _maxAmount) {
                break;
            }
        }
    }
    
}