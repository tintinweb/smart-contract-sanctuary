/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract DoImportantStuff {
    function begin(int depth) public {
        if(depth == 0) return;
        begin(depth - 1);
        begin(depth - 1);
    }
}