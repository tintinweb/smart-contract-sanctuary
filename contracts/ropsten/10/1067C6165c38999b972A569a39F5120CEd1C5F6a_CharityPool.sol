pragma solidity ^0.5.12;

import './CompoundWallet.sol';

contract CharityPool is CompoundWallet {
    
    uint public ethDeposited = 0;
    uint public nextId = 0;
    address public admin;
    mapping(address => uint) public deposits;
    mapping(address => bool) public poolsWhitelist;
    mapping(address => mapping(uint => uint)) public votes;
    mapping(address => uint) public votingPower;
    Charity[] public winners;
    Charity[] public charities;
    
    
    event whitelistedEvent(address member);
    event unWhitelistedEvent(address member);
    event deposited(uint depositAmount);
    event withdrawed(uint withdrawAmount);
    event addedVotes(uint id, uint voteAmount);
    event removedVotes(uint id, uint voteAmount);
    event wonPrize(uint timestamp, uint id, uint votes);

    constructor() public {
        admin = msg.sender;
        deposits[msg.sender] = 0;
    }

    struct Charity {
        uint id;
        string name;
        address payable targetAddress;
        uint votes;
    }
 
    /// @dev Whitelist member for a pool
    /// @param _memberTarget the address of the member to add to whitelist
    function whitelist(address _memberTarget) public onlyPoolAdmin() {
        poolsWhitelist[_memberTarget] = true;
        emit whitelistedEvent(_memberTarget);
    }
    
    /// @dev Unwhitelist member for a pool
    /// @param _memberTarget the address of the member to remove from whitelist
    function unwhitelist(address _memberTarget) public onlyPoolAdmin() {
        require(deposits[_memberTarget] == 0, 'cannot unwhitelist with deposits!');
        poolsWhitelist[_memberTarget] = false;
        emit unWhitelistedEvent(_memberTarget);
    }
    
     /// @dev Deposit into a pool
     /// @param _compoundAddress the compound address to deposit into
    function deposit(address payable _compoundAddress) public payable onlyMember() {
        deposits[msg.sender] += msg.value;
        ethDeposited += msg.value;
        votingPower[msg.sender] += msg.value;
        supplyEthToCompound(_compoundAddress);
        emit deposited(msg.value);
    }
    
    /// @dev Withdraw from a pool
    /// @param _amount the amount of Wei to withdraw
    /// @param _compoundAddress the compound address to withdraw from
    function withdraw(uint _amount, address _compoundAddress) public onlyMember() {
        require(deposits[msg.sender] >= _amount, 'not enough deposited!');
        require(votingPower[msg.sender] >= _amount, 'not enough voting power to withdraw that amount!');
        redeemcETHTokens(_amount, false, _compoundAddress);
        address(msg.sender).transfer(_amount);
        deposits[msg.sender] -= _amount;
        ethDeposited -= _amount;
        votingPower[msg.sender] -= _amount;
        emit withdrawed(_amount);
    }
    

    /// @dev Releases the interest  after the timeperiod
    /// @param _compoundAddress the compound address
    function releasePrizeTarget(address _compoundAddress) public onlyAdmin() {
        Charity memory mostVotes = charities[0];
        uint charityLength = charities.length;

        for (uint i=0; i<charityLength; i++) {
            if(charities[i].votes > mostVotes.votes) {
                mostVotes = charities[i];
            }
        }
        address payable _target = mostVotes.targetAddress;
        //Release interest to target address
        address(_target).transfer(calculateInterest(_compoundAddress));
        winners.push(mostVotes);
        emit wonPrize(block.timestamp, mostVotes.id, mostVotes.votes);
    }


    /// @dev Calculates the interest accured for Pool
    function calculateInterest(address _compoundAddress) internal returns (uint) {
        cETH cToken = cETH(_compoundAddress);
        //1. Retrieve how much total ETH Underlying in Contract
        uint contractEthUnderlying = cToken.balanceOfUnderlying(address(this));
        //2. Calculate the total interest to be paid out for contract
        uint totalInterest = contractEthUnderlying - ethDeposited;
        return totalInterest;
    }

    /// @dev Creates a charity address
    /// @param _name the name of the charity
    /// @param _targetAddress the target address of the charity
    function createCharity(string memory _name, address payable _targetAddress) public onlyAdmin() {
        charities.push(Charity(nextId, _name, _targetAddress, 0));
        nextId++;
    }

    /// @dev Adds votes to a charity
    /// @param _id the id of the charity
    /// @param _voteAmount the amount of votes to add
    function addVotes(uint _id, uint _voteAmount) public onlyMember() {
        require(votingPower[msg.sender] >= _voteAmount, 'must have enough voting power!');
        require(_voteAmount > 0, 'cannot vote negative!');
        votes[msg.sender][_id] += _voteAmount;
        votingPower[msg.sender] -= _voteAmount;
        charities[_id].votes += _voteAmount;
        emit addedVotes(_id, _voteAmount);
    }

    /// @dev Removes votes from a charity    
    /// @param _id the id of the charity
    /// @param _voteAmount the amount of votes to remove
    function removeVotes(uint _id, uint _voteAmount) public onlyMember() {
        require(deposits[msg.sender] >= _voteAmount, 'not enough deposited to remove votes!');
        require(votes[msg.sender][_id] >= _voteAmount, 'not enough votes in this charity to remove!');
        require(_voteAmount > 0, 'cannot vote negative!');
        votes[msg.sender][_id] -= _voteAmount;
        votingPower[msg.sender] += _voteAmount;
        charities[_id].votes -= _voteAmount;
        emit removedVotes(_id, _voteAmount);
    }


    /// @dev Can only be admin for pool modifier
    modifier onlyPoolAdmin() {
        require(msg.sender == admin, 'Must be te admin for this pool!');
        _;
    }

    /// @dev Can only be members in pool modifier
    modifier onlyMember() {
        require(poolsWhitelist[msg.sender] == true, 'Must be a member!');
        _;
    }
    
    
}