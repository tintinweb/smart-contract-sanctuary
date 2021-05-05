/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity >=0.4.22 <=0.6.0;
contract Hello {
    string constant a = "Hello MITers";
    function get() public pure returns (string memory){
        return a;
    }
}