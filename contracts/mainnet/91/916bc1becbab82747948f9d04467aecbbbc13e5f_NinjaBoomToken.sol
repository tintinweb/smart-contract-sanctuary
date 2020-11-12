// SPDX-License-Identifier: MIT

    /**
     * NIB Network
     * https://NIB.network
     *
     * Additional details for contract and wallet information:
     * https://NIB.network/tracking/
     * 𝖓𝖎𝖓𝖏𝖆𝖇𝖔𝖔𝖒 𝖎𝖘 𝖑𝖎𝖛𝖊
     *
     */
     

pragma solidity ^0.7.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract NinjaBoomToken {

    //Enable SafeMath
    using SafeMath for uint256;

    //Token details
    string constant public name = "NinjaBoom Token";
    string constant public symbol = "NIB";
    uint8 constant public decimals = 18;

    //Reward pool and owner address
    address public owner;
    address public rewardPoolAddress;

    //Supply and tranasction fee
    uint256 public maxTokenSupply = 10000e18;   // 10,000 tokens
    uint256 public feePercent = 0;          // initial transaction fee percentage
    uint256 public feePercentMax = 100;      // maximum transaction fee percentage

    //Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner,address indexed _spender, uint256 _tokens);
    event TranserFee(uint256 _tokens);
    event UpdateFee(uint256 _fee);
    event RewardPoolUpdated(address indexed _rewardPoolAddress, address indexed _newRewardPoolAddress);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner, address indexed _newOwner);

    //Mappings
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowances;

    //On deployment
    constructor () {
        owner = msg.sender;
        rewardPoolAddress = address(this);
        balanceOf[msg.sender] = maxTokenSupply;
        emit Transfer(address(0), msg.sender, maxTokenSupply);
    }

    //ERC20 totalSupply
    function totalSupply() public view returns (uint256) {
        return maxTokenSupply;
    }

    //ERC20 transfer
    function transfer(address _to, uint256 _tokens) public returns (bool) {
        transferWithFee(msg.sender, _to, _tokens);
        return true;
    }

    //ERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool) {
        require(_tokens <= balanceOf[_from], "Not enough tokens in the approved address balance");
        require(_tokens <= allowances[_from][msg.sender], "token amount is larger than the current allowance");
        transferWithFee(_from, _to, _tokens);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_tokens);
        return true;
    }

    //ERC20 approve
    function approve(address _spender, uint256 _tokens) public returns (bool) {
        allowances[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    //ERC20 allowance
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    //Transfer with transaction fee applied
    function transferWithFee(address _from, address _to, uint256 _tokens) internal returns (bool) {
        require(balanceOf[_from] >= _tokens, "Not enough tokens in the senders balance");
        uint256 _feeAmount = (_tokens.mul(feePercent)).div(100);
        balanceOf[_from] = balanceOf[_from].sub(_tokens);
        balanceOf[_to] = balanceOf[_to].add(_tokens.sub(_feeAmount));
        balanceOf[rewardPoolAddress] = balanceOf[rewardPoolAddress].add(_feeAmount);
        emit Transfer(_from, _to, _tokens.sub(_feeAmount));
        emit Transfer(_from, rewardPoolAddress, _feeAmount);
        emit TranserFee(_tokens);
        return true;
    }

    //Update transaction fee percentage
    function updateFee(uint256 _updateFee) public onlyOwner {
        require(_updateFee <= feePercentMax, "Transaction fee cannot be greater than 10%");
        feePercent = _updateFee;
        emit UpdateFee(_updateFee);
    }

    //Update the reward pool address
    function updateRewardPool(address _newRewardPoolAddress) public onlyOwner {
        require(_newRewardPoolAddress != address(0), "New reward pool address cannot be a zero address");
        rewardPoolAddress = _newRewardPoolAddress;
        emit RewardPoolUpdated(rewardPoolAddress, _newRewardPoolAddress);
    }

    //Transfer current token balance to the reward pool address
    function rewardPoolBalanceTransfer() public onlyOwner returns (bool) {
        uint256 _currentBalance = balanceOf[address(this)];
        transferWithFee(address(this), rewardPoolAddress, _currentBalance);
        return true;
    }

    //Transfer ownership to new owner
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //Remove owner from the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner, address(0));
        owner = address(0);
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only current owner can call this function");
        _;
    }
}