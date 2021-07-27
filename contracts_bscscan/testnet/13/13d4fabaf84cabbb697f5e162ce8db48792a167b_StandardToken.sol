/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

//*****************************************************************************//
//                        Coin Name : ILUS                                    //
//                           Symbol : ILUS                                    //
//                     Total Supply : 100,000,000                             //
//                         Decimals : 18                                      //
//                    Functionality : Buy, Swap, Stake, Governance            //
//****************************************************************************//

 /**
 * @title SafeMath
 * @dev   Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    if (a == 0){
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b,"Calculation error");
    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256){
    // Solidity only automatically asserts when dividing by 0
    require(b > 0,"Calculation error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256){
    require(b <= a,"Calculation error");
    uint256 c = a - b;
    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a + b;
    require(c >= a,"Calculation error");
    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256){
    require(b != 0,"Calculation error");
    return a % b;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title ILUS Contract For ERC20 Tokens
* @dev ILUS tokens as per ERC20 Standards
*/
contract StandardToken is IERC20 {

  using SafeMath for uint256;

  address private _owner;                                                       // Owner of the Contract.
  string  private _name;                                                        // Name of the token.
  string  private _symbol;                                                      // symbol of the token.
  uint8   private _decimal;                                                     // variable to maintain decimal precision of the token.
  uint256 private _totalSupply = 100000000000000000000000000;                   // total supply of token.
  bool    private _stopped = false;                                             // state variable to check fail-safe for contract.
  uint256 public airdropcount = 0;                                              // Variable to keep track on number of airdrop
  address private _tokenPoolAddress;                                            // Pool Address to manage Staking user's Token.
  uint256 airdropcountOfMMM = 0;                                                // Variable to keep track on number of airdrop
  uint256 tokensForMMM = 25150000000000000000000000;                            // airdrop tokens for MMM
   
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
 
  constructor (string memory Name, string memory Symbol, uint8 Decimal, address Owner, address tokenPoolAddress) {
    _name = Name;
    _symbol = Symbol;
    _decimal = Decimal;
    _balances[Owner] = _totalSupply;
    _owner = Owner;
    _tokenPoolAddress = tokenPoolAddress;
  }
 
  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */

  /**
   * @dev get address of smart contract owner
   * @return address of owner
   */
  function getowner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev modifier to check if the message sender is owner
   */
  modifier onlyOwner() {
    require(isOwner(),"You are not authenticate to make this transfer");
    _;
  }
  
    
  /**
   * @dev Internal function for modifier
   */
  function isOwner() internal view returns (bool) {
      return msg.sender == _owner;
  }

  /** 
   * @dev Transfer ownership of the smart contract. For owner only
   * @return request status
   */
  function transferOwnership(address newOwner) public onlyOwner returns (bool){
    _owner = newOwner;
    return true;
  }

        
  /** 
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * View only functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */
  
  /**
   * @return the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /** 
   * @return the symbol of the token.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /** 
   * @return the number of decimal of the token.
   */
  function decimals() public view returns (uint8) {
    return _decimal;
  }

  /** 
   * @dev Total number of tokens in existence.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /** 
   * @dev Gets the balance of the specified address.
   * @param owner The address to query the balance of.
   * @return A uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  /** 
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  /** 
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * Transfer, allow and burn functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */

  /**
   * @dev Transfer token to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /** 
   * @dev Transfer tokens from one address to another.
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /** 
   * @dev Transfer token for a specified addresses.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
   function _transfer(address from, address to, uint256 value) internal {
    require(from != address(0),"Invalid from Address");
    require(to != address(0),"Invalid to Address");
    require(value > 0, "Invalid Amount");
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /** 
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /** 
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0),"Invalid address");
    require(owner != address(0),"Invalid address");
    require(value > 0, "Invalid Amount");
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /** 
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /** 
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }
    
  /** 
   * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
   * @param _addresses array of address in serial order
   * @param _amount amount in serial order with respect to address array
   */
  function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      airdropcount = airdropcount + 1;
      }
    return true;
   }

   /** 
   * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
   * @param _addresses array of address in serial order
   * @param _amount amount in serial order with respect to address array
   */
  function airdropByOwnerForMMM(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
    require(_addresses.length == _amount.length,"Invalid Array");
    require(tokensForMMM > 0, "Tokens are zero");
    uint256 count = _addresses.length;
    for (uint256 i = 0; i < count; i++){
      _transfer(msg.sender, _addresses[i], _amount[i]);
      uint256 remainingTokens = tokensForMMM - _amount[i];
      tokensForMMM = remainingTokens;
      airdropcountOfMMM = airdropcountOfMMM + 1;
      }
    return true;
   }

  /** 
   * @dev Internal function that burns an amount of the token of a given account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0),"Invalid account");
    require(value > 0, "Invalid Amount");
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /** 
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }
  
  /** 
   * Function to mint tokens
   * @param _value The amount of tokens to mint.
   */
  function mint(uint256 _value) public onlyOwner returns(bool){
    require(_value > 0,"The amount should be greater than 0");
    _mint(_value,msg.sender);
    return true;
  }

  /** 
   * @dev Internal function that mints an amount of the token of a given account.
   * @param _value The amount that will be mint.
   * @param _tokenOwner The address of the token owner.
   */
  function _mint(uint256 _value,address _tokenOwner) internal returns(bool){
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    _totalSupply = _totalSupply.add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
    return true;
  }
  
  // Mapping for users with id => address Staked Address
  mapping (uint256 => address) private _stakerAddress;

  // Mapping for users with id => Tokens 
  mapping (uint256 => uint256) private _usersTokens;
  
  // Mapping for users with id => Staking Time
  mapping (uint256 => uint256) private _stakingStartTime;

  // Mapping for users with id => Status
  mapping (uint256 => bool) private _TokenTransactionstatus;  
 
  // Mapping to keep track of final withdraw value of staked token
  mapping(uint256=>uint256) private _finalWithdrawlStake;
  
  // Reward Percentage
  uint256 private _rewardPercentage= 15; 
  
  // Count of no of staking
  uint256 private _stakingCount = 0;

  // Withdraw Time limit
  uint256 _withdrawLimit = 1800;

  
  /** 
   * @dev modifier to check the failsafe
   */
  modifier failSafe(){
    require(_stopped == false, "Fail Safe check failed");
    _;
  }

 /*
  * ------------------------------------------------------------------------------------
  * Owner functions of get value, set value, blacklist and withdraw ETH Functionality
  * ------------------------------------------------------------------------------------
  */

  /**
   * @dev Function to secure contract from fail by toggling _stopped variable
   */
  function toggleContractActive() public onlyOwner{
    _stopped = !_stopped;
  }


  /**
   * @dev Function to set token pool address
   * @param add Address for token pool that manages supplies for stakes.
   */
  function setTokenPoolAddress(address add) public onlyOwner returns(bool){
    require(add != address(0),"Invalid Address");
    _tokenPoolAddress = add;
    return true;
  }
  
 
  /**
   * @dev Function to get Token Pool addresss
   */
  function getTokenpoolAddress() public view returns(address){
    return _tokenPoolAddress;
  }


  /**
   * @dev Function for setting rewards percentage by owner
   * @param rewardsPercentage Reward percentage
   */
  function setRewardPercentage(uint256 rewardsPercentage) public onlyOwner returns(bool){
    require(rewardsPercentage > 0, "Invalid Percentage");
    _rewardPercentage = rewardsPercentage;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getRewardPercentage() public view returns(uint256){
    return _rewardPercentage;
  }

  
  /**
   * @dev Function to blacklist any stake
   * @param status true/false
   * @param stakingId stake id for that particular stake
   */
  function blacklistStake(bool status,uint256 stakingId) external onlyOwner{
    _TokenTransactionstatus[stakingId] = status;
  }

  /**
   * @dev function to get total ethers in contract
   */
    function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
    }

  /** 
   * @dev function to withdraw total ethers from contract
   */
    function withdrawETH() external onlyOwner returns(bool){
    msg.sender.transfer(address(this).balance);
    return true;
    }

 
