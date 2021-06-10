/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/I_Token.sol

pragma solidity 0.5.0;

/**
 * @title   Interface Token
 * @notice  Allows the Curve contract to interact with the token contract
 *          without importing the entire smart contract. For documentation
 *          please see the token contract:
 *          https://gitlab.com/linumlabs/swarm-token
 * @dev     This is not a full interface of the token, but instead a partial
 *          interface covering only the functions that are needed by the curve.
 */
interface I_Token {
    // -------------------------------------------------------------------------
    // IERC20 functions
    // -------------------------------------------------------------------------

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // -------------------------------------------------------------------------
    // ERC20 functions
    // -------------------------------------------------------------------------

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    // -------------------------------------------------------------------------
    // ERC20 Detailed
    // -------------------------------------------------------------------------

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // -------------------------------------------------------------------------
    // Burnable functions
    // -------------------------------------------------------------------------

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    // -------------------------------------------------------------------------
    // Mintable functions
    // -------------------------------------------------------------------------

    function isMinter(address account) external view returns (bool);

    function addMinter(address account) external;

    function renounceMinter() external;

    function mint(address account, uint256 amount) external returns (bool);

    // -------------------------------------------------------------------------
    // Capped functions
    // -------------------------------------------------------------------------

    function cap() external view returns (uint256);
}

// File: contracts/I_Curve.sol

pragma solidity 0.5.0;

/**
 * @title   Interface Curve
 * @notice  This contract acts as an interface to the curve contract. For
 *          documentation please see the curve smart contract.
 */
interface I_Curve {
    
    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to buy
     * @return uint256 The cost to buy the _amount of tokens in the collateral
     *         currency (see collateral token).
     */
    function buyPrice(uint256 _amount)
        external
        view
        returns (uint256 collateralRequired);

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to sell
     * @return collateralReward The reward for selling the _amount of tokens in the
     *         collateral currency (see collateral token).
     */
    function sellReward(uint256 _amount)
        external
        view
        returns (uint256 collateralReward);

    /**
      * @return If the curve is both active and initialised.
      */
    function isCurveActive() external view returns (bool);

    /**
      * @return The address of the collateral token (DAI)
      */
    function collateralToken() external view returns (address);

    /**
      * @return The address of the bonded token (BZZ).
      */
    function bondedToken() external view returns (address);

    /**
      * @return The required collateral amount (DAI) to initialise the curve.
      */
    function requiredCollateral(uint256 _initialSupply)
        external
        view
        returns (uint256);

    // -------------------------------------------------------------------------
    // State modifying functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function initializes the curve contract, and ensure the
     *         curve has the required permissions on the token contract needed
     *         to function.
     */
    function init() external;

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mint(uint256 _amount, uint256 _maxCollateralSpend)
        external
        returns (bool success);

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @param  _to The address to send the tokens to.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mintTo(
        uint256 _amount, 
        uint256 _maxCollateralSpend, 
        address _to
    )
        external
        returns (bool success);

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to sell.
      * @param  _minCollateralReward The min amount of collateral (DAI) the user is
      *         willing to receive for their tokens.
      * @return The status of the burn. Note that should the total reward of the
      *         burn be below the _minCollateralReward the transaction will revert.
      */
    function redeem(uint256 _amount, uint256 _minCollateralReward)
        external
        returns (bool success);

    /**
      * @notice Shuts down the curve, disabling buying, selling and both price
      *         functions. Can only be called by the owner. Will renounce the
      *         minter role on the bonded token.
      */
    function shutDown() external;
}

// File: contracts/Curve.sol

pragma solidity 0.5.0;






