// SPDX-License-Identifier: MIT

/* ________  ________  ________ _________  ________   ________  
 *|\   ____\|\   __  \|\   ____\\___   ___\\_____  \ |\_____  \ 
 *\ \  \___|\ \  \|\  \ \  \___\|___ \  \_\|____|\ /_ \|___/  /|
 * \ \_____  \ \  \\\  \ \  \       \ \  \  |\____\  \    /  / /
 *  \|____|\  \ \  \\\  \ \  \____   \ \  \  \|___|\  \  /  / / 
 *    ____\_\  \ \_______\ \_______\  \ \__\  |\_______\/__/ /  
 *   |\_________\|_______|\|_______|   \|__|  \|_______||__|/   
 *   \|_________|                                                                                                                         
 */

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.4;

    // Charities Contract test Version 28 for the SOCT37 token. Only for testing purposes on the BSC testnet

   /* IMPORTANT: This Charities Contract do not trade SOCT37 tokens for BNB by itself every X minutes because solidity smart contracts do not contain automated functions.
    * What it does is to allow an external automated system(EAS) that can always provide the credentials of the Contract Owner to be the one in charge
    * to check with method _checkIfReadyToSwap every X minutes the number of SOCT37 tokens in this Contract and decide if there's enough to trade. If not, it will comeback every 10 minutes to check again.
    * If there is enough SOCT37 to trade, then the EAS calls another method in the CC, swapTokensForBNB, and the EAS is in charge to decide how much SOCT37 will be traded.
    * The _checkIfReadyToSwap method doesn't contain an IF statement to trade or not within the same method because every call to that kind of function would cost GAS even if the trading is not done.
    * That is why there are 2 independent methods in this Contract: 1 that checks the funds (_checkIfReadyToSwap), 1 that allows the trade (swapTokensForBNB).
    * The EAS keeps a database of total quantity of SOCT37 on this contract and how it changes on each call, and by analyzing this data ONLY the EAS will decide if its worth or not
    * to reduce or increase the periodicity of trades and amount of SOCT37 to be traded for BNB. BUT to prevent exploits this Contract will NEVER allow to trade SOCT37
    * worth more than 0.5 BNB on each transaction and/or in a periodicity less than every 5 minutes.
    * It is important to understand that for security reasons the location of this External Automated System will not be disclosed.
    */
import '@openzeppelin/contracts/utils/math/SafeMath.sol';    
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './libs/pancakePair.sol';
import './libs/IPancakeRouter01.sol';
import './libs/IPancakeRouter02.sol';


