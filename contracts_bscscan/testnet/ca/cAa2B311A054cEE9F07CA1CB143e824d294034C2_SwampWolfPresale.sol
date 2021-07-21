/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT

/*
________________________________________________________
                         INFO:                          |
________________________________________________________|
This contract is published by RISING CORPORATION for    |
the DarkAgeOfBeast network ( DAOB ) on BSC.             |
Name : SwampWolfPresale                                 |
Token link: SWAMPWOLF                                   |
Solidity: 0.8.6                                         |
--------------------------------------------------------|
                  WEBSITE AND SOCIAL:                   |
________________________________________________________|
website :   https://wolfswamp.daob.finance/             |
Twitter :   https://twitter.com/DarkAgeOfBeast          |
Medium  :   https://medium.com/@daob.wolfswamp          |
Reddit  :   https://www.reddit.com/r/DarkAgeOfTheBeast/ |
TG_off  :   https://t.me/DarkAgeOfBeastOfficial         |
TG_chat :   https://t.me/Darkageofbeast                 |
________________________________________________________|
                 SECURITY AND FEATURES:                 |
________________________________________________________|
The owner can use certain functions.                    |
All sensitive functions are limited.                    |
Can not be used without the SwampWolfReferral contract. |
The total amount to be sold is 100% + X% for referrers. |
            !  THERE ARE NO HIDDEN FEES  !              |
________________________________________________________|
            Creative Commons (CC) license:              |
________________________________________________________|
You can reuse this contract by mentioning at the top :  |
    https://creativecommons.org/licenses/by-sa/4.0/     |
        CC BY MrRise from RisingCorporation.            |
________________________________________________________|

Thanks !
Best Regards !
by MrRise
2021-07-21
*/

pragma solidity >=0.6.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b);
        // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


pragma solidity 0.8.6;

abstract contract Ownable {
    address payable owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity 0.8.6;

contract Whitelisted is Ownable {
    mapping(address => uint8) public whitelist;

    // Only whitelisted
    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }
    // Set purchaser to whitelist with zone code
    function joinWhitelist(address _purchaser, uint8 _zone) public {
        whitelist[_purchaser] = _zone;
    }
    // Delete purchaser from whitelist
    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = 0;
    }
    // Check if purchaser is whitelisted : return true or false
    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
     * - the calling contract must have an BNB balance of at least `value`.
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/libs/IBEP20.sol

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity 0.8.6;

interface ISwampWolfToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function burnUnsoldPresale(uint256 amount) external;
}

pragma solidity 0.8.6;

interface ISwampWolfReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

pragma solidity 0.8.6;

