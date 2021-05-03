/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity =0.8.0;

contract EVMTwitter {
    address public replyTo;
    string public content;
    
    constructor(address _replyTo, string memory _content) {
        replyTo = _replyTo;
        content = _content;
    }
}