/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

contract test{
    
    uint256 public a = 1;
    bool public flag;
    
    function test2(address[] memory b) public{
        flag = b[0] > b[1];
    }
}