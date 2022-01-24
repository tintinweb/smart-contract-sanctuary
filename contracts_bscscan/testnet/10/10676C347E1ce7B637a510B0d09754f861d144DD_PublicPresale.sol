/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library Address {

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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

  
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Crowdsale is Context, ReentrancyGuard, Ownable {
    // The token being sold
    IERC20 public token;

    // Address where funds are collected
    address public wallet;

    uint public numerator;
    uint public denominator;

    uint public bnbRaised;

    mapping(address => uint) public purchasedAmount;
    mapping(address => uint) public claimedAmount;

    event TokenPurchased(address indexed user, uint value);
    event TokenClaimed(address indexed user, uint value);

    constructor(uint numerator_, uint denominator_, address wallet_, IERC20 token_) {
        setParameters(numerator_, denominator_, wallet_, token_);
    }

    function setParameters(uint numerator_, uint denominator_, address wallet_, IERC20 token_) public onlyOwner {
        require(numerator_ > 0 && denominator_ > 0, "Crowdsale: rate is 0");
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        numerator = numerator_;
        denominator = denominator_;
        wallet = wallet_;
        token = token_;
    }

    function setToken(IERC20 token_) external onlyOwner {
        require(address(token_) != address(0), "Crowdsale: token is the zero address");
        token = token_;
    }

    function getTokenAmount(uint amount) public view returns (uint) {
        return amount * numerator / denominator;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }
}

// abstract contract TimedCrowdsale is Crowdsale {
//     uint public openingTime;
//     uint public closingTime;

   
//     event TimedCrowdsaleExtended(uint prevClosingTime, uint newClosingTime);

//     modifier onlyWhileOpen {
//         require(isOpen(), "TimedCrowdsale: not open");
//         _;
//     }

//     constructor (uint openingTime_, uint closingTime_) {
//         // solhint-disable-next-line not-rely-on-time
//         require(openingTime_ >= block.timestamp, "TimedCrowdsale: opening time is before current time");
//         // solhint-disable-next-line max-line-length
//         require(closingTime_ > openingTime_, "TimedCrowdsale: opening time is not before closing time");

//         openingTime = openingTime_;
//         closingTime = closingTime_;
//     }

//     function isOpen() public view returns (bool) {
//         // solhint-disable-next-line not-rely-on-time
//         return block.timestamp >= openingTime && block.timestamp <= closingTime;
//     }

//     function hasClosed() public view returns (bool) {
//         // solhint-disable-next-line not-rely-on-time
//         return block.timestamp > closingTime;
//     }

//     function extendTime(uint newClosingTime) external onlyOwner {
//         require(!hasClosed(), "TimedCrowdsale: already closed");
//         // solhint-disable-next-line max-line-length
//         require(newClosingTime > closingTime, "TimedCrowdsale: new closing time is before current closing time");

//         emit TimedCrowdsaleExtended(closingTime, newClosingTime);
//         closingTime = newClosingTime;
//     }

    
// }

contract PublicPresale is Crowdsale {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint public hardCap;
    uint public allocationCap;
    uint public minPresaleAmount;

    uint public openingTime;
    uint public closingTime;
    bool public claimOpen;
    uint public phaseLength = 1 hours; //10 days

    modifier onlyWhileOpen {
        require(!claimOpen, "Presale is ended");
        require(isOpen(), "Presale is not open");
        _;
    }

    constructor(uint allocationCap_, uint hardCap_, uint numerator_, uint denominator_, address token_, uint openingTime_)
    Crowdsale(numerator_, denominator_, address(this), IERC20(token_)) {
        allocationCap = allocationCap_;
        hardCap = hardCap_;
        openingTime = openingTime_;
        closingTime = openingTime_.add(uint(1814400)); // 21 days
        claimOpen = false;
        minPresaleAmount = 2 * 10 ** 17; //0.2 BNB
    }

    function getPurchasableAmount(address wallet, uint amount) public view returns (uint) {
        if (purchasedAmount[wallet] > allocationCap)
            return 0;

        amount = (amount + bnbRaised) > hardCap ? (hardCap - bnbRaised) : amount;
        return amount - purchasedAmount[wallet];
    }

    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= openingTime && block.timestamp <= closingTime;
    }

    function setCap(uint hardCap_, uint allocationCap_) external onlyOwner {
        hardCap = hardCap_;
        allocationCap = allocationCap_;
    }

    function openClaim() external onlyOwner {
        claimOpen = true;
    }

    function closeClaim() external onlyOwner {
        claimOpen = false;
    }

    function depositTokens(uint amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, wallet, amount);
    }

    function percentVested() public view returns ( uint percentVested_ ) {
        uint phaseCompleted = (block.timestamp.sub(closingTime)).div(phaseLength);

        if ( phaseCompleted <= 10 ) {
            percentVested_ = phaseLength.mul(10);
        } else {
            percentVested_ = 100;
        }
    }

    function claimableAmount( address _depositor ) public view returns ( uint pendingPayout_ ) {
        uint percentageVested = percentVested();
        uint payout_ = purchasedAmount[_depositor].mul( percentageVested ).div( 100 );
        uint tokenAmount = getTokenAmount(payout_);
        pendingPayout_ = tokenAmount.sub(claimedAmount[_depositor]);

        return pendingPayout_;
        
    }


    function buyTokens() external payable onlyWhileOpen {
        uint256 amount = msg.value;
        require(amount >= minPresaleAmount, "Presale Alert: Purchase amount less than min amount");
        amount = getPurchasableAmount(msg.sender, amount);

        require(amount > 0, "Presale Alert: Purchase amount is 0.");
        require(purchasedAmount[msg.sender] + amount <= allocationCap, "Presale Alert: Purchase amount is above cap.");

        bnbRaised += amount;
        if(bnbRaised >= hardCap) {
            claimOpen = true;
            closingTime = block.timestamp;
        }
        purchasedAmount[msg.sender] += amount;

        emit TokenPurchased(msg.sender, amount);
    }

    function claim() external nonReentrant {
        require(claimOpen, "The claim hasn't been opened yet.");
        uint purchaseAmount = purchasedAmount[msg.sender];
        require(purchaseAmount > 0, "Presale Alert: Address was not a participant.");

        uint claimable = claimableAmount(msg.sender);
        require(claimable > 0, "Presale Alert: No claimable token.");

        require(address(token) != address(0), "Presale Alert: Token hasn't been set yet.");
        claimedAmount[msg.sender] = claimedAmount[msg.sender].add(claimable);
        token.safeTransfer(msg.sender, claimable);

        emit TokenClaimed(msg.sender, claimable);
    }
}