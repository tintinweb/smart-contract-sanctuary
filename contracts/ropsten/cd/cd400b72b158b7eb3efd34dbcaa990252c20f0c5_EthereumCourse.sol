/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

/**
 *Submitted for verification at Etherscan.io on 2017-10-17
*/

pragma solidity 0.4.17;
contract EthereumCourse {
    mapping(address => bool) public voted;
    string public poll = 'Is this course hard or easy for you?';
    string[] public votes;
    
    event Vote(address voter, string answer);
    
    function vote(string _answer) public returns(bool) {
        if (voted[msg.sender]) {
            return false;
        }
        voted[msg.sender] = true;
        votes.push(_answer);
        Vote(msg.sender, _answer);
        return true;
    }
}