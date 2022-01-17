// SPDX-License-Identifier: GPL-3.0

// To do: make $coffee untransferrable

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface coffeeERC20 {
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external returns (uint256);
    function decimals() external returns (uint8);
}

contract coffeeBreak is Ownable {

    uint constant VERSION = 4;
    bool started = false;
    uint startTime;
    address judge;

    address coffeeCoinRegistery = 0xEbe45e73Dcad7e96f504091A7D8b71215111f2A4;
    uint coffeePayment = 10;

    uint paymentAmount = 100000000 gwei;
    uint minMembers = 2; // minimum team count
    uint maxMembers = 36; 

    uint round = 0; 
    uint deadline; // deadline timestamp
    uint interval = 120; // 6 hours = 21600
    uint gracePeriod = 60; // 15 min
    uint intervalDecay = 5; // percent rate decay
    uint decayRandom = 0; // percent randomness to be added to the decay rate

    struct capcha {
        string question;
        bytes32 answer;
        address author;
        bool solved;
    }
    struct team {
        uint turn;
        string name;
        address[] members; 
        capcha[] capchas;
        bool alive;
        uint coffeeBalance;
    }
    // team[] teams;
    mapping (uint => team) teams;
    uint numTeams;
    mapping (bytes32 => mapping (address => bool)) memberApprovals;

    constructor() {
        start();
    }

//  PRIMARY FUNCTIONS

    function getCoffee(string memory _answer, string memory _newQuestion, string memory _newAnswer) public {
        uint _teamId = teamIdByAddress(msg.sender);
        require(coffeeReady(), "Coffee not ready.");
        require(teams[_teamId].members[teams[_teamId].turn] == msg.sender, "Not your turn");
        require(teams[_teamId].capchas[round].solved == false, "Capcha already solved.");
        require(teams[_teamId].alive == true, "Your team already lost.");
        require(teams[_teamId].capchas[round - 1].answer == keccak256(abi.encodePacked(_answer)), "Wrong answer. Ask for help if you need to.");
        capcha memory _capcha = capcha({
            question : _newQuestion,
            answer : keccak256(abi.encodePacked(_newAnswer)),
            author : msg.sender,
            solved : true
        });
        // save question + answer to the next teams capcha
        teams[(_teamId + 1) % numTeams].capchas.push(_capcha);
        teams[_teamId].turn = (teams[_teamId].turn + 1) % teams[_teamId].members.length; // increment turn
        // check for losses for previous rounds
        for (uint i = 0; i < numTeams; i++) 
            checkForLosses(i);
        teams[_teamId].coffeeBalance += coffeePayment;
        coffeeERC20(coffeeCoinRegistery).mint(msg.sender, coffeePayment); // make payment
    }

    function coffeeReady() public view returns (bool) {
        return (block.timestamp >= deadline && block.timestamp <= deadline + gracePeriod);
    }

    function checkForLosses(uint _teamId) public {
        for (uint _round = 0;_round <= round - 1;_round++) { 
            if (!teams[_teamId].capchas[_round].solved)
                teams[_teamId].alive = false;
        }
    }

    function winner() public view returns (uint){
        uint winningTeamId;

        // first check previous rounds
        uint numActiveTeams = 0;
        for (uint _teamId = 0;_teamId < numTeams;_teamId++) {
            if (teams[_teamId].alive) {
                numActiveTeams++;
                winningTeamId = _teamId;
            }
        }
        if (numActiveTeams == 1)
            return winningTeamId;

        // first last round if we are past the grace period

        require(block.timestamp > deadline + gracePeriod, "No winner yet");

        numActiveTeams = 0;
        for (uint _teamId = 0;_teamId < numTeams;_teamId++) {
            bool alive = true;
            for (uint _round = 0;_round <= round - 1;_round++) { 
                if (!teams[_teamId].capchas[_round].solved)
                    alive = false; 
            }
            if (alive) {
                numActiveTeams++;
                winningTeamId = _teamId;
            }
        }
        if (numActiveTeams == 1)
            return winningTeamId;
        revert("No winner!");
    }
    
    function nextRound() private {
        round++;
        uint _random = uint(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, msg.sender))) % decayRandom; // fix later -- refer to amxx's contract
        interval = interval * (100 - intervalDecay + _random) / 100;
        deadline += interval;
    }

