// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    // function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
}

contract FNBSale is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public privateSaleStartTimestamp;
    uint256 public privateSaleEndTimestamp;
    uint256 public totalDepositedBNBBalance;
    uint256 public minimumDepositBNBAmount = uint256(0.1 ether);
    uint256 public maximumDepositBNBAmount = uint256(10 ether);
    uint256 public price = 83333;

    constructor(address mainContractAddress) {
        token = IERC20(mainContractAddress);
    }

    function buy() public payable {
        uint256 take = msg.value;
        require(privateSaleStartTimestamp > 0 && block.timestamp >= privateSaleStartTimestamp && block.timestamp <= privateSaleEndTimestamp, "presale is not active");
        require(take>= minimumDepositBNBAmount && take <= maximumDepositBNBAmount , "Wrong buy value");

        uint256 decimalsDiff = uint256(18).sub(token.decimals());
        uint256 tokenAmount = take.mul(price).div(10 ** decimalsDiff);
        uint256 contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance >= tokenAmount, "Insufficient contract balance");
        token.transfer(msg.sender, tokenAmount);

        totalDepositedBNBBalance = totalDepositedBNBBalance.add(take);
        emit Bought(msg.sender, take);

    }

    function releaseFunds() external onlyOwner {
        require(block.timestamp >= privateSaleEndTimestamp, "Too soon");
        payable(msg.sender).transfer(address(this).balance);
        uint256 balanceOfThis = token.balanceOf(address(this));
        if (balanceOfThis > 0) {
            token.transfer(msg.sender, balanceOfThis);
        }
    }

    function recoverIERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedBNBBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > privateSaleEndTimestamp) {
            return 0;
        } else {
            return (privateSaleEndTimestamp - block.timestamp);
        }
    }

    function setMinDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue < maximumDepositBNBAmount, "Min value should be less than max value");
        emit UpdateMinDepositAmount(minimumDepositBNBAmount, newValue);
        minimumDepositBNBAmount = newValue;
    }

    function setMaxDepositAmount(uint256 newValue) external onlyOwner {
        require(newValue > minimumDepositBNBAmount, "Max value should be greater than min value");
        emit UpdateMinDepositAmount(maximumDepositBNBAmount, newValue);
        maximumDepositBNBAmount = newValue;
    }

    function setPrice(uint256 newValue) external onlyOwner {
        require(block.timestamp < privateSaleStartTimestamp || privateSaleStartTimestamp == 0, "Private sale already started");
        emit UpdatePrice(price, newValue);
        price = newValue;
    }

    function setPrivateSaleTime(uint256 start, uint256 end) external onlyOwner {
        // require(privateSaleEndTimestamp == 0 && privateSaleStartTimestamp == 0, "Sale times cannot be changed after setting once");
        privateSaleStartTimestamp = start < block.timestamp ? block.timestamp : start;
        require(end > block.timestamp, "Sale End time should be grater than current time.");
        privateSaleEndTimestamp = end;
    }


    event UpdateMinDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdateMaxDepositAmount(uint256 oldValue, uint256 newValue);
    event UpdatePrice(uint256 oldValue, uint256 newValue);
    event Bought(address indexed user, uint256 amount);
    event SendBack(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}