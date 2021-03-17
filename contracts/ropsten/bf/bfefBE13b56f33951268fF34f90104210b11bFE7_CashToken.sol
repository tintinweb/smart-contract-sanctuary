// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./ICash.sol";

/**
 * @title Gateway Cash Token
 * @author Compound Finance
 * @notice The Gateway Cash Token for Ethereum
 */
contract CashToken is ICash {
    // @notice Structure to save gas while storing yield and index
    struct CashYieldAndIndex {
        uint128 yield;
        uint128 index;
    }

    /// @notice The number of seconds in the year, used for Cash index calculations
    uint public constant SECONDS_PER_YEAR = 31536000;

    /// @notice The denomination of Cash index
    uint public constant indexBaseUnit = 1e18;

    /// @notice The denomination of `exponent` result
    uint public constant expBaseUnit = 1e18;

    /// @notice The denomination of Cash APY BPS
    uint public constant bpsBaseUnit = 1e4;

    /// @notice The admin of contract, address of `Starport` contract
    address immutable public admin;

    /// @notice The timestamp when current Cash yield and index are activated
    uint public cashYieldStart;

    /// @notice The Cash yield and index values
    CashYieldAndIndex public cashYieldAndIndex;

    /// @notice The timestamp when next Cash yield and index should be activated
    uint public nextCashYieldStart;

    /// @notice The next Cash yield and index values
    CashYieldAndIndex public nextCashYieldAndIndex;

    /// @notice See {IERC20-allowance}
    mapping (address => mapping (address => uint)) public allowances;

    /// @notice The total amount of minted Cash principal
    uint public totalCashPrincipal;

    /// @notice The amount of cash principal per account
    mapping (address => uint128) public cashPrincipal;

    bool public initialized = false;

    /**
     * @notice Construct a Cash Token
     * @dev You must call `initialize()` after construction
     * @param admin_ The address of admin
     */
    constructor(address admin_) {
        admin = admin_;
    }

    /**
     * @notice Initialize Cash token contract
     * @param initialYield The initial value for Cash token APY in BPS (e.g. 100=1%)
     * @param initialYieldStart The timestamp when Cash index and yield were activated on Gateway
     */
    function initialize(uint128 initialYield, uint initialYieldStart) external {
        require(initialized == false, "Cash Token already initialized");

        // Note: we don't check that this is in the past, but calls will revert until it is.
        cashYieldStart = initialYieldStart;
        cashYieldAndIndex = CashYieldAndIndex({yield: initialYield, index: 1e18});

        initialized = true;
    }

    /**
     * Section: Ethereum Asset Interface
     */

    /**
     * @notice Mint Cash tokens for the given account
     * @dev Invoked by Starport contract
     * @dev principal is `u128` to be compliant with Gateway
     * @param account The owner of minted Cash tokens
     * @param principal The principal amount of minted Cash tokens
     * @return The minted amount of Cash tokens = principal * index
     */
    function mint(address account, uint128 principal) external override returns (uint) {
        require(msg.sender == admin, "Must be admin");
        uint amount = principal * getCashIndex() / indexBaseUnit;
        cashPrincipal[account] += principal;
        totalCashPrincipal = totalCashPrincipal + principal;
        emit Transfer(address(0), account, amount);
        return amount;
    }

    /**
     * @notice Burn Cash tokens for the given account
     * @dev Invoked by Starport contract
     * @dev principal is `u128` to be compliant with Gateway
     * @param account The owner of burned Cash tokens
     * @param amount The amount of burned Cash tokens
     * @return The amount of burned principal = amount / index
     */
    function burn(address account, uint amount) external override returns (uint128) {
        require(msg.sender == admin, "Must be admin");
        uint128 principal = amountToPrincipal(amount);
        cashPrincipal[account] -= principal;
        totalCashPrincipal = totalCashPrincipal - principal;
        emit Transfer(account, address(0), amount);
        return principal;
    }

    /**
     * @notice Update yield and index to be in sync with Gateway
     * @dev It is expected to be called at least once per day
     * @dev Cash index denomination is 1e18
     * @param nextYield The new value of Cash APY measured in BPS
     * @param nextIndex The new value of Cash index
     * @param nextYieldStart The timestamp when new values for cash and index are activated
     */
    function setFutureYield(uint128 nextYield, uint128 nextIndex, uint nextYieldStart) external override {
        require(msg.sender == admin, "Must be admin");
        require(nextYield <= 1e4, "Invalid yield range");
        require(nextYieldStart > cashYieldStart, "Invalid yield start");
        uint nextStart = nextCashYieldStart;

        // Updating cash yield and index to the 'old' next values
        if (nextStart != 0 && block.timestamp > nextStart) {
            cashYieldStart = nextStart;
            cashYieldAndIndex = nextCashYieldAndIndex;
        }
        nextCashYieldStart = nextYieldStart;
        nextCashYieldAndIndex = CashYieldAndIndex({yield: nextYield, index: nextIndex});

        emit SetFutureYield(nextYield, nextIndex, nextYieldStart);
    }

    /**
     * @notice Get current cash index
     * @dev Since function is `view` and cannot modify storage,
            the check for next index and yield values was added
     * @return The current cash index, 18 decimals
     */
    function getCashIndex() public view virtual override returns (uint128) {
        uint nextStart = nextCashYieldStart;
        if (nextStart != 0 && block.timestamp > nextStart) {
            return calculateIndex(nextCashYieldAndIndex.yield, nextCashYieldAndIndex.index, nextStart);
        } else {
            return calculateIndex(cashYieldAndIndex.yield, cashYieldAndIndex.index, cashYieldStart);
        }
    }

    /**
     * Section: ERC20 Interface
     */

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view override returns (uint) {
        return totalCashPrincipal * getCashIndex() / indexBaseUnit;
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) view external override returns (uint) {
        return cashPrincipal[account] * getCashIndex() / indexBaseUnit;
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     * @return a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        require(msg.sender != recipient, "Invalid recipient");
        uint128 principal = amountToPrincipal(amount);
        cashPrincipal[recipient] += principal;
        cashPrincipal[msg.sender] -= principal;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

     /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @return a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != recipient, "Invalid recipient");
        address spender = msg.sender;
        uint128 principal = amountToPrincipal(amount);
        allowances[sender][spender] -= amount;
        cashPrincipal[recipient] += principal;
        cashPrincipal[sender] -= principal;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Returns the name of the token.
     */
    function name() external pure returns (string memory) {
        return "Cash";
    }

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external pure returns (string memory) {
        return "CASH";
    }

    /**
     * @notice Returns the number of decimals
     */
    function decimals() external pure returns (uint8) {
        return 6;
    }

    /**
     * Section: Function Helpers
     */

    // Helper function to conver amount to principal using current Cash index
    function amountToPrincipal(uint amount) public view returns (uint128) {
        uint256 principal = amount * indexBaseUnit / getCashIndex();
        require(principal < type(uint128).max, "amountToPrincipal::overflow");
        return uint128(principal);
    }

    // Helper function to calculate current Cash index
    // Note: Formula for continuos compounding interest -> A = Pe^rt,
    //       current_index = base_index * e^(yield * time_ellapsed)
    //       yield is in BPS, so 300 = 3% = 0.03
    function calculateIndex(uint128 yield, uint128 index, uint start) public view returns (uint128) {
        require(index > 0, "Cash Token uninitialized");
        uint newIndex = index * exponent(yield, block.timestamp - start) / expBaseUnit;
        require(newIndex < type(uint128).max, "calculateIndex::overflow");
        return uint128(newIndex);
    }

    // Helper function to calculate e^rt part from countinous compounding interest formula
    // Note: We use the third degree approximation of Taylor Series
    //       1 + x/1! + x^2/2! + x^3/3!
    function exponent(uint128 yield, uint time) public pure returns (uint) {
        uint scale = expBaseUnit / bpsBaseUnit;
        uint epower = yield * time * scale / SECONDS_PER_YEAR;
        uint first = epower * expBaseUnit ** 2;
        uint second = epower * epower * expBaseUnit / 2;
        uint third = epower * epower * epower / 6;
        return (expBaseUnit ** 3 + first + second + third) / expBaseUnit ** 2;
    }
}