/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

contract Thing {
    uint public z = 0;
    
    function sum(uint x, uint y) external {
        z = x + y;
    }
}