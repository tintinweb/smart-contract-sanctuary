/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

contract Storage {
    uint public pos0 = 77; // 0x0
    
    function increment() external {
        pos0++;  // SSTORE
    }
    
    function addTo(uint x) external {
        pos0 += x;
    }
}