contract SOCTCharitiesContractV28 is Context, Ownable {
    using SafeMath for uint256;
	using Address for address;
    address payable public charityAddress; // The charity address is the only one allowed to be payable to ensure funds won't be used for anything else
    address private previousCharityAddress; // It will never be allowed to send funds twice in a row to same Nonprofit
    string public charityName;
    uint256 public totalFunds;
    uint256 public totalBNBdonated;
    bool ended;
    uint256 public expiration;
    uint256 public duration = 20 minutes; //20 minutes is for testing purposes only
    uint256 optionA = 7 days;
    uint256 optionB = 2 weeks;
    uint256 optionC = 4 weeks;
    uint256 lastSwap;
    IPancakeRouter02 public pancakeRouter;
    address private Pancake_Router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // Router on TestNet
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private testToken = 0x05d9C586b66507Ae3c26D2B1d3025E59C282a95f; // actual address of last test token (SOCT37)
    address private LPpairAddress = 0xE7e82B259aaD65684f2D2bbAAfa327d8BDAAfaf4; // the Liquidity Pool contract presented on the BSC testNet Pancake Swap dummy DEX
    
    //event emitted on changes
    event fundsTransfered(string name, address charity, uint256 amount, uint256 date);

    constructor () {
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(Pancake_Router);
        pancakeRouter = _pancakeRouter;
        expiration = block.timestamp + duration;
    }
    
    function _restartCountdown() public onlyOwner() {
        require(block.timestamp >= expiration, "Charity countdown time hasn't expired yet.");
        require(!ended, "Countdown has not ended.");
        ended = false;
        expiration = block.timestamp + duration;
        charityAddress == deadAddress;
        charityName = 'No Charity Selected';
    }
    
    function getSOCTFundsOnContract() public view returns (uint256 totalSOCT) {
        IERC20 SOCT = IERC20(testToken);
        totalSOCT = SOCT.balanceOf(address(this)).div(10**8);
        return totalSOCT;
    }
    
    function getBNBFundsOnContract() public view returns (uint256 totalBNB) {
        totalBNB = address(this).balance.div(10**18);
        return totalBNB;
    }
    
    function gettotalBNBdonated() public view returns (uint256 totalBNB) {
        return totalBNBdonated;
    }

    function getExpiration() public view returns (uint256 Expiration) {
        return expiration;
    }
    
    function getDuration() public view returns (uint256 Duration) {
        return duration;
    }
    
    function getCurrentCharity() public view returns (string memory theCharityName, address theCharityAddress) {
         return (charityName, charityAddress);
    }

    function _setCharity(address charityOwnAddress, string memory foundationName) public onlyOwner() {
        charityAddress = payable(charityOwnAddress);
        charityName = foundationName;
    }

    function _resetCharity() public onlyOwner() {
        charityAddress == deadAddress;
        charityName = 'No Charity Selected';
    }
    
    // this function is important to be able to update LP address if Pancake updates to a newer version
    function _setPancakeSwapLPContractAddress(address newPancakeLP, address newPancakeRouter) public onlyOwner() {
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(newPancakeRouter);
        pancakeRouter = _pancakeRouter;
        LPpairAddress = newPancakeLP;
    }
    
    function getPancakeLP() public view returns (address pancakeLP) {
        pancakeLP = LPpairAddress;
    }
   
    // There is only 3 options available for the perodicity of each cyle the Charities Contract
    // sends the funds to Nonprofits: 1 = 7 days, 2 = 2 weeks, 3 = 1 month
    function _setTime(uint256 option) public onlyOwner() {
        require(option == 1 || option == 2 || option == 3, 'Options available are only 1, 2 or 3');
        if(option == 1){
            duration = optionA;
        } else if(option == 2){
            duration = optionB;
        } else{
            duration = optionC;
        }
    }
    
    function getTime() public view returns (uint256 time) {
        time = duration;
    }
    
    // Next 2 methods are only for testing purposes and should not exist on final Charities Contract on BSC MainNet
    
    function _setTestTime(uint256 NumberofMinutes) public onlyOwner() {
        duration = NumberofMinutes * 1 minutes;
    }
    
    function _set3Minutes() public onlyOwner() {
        duration = 3 minutes;
    }
    
    // to be able to receive BNB
    receive() external payable {}

    // This is to rescue any BEP-20 token sent into the contract. Does not allow to rescue any SOCT or BNB
    function _adminRescueTokens(address token, uint256 amount) public onlyOwner() {
        require(token != pancakeRouter.WETH() || token != address(testToken), 'Cannot withdraw any BNB or SOCT');
        IERC20(token).transfer(msg.sender, amount);
    }
    
    // Main function called from the External Automated System
    function _checkIfReadyToSwap() public view returns (uint256 minToSellinSOCT, uint256 tFundsInBNB) {
        IERC20 SOCT37 = IERC20(testToken);
        pancakePair pair = pancakePair(LPpairAddress);
        (uint256 soct, uint256 bnb,) = pair.getReserves();
        uint256 SOCTnoD = soct.div(10**8);
        uint256 pE = bnb.mul(10**18).div(SOCTnoD);
        uint256 priceEst = pE.div(10**18);

        uint256 SOCTFunds = SOCT37.balanceOf(address(this));
        uint256 FundsInBNB = priceEst.mul(SOCTFunds.div(10**8));
        uint256 B = SOCTnoD.div(bnb);
        uint256 MinToSell = B.div(10); // 0.1BNB
        return (MinToSell, FundsInBNB / 10**15); // FundsInBNB returns only 3 digits after floating point  
    }

    function _getHalfBNB() private view returns (uint256 HBNB) {
        pancakePair pair = pancakePair(LPpairAddress);
        (uint256 soct, uint256 bnb,) = pair.getReserves();
        uint256 SOCTnoD = soct.div(10**8);
        uint256 hB = SOCTnoD.div(bnb);
        uint256 halfBNBestPrice = hB.div(2) + hB.div(20); // 0.55BNB
        return halfBNBestPrice;
    }
    
    function swapTokensForBNB(uint256 tokenAmount) public onlyOwner() returns (uint256 time, uint256 totalSwapped) {
        require(block.timestamp > lastSwap, 'cannot swap twice in less than 5 minutes');
        uint256 halfBNBEstP = _getHalfBNB();
        require(tokenAmount <= halfBNBEstP, 'cannot swap more than half BNB');
        address[] memory path = new address[](2);
        path[0] = testToken;
        path[1] = pancakeRouter.WETH();
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
        lastSwap = block.timestamp + 5 minutes;
        return (block.timestamp, tokenAmount);
    }
   
    // This method sends the total amount of BNB raised to 1 charity address
    // ONLY if 1. countdown time is zero
    // 2. there is a charity address selected
    // 3. the charity address is not the same as previous charity address to ensure fair distribution of funds
    function _sendCharityFunds() public onlyOwner() {
        //Conditions
        require(block.timestamp >= expiration, 'Charity countdown time has not expired yet');
        require(charityAddress != previousCharityAddress, 'Cannot send funds to same charity twice in a row');
        require(!ended, 'sendCharityFunds has already been called');
        require(charityAddress != deadAddress, 'There is no charity set to send funds to');        

        //Effects
        ended = true;
        previousCharityAddress = charityAddress;
        totalBNBdonated = totalBNBdonated + address(this).balance;
        emit fundsTransfered(charityName, charityAddress, address(this).balance, block.timestamp);
        
        //Interaction
        charityAddress.transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
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

pragma solidity ^0.8.4;

interface pancakePair {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);
	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);
	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
	event Mint(address indexed sender, uint amount0, uint amount1);
	event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
	event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);
	function MINIMUM_LIQUIDITY() external pure returns (uint);
	function factory() external view returns (address);
	function token0() external view returns (address);
	function token1() external view returns (address);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function price0CumulativeLast() external view returns (uint);
	function price1CumulativeLast() external view returns (uint);
	function kLast() external view returns (uint);
	function mint(address to) external returns (uint liquidity);
	function burn(address to) external returns (uint amount0, uint amount1);
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
	function skim(address to) external;
	function sync() external;
	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPancakeRouter01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);
	function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountToken, uint amountETH);
	function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountToken, uint amountETH);
	function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountETH);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
	) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
}