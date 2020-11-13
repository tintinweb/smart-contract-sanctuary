// SPDX-License-Identifier: MIT
// Developed by Pironmind
// https://t.me/pironmind

pragma solidity >=0.4.22 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IVotes.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IRandom.sol";

/*
 * @title AmericanVotes
 * @dev Implements voting process along with vote delegation
 */
contract AmericanVotes is IVotes, Ownable, ReentrancyGuard {
    using Address for *;
    using SafeMath for uint;

    event EthereumDeposited(address voter, uint256 amount);
    event LuckyBonusClaimed(address lacky, uint256 amount);
    event TeamRewardClaimed(address teammate, uint256 amount);
    event EthereumWithdrawn(address resipient, uint256 amount);
    event DemocratsWon(bool x);

    enum Consignmen { NONE, REPUBLICANS, DEMOCRATS }
    enum State { NONE, CHANGE }

    struct Voter {
        uint weight; // balance
        uint balance;
        bool voted;  // if true, that person already voted
        Consignmen voteType;
        State state;
        bool credited;
    }

    struct Proposal {
        uint voteCount; // number of accumulated votes
        uint voteWeight;
        uint weightRepublicans;
        uint weightDemocrats;
        uint forRepublicans;
        uint forDemocrats;
        uint startDate;
        uint endDate;
        Consignmen winner;
    }

    Proposal public proposal;

    mapping(address => Voter) public voters;

    address[] public votersList;

    uint256 private _minimumDeposit;

    uint256 public serviceFee;

    uint256 public luckyFee;

    mapping (address => uint) public balances;

    address public teamWallet;
    IRandom public randomOracle;
    address public luckyAddress = address(0);

    /*
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(address _teamWallet, address _randomOracle, uint startDate, uint endDate) {
        teamWallet = _teamWallet;
        randomOracle = IRandom(_randomOracle);
        proposal.startDate = startDate;
        proposal.endDate = endDate;
        serviceFee = 20; // %
        luckyFee = 5; // %
        _minimumDeposit = 1e17;
    }

    // @dev How much lucky guy get in random
    function luckyBonus() public view returns (uint256) {
        return balances[address(0)];
    }

    // @dev How much team get if anything will be okey
    function teamReward() public view returns (uint256) {
        return balances[teamWallet];
    }

    function isVoted(address _who) public override view returns (bool) {
        return voters[_who].voted;
    }


    function totalVotes() public override view returns (uint) {
        return proposal.voteCount;
    }

    function totalWeight() public override view returns (uint) {
        return proposal.voteWeight;
    }

    function minimumDeposit() public view returns (uint) {
        return _minimumDeposit;
    }

    // @dev _amount (wei)
    function setMinimumDeposit(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Must be more then 0");

        _minimumDeposit = _amount;
    }

    function _deposit() internal /*override*/ /*payable*/ /*nonReentrant*/ {
        require(!Address.isContract(msg.sender), "Contract deposit not accepted");
        require(msg.value >= minimumDeposit(), "Not enough balance for deposit");

        uint _serviceShare = msg.value.mul(serviceFee).div(100);
        uint _luckyShare = msg.value.mul(luckyFee).div(100);
        balances[address(teamWallet)] = balances[address(teamWallet)]
            .add(_serviceShare.sub(_luckyShare));
        balances[address(luckyAddress)] = balances[address(luckyAddress)]
            .add(_luckyShare);

        voters[msg.sender].balance = voters[msg.sender].balance.add(msg.value.sub(_serviceShare));

        emit EthereumDeposited(msg.sender, msg.value.sub(_serviceShare));
        emit EthereumDeposited(teamWallet, _serviceShare.sub(_luckyShare));
        emit EthereumDeposited(luckyAddress, _luckyShare);
    }

    function withdraw() public override onlyAfter afterWinnerSet {

        // team wallet withdraw
        if (msg.sender == address(teamWallet)) {
            uint amount = balances[address(teamWallet)];
            balances[address(teamWallet)] = balances[address(teamWallet)].sub(amount);
            balances[address(teamWallet)] = 0;
            payable(msg.sender).transfer(amount);
            emit TeamRewardClaimed(address(teamWallet), amount);
            return;
        }

        // lucky wallet withdraw
        if (msg.sender == address(luckyAddress) && balances[address(luckyAddress)] > 0) {
            uint amount = balances[address(luckyAddress)];
            balances[address(luckyAddress)] = balances[address(luckyAddress)].sub(amount);
            balances[address(luckyAddress)] = 0;
            payable(msg.sender).transfer(amount);
            emit LuckyBonusClaimed(address(luckyAddress), amount);
            return;
        }

        // count withdraw
        require(!voters[msg.sender].credited, "Balance counted");
        require(voters[msg.sender].voteType == proposal.winner, "Only if winner");

        voters[msg.sender].credited = true;

        uint weight = voters[msg.sender].weight;
        uint share = _countShare(proposal.weightDemocrats, proposal.weightRepublicans, weight);

        voters[msg.sender].weight = voters[msg.sender].weight.sub(weight, "WSUB1");
        voters[msg.sender].balance = voters[msg.sender].balance.add(weight).add(share);

        uint _amount = voters[msg.sender].balance;
        voters[msg.sender].balance = voters[msg.sender].balance.sub(_amount, "WSUB2");

        payable(msg.sender).transfer(_amount);
        emit EthereumWithdrawn(address(msg.sender), _amount);
    }

    function voteForRepublicans() public override payable nonReentrant {
        _deposit();
        _vote(Consignmen.REPUBLICANS, msg.sender);
    }

    function voteForDemocrats() public override payable nonReentrant {
        _deposit();
        _vote(Consignmen.DEMOCRATS, msg.sender);
    }

    // after 1 month contract can be destroyed
    function destroyIt() public override onlyOwner {
        require(block.timestamp > proposal.endDate.add(31 * 1 days));
        selfdestruct(msg.sender);
    }

    function democratsWon() public override onlyOwner onlyAfter winnerNotSet {
        _setWinner(Consignmen.DEMOCRATS);
        _selectLucky();
        emit DemocratsWon(true);
    }

    function republicansWon() public override onlyOwner onlyAfter winnerNotSet {
        _setWinner(Consignmen.REPUBLICANS);
        _selectLucky();
        emit DemocratsWon(false);
    }

    function _setWinner(Consignmen _winner) internal {
        proposal.winner = _winner;
    }

    function _selectLucky() internal {
        require(randomOracle.getNumber(0, uint(votersList.length).sub(1, "SL1")) >= 0, "Oracle connected");
        uint luckyNum = randomOracle.getNumber(0, uint(votersList.length).sub(1, "SL1"));
        luckyAddress = votersList[luckyNum];
        uint luckyBank = balances[address(0)];
        balances[address(0)] = balances[address(0)].sub(luckyBank);
        balances[votersList[luckyNum]] = balances[votersList[luckyNum]].add(luckyBank);
    }

    function _vote(Consignmen _type, address voter)
        internal
        onlyDuring
    {
        Voter storage sender = voters[msg.sender];

        if (sender.voteType != Consignmen.NONE) {
            require(sender.voteType == _type, "Only for one candidate");
        }

        uint256 amount = sender.balance;
        sender.balance = sender.balance.sub(amount);
        sender.weight = sender.weight.add(amount);
        sender.voteType = _type;

        if (_type == Consignmen.DEMOCRATS) {
            proposal.weightDemocrats = proposal.weightDemocrats.add(amount);
        } else {
            proposal.weightRepublicans = proposal.weightRepublicans.add(amount);
        }

        if (!sender.voted) {
            proposal.voteCount++;
            if (_type == Consignmen.DEMOCRATS) {
                proposal.forDemocrats++;
            } else {
                proposal.forRepublicans++;
            }
            votersList.push(voter);
        }

        sender.voted = true;

        proposal.voteWeight = proposal.voteWeight.add(amount);
    }

    function _countShare(uint256 share1, uint256 share2, uint256 userShare) public view returns(uint) {
        if (proposal.winner == Consignmen.DEMOCRATS) {
            return userShare.mul(share1).div(share2);
        }
        return userShare.mul(share2).div(share1);
    }

    modifier onlyDuring() {
        require(
            block.timestamp >= proposal.startDate &&
            block.timestamp <= proposal.endDate,
            "Voting not has not started or just ended yet"
        );
        _;
    }

    modifier onlyAfter() {
        require(block.timestamp > proposal.endDate, "Voting in progress");
        _;
    }

    modifier winnerNotSet() {
        require(proposal.winner == Consignmen.NONE, "Only if no winner");
        _;
    }

    modifier afterWinnerSet() {
        require(proposal.winner != Consignmen.NONE, "Only after winner was set");
        _;
    }
}
