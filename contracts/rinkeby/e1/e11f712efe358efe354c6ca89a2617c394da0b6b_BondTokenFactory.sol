/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

// File: interfaces/IOwnable.sol


pragma solidity >=0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}
// File: types/Ownable.sol


pragma solidity >=0.7.5;


abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// File: BondageToken_flat.sol



// File: libraries/SafeMath.sol


pragma solidity >=0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}
// File: interfaces/INoteKeeper.sol


pragma solidity >=0.7.5;

interface INoteKeeper {
  // Info for market note
  struct Note {
    uint256 payout; // gOHM remaining to be paid
    uint48 created; // time market was created
    uint48 matured; // timestamp when market is matured
    uint48 redeemed; // time market was redeemed
    uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
  }

  function redeem(address _user, uint256[] memory _indexes, bool _sendgOHM) external returns (uint256);
  function redeemAll(address _user, bool _sendgOHM) external returns (uint256);
  function pushNote(address to, uint256 index) external;
  function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

  function indexesFor(address _user) external view returns (uint256[] memory);
  function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}
// File: interfaces/IERC20.sol


pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: interfaces/IERC20Metadata.sol


pragma solidity >=0.7.5;


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
// File: libraries/SafeERC20.sol


pragma solidity >=0.7.5;


/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}
// File: types/ERC20.sol


pragma solidity >=0.7.5;




abstract contract ERC20 is IERC20 {

    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );
    
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    
    string internal _symbol;
    
    uint8 internal immutable _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

// File: interfaces/IBondDepository.sol


pragma solidity >=0.7.5;



interface IBondDepository is INoteKeeper {

  // Info about each type of market
  struct Market {
    uint256 capacity; // capacity remaining
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
    uint64 totalDebt; // total debt from market
    uint64 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    uint64 sold; // base tokens out
    uint256 purchased; // quote tokens in
  }

  // Info for creating new markets
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint64 controlVariable; // scaling variable for price
    uint48 vesting; // length of time from deposit to maturity if fixed-term
    uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
    uint64 maxDebt; // 9 decimal debt maximum in OHM
  }

  // Additional info about market.
  struct Metadata {
    uint48 lastTune; // last timestamp when control variable was tuned
    uint48 lastDecay; // last timestamp when market was created and debt was decayed
    uint48 length; // time from creation to conclusion. used as speed to decay debt.
    uint48 depositInterval; // target frequency of deposits
    uint48 tuneInterval; // frequency of tuning
    uint8 quoteDecimals; // decimals of quote token
  }

  // Control variable adjustment data
  struct Adjustment {
    uint64 change;
    uint48 lastAdjustment;
    uint48 timeToAdjusted;
    bool active;
  }

  function markets(uint256 id) external view returns (Market memory);
  function notes(address user) external view returns (Note[] memory);

  /**
   * @notice deposit market
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _user address
   * @param _referral address
   * @return payout_ uint256
   * @return expiry_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  );

  function create (
    IERC20 _quoteToken, // token used to deposit
    uint256[3] memory _market, // [capacity, initial price]
    bool[2] memory _booleans, // [capacity in quote, fixed term]
    uint256[2] memory _terms, // [vesting, conclusion]
    uint32[2] memory _intervals // [deposit interval, tune interval]
  ) external returns (uint256 id_);
  function close(uint256 _id) external;

  function isLive(uint256 _bid) external view returns (bool);
  function liveMarkets() external view returns (uint256[] memory);
  function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
  function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
  function marketPrice(uint256 _bid) external view returns (uint256);
  function currentDebt(uint256 _bid) external view returns (uint256);
  function debtRatio(uint256 _bid) external view returns (uint256);
  function debtDecay(uint256 _bid) external view returns (uint64);
}
// File: BondageToken.sol


pragma solidity >=0.7.5;
pragma abicoder v2;





interface IFactory {
    function dev() external view returns (address);
}

contract BondToken is ERC20 {

/* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;

/* ========== EVENTS ========== */

    event Success(uint256 harvest);
    event RedFlag(uint256 harvest, uint256 expected);

/* ========== MODIFIERS ========== */

    modifier onlyRedeemed() {
        require(harvested, "Not harvested");
        _;
    }

    modifier onlyMatured() {
        require(block.timestamp > expiry, "Not vested");
        require(!harvested, "Already harvested");
        _;
    }

/* ========== STATE VARIABLES ========== */

    // Created the token. Used to find dev address.
    IFactory public immutable factory;
    // The underlying token.
    IERC20 public immutable underlying;
    // The bond depository.
    IBondDepository public immutable depository;
    // The timestamp when mintable bonds expire.
    uint256 public immutable expiry;
    // The last tracked Note index.
    uint256 public nonce;
    // Whether payouts have been harvested and burns can begin.
    bool public harvested;
    // Fee taken on burns for underlying. 3 decimals (1000 = 1%)
    uint256 public immutable fee;

/* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name, 
        string memory _symbol,
        address _depository,
        address _underlying,
        uint256 _expiry,
        uint256 _fee
    ) ERC20(_name, _symbol, 18) {
        factory = IFactory(msg.sender);
        depository = IBondDepository(_depository);
        underlying = IERC20(_underlying);
        expiry = _expiry;
        fee = _fee;
    }

/* ========== BEFORE EXPIRY ========== */

    // Mint tokens by depositing a bond. The bond must expire before or at the
    // global expiry timestamp. This ensures each token will be redeemable for
    // one underlying at expiry.
    // If any bonds were added since the last mint (anyone can deposit on behalf of
    // this address), the equivalent underlying payable is minted to the dev.
    function mint(uint256 _id, uint256 _principalIn, uint256 _maxPrice) external returns (uint256) {
        IBondDepository.Market memory market = depository.markets(_id);

        // note user must approve quote token for transfer by this address.
        market.quoteToken.safeTransferFrom(msg.sender, address(this), _principalIn);
        market.quoteToken.approve(address(depository), _principalIn);

        // Deposit bond, returning time when payout accessible and payout amount
        (
            uint256 payout_,
            uint256 expiry_, 
            uint256 index_
        ) = depository.deposit(
            _id, 
            _principalIn, 
            _maxPrice, 
            address(this),
            address(this)
        );

        // This piece makes these tokens composable.
        // We know that each token will always have 1 underlying available at expiry.
        require(expiry_ <= expiry, "Expires after expiry");

        // Any unexpected bonds get minted to dev.
        if (index_ > nonce + 1) _mintUnexpectedToDev(index_);
        
        // Mint bondage tokens to user.
        _mint(msg.sender, payout_);
        return payout_;
    }

    // Mint tokens by transferring a bond. The bond must expire before or at the
    // global expiry timestamp. This ensures each token will be redeemable for
    // one underlying at expiry.
    // If any bonds were added since the last mint (anyone can deposit on behalf of
    // this address), the equivalent underlying payable is minted to the dev.
    function mintWithTransfer(uint256 _note) external returns (uint256) {
        // Transfer note ownership from sender to this contract.
        // Sender must have called pushNote already (similar to approval).
        uint256 index = depository.pullNote(msg.sender, _note);

        // Fetch info about the note just pulled.
        IBondDepository.Note memory note = depository.notes(address(this))[index];
        
        // Make sure underlying will be redeemable before or at expiry.
        require(note.matured <= expiry, "Expires after expiry");

        // Send any unexpected bond payouts to dev.
        if (index > nonce + 1) _mintUnexpectedToDev(index);

        // Mint bondage tokens to user.
        _mint(msg.sender, note.payout);
        return note.payout;
    }

    // Any note not deposited or transferred to this contract directly
    // (i.e. deposit on behalf of this contract without engaging it and
    // minting bondage tokens) are minted to the dev.
    function _mintUnexpectedToDev(uint256 _index) internal {
        IBondDepository.Note[] memory notes = depository.notes(address(this));
        uint256 freeMoney;
        for (uint256 i = nonce; i < _index; i++) {
            if (notes[i].matured <= expiry) {
                freeMoney += notes[i].payout;
            } // else dev takes it with scrap()
        }
        _mint(factory.dev(), freeMoney);
        nonce = _index;
    }

/* ========== AFTER EXPIRY ========== */

    // Harvest gOHM payouts from the bond depository, allowing
    // token redemptions to occur. This function uses the
    // redeemAll() function of the depository, which may surpass
    // the block gas limit if there are enough Notes.
    function harvest() external onlyMatured returns (uint256) {
        uint256 bounty = depository.redeemAll(address(this), true);
        uint256 supply = totalSupply();
        // Dev receives any unexpected bonus
        if (bounty > supply) {
            _mint(factory.dev(), bounty - supply);
            emit Success(bounty);
        // if bounty is less, something has gone wrong.
        // redemptions will still occur, based on redemptionRate()
        } else if (bounty < supply) emit RedFlag(bounty, supply);
        else emit Success(bounty);
        // Open burn(), prevent this from being called again.
        harvested = true;
        return bounty;
    }

    // All Note indexes for this address.
    // Only set if safeHarvest() is used.
    uint256[] private indexes;
    // Index redeemed up to. Helps contract keep track.
    uint256 private redeemedTo;

    // Harvest gOHM payouts from the bond depository, allowing
    // token redemptions to occur. This function stores an array
    // of indexes to redeem, and executes in <= 30 chunks. This
    // avoids any block gas limit issues that we may run into with harvestAll().
    function safeHarvest() external onlyMatured returns (uint256) {
        // First time called, we store the array of indexes
        if (indexes.length == 0) {
            indexes = depository.indexesFor(address(this));
            return 0;
        // After first, we redeem in <= 30 index chunks.
        } else {
            uint256 remaining = indexes.length - redeemedTo;
            uint256 toRedeem = remaining < 30 ? remaining : 30;
            if (toRedeem == 0) {
                harvested = true;
                emit Success(0);
                return 0;
            }
            uint256[] memory redeem = new uint256[](toRedeem);
            for (uint256 i = 0; i < toRedeem; i++) {
                redeem[i] = redeemedTo + i;
            }
            return depository.redeem(address(this), redeem, true);
        }
    }

