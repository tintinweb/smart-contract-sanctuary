pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";


contract DintToken is ERC20("Investment Token", "DINT"), Ownable {

  uint256 private _cap = 500000000e18;
  uint256 private _totalLock;

  uint256 public lockFromBlock;
  uint256 public lockToBlock;
  

  mapping(address => uint256) private _locks;
  mapping(address => uint256) private _lastUnlockBlock;

  event Lock(address indexed to, uint256 value);

  /**
    * @dev Returns the cap on the token's total supply.
    */
  function cap() public view returns (uint256) {
      return _cap;
  }
  function circulatingSupply() public view returns (uint256) {
      return totalSupply().sub(_totalLock);
  }

  function totalLock() public view returns (uint256) {
      return _totalLock;
  }

  constructor(uint256 _lockFromBlock, uint256 _lockToBlock) public {
    lockFromBlock = _lockFromBlock;
    lockToBlock = _lockToBlock;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) { // When minting tokens
          require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
      }
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
      super._transfer(sender, recipient, amount);
      _moveDelegates(_delegates[sender], _delegates[recipient], amount);
  }

  /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address _to, uint256 _amount) public onlyOwner {
      _mint(_to, _amount);
      _moveDelegates(address(0), _delegates[_to], _amount);
  }

  function totalBalanceOf(address _holder) public view returns (uint256) {
      return _locks[_holder].add(balanceOf(_holder));
  }

  function lockOf(address _holder) public view returns (uint256) {
      return _locks[_holder];
  }

  function lastUnlockBlock(address _holder) public view returns (uint256) {
      return _lastUnlockBlock[_holder];
  }

  function lock(address _holder, uint256 _amount) public onlyOwner {
      require(_holder != address(0), "ERC20: lock to the zero address");
      require(_amount <= balanceOf(_holder), "ERC20: lock amount over blance");

      _transfer(_holder, address(this), _amount);

      _locks[_holder] = _locks[_holder].add(_amount);
      _totalLock = _totalLock.add(_amount);
      if (_lastUnlockBlock[_holder] < lockFromBlock) {
          _lastUnlockBlock[_holder] = lockFromBlock;
      }
      emit Lock(_holder, _amount);
  }

  function canUnlockAmount(address _holder) public view returns (uint256) {
      if (block.number < lockFromBlock) {
          return 0;
      }
      else if (block.number >= lockToBlock) {
          return _locks[_holder];
      }
      else {
          uint256 releaseBlock = block.number.sub(_lastUnlockBlock[_holder]);
          uint256 numberLockBlock = lockToBlock.sub(_lastUnlockBlock[_holder]);
          return _locks[_holder].mul(releaseBlock).div(numberLockBlock);
      }
  }

  function unlock() public {
      require(_locks[msg.sender] > 0, "ERC20: cannot unlock");
      
      uint256 amount = canUnlockAmount(msg.sender);
      // just for sure
      if (amount > balanceOf(address(this))) {
          amount = balanceOf(address(this));
      }
      _transfer(address(this), msg.sender, amount);
      _locks[msg.sender] = _locks[msg.sender].sub(amount);
      _lastUnlockBlock[msg.sender] = block.number;
      _totalLock = _totalLock.sub(amount);
  }

  // This function is for dev address migrate all balance to a multi sig address
  function transferAll(address _to) public {
      _locks[_to] = _locks[_to].add(_locks[msg.sender]);

      if (_lastUnlockBlock[_to] < lockFromBlock) {
          _lastUnlockBlock[_to] = lockFromBlock;
      }

      if (_lastUnlockBlock[_to] < _lastUnlockBlock[msg.sender]) {
          _lastUnlockBlock[_to] = _lastUnlockBlock[msg.sender];
      }

      _locks[msg.sender] = 0;
      _lastUnlockBlock[msg.sender] = 0;

      _transfer(msg.sender, _to, balanceOf(msg.sender));
  }

  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  /// @dev A record of each accounts delegate
  mapping (address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
      uint32 fromBlock;
      uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping (address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
  function delegates(address delegator)
      external
      view
      returns (address)
  {
      return _delegates[delegator];
  }

  /**
  * @notice Delegate votes from `msg.sender` to `delegatee`
  * @param delegatee The address to delegate votes to
  */
  function delegate(address delegatee) external {
      return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
      address delegatee,
      uint nonce,
      uint expiry,
      uint8 v,
      bytes32 r,
      bytes32 s
  )
      external
  {
      bytes32 domainSeparator = keccak256(
          abi.encode(
              DOMAIN_TYPEHASH,
              keccak256(bytes(name())),
              getChainId(),
              address(this)
          )
      );

      bytes32 structHash = keccak256(
          abi.encode(
              DELEGATION_TYPEHASH,
              delegatee,
              nonce,
              expiry
          )
      );

      bytes32 digest = keccak256(
          abi.encodePacked(
              "\x19\x01",
              domainSeparator,
              structHash
          )
      );

      address signatory = ecrecover(digest, v, r, s);
      require(signatory != address(0), "DINT::delegateBySig: invalid signature");
      require(nonce == nonces[signatory]++, "DINT::delegateBySig: invalid nonce");
      require(now <= expiry, "DINT::delegateBySig: signature expired");
      return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account)
      external
      view
      returns (uint256)
  {
      uint32 nCheckpoints = numCheckpoints[account];
      return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint blockNumber)
      external
      view
      returns (uint256)
  {
      require(blockNumber < block.number, "DINT::getPriorVotes: not yet determined");

      uint32 nCheckpoints = numCheckpoints[account];
      if (nCheckpoints == 0) {
          return 0;
      }

      // First check most recent balance
      if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
          return checkpoints[account][nCheckpoints - 1].votes;
      }

      // Next check implicit zero balance
      if (checkpoints[account][0].fromBlock > blockNumber) {
          return 0;
      }

      uint32 lower = 0;
      uint32 upper = nCheckpoints - 1;
      while (upper > lower) {
          uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
          Checkpoint memory cp = checkpoints[account][center];
          if (cp.fromBlock == blockNumber) {
              return cp.votes;
          } else if (cp.fromBlock < blockNumber) {
              lower = center;
          } else {
              upper = center - 1;
          }
      }
      return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee)
      internal
  {
      address currentDelegate = _delegates[delegator];
      uint256 delegatorBalance = balanceOf(delegator);
      _delegates[delegator] = delegatee;

      emit DelegateChanged(delegator, currentDelegate, delegatee);

      _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
      if (srcRep != dstRep && amount > 0) {
          if (srcRep != address(0)) {
              // decrease old representative
              uint32 srcRepNum = numCheckpoints[srcRep];
              uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
              uint256 srcRepNew = srcRepOld.sub(amount);
              _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
          }

          if (dstRep != address(0)) {
              // increase new representative
              uint32 dstRepNum = numCheckpoints[dstRep];
              uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
              uint256 dstRepNew = dstRepOld.add(amount);
              _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
          }
      }
  }

  function _writeCheckpoint(
      address delegatee,
      uint32 nCheckpoints,
      uint256 oldVotes,
      uint256 newVotes
  )
      internal
  {
      uint32 blockNumber = safe32(block.number, "DINT::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
      require(n < 2**32, errorMessage);
      return uint32(n);
  }

  function getChainId() internal pure returns (uint) {
      uint256 chainId;
      assembly { chainId := chainid() }
      return chainId;
  }
}