/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _governance;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event GovernanceshipTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _governance = msgSender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        emit GovernanceshipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(
            _governance == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyGovernance` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyGovernance {
        emit OwnershipTransferred(_governance, address(0));
        _governance = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newGovernance)
        public
        virtual
        onlyGovernance
    {
        require(
            newGovernance != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}

contract Dice is Context, Ownable {
    using SafeMath for uint256;

    uint256 private _gameFeePercent;
    uint256 private _winnerPercent;
    uint256 private _depositFeePercent;
    uint256 private _withdrawFeePercent;
    uint256 private _totalAmount;
    uint256 private _adminAmount;
    address private _adminAccount;

    mapping(address => uint256) private _userBalanceList;

    // Events
    event ChangeAdminAccount(
        address indexed governance,
        address newAdminAccount
    );
    event ChangeGameFeePercent(
        address indexed governance,
        uint256 gameFeePercent
    );
    event ChangeWinnerPercent(
        address indexed governance,
        uint256 winnerPercent
    );
    event ChangeDepositFeePercent(
        address indexed governance,
        uint256 depositFeePercent
    );
    event ChangeWithdrawFeePercent(
        address indexed governance,
        uint256 withdrawFeePercent
    );
    event UpdateUserBalance(address indexed userAddress, uint256 amount);
    event UpdateDepositBalancce(address indexed userAddress, uint256 amount);
    event UpdateWithdrawBalancce(address indexed userAddress, uint256 amount);
    event UpdateWinnerBalance(address indexed winnerAddress, uint256 amount);
    event UpdateAdminBalance(address indexed adminAddress, uint256 amount);
    event Deposit(address indexed fromAccount, uint256 amount);
    event UserWithdraw(address indexed userAddress, uint256 amount);
    event AdminWithdraw(address indexed adminAddress, uint256 amount);
    event EmergencyWithdraw(address indexed governance, uint256 amount);
    event DiceGameEvent(
        string gameInfo,
        string winnerName,
        address indexed winnerAddress,
        uint256 winnerScore,
        uint256 winnerAmount
    );

    constructor(address adminAccount) {
        _totalAmount = 0;
        _adminAmount = 0;
        _winnerPercent = 9300;
        _gameFeePercent = 700;
        _depositFeePercent = 300;
        _withdrawFeePercent = 300;

        _adminAccount = adminAccount;
    }

    /**
     * @dev Get Balance of User
     */
    function balanceOfPlayer(address userAddress)
        external
        view
        returns (uint256)
    {
        return _userBalanceList[userAddress];
    }

    /**
     * @dev Get Total ETH Amount
     */
    function getTotalAmount() external view returns (uint256) {
        return _totalAmount;
    }

    /**
     * @dev Get Fee Account
     */
    function getAdminAccount() external view returns (address) {
        return _adminAccount;
    }

    /**
     * @dev Change Admin Account
     */
    function changeAdminAccount(address newAdminAccount)
        external
        onlyGovernance
    {
        _adminAccount = newAdminAccount;

        emit ChangeAdminAccount(governance(), newAdminAccount);
    }

    /**
     * @dev Get Game Fee Percent
     */
    function getGameFeePercent() external view returns (uint256) {
        return _gameFeePercent;
    }

    /**
     * @dev Change Game Fee Percent
     */
    function changeGameFeePercent(uint256 gameFeePercent)
        external
        onlyGovernance
    {
        // Update Game Fee Percent
        _gameFeePercent = gameFeePercent;

        // Update Winner Fee Percent
        _winnerPercent = (uint256)(10000).sub(_gameFeePercent);

        emit ChangeGameFeePercent(governance(), gameFeePercent);
        emit ChangeWinnerPercent(governance(), _winnerPercent);
    }

    /**
     * @dev Get Deposit Fee Percent
     */
    function getDepositFeePercent() external view returns (uint256) {
        return _depositFeePercent;
    }

    /**
     * @dev Change Deposit Fee Percent
     */
    function changeDepositFeePercent(uint256 depositFeePercent)
        external
        onlyGovernance
    {
        // Update Deposit Fee Percent
        _depositFeePercent = depositFeePercent;

        emit ChangeDepositFeePercent(governance(), depositFeePercent);
    }

    /**
     * @dev Get Withdraw Fee Percent
     */
    function getWithdrawFeePercent() external view returns (uint256) {
        return _depositFeePercent;
    }

    /**
     * @dev Change Withdraw Fee Percent
     */
    function changeWithdrawFeePercent(uint256 withdrawFeePercent)
        external
        onlyGovernance
    {
        // Update Withdraw Fee Percent
        _withdrawFeePercent = withdrawFeePercent;

        emit ChangeWithdrawFeePercent(governance(), withdrawFeePercent);
    }

    /**
     * @dev Get Admin Amount
     */
    function getAdminAmount() external view returns (uint256) {
        return _adminAmount;
    }

    /**
     * @dev receive event
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev Receive ETH from player and update his balance on DiceContract
     */
    function deposit() public payable {
        address userAddress = _msgSender();
        uint256 depositAmouont = msg.value;

        // Calculate Deposit Fee
        uint256 depositFeeAmount =
            depositAmouont.mul(_depositFeePercent).div(10000);
        uint256 updatedDepositAmount = depositAmouont.sub(depositFeeAmount);

        // Update Player's Balance
        _userBalanceList[userAddress] = _userBalanceList[userAddress].add(
            updatedDepositAmount
        );

        // Update Admin Balance
        _adminAmount = _adminAmount.add(depositFeeAmount);

        // Update Total ETH Balance
        _totalAmount = _totalAmount.add(depositAmouont);

        emit Deposit(userAddress, depositAmouont);
        emit UpdateDepositBalancce(userAddress, updatedDepositAmount);
        emit UpdateAdminBalance(_adminAccount, depositFeeAmount);
    }

    /**
     * @dev Withdraw Admin Balance to admin account, only Governance call it
     */
    function adminWithdraw() public payable onlyGovernance {
        uint256 withdrawAmount = _adminAmount;
        bytes memory callData;

        // Send ETH From Contract to Admin Address
        (bool sent, bytes memory data) =
            _adminAccount.call{value: withdrawAmount}("");
        callData = data;
        require(sent, "Failed to Withdraw Admin.");

        // Update Admin Balance
        _adminAmount = 0;
        // Update Total Balance
        _totalAmount = _totalAmount.sub(withdrawAmount);

        emit AdminWithdraw(_adminAccount, withdrawAmount);
    }

    /**
     * @dev Withdraw User Balance to user account, only Governance call it
     */
    function userWithdraw(address userAddress, uint256 amount)
        public
        payable
        onlyGovernance
    {
        require(
            _userBalanceList[userAddress] >= amount,
            "User Balance should be more than withdraw amount."
        );

        // Calculate Withdraw Fee
        uint256 withdrawFeeAmount = amount.mul(_withdrawFeePercent).div(10000);
        uint256 withdrawAmount = amount.sub(withdrawFeeAmount);
        bytes memory callData;

        // Send ETH From Contract to User Address
        (bool sent, bytes memory data) =
            userAddress.call{value: withdrawAmount}("");
        callData = data;
        require(sent, "Failed to Withdraw User.");

        // Update User Balance
        _userBalanceList[userAddress] = _userBalanceList[userAddress].sub(
            amount
        );
        // Update Admin Balance
        _adminAmount = _adminAmount.add(withdrawFeeAmount);
        // Update Total Balance
        _totalAmount = _totalAmount.sub(withdrawAmount);

        emit UserWithdraw(userAddress, amount);
        emit UpdateWithdrawBalancce(userAddress, withdrawAmount);
        emit UpdateAdminBalance(_adminAccount, withdrawFeeAmount);
    }

    /**
     * @dev EmergencyWithdraw when need to update contract and then will restore it
     */
    function emergencyWithdraw() public payable onlyGovernance {
        require(_totalAmount > 0, "Can't send over total ETH amount.");

        uint256 amount = _totalAmount;
        address governanceAddress = governance();
        bytes memory callData;

        // Send ETH From Contract to Governance Address
        (bool sent, bytes memory data) =
            governanceAddress.call{value: amount}("");
        callData = data;
        require(sent, "Failed to Withdraw Governance");

        // Update Admin&Total Balance
        _totalAmount = 0;
        _adminAmount = 0;

        emit EmergencyWithdraw(governanceAddress, amount);
    }

    /**
     * @dev Update User Balance after playing dice game, only governance call it
     */
    function updateUserBalance(address userAddress, uint256 gameAmount)
        public
        onlyGovernance
        returns (bool)
    {
        require(
            _userBalanceList[userAddress] >= gameAmount,
            "User Balance should be more than game amount."
        );

        // Update User Balance
        _userBalanceList[userAddress] = _userBalanceList[userAddress].sub(
            gameAmount
        );

        emit UpdateUserBalance(userAddress, gameAmount);
        return true;
    }

    /**
     * @dev Update Winner Balance who is win on dice game
     */
    function updateWinnerBalance(address winnerAddress, uint256 winnerAmount)
        public
        onlyGovernance
        returns (uint256)
    {
        require(
            _totalAmount >= winnerAmount,
            "Total balance should be more than winner amount."
        );

        // Calculate Game Fee
        uint256 gameFeeAmount = winnerAmount.mul(_gameFeePercent).div(10000);
        uint256 updatedWinnerAmount = winnerAmount.sub(gameFeeAmount);

        // Update User&Admin Balance
        _userBalanceList[winnerAddress] = _userBalanceList[winnerAddress].add(
            updatedWinnerAmount
        );
        _adminAmount = _adminAmount.add(gameFeeAmount);

        emit UpdateWinnerBalance(winnerAddress, winnerAmount);
        emit UpdateUserBalance(winnerAddress, updatedWinnerAmount);
        emit UpdateAdminBalance(_adminAccount, gameFeeAmount);
        return updatedWinnerAmount;
    }

    /**
     * @dev Play Tournament Dice Game, only Owner can call this function
     */
    function playDiceGame(
        string memory gameInfo,
        address[] memory playerList,
        string memory winnerTelegramName,
        uint256 winnerScore,
        uint256 totalAmount,
        uint256 playAmount,
        uint256 gameLength
    ) public payable onlyGovernance returns (bool) {
        // Check Game Players Balance
        for (uint256 i = 0; i < gameLength; i++) {
            require(
                _userBalanceList[playerList[i]] >= playAmount,
                "The balance of all players should be  more than playAmount."
            );
        }

        // Update the balance of players
        for (uint256 i = 0; i < gameLength; i++) {
            updateUserBalance(playerList[i], playAmount);
        }

        // Update Winner Balance
        uint256 winnerAmount = updateWinnerBalance(playerList[0], totalAmount);

        // Dice Game Event
        emit DiceGameEvent(
            gameInfo,
            winnerTelegramName,
            playerList[0],
            winnerScore,
            winnerAmount
        );

        return true;
    }
}