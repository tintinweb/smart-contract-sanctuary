// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/spec_interfaces/IProtocolWallet.sol

pragma solidity 0.6.12;


/// @title Protocol Wallet interface
interface IProtocolWallet {
    event FundsAddedToPool(uint256 added, uint256 total);

    /*
    * External functions
    */

    /// Returns the address of the underlying staked token
    /// @return balance is the wallet balance
    function getBalance() external view returns (uint256 balance);

    /// Transfers the given amount of orbs tokens form the sender to this contract and updates the pool
    /// @dev assumes the caller approved the amount prior to calling
    /// @param amount is the amount to add to the wallet
    function topUp(uint256 amount) external;

    /// Withdraws from pool to the client address, limited by the pool's MaxRate.
    /// @dev may only be called by the wallet client
    /// @dev no more than MaxRate x time period since the last withdraw may be withdrawn
    /// @dev allocation that wasn't withdrawn can not be withdrawn in the next call
    /// @param amount is the amount to withdraw
    function withdraw(uint256 amount) external; /* onlyClient */


    /*
    * Governance functions
    */

    event ClientSet(address client);
    event MaxAnnualRateSet(uint256 maxAnnualRate);
    event EmergencyWithdrawal(address addr, address token);
    event OutstandingTokensReset(uint256 startTime);

    /// Sets a new annual withdraw rate for the pool
    /// @dev governance function called only by the migration owner
    /// @dev the rate for a duration is duration x annualRate / 1 year 
    /// @param _annualRate is the maximum annual rate that can be withdrawn
    function setMaxAnnualRate(uint256 _annualRate) external; /* onlyMigrationOwner */

    /// Returns the annual withdraw rate of the pool
    /// @return annualRate is the maximum annual rate that can be withdrawn
    function getMaxAnnualRate() external view returns (uint256);

    /// Resets the outstanding tokens to new start time
    /// @dev governance function called only by the migration owner
    /// @dev the next duration will be calculated starting from the given time
    /// @param startTime is the time to set as the last withdrawal time
    function resetOutstandingTokens(uint256 startTime) external; /* onlyMigrationOwner */

    /// Emergency withdraw the wallet funds
    /// @dev governance function called only by the migration owner
    /// @dev used in emergencies, when a migration to a new wallet is needed
    /// @param erc20 is the erc20 address of the token to withdraw
    function emergencyWithdraw(address erc20) external; /* onlyMigrationOwner */

    /// Sets the address of the client that can withdraw funds
    /// @dev governance function called only by the functional owner
    /// @param _client is the address of the new client
    function setClient(address _client) external; /* onlyFunctionalOwner */

}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/WithClaimableMigrationOwnership.sol

