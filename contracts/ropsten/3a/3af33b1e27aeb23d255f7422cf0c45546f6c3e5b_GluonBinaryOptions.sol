/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/GluonBinaryOptions.sol

pragma solidity ^0.7.6;


contract GluonBinaryOptions {

    using SafeMath for uint256;

    address payable public owner;

    enum Result {Unresolved, Yes, No, Undecided} //generic. some betting events may be undecided "Tie"
    struct Option {
        string optionCode; //e.g. BTC-45000 : BTC will be more than 45000 USD before expiry, ETH-3500
        bytes32 identifier;
        string description;
        uint expiryBlock;
        bool resolved;
        Result result;
        uint totalPot;
    }

    struct Bet {
        uint amount;
        Result predictedResult;
        bool paidOut;
    }
    uint public commission = 0; //divided by 1000, so 1 is 0.1 %
    uint public optionsCount;
    mapping(bytes32 => mapping(uint8 => uint)) public betsByOutcome; // identifier => { result => balance}
    mapping(uint => Option) public optionsArray;
    mapping(bytes32 => Option) public Options;
    mapping(address => mapping(bytes32 => Bet)) public Bets;
    uint private r = 0;
    event OptionPlaced(bytes32 identifier, address indexed account, uint value, uint Result, uint totalForResult);
    event OptionPaid(bytes32 identifier, address indexed winner, uint value, uint totalPot, uint ratio, uint commissionAmount);
    event OptionResult(bytes32 identifier, uint result, uint totalBalance, uint winnerRatio);

    constructor (address payable owner_) {
        owner = owner_;
    }
    function setCommission(uint _commision) public{
        commission = _commision;
    }
    function getResultBalance(bytes32 identifier, Result result) isValidResult(result) public view returns (uint balance) {
        return betsByOutcome[identifier][uint8(result)];
    }

    function getTotalPot(bytes32 identifier) public view returns (uint totalPot) {
        return Options[identifier].totalPot;
    }

    function addBinaryOption(string calldata optionCode, string calldata description, uint durationInBlocks) public returns (bool success){
        bytes32 id = keccak256(abi.encodePacked(optionCode, description, durationInBlocks));
        return addBinaryOption(id, optionCode, description, durationInBlocks);
    }

    function addBinaryOption(bytes32 identifier, string calldata optionCode, string calldata description, uint durationInBlocks) isOwner() private returns (bool success) {

        require(durationInBlocks > 0);
        require(Options[identifier].expiryBlock == 0);
        Options[identifier] = Option(optionCode, identifier, description, block.number + durationInBlocks, false, Result.Unresolved, 0);
        optionsArray[optionsCount] = Options[identifier];
        optionsCount ++;
        return true;
    }

    function placeBet(bytes32 identifier, Result result) public isValidResult(result) payable returns (bool success) {

        require(msg.value > 0);

        Option storage option = Options[identifier];
        require(option.expiryBlock > 0);
        require(!option.resolved);
        require(option.expiryBlock > block.number - 10);

        require(Bets[msg.sender][identifier].amount == 0);

        betsByOutcome[identifier][uint8(result)] = betsByOutcome[identifier][uint8(result)].add(msg.value);
        option.totalPot = option.totalPot.add(msg.value);

        Bet memory bet;
        bet.amount = msg.value;
        bet.predictedResult = result;
        Bets[msg.sender][identifier] = bet;
        emit OptionPlaced(option.identifier, msg.sender, bet.amount, uint(result), betsByOutcome[identifier][uint8(result)]);
        return true;
    }
    function setOptionResult(bytes32 identifier, Result result) public returns (bool success) {

        Option storage option = Options[identifier];
        require(option.expiryBlock < block.number);
        require(result == Result.Yes || result == Result.No || result == Result.Undecided);
        option.result = result;
        option.resolved = true;
        uint totalBalance = getResultBalance(identifier, Result.Yes) + getResultBalance(identifier, Result.No);
        uint ResultBalance = getResultBalance(identifier, result);
        r = 1000 * totalBalance / ResultBalance;
        emit OptionResult(option.identifier, uint(result), uint(totalBalance), uint(r));
        return true;
    }

    function receivePayment(bytes32 identifier) public returns (bool success) {

        Option storage option = Options[identifier];
        require(option.expiryBlock < block.number);
        require(option.resolved);
        require(r > 0);
        Bet storage bet = Bets[msg.sender][identifier];
        require(bet.amount > 0);
        require(option.totalPot > 0);
        require(!bet.paidOut);

        if (option.result != Result.Undecided) {
            require(bet.predictedResult == option.result); 
        }

        uint payoutAmount = r * bet.amount / 1000;

        bet.paidOut = true;
        option.totalPot -= payoutAmount;

        uint commissionAmount = payoutAmount * commission/1000;
        msg.sender.transfer(payoutAmount - commissionAmount);
        owner.transfer(commissionAmount);
        emit OptionPaid(option.identifier, msg.sender, payoutAmount, option.totalPot, r, commissionAmount);
        return true;
    }

    //    function kill() isOwner() public {
    //        selfdestruct(owner);
    //    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isValidResult(Result result) {
        require(result == Result.Yes || result == Result.No);
        _;
    }
}