/*
   * -------------------------------------------------------------------------------------
   * Functions for Staking Functionlaity
   * -------------------------------------------------------------------------------------
   */

  /**
   * @dev Function to get Final Withdraw Staked value
   * @param id stake id for the stake
   */
  function getFinalWithdrawlStake(uint256 id) public view returns(uint256){
    return _finalWithdrawlStake[id];
  }

  /**
   * @dev Function to get Staking address by id
   * @param id stake id for the stake
   */
  function getStakingAddressById(uint256 id) public view returns (address){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakerAddress[id];
  }
  
  /**
   * @dev Function to get Staking Starting time by id
   * @param id stake id for the stake
   */
  function getStakingStartTimeById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _stakingStartTime[id];
  }
  
  /**
   * @dev Function to get Staking tokens by id
   * @param id stake id for the stake
   */
  function getStakingTokenById(uint256 id)public view returns(uint256){
    require(id <= _stakingCount,"Unable to reterive data on specified id, Please try again!!");
    return _usersTokens[id];
  }
  
 /**
   * @dev Function to get active Staking tokens by id
   * @param id stake id for the stake
   */
  function getActiveStakesById(uint256 id)public view returns(address){
    return _stakerAddress[id];
  }

  /**
   * @dev Function to get Token lockstatus by id
   * @param id stake id for the stake
   */
  function getTokenLockstatus(uint256 id)public view returns(bool){
    return _TokenTransactionstatus[id];
  }

  /**
   * @dev Function to get staking count
   */
  function getStakingCount() public view returns(uint256){
      return _stakingCount;
  }

  /**
   * @dev Function to get Rewards on the stake
   * @param id stake id for the stake
   */
  function getRewardsDetailsOfUserById(uint256 id) public view returns(uint256){
     // return (_usersTokens[id].mul(_rewardPercentage).mul((block.timestamp - _stakingStartTime[id])/86400)).div(36500);
        return (_usersTokens[id].mul(_rewardPercentage));  
  }

  /**
   * @dev Function for setting withdraw time limit by owner
   * @param withdrawLimit Withdraw Limit
   */
  function setWithdrawLimit(uint256 withdrawLimit) public onlyOwner returns(bool){
    require(withdrawLimit > 0, "Invalid Time");
    _withdrawLimit = withdrawLimit;
    return true;
  }

  /**
   * @dev Function for getting withdraw limit by owner
   */
  function getWithdrawLimit() public view returns(uint256){
    return _withdrawLimit;
  }

  /**
   * @dev Function to performs staking for user tokens for a specific period of time
   * @param tokens number of tokens
   */
  function performStaking(uint256 tokens) public failSafe returns(bool){
    require(tokens > 0, "tokens cannot be zero");  
    _stakingCount = _stakingCount +1 ;
    _stakerAddress[_stakingCount] = msg.sender;
    _stakingStartTime[_stakingCount] = block.timestamp;
    _usersTokens[_stakingCount] = tokens;
    _TokenTransactionstatus[_stakingCount] = false;
    _transfer(msg.sender, _tokenPoolAddress, tokens);
    return true;
  }

  /**
   * @dev Function for withdrawing staked tokens
   * @param stakingId stake id for the stake
   */
  function withdrawStakedTokens(uint256 stakingId) public failSafe returns(bool){
    require(_stakerAddress[stakingId] == msg.sender,"No staked token found on this address and ID");
    require(_TokenTransactionstatus[stakingId] != true,"Either tokens are already withdrawn or blocked by admin");
    require(balanceOf(_tokenPoolAddress) >= _usersTokens[stakingId], "Pool is dry, can not perform transaction");
    _TokenTransactionstatus[stakingId] = true;
        if (block.timestamp > _stakingStartTime[_stakingCount].add(_withdrawLimit)){
          _finalWithdrawlStake[stakingId] = _usersTokens[stakingId] +getRewardsDetailsOfUserById(stakingId);
        _transfer(_tokenPoolAddress, msg.sender, _usersTokens[stakingId]);
        _transfer(_owner, msg.sender, getRewardsDetailsOfUserById(stakingId));
        }
        else {
         _transfer(_tokenPoolAddress, msg.sender, _usersTokens[stakingId]); 
        }
    return true;
  }

