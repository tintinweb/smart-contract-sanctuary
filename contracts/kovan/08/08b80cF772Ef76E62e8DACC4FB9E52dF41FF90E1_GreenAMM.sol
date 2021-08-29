// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@yield-protocol/utils-v2/contracts/access/Ownable.sol";
import "@yield-protocol/utils-v2/contracts/token/ERC20.sol";

/**
@dev Internal library that implements Fixed Point Math
WADs are fixed point numbers with decimals=18
 */
library FPMath {
    // /**
    // @notice Multiply 2 WADs
    // */
    uint256 internal constant WAD = 1e18;

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / WAD;
    }

    /// @dev div 2 WADs
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD) / b;
    }
}

/// @dev placeholder to keep all token-related data
struct TokenData {
    uint256 reserves;
    // ended up not needing anything else
}

/**
@notice 'Engine' of the standard xy=k AMM contract
 */
abstract contract GreenAMMEngine is Ownable {
    bool internal isInitialized;

    /// @dev info about X token
    TokenData public x;
    /// @dev info about Y token
    TokenData public y;

    /// @dev K from X*Y=K
    /// IMIPORTANT: K has 36 decimals
    uint256 public k;

    event KChanged(uint256 newK);
    event Inited(uint256 x, uint256 y);
    event Minted(uint256 x, uint256 y);
    event Burned(uint256 x, uint256 y);
    event SoldX(uint256 x, uint256 y);
    event SoldY(uint256 x, uint256 y);

    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized, "already initialized");
        _;
    }

    /// @dev asserts that amountX/amountY have same ratio as existing reserves
    modifier maintainsBalance(uint256 amountX, uint256 amountY) {
        require(x.reserves != 0 && y.reserves != 0, "Empty pool");

        // since decimals for X and Y are unchanged, don't bother computing *exact* value for x/y:
        // x1 * dec_x / y1 * dec_y == x2 * dec_x / y2 * dec_y IMPLIES x1/y1 == x2/y2
        // x1/y1 == x2/y2 IS EQUIVALENT to x1 * y2 == x2 * y1
        require(x.reserves * amountY == y.reserves * amountX, "Unbalancing");
        _;
    }

    /**
    @notice constructor
    @param xDecimals decimals of X token
    @param yDecimals decimals of Y token

    Only 18-decimal tokens are supported
     */
    constructor(uint8 xDecimals, uint8 yDecimals) {
        require(xDecimals == 18, "Only WAD-denominated tokens are supported");
        require(yDecimals == 18, "Only WAD-denominated tokens are supported");
        x = TokenData(0);
        y = TokenData(0);
    }

    /// @dev recompute K based on new reserve numbers
    function kRecompute() internal {
        k = x.reserves * y.reserves; // use increased precision
        emit KChanged(k);
    }

    /**
    @notice 'State Chage' function for 'Init' method
    @param amountX X tokens to deposit
    @param amountY Y tokens to deposit
    @return new K value
     */
    function stateChangeInit(uint256 amountX, uint256 amountY) internal notInitialized onlyOwner returns (uint256) {
        require(amountX != 0 && amountY != 0, "Can't create empty pool");

        isInitialized = true;

        x.reserves += amountX;
        y.reserves += amountY;

        kRecompute();
        return k;
    }

    /**
    @notice 'State Chage' function for 'Mint' method
    @param amountX X tokens to deposit
    @param amountY Y tokens to deposit
    @return rewardsFraction how many AMM tokens need to be issued (36-decimal fraction of total supply)
     */
    function stateChangeMint(uint256 amountX, uint256 amountY)
        internal
        initialized
        maintainsBalance(amountX, amountY)
        returns (uint256 rewardsFraction)
    {
        rewardsFraction = FPMath.wadDiv(amountX, x.reserves);

        x.reserves += amountX;
        y.reserves += amountY;

        kRecompute();
    }

    /**
    @notice 'State Chage' function for 'Burn' method
    @param amountX X tokens to burn
    @param amountY Y tokens to burn
    @return rewardsFraction how many AMM tokens need to be burned (36-decimal fraction of total supply)
     */
    function stateChangeBurn(uint256 amountX, uint256 amountY)
        internal
        initialized
        maintainsBalance(amountX, amountY)
        returns (uint256 rewardsFraction)
    {
        rewardsFraction = FPMath.wadDiv(amountX, x.reserves);

        x.reserves -= amountX;
        y.reserves -= amountY;

        kRecompute();

        // BurnInteraction(amountX, amountY, rewardsAmount);
    }

    /**
    @notice 'State Chage' function for 'SellX' method
    @param amountX X tokens to add to reserves
    @return how many Y tokens need to be returned to the user
     */
    function stateChangeSellX(uint256 amountX) internal initialized returns (uint256) {
        // (x + A) * (y - B) = k
        // y - B = k / (x + A)
        // B = y - k / (x + A)
        uint256 amountY = y.reserves - k / (x.reserves + amountX);
        x.reserves += amountX;
        y.reserves -= amountY;

        return amountY;
    }

    /**
    @notice 'State Chage' function for 'SellY' method
    @param amountY Y tokens to add to reserves
    @return how many X tokens need to be returned to the user
     */

    function stateChangeSellY(uint256 amountY) internal initialized returns (uint256) {
        uint256 amountX = x.reserves - k / (y.reserves + amountY);
        x.reserves -= amountX;
        y.reserves += amountY;

        return amountX;
    }
}

