pragma solidity ^0.4.24;

// File: contracts/WeAreDevelopersRanklist.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract WeAreDevelopersRanklist is Ownable {

    struct Winner {
        string fullName;
        uint8 rank;
    }
    
    Winner[] winners;
    mapping (uint8 => Winner) winnerByRank;

    constructor() public {
        setWinner("no permission to publish", 1);
        setWinner("Emanuel Schmoczer", 2);
        setWinner("no permission to publish", 3);
        setWinner("Thomas Boigner", 4);
        setWinner("no permission to publish", 5);
        setWinner("no permission to publish", 6);
        setWinner("Magomed Arsaev", 7);
        setWinner("Elsa Heer", 8);
        setWinner("no permission to publish", 9);
        setWinner("no permission to publish", 10);
    }

    function getDescription() public pure returns(string) {
        return "This is the wall of fame of developers participating in the CONDA developer challange at WeAreDevelopers 2018";
    }
    
    function setWinner(string _fullName, uint8 _rank) public onlyOwner {
        Winner storage winner = winners[winners.length++];
        winner.fullName = _fullName;
        winner.rank = _rank;

        winnerByRank[_rank] = winner;
    }
    
    function getWinnerWithRank(uint8 _rank) public view returns(string) {
        Winner storage winner = winnerByRank[_rank];
        
        return winner.fullName;
    }

    function getRank01() public view returns(string) {
        return getWinnerWithRank(1);
    }

    function getRank02() public view returns(string) {
        return getWinnerWithRank(2);
    }

    function getRank03() public view returns(string) {
        return getWinnerWithRank(3);
    }

    function getRank04() public view returns(string) {
        return getWinnerWithRank(4);
    }

    function getRank05() public view returns(string) {
        return getWinnerWithRank(5);
    }

    function getRank06() public view returns(string) {
        return getWinnerWithRank(6);
    }

    function getRank07() public view returns(string) {
        return getWinnerWithRank(7);
    }

    function getRank08() public view returns(string) {
        return getWinnerWithRank(8);
    }

    function getRank09() public view returns(string) {
        return getWinnerWithRank(9);
    }

    function getRank10() public view returns(string) {
        return getWinnerWithRank(10);
    }
}