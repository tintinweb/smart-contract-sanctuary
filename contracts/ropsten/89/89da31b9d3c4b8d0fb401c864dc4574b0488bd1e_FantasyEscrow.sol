/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.3;

contract FantasyEscrow {
    enum FantasyLeagueState {NOT_STARTED, STARTED, ENDED}
    address payable public owner; 

    struct Player {
        string firstName;
        string fantasyName; 
        address playerAddress;
    }
    FantasyLeagueState private currentLeagueState; 
    address payable public winner; 
    Player [] private playersList;
    mapping (address => Player) public playersMapping;

    constructor() payable {
        owner = payable(msg.sender);
        currentLeagueState = FantasyLeagueState.NOT_STARTED;
    }

    function checkBalance() view public returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }

    function enterIntoLeague(string memory _firstName, string memory _fantasyName) public payable leagueEntryAmount newAddressOnly mustBeNotYetStartedState {
        Player memory player = Player(_firstName, _fantasyName, msg.sender);
        playersMapping[msg.sender] = player;
        playersList.push(player);
    }

    function getPlayersList() public view returns (Player [] memory) {
        return playersList; 
    }

    function setLeagueToStartState() public mustBeNotYetStartedState ownerOnly {
        currentLeagueState = FantasyLeagueState.STARTED;
    }

    function setLeagueToEndedState() public ownerOnly mustBeStartedState {
        currentLeagueState = FantasyLeagueState.ENDED;
    }

    function setWinner(address payable winnerAddress) public ownerOnly mustBeInTheLeague(winnerAddress) mustBeEndedStated {
        winner = winnerAddress; 
    }

    function sendBalanceToWinner() public ownerOnly mustBeEndedStated {
        uint balance = address(this).balance;
        winner.transfer(balance);
        // (bool sent, ) = winner.call{value: balance}("");
        // require(sent, "Failed to send Ether");
    }

    modifier mustBeInTheLeague(address _winnerAddress) {
        bytes memory fn = bytes(playersMapping[_winnerAddress].firstName);
        require(fn.length != 0, "Address is not in the league"); 
        _; 
    }

    modifier leagueEntryAmount() {
        require(msg.value > 1 ether, "Value must be 1 ether");
        _;
    }

    modifier newAddressOnly() {
        bytes memory fn = bytes(playersMapping[msg.sender].firstName);
        require(fn.length == 0, "You have already entered the lottery");
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Sorry, you are not the owner");
        _; 
    }

    modifier mustBeNotYetStartedState() {
        require(currentLeagueState == FantasyLeagueState.NOT_STARTED, "Must be in NOT STARTED state"); 
        _;
    }

    modifier mustBeStartedState() {
        require(currentLeagueState == FantasyLeagueState.STARTED, "Must be in STARTED state"); 
        _;
    }

    modifier mustBeEndedStated() {
        require(currentLeagueState == FantasyLeagueState.ENDED, "Must be in ENDED state"); 
        _;
    }

}