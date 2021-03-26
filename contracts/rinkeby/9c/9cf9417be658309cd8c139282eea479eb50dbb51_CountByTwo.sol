/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

contract CountByTwo {
    uint256 count;
    
    
    function countUp() public returns(uint256) {
        count = count + 2;
        return count;
    }
}