contract Curve is Ownable, I_Curve {
    using SafeMath for uint256;
    // The instance of the token this curve controls (has mint rights to)
    I_Token internal bzz_;
    // The instance of the collateral token that is used to buy and sell tokens
    IERC20 internal dai_;
    // Stores if the curve has been initialised
    bool internal init_;
    // The active state of the curve (false after emergency shutdown)
    bool internal active_;
    // Mutex guard for state modifying functions
    uint256 private status_;
    // States for the guard 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    // Emitted when tokens are minted
    event mintTokens(
        address indexed buyer,      // The address of the buyer
        uint256 amount,             // The amount of bonded tokens to mint
        uint256 pricePaid,          // The price in collateral tokens 
        uint256 maxSpend            // The max amount of collateral to spend
    );
    // Emitted when tokens are minted
    event mintTokensTo(
        address indexed buyer,      // The address of the buyer
        address indexed receiver,   // The address of the receiver of the tokens
        uint256 amount,             // The amount of bonded tokens to mint
        uint256 pricePaid,          // The price in collateral tokens 
        uint256 maxSpend            // The max amount of collateral to spend
    );
    // Emitted when tokens are burnt
    event burnTokens(
        address indexed seller,     // The address of the seller
        uint256 amount,             // The amount of bonded tokens to sell
        uint256 rewardReceived,     // The collateral tokens received
        uint256 minReward           // The min collateral reward for tokens
    );
    // Emitted when the curve is permanently shut down
    event shutDownOccurred(address indexed owner);

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /**
      * @notice Requires the curve to be initialised and active.
      */
    modifier isActive() {
        require(active_ && init_, "Curve inactive");
        _;
    }

    /**
      * @notice Protects against re-entrancy attacks
      */
    modifier mutex() {
        require(status_ != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        status_ = _ENTERED;
        // Function executes
        _;
        // Status set to not entered
        status_ = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address _bondedToken, address _collateralToken) public Ownable() {
        bzz_ = I_Token(_bondedToken);
        dai_ = IERC20(_collateralToken);
        status_ = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to buy
     * @return uint256 The cost to buy the _amount of tokens in the collateral
     *         currency (see collateral token).
     */
    function buyPrice(uint256 _amount)
        public
        view
        isActive()
        returns (uint256 collateralRequired)
    {
        collateralRequired = _mint(_amount, bzz_.totalSupply());
        return collateralRequired;
    }

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to sell
     * @return collateralReward The reward for selling the _amount of tokens in the
     *         collateral currency (see collateral token).
     */
    function sellReward(uint256 _amount)
        public
        view
        isActive()
        returns (uint256 collateralReward)
    {
        (collateralReward, ) = _withdraw(_amount, bzz_.totalSupply());
        return collateralReward;
    }

    /**
      * @return If the curve is both active and initialised.
      */
    function isCurveActive() public view returns (bool) {
        if (active_ && init_) {
            return true;
        }
        return false;
    }

    /**
      * @param  _initialSupply The expected initial supply the bonded token
      *         will have.
      * @return The required collateral amount (DAI) to initialise the curve.
      */
    function requiredCollateral(uint256 _initialSupply)
        public
        view
        returns (uint256)
    {
        return _initializeCurve(_initialSupply);
    }

    /**
      * @return The address of the bonded token (BZZ).
      */
    function bondedToken() external view returns (address) {
        return address(bzz_);
    }

    /**
      * @return The address of the collateral token (DAI)
      */
    function collateralToken() external view returns (address) {
        return address(dai_);
    }

    // -------------------------------------------------------------------------
    // State modifying functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function initializes the curve contract, and ensure the
     *         curve has the required permissions on the token contract needed
     *         to function.
     */
    function init() external {
        // Checks the curve has not already been initialized
        require(!init_, "Curve is init");
        // Checks the curve has the correct permissions on the given token
        require(bzz_.isMinter(address(this)), "Curve is not minter");
        // Gets the total supply of the token
        uint256 initialSupply = bzz_.totalSupply();
        // The curve requires that the initial supply is at least the expected
        // open market supply
        require(
            initialSupply >= _MARKET_OPENING_SUPPLY,
            "Curve equation requires pre-mint"
        );
        // Gets the price for the current supply
        uint256 price = _initializeCurve(initialSupply);
        // Requires the transfer for the collateral needed to back fill for the
        // minted supply
        require(
            dai_.transferFrom(msg.sender, address(this), price),
            "Failed to collateralized the curve"
        );
        // Sets the Curve to being active and initialised
        active_ = true;
        init_ = true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mint(
        uint256 _amount, 
        uint256 _maxCollateralSpend
    )
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the price for the amount of tokens
        uint256 price = _commonMint(_amount, _maxCollateralSpend, msg.sender);
        // Emitting event with all important info
        emit mintTokens(
            msg.sender, 
            _amount, 
            price, 
            _maxCollateralSpend
        );
        // Returning that the mint executed successfully
        return true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @param  _to The address to send the tokens to.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mintTo(
        uint256 _amount, 
        uint256 _maxCollateralSpend, 
        address _to
    )
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the price for the amount of tokens
        uint256 price =  _commonMint(_amount, _maxCollateralSpend, _to);
        // Emitting event with all important info
        emit mintTokensTo(
            msg.sender,
            _to, 
            _amount, 
            price, 
            _maxCollateralSpend
        );
        // Returning that the mint executed successfully
        return true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to sell.
      * @param  _minCollateralReward The min amount of collateral (DAI) the user is
      *         willing to receive for their tokens.
      * @return The status of the burn. Note that should the total reward of the
      *         burn be below the _minCollateralReward the transaction will revert.
      */
    function redeem(uint256 _amount, uint256 _minCollateralReward)
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the reward for the amount of tokens
        uint256 reward = sellReward(_amount);
        // Checks the reward has not slipped below the min amount the user
        // wishes to receive.
        require(reward >= _minCollateralReward, "Reward under min sell");
        // Burns the number of tokens (fails - no bool return)
        bzz_.burnFrom(msg.sender, _amount);
        // Transfers the reward from the curve to the collateral token
        require(
            dai_.transfer(msg.sender, reward),
            "Transferring collateral failed"
        );
        // Emitting event with all important info
        emit burnTokens(
            msg.sender, 
            _amount, 
            reward, 
            _minCollateralReward
        );
        // Returning that the burn executed successfully
        return true;
    }

    /**
      * @notice Shuts down the curve, disabling buying, selling and both price
      *         functions. Can only be called by the owner. Will renounce the
      *         minter role on the bonded token.
      */
    function shutDown() external onlyOwner() {
        // Removes the curve as a minter on the token
        bzz_.renounceMinter();
        // Irreversibly shuts down the curve
        active_ = false;
        // Emitting address of owner who shut down curve permanently
        emit shutDownOccurred(msg.sender);
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @param  _to The address to send the tokens to.
      * @return uint256 The price the user has paid for buying the _amount of 
      *         BUZZ tokens. 
      */
    function _commonMint(
        uint256 _amount,
        uint256 _maxCollateralSpend,
        address _to
    )
        internal
        returns(uint256)
    {
        // Gets the price for the amount of tokens
        uint256 price = buyPrice(_amount);
        // Checks the price has not risen above the max amount the user wishes
        // to spend.
        require(price <= _maxCollateralSpend, "Price exceeds max spend");
        // Transfers the price of tokens in the collateral token to the curve
        require(
            dai_.transferFrom(msg.sender, address(this), price),
            "Transferring collateral failed"
        );
        // Mints the user their tokens
        require(bzz_.mint(_to, _amount), "Minting tokens failed");
        // Returns the price the user will pay for buy
        return price;
    }

    // -------------------------------------------------------------------------
    // Curve mathematical functions

    uint256 internal constant _BZZ_SCALE = 1e16;
    uint256 internal constant _N = 5;
    uint256 internal constant _MARKET_OPENING_SUPPLY = 62500000 * _BZZ_SCALE;
    // Equation for curve: 

    /**
     * @param   x The supply to calculate at.
     * @return  x^32/_MARKET_OPENING_SUPPLY^5
     * @dev     Calculates the 32 power of `x` (`x` squared 5 times) times a 
     *          constant. Each time it squares the function it divides by the 
     *          `_MARKET_OPENING_SUPPLY` so when `x` = `_MARKET_OPENING_SUPPLY` 
     *          it doesn't change `x`. 
     *
     *          `c*x^32` | `c` is chosen in such a way that 
     *          `_MARKET_OPENING_SUPPLY` is the fixed point of the helper 
     *          function.
     *
     *          The division by `_MARKET_OPENING_SUPPLY` also helps avoid an 
     *          overflow.
     *
     *          The `_helper` function is separate to the `_primitiveFunction` 
     *          as we modify `x`. 
     */
    function _helper(uint256 x) internal view returns (uint256) {
        for (uint256 index = 1; index <= _N; index++) {
            x = (x.mul(x)).div(_MARKET_OPENING_SUPPLY);
        }
        return x;
    }

    /**
     * @param   s The supply point being calculated for. 
     * @return  The amount of DAI required for the requested amount of BZZ (s). 
     * @dev     `s` is being added because it is the linear term in the 
     *          polynomial (this ensures no free BUZZ tokens).
     *
     *          primitive function equation: s + c*s^32.
     * 
     *          See the helper function for the definition of `c`.
     *
     *          Converts from something measured in BZZ (1e16) to dai atomic 
     *          units 1e18.
     */
    function _primitiveFunction(uint256 s) internal view returns (uint256) {
        return s.add(_helper(s));
    }

    /**
     * @param  _supply The number of tokens that exist.
     * @return uint256 The price for the next token up the curve.
     */
    function _spotPrice(uint256 _supply) internal view returns (uint256) {
        return (_primitiveFunction(_supply.add(1)).sub(_primitiveFunction(_supply)));
    }

    /**
     * @param  _amount The amount of tokens to be minted
     * @param  _currentSupply The current supply of tokens
     * @return uint256 The cost for the tokens
     * @return uint256 The price being paid per token
     */
    function _mint(uint256 _amount, uint256 _currentSupply)
        internal
        view
        returns (uint256)
    {
        uint256 deltaR = _primitiveFunction(_currentSupply.add(_amount)).sub(
            _primitiveFunction(_currentSupply));
        return deltaR;
    }

    /**
     * @param  _amount The amount of tokens to be sold
     * @param  _currentSupply The current supply of tokens
     * @return uint256 The reward for the tokens
     * @return uint256 The price being received per token
     */
    function _withdraw(uint256 _amount, uint256 _currentSupply)
        internal
        view
        returns (uint256, uint256)
    {
        assert(_currentSupply - _amount > 0);
        uint256 deltaR = _primitiveFunction(_currentSupply).sub(
            _primitiveFunction(_currentSupply.sub(_amount)));
        uint256 realized_price = deltaR.div(_amount);
        return (deltaR, realized_price);
    }

    /**
     * @param  _initial_supply The supply the curve is going to start with.
     * @return initial_reserve How much collateral is needed to collateralized
     *         the bonding curve.
     * @return price The price being paid per token (averaged).
     */
    function _initializeCurve(uint256 _initial_supply)
        internal
        view
        returns (uint256 price)
    {
        price = _mint(_initial_supply, 0);
        return price;
    }
}