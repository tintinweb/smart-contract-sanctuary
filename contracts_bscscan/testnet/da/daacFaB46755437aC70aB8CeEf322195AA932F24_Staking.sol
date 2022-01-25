// contracts/Staking.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./sEvryHyper.sol";

contract Staking is Ownable {
    // using SafeERC20 for ERC20;
    // using SafeMath for uint256;

    address public immutable EVHY;
    address public immutable sEVHY;

    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint distribute;
    }
    Epoch public epoch;

    // address public distributor;
    
    // address public locker;
    // uint public totalBonus;
    
    // address public warmupContract;
    // uint public warmupPeriod;
    
    constructor ( 
        address _EVHY, 
        address _sEVHY, 
        uint _epochLength,
        uint _firstEpochNumber,
        uint _firstEpochBlock
    ) {
        require( _EVHY != address(0) );
        EVHY = _EVHY;
        require( _sEVHY != address(0) );
        sEVHY = _sEVHY;
        
        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endBlock: _firstEpochBlock,
            distribute: 0
        });
    }

    // struct Claim {
    //     uint deposit;
    //     uint gons;
    //     uint expiry;
    //     bool lock; // prevents malicious delays
    // }
    // mapping( address => Claim ) public warmupInfo;

    // /**
    //     @notice stake EVHY to enter warmup
    //     @param _amount uint
    //     @return bool
    //  */
    // function stake( uint _amount, address _recipient ) external returns ( bool ) {
    //     rebase();
        
    //     ERC20( EVHY ).safeTransferFrom( msg.sender, address(this), _amount );

    //     Claim memory info = warmupInfo[ _recipient ];
    //     require( !info.lock, "Deposits for account are locked" );

    //     warmupInfo[ _recipient ] = Claim ({
    //         deposit: info.deposit.add( _amount ),
    //         gons: info.gons.add( sEvryHyper( sEVHY ).gonsForBalance( _amount ) ),
    //         expiry: epoch.number.add( warmupPeriod ),
    //         lock: false
    //     });
        
    //     ERC20( sEVHY ).safeTransfer( warmupContract, _amount );
    //     return true;
    // }

    // /**
    //     @notice retrieve sEVHY from warmup
    //     @param _recipient address
    //  */
    // function claim ( address _recipient ) public {
    //     Claim memory info = warmupInfo[ _recipient ];
    //     if ( epoch.number >= info.expiry && info.expiry != 0 ) {
    //         delete warmupInfo[ _recipient ];
    //         IWarmup( warmupContract ).retrieve( _recipient, sEvryHyper( sEVHY ).balanceForGons( info.gons ) );
    //     }
    // }

    // /**
    //     @notice forfeit sEVHY in warmup and retrieve EVHY
    //  */
    // function forfeit() external {
    //     Claim memory info = warmupInfo[ msg.sender ];
    //     delete warmupInfo[ msg.sender ];

    //     IWarmup( warmupContract ).retrieve( address(this), sEvryHyper( sEVHY ).balanceForGons( info.gons ) );
    //     ERC20( EVHY ).safeTransfer( msg.sender, info.deposit );
    // }

    // /**
    //     @notice prevent new deposits to address (protection from malicious activity)
    //  */
    // function toggleDepositLock() external {
    //     warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    // }

    // /**
    //     @notice redeem sEVHY for EVHY
    //     @param _amount uint
    //     @param _trigger bool
    //  */
    // function unstake( uint _amount, bool _trigger ) external {
    //     if ( _trigger ) {
    //         rebase();
    //     }
    //     ERC20( sEVHY ).safeTransferFrom( msg.sender, address(this), _amount );
    //     ERC20( EVHY ).safeTransfer( msg.sender, _amount );
    // }

    // /**
    //     @notice returns the sEVHY index, which tracks rebase growth
    //     @return uint
    //  */
    // function index() public view returns ( uint ) {
    //     return sEvryHyper( sEVHY ).index();
    // }

    // /**
    //     @notice trigger rebase if epoch over
    //  */
    // function rebase() public {
    //     if( epoch.endBlock <= block.number ) {

    //         sEvryHyper( sEVHY ).rebase( epoch.distribute, epoch.number );

    //         epoch.endBlock = epoch.endBlock.add( epoch.length );
    //         epoch.number++;
            
    //         if ( distributor != address(0) ) {
    //             IDistributor( distributor ).distribute();
    //         }

    //         uint balance = contractBalance();
    //         uint staked = sEvryHyper( sEVHY ).circulatingSupply();

    //         if( balance <= staked ) {
    //             epoch.distribute = 0;
    //         } else {
    //             epoch.distribute = balance.sub( staked );
    //         }
    //     }
    // }

    // /**
    //     @notice returns contract EVHY holdings, including bonuses provided
    //     @return uint
    //  */
    // function contractBalance() public view returns ( uint ) {
    //     return ERC20( EVHY ).balanceOf( address(this) ).add( totalBonus );
    // }

    // /**
    //     @notice provide bonus to locked staking contract
    //     @param _amount uint
    //  */
    // function giveLockBonus( uint _amount ) external {
    //     require( msg.sender == locker );
    //     totalBonus = totalBonus.add( _amount );
    //     ERC20( sEVHY ).safeTransfer( locker, _amount );
    // }

    // /**
    //     @notice reclaim bonus from locked staking contract
    //     @param _amount uint
    //  */
    // function returnLockBonus( uint _amount ) external {
    //     require( msg.sender == locker );
    //     totalBonus = totalBonus.sub( _amount );
    //     ERC20( sEVHY ).safeTransferFrom( locker, address(this), _amount );
    // }

    // enum CONTRACTS { DISTRIBUTOR, WARMUP, LOCKER }

    // /**
    //     @notice sets the contract address for LP staking
    //     @param _contract address
    //  */
    // function setContract( CONTRACTS _contract, address _address ) external onlyManager() {
    //     if( _contract == CONTRACTS.DISTRIBUTOR ) { // 0
    //         distributor = _address;
    //     } else if ( _contract == CONTRACTS.WARMUP ) { // 1
    //         require( warmupContract == address( 0 ), "Warmup cannot be set more than once" );
    //         warmupContract = _address;
    //     } else if ( _contract == CONTRACTS.LOCKER ) { // 2
    //         require( locker == address(0), "Locker cannot be set more than once" );
    //         locker = _address;
    //     }
    // }
    
    // /**
    //  * @notice set warmup period for new stakers
    //  * @param _warmupPeriod uint
    //  */
    // function setWarmup( uint _warmupPeriod ) external onlyManager() {
    //     warmupPeriod = _warmupPeriod;
    // }
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

