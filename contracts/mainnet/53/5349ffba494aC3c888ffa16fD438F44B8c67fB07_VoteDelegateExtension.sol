/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// File: contracts\interfaces\IBooster.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBooster {
    function owner() external view returns(address);
    function setVoteDelegate(address _voteDelegate) external;
    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool);
    function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight ) external returns(bool);
}

// File: @openzeppelin\contracts\math\SafeMath.sol

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

// File: contracts\VoteDelegateExtension.sol
pragma solidity 0.6.12;


/*
Add a layer to voting to easily apply data packing into vote id, as well as simplify calling functions
*/
contract VoteDelegateExtension{
    using SafeMath for uint256;

    address public constant voteOwnership = address(0xE478de485ad2fe566d49342Cbd03E49ed7DB3356);
    address public constant voteParameter = address(0xBCfF8B0b9419b9A88c44546519b1e909cF330399);
    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    uint256 private constant MAX_UINT_128  = (2**128) - 1;
    uint256 private constant MAX_UINT_64  = (2**64) - 1;
    uint256 private constant MAX_VOTE = 1e18;

    address public owner;
    address public daoOperator;
    address public gaugeOperator;

    constructor() public {
        //default to multisig
        owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
        daoOperator = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
        gaugeOperator = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyDaoOperator() {
        require(daoOperator == msg.sender, "!dop");
        _;
    }

    modifier onlyGaugeOperator() {
        require(gaugeOperator == msg.sender, "!gop");
        _;
    }

    //set owner - only OWNER
    function setOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    //set dao vote operator - only OWNER
    function setDaoOperator(address _operator) external onlyOwner{
        daoOperator = _operator;
    }

    //set gauge vote operator - only OWNER
    function setGaugeOperator(address _operator) external onlyOwner{
        gaugeOperator = _operator;
    }

    //revert to booster's owner
    function revertControl() external onlyOwner{
        IBooster(booster).setVoteDelegate(IBooster(booster).owner());
    }

    //pack data by shifting and ORing
    function _encodeData(uint256 _value, uint256 _shiftValue, uint256 _base) internal pure returns(uint256) {
        return uint256((_value << _shiftValue) | _base);
    }

    function packData(uint256 _voteId, uint256 _yay, uint256 _nay) public pure returns(uint256){
        uint256 pack = _encodeData(_yay, 192, 0);
        pack = _encodeData(_nay,128,pack);
        pack = _encodeData(_voteId, 0, pack);
        return pack;
    }

    //Submit a DAO vote (with weights)
    function DaoVoteWithWeights(uint256 _voteId, uint256 _yay, uint256 _nay, bool _isOwnership) external onlyDaoOperator returns(bool){
        //convert 10,000 to 1e18
        _yay = _yay.mul(1e18).div(10000);
        _nay = _nay.mul(1e18).div(10000);
        require(_yay.add(_nay) == MAX_VOTE, "!equal max_vote");

        uint256 data = packData(_voteId, _yay, _nay);

        //vote with enocded vote id.  "supported" needs to be false if doing this type
        return IBooster(booster).vote(data, _isOwnership ? voteOwnership : voteParameter, false);
    }

    //Submit a DAO vote
    function DaoVote(uint256 _voteId, bool _support, bool _isOwnership) external onlyDaoOperator returns(bool){
        //vote with full voting power on either choice
        return IBooster(booster).vote(_voteId, _isOwnership ? voteOwnership : voteParameter, _support);
    }

    //Submit Gauge Weights
    function GaugeVote(address[] calldata _gauge, uint256[] calldata _weight) external onlyGaugeOperator returns(bool){
        //vote for gauge weights
        return IBooster(booster).voteGaugeWeight(_gauge, _weight);
    }
}