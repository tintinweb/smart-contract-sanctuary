/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

contract PresaleTeddy is Ownable {
    using SafeMath for uint;

    IERC20 public token;
    // Presale amount is fixed value. Only can be set at deployment.
    uint public presale1Amount;
    uint public presale2Amount;
    // Presale price 
    uint public presale1Price;
    uint public presale2Price;
    // Presale finish date (Timestamp in second)
    uint public presaleFinishTime;
    uint public soldAmount;
    uint public totalBnbRaised;

    struct userInfo {
        uint bnbPaid;
        uint amountBought;
        uint amountReferred;
    }

    mapping(address => userInfo) public activeAccounts;

    constructor(address _token, uint _presale1Price, uint _presale2Price, uint _presaleFinishTime){
        token = IERC20(_token);
        presale1Price = _presale1Price;
        presale2Price = _presale2Price;
        presaleFinishTime = _presaleFinishTime;
        presale1Amount = token.totalSupply().div(10);
        presale2Amount = token.totalSupply().mul(3).div(10);
    }

    modifier onlyPresaleAmount {
        require(soldAmount <= presale1Amount.add(presale2Amount), "Presale token has sold out");
        _;
    }
    modifier onlyPresalePeriod {
        require(block.timestamp <= presaleFinishTime, "Presale period has passed");
        _;
    }
    modifier onlyAfterPresale {
        require(block.timestamp >= presaleFinishTime, "This operation is not allowed before presale period finishs");
        _;
    }

    function getCurrentPrice() public view returns(uint) {
        uint price;
        if (soldAmount < presale1Amount) {
            price = presale1Price;
        } else {
            price = presale2Price;
        }
        return price;
    }


    function buy() payable external onlyPresaleAmount onlyPresalePeriod {
        require( msg.value >= 1e17, "Min. buying amount is 0.1 BNB");
        require( msg.value <= 5 * 1e18, "Max. buying amount is 5 BNB each time or per acount");        
        require(activeAccounts[msg.sender].bnbPaid.add(msg.value) <= 5 * 1e18, "Max. buying amount is 5 BNB per account");
        
        uint price = getCurrentPrice();

        uint presaleAmount = msg.value.div(1e9).mul(price);

        require(token.balanceOf(address(this)) >= (presaleAmount), "Not enough token for sale: PresaleTeddy.buy");
        require(soldAmount.add(presaleAmount) <= presale1Amount.add(presale2Amount), "Presale token sold out: PresaleTeddy.buy");
        
        // Add bought amount into userInfo data of buyer
        activeAccounts[tx.origin].amountBought = activeAccounts[tx.origin].amountBought.add(presaleAmount);
        // Accumulate total paid bnb in userInfo data of buyer
        activeAccounts[tx.origin].bnbPaid = activeAccounts[tx.origin].bnbPaid.add(msg.value);
        // Accumulate total sold token 
        soldAmount = soldAmount.add(presaleAmount);
        // Accoumulate total bnb raised
        totalBnbRaised = totalBnbRaised.add(msg.value);
    }
    
    function buyWithReferral(address _referral) payable external onlyPresaleAmount onlyPresalePeriod {
        require( msg.value >= 1e17, "Min. buying amount is 0.1 BNB");
        require( msg.value <= 5 * 1e18, "Max. buying amount is 5 BNB each time or per acount");
        require(activeAccounts[msg.sender].bnbPaid.add(msg.value) <= 5 * 1e18, "Max. buying amount is 5 BNB per account");
        require(_referral != 0x0000000000000000000000000000000000000000, "Referral not valid: != 0x0000000000000000000000000000000000000000");
        require(_referral.balance != 0, "Referral is a empty address: 0 balance");
        require(_referral != tx.origin, "Referral is not allowed to be sender");
        
        uint price = getCurrentPrice();

        uint presaleAmount = msg.value.div(1e9).mul(price);
        uint referredAmount = msg.value.div(1e9).mul(price).mul(3).div(10);

        require(token.balanceOf(address(this)) >= (presaleAmount + referredAmount), "Not enough token for sale: PresaleTerry.buyWithReferral");
        require(soldAmount.add(presaleAmount).add(referredAmount) <= presale1Amount.add(presale2Amount), "Presale token sold out: PresaleTeddy.buyWithReferral");
        // Add bought amount into userInfo data of buyer
        activeAccounts[tx.origin].amountBought = activeAccounts[tx.origin].amountBought.add(presaleAmount);
        // Add reffered amount into userInfo data of refferal
        activeAccounts[_referral].amountReferred = activeAccounts[_referral].amountReferred.add(referredAmount);
        // Accumulate total paid bnb in userInfo data of buyer
        activeAccounts[tx.origin].bnbPaid = activeAccounts[tx.origin].bnbPaid.add(msg.value);
        // Accumulate total sold token 
        soldAmount = soldAmount.add(referredAmount).add(presaleAmount);
        // Accoumulate total bnb raised
        totalBnbRaised = totalBnbRaised.add(msg.value);
    }

    function withdrawBNB(address payable payto, uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Not enough BNB to withdraw: PresaleTerry.withdrawBNB");
        payto.transfer(_amount);
    }

    function claim() external onlyAfterPresale {
        uint lockedAmount = activeAccounts[tx.origin].amountBought.add(activeAccounts[tx.origin].amountReferred);
        require(lockedAmount > 0, "You do not have token to claim");
        
        activeAccounts[tx.origin].amountBought = 0;
        activeAccounts[tx.origin].amountReferred = 0;
        token.transfer(tx.origin, lockedAmount);
    }

    function setPriceOne(uint _newPrice) external onlyOwner {
        presale1Price = _newPrice;
    }

    function setPriceTwo(uint _newPrice) external onlyOwner {
        presale2Price = _newPrice;
    }
    
    function setFinishTime(uint _newEndTime) external onlyOwner {
        require( _newEndTime > block.timestamp, "The new End time need to be later than current time");
        presaleFinishTime = _newEndTime;
    }
}