/**
@notice Standard k=xy AMM contract
 */
contract GreenAMM is ERC20("GreenAMMToken", "OWL_GAMT", 36), GreenAMMEngine {
    /// @dev X token
    IERC20Metadata internal xToken;
    /// @dev Y token
    IERC20Metadata internal yToken;

    constructor(IERC20Metadata _x, IERC20Metadata _y) GreenAMMEngine(_x.decimals(), _y.decimals()) {
        require(address(_x) != address(_y), "bad pair");
        xToken = _x;
        yToken = _y;
    }

    /**
    @notice Supply any amount of x and y to the contract
    Mint k AMM tokens to sender. Can only be called once.

    @param amountX X tokens to deposit
    @param amountY Y tokens to deposit
    */
    function Init(uint256 amountX, uint256 amountY) public {
        uint256 rewardsAmount = stateChangeInit(amountX, amountY);
        _mint(msg.sender, rewardsAmount);

        xToken.transferFrom(msg.sender, address(this), amountX);
        yToken.transferFrom(msg.sender, address(this), amountY);

        emit Inited(amountX, amountY);
    }

    /**
    @notice x and y are supplied to the contract in the same proportion as the x and y balances of the contract
    Mint AMM tokens to sender as the proportion of their deposit to the AMM reserves

    @param amountX X tokens to deposit
    @param amountY Y tokens to deposit
    */
    function Mint(uint256 amountX, uint256 amountY) public {
        uint256 rewardsAmount = FPMath.wadMul(stateChangeMint(amountX, amountY), _totalSupply);

        _mint(msg.sender, rewardsAmount);

        xToken.transferFrom(msg.sender, address(this), amountX);
        yToken.transferFrom(msg.sender, address(this), amountY);

        emit Minted(amountX, amountY);
    }

    /**
    @notice AMM tokens are burned
    The AMM sends x and y tokens to the caller in the proportion of tokens burned to AMM total supply

    @param amountX X tokens to burn
    @param amountY Y tokens to burn
    */
    function Burn(uint256 amountX, uint256 amountY) public {
        uint256 rewardsAmount = FPMath.wadMul(stateChangeBurn(amountX, amountY), _totalSupply);

        _burn(msg.sender, rewardsAmount);

        xToken.transfer(msg.sender, amountX);
        yToken.transfer(msg.sender, amountY);

        emit Burned(amountX, amountY);
    }

    /**
    @notice The user provides x
    The AMM sends y to the user so that x_reserves * y_reserves remains at k

    @param amountX X tokens the user sells
    */
    function SellX(uint256 amountX) public {
        uint256 amountY = stateChangeSellX(amountX);

        xToken.transferFrom(msg.sender, address(this), amountX);
        yToken.transfer(msg.sender, amountY);

        emit SoldX(amountX, amountY);
    }

    /**
    @notice The user provides y
    The AMM sends x to the user so that x_reserves * y_reserves remains at k

    @param amountY Y tokens the user sells
    */
    function SellY(uint256 amountY) public {
        uint256 amountX = stateChangeSellY(amountY);

        yToken.transferFrom(msg.sender, address(this), amountY);
        xToken.transfer(msg.sender, amountX);

        emit SoldY(amountX, amountY);
    }
}

/**
@dev SMTChecker test for GreenAMMEngine

Each invariant ends with 'revert' to workaround the fact that the Engine is stateful
 */
