/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

pragma solidity >=0.7.0 <0.9.0;

contract BatchTransferer {
    function batch_transfer(address[] calldata target, uint256[] calldata amt) payable external {
        uint256 n = target.length;
        require(amt.length == n);
        uint256 remaining = msg.value;
        for (uint i = 0; i < n; i++) {
            payable(target[i]).transfer(amt[i]);
            remaining -= amt[i];
        }
        payable(msg.sender).transfer(remaining);
    }
}