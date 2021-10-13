/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

contract MockBNBBEP20 {
    function balanceOf(address _addr) public view returns (uint256) {
        return _addr.balance;
    }
    function allowance(address _addr, address spender) public view returns (uint256) {
        return type(uint256).max;
    }
}