/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity=0.7.0;

// 不要使用这个合约，其中包含一个 bug。
contract Fund {
    mapping(address => uint) shares;
    /// 提取你的分成。
    function withdraw() public {
        msg.sender.call{value: 1 ether}("");
    }
}