// contracts/sEvryHyper.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC20 is IERC20 {
  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

  // Present in ERC777
  mapping(address => uint256) internal _balances;

  // Present in ERC777
  mapping(address => mapping(address => uint256)) internal _allowances;

  // Present in ERC777
  uint256 internal _totalSupply;

  // Present in ERC777
  string internal _name;

  // Present in ERC777
  string internal _symbol;

  // Present in ERC777
  uint8 internal _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the name of the token.
   */
  // Present in ERC777
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  // Present in ERC777
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  // Present in ERC777
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  // Present in ERC777
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  // Present in ERC777
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  // Overrideen in ERC777
  // Confirm that this behavior changes
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  // Present in ERC777
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  // Present in ERC777
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  // Present in ERC777
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  // Present in ERC777
  function _mint(address account_, uint256 ammount_) internal virtual {
    require(account_ != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(this), account_, ammount_);
    _totalSupply = _totalSupply.add(ammount_);
    _balances[account_] = _balances[account_].add(ammount_);
    emit Transfer(address(this), account_, ammount_);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  // Present in ERC777
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  // Present in ERC777
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  // Considering deprication to reduce size of bytecode as changing _decimals to internal acheived the same functionality.
  // function _setupDecimals(uint8 decimals_) internal {
  //     _decimals = decimals_;
  // }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  // Present in ERC777
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 amount_
  ) internal virtual {}
}

abstract contract ERC20Permit is ERC20, IERC20Permit {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  bytes32 public DOMAIN_SEPARATOR;

  constructor() {
    uint256 chainID;
    assembly {
      chainID := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        chainID,
        address(this)
      )
    );
  }

  /**
   * @dev See {IERC2612Permit-permit}.
   *
   */
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(block.timestamp <= deadline, "Permit: expired deadline");

    bytes32 hashStruct = keccak256(
      abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
    );

    bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

    address signer = ecrecover(_hash, v, r, s);
    require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

    _nonces[owner].increment();
    _approve(owner, spender, amount);
  }

  /**
   * @dev See {IERC2612Permit-nonces}.
   */
  function nonces(address owner) public view override returns (uint256) {
    return _nonces[owner].current();
  }
}