contract GreenAMMEngineTest is GreenAMMEngine {
    constructor(uint8 xDecimals, uint8 yDecimals) GreenAMMEngine(xDecimals, yDecimals) {}

    /// @dev Init test: K is recomputed
    function invInit(uint256 amountX, uint256 amountY) public {
        uint256 tokens = stateChangeInit(amountX, amountY);
        assert(tokens == k);
        revert("inv");
    }

    /// @dev Mint test: K is recomputed and tokens ratio stay the same
    function invMint(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) public {
        require(x1 != 0, "inv");
        require(x2 != 0, "inv");
        require(y1 != 0, "inv");
        require(y2 != 0, "inv");

        uint256 supply1 = stateChangeInit(x1, y1);
        uint256 supply2 = FPMath.wadMul(stateChangeMint(x2, y2), supply1);
        assert(x2 / x1 == supply2 / supply1);
        revert("inv");
    }

    /// @dev sell X: K is unchanged
    function invSellX(
        uint256 x1,
        uint256 y1,
        uint256 sellAmount
    ) public {
        require(x1 != 0, "inv");
        require(y1 != 0, "inv");

        stateChangeInit(x1, y1);
        uint256 oldK = k;
        uint256 oldX = x.reserves;
        stateChangeSellX(sellAmount);

        assert(k == oldK);
        assert(x.reserves == oldX + sellAmount);

        assert(x.reserves * y.reserves == k);
        revert("inv");
    }

    /// @dev sell Y: K is unchanged
    function invSellY(
        uint256 x1,
        uint256 y1,
        uint256 sellAmount
    ) public {
        require(x1 != 0, "inv");
        require(y1 != 0, "inv");

        stateChangeInit(x1, y1);
        uint256 oldK = k;
        uint256 oldY = y.reserves;
        stateChangeSellY(sellAmount);

        assert(k == oldK);
        assert(y.reserves == oldY + sellAmount);

        assert(x.reserves * y.reserves == oldK);
        revert("inv");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * 
 * Calls to {transferFrom} do not check for allowance if the caller is the owner
 * of the funds. This allows to reduce the number of approvals that are necessary.
 *
 * Finally, {transferFrom} does not decrease the allowance if it is set to
 * type(uint256).max. This reduces the gas costs without any likely impact.
 */
contract ERC20 is IERC20Metadata {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public override name = "???";
    string                                            public override symbol = "???";
    uint8                                             public override decimals = 18;

    /**
     *  @dev Sets the values for {name}, {symbol} and {decimals}.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address guy) external view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint wad) external virtual override returns (bool) {
        return _setAllowance(msg.sender, spender, wad);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `wad`.
     */
    function transfer(address dst, uint wad) external virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `wad`.
     * - the caller is not `src`, it must have allowance for ``src``'s tokens of at least
     * `wad`.
     */
    /// if_succeeds {:msg "TransferFrom - decrease allowance"} msg.sender != src ==> old(_allowance[src][msg.sender]) >= wad;
    function transferFrom(address src, address dst, uint wad) external virtual override returns (bool) {
        _decreaseAllowance(src, wad);

        return _transfer(src, dst, wad);
    }

    /**
     * @dev Moves tokens `wad` from `src` to `dst`.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `src` must have a balance of at least `amount`.
     */
    /// if_succeeds {:msg "Transfer - src decrease"} old(_balanceOf[src]) >= _balanceOf[src];
    /// if_succeeds {:msg "Transfer - dst increase"} _balanceOf[dst] >= old(_balanceOf[dst]);
    /// if_succeeds {:msg "Transfer - supply"} old(_balanceOf[src]) + old(_balanceOf[dst]) == _balanceOf[src] + _balanceOf[dst];
    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        unchecked { _balanceOf[src] = _balanceOf[src] - wad; }
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    /**
     * @dev Decreases the allowance granted to the caller by `src`, unless src == msg.sender or _allowance[src][msg.sender] == MAX
     *
     * Emits an {Approval} event indicating the updated allowance, if the allowance is updated.
     *
     * Requirements:
     *
     * - `spender` must have allowance for the caller of at least
     * `wad`, unless src == msg.sender
     */
    /// if_succeeds {:msg "Decrease allowance - underflow"} old(_allowance[src][msg.sender]) <= _allowance[src][msg.sender];
    function _decreaseAllowance(address src, uint wad) internal virtual returns (bool) {
        if (src != msg.sender) {
            uint256 allowed = _allowance[src][msg.sender];
            if (allowed != type(uint).max) {
                require(allowed >= wad, "ERC20: Insufficient approval");
                unchecked { _setAllowance(src, msg.sender, allowed - wad); }
            }
        }

        return true;
    }

    /** @dev Creates `wad` tokens and assigns them to `dst`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    /// if_succeeds {:msg "Mint - balance overflow"} old(_balanceOf[dst]) >= _balanceOf[dst];
    /// if_succeeds {:msg "Mint - supply overflow"} old(_totalSupply) >= _totalSupply;
    function _mint(address dst, uint wad) internal virtual returns (bool) {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);

        return true;
    }

    /**
     * @dev Destroys `wad` tokens from `src`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `src` must have at least `wad` tokens.
     */
    /// if_succeeds {:msg "Burn - balance underflow"} old(_balanceOf[src]) <= _balanceOf[src];
    /// if_succeeds {:msg "Burn - supply underflow"} old(_totalSupply) <= _totalSupply;
    function _burn(address src, uint wad) internal virtual returns (bool) {
        unchecked {
            require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
            _balanceOf[src] = _balanceOf[src] - wad;
            _totalSupply = _totalSupply - wad;
            emit Transfer(src, address(0), wad);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

{
  "modelChecker": null,
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}