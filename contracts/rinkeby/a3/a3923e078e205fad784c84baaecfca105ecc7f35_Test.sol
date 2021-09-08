/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

contract Test {
    uint256 private count;
    
    function add(uint256 a) public returns (uint256) {
        count = count + a;
        return count;
    }
}