// TEAM MANAGEMENT

    function createTeam(address[] memory _members, string memory _name) public {
        require(started==false,"game already started.");
        require(_members.length >= minMembers, "not enough members");
        require(_members.length <= maxMembers, "too many members");
        teams[numTeams].members = _members;
        teams[numTeams].name = _name;
        teams[numTeams].turn = 0;
        teams[numTeams].alive = true;
        teams[numTeams].coffeeBalance = 0;
        teams[numTeams].capchas[0] = capcha({
            question : "Type 'go' to start.",
            answer : keccak256(abi.encodePacked("go")),
            author : msg.sender,
            solved : false
        });
        numTeams++;
    }

    function nominateMember(address _newAddress) public { 
        uint _teamId = teamIdByAddress(msg.sender);
        bytes32 _hash = keccak256(abi.encodePacked(_teamId, _newAddress));
        memberApprovals[_hash][_newAddress] = true;
    }

    function approveMember(address _newAddress, bool _approved) public {
        uint _teamId = teamIdByAddress(msg.sender);
        bytes32 _hash = keccak256(abi.encodePacked(_teamId, _newAddress));
        memberApprovals[_hash][_newAddress] = _approved;
    }

    function mergeMember(address _newAddress) public {
        uint _teamId = teamIdByAddress(msg.sender);
        bool allApproved = true;
        bytes32 _hash = keccak256(abi.encodePacked(_teamId, _newAddress));
        for (uint i = 0;i < teams[_teamId].members.length;i++){
            if (memberApprovals[_hash][_newAddress] == false)
                allApproved = false;
        }
        require(allApproved, "Not approved");
        addMember(_teamId, _newAddress);
    }

    function addMember(uint _teamId, address _newAddress) private {
        require(teams[_teamId].members.length < maxMembers, "Team has maximum members.");
        teams[_teamId].members.push(_newAddress);
    }

// GAME MANAGEMENT

    function start() public onlyOwner {
        require(started == false, "Already started!");
        started = true;
        startTime = block.timestamp;
        deadline = startTime + interval;
        round++;
    }

// JUDGE FUNCTIONS

    function setJudge(address _newJudge) public onlyOwner {
        judge = _newJudge;
    }

    function adminExtendDeadline(uint _moreTime) public {
        require(msg.sender == judge, "You are not the judge.");
        deadline += _moreTime;
    }

    function adminSolve(uint _round, uint _teamId) public {
        require(msg.sender == judge, "You are not the judge.");
        teams[_teamId].capchas[_round].solved = true;
    }

    function adminReverseLoss(uint _teamId) public {
        require(msg.sender == judge, "You are not the judge.");
        teams[_teamId].alive = true;
    }

// VIEW FUNCTIONS

    function getRound() public view returns (uint){
        return round;
    }

    function whosTurn(uint _teamId) public view returns (address){
        uint _turn = teams[_teamId].turn;
        return teams[_teamId].members[_turn];
    }

    function whosTurnNext(uint _teamId) public view returns (address){
        uint _turn = (teams[_teamId].turn + 1) % teams[_teamId].members.length;
        return teams[_teamId].members[_turn];
    }

    function getInterval() public view returns (uint){
        return interval;
    }

    function getDeadline() public view returns (uint){
        return deadline;
    }

    function isStarted() public view returns (bool){
        return started;
    }

    function getNumTeams() public view returns (uint){
        return numTeams;
    }

    function teamIdByAddress(address _address) public view returns (uint) {
        for (uint _teamId = 0; _teamId < numTeams;_teamId++){
            for (uint m = 0; m < teams[_teamId].members.length;m++){
                if (teams[_teamId].members[m] == _address)
                    return _teamId;
            }
        }
        revert("Address not on team.");
    }

    function getQuestion(uint _teamId) public view returns (string memory) {
        return teams[_teamId].capchas[round].question;
    }

    function coffeeBalance(uint _teamId) public view returns (uint) {
        return teams[_teamId].coffeeBalance;
    }

    function getMembers(uint _teamId) public view returns (address[] memory) {
        return teams[_teamId].members;
    }

    function getTeamName(uint _teamId) public view returns (string memory) {
        return teams[_teamId].name;
    }

    function getStatus(uint _teamId) public view returns (bool) {
        return teams[_teamId].alive;
    }

// INTERFACE FUNCTIONS

    function coffeeBalanceByAddress(address account) public returns (uint256){
        return coffeeERC20(coffeeCoinRegistery).balanceOf(account); 
    }

    function coffeeDecimals() public returns (uint8){
        return coffeeERC20(coffeeCoinRegistery).decimals();  
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}