/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.6.2 <0.8.0;

library Test {
    function blockInfo() public view returns (uint256, uint256, address) {
        return (block.number, block.timestamp, block.coinbase);
    }
    function msgInfo() public view returns (address, uint256) {
        return (msg.sender, msg.value);
    }
    function txInfo() public view returns (address, uint256) {
        return (tx.origin, tx.gasprice);
    }
    function calculateGas(uint256 x) public view returns (uint256) {
        uint256 a = gasleft();
        uint256 sum = 0;
        for (uint256 i = 1; i <= x; i++) {
            sum += i;
        }
        uint256 b = gasleft();
        require(sum == x * (x+1) / 2);
        return a - b;
    }
}