contract sEvryHyper is ERC20Permit, Ownable {
  using SafeMath for uint256;

  modifier onlyStakingContract() {
    require(msg.sender == stakingContract);
    _;
  }

  address public stakingContract;
  address public initializer;

  event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply);
  event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
  event LogStakingContractUpdated(address stakingContract);

  struct Rebase {
    uint256 epoch;
    uint256 rebase; // 18 decimals
    uint256 totalStakedBefore;
    uint256 totalStakedAfter;
    uint256 amountRebased;
    uint256 index;
    uint256 blockNumberOccured;
  }
  Rebase[] public rebases;

  uint256 public INDEX;

  uint256 private constant MAX_UINT256 = ~uint256(0);
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 1e18;

  // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
  // Use the highest value that fits in a uint256 for max granularity.
  uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

  // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
  uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

  uint256 private _gonsPerFragment;
  mapping(address => uint256) private _gonBalances;

  mapping(address => mapping(address => uint256)) private _allowedValue;

  constructor() ERC20("Staked EvryHyper", "sEVHY", 18) ERC20Permit() {
    initializer = msg.sender;
    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
  }

  function initialize(address stakingContract_) external returns (bool) {
    require(msg.sender == initializer);
    require(stakingContract_ != address(0));
    stakingContract = stakingContract_;
    _gonBalances[stakingContract] = TOTAL_GONS;

    emit Transfer(address(0x0), stakingContract, _totalSupply);
    emit LogStakingContractUpdated(stakingContract_);

    initializer = address(0);
    return true;
  }

  function setIndex(uint256 _INDEX) external onlyOwner returns (bool) {
    require(INDEX == 0);
    INDEX = gonsForBalance(_INDEX);
    return true;
  }

  /**
    @notice increases sEVHY supply to increase staking balances relative to profit_
    @param profit_ uint256
    @return uint256
  */
  function rebase(uint256 profit_, uint256 epoch_) public onlyStakingContract returns (uint256) {
    uint256 rebaseAmount;
    uint256 circulatingSupply_ = circulatingSupply();

    if (profit_ == 0) {
      emit LogSupply(epoch_, block.timestamp, _totalSupply);
      emit LogRebase(epoch_, 0, index());
      return _totalSupply;
    } else if (circulatingSupply_ > 0) {
      rebaseAmount = profit_.mul(_totalSupply).div(circulatingSupply_);
    } else {
      rebaseAmount = profit_;
    }

    _totalSupply = _totalSupply.add(rebaseAmount);

    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }

    _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

    _storeRebase(circulatingSupply_, profit_, epoch_);

    return _totalSupply;
  }

  /**
    @notice emits event with data about rebase
    @param previousCirculating_ uint
    @param profit_ uint
    @param epoch_ uint
    @return bool
  */
  function _storeRebase(
    uint256 previousCirculating_,
    uint256 profit_,
    uint256 epoch_
  ) internal returns (bool) {
    uint256 rebasePercent = profit_.mul(1e18).div(previousCirculating_);

    rebases.push(
      Rebase({
        epoch: epoch_,
        rebase: rebasePercent, // 18 decimals
        totalStakedBefore: previousCirculating_,
        totalStakedAfter: circulatingSupply(),
        amountRebased: profit_,
        index: index(),
        blockNumberOccured: block.number
      })
    );

    emit LogSupply(epoch_, block.timestamp, _totalSupply);
    emit LogRebase(epoch_, rebasePercent, index());

    return true;
  }

  function balanceOf(address who) public view override returns (uint256) {
    return _gonBalances[who].div(_gonsPerFragment);
  }

  function gonsForBalance(uint256 amount) public view returns (uint256) {
    return amount.mul(_gonsPerFragment);
  }

  function balanceForGons(uint256 gons) public view returns (uint256) {
    return gons.div(_gonsPerFragment);
  }

  // Staking contract holds excess sEVHY
  function circulatingSupply() public view returns (uint256) {
    return _totalSupply.sub(balanceOf(stakingContract));
  }

  function index() public view returns (uint256) {
    return balanceForGons(INDEX);
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    uint256 gonValue = gonsForBalance(value);
    _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
    _gonBalances[to] = _gonBalances[to].add(gonValue);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function allowance(address owner_, address spender) public view override returns (uint256) {
    return _allowedValue[owner_][spender];
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public override returns (bool) {
    _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender].sub(value);
    emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

    uint256 gonValue = gonsForBalance(value);
    _gonBalances[from] = _gonBalances[from].sub(gonValue);
    _gonBalances[to] = _gonBalances[to].add(gonValue);
    emit Transfer(from, to, value);

    return true;
  }

  function approve(address spender, uint256 value) public override returns (bool) {
    _allowedValue[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  // What gets called in a permit
  function _approve(
    address owner,
    address spender,
    uint256 value
  ) internal virtual override {
    _allowedValue[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
    _allowedValue[msg.sender][spender] = _allowedValue[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
    uint256 oldValue = _allowedValue[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedValue[msg.sender][spender] = 0;
    } else {
      _allowedValue[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedValue[msg.sender][spender]);
    return true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}