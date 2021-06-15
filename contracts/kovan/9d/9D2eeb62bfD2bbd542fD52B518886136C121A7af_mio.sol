/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

contract mio {
    
    uint public x;
    
    constructor() public {
        x = block.timestamp;
    }
    
    function getTime () public view {
        block.timestamp - x;
    }
}