/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity ^0.4.18;



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
contract BettingOrig is Ownable {
    
    event EtherTransfer(address beneficiary, uint amount);
    
    /* To store bets for each team from each address */
    mapping (bytes32 => mapping (address => uint256)) public bets;

    /* The address of the owner */
    address owner;

    /* Boolean to verify if betting period is active */
    bool bettingActive = false;

    bytes32 winner;
    uint256 numCandidates;
    uint256 numvoters;

    /* All candidates stored as string of bytes as solidity does not support strings */
    bytes32[] public candidateList;

    /* Address array to store all addresses that have participated in the betting. */
    address[] public betters;

    /* Events can be emitted by functions in order to notify listener (off-chain)
     * applications of the occurrence of a certain event
     */
    event Print(bytes32[] _name);

    /* Runs before certain functions to ensure that the owner runs this */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /* Constructor */
    constructor() public {
        owner = msg.sender;
        numCandidates = 0;
    }

    /* Getter function that returns candidate list. */
    function getCandidateList() public constant returns (bytes32[]) {
        return candidateList;
    }

    /* Getter function that returns contract owner address */
    function getOwner() public constant returns (address) {
        return owner;
    }

    /* Getter function that returns the number of candidates */
    function getCount() public constant returns (uint256) {
        return candidateList.length;
    }

    /* Returns the total balance involved in bets */
    function getBalance() public constant returns (uint256) {
        return address(this).balance;
    }

    /* Function that adds candidate to candidate list. Can only be called by owner. */
    function addCandidate(bytes32 candidate) onlyOwner public returns (bool) {
        candidateList.push(candidate);
        numCandidates += 1;
        return true;
    }

    /* Function that inputs data about the winner. Can only be called by owner. */
    function addWinner(bytes32 selectedwinner) onlyOwner public returns (bool) {
        winner = selectedwinner;
        return true;
    }

    /* Function to enable betting */
    function beginVotingPeriod() onlyOwner public returns(bool) {
        bettingActive = true;
        return true;
    }

    /* This function increments the vote count for the specified candidate. This
     * is equivalent to casting a vote
     */
    function betOnCandidate(bytes32 candidate) public payable  {
        require(bettingActive);
        require(msg.value >= 0.0001 ether);
        require(validCandidate(candidate));
        betters.push(msg.sender);
        bets[candidate][msg.sender] += msg.value;
    }

    /* This function checks if the provided candidate is valid
     * list and returns a boolean.
     */
    function validCandidate(bytes32 candidate) view public returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    // /* An implementation for randomly selecting a winner (for debugging!) */
    // function getWinner() view public returns (uint256) {
    //     if (numCandidates == 0) return;
    //     return (uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))) % numCandidates);
    // }
    
    function withdrawEther(address beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    /* Function to close voting and handle payout. Can only be called by the owner. */
    function closeVoting() onlyOwner public returns (bool) {
        require(bettingActive);
        bytes32 winningCandidate = winner;

        // getting list of winners and losers
        // and the money lost by all losers
        address[] memory winners;
        uint256 numWinners = 0;
        uint256 numLosers = 0;
        uint256 surplus = 0;
        for (uint x = 0; x < betters.length; x++) {
            if (bets[winningCandidate][betters[x]] > 0) {
                winners[numWinners++] = betters[x];
            } else {
                surplus += bets[winningCandidate][betters[x]];
                numLosers++;
            }
        }

        // keeping 10% as service fee and distribute rest among the winners
        uint256 prize = surplus * 9 / 10;
        // calculate prize per winner
        prize = prize / numLosers;
        // distribute the prize to the winners alongwith the money they bet in
        for (x = 0; x < winners.length; x++) {
            winners[x].transfer(prize + bets[winningCandidate][winners[x]]);
        }
        // Close the betting period
        bettingActive = false;
        return true;
    }
}