/* ========== AFTER HARVEST ========== */

    // User can burn their tokens for same amount of gOHM
    // (minus fee), once payouts have been harvested.
    function burn(uint256 amount) external onlyRedeemed {
        _burn(msg.sender, amount);
        // Fee is universal and set in factory.
        if (fee != 0) {
            uint256 take = amount * fee / 1e5;
            underlying.safeTransfer(factory.dev(), take);
            amount -= take; // remove fee from what is sent to user.
        }
        underlying.safeTransfer(msg.sender, amount);
    }

    // Dev gets to claim all payouts once harvest has occurred.
    // These are unlikely, we can assume they are erroneous.
    function scrap() external onlyRedeemed returns (uint256) {
        uint256 freeMoney = depository.redeemAll(address(this), true);
        underlying.safeTransfer(factory.dev(), freeMoney);
        return freeMoney;
    }

/* ========== VIEW FUNCTIONS ========== */

    // Make sure everyone gets their fair share. Important if
    // harvest is > or < expected (expected == totalSupply).
    function redemptionRate() external view returns (uint256) {
        return underlying.balanceOf(address(this)) * 1e18 / totalSupply();
    }
}
// File: BondageFactory.sol


pragma solidity 0.8.0;



contract BondTokenFactory is Ownable {

/* ========== STATE VARIABLES ========== */

    // All previously created tokens.
    address[] public created;
    // Previously created token for: depository, underlying, expiry timestamp.
    mapping(address => mapping(address => mapping(uint256 => address))) public createdFor;
    // A fee can be taken when a bond is redeemed. 3 decimals (1000 = 1%).
    uint256 public fee;

/* ========== CONSTRUCTOR ========== */

    constructor() {}

/* ========== FACTORY ========== */

    // Creates a Bondage Token for given expiry if it does not yet exist.
    // For a gOHM bond expiring Jan 1, 2022, name will be 'gOHM 1/1/2022'
    // and symbol will be gOHM010122. Any bond expiring before or at the
    // expiration timestamp will be able to mint the bond token.
    function create(
        address _depository, 
        address _underlying, 
        uint256 _expiry
    ) external {
        require(createdFor[_depository][_underlying][_expiry] == address(0), "Already created");

        (string memory name, string memory symbol) = getNameAndSymbol(_underlying, _expiry);

        // Deploy a new Bondage Token with given expiry.
        address token = address(new BondToken(
            name,
            symbol,
            _depository,
            _underlying,
            _expiry,
            fee
        ));

        // Store the address of the new token for recall
        createdFor[_depository][_underlying][_expiry] = token;
        created.push(token);
    }

    function getNameAndSymbol(address _underlying, uint256 _expiry) public view returns (string memory name, string memory symbol) {
        // Convert expiry time to strings for name/symbol.
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_expiry);
        string memory yearStr = uint2str(year);
        string memory yearStrConcat = uint2str(year % 100);
        string memory monthStr = month < 10 ? string(abi.encodePacked(uint2str(0), uint2str(month))) : uint2str(month);
        string memory dayStr = day < 10 ? string(abi.encodePacked(uint2str(0), uint2str(day))) : uint2str(day);

        string memory underlyingSymbol = IERC20Metadata(_underlying).symbol();

        // Construct name/symbol strings.
        name = string(abi.encodePacked(underlyingSymbol, " ", monthStr, "/", dayStr, "/", yearStr));
        symbol = string(abi.encodePacked(underlyingSymbol, "-", monthStr, dayStr, yearStrConcat));
    }

/* ========== OWNABLE ========== */

    // Set the redemption fee for new tokens. 
    function setFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    // Address to receive fees/free money.
    function dev() external view returns (address) {
        return _owner;
    }

/* ========== VIEW FUNCTIONS ========== */

    // Some constants for timestamp -> date conversion.
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // Converts a uint256 timestamp (seconds since 1970) into human-readable year, month, and day.
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    // Some fancy math to convert a number of days into a human-readable date, courtesy of BokkyPooBah.
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    // Some fancy math to convert a uint into a string, courtesy of Provable Things.
    // Updated to work with solc 0.8.0.
    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}