/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity 0.4.26;

contract Burner {
    function() external {}
    
    function selfDestruct() external {
        selfdestruct(address(this));
    }
}