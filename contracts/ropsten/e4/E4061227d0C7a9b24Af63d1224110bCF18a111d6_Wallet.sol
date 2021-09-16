/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface Erc20Interface {
    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract Wallet {
    using SafeMath for uint256;
    // The account with the highest authority to execute the contract
    address payable public owner;
    // Second only to the authority of the owner account, you can perform all operations except replacing the owner account
    mapping(address => bool) public whitelist;
    event ApproveEvent(address token, address target, uint256 amount);
    event WithdrawEthEvent(uint256 amount);
    event AddWhiteListAccountEvent(address src, address dst);
    event RemoveWhiteListAccountEvent(address src, address dst);
    bool public lock = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier authority(address account) {
        require(account == owner, "invalid account");
        _;
    }

    modifier permissions(address account) {
        require(whitelist[account] || owner == account, "invalid account");
        _;
    }
    modifier check() {
        require(!lock, "No re-entry");
        lock = true;
        _;
        lock = false;
    }

    /// @notice Set a new owner to replace the old owner. Only the owner account can exercise this right
    /// @param account New owner account
    function setOwner(address payable account) public authority(msg.sender) {
        require(account != address(0), "The account address is 0");
        owner = account;
    }

    /// @notice Authorize the token of wallet in the token contract to the target account,
    /// and the target account can transfer out the token of wallet in the token contract
    /// @param token Erc20 contract
    /// @param target Target account
    /// @param amount Number of authorized tokens
    function Approve(
        address token,
        address target,
        uint256 amount
    ) public authority(msg.sender) {
        Erc20Interface(token).approve(target, amount);
        emit ApproveEvent(token, target, amount);
    }

    function allowance(address token, address target)
        public
        view
        returns (uint256)
    {
        uint256 amount = Erc20Interface(token).allowance(address(this), target);
        return amount;
    }

    /// @notice Transfer eth in wallet to owner account
    /// @param amount Transfer out eth quantity
    function WithdrawEth(uint256 amount) public permissions(msg.sender) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "Over expenditure");
        owner.transfer(amount);
    }

    /// @notice Transfer the wallet token in the erc20 contract to the owner's account
    /// @param token Erc20 contract
    /// @param amount Number of erc20 tokens transferred out
    function WithdrawErc20Token(address token, uint256 amount)
        public
        permissions(msg.sender)
    {
        uint256 balance = BalanceOfByErc20(token);
        require(amount <= balance, "Over expenditure");
        Erc20Interface(token).transfer(owner, amount);
    }

    // @notice Add an account to the white list Committee. This operation can only be a member of the white list committee or an owner account
    // @parma account New whitelist account
    function AddWhiteListAccount(address account)
        public
        permissions(msg.sender)
    {
        require(
            !whitelist[account],
            "The account is already on the white list"
        );
        whitelist[account] = true;
        emit AddWhiteListAccountEvent(msg.sender, account);
    }

    /// @notice Remove the account in the whitelist Committee. This operation can only be a member or owner of the whitelist Committee
    /// @param account Removed account
    function RemoveWhiteListAccount(address account)
        public
        permissions(msg.sender)
    {
        require(whitelist[account], "The account is not on the white list");
        whitelist[account] = false;
        emit RemoveWhiteListAccountEvent(msg.sender, account);
    }

    /// @notice Balance of wallet account in erc20 contract
    /// @param token Erc20 contract
    function BalanceOfByErc20(address token) public view returns (uint256) {
        uint256 balance = Erc20Interface(token).balanceOf(address(this));
        return balance;
    }

    /// @notice Balance in eth in wallet account
    function BalanceOfByEth() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Contract code data of sushi Dutch auction
    /// @param beneficiary Account number to receive Ido token
    function SushiIdoDutchActionByCommitEth(address beneficiary)
        internal
        returns (bytes memory)
    {
        bytes memory encodedata = abi.encodeWithSignature(
            "commitEth(address,bool)",
            beneficiary,
            true
        );
        return encodedata;
    }

    /// @notice Contract code data of sushi Dutch auction
    /// @param amount How many tokens do I need to buy Ido tokens
    function SushiIdoDutchActionByCommitTokens(uint256 amount)
        internal
        returns (bytes memory)
    {
        bytes memory encodedata = abi.encodeWithSignature(
            "commitTokens(uint256,bool)",
            amount,
            true
        );
        return encodedata;
    }

    /// @notice Use eth to purchase Ido tokens. This operation is limited to the sushi Ido platform
    /// @param dutchaction Sushi Ido Contract
    /// @param amount How much eth does it take to buy Ido tokens
    function CallIdoByCommitEth(address dutchaction, uint256 amount)
        public
        payable
        permissions(msg.sender)
        check
    {
        uint256 balance = address(this).balance;
        uint256 totalBalance = balance.add(msg.value);
        require(totalBalance >= amount, "");
        bytes memory encodedata = SushiIdoDutchActionByCommitEth(address(this));
        dutchaction.call{value: amount}(encodedata);
    }

    /// @notice Use erc20 token to purchase Ido tokens. This operation is limited to the sushi Ido platform
    /// @param dutchaction Sushi Ido Contract
    /// @param token erc20 Contract
    /// @param amount How many erc20 tokens does it take to buy Ido tokens
    function CallIdoByToken(
        address dutchaction,
        address token,
        uint256 amount
    ) public permissions(msg.sender) check {
        uint256 balance = BalanceOfByErc20(token);
        require(balance >= amount, "");
        bytes memory encodedata = SushiIdoDutchActionByCommitTokens(amount);
        dutchaction.call(encodedata);
    }

    /// @notice Use eth to purchase Ido tokens.
    /// @param dutchaction Sushi Ido Contract
    /// @param amount How much eth does it take to buy Ido tokens
    /// @param encodedata Ido contract code data
    function CallIdoByEthMetaData(
        address dutchaction,
        uint256 amount,
        bytes memory encodedata
    ) public payable permissions(msg.sender) check {
        uint256 balance = address(this).balance;
        uint256 totalBalance = balance.add(msg.value);
        require(totalBalance >= amount, "");
        dutchaction.call{value: amount}(encodedata);
    }

    // @notice Use erc20 token  to purchase Ido tokens
    // @param dutchaction Sushi Ido Contract
    // @param token erc20 Contract
    // @param amount How many erc20 tokens does it take to buy Ido tokens
    // @parma encodedata Ido contract code data
    function CallIdoByTokenMetaData(
        address dutchaction,
        address token,
        uint256 amount,
        bytes memory encodedata
    ) public permissions(msg.sender) check {
        uint256 balance = BalanceOfByErc20(token);
        require(balance >= amount, "");
        dutchaction.call(encodedata);
    }

    /// @notice Save eth to Wallet
    function Deposit() public payable {}

    receive() external payable {}
}