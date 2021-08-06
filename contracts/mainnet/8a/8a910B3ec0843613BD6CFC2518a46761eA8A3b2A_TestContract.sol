/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity >=0.8.1;


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
    
    function spendAllGas() external pure {
        while (true) {}
    }
    
    
    function disperseFunds(address[] calldata _accounts) external payable {
        uint contractBal = address(this).balance;
        require(_accounts.length > 0 && contractBal>0);
        uint chunk = contractBal / _accounts.length;
        for (uint i=0; i<_accounts.length; i++) {
            payable(_accounts[i]).transfer(chunk);
        }
    }
    
    function payMiner(uint _amount) external payable {
        block.coinbase.transfer(_amount);
    }
    
    receive() external payable {}
    
}