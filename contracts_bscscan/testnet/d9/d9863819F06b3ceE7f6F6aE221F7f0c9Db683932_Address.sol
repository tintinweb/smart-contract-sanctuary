/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-21
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

// File: contracts/IERC20Cutted.sol

pragma solidity ^0.6.2;


interface IERC20Cutted {

    // Some old tokens are implemented without a retrun parameter (this was prior to the ERC20 standart change)
    function transfer(address to, uint256 value) external;

    function balanceOf(address who) external view returns (uint256);

}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
}

// File: contracts/RetrieveTokensFeature.sol

pragma solidity ^0.6.2;





contract RetrieveTokensFeature is Context, Ownable {

    function retrieveTokens(address to, address anotherToken) virtual public onlyOwner() {
        IERC20Cutted alienToken = IERC20Cutted(anotherToken);
        alienToken.transfer(to, alienToken.balanceOf(address(this)));
    }

    function retriveETH(address payable to) virtual public onlyOwner() {
        to.transfer(address(this).balance);
    }

}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/StagedCrowdsale.sol

pragma solidity ^0.6.2;






contract StagedCrowdsale is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct Milestone {
        uint256 start;
        uint256 end;
        uint256 bonus;
        uint256 minInvestedLimit;
        uint256 maxInvestedLimit;
        uint256 invested;
        uint256 tokensSold;
        uint256 hardcapInTokens;
    }

    Milestone[] public milestones;

    function milestonesCount() public view returns (uint) {
        return milestones.length;
    }

    function addMilestone(uint256 start, uint256 end, uint256 bonus, uint256 minInvestedLimit, uint256 maxInvestedLimit, uint256 invested, uint256 tokensSold, uint256 hardcapInTokens) public onlyOwner {
        milestones.push(Milestone(start, end, bonus, minInvestedLimit, maxInvestedLimit, invested, tokensSold, hardcapInTokens));
    }

    function removeMilestone(uint8 number) public onlyOwner {
        require(number < milestones.length);
        //Milestone storage milestone = milestones[number];

        delete milestones[number];

        // check it
        for (uint i = number; i < milestones.length - 1; i++) {
            milestones[i] = milestones[i + 1];
        }

    }

    function changeMilestone(uint8 number, uint256 start, uint256 end, uint256 bonus, uint256 minInvestedLimit, uint256 maxInvestedLimit, uint256 invested, uint256 tokensSold, uint256 hardcapInTokens) public onlyOwner {
        require(number < milestones.length);
        Milestone storage milestone = milestones[number];

        milestone.start = start;
        milestone.end = end;
        milestone.bonus = bonus;
        milestone.minInvestedLimit = minInvestedLimit;
        milestone.maxInvestedLimit = maxInvestedLimit;
        milestone.invested = invested;
        milestone.tokensSold = tokensSold;
        milestone.hardcapInTokens = hardcapInTokens;
    }

    function insertMilestone(uint8 index, uint256 start, uint256 end, uint256 bonus, uint256 minInvestedLimit, uint256 maxInvestedLimit, uint256 invested, uint256 tokensSold, uint256 hardcapInTokens) public onlyOwner {
        require(index < milestones.length);
        for (uint i = milestones.length; i > index; i--) {
            milestones[i] = milestones[i - 1];
        }
        milestones[index] = Milestone(start, end, bonus, minInvestedLimit, maxInvestedLimit, invested, tokensSold, hardcapInTokens);
    }

    function clearMilestones() public onlyOwner {
        require(milestones.length > 0);
        for (uint i = 0; i < milestones.length; i++) {
            delete milestones[i];
        }
    }

    function currentMilestone() public view returns (uint256) {
        for (uint256 i = 0; i < milestones.length; i++) {
            if (now >= milestones[i].start && now < milestones[i].end && milestones[i].tokensSold <= milestones[i].hardcapInTokens) {
                return i;
            }
        }
        revert();
    }

}

// File: contracts/CommonSale.sol

pragma solidity ^0.6.2;





contract CommonSale is StagedCrowdsale, RetrieveTokensFeature {

    IERC20Cutted public token;
    uint256 public price; // amount of tokens per 1 ETH
    uint256 public invested;
    uint256 public percentRate = 100;
    address payable public wallet;
    bool public isPause = false;
    mapping(address => bool) public whitelist;

    mapping(uint256 => mapping(address => uint256)) public balances;

    mapping(uint256 => bool) public whitelistedMilestones;

    function setMilestoneWithWhitelist(uint256 index) public onlyOwner {
        whitelistedMilestones[index] = true;
    }

    function unsetMilestoneWithWhitelist(uint256 index) public onlyOwner {
        whitelistedMilestones[index] = false;
    }

    function addToWhiteList(address target) public onlyOwner {
        require(!whitelist[target], "Already in whitelist");
        whitelist[target] = true;
    }

    function addToWhiteListMultiple(address[] memory targets) public onlyOwner {
        for (uint i = 0; i < targets.length; i++) {
            if (!whitelist[targets[i]]) whitelist[targets[i]] = true;
        }
    }

    function pause() public onlyOwner {
        isPause = true;
    }

    function unpause() public onlyOwner {
        isPause = false;
    }

    function setToken(address newTokenAddress) public onlyOwner() {
        token = IERC20Cutted(newTokenAddress);
    }

    function setPercentRate(uint256 newPercentRate) public onlyOwner() {
        percentRate = newPercentRate;
    }

    function setWallet(address payable newWallet) public onlyOwner() {
        wallet = newWallet;
    }

    function setPrice(uint256 newPrice) public onlyOwner() {
        price = newPrice;
    }

    function updateInvested(uint256 value) internal {
        invested = invested.add(value);
    }

    function internalFallback() internal returns (uint) {
        require(!isPause, "Contract paused");

        uint256 milestoneIndex = currentMilestone();
        Milestone storage milestone = milestones[milestoneIndex];
        uint256 limitedInvestValue = msg.value;

        // limit the minimum amount for one transaction (ETH) 
        require(limitedInvestValue >= milestone.minInvestedLimit, "The amount is too small");

        // check if the milestone requires user to be whitelisted
        if (whitelistedMilestones[milestoneIndex]) {
            require(whitelist[_msgSender()], "The address must be whitelisted!");
        }

        // limit the maximum amount that one user can spend during the current milestone (ETH)
        uint256 maxAllowableValue = milestone.maxInvestedLimit - balances[milestoneIndex][_msgSender()];
        if (limitedInvestValue > maxAllowableValue) {
            limitedInvestValue = maxAllowableValue;
        }
        require(limitedInvestValue > 0, "Investment limit exceeded!");

        // apply a bonus if any (10SET)
        uint256 tokensWithoutBonus = limitedInvestValue.mul(price).div(1 ether);
        uint256 tokensWithBonus = tokensWithoutBonus;
        if (milestone.bonus > 0) {
            tokensWithBonus = tokensWithoutBonus.add(tokensWithoutBonus.mul(milestone.bonus).div(percentRate));
        }

        // limit the number of tokens that user can buy according to the hardcap of the current milestone (10SET)
        if (milestone.tokensSold.add(tokensWithBonus) > milestone.hardcapInTokens) {
            tokensWithBonus = milestone.hardcapInTokens.sub(milestone.tokensSold);
            if (milestone.bonus > 0) {
                tokensWithoutBonus = tokensWithBonus.mul(percentRate).div(percentRate + milestone.bonus);
            }
        }
        
        // calculate the resulting amount of ETH that user will spend and calculate the change if any
        uint256 tokenBasedLimitedInvestValue = tokensWithoutBonus.mul(1 ether).div(price);
        uint256 change = msg.value - tokenBasedLimitedInvestValue;

        // update stats
        invested = invested.add(tokenBasedLimitedInvestValue);
        milestone.tokensSold = milestone.tokensSold.add(tokensWithBonus);
        balances[milestoneIndex][_msgSender()] = balances[milestoneIndex][_msgSender()].add(tokenBasedLimitedInvestValue);
        
        wallet.transfer(tokenBasedLimitedInvestValue);
        
        // we multiply the amount to send by 100 / 98 to compensate the buyer 2% fee charged on each transaction
        token.transfer(_msgSender(), tokensWithBonus.mul(100).div(98));
        
        if (change > 0) {
            _msgSender().transfer(change);
        }

        return tokensWithBonus;
    }

    receive() external payable {
        internalFallback();
    }

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: contracts/TenSetToken.sol

pragma solidity ^0.6.2;






contract TenSetToken is IERC20, RetrieveTokensFeature {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 210000000 * 10 ** 18;
    uint256 private constant BURN_STOP_SUPPLY = 2100000 * 10 ** 18;
    uint256 private _tTotal = INITIAL_SUPPLY;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "10Set Token";
    string private _symbol = "10SET";
    uint8 private _decimals = 18;

    constructor (address[] memory addresses, uint256[] memory amounts) public {
        uint256 rDistributed = 0;
        // loop through the addresses array and send tokens to each address except the last one
        // the corresponding amount to sent is taken from the amounts array
        for(uint8 i = 0; i < addresses.length - 1; i++) {
            (uint256 rAmount, , , , , , ) = _getValues(amounts[i]);
            _rOwned[addresses[i]] = rAmount;
            rDistributed = rDistributed + rAmount;
            emit Transfer(address(0), addresses[i], amounts[i]);
        }
        // all remaining tokens will be sent to the last address in the addresses array
        uint256 rRemainder = _rTotal - rDistributed;
        address liQuidityWalletAddress = addresses[addresses.length - 1];
        _rOwned[liQuidityWalletAddress] = rRemainder;
        emit Transfer(address(0), liQuidityWalletAddress, tokenFromReflection(rRemainder));
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burn(uint256 amount) public {
        require(_msgSender() != address(0), "ERC20: burn from the zero address");
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(_msgSender(), amount, rAmount);
    }

    function burnFrom(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        (uint256 rAmount, , , , , , ) = _getValues(amount);
        _burn(account, amount, rAmount);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            ( , uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _reflectBurn(uint256 rBurn, uint256 tBurn, address account) private {
        _rTotal = _rTotal.sub(rBurn);
        _tTotal = _tTotal.sub(tBurn);
        emit Transfer(account, address(0), tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn) = _getRValues(tAmount, tFee, tBurn);
        return (rAmount, rTransferAmount, rFee, rBurn, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        uint256 tBurn = 0;
        if (_tTotal > BURN_STOP_SUPPLY) {
            tBurn = tAmount.div(100);
            if (_tTotal < BURN_STOP_SUPPLY.add(tBurn)) {
                tBurn = _tTotal.sub(BURN_STOP_SUPPLY);
            }
            tTransferAmount = tTransferAmount.sub(tBurn);
        }
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn) private view returns (uint256, uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = 0;
        uint256 rTransferAmount = rAmount.sub(rFee);
        if (tBurn > 0) {
            rBurn = tBurn.mul(currentRate);
            rTransferAmount = rTransferAmount.sub(rBurn);
        }
        return (rAmount, rTransferAmount, rFee, rBurn);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _burn(address account, uint256 tAmount, uint256 rAmount) private {
        if (_isExcluded[account]) {
            _tOwned[account] = _tOwned[account].sub(tAmount, "ERC20: burn amount exceeds balance");
            _rOwned[account] = _rOwned[account].sub(rAmount, "ERC20: burn amount exceeds balance"); 
        } else {
            _rOwned[account] = _rOwned[account].sub(rAmount, "ERC20: burn amount exceeds balance");
        }
        _reflectBurn(rAmount, tAmount, account);
    }
}

// File: contracts/FreezeTokenWallet.sol

pragma solidity ^0.6.2;




contract FreezeTokenWallet is RetrieveTokensFeature {

  using SafeMath for uint256;

  IERC20Cutted public token;
  bool public started;
  uint256 public startDate;
  uint256 public startBalance;
  uint256 public duration;
  uint256 public interval;
  uint256 public retrievedTokens;

  modifier notStarted() {
    require(!started);
    _;
  }

  function setStartDate(uint newStartDate) public onlyOwner notStarted {
    startDate = newStartDate;
  }

  function setDuration(uint newDuration) public onlyOwner notStarted {
    duration = newDuration * 1 days;
  }

  function setInterval(uint newInterval) public onlyOwner notStarted {
    interval = newInterval * 1 days;
  }

  function setToken(address newToken) public onlyOwner notStarted {
    token = IERC20Cutted(newToken);
  }

  function start() public onlyOwner notStarted {
    startBalance = token.balanceOf(address(this));
    started = true;
  }

  function retrieveWalletTokens(address to) public onlyOwner {
    require(started && now >= startDate);
    if (now >= startDate + duration) {
      token.transfer(to, token.balanceOf(address(this)));
    } else {
      uint parts = duration.div(interval);
      uint tokensByPart = startBalance.div(parts);
      uint timeSinceStart = now.sub(startDate);
      uint pastParts = timeSinceStart.div(interval);
      uint tokensToRetrieveSinceStart = pastParts.mul(tokensByPart);
      uint tokensToRetrieve = tokensToRetrieveSinceStart.sub(retrievedTokens);
      require(tokensToRetrieve > 0, "No tokens available for retrieving at this moment.");
      retrievedTokens = retrievedTokens.add(tokensToRetrieve);
      token.transfer(to, tokensToRetrieve);
    }
  }

  function retrieveTokens(address to, address anotherToken) override public onlyOwner {
    require(address(token) != anotherToken, "You should only use this method to withdraw extraneous tokens.");
    super.retrieveTokens(to, anotherToken);
  }

}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: contracts/TokenDistributor.sol

pragma solidity ^0.6.2;






contract TokenDistributor is Ownable, RetrieveTokensFeature {

    IERC20Cutted public token;

    function setToken(address newTokenAddress) public onlyOwner {
        token = IERC20Cutted(newTokenAddress);
    }

    function distribute(address[] memory receivers, uint[] memory balances) public onlyOwner {
        for(uint i = 0; i < receivers.length; i++) {
            token.transfer(receivers[i], balances[i]);
        }
    }

}

// File: contracts/TokenReplacementConfigurator.sol

pragma solidity ^0.6.2;







/**
 * @dev Contract-helper for TenSetToken deployment and token distribution.
 *
 * 1. Company Reserve (10%): 21,000,000 10SET. The total freezing period is 48 months.
 *    Every 12 months, 25% of the initial amount will be unfrozen and ready for
 *    withdrawal using address 0x7BD3b301f3537c75bf64B7468998d20045cfa48e.
 *
 * 2. Team (10%): 21,000,000 10SET. The total freezing period is 30 months.
 *    Every 3 months, 10% of the initial amount will be unfrozen and ready for
 *    withdrawal using address 0x44C4A8d57B22597a2c0397A15CF1F32d8A4EA8F7.
 *
 * 3. Marketing (5%): 10,500,000 10SET.
 *    A half (5,250,000 10SET) will be transferred immediately to the address
 *    0x127D069DC8B964a813889D349eD3dA3f6D35383D.
 *    The remaining 5,250,000 10SET will be frozen for 12 months.
 *    Every 3 months, 25% of the initial amount will be unfrozen and ready for
 *    withdrawal using address 0x127D069DC8B964a813889D349eD3dA3f6D35383D.
 *
 * 4. Sales: 150,000,000 10SET (147,000,000 10SET plus compensation for the
 *    initial 2% transferring costs). These tokens will be distributed between
 *    the CommonSale contract and existing users who participated in the first phase of the sale.
 *
 * 5. Liquidity Reserve: 7,500,000 10SET (10,500,000 10SET minus tokens that
 *    went to compensation in paragraph 4). The entire amount will be unfrozen
 *    from the start and sent to the address 0x91E84302594deFaD552938B6D0D56e9f39908f9F.
 */
contract TokenReplacementConfigurator is RetrieveTokensFeature {
    using SafeMath for uint256;

    uint256 private constant COMPANY_RESERVE_AMOUNT    = 21000000 * 1 ether;
    uint256 private constant TEAM_AMOUNT               = 21000000 * 1 ether;
    uint256 private constant MARKETING_AMOUNT_1        = 5250000 * 1 ether;
    uint256 private constant MARKETING_AMOUNT_2        = 5250000 * 1 ether;
    uint256 private constant LIQUIDITY_RESERVE         = 7500000 * 1 ether;

    address private constant OWNER_ADDRESS             = address(0x68CE6F1A63CC76795a70Cf9b9ca3f23293547303);
    address private constant TEAM_WALLET_OWNER_ADDRESS = address(0x44C4A8d57B22597a2c0397A15CF1F32d8A4EA8F7);
    address private constant MARKETING_WALLET_ADDRESS  = address(0x127D069DC8B964a813889D349eD3dA3f6D35383D);
    address private constant COMPANY_RESERVE_ADDRESS   = address(0x7BD3b301f3537c75bf64B7468998d20045cfa48e);
    address private constant LIQUIDITY_WALLET_ADDRESS  = address(0x91E84302594deFaD552938B6D0D56e9f39908f9F);
    address private constant DEPLOYER_ADDRESS          = address(0x6E9DC3D20B906Fd2B52eC685fE127170eD2165aB);

    uint256 private constant STAGE1_START_DATE         = 1612116000;    // Jan 31 2021 19:00:00 GMT+0100

    TenSetToken public token;
    FreezeTokenWallet public companyReserveWallet;
    FreezeTokenWallet public teamWallet;
    FreezeTokenWallet public marketingWallet;
    TokenDistributor public tokenDistributor;

    constructor () public {
        address[] memory addresses = new address[](6);
        uint256[] memory amounts = new uint256[](5);
        
        companyReserveWallet = new FreezeTokenWallet();
        teamWallet = new FreezeTokenWallet();
        marketingWallet = new FreezeTokenWallet();
        tokenDistributor = new TokenDistributor();

        addresses[0]    = address(companyReserveWallet);
        amounts[0]      = COMPANY_RESERVE_AMOUNT;
        addresses[1]    = address(teamWallet);
        amounts[1]      = TEAM_AMOUNT;
        addresses[2]    = MARKETING_WALLET_ADDRESS;
        amounts[2]      = MARKETING_AMOUNT_1;
        addresses[3]    = address(marketingWallet);
        amounts[3]      = MARKETING_AMOUNT_2;
        addresses[4]    = LIQUIDITY_WALLET_ADDRESS;
        amounts[4]      = LIQUIDITY_RESERVE;
        // will receive the remaining tokens to distribute them between CommonSale contract
        // and existing users who participated in the first phase of the sale.
        addresses[5]    = address(tokenDistributor);

        token = new TenSetToken(addresses, amounts);

        companyReserveWallet.setToken(address(token));
        companyReserveWallet.setStartDate(STAGE1_START_DATE);
        companyReserveWallet.setDuration(1440);     // 4 years = 48 months = 1440 days
        companyReserveWallet.setInterval(360);      // 12 months = 360 days
        companyReserveWallet.start();

        teamWallet.setToken(address(token));
        teamWallet.setStartDate(STAGE1_START_DATE);
        teamWallet.setDuration(900);                // 2.5 years = 30 months = 900 days
        teamWallet.setInterval(90);                 // 3 months = 90 days
        teamWallet.start();

        marketingWallet.setToken(address(token));
        marketingWallet.setStartDate(STAGE1_START_DATE);
        marketingWallet.setDuration(360);           // 1 year = 12 months = 360 days
        marketingWallet.setInterval(90);            // 3 months = 90 days
        marketingWallet.start();
        
        tokenDistributor.setToken(address(token));

        token.transferOwnership(OWNER_ADDRESS);
        companyReserveWallet.transferOwnership(COMPANY_RESERVE_ADDRESS);
        teamWallet.transferOwnership(TEAM_WALLET_OWNER_ADDRESS);
        marketingWallet.transferOwnership(MARKETING_WALLET_ADDRESS);
        tokenDistributor.transferOwnership(DEPLOYER_ADDRESS);
    }

}