pragma solidity 0.6.12;


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableMigrationOwnership is Context{
    address private _migrationOwner;
    address private _pendingMigrationOwner;

    event MigrationOwnershipTransferred(address indexed previousMigrationOwner, address indexed newMigrationOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial migrationMigrationOwner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _migrationOwner = msgSender;
        emit MigrationOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current migrationOwner.
     */
    function migrationOwner() public view returns (address) {
        return _migrationOwner;
    }

    /**
     * @dev Throws if called by any account other than the migrationOwner.
     */
    modifier onlyMigrationOwner() {
        require(isMigrationOwner(), "WithClaimableMigrationOwnership: caller is not the migrationOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current migrationOwner.
     */
    function isMigrationOwner() public view returns (bool) {
        return _msgSender() == _migrationOwner;
    }

    /**
     * @dev Leaves the contract without migrationOwner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current migrationOwner.
     *
     * NOTE: Renouncing migrationOwnership will leave the contract without an migrationOwner,
     * thereby removing any functionality that is only available to the migrationOwner.
     */
    function renounceMigrationOwnership() public onlyMigrationOwner {
        emit MigrationOwnershipTransferred(_migrationOwner, address(0));
        _migrationOwner = address(0);
    }

    /**
     * @dev Transfers migrationOwnership of the contract to a new account (`newOwner`).
     */
    function _transferMigrationOwnership(address newMigrationOwner) internal {
        require(newMigrationOwner != address(0), "MigrationOwner: new migrationOwner is the zero address");
        emit MigrationOwnershipTransferred(_migrationOwner, newMigrationOwner);
        _migrationOwner = newMigrationOwner;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingMigrationOwner() {
        require(msg.sender == _pendingMigrationOwner, "Caller is not the pending migrationOwner");
        _;
    }
    /**
     * @dev Allows the current migrationOwner to set the pendingOwner address.
     * @param newMigrationOwner The address to transfer migrationOwnership to.
     */
    function transferMigrationOwnership(address newMigrationOwner) public onlyMigrationOwner {
        _pendingMigrationOwner = newMigrationOwner;
    }
    /**
     * @dev Allows the _pendingMigrationOwner address to finalize the transfer.
     */
    function claimMigrationOwnership() external onlyPendingMigrationOwner {
        _transferMigrationOwnership(_pendingMigrationOwner);
        _pendingMigrationOwner = address(0);
    }

    /**
     * @dev Returns the current _pendingMigrationOwner
    */
    function pendingMigrationOwner() public view returns (address) {
       return _pendingMigrationOwner;  
    }
}

// File: contracts/WithClaimableFunctionalOwnership.sol

pragma solidity 0.6.12;


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableFunctionalOwnership is Context{
    address private _functionalOwner;
    address private _pendingFunctionalOwner;

    event FunctionalOwnershipTransferred(address indexed previousFunctionalOwner, address indexed newFunctionalOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial functionalFunctionalOwner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _functionalOwner = msgSender;
        emit FunctionalOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current functionalOwner.
     */
    function functionalOwner() public view returns (address) {
        return _functionalOwner;
    }

    /**
     * @dev Throws if called by any account other than the functionalOwner.
     */
    modifier onlyFunctionalOwner() {
        require(isFunctionalOwner(), "WithClaimableFunctionalOwnership: caller is not the functionalOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current functionalOwner.
     */
    function isFunctionalOwner() public view returns (bool) {
        return _msgSender() == _functionalOwner;
    }

    /**
     * @dev Leaves the contract without functionalOwner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current functionalOwner.
     *
     * NOTE: Renouncing functionalOwnership will leave the contract without an functionalOwner,
     * thereby removing any functionality that is only available to the functionalOwner.
     */
    function renounceFunctionalOwnership() public onlyFunctionalOwner {
        emit FunctionalOwnershipTransferred(_functionalOwner, address(0));
        _functionalOwner = address(0);
    }

    /**
     * @dev Transfers functionalOwnership of the contract to a new account (`newOwner`).
     */
    function _transferFunctionalOwnership(address newFunctionalOwner) internal {
        require(newFunctionalOwner != address(0), "FunctionalOwner: new functionalOwner is the zero address");
        emit FunctionalOwnershipTransferred(_functionalOwner, newFunctionalOwner);
        _functionalOwner = newFunctionalOwner;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingFunctionalOwner() {
        require(msg.sender == _pendingFunctionalOwner, "Caller is not the pending functionalOwner");
        _;
    }
    /**
     * @dev Allows the current functionalOwner to set the pendingOwner address.
     * @param newFunctionalOwner The address to transfer functionalOwnership to.
     */
    function transferFunctionalOwnership(address newFunctionalOwner) public onlyFunctionalOwner {
        _pendingFunctionalOwner = newFunctionalOwner;
    }
    /**
     * @dev Allows the _pendingFunctionalOwner address to finalize the transfer.
     */
    function claimFunctionalOwnership() external onlyPendingFunctionalOwner {
        _transferFunctionalOwnership(_pendingFunctionalOwner);
        _pendingFunctionalOwner = address(0);
    }

    /**
     * @dev Returns the current _pendingFunctionalOwner
    */
    function pendingFunctionalOwner() public view returns (address) {
       return _pendingFunctionalOwner;  
    }
}

// File: contracts/ProtocolWallet.sol

pragma solidity 0.6.12;






/// @title Protocol Wallet contract
/// @dev the protocol wallet utilizes two claimable owners: migrationOwner and functionalOwner
contract ProtocolWallet is IProtocolWallet, WithClaimableMigrationOwnership, WithClaimableFunctionalOwnership {
    using SafeMath for uint256;

    IERC20 public token;
    address public client;
    uint256 public lastWithdrawal;
    uint256 maxAnnualRate;

    /// Constructor
    /// @param _token is the wallet token
    /// @param _client is the initial wallet client address
    /// @param _maxAnnualRate is the maximum annual rate that can be withdrawn
    constructor(IERC20 _token, address _client, uint256 _maxAnnualRate) public {
        token = _token;
        client = _client;
        lastWithdrawal = block.timestamp;

        setMaxAnnualRate(_maxAnnualRate);
    }

    modifier onlyClient() {
        require(msg.sender == client, "caller is not the wallet client");

        _;
    }

    /*
    * External functions
    */

    /// Returns the address of the underlying staked token
    /// @return balance is the wallet balance
    function getBalance() public override view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }

    /// Transfers the given amount of orbs tokens form the sender to this contract and updates the pool
    /// @dev assumes the caller approved the amount prior to calling
    /// @param amount is the amount to add to the wallet
    function topUp(uint256 amount) external override {
        emit FundsAddedToPool(amount, getBalance().add(amount));
        require(token.transferFrom(msg.sender, address(this), amount), "ProtocolWallet::topUp - insufficient allowance");
    }

    /// Withdraws from pool to the client address, limited by the pool's MaxRate.
    /// @dev may only be called by the wallet client
    /// @dev no more than MaxRate x time period since the last withdraw may be withdrawn
    /// @dev allocation that wasn't withdrawn can not be withdrawn in the next call
    /// @param amount is the amount to withdraw
    function withdraw(uint256 amount) external override onlyClient {
        uint256 _lastWithdrawal = lastWithdrawal;
        require(_lastWithdrawal <= block.timestamp, "withdrawal is not yet active");

        uint duration = block.timestamp.sub(_lastWithdrawal);
        require(amount.mul(365 * 24 * 60 * 60) <= maxAnnualRate.mul(duration), "ProtocolWallet::withdraw - requested amount is larger than allowed by rate");

        lastWithdrawal = block.timestamp;
        if (amount > 0) {
            require(token.transfer(msg.sender, amount), "ProtocolWallet::withdraw - transfer failed");
        }
    }

    /*
    * Governance functions
    */

    /// Sets a new annual withdraw rate for the pool
    /// @dev governance function called only by the migration owner
    /// @dev the rate for a duration is duration x annualRate / 1 year
    /// @param _annualRate is the maximum annual rate that can be withdrawn
    function setMaxAnnualRate(uint256 _annualRate) public override onlyMigrationOwner {
        maxAnnualRate = _annualRate;
        emit MaxAnnualRateSet(_annualRate);
    }

    /// Returns the annual withdraw rate of the pool
    /// @return annualRate is the maximum annual rate that can be withdrawn
    function getMaxAnnualRate() external override view returns (uint256) {
        return maxAnnualRate;
    }

    /// Resets the outstanding tokens to new start time
    /// @dev governance function called only by the migration owner
    /// @dev the next duration will be calculated starting from the given time
    /// @param startTime is the time to set as the last withdrawal time
    function resetOutstandingTokens(uint256 startTime) external override onlyMigrationOwner {
        lastWithdrawal = startTime;
        emit OutstandingTokensReset(startTime);
    }

    /// Emergency withdraw the wallet funds
    /// @dev governance function called only by the migration owner
    /// @dev used in emergencies, when a migration to a new wallet is needed
    /// @param erc20 is the erc20 address of the token to withdraw
    function emergencyWithdraw(address erc20) external override onlyMigrationOwner {
        IERC20 _token = IERC20(erc20);
        emit EmergencyWithdrawal(msg.sender, address(_token));
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "FeesWallet::emergencyWithdraw - transfer failed");
    }

    /// Sets the address of the client that can withdraw funds
    /// @dev governance function called only by the functional owner
    /// @param _client is the address of the new client
    function setClient(address _client) external override onlyFunctionalOwner {
        client = _client;
        emit ClientSet(_client);
    }
}