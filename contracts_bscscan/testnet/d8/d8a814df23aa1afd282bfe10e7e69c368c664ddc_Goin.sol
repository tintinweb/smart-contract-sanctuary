/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.5.15;


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

contract Goin is Ownable {
    using SafeMath for uint;
    address constant public TRX = 0x0000000000000000000000000000000000000000;
    //  shasta testnet: TBjfUV7TwbMyKcXM2ygW15xtaDW3d11w4Z
    address constant public ILT_TOKEN = 0x136086Cb75bef204377142A4D497d4d4dF75Aa76;
    //  nile testnet: TW5SXzj7xxF9st8YcfaYTy5YdqMHn9KKZd
    //    address constant public ILT_TOKEN = 0xdc904EfdaB9E192441D84DCD6d879336f2F496F3;

    uint constant MIN_NUMBER = 1;
    uint constant MAX_NUMBER = 15;

    uint constant BET_MODULO = 2;
    // There is minimum and maximum bets.
    uint constant TRX_MIN_BET = 1 ;//trx;
    uint constant TRX_MAX_AMOUNT = 100000 ;//trx;
    uint constant ILT_MIN_BET = 10 ** 7;// ilt
    uint constant ILT_MAX_AMOUNT = 300000 * 10 ** 6;// ilt

    //    address payable public owner;

    // Initializing the state variable
    uint256 h = uint256(keccak256(abi.encodePacked(uint(10))));

    uint public INSTANT_MULTIPLIER = 194;
    // number of series => multiplier
    mapping(uint256 => uint256) public multipliers;
    uint constant MULTIPLIER_MODULO = 100;

    // Map the bet placed in each turn.
    mapping(string => bytes32) public betByTurnId;
    // error code
    enum Errors {
        MAX_UINT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        ALREADY_CLAIMED,
        INVALID_WINNING_CHANCE,
        INVALID_MULTIPLIER,
        INVALID_SERIES_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL
    }

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address token, address indexed beneficiary, uint amount);
    event Payment(address token, address indexed beneficiary, uint amount);
    event Withdraw(address token, address indexed _user, uint _value);
    event LineReached(uint256 line, uint numberOfSeries, bytes32 _data);

    enum Direction {
        HEAD,
        TAIL
    }

    // Constructor. Deliberately does not take any parameters.
    constructor() public {
        multipliers[0] = 194;
        multipliers[1] = 376;
        multipliers[2] = 730;
        multipliers[3] = 1416;
        multipliers[4] = 2748;
        multipliers[5] = 5331;
        multipliers[6] = 10342;
        multipliers[7] = 20064;
        multipliers[8] = 38924;
        multipliers[9] = 75512;
        multipliers[10] = 146494;
        multipliers[11] = 284198;
        multipliers[12] = 551344;
        multipliers[13] = 1069607;
        multipliers[14] = 2075037;
    }

    function kill() public onlyOwner {//onlyOwner is custom modifier
        IERC20 trc20Token = IERC20(ILT_TOKEN);
        uint tokenBalance = trc20Token.balanceOf(address(this));
        trc20Token.transfer(owner(), tokenBalance);
        selfdestruct(msg.sender);
    }

    // Funds withdrawal to cover costs of inspirelab.io operation
    function withdraw(address payable beneficiary, uint256 amount) external onlyOwner returns (bool success) {
        require(address(this).balance >= amount, errorToString(Errors.NOT_ENOUGH_FUNDS));

        sendFundsTrx(beneficiary, amount);
        return true;
    }

    // Funds withdrawal to cover costs of inspirelab.io operation
    function withdrawIlt(address payable beneficiary, uint amount) external onlyOwner returns (bool success) {
        require(balanceOf(ILT_TOKEN) >= amount, errorToString(Errors.NOT_ENOUGH_FUNDS));
        //            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        IERC20(ILT_TOKEN).transfer(beneficiary, amount);
        return true;
    }

    function() external payable {}

    // Set the multiplier for Instant mode, multiplier will be divided by 100 when calculating a reward
    function setInstantMultiplier(uint multiplier) external onlyOwner {
        require(0 < multiplier && multiplier < 10000, errorToString(Errors.INVALID_MULTIPLIER));
        INSTANT_MULTIPLIER = multiplier;
    }

    // Set the multiplier for Multiply mode, multiplier will be divided by 100 when calculating a reward
    function setMultiplyMultiplier(uint8 numberOfSeries, uint multiplier) external onlyOwner {
        require(MIN_NUMBER <= numberOfSeries && numberOfSeries <= MAX_NUMBER, errorToString(Errors.INVALID_SERIES_NUMBER));
        require(0 < multiplier, errorToString(Errors.INVALID_MULTIPLIER));
        multipliers[numberOfSeries] = multiplier;
    }

    // Defining a function to generate a random number
    function random(uint seed, uint _externalRandomNumber) private view returns (uint randomness)
    {
        bytes32 _structHash;
        uint256 _randomNumber;
        uint _modulus = BET_MODULO;

        _structHash = keccak256(
            abi.encode(
                seed,
                now,
                _externalRandomNumber
            )
        );
        _randomNumber = uint256(_structHash);
        randomness = _randomNumber % _modulus;
    }

    /** @dev Allows a player to place a bet on a specific outcome (head or tail).
        @param dir Bet option chosen by the player. Allowed values are 0 (Heads) and 1 (Tails).
    */
    function betInstantTrx(Direction dir) external payable returns (uint result, bool isWin, uint payout) {
        address payable gambler = msg.sender;

        // Validate input data ranges.
        uint amount = msg.value;
        require(amount >= TRX_MIN_BET && amount <= TRX_MAX_AMOUNT, errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));
        // Check whether we can pay in case the player wins (comment out to test).
        uint coinWinAmount = (amount.mul(INSTANT_MULTIPLIER)).div(MULTIPLIER_MODULO);
        require(balanceOf(TRX) >= coinWinAmount, errorToString(Errors.PAYOUT_NOT_ENOUGH));
        bytes32 _blockhash = blockhash(block.number - 1);

        uint256 actualSeed = uint256(keccak256(abi.encodePacked(h, _blockhash)));
        uint number = now;
        result = random(actualSeed, number);
        h = actualSeed;

        isWin = false;
        payout = 0;
        // you win
        if ((dir == Direction.HEAD && result == 0) || (dir == Direction.TAIL && result == 1)) {
            isWin = true;
            payout = coinWinAmount;
        }

        // Send the funds to gambler.
        sendFundsTrx(gambler, payout == 0 ? 0 : payout);
    }

    // Helper routine to process the payment.
    function sendFundsTrx(address payable beneficiary, uint amount) private {
        if (amount > 0) {
            if (beneficiary.send(amount)) {
//                emit Payment(TRX, beneficiary, amount);
            } else {
                emit FailedPayment(TRX, beneficiary, amount);
            }
        }
    }

    /** @dev Allows a player to place a bet on a specific outcome (head or tail).
        @param dir Bet option chosen by the player. Allowed values are 0 (Heads) and 1 (Tails).
    */
    function betInstantIlt(Direction dir, uint amount) external returns (uint randomness, bool isWinner, uint prize)
    {
        IERC20 erc20Interface = IERC20(ILT_TOKEN);

        address gambler = msg.sender;
        // Validate input data ranges.
        uint tokenBalance = erc20Interface.balanceOf(gambler);
        require(amount <= 10 ** 15 && tokenBalance <= 10 ** 15, errorToString(Errors.VALUE_OVER_FLOW));
        require(tokenBalance.sub(amount) >= 0, errorToString(Errors.YOUR_AMOUNT_OVER_YOUR_BALANCE));
        require(amount >= ILT_MIN_BET && amount <= ILT_MAX_AMOUNT, errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));
        // Check whether we can pay in case the player wins.
        uint coinWinAmount = (amount.mul(INSTANT_MULTIPLIER)).div(MULTIPLIER_MODULO);
        require(balanceOf(ILT_TOKEN) >= coinWinAmount, errorToString(Errors.PAYOUT_NOT_ENOUGH));
        bytes32 _blockhash = blockhash(block.number - 1);

        uint256 actualSeed = uint256(keccak256(abi.encodePacked(h, _blockhash)));
        uint number = now;
        randomness = random(actualSeed, number);
        h = actualSeed;

        isWinner = false;
        prize = 0;
        // you win
        if ((dir == Direction.HEAD && randomness == 0) || (dir == Direction.TAIL && randomness == 1)) {
            isWinner = true;
            prize = coinWinAmount;
        } else {
            //you lose
            uint beforeTransfer = erc20Interface.balanceOf(address(this));
            erc20Interface.transferFrom(msg.sender, address(this), amount);
            require(balanceOf(ILT_TOKEN).sub(beforeTransfer) == amount, errorToString(Errors.NOT_EQUAL));
        }
        // Send the funds to gambler.
        sendFundsIlt(gambler, prize == 0 ? 0 : prize);
    }

    // Helper routine to process the payment.
    function sendFundsIlt(address beneficiary, uint amount) private {
        // Send and notify
        if (amount > 0) {
            if (IERC20(ILT_TOKEN).transfer(beneficiary, amount)) {
                //                emit Payment(ILT_TOKEN, beneficiary, amount);
            } else {
                emit FailedPayment(ILT_TOKEN, beneficiary, amount);
            }
        }
    }

    /** @dev Allows a player to place a bet on a specific outcome (head or tail).
        @param turnId Bet turn id provided by the server as a UUID.
    */
    function betMultiplyTrx(string calldata turnId) external payable {
        // Validate input data ranges.
        uint amount = msg.value;
        // Player's bet value must meet minimum bet requirement.
        require(amount >= TRX_MIN_BET && amount <= TRX_MAX_AMOUNT, errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));

        // 1. Creates a new Bet and assigns it to the list of bets.
        // 3. Raises an event for the bet placed by the player.
        require(betByTurnId[turnId] == 0x0, errorToString(Errors.INVALID_DATA));
        bytes32 _amount = bytes32(amount);
        _amount = _amount << 1;
        betByTurnId[turnId] = _amount;
        //        emit NewBetPlaced(sessionIndex, msg.sender, msg.value, BetOption(option));
    }

    //convert bytes to bytes32
    function convertToBytes32(bytes memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function rewardWinner(address winner, string calldata turnId,
        bytes calldata result, bytes calldata userStep) external
    {
        require(betByTurnId[turnId] != 0x0, errorToString(Errors.INVALID_DATA));
        require(userStep.length <= 15, errorToString(Errors.INVALID_DATA));
        // Require not claimed
        require(!hasClaimed(turnId), errorToString(Errors.ALREADY_CLAIMED));

        // Validate signed signature
        //        require(secretSigner == recoverAddr(dataHash, v, r, s), errorToString(Errors.ECDSA_SIGNATURE_INVALID));

        bytes32 _result = convertToBytes32(result);
        bytes32 _userStep = convertToBytes32(userStep);
        uint _N = userStep.length;
        bytes32 _firstNBits = getFirstNBits(_result, _N * 8);
        if (_firstNBits == _userStep) {
            _payout(winner, _N, turnId);
        }
        emit LineReached(276, _N, _firstNBits);
    }

    /*
     * Helper: returns whether this player has claimed.
     */
    function hasClaimed(string memory turnId) internal view returns (bool)
    {
        return getLastNBits(betByTurnId[turnId], 1) != 0x0 ? true : false;
    }

    function _payout(address winner, uint numberOfSeries, string memory turnId) private {
        if (numberOfSeries > 0) {
            // Payout. (break the complex calculation to prevent "Stack too deep, try removing local variables."
            bytes32 curBet = betByTurnId[turnId];
            curBet = curBet >> 1;
            uint256 amount = uint(curBet);
            uint256 winAmount = amount.mul(multipliers[numberOfSeries - 1]).div(MULTIPLIER_MODULO);
            betByTurnId[turnId] = bytes32(uint(curBet).mul(2).add(1));
            emit Payment(TRX, winner, winAmount);
            //            sendFundsTrx(winner, winAmount);
        }
    }

    function getFirstNBits(
        bytes32 _x,
        uint _n
    ) public pure returns (bytes32) {
        require(_n <= 120, errorToString(Errors.VALUE_OVER_FLOW));
        bytes32 nOnes = bytes32(2 ** _n - 1);
        bytes32 mask = nOnes << (256 - _n);
        // Total 256 bits
        return _x & mask;
    }

    function getLastNBits(
        bytes32 _A,
        uint _N
    ) public pure returns (bytes32) {
        require(_N < 21, errorToString(Errors.VALUE_OVER_FLOW));
        uint lastN = uint(_A) % (2 ** _N);
        return bytes32(lastN);
    }

    /**
     * @dev convert enum to string value
        MAX_UINT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        ALREADY_CLAIMED,
        INVALID_MULTIPLIER,
        INVALID_SERIES_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL
     */
    function errorToString(Errors error) internal pure returns (string memory) {
        // Error handling for input
        require(uint8(error) <= 12);

        // Loop through possible options
        if (Errors.MAX_UINT_REACHED == error) return "MAX_UINT_REACHED";
        if (Errors.VALUE_OVER_FLOW == error) return "VALUE_OVER_FLOW";
        if (Errors.YOUR_AMOUNT_OVER_YOUR_BALANCE == error) return "YOUR_AMOUNT_OVER_YOUR_BALANCE";
        if (Errors.INTERNAL_TX_ERROR == error) return "INTERNAL_TX_ERROR";
        if (Errors.ALREADY_CLAIMED == error) return "ALREADY_CLAIMED";
        if (Errors.INVALID_MULTIPLIER == error) return "INVALID_MULTIPLIER";
        if (Errors.INVALID_SERIES_NUMBER == error) return "INVALID_SERIES_NUMBER";
        if (Errors.INVALID_DATA == error) return "INVALID_DATA";
        if (Errors.PAYOUT_NOT_ENOUGH == error) return "PAYOUT_NOT_ENOUGH";
        if (Errors.NOT_ENOUGH_FUNDS == error) return "NOT_ENOUGH_FUNDS";
        if (Errors.PLACE_BET_TOKEN_NOT_IN_RANGE == error) return "PLACE_BET_TOKEN_NOT_IN_RANGE";
        if (Errors.NOT_EQUAL == error) return "NOT_EQUAL";
    }

    /**
     * @dev Get the amount of coin deposited to this smart contract
     */
    function balanceOf(address token) internal view returns (uint) {
        if (token == TRX) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }
}