/*
 * -------------------------------------------------------------------------------------
 * Functions for Governance Functionality
 * -------------------------------------------------------------------------------------
 */

  // Map a proposal ID to a specific proposal
  mapping(uint256 => Proposal) public proposals;
  // Map a proposal ID to a voter's address and their vote
  mapping(uint256 => mapping(address => bool)) public voted;
  // Determine if the user is blocked from voting
  mapping (address => uint256) public blocked;
  mapping (address => bool) public isBlocked;
  mapping (uint256 => mapping (address => bool)) public votes;
  
  uint256 public proposalIDcount = 0;
  struct Proposal {
    address submitter;
    uint256 votingDeadline;
    uint256 inFavour;
    uint256 inAgainst;
  }

event VotesSubmitted (uint256 _proposalID);
event ProposalSubmitted(uint256 proposalId);

/** 
 * @dev Modifier to check if a user account is blocked
 */
    modifier whenNotBlocked(address _account) {
      require(!isBlocked[_account]);
      _;
    }

/** 
 * @dev Function to blacklist any address
 * @param status true/false
 * @param _account _account address for that particular user
 */
  function blacklistAddresses(bool status, address _account) external onlyOwner {
    isBlocked[_account] = status;
  }

/**
 * @dev Allows a token holder to submit a proposal to vote on
 * @param voteLength time limit for the voting
 */
  function submitProposal(uint256 voteLength) public onlyOwner returns (uint256) {
    _transfer(msg.sender, _owner, 10**_decimal);
    uint256 proposalID = addProposal(msg.sender, voteLength);
    emit ProposalSubmitted(proposalID);
    return proposalID;
  }


