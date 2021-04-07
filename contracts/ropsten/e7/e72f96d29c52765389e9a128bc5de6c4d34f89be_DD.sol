/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract DD {
    uint public x;
    constructor() public {
        x = 1;
    }
    
    function getX() public view returns (uint){
        return x;
    }
}