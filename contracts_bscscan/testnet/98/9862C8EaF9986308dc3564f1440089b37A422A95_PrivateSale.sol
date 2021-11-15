// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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
    mapping (address => bool) private _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddOwner(address indexed newOwner, bool indexed result);
    event RemoveOwner(address indexed newOwner, bool indexed result);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        _owners[msgSender] = true;
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
        require(_owners[_msgSender()], "Ownable: caller is not the owner");
        _;
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

    function addOwner(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: Owner is the zero address");
        _owners[_newOwner] = true;
        emit AddOwner(_newOwner, true);
    }

    function removeOwner(address _newOwner) public virtual onlyOwner {
        address msgSender = _msgSender();
        require(_newOwner != address(0), "Ownable: Owner is the zero address");
        require(_newOwner != msgSender, "You can't remove yourself");
        _owners[_newOwner] = false;
        emit RemoveOwner(_newOwner, false);
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IERC20 {

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


contract PrivateSale is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (address => bool) private validMultiCoins;
    mapping (address => uint256) private multiCoinBalance;
    mapping (address => mapping (address => uint256)) private multiCoinBalanceByInvestor;

    mapping (address => uint256) private users_BNB_Value;
    mapping (address => uint256) private users_TOKEN_Value;

    mapping (address => bool) private checkInvestors;
    mapping (uint256 => address) private investors;

    uint256 private total;
    uint256 private minContribution = 1 * 10**17; // 0.1 BNB
    uint256 private maxContribution = 3 * 10**18; // 3 BNB
    uint256 private tokenValueForBNB = 20 * 10**6; // 1 BNB = 20,000,000 NFTBD
    address private fundAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private secretCode;
    bool private pause;


    constructor(address _fundAddress, uint256 _secretCode) {
        fundAddress = _fundAddress;
        secretCode = _secretCode;
        pause = false;
    }

    function addInvestorAddress(address _wallet) private returns(bool) {
        if (!checkInvestors[_wallet]) {
            checkInvestors[_wallet] = true;

            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            investors[newItemId] = _wallet;
        }
        return true;
    }

    function joinWithBNB() external payable returns (bool) {

        require(!pause, "Private Sale is over");

        uint256 bnbAmountToSent = msg.value;
        address sender = _msgSender();

        require(bnbAmountToSent > 0, "Your BNB balance is too low");
        require(sender != address(0), "User address can't be the zero address");

        require(bnbAmountToSent >= minContribution, "You must invest at least 0.1 BNB");

        uint256 tokenAmount = _calculAmount(bnbAmountToSent);

        users_BNB_Value[sender] = users_BNB_Value[sender].add(bnbAmountToSent);
        users_TOKEN_Value[sender] = users_TOKEN_Value[sender].add(tokenAmount);

        total = total.add(bnbAmountToSent);
        addInvestorAddress(sender);

        payable(fundAddress).transfer(bnbAmountToSent);

        return true;
    }

    function joinWithMultiCoin(address BEP20Address, uint256 BEP20Amount, uint256 tokenAmount, uint256 bnbAmount, uint256 _secretCode) external returns (bool) {

        require(!pause, "Private Sale is over");

        require(secretCode == _secretCode, "Secret Code not found");

        require(BEP20Address != address(0), "BEP20Address can't be the zero address");
        require(validMultiCoins[BEP20Address], "This token is not support");

        require(BEP20Amount > 0, "BEP20 amount must be greater than zero");
        uint256 BEP20TokenBalance = IERC20(BEP20Address).balanceOf(msg.sender);
        require(BEP20TokenBalance > 0, "Your BEP20 balance must be greater than zero");
        require(BEP20TokenBalance >= BEP20Amount, "Your BEP20 balance must be greater than BEP20Amount");

        require(tokenAmount > 0, "tokenAmount amount must be greater than zero");
        require(bnbAmount > 0, "bnbAmount amount must be greater than zero");

        uint256 allowanceBalance = IERC20(BEP20Address).allowance(msg.sender, address(this));
        require(allowanceBalance >= BEP20Amount, "Your allowanceBalance is low");

        require(IERC20(BEP20Address).transferFrom(msg.sender, fundAddress, BEP20Amount), "BEP20 payment failed after allowance");

        users_BNB_Value[msg.sender] = users_BNB_Value[msg.sender].add(bnbAmount);
        users_TOKEN_Value[msg.sender] = users_TOKEN_Value[msg.sender].add(tokenAmount);

        multiCoinBalance[BEP20Address] = multiCoinBalance[BEP20Address].add(BEP20Amount);
        multiCoinBalanceByInvestor[msg.sender][BEP20Address] = multiCoinBalanceByInvestor[msg.sender][BEP20Address].add(BEP20Amount);

        addInvestorAddress(msg.sender);

        return true;
    }

    function getMyInvest(address _address) public view returns(uint256 investBNB, uint256 investToken) {
        return (users_BNB_Value[_address], users_TOKEN_Value[_address]);
    }

    function getMyInvestByToken(address _address, address BEP20Address) public view returns(uint256) {
        return multiCoinBalanceByInvestor[_address][BEP20Address];
    }

    function getInvestByBEP20Address(address _address) public view onlyOwner() returns(uint256) {
        return multiCoinBalance[_address];
    }

    function getInvestor(uint256 i) public view onlyOwner() returns(address) {
        return investors[i];
    }

    function checkInvestor(address _address) public view onlyOwner() returns(bool) {
        return checkInvestors[_address];
    }

    function totalInvestor() public view returns(uint256) {
        return _tokenIds.current();
    }

    function totalInvest() public view returns(uint256) {
        return total;
    }

    function setMinMaxContribution(uint256 _minContribution, uint256 _maxContribution) external onlyOwner() {
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    function setFundAddress(address _fundAddress) external onlyOwner() {
        fundAddress = _fundAddress;
    }

    function getMinMaxContribution() public view onlyOwner() returns(uint256 min, uint256 max) {
        return(minContribution, maxContribution);
    }

    function getFundAddress() public view onlyOwner() returns(address) {
        return fundAddress;
    }

    function _calculAmount(uint256 amountInvest) private view returns (uint256) {
        return tokenValueForBNB.mul(amountInvest);
    }

    function setSecreCode(uint256 _secretCode) external onlyOwner() {
        secretCode = _secretCode;
    }

    function getSecreCode() external view onlyOwner() returns(uint256) {
        return secretCode;
    }

    function setPause(bool _pause) external onlyOwner() {
        pause = _pause;
    }

    function getPause() external view returns(bool) {
        return pause;
    }

    function setTokenForPayment(address _bep20Address, bool _val) external onlyOwner() returns(bool) {
        validMultiCoins[_bep20Address] = _val;
        return true;
    }

    function checkTokenForPayment(address _bep20Address) public view onlyOwner() returns(bool) {
        return validMultiCoins[_bep20Address];
    }

    function secureWallet(uint256 _value) external onlyOwner() {
        payable(owner()).transfer(_value);
    }

    function routerCustomToken(address _customAddress) external onlyOwner() {
        uint256 tokens = IERC20(_customAddress).balanceOf(address(this));
        require(tokens > 0, "Token must be greater than zero");
        IERC20(_customAddress).transfer(msg.sender, tokens);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}