/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

contract C {
    error A(uint256 aa);
    
    function x(uint256 a) public {
        revert A(a);
    }
}