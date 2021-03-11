// Copyright (c) 2020 The UNION Protocol Foundation
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./EnumerableSet.sol";

/**
 * @title UNION Protocol Governance Token
 * @dev Implementation of the basic standard token.
 */
contract UnionGovernanceToken is AccessControl, IERC20 {

  using Address for address;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice Struct for marking number of votes from a given block
   * @member from
   * @member votes
   */
  struct VotingCheckpoint {
    uint256 from;
    uint256 votes;
  }
 
  /**
   * @notice Struct for locked tokens
   * @member amount
   * @member releaseTime
   * @member votable
   */
  struct LockedTokens{
    uint amount;
    uint releaseTime;
    bool votable;
  }

  /**
  * @notice Struct for EIP712 Domain
  * @member name
  * @member version
  * @member chainId
  * @member verifyingContract
  * @member salt
  */
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
  }

  /**
  * @notice Struct for EIP712 VotingDelegate call
  * @member owner
  * @member delegate
  * @member nonce
  * @member expirationTime
  */
  struct VotingDelegate {
    address owner;
    address delegate;
    uint256 nonce;
    uint256 expirationTime;
  }

  /**
  * @notice Struct for EIP712 Permit call
  * @member owner
  * @member spender
  * @member value
  * @member nonce
  * @member deadline
  */
  struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
  }

  /**
   * @notice Vote Delegation Events
   */
  event VotingDelegateChanged(address indexed _owner, address indexed _fromDelegate, address indexed _toDelegate);
  event VotingDelegateRemoved(address indexed _owner);
  
  /**
   * @notice Vote Balance Events
   * Emmitted when a delegate account's vote balance changes at the time of a written checkpoint
   */
  event VoteBalanceChanged(address indexed _account, uint256 _oldBalance, uint256 _newBalance);

  /**
   * @notice Transfer/Allocator Events
   */
  event TransferStatusChanged(bool _newTransferStatus);

  /**
   * @notice Reversion Events
   */
  event ReversionStatusChanged(bool _newReversionSetting);

  /**
   * @notice EIP-20 Approval event
   */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
  /**
   * @notice EIP-20 Transfer event
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Burn(address indexed _from, uint256 _value);
  event AddressPermitted(address indexed _account);
  event AddressRestricted(address indexed _account);

  /**
   * @dev AccessControl recognized roles
   */
  bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
  bytes32 public constant ROLE_ALLOCATE = keccak256("ROLE_ALLOCATE");
  bytes32 public constant ROLE_GOVERN = keccak256("ROLE_GOVERN");
  bytes32 public constant ROLE_MINT = keccak256("ROLE_MINT");
  bytes32 public constant ROLE_LOCK = keccak256("ROLE_LOCK");
  bytes32 public constant ROLE_TRUSTED = keccak256("ROLE_TRUSTED");
  bytes32 public constant ROLE_TEST = keccak256("ROLE_TEST");
   
  bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
  );
  bytes32 public constant DELEGATE_TYPEHASH = keccak256(
    "DelegateVote(address owner,address delegate,uint256 nonce,uint256 expirationTime)"
  );

  //keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  address private constant BURN_ADDRESS = address(0);
  address public UPGT_CONTRACT_ADDRESS;

  /**
   * @dev hashes to support EIP-712 signing and validating, EIP712DOMAIN_SEPARATOR is set at time of contract instantiation and token minting.
   */
  bytes32 public immutable EIP712DOMAIN_SEPARATOR;

  /**
   * @dev EIP-20 token name
   */
  string public name = "UNION Protocol Governance Token";

  /**
   * @dev EIP-20 token symbol
   */
  string public symbol = "UNN";

  /**
   * @dev EIP-20 token decimals
   */
  uint8 public decimals = 18;

  /**
   * @dev Contract version
   */
  string public constant version = '0.0.1';

  /**
   * @dev Initial amount of tokens
   */
  uint256 private uint256_initialSupply = 100000000000 * 10**18;

  /**
   * @dev Total amount of tokens
   */
  uint256 private uint256_totalSupply;

  /**
   * @dev Chain id
   */
  uint256 private uint256_chain_id;

  /**
   * @dev general transfer restricted as function of public sale not complete
   */
  bool private b_canTransfer = false;

  /**
   * @dev private variable that determines if failed EIP-20 functions revert() or return false.  Reversion short-circuits the return from these functions.
   */
  bool private b_revert = false; //false allows false return values

  /**
   * @dev Locked destinations list
   */
  mapping(address => bool) private m_lockedDestinations;

  /**
   * @dev EIP-20 allowance and balance maps
   */
  mapping(address => mapping(address => uint256)) private m_allowances;
  mapping(address => uint256) private m_balances;
  mapping(address => LockedTokens[]) private m_lockedBalances;

  /**
   * @dev nonces used by accounts to this contract for signing and validating signatures under EIP-712
   */
  mapping(address => uint256) private m_nonces;

  /**
   * @dev delegated account may for off-line vote delegation
   */
  mapping(address => address) private m_delegatedAccounts;

  /**
   * @dev delegated account inverse map is needed to live calculate voting power
   */
  mapping(address => EnumerableSet.AddressSet) private m_delegatedAccountsInverseMap;


  /**
   * @dev indexed mapping of vote checkpoints for each account
   */
  mapping(address => mapping(uint256 => VotingCheckpoint)) private m_votingCheckpoints;

  /**
   * @dev mapping of account addrresses to voting checkpoints
   */
  mapping(address => uint256) private m_accountVotingCheckpoints;

  /**
   * @dev Contructor for the token
   * @param _owner address of token contract owner
   * @param _initialSupply of tokens generated by this contract
   * Sets Transfer the total suppply to the owner.
   * Sets default admin role to the owner.
   * Sets ROLE_ALLOCATE to the owner.
   * Sets ROLE_GOVERN to the owner.
   * Sets ROLE_MINT to the owner.
   * Sets EIP 712 Domain Separator.
   */
  constructor(address _owner, uint256 _initialSupply) public {
    
    //set internal contract references
    UPGT_CONTRACT_ADDRESS = address(this);

    //setup roles using AccessControl
    _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    _setupRole(ROLE_ADMIN, _owner);
    _setupRole(ROLE_ADMIN, _msgSender());
    _setupRole(ROLE_ALLOCATE, _owner);
    _setupRole(ROLE_ALLOCATE, _msgSender());
    _setupRole(ROLE_TRUSTED, _owner);
    _setupRole(ROLE_TRUSTED, _msgSender());
    _setupRole(ROLE_GOVERN, _owner);
    _setupRole(ROLE_MINT, _owner);
    _setupRole(ROLE_LOCK, _owner);
    _setupRole(ROLE_TEST, _owner);

    m_balances[_owner] = _initialSupply;
    uint256_totalSupply = _initialSupply;
    b_canTransfer = false;
    uint256_chain_id = _getChainId();

    EIP712DOMAIN_SEPARATOR = _hash(EIP712Domain({
        name : name,
        version : version,
        chainId : uint256_chain_id,
        verifyingContract : address(this),
        salt : keccak256(abi.encodePacked(name))
      }
    ));
   
    emit Transfer(BURN_ADDRESS, _owner, uint256_totalSupply);
  }

    /**
   * @dev Sets transfer status to lock token transfer
   * @param _canTransfer value can be true or false.
   * disables transfer when set to false and enables transfer when true
   * Only a member of ADMIN role can call to change transfer status
   */
  function setCanTransfer(bool _canTransfer) public {
    if(hasRole(ROLE_ADMIN, _msgSender())){
      b_canTransfer = _canTransfer;
      emit TransferStatusChanged(_canTransfer);
    }
  }

  /**
   * @dev Gets status of token transfer lock
   * @return true or false status of whether the token can be transfered
   */
  function getCanTransfer() public view returns (bool) {
    return b_canTransfer;
  }

  /**
   * @dev Sets transfer reversion status to either return false or throw on error
   * @param _reversion value can be true or false.
   * disables return of false values for transfer failures when set to false and enables transfer-related exceptions when true
   * Only a member of ADMIN role can call to change transfer reversion status
   */
  function setReversion(bool _reversion) public {
    if(hasRole(ROLE_ADMIN, _msgSender()) || 
       hasRole(ROLE_TEST, _msgSender())
    ) {
      b_revert = _reversion;
      emit ReversionStatusChanged(_reversion);
    }
  }

  /**
   * @dev Gets status of token transfer reversion
   * @return true or false status of whether the token transfer failures return false or are reverted
   */
  function getReversion() public view returns (bool) {
    return b_revert;
  }

  /**
   * @dev retrieve current chain id
   * @return chain id
   */
  function getChainId() public pure returns (uint256) {
    return _getChainId();
  }

  /**
   * @dev Retrieve current chain id
   * @return chain id
   */
  function _getChainId() internal pure returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * @dev Retrieve total supply of tokens
   * @return uint256 total supply of tokens
   */
  function totalSupply() public view override returns (uint256) {
    return uint256_totalSupply;
  }

  /**
   * Balance related functions
   */

  /**
   * @dev Retrieve balance of a specified account
   * @param _account address of account holding balance
   * @return uint256 balance of the specified account address
   */
  function balanceOf(address _account) public view override returns (uint256) {
    return m_balances[_account].add(_calculateReleasedBalance(_account));
  }

  /**
   * @dev Retrieve locked balance of a specified account
   * @param _account address of account holding locked balance
   * @return uint256 locked balance of the specified account address
   */
  function lockedBalanceOf(address _account) public view returns (uint256) {
    return _calculateLockedBalance(_account);
  }

  /**
   * @dev Retrieve lenght of locked balance array for specific address
   * @param _account address of account holding locked balance
   * @return uint256 locked balance array lenght
   */
  function getLockedTokensListSize(address _account) public view returns (uint256){
    require(_msgSender() == _account || hasRole(ROLE_ADMIN, _msgSender()) || hasRole(ROLE_TRUSTED, _msgSender()), "UPGT_ERROR: insufficient permissions");
    return m_lockedBalances[_account].length;
  }

  /**
   * @dev Retrieve locked tokens struct from locked balance array for specific address
   * @param _account address of account holding locked tokens
   * @param _index index in array with locked tokens position
   * @return amount of locked tokens
   * @return releaseTime descibes time when tokens will be unlocked
   * @return votable flag is describing votability of tokens
   */
  function getLockedTokens(address _account, uint256 _index) public view returns (uint256 amount, uint256 releaseTime, bool votable){
    require(_msgSender() == _account || hasRole(ROLE_ADMIN, _msgSender()) || hasRole(ROLE_TRUSTED, _msgSender()), "UPGT_ERROR: insufficient permissions");
    require(_index < m_lockedBalances[_account].length, "UPGT_ERROR: LockedTokens position doesn't exist on given index");
    LockedTokens storage lockedTokens = m_lockedBalances[_account][_index];
    return (lockedTokens.amount, lockedTokens.releaseTime, lockedTokens.votable);
  }

  /**
   * @dev Calculates locked balance of a specified account
   * @param _account address of account holding locked balance
   * @return uint256 locked balance of the specified account address
   */
  function _calculateLockedBalance(address _account) private view returns (uint256) {
    uint256 lockedBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime > block.timestamp){
        lockedBalance = lockedBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return lockedBalance;
  }

  /**
   * @dev Calculates released balance of a specified account
   * @param _account address of account holding released balance
   * @return uint256 released balance of the specified account address
   */
  function _calculateReleasedBalance(address _account) private view returns (uint256) {
    uint256 releasedBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime <= block.timestamp){
          releasedBalance = releasedBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return releasedBalance;
  }

  /**
   * @dev Calculates locked votable balance of a specified account
   * @param _account address of account holding locked votable balance
   * @return uint256 locked votable balance of the specified account address
   */
  function _calculateLockedVotableBalance(address _account) private view returns (uint256) {
    uint256 lockedVotableBalance = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].votable == true){
        lockedVotableBalance = lockedVotableBalance.add(m_lockedBalances[_account][i].amount);
      }
    }
    return lockedVotableBalance;
  }

  /**
   * @dev Moves released balance to normal balance for a specified account
   * @param _account address of account holding released balance
   */
  function _moveReleasedBalance(address _account) internal virtual{
    uint256 releasedToMove = 0;
    for (uint i=0; i<m_lockedBalances[_account].length; i++) {
      if(m_lockedBalances[_account][i].releaseTime <= block.timestamp){
        releasedToMove = releasedToMove.add(m_lockedBalances[_account][i].amount);
        m_lockedBalances[_account][i] = m_lockedBalances[_account][m_lockedBalances[_account].length - 1];
        m_lockedBalances[_account].pop();
      }
    }
    m_balances[_account] = m_balances[_account].add(releasedToMove);
  }

  /**
   * Allowance related functinons
   */

  /**
   * @dev Retrieve the spending allowance for a token holder by a specified account
   * @param _owner Token account holder
   * @param _spender Account given allowance
   * @return uint256 allowance value
   */
  function allowance(address _owner, address _spender) public override virtual view returns (uint256) {
    return m_allowances[_owner][_spender];
  }

  /**
   * @dev Message sender approval to spend for a specified amount
   * @param _spender address of party approved to spend
   * @param _value amount of the approval 
   * @return boolean success status 
   * public wrapper for _approve, _owner is msg.sender
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    bool success = _approveUNN(_msgSender(), _spender, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: APPROVE ERROR");
    }
    return success;
  }
  
  /**
   * @dev Token owner approval of amount for specified spender
   * @param _owner address of party that owns the tokens being granted approval for spending
   * @param _spender address of party that is granted approval for spending
   * @param _value amount approved for spending
   * @return boolean approval status
   * if _spender allownace for a given _owner is greater than 0, 
   * increaseAllowance/decreaseAllowance should be used to prevent a race condition whereby the spender is able to spend the total value of both the old and new allowance.  _spender cannot be burn or this governance token contract address.  Addresses github.com/ethereum/EIPs/issues738
   */
  function _approveUNN(address _owner, address _spender, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
      _spender != UPGT_CONTRACT_ADDRESS &&
      (m_allowances[_owner][_spender] == 0 || _value == 0)
    ){
      m_allowances[_owner][_spender] = _value;
      emit Approval(_owner, _spender, _value);
      retval = true;
    }
    return retval;
  }

  /**
   * @dev Increase spender allowance by specified incremental value
   * @param _spender address of party that is granted approval for spending
   * @param _addedValue specified incremental increase
   * @return boolean increaseAllowance status
   * public wrapper for _increaseAllowance, _owner restricted to msg.sender
   */
  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    bool success = _increaseAllowanceUNN(_msgSender(), _spender, _addedValue);
    if(!success && b_revert){
      revert("UPGT_ERROR: INCREASE ALLOWANCE ERROR");
    }
    return success;
  }

  /**
   * @dev Allow owner to increase spender allowance by specified incremental value
   * @param _owner address of the token owner
   * @param _spender address of the token spender
   * @param _addedValue specified incremental increase
   * @return boolean return value status
   * increase the number of tokens that an _owner provides as allowance to a _spender-- does not requrire the number of tokens allowed to be set first to 0.  _spender cannot be either burn or this goverance token contract address.
   */
  function _increaseAllowanceUNN(address _owner, address _spender, uint256 _addedValue) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
      _spender != UPGT_CONTRACT_ADDRESS &&
      _addedValue > 0
    ){
      m_allowances[_owner][_spender] = m_allowances[_owner][_spender].add(_addedValue);
      retval = true;
      emit Approval(_owner, _spender, m_allowances[_owner][_spender]);
    }
    return retval;
  }

  /**
   * @dev Decrease spender allowance by specified incremental value
   * @param _spender address of party that is granted approval for spending
   * @param _subtractedValue specified incremental decrease
   * @return boolean success status
   * public wrapper for _decreaseAllowance, _owner restricted to msg.sender
   */
  //public wrapper for _decreaseAllowance, _owner restricted to msg.sender
  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    bool success = _decreaseAllowanceUNN(_msgSender(), _spender, _subtractedValue);
    if(!success && b_revert){
      revert("UPGT_ERROR: DECREASE ALLOWANCE ERROR");
    }
    return success;
  } 

  /**
   * @dev Allow owner to decrease spender allowance by specified incremental value
   * @param _owner address of the token owner
   * @param _spender address of the token spender
   * @param _subtractedValue specified incremental decrease
   * @return boolean return value status
   * decrease the number of tokens than an _owner provdes as allowance to a _spender.  A _spender cannot have a negative allowance.  Does not require existing allowance to be set first to 0.  _spender cannot be burn or this governance token contract address.
   */
  function _decreaseAllowanceUNN(address _owner, address _spender, uint256 _subtractedValue) internal returns (bool) {
    bool retval = false;
    if(_spender != BURN_ADDRESS &&
       _spender != UPGT_CONTRACT_ADDRESS &&
      _subtractedValue > 0 &&
      m_allowances[_owner][_spender] >= _subtractedValue
    ){
      m_allowances[_owner][_spender] = m_allowances[_owner][_spender].sub(_subtractedValue);
      retval = true;
      emit Approval(_owner, _spender, m_allowances[_owner][_spender]);
    }
    return retval;
  }

  /**
   * LockedDestination related functions
   */

  /**
   * @dev Adds address as a designated destination for tokens when locked for allocation only
   * @param _address Address of approved desitnation for movement during lock
   * @return success in setting address as eligible for transfer independent of token lock status
   */
  function setAsEligibleLockedDestination(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      m_lockedDestinations[_address] = true;
      retVal = true;
    }
    return retVal;
  }

  /**
   * @dev removes desitnation as eligible for transfer
   * @param _address address being removed
   */
  function removeEligibleLockedDestination(address _address) public {
    if(hasRole(ROLE_ADMIN, _msgSender())){
      require(_address != BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");
      delete(m_lockedDestinations[_address]);
    }
  }

  /**
   * @dev checks whether a destination is eligible as recipient of transfer independent of token lock status
   * @param _address address being checked
   * @return whether desitnation is locked
   */
  function checkEligibleLockedDesination(address _address) public view returns (bool) {
    return m_lockedDestinations[_address];
  }

  /**
   * @dev Adds address as a designated allocator that can move tokens when they are locked
   * @param _address Address receiving the role of ROLE_ALLOCATE
   * @return success as true or false
   */
  function setAsAllocator(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      grantRole(ROLE_ALLOCATE, _address);
      retVal = true;
    }
    return retVal;
  }
  
  /**
   * @dev Removes address as a designated allocator that can move tokens when they are locked
   * @param _address Address being removed from the ROLE_ALLOCATE
   * @return success as true or false
   */
  function removeAsAllocator(address _address) public returns (bool) {
    bool retVal = false;
    if(hasRole(ROLE_ADMIN, _msgSender())){
      if(hasRole(ROLE_ALLOCATE, _address)){
        revokeRole(ROLE_ALLOCATE, _address);
        retVal = true;
      }
    }
    return retVal;
  }

  /**
   * @dev Checks to see if an address has the role of being an allocator
   * @param _address Address being checked for ROLE_ALLOCATE
   * @return true or false whether the address has ROLE_ALLOCATE assigned
   */
  function checkAsAllocator(address _address) public view returns (bool) {
    return hasRole(ROLE_ALLOCATE, _address);
  }

  /**
   * Transfer related functions
   */

  /**
   * @dev Public wrapper for transfer function to move tokens of specified value to a given address
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @return status of transfer success
   */
  function transfer(address _to, uint256 _value) external override returns (bool) {
    bool success = _transferUNN(_msgSender(), _to, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER");
    }
    return success;
  }

  /**
   * @dev Transfer token for a specified address, but cannot transfer tokens to either the burn or this governance contract address.  Also moves voting delegates as required.
   * @param _owner The address owner where transfer originates
   * @param _to The address to transfer to
   * @param _value The amount to be transferred
   * @return status of transfer success
   */
  function _transferUNN(address _owner, address _to, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
         _to != BURN_ADDRESS &&
         _to != UPGT_CONTRACT_ADDRESS &&
         (balanceOf(_owner) >= _value) &&
         (_value >= 0)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_balances[_to] = m_balances[_to].add(_value);
        retval = true;
        //need to move voting delegates with transfer of tokens
        retval = retval && _moveVotingDelegates(m_delegatedAccounts[_owner], m_delegatedAccounts[_to], _value);
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferAndLock function to move tokens of specified value to a given address and lock them for a period of time
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   * Requires ROLE_LOCK
   */
  function transferAndLock(address _to, uint256 _value, uint256 _releaseTime, bool _votable) public virtual returns (bool) {
    bool retval = false;
    if(hasRole(ROLE_LOCK, _msgSender())){
      retval = _transferAndLock(msg.sender, _to, _value, _releaseTime, _votable);
    }
   
    if(!retval && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER AND LOCK");
    }
    return retval;
  }

  /**
   * @dev Transfers tokens of specified value to a given address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   */
  function _transferAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) internal virtual returns (bool){
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
         _to != BURN_ADDRESS &&
         _to != UPGT_CONTRACT_ADDRESS &&
         (balanceOf(_owner) >= _value) &&
         (_value >= 0)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_lockedBalances[_to].push(LockedTokens(_value, _releaseTime, _votable));
        retval = true;
        //need to move voting delegates with transfer of tokens
        // retval = retval && _moveVotingDelegates(m_delegatedAccounts[_owner], m_delegatedAccounts[_to], _value);  
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferFrom function
   * @param _owner The address to transfer from
   * @param _spender cannot be the burn address
   * @param _value The amount to be transferred
   * @return status of transferFrom success
   * _spender cannot be either this goverance token contract or burn
   */
  function transferFrom(address _owner, address _spender, uint256 _value) external override returns (bool) {
    bool success = _transferFromUNN(_owner, _spender, _value);
    if(!success && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER FROM");
    }
    return success;
  }

  /**
   * @dev Transfer token for a specified address.  _spender cannot be either this goverance token contract or burn
   * @param _owner The address to transfer from
   * @param _spender cannot be the burn address
   * @param _value The amount to be transferred
   * @return status of transferFrom success
   * _spender cannot be either this goverance token contract or burn
   */
  function _transferFromUNN(address _owner, address _spender, uint256 _value) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_spender)) {
      if(
        _spender != BURN_ADDRESS &&
        _spender != UPGT_CONTRACT_ADDRESS &&
        (balanceOf(_owner) >= _value) &&
        (_value > 0) &&
        (m_allowances[_owner][_msgSender()] >= _value)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_balances[_spender] = m_balances[_spender].add(_value);
        m_allowances[_owner][_msgSender()] = m_allowances[_owner][_msgSender()].sub(_value);
        retval = true;
        //need to move delegates that exist for this owner in line with transfer
        retval = retval && _moveVotingDelegates(_owner, _spender, _value); 
        emit Transfer(_owner, _spender, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public wrapper for transferFromAndLock function to move tokens of specified value from given address to another address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   * Requires ROLE_LOCK
   */
  function transferFromAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) public virtual returns (bool) {
     bool retval = false;
    if(hasRole(ROLE_LOCK, _msgSender())){
      retval = _transferFromAndLock(_owner, _to, _value, _releaseTime, _votable);
    }
   
    if(!retval && b_revert){
      revert("UPGT_ERROR: ERROR ON TRANSFER FROM AND LOCK");
    }
    return retval;
  }

  /**
   * @dev Transfers tokens of specified value from a given address to another address and lock them for a period of time
   * @param _owner The address owner where transfer originates
   * @param _to specified recipient
   * @param _value amount being transfered to recipient
   * @param _releaseTime time in seconds after amount will be released
   * @param _votable flag which describes if locked tokens are votable or not
   * @return status of transfer success
   */
  function _transferFromAndLock(address _owner, address _to, uint256 _value, uint256 _releaseTime, bool _votable) internal returns (bool) {
    bool retval = false;
    if(b_canTransfer || hasRole(ROLE_ALLOCATE, _msgSender()) || checkEligibleLockedDesination(_to)) {
      if(
        _to != BURN_ADDRESS &&
        _to != UPGT_CONTRACT_ADDRESS &&
        (balanceOf(_owner) >= _value) &&
        (_value > 0) &&
        (m_allowances[_owner][_msgSender()] >= _value)
      ){
        _moveReleasedBalance(_owner);
        m_balances[_owner] = m_balances[_owner].sub(_value);
        m_lockedBalances[_to].push(LockedTokens(_value, _releaseTime, _votable));
        m_allowances[_owner][_msgSender()] = m_allowances[_owner][_msgSender()].sub(_value);
        retval = true;
        //need to move delegates that exist for this owner in line with transfer
        // retval = retval && _moveVotingDelegates(_owner, _to, _value); 
        emit Transfer(_owner, _to, _value);
      }
    }
    return retval;
  }

  /**
   * @dev Public function to burn tokens
   * @param _value number of tokens to be burned
   * @return whether tokens were burned
   * Only ROLE_MINTER may burn tokens
   */
  function burn(uint256 _value) external returns (bool) {
    bool success = _burn(_value);
    if(!success && b_revert){
      revert("UPGT_ERROR: FAILED TO BURN");
    }
    return success;
  } 

  /**
   * @dev Private function Burn tokens
   * @param _value number of tokens to be burned
   * @return bool whether the tokens were burned
   * only a minter may burn tokens, meaning that tokens being burned must be previously send to a ROLE_MINTER wallet.
   */
  function _burn(uint256 _value) internal returns (bool) {
    bool retval = false;
    if(hasRole(ROLE_MINT, _msgSender()) &&
       (m_balances[_msgSender()] >= _value)
    ){
      m_balances[_msgSender()] -= _value;
      uint256_totalSupply = uint256_totalSupply.sub(_value);
      retval = true;
      emit Burn(_msgSender(), _value);
    }
    return retval;
  }

  /** 
  * Voting related functions
  */

  /**
   * @dev Public wrapper for _calculateVotingPower function which calulates voting power
   * @dev voting power = balance + locked votable balance + delegations
   * @return uint256 voting power
   */
  function calculateVotingPower() public view returns (uint256) {
    return _calculateVotingPower(_msgSender());
  }

  /**
   * @dev Calulates voting power of specified address
   * @param _account address of token holder
   * @return uint256 voting power
   */
  function _calculateVotingPower(address _account) private view returns (uint256) {
    uint256 votingPower = m_balances[_account].add(_calculateLockedVotableBalance(_account));
    for (uint i=0; i<m_delegatedAccountsInverseMap[_account].length(); i++) {
      if(m_delegatedAccountsInverseMap[_account].at(i) != address(0)){
        address delegatedAccount = m_delegatedAccountsInverseMap[_account].at(i);
        votingPower = votingPower.add(m_balances[delegatedAccount]).add(_calculateLockedVotableBalance(delegatedAccount));
      }
    }
    return votingPower;
  }

  /**
   * @dev Moves a number of votes from a token holder to a designated representative
   * @param _source address of token holder
   * @param _destination address of voting delegate
   * @param _amount of voting delegation transfered to designated representative
   * @return bool whether move was successful
   * Requires ROLE_TEST
   */
  function moveVotingDelegates(
    address _source,
    address _destination,
    uint256 _amount) public returns (bool) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _moveVotingDelegates(_source, _destination, _amount);
  }

  /**
   * @dev Moves a number of votes from a token holder to a designated representative
   * @param _source address of token holder
   * @param _destination address of voting delegate
   * @param _amount of voting delegation transfered to designated representative
   * @return bool whether move was successful
   */
  function _moveVotingDelegates(
      address _source, 
      address _destination, 
      uint256 _amount
  ) internal returns (bool) {
    if(_source != _destination && _amount > 0) {
      if(_source != BURN_ADDRESS) {
        uint256 sourceNumberOfVotingCheckpoints = m_accountVotingCheckpoints[_source];
        uint256 sourceNumberOfVotingCheckpointsOriginal = (sourceNumberOfVotingCheckpoints > 0)? m_votingCheckpoints[_source][sourceNumberOfVotingCheckpoints.sub(1)].votes : 0;
        if(sourceNumberOfVotingCheckpointsOriginal >= _amount) {
          uint256 sourceNumberOfVotingCheckpointsNew = sourceNumberOfVotingCheckpointsOriginal.sub(_amount);
          _writeVotingCheckpoint(_source, sourceNumberOfVotingCheckpoints, sourceNumberOfVotingCheckpointsOriginal, sourceNumberOfVotingCheckpointsNew);
        }
      }

      if(_destination != BURN_ADDRESS) {
        uint256 destinationNumberOfVotingCheckpoints = m_accountVotingCheckpoints[_destination];
        uint256 destinationNumberOfVotingCheckpointsOriginal = (destinationNumberOfVotingCheckpoints > 0)? m_votingCheckpoints[_source][destinationNumberOfVotingCheckpoints.sub(1)].votes : 0;
        uint256 destinationNumberOfVotingCheckpointsNew = destinationNumberOfVotingCheckpointsOriginal.add(_amount);
        _writeVotingCheckpoint(_destination, destinationNumberOfVotingCheckpoints, destinationNumberOfVotingCheckpointsOriginal, destinationNumberOfVotingCheckpointsNew);
      }
    }
    
    return true; 
  }

  /**
   * @dev Writes voting checkpoint for a given voting delegate
   * @param _votingDelegate exercising votes
   * @param _numberOfVotingCheckpoints number of voting checkpoints for current vote
   * @param _oldVotes previous number of votes
   * @param _newVotes new number of votes
   * Public function for writing voting checkpoint
   * Requires ROLE_TEST
   */
  function writeVotingCheckpoint(
    address _votingDelegate,
    uint256 _numberOfVotingCheckpoints,
    uint256 _oldVotes,
    uint256 _newVotes) public {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    _writeVotingCheckpoint(_votingDelegate, _numberOfVotingCheckpoints, _oldVotes, _newVotes);
  }

  /**
   * @dev Writes voting checkpoint for a given voting delegate
   * @param _votingDelegate exercising votes
   * @param _numberOfVotingCheckpoints number of voting checkpoints for current vote
   * @param _oldVotes previous number of votes
   * @param _newVotes new number of votes
   * Private function for writing voting checkpoint
   */
  function _writeVotingCheckpoint(
    address _votingDelegate, 
    uint256 _numberOfVotingCheckpoints, 
    uint256 _oldVotes, 
    uint256 _newVotes) internal {
    if(_numberOfVotingCheckpoints > 0 && m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints.sub(1)].from == block.number) {
      m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints-1].votes = _newVotes;
    }
    else {
      m_votingCheckpoints[_votingDelegate][_numberOfVotingCheckpoints] = VotingCheckpoint(block.number, _newVotes);
      _numberOfVotingCheckpoints = _numberOfVotingCheckpoints.add(1);
    }
    emit VoteBalanceChanged(_votingDelegate, _oldVotes, _newVotes);
  }

  /**
   * @dev Calculate account votes as of a specific block
   * @param _account address whose votes are counted
   * @param _blockNumber from which votes are being counted
   * @return number of votes counted
   */
  function getVoteCountAtBlock(
    address _account, 
    uint256 _blockNumber) public view returns (uint256) {
    uint256 voteCount = 0;
    if(_blockNumber < block.number) {
      if(m_accountVotingCheckpoints[_account] != 0) {
        if(m_votingCheckpoints[_account][m_accountVotingCheckpoints[_account].sub(1)].from <= _blockNumber) {
          voteCount = m_votingCheckpoints[_account][m_accountVotingCheckpoints[_account].sub(1)].votes;
        }
        else if(m_votingCheckpoints[_account][0].from > _blockNumber) {
          voteCount = 0;
        }
        else {
          uint256 lower = 0;
          uint256 upper = m_accountVotingCheckpoints[_account].sub(1);
          
          while(upper > lower) {
            uint256 center = upper.sub((upper.sub(lower).div(2)));
            VotingCheckpoint memory votingCheckpoint = m_votingCheckpoints[_account][center];
            if(votingCheckpoint.from == _blockNumber) {
              voteCount = votingCheckpoint.votes;
              break;
            }
            else if(votingCheckpoint.from < _blockNumber) {
              lower = center;
            }
            else {
              upper = center.sub(1);
            }
          
          }
        }
      }
    }
    return voteCount;
  }

  /**
   * @dev Vote Delegation Functions
   * @param _to address where message sender is assigning votes
   * @return success of message sender delegating vote
   * delegate function does not allow assignment to burn
   */
  function delegateVote(address _to) public returns (bool) {
    return _delegateVote(_msgSender(), _to);
  }

  /**
   * @dev Delegate votes from token holder to another address
   * @param _from Token holder 
   * @param _toDelegate Address that will be delegated to for purpose of voting
   * @return success as to whether delegation has been a success
   */
  function _delegateVote(
    address _from, 
    address _toDelegate) internal returns (bool) {
    bool retval = false;
    if(_toDelegate != BURN_ADDRESS) {
      address currentDelegate = m_delegatedAccounts[_from];
      uint256 fromAccountBalance = m_balances[_from].add(_calculateLockedVotableBalance(_from));
      address oldToDelegate = m_delegatedAccounts[_from];
      m_delegatedAccounts[_from] = _toDelegate;

      m_delegatedAccountsInverseMap[oldToDelegate].remove(_from);
      if(_from != _toDelegate){
        m_delegatedAccountsInverseMap[_toDelegate].add(_from);
      }

      retval = true;
      retval = retval && _moveVotingDelegates(currentDelegate, _toDelegate, fromAccountBalance);
      if(retval) {
        if(_from == _toDelegate){
          emit VotingDelegateRemoved(_from);
        }
        else{
          emit VotingDelegateChanged(_from, currentDelegate, _toDelegate);
        }
      }
    }
    return retval;
  }

  /**
   * @dev Revert voting delegate control to owner account
   * @param _account  The account that has delegated its vote
   * @return success of reverting delegation to owner
   */
  function _revertVotingDelegationToOwner(address _account) internal returns (bool) {
    return _delegateVote(_account, _account);
  }

  /**
   * @dev Used by an message sending account to recall its voting delegates
   * @return success of reverting delegation to owner
   */
  function recallVotingDelegate() public returns (bool) {
    return _revertVotingDelegationToOwner(_msgSender());
  }
  
  /**
   * @dev Retrieve the voting delegate for a specified account
   * @param _account  The account that has delegated its vote
   */ 
  function getVotingDelegate(address _account) public view returns (address) {
    return m_delegatedAccounts[_account];
  }

  /** 
  * EIP-712 related functions
  */

  /**
   * @dev EIP-712 Ethereum Typed Structured Data Hashing and Signing for Allocation Permit
   * @param _owner address of token owner
   * @param _spender address of designated spender
   * @param _value value permitted for spend
   * @param _deadline expiration of signature
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   */
  function permit(
    address _owner, 
    address _spender, 
    uint256 _value, 
    uint256 _deadline, 
    uint8 _ecv, 
    bytes32 _ecr, 
    bytes32 _ecs
  ) external returns (bool) {
    require(block.timestamp <= _deadline, "UPGT_ERROR: wrong timestamp");
    require(uint256_chain_id == _getChainId(), "UPGT_ERROR: chain_id is incorrect");
    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        EIP712DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, m_nonces[_owner]++, _deadline))
      )
    );
    require(_owner == _recoverSigner(digest, _ecv, _ecr, _ecs), "UPGT_ERROR: sign does not match user");
    require(_owner != BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");

    return _approveUNN(_owner, _spender, _value);
  }

  /**
   * @dev EIP-712 ETH Typed Structured Data Hashing and Signing for Delegate Vote
   * @param _owner address of token owner
   * @param _delegate address of voting delegate
   * @param _expiretimestamp expiration of delegation signature
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   * @ @return bool true or false depedening on whether vote was successfully delegated
   */
  function delegateVoteBySignature(
    address _owner, 
    address _delegate, 
    uint256 _expiretimestamp, 
    uint8 _ecv, 
    bytes32 _ecr, 
    bytes32 _ecs
  ) external returns (bool) {
    require(block.timestamp <= _expiretimestamp, "UPGT_ERROR: wrong timestamp");
    require(uint256_chain_id == _getChainId(), "UPGT_ERROR: chain_id is incorrect");
    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01",
        EIP712DOMAIN_SEPARATOR,
        _hash(VotingDelegate(
          {
            owner : _owner,
            delegate : _delegate,
            nonce : m_nonces[_owner]++,
            expirationTime : _expiretimestamp
          })
        )
      )
    );
    require(_owner == _recoverSigner(digest, _ecv, _ecr, _ecs), "UPGT_ERROR: sign does not match user");
    require(_owner!= BURN_ADDRESS, "UPGT_ERROR: address cannot be burn address");

    return _delegateVote(_owner, _delegate);
  }

  /**
   * @dev Public hash EIP712Domain struct for EIP-712
   * @param _eip712Domain EIP712Domain struct
   * @return bytes32 hash of _eip712Domain
   * Requires ROLE_TEST
   */
  function hashEIP712Domain(EIP712Domain memory _eip712Domain) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_eip712Domain);
  }

  /**
   * @dev Hash Delegate struct for EIP-712
   * @param _delegate VotingDelegate struct
   * @return bytes32 hash of _delegate
   * Requires ROLE_TEST
   */
  function hashDelegate(VotingDelegate memory _delegate) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_delegate);
  }

  /**
   * @dev Public hash Permit struct for EIP-712
   * @param _permit Permit struct
   * @return bytes32 hash of _permit
   * Requires ROLE_TEST
   */
  function hashPermit(Permit memory _permit) public view returns (bytes32) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _hash(_permit);
  }

  /**
   * @param _digest signed, hashed message
   * @param _ecv ECDSA v parameter
   * @param _ecr ECDSA r parameter
   * @param _ecs ECDSA s parameter
   * @return address of the validated signer
   * based on openzeppelin/contracts/cryptography/ECDSA.sol recover() function
   * Requires ROLE_TEST
   */
  function recoverSigner(bytes32 _digest, uint8 _ecv, bytes32 _ecr, bytes32 _ecs) public view returns (address) {
    require(hasRole(ROLE_TEST, _msgSender()), "UPGT_ERROR: ROLE_TEST Required");
    return _recoverSigner(_digest, _ecv, _ecr, _ecs);
  }

  /**
  * @dev Private hash EIP712Domain struct for EIP-712
  * @param _eip712Domain EIP712Domain struct
  * @return bytes32 hash of _eip712Domain
  */
  function _hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32) {
      return keccak256(
          abi.encode(
              EIP712DOMAIN_TYPEHASH,
              keccak256(bytes(_eip712Domain.name)),
              keccak256(bytes(_eip712Domain.version)),
              _eip712Domain.chainId,
              _eip712Domain.verifyingContract,
              _eip712Domain.salt
          )
      );
  }

  /**
  * @dev Private hash Delegate struct for EIP-712
  * @param _delegate VotingDelegate struct
  * @return bytes32 hash of _delegate
  */
  function _hash(VotingDelegate memory _delegate) internal pure returns (bytes32) {
      return keccak256(
          abi.encode(
              DELEGATE_TYPEHASH,
              _delegate.owner,
              _delegate.delegate,
              _delegate.nonce,
              _delegate.expirationTime
          )
      );
  }

  /** 
  * @dev Private hash Permit struct for EIP-712
  * @param _permit Permit struct
  * @return bytes32 hash of _permit
  */
  function _hash(Permit memory _permit) internal pure returns (bytes32) {
      return keccak256(abi.encode(
      PERMIT_TYPEHASH,
      _permit.owner,
      _permit.spender,
      _permit.value,
      _permit.nonce,
      _permit.deadline
      ));
  }

  /**
  * @dev Recover signer information from provided digest
  * @param _digest signed, hashed message
  * @param _ecv ECDSA v parameter
  * @param _ecr ECDSA r parameter
  * @param _ecs ECDSA s parameter
  * @return address of the validated signer
  * based on openzeppelin/contracts/cryptography/ECDSA.sol recover() function
  */
  function _recoverSigner(bytes32 _digest, uint8 _ecv, bytes32 _ecr, bytes32 _ecs) internal pure returns (address) {
      // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
      // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
      // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
      // signatures from current libraries generate a unique signature with an s-value in the lower half order.
      //
      // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
      // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
      // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
      // these malleable signatures as well.
      if(uint256(_ecs) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
          revert("ECDSA: invalid signature 's' value");
      }

      if(_ecv != 27 && _ecv != 28) {
          revert("ECDSA: invalid signature 'v' value");
      }

      // If the signature is valid (and not malleable), return the signer address
      address signer = ecrecover(_digest, _ecv, _ecr, _ecs);
      require(signer != BURN_ADDRESS, "ECDSA: invalid signature");

      return signer;
  }
}