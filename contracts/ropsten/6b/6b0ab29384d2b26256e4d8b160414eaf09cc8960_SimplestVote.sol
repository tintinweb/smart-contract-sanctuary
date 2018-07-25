pragma solidity ^0.4.22;


contract SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
  A simplest vote interface.
  (1) single issue
  (2) only 1 or 2
  (3) no voting time limit
  (4) each address can only vote once.
  (5) each address has the same weight.
 */
contract SimplestVote {

    mapping(address => uint256) public ballots;
    mapping(uint256/*option*/ => uint256/*weight*/) public currentVotes;  // mapping from

    /* Send coins */
    function vote(uint256 option) public {
        require(option == 1 || option == 2);
        require(ballots[msg.sender] == 0); // no revote
        ballots[msg.sender] = option;
        currentVotes[option] = currentVotes[option] + 1;
    }

    function getMostVotedOptions() public view returns(uint256 result) {
        return currentVotes[1] >= currentVotes[2] ? 1 : 2;
    }

}