/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract SMRPrivate is Context, Ownable {
    
    using SafeMath for uint256;
    address public tokenAddr;
    IERC20 public tokenContract;
    uint256 public minAmountGweiBuy;
    uint256 public maxAmountGweiBuy;
    mapping (address => bool) public isAddressWhiteListed;
    bool public isSaleEnded;
    bool public isSaleStarted;
    uint256 public preSupply;
    uint256 public tokenAmountPerBNB;
    uint256 public tokenBalanceInSale;
    
    constructor (uint256 _tokenAmountPerBNB, uint256 _minAmountGwei, uint256 _maxAmountGwei, address _tokenAddr) public {
        tokenAmountPerBNB = _tokenAmountPerBNB;
        minAmountGweiBuy = _minAmountGwei;
        maxAmountGweiBuy = _maxAmountGwei;
        tokenAddr = _tokenAddr;
        tokenContract = IERC20(tokenAddr);
    }
    
    receive() external payable {
        buyToken();
    }
    
    function buyToken() public payable {
        require(isSaleStarted, "Sale hasn't started yet!");
        require(!isSaleEnded, "Sale finished!");
        require(msg.value < maxAmountGweiBuy, "BNB amount must less than max buy amount!");
        require(msg.value > minAmountGweiBuy, "BNB amount must more than min buy amount!");
        require(isAddressWhiteListed[msg.sender], "User must be whitelisted first before buying token, Please contact owner!");
        require (tokenContract.balanceOf(address(this)) > 0, "Insufficient balance in sale contract!");
        if (preSupply == 0){
            preSupply = tokenContract.balanceOf(address(this));
        }
        
        uint256 etherUsed = msg.value;
        uint256 tokensToBuy = etherUsed.mul(tokenAmountPerBNB).div(10 ** 18).mul(tokenContract.decimals());
    	require(tokensToBuy <= tokenContract.balanceOf(address(this)), "Amount must less than left sale balance!");
    	tokenContract.transfer(msg.sender, tokensToBuy);
        
        if (tokenContract.balanceOf(address(this)) <= (preSupply.div(100))) isSaleEnded = true;
        tokenBalanceInSale = tokenContract.balanceOf(address(this));
    }
    
    function checkWhiteListed(address addr) external returns (bool) {
        return isAddressWhiteListed[addr];
    }
    
    
    // owner functions
    
    function setSaleStartforOwnerOnly() external onlyOwner {
        isSaleStarted = true;
        isSaleEnded = false;
    }
    
    function setSaleEndforOwnerOnly () external onlyOwner {
        isSaleEnded = true;
        isSaleStarted = false;
    }
    
    function addToWhiteList (address user) external onlyOwner {
        isAddressWhiteListed[user] = true;
    }
    
    function transferRaisedBNB (address payable reciever) external onlyOwner {
        reciever.transfer(address(this).balance);
    }
    
    function transferToken (address reciever, uint256 amount) external onlyOwner {
        require(amount <= tokenBalanceInSale, "Insufficient balance in sale contract!");
        tokenContract.transfer(reciever, amount);
    }
    
    function updateTokenBalance () external onlyOwner {
        tokenBalanceInSale = tokenContract.balanceOf(address(this));
    }
    
    function setTokenAmountPerBNB (uint256 amount) external onlyOwner {
        tokenAmountPerBNB = amount;
    }
    
    function setTokenAddress (address addr) external onlyOwner {
        tokenAddr = addr;
        tokenContract = IERC20(addr);
    }
    
    function setMinMaxBuyAmountBNB (uint256 minAmount, uint256 maxAmount) external onlyOwner {
        minAmountGweiBuy = minAmount;
        maxAmountGweiBuy = maxAmount;
    }
    
}