/**
 * @dev Adds a new proposal to the proposal mapping
 * @param Submitter address of the submitter who is submitting the proposal
 * @param voteLength time limit for the voting
 */
  function addProposal(address Submitter, uint256 voteLength) internal returns (uint256) {
   
    uint256 ID = proposalIDcount;
    proposals[ID] = Proposal({
    inFavour: 0,
    inAgainst: 0,
    submitter: Submitter,
    votingDeadline: block.timestamp + voteLength
     });
    proposalIDcount = proposalIDcount.add(1);
    return ID;
  }

/**
 * @dev Allows token holders to submit their votes in favor of a specific proposalID
 * @param _proposalID The proposal ID the token holder is voting on
 */  
  function submitVote(uint256 _proposalID, bool vote) whenNotBlocked(msg.sender) public returns (bool){
    require(voted[_proposalID][msg.sender] == false, "Already voted");
    Proposal memory p = proposals[_proposalID];
    require(p.votingDeadline > block.timestamp, "Voting time over");
    if (blocked[msg.sender] == 0) {
      blocked[msg.sender] = _proposalID;
    } else if (p.votingDeadline >   proposals[blocked[msg.sender]].votingDeadline) 
    {       
      blocked[msg.sender] = _proposalID;
    }
  
    _transfer(msg.sender, _owner, 10**_decimal);
    
    _burn(_owner, 10**_decimal);

    voted[_proposalID][msg.sender] = true;

    if (vote == true){
       proposals[_proposalID].inFavour++;
       votes[_proposalID][msg.sender] = true;   
    }
    else {
    proposals[_proposalID].inAgainst ++;
    votes[_proposalID][msg.sender] = false;
    }

     emit VotesSubmitted(
        _proposalID); 

    return true;
  }

/**
 * @dev Allows to get status of a proposal for a specific proposalID
 * @param _proposalID The proposal ID the proposal
 */  
function getProposalStatus(uint256 _proposalID) public view returns(bool){
require(proposals[_proposalID].votingDeadline < block.timestamp, "Voting time is not over");   
 if (proposals[_proposalID].inFavour > proposals[_proposalID].inAgainst){
return true;
}
    else{
return false;
        }
    }
}