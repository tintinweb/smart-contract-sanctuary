/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.6.2 <0.8.0;

library Test {
    function whoami_1() public view returns (address) {
        return msg.sender;
    }
    function whoami_2() public view returns (address) {
        return tx.origin;
    }
    function calculateGas(uint256 x) public view returns (uint256) {
        uint256 a = gasleft();
        uint256 sum = 0;
        for (uint256 i = 1; i <= x; i++) {
            sum += x;
        }
        uint256 b = gasleft();
        require(sum == x * (x+1) / 2);
        return a - b;
    }
}