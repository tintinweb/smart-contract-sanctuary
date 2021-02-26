/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

//*****************************************************************************//
//                        Coin Name : CORE                                    //
//                           Symbol : CORE                                    //
//                     Total Supply : 10,000,000                              //
//                         Decimals : 18                                      //
//                    Functionality :                                         //
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

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function latestAnswer() external view returns (int256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract IDelegate {
  function balanceOf(address) public pure returns (uint256){}
  function decimals() public pure returns (uint8){}
  function transferFrom (address from, address to, uint256 value) external returns (bool){}
      
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
* @title Core Contract For ERC20 Tokens
* @dev Core tokens as per ERC20 Standards
*/
contract Core is IERC20 {

  using SafeMath for uint256;

  address private _owner;                         // Owner of the Contract.
  string  private _name;                          // Name of the token.
  string  private _symbol;                        // symbol of the token.
  uint8   private _decimal;                      // variable to maintain decimal precision of the token.
  uint256 private _totalSupply;                   // total supply of token.
  bool    private _stopped = false;               // state variable to check fail-safe for contract.
  address private _tokenPoolAddress;              // Pool Address to manage Staking user's Token.
  uint256 private _tokenPriceETH=100;             // Set price of token with respect to ETH.
  uint256 public airdropcount = 0;                // Variable to keep track on number of airdrop
    
  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => address) public whitelistAddresses;
  constructor (string memory Name, string memory Symbol, uint8 Decimal, uint256 TotalSupply, address Owner, address TokenPoolAddress) {
    _name = Name;
    _symbol = Symbol;
    _decimal = Decimal;
    _totalSupply = TotalSupply*(10**uint256(Decimal));
    _balances[Owner] = _totalSupply;
    _owner = Owner;
    _tokenPoolAddress = TokenPoolAddress;
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

  function whitelistAddressesForBuyTokens(address oracleContract, address delegateContract) public onlyOwner returns(bool){
    whitelistAddresses[delegateContract] = oracleContract;
    return true;
}
      
  /*
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

  /*
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   * Transfer, allow, mint and burn functions
   * ----------------------------------------------------------------------------------------------------------------------------------------------
   */

  /*
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

  function _mint(uint256 _value,address _tokenOwner) internal returns(bool){
    _balances[_tokenOwner] = _balances[_tokenOwner].add(_value);
    _totalSupply = _totalSupply.add(_value);
    emit Transfer(address(0), _tokenOwner, _value);
    return true;
  }


  /**
   * Get ETH balance from this contract
   */
  function getContractETHBalance() public view returns(uint256){
    return(address(this).balance);
  }

   // To check for the payable amount for purchasing the tokens
  modifier payableCheck(){
    require(msg.value > 0 ,
      "Can not buy tokens,");
    _;
  }

    /**
   * @dev modifier to check the failsafe
   */
  modifier failSafe(){
    require(_stopped == false, "Fail Safe check failed");
    _;
  }
AggregatorV3Interface internal priceFeed;

function buyTokens() external failSafe payable payableCheck returns(bool){
    require(balanceOf(_owner) >= msg.value * _tokenPriceETH/1000000000000000000*1);
    transferFrom(_owner, msg.sender, msg.value * _tokenPriceETH);
    return true;
  }

  function buyTokensByERC20(address delegateContract, uint256 value) external failSafe returns(bool){
      IDelegate delegate = IDelegate(delegateContract);
      delegate.transferFrom(msg.sender, _owner, value);
      priceFeed = AggregatorV3Interface(whitelistAddresses[delegateContract]);
      (
             
            int price
            
        ) = priceFeed.latestAnswer();
      uint256 token = value * uint256(price) / _tokenPriceETH;
      transferFrom(_owner, msg.sender, token);
    return true;  
  }
  // Map a proposal ID to a specific proposal
  mapping(uint => Proposal) public proposals;
  // Map a proposal ID to a voter's address and their vote
  mapping(uint => mapping(address => bool)) public voted;
  // Determine if the user is blocked from voting
  mapping (address => uint) public blocked;
  mapping (address => bool) public isBlocked;
  mapping (uint => uint256) private votesNeeded;
  
  struct Proposal {
    uint votesReceived;
    bool passed;
    address submitter;
    uint votingDeadline;
    uint256 maxVotesNeeded;
  }

event VotesSubmitted (uint _proposalID, uint votesReceived, bool proposalPassed);
event ProposalSubmitted(uint proposalId);
  
  // @dev Modifier to check if a user account is blocked
    modifier whenNotBlocked(address _account) {
      require(!isBlocked[_account]);
      _;
    }

  /*
   * @dev Function to blacklist any address
   * @param status true/false
   * @param _account _account address for that particular user
   */
  function blacklistAddresses(bool status, address _account) external onlyOwner {
    isBlocked[_account] = status;
  }

//   function setvotesRequired (uint votecount) external returns (bool) {
//   require(votecount != 0);
//   votesNeeded = votecount;
//   return true;
// }

// function getvotesRequired() public view returns(uint){
//  return votesNeeded; 
// }

// @dev Allows a token holder to submit a proposal to vote on
  function submitProposal(uint256 maxVotesNeeded, uint256 voteLength) public onlyEligibleVoter(msg.sender) whenNotBlocked(msg.sender) returns (uint proposalID) {
    uint votesReceived = balanceOf(msg.sender);
    proposalID = addProposal(votesReceived, msg.sender, maxVotesNeeded, voteLength);
    votesNeeded[proposalID] = maxVotesNeeded;
    emit ProposalSubmitted(proposalID);
    return proposalID;
  }

  modifier onlyEligibleVoter(address _voter) {
  uint balance = balanceOf(_voter);
   require(balance > 0);
  _;
}

// @dev Adds a new proposal to the proposal mapping
// @param _votesReceived from the user submitting the proposal
  function addProposal(uint _votesReceived, address Submitter, uint256 maxVotesNeeded, uint256 voteLength) internal returns (uint proposalID) {
   uint votes = _votesReceived;
   uint proposalIDcount;
   if (votes < maxVotesNeeded) {
      if (proposalIDcount == 0) {
        proposalIDcount = 1;
      }
    proposalID = proposalIDcount;
    proposals[proposalID] = Proposal({
    votesReceived: votes,
    passed: false,
    submitter: Submitter,
    votingDeadline: block.timestamp + voteLength,
    maxVotesNeeded: maxVotesNeeded
     });
    blocked[Submitter] = proposalID;
    voted[proposalID][Submitter] = true;
    proposalIDcount = proposalIDcount.add(1);
    return proposalID;
   }
   else {
    require(balanceOf(Submitter) >= maxVotesNeeded);
    endVote(proposalID);
    return proposalID;
   }
  }

// @dev Allows token holders to submit their votes in favor of a specific proposalID
// @param _proposalID The proposal ID the token holder is voting on
  
  function submitVote(uint _proposalID) onlyEligibleVoter(msg.sender) whenNotBlocked(msg.sender) public returns (bool){
    Proposal memory p = proposals[_proposalID];
    if (blocked[msg.sender] == 0) {
      blocked[msg.sender] = _proposalID;
    } else if (p.votingDeadline >   proposals[blocked[msg.sender]].votingDeadline) 
    {
// this proposal's voting deadline is further into the future than
// the proposal that blocks the sender, so make it the blocker       
      blocked[msg.sender] = _proposalID;
    }
    uint votesReceived = balanceOf(msg.sender);

    proposals[_proposalID].votesReceived += votesReceived;
    voted[_proposalID][msg.sender] = true;
    if (proposals[_proposalID].votesReceived >= votesNeeded[_proposalID]) 
    {
      proposals[_proposalID].passed = true;
      emit VotesSubmitted(
        _proposalID, 
        votesReceived, 
        proposals[_proposalID].passed
      );
      endVote(_proposalID);
    }
    emit VotesSubmitted(
      _proposalID, 
      votesReceived, 
      proposals[_proposalID].passed
    );
    return true;
  }
  
// @dev Sets when a particular vote will end
// @param _proposalID The specific proposal's ID
  function endVote(uint _proposalID) internal { 
    require(voteSuccessOrFail(_proposalID));
    updateProposalToPassed(_proposalID);
  }

  /// @dev Determines whether or not a particular vote has passed or failed
/// @param _proposalID The proposal ID to check
/// @return Returns whether or not a particular vote has passed or failed
  function voteSuccessOrFail(uint _proposalID) public view returns (bool) {
    return proposals[_proposalID].passed;
  }

  function updateProposalToPassed (uint _proposalID) internal returns (bool){
    proposals[_proposalID].passed = true;
    return true;
  }
}