contract SwampWolfPresale is Ownable, Whitelisted {

    using SafeMath for uint256;
    using SafeMath for uint16;

    // The start time of presale.
    uint256 public startTime;
    // The end time of presale.
    uint256 public endTime;
    // The list of buyers.
    mapping(address => uint256) public BuyerList;
    // Maximum purchase per buyer ( 10 BNB ).
    uint256 public MAX_BUY_LIMIT = 10000000000000000001;
    // The referral commission rate in basis points.
    uint16 public referralReward = 300;
    // The Rate of SWAMPWOLF token by BNB ( 2430 SWAMPWOLF / 1 BNB )
    uint256 public rate = 243e1;
    // The BNB raised in wei.
    uint256 public weiRaised;
    // The SwampWolfToken contract.
    ISwampWolfToken public swampWolfToken;
    // The SwampWolfReferral contract.
    ISwampWolfReferral public swampWolfReferral;
    // if presale is stopped.
    bool public isPresaleStopped = false;
    // if presale is paused.
    bool public isPresalePaused = false;

    //event
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transferred(address indexed purchaser, address indexed referral, uint256 amount);


    constructor(
        ISwampWolfToken _swampWolf,
        ISwampWolfReferral _referral,
        uint256 _startTime,
        uint256 _endTime
    ) {
        swampWolfToken = _swampWolf;
        swampWolfReferral = _referral;
        startTime = _startTime;
        endTime = _endTime;
        require(endTime >= startTime);
    }

    /**
     * @dev fallback function to prevent mistake.
     *
     */
    fallback() external payable {
        buy(msg.sender, owner);
    }

    /**
     * @dev To receive BNB for presale
     *
     */
    receive() external payable {}


    /**
     * @dev The Buy tokens function.
     *
     * Requirements
     *
     * Buyer must be whitelisted.
     */
    function buy(address _beneficiary, address _referrer) public onlyWhitelisted payable {
        require(isPresaleStopped != true, 'Presale is stopped');
        require(isPresalePaused != true, 'Presale is paused');
        require(_beneficiary != address(0), 'User asking for tokens sent to be on 0 address');
        require(validPurchase(), 'Its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        // The BNB amount sent by the buyer
        uint256 weiAmount = msg.value;
        require(weiAmount < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT is 10 BNB');
        // Calc how many SWAMPWOLF this makes
        uint256 tokens = weiAmount.mul(rate);
        // Calc the referrer reward
        uint256 refReward = tokens.mul(referralReward).div(10000);
        weiRaised = weiRaised.add(weiAmount);
        uint256 remainingTokens = tokensRemainingForSale();
        uint256 tokensNeeded = tokens.add(refReward);
        require(tokensNeeded <= remainingTokens, 'Not enough tokens');
        require(address(swampWolfReferral) != address(0), 'Need referral contract' );
        require(_referrer != address(0), 'Referrer can not be zero address');
        require(_referrer != _beneficiary, 'Referrer can not be beneficiary');
        swampWolfReferral.recordReferral(_beneficiary, _referrer);
        address referrer = swampWolfReferral.getReferrer(_beneficiary);
        payReferral(referrer, refReward);
        swampWolfToken.transfer(_beneficiary, tokens);
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    /**
     * @dev Pay the referral commission to the referrer
     *
     */
    function payReferral(address _referrer, uint256 _amount) internal {
        swampWolfToken.transfer(_referrer, _amount);
        swampWolfReferral.recordReferralCommission(_referrer,_amount);


    }

    /**
    * @dev Check is the purchase is valid
    *
    * Internal purpose
    */
    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
    * @dev Check is the presale has ended
    *
    */
    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    /**
    * @dev Display the current balance of `msg.sender`
    *
    */
    function showMyTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = swampWolfToken.balanceOf(msg.sender);
    }

    /**
    * @dev Set the end date of presale
    *
    */
    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns (bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = block.timestamp + daysToEndFromToday;
        return true;
    }

    /**
    * @dev Set the SWAMPWOLF/BNB price rate
    *
    * Requirement
    *
    * Can only be called by the owner
    */
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
        return true;
    }

    /**
    * @dev Set the referral reward rate in basis points
    *
    * Requirements
    *
    * Can only be called by the owner.
    */
    function setReferralReward(uint16 newReward) public onlyOwner returns (bool) {
        referralReward = newReward;
        return true;
    }

    /**
    * @dev Pause the presale
    *
    * Requirements
    *
    * Can only be called by the owner.
    */
    function pausePresale() public onlyOwner returns (bool) {
        isPresalePaused = true;
        return isPresalePaused;
    }

    /**
    * @dev Resume the presale
    *
    * Requirements
    *
    * Can only be called by the owner.
    */
    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }

    /**
    * @dev Stop the presale
    *
    * Requirements
    *
    * Can only be called by the owner.
    */
    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    /**
    * @dev Start the presale
    *
    * Requirements
    *
    * Can only be called by the owner.
    */
    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp;
        return true;
    }

    /**
     * @dev Burn unsold tokens after presale.
     *
     * Requirements
     *
     * Can only be called by the owner.
     * Presale must be ended.
     */
    function burnUnsoldTokens() public onlyOwner {
        require(hasEnded(), 'Presale not ended');
        uint256 unsold = swampWolfToken.balanceOf(address(this));
        swampWolfToken.burnUnsoldPresale(unsold);
    }

    /**
     * @dev Transfers BNB from the presale to `msg.sender` to put them in liquidity.
     *
     * Requirements
     *
     * Can only be called by the owner.
     */
    function transferPresaleBNB() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    /**
     * @dev Transfer `_token` to `msg.sender`.
     *
     * Requirements
     *
     * Can only be called by the owner.
     * Ensure requested tokens aren't SWAMPWOLF tokens.
     */
    function recoverLostTokensExceptOurTokens(address _token) public onlyOwner {
        require(_token != address(swampWolfToken), "Cannot recover SWAMPWOLF tokens");
        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(msg.sender, amount);
    }

    /**
     * @dev Check how many SWAMPWOLF tokens remaining for sale.
     *
     */
    function tokensRemainingForSale() public view returns (uint256 balance) {
        uint256 tokenBalance = swampWolfToken.balanceOf(address(this));
        // The total current balance is 100% + 3% for referral
        uint256 totalBP = referralReward.add(10000);
        uint256 rewardBalance = tokenBalance.div(totalBP).mul(referralReward);
        balance = tokenBalance.sub(rewardBalance);
    }
}