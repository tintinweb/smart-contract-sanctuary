// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Iagon Types
 * @author Iagon
 */
library Types {
    struct Invest {
        uint256 deposit;
        uint256 releaseCounter;
        uint256 ratePerMonth;
        uint256[] timesInMonth;
        uint256[] counterArray;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "./contracts/Types.sol";

contract TokenVesting is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

    // Investing count
    uint256 public nextInvestId;

    // Iagon Token Address
    address public iagonTokenAddress;

    // for testing 5 min interval in seconds
    //uint256[] intervalTime = [300, 600, 900, 1200, 1500, 1800, 2100, 2400, 2700, 3000]; 

    // array of intervals in months(upto 10 months)
    uint256[] intervalTime = [30 days, 61 days, 91 days, 122 days, 152 days, 183 days, 213 days, 244 days, 274 days, 304 days];
   
    // array of numbers
    uint256[] countArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    
    // mapping of invest id with Invest struct information
    mapping(uint256 => Types.Invest) private invests;
  
    /**
     * @dev Emitted when sender invest the tokens.
    */ 

    event CreateInvesting(
        uint256 indexed investId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    /**
     * @dev Emitted when sender or recipient withdraws the amount of tokens from investing.
    */ 

    event WithdrawFromInvesting( 
        uint256 indexed investId, 
        address indexed recipient, 
        uint256 amount
    );

    /**
     * @dev modifier. checks whether method is called by sender or recipient.
     *
     * @param investId the invest id 
    */ 

    modifier onlySenderOrRecipient(uint256 investId) {
        require(
            msg.sender == invests[investId].sender || msg.sender == invests[investId].recipient,
            "caller is not the sender or the recipient of the invest"
        );
        _;
    }

    /**
     * @dev modifier. checks whether invest id exists.
     *
     * @param investId the invest id 
    */ 

    modifier investExists(uint256 investId) {
        require(invests[investId].isEntity, "invest id does not exist");
        _;
    }

    /**
     * @dev constructor takes no parameters.
     * sets the nextInvestId and iagon Token Address
     * Creates a vesting contract that vests its balance of Iagon ERC20 token to the
     * recipient, gradually as rate per month until start + interval. By then all
     * of the balance will have vested.
    */

    constructor() {
        nextInvestId = 1; 
        iagonTokenAddress = 0x06f7246f009F6f0372C481AD6cf60f3CDe31DCe2; // test token address(TT)
    }

    /**
     * @dev can view details of investing by its invest id.
     *
     * @param investId sender or recipient invest Id that to be viewed.
     *
     * Returns
     * - `sender` sender address.
     * - `recipient` recipient address.
     * - `deposit` amount of tokens that are locked.
     * - `tokenAddress` iagon token address.
     * - `startTime` timestamp from vesting will start.
     * - `stopTime` timestamp where vesting will stop.
     * - `remainingBalance` amount of tokens that are remaining in contract.
     * - `ratePerMonth` amount that will release per month.
    */

    function getInvestDetails(uint256 investId)
        external
        view
        investExists(investId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerMonth
        ){
        sender = invests[investId].sender;
        recipient = invests[investId].recipient;
        deposit = invests[investId].deposit;
        tokenAddress = invests[investId].tokenAddress;
        startTime = invests[investId].startTime;
        stopTime = invests[investId].stopTime;
        remainingBalance = invests[investId].remainingBalance;
        ratePerMonth = invests[investId].ratePerMonth;
    }

    /**
     * @dev investor investing tokens.
     * It locks the tokens for 3 months and start investing from starting of 4th month.
     * sender or recipient can start withdrawing tokens after every 30 or 31 alternative 
     * interval days of months.
     *
     * @param recipient address of the beneficiary to whom vested tokens are transferred.
     * @param deposit amount of Iagon token to be vest.
     *
     * Requirement
     * - deposit must be divisible by 9.
     *
     * Returns
     * - new invest ID.
     *
     * Emits a {CreateInvesting} event.
    */

    function investorInvestTokens(address recipient, uint256 deposit) 
        external
        nonReentrant
        returns(uint256){
            uint256 startTime = block.timestamp + 91 days;  // start time after 3 months from current time
            // for testing block.timestamp + 900 seconds where 5 min == 1 month
            uint256 stopTime = block.timestamp + 365 days;  // vesting ends after year from cuurent time
            // for testing block.timestamp + 3900 seconds where 5 min == 1 month

            require(recipient != address(0x00), "can not invest to the zero address");
            require(recipient != address(this), "can not invest to the contract itself");
            require(recipient != msg.sender, "can not invest to the caller");
            require(deposit > 0, "deposit is zero");
            require(startTime >= block.timestamp, "start time before block.timestamp");
            require(stopTime > startTime, "stop time before the start time");
            require(deposit % 9 == 0, "deposit cannot be proportionally divided");

            uint256 investId = nextInvestId;
            uint256 ratePerMonth = deposit / 9;  // release tokens per month. 
            invests[investId] = Types.Invest({
                remainingBalance: deposit,
                deposit: deposit,
                isEntity: true,
                ratePerMonth: ratePerMonth,
                recipient: recipient,
                sender: msg.sender,
                startTime: startTime,
                stopTime: stopTime,
                tokenAddress: iagonTokenAddress,
                releaseCounter: 0,
                timesInMonth: intervalTime,
                counterArray: countArray
            });

            nextInvestId = nextInvestId + 1;
            IERC20(iagonTokenAddress).transferFrom(msg.sender, address(this), deposit); // transfer tokens to recipient
            
            emit CreateInvesting(investId, msg.sender, recipient, deposit, iagonTokenAddress, startTime, stopTime);
            
            return investId;
    }

    /**
     * @dev advisor investing tokens.
     * It locks the tokens for 2 months and start investing from starting of 3rd month.
     * sender or recipient can start withdrawing tokens after every 30 or 31 alternative 
     * interval days of months.
     *
     * @param recipient address of the beneficiary to whom vested tokens are transferred.
     * @param deposit amount of Iagon token to be vest.
     *
     * Requirement
     * - deposit must be divisible by 10.
     *
     * Returns
     * - new invest ID.
     *
     * Emits a {CreateInvesting} event.
    */
    
    function advisorInvestTokens(address recipient, uint256 deposit) 
        external
        nonReentrant
        returns(uint256){
            uint256 startTime = block.timestamp + 60 seconds;  // start time after 2 months from current time
            // for testing block.timestamp + 600 seconds where 5 min == 1 month
            uint256 stopTime = block.timestamp + 3000;  // vesting ends after year from cuurent time
            // for testing block.timestamp + 3900 seconds where 5 min == 1 month

            require(recipient != address(0x00), "can not invest to the zero address");
            require(recipient != address(this), "can not invest to the contract itself");
            require(recipient != msg.sender, "can not invest to the caller");
            require(deposit > 0, "deposit is zero");
            require(startTime >= block.timestamp, "start time before block.timestamp");
            require(stopTime > startTime, "stop time before the start time");
            require(deposit % 10 == 0, "deposit cannot proportionally divided");

            uint256 investId = nextInvestId;
            uint256 ratePerMonth = deposit / 10;  // release tokens per month. 
            invests[investId] = Types.Invest({
                remainingBalance: deposit,
                deposit: deposit,
                isEntity: true,
                ratePerMonth: ratePerMonth,
                recipient: recipient,
                sender: msg.sender,
                startTime: startTime,
                stopTime: stopTime,
                tokenAddress: iagonTokenAddress,
                releaseCounter: 0,
                timesInMonth: intervalTime,
                counterArray: countArray
            });

            nextInvestId = nextInvestId + 1;
            IERC20(iagonTokenAddress).transferFrom(msg.sender, address(this), deposit); // transfer tokens to recipient
            
            emit CreateInvesting(investId, msg.sender, recipient, deposit, iagonTokenAddress, startTime, stopTime);
            
            return investId;
    }

    /**
     * @dev withdraw investing tokens.
     * sender or recipient can start withdrawing tokens after every 30 or 31 alternative 
     * interval days of months.
     *
     * @param investId invest Id.
     *
     * Requirement
     * - caller must be sender or recipient.
     *
     * Returns
     * - boolean.
     *
     * Emits a {WithdrawFromInvesting} event.
    */

    function withdrawTokens(uint256 investId)
        external
        nonReentrant
        investExists(investId)
        onlySenderOrRecipient(investId)
        returns (bool){
            int256 timeDiff = int(block.timestamp - invests[investId].startTime);
            require(timeDiff > 0, "tokens are not released yet");

            uint256 percent = invests[investId].ratePerMonth;
            uint256 duration = block.timestamp - invests[investId].startTime;

            uint256 releaseAmount = 0;
            uint256 i;

            if(block.timestamp >= invests[investId].stopTime){  // current time is passed the stop time
                
                releaseAmount = invests[investId].remainingBalance;
                IERC20(invests[investId].tokenAddress).safeTransfer(invests[investId].recipient, releaseAmount); 
                
                delete invests[investId];
                emit WithdrawFromInvesting(investId, invests[investId].recipient, releaseAmount);

                return true;
            }
            for(i = 0; i < 10; i++){
                uint nextCount = i + 1;
                // checks the interval of time and releases amount accordingly
                if(invests[investId].timesInMonth[i] <= duration && invests[investId].timesInMonth[nextCount] >= duration){
                    
                    uint256 counter = invests[investId].counterArray[i];
                    counter = counter - invests[investId].releaseCounter;
                    releaseAmount = percent * counter;

                    require(releaseAmount > 0, 'amount is already withdrawn');

                    invests[investId].remainingBalance = invests[investId].remainingBalance - releaseAmount;
                    invests[investId].releaseCounter = invests[investId].releaseCounter + counter;

                    if (invests[investId].remainingBalance == 0) delete invests[investId];

                    IERC20(invests[investId].tokenAddress).safeTransfer(invests[investId].recipient, releaseAmount);
                    emit WithdrawFromInvesting(investId, invests[investId].recipient, releaseAmount);

                    return true;
                }
            }
            require(releaseAmount > 0, 'release Amount is zero');
           
            emit WithdrawFromInvesting(investId, invests[investId].recipient, releaseAmount);

            return false;
    }

    function getBalance(uint256 investId)
        external
        view
        investExists(investId)
        returns (uint256){
            uint256 percent = invests[investId].ratePerMonth;
            uint256 duration = block.timestamp - invests[investId].startTime;

            uint256 releaseAmount = 0;
            uint256 i;

            if(block.timestamp >= invests[investId].stopTime){  // current time is passed the stop time
                return invests[investId].remainingBalance;
            }
            for(i = 0; i < 10; i++){
                uint nextCount = i + 1;
                // checks the interval of time and releases amount accordingly
                if(invests[investId].timesInMonth[i] <= duration && invests[investId].timesInMonth[nextCount] >= duration){
                    uint256 counter = invests[investId].counterArray[i];
                    counter = counter - invests[investId].releaseCounter;

                    releaseAmount = percent * counter;
                    return releaseAmount;
                }
            }
            return releaseAmount;
        }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}