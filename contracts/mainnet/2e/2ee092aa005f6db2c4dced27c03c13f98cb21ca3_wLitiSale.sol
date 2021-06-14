/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: contracts/sale_v2.sol

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

//@R

//+---------------------------------------------------------------------------------------+
// Imports
//+---------------------------------------------------------------------------------------+



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

//+---------------------------------------------------------------------------------------+
// Contracts
//+---------------------------------------------------------------------------------------+

/** This contract is designed for coordinating the sale of wLiti tokens to purchasers
  *     and includes a referral system where referrers earn bonus tokens on each wLiti
  *     sale.
  **/
contract wLitiSale is Context, Ownable {

    using SafeMath for uint256;

    //+---------------------------------------------------------------------------------------+
    // Structures
    //+---------------------------------------------------------------------------------------+

    //Type for tracking referral memebers and their bonus percentages
    struct Referrer {

        bool isReferrer;  //If true, referer is allowed to receive referral bonuses
        uint256 bonusPercent; //Percentage bonus amount

    }

    //+---------------------------------------------------------------------------------------+
    // Contract Data Members
    //+---------------------------------------------------------------------------------------+

    //Referral info
    address private _masterReferrerWallet; //Wallet of the master referrer (this person ALWAYS recieves a bonus)
    uint256 private _maxBonusPercent; //Max bonus that can be given to referrers
    mapping(address => Referrer) _referrers; //Track referrer info

    //Sale info
    IERC20 private _token; //Token to be sold
    address private _ETHWallet; //Wallet ETH is sent to
    uint256 private _saleCount; //Counts the number of sales
    uint256 private _tokenPrice; //ETH price per token
    uint256 private _saleSupplyLeft; //Supply left in sale
    uint256 private _saleSupplyTotal; //Total supply of sale
    uint256 private _saleStartTime; //Sale start epoch timestamp
    uint256 private _saleEndTime; //Sale end epoch timestamp
    mapping(uint256 => uint256) _weiRaised; //Track wei raised from each sale

    //+---------------------------------------------------------------------------------------+
    // Constructors
    //+---------------------------------------------------------------------------------------+

    /** Constructor to build the contract
      *
      * @param token - the contract address of the token that is being sold
      * @param ETHWallet - the wallet that ETH will be sent to after every purchase
      * @param masterReferrerWallet - the wallet of the master referrer
      *
      **/
    constructor(address token, address ETHWallet, address masterReferrerWallet) {

        _token = IERC20(token);
        _ETHWallet = ETHWallet;
        _masterReferrerWallet = masterReferrerWallet;

    }

    //+---------------------------------------------------------------------------------------+
    // Getters
    //+---------------------------------------------------------------------------------------+

    function getMasterReferrerWallet() public view returns (address) { return _masterReferrerWallet; }

    function getReferrerBonusPercent(address referrer) public view returns (uint256) { return _referrers[referrer].bonusPercent; }

    function getMaxBonusPercent() public view returns (uint256) { return _maxBonusPercent; }

    function getTokenPrice() public view returns (uint256) { return _tokenPrice; }

    function getSaleSupplyLeft() public view returns (uint256) { return _saleSupplyLeft; }

    function getSaleSupplyTotal() public view returns (uint256) { return _saleSupplyTotal; }

    function getSaleStartTime() public view returns (uint256) { return _saleStartTime; }

    function getSaleEndTime() public view returns (uint256) { return _saleEndTime; }

    function getSaleCount() public view returns (uint256) { return _saleCount; }

    function getWeiRaised(uint256 sale) public view returns (uint256) { return _weiRaised[sale]; }

    function getETHWallet() public view returns (address) { return _ETHWallet; }

    function isSaleActive() public view returns (bool) {

        return (block.timestamp > _saleStartTime &&
                block.timestamp < _saleEndTime);

    }

    function isReferrer(address referrer) public view returns (bool) { return _referrers[referrer].isReferrer; }

    //+---------------------------------------------------------------------------------------+
    // Private Functions
    //+---------------------------------------------------------------------------------------+

    function transferReferralTokens(address referrer, uint256 bonusPercent, uint purchaseAmountBig) private {

        uint256 referralAmountBig = purchaseAmountBig.mul(bonusPercent).div(10**2);
        _token.transfer(referrer, (referralAmountBig));

    }

    //+---------------------------------------------------------------------------------------+
    // Public/User Functions
    //+---------------------------------------------------------------------------------------+

    /** Purchase tokens from contract and distribute token bonuses to referrers. Master referrer will ALWAYS recieve at least
      *     a 1% token bonus. A second referrer address is required to be provided when purchasing and they will recieve at least 1%.
      *     A third referrer is optional, but not required. If the optional referrer is an autherized Referrer by the contract owner, then
      *     the optional referrer will receive a minimum of a 1% token bonus.
      *
      *  @param purchaseAmount - the amount of tokens that the purchaser wants to buy
      *  @param referrer - second referrer that is required
      *  @param optionalReferrer - third referrer that is optional
      **/
    function purchaseTokens(uint256 purchaseAmount, address referrer, address optionalReferrer) public payable {

        require(_msgSender() != address(0), "AddressZero cannot purchase tokens");
        require(isSaleActive(), "Sale is not active");
        require(getTokenPrice() != 0, "Token price is not set");
        require(getMaxBonusPercent() != 0, "Referral bonus percent is not set");
        require(isReferrer(referrer), "Referrer is not authorized");

        //Calculate big number amounts
        uint256 purchaseAmountBig = purchaseAmount * 1 ether; //Amount of tokens user is purchasing
        uint256 totalRAmountBig = purchaseAmountBig.mul(_maxBonusPercent).div(10**2); //Amount of tokens referrers will earn
        uint256 totalAmountBig = purchaseAmountBig.add(totalRAmountBig); //Total amount of tokens being distributed
        uint256 masterBonusPercent = _maxBonusPercent; //Bonus percent for the master referrer

        require(totalAmountBig <= _saleSupplyLeft, "Purchase amount is bigger than the remaining sale supply");

        uint256 totalPrice = purchaseAmount * _tokenPrice; //Total ETH price for tokens
        require(msg.value >= totalPrice, "Payment amount too low");

        //If the optionalReferrer is an authorized referrer, then distribute referral bonus tokens
        if(isReferrer(optionalReferrer)) {

            require(_referrers[referrer].bonusPercent + _referrers[optionalReferrer].bonusPercent < _maxBonusPercent,
                "Referrers bonus percent must be less than max bonus");

            //Subtract the master's bonus by the referrers' bonus AND transfer tokens to the optional referrer
            masterBonusPercent = masterBonusPercent.sub(_referrers[referrer].bonusPercent).sub(_referrers[optionalReferrer].bonusPercent);
            transferReferralTokens(optionalReferrer, _referrers[optionalReferrer].bonusPercent, purchaseAmountBig);

        }
        //There is only one referrer, ignore the optional referrer
        else {

            require(_referrers[referrer].bonusPercent < _maxBonusPercent, "Referrer bonus percent must be less than max bonus");

            //Subtract the master's bonus by the referrer's bonus
            masterBonusPercent = masterBonusPercent.sub(_referrers[referrer].bonusPercent);

        }

        //Transfer tokens to referrer, master referrer, and purchaser
        transferReferralTokens(referrer, _referrers[referrer].bonusPercent, purchaseAmountBig);
        transferReferralTokens(_masterReferrerWallet, masterBonusPercent, purchaseAmountBig);
        _token.transfer(msg.sender, (purchaseAmountBig));

        //Modify sale information
        _weiRaised[_saleCount] = _weiRaised[_saleCount] + totalPrice;
        _saleSupplyLeft = _saleSupplyLeft - (totalAmountBig);

        //Transfer ETH back to presale wallet
        address payable walletPayable = payable(_ETHWallet);
        walletPayable.transfer(totalPrice);

        //Transfer extra ETH back to buyer
        address payable client = payable(msg.sender);
        client.transfer(msg.value - totalPrice);

    }

    //+---------------------------------------------------------------------------------------+
    // Setters (Owner Only)
    //+---------------------------------------------------------------------------------------+

    //Set the max bonue that referrers can earn
    function setMaxBonusPercent(uint256 percent) public onlyOwner { _maxBonusPercent = percent; }

    //Set the ETH price of the tokens
    function setTokenPrice(uint256 price) public onlyOwner { _tokenPrice = price; }

    //Set the wallet to receive ETH
    function setETHWallet(address ETHWallet) public onlyOwner { _ETHWallet = ETHWallet; }

    //Set the master referrer wallet
    function setMasterReferrerWallet(address masterReferrerWallet) public onlyOwner { _masterReferrerWallet = masterReferrerWallet; }

    //Set referrer bonus percent
    function setReferrerBonusPercent(address referrer, uint256 bonusPercent) public onlyOwner {

        _referrers[referrer].bonusPercent = bonusPercent;

    }

    //+---------------------------------------------------------------------------------------+
    // Controls (Owner Only)
    //+---------------------------------------------------------------------------------------+

    //Add a referrer
    function addReferrer(address referrer, uint256 bonusPercent) public onlyOwner {

        require(!isReferrer(referrer), "Address is already a referrer");
        require(bonusPercent < _maxBonusPercent, "Referrer bonus cannot be equal to or greater than max bonus");
        require(bonusPercent > 0, "Bonus percent must be greater than 0");

        _referrers[referrer].isReferrer = true;
        _referrers[referrer].bonusPercent = bonusPercent;

    }

    //Remove a referrer
    function removeReferrer(address referrer) public onlyOwner {

        require(isReferrer(referrer), "Address already is not a referrer");

        delete _referrers[referrer];

    }

    //Withdraw a number of tokens from contract to the contract owner
    function withdrawToken(uint256 amount) public onlyOwner {
        _token.transfer(owner(), amount);
    }

    //Withdraw ALL tokens from contract to the contract owner
    function withdrawAllTokens() public onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    //Create a sale
    function createSale(uint256 supply, uint256 timeStart, uint256 timeEnd) public onlyOwner {

        require(supply <= _token.balanceOf(address(this)), "Supply too high, not enough tokens in contract");
        require(timeStart >= block.timestamp, "Sale start time cannot be in the past");
        require(timeEnd > timeStart, "Sale start time cannot be before the end time");

        //Store sale info
        _saleSupplyTotal = supply;
        _saleSupplyLeft = supply;
        _saleStartTime = timeStart;
        _saleEndTime = timeEnd;
        _saleCount += 1;

    }

}