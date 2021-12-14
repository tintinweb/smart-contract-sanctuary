/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

interface IStakingHelper {
    function stakedAccounts(uint256 _index) external view returns(address);
    function getStakedLength() external view returns (uint256);
    function stakedTime(address _account) external view returns(uint256);
}

interface ITSUKI {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

contract TreasuryReward is Ownable {

    using SafeMath for uint256;

    IStakingHelper public stakingHelper;
    IRandomNumberGenerator public randomMaker;
    ITSUKI public tsuki;


    uint256 public DAY2SEC = 900;
    uint256 public MAX_LUCKY_COUNTS = 3;
    uint256 public LaunchTime;
    uint256 public MintPeriod;
    uint256 public RedeemPeriod;

    uint256 public minimumTsukiAmount;
    uint256 public participants;

    address[] public whiteAccounts;
    address[] public luckyAccounts;
    
    constructor(address _stakingHelper, address _random, address _tsuki) {
        stakingHelper = IStakingHelper(_stakingHelper);
        randomMaker = IRandomNumberGenerator(_random);
        tsuki = ITSUKI(_tsuki);
        LaunchTime = 1638987514;
        MintPeriod = 240;
        RedeemPeriod = 480;
        minimumTsukiAmount = 1;
    }

    function GetWhiteAccounts() public onlyOwner {
       uint256 len = IStakingHelper( stakingHelper ).getStakedLength();
       if(whiteAccounts.length != 0)
        resetWhiteAccounts();
       uint256 k = 0;
       for(k = 0; k < len; k++) {
           address tempAccount = IStakingHelper( stakingHelper ).stakedAccounts(k);
            if(isWhiteListed(tempAccount)) {
                whiteAccounts.push(tempAccount);
            }
       }
       participants = whiteAccounts.length;
    }

    function VoteLuckyAccount() public {
        require(block.timestamp > LaunchTime + RedeemPeriod * DAY2SEC, "Not yet finished the minting");
        require(participants > 0, "White lists can't be zero");
        require(isWhiteListed(msg.sender), "msg.sender is not white listed");

        if(participants > MAX_LUCKY_COUNTS) {
            require(luckyAccounts.length < MAX_LUCKY_COUNTS, "Account is fulfilled");

            uint256 seed = uint256(blockhash(block.number - 1));
            randomMaker.getRandomNumber(seed);
            uint256 oneRand = randomMaker.viewRandomResult();
            address tempAccount = whiteAccounts[oneRand % participants];
            for(uint k = 0; k < luckyAccounts.length; k++) {
                if(tempAccount == luckyAccounts[k])
                    return;
            }
            luckyAccounts.push(tempAccount);
        } else {
            for(uint256 k = 0; k< participants; k++) {
                luckyAccounts.push(whiteAccounts[k]);
            }
        }
    }

    function getLuckyAccountLength() public view returns(uint256) {
        return luckyAccounts.length;
    }

    function getLuckyAccounts() public view returns(address [] memory) {
        return luckyAccounts;
    }
    
    function isWhiteListed(address account) public view returns(bool) {
        require(account != address(0), "account is zero address");

        uint256 stakedTime = IStakingHelper( stakingHelper ).stakedTime(account);
        bool isWhite = false;
        if(stakedTime > LaunchTime && stakedTime < LaunchTime + RedeemPeriod * DAY2SEC) {
            if(ITSUKI(tsuki).balanceOf(account) > minimumTsukiAmount) {
                isWhite = true; 
            }
        }
        return isWhite;
    }

    function isLive() public view returns(bool) {
        bool bLive;
        if(block.timestamp > LaunchTime + RedeemPeriod * DAY2SEC && luckyAccounts.length < MAX_LUCKY_COUNTS)
            bLive = true;
        return bLive;
    }

    function resetWhiteAccounts() internal {
        require(whiteAccounts.length > 0, "Passed Accounts lengh is zero");

        uint256 len = whiteAccounts.length;
        uint256 k = 0;
        for(k = 0; k < len; k++) {
            whiteAccounts.pop();
        }
    }

    function ResetLuckyAccounts() public onlyOwner {
        require(luckyAccounts.length >= MAX_LUCKY_COUNTS, "LuckyAccounts is not fulfilled");
        uint k = 0;
        for(k = 0; k < MAX_LUCKY_COUNTS; k++) 
            luckyAccounts.pop();
    }

    function updateStakingHelper(address _stakingAddr) public onlyOwner {
        require(_stakingAddr != address(0), "Staking Address can't be zero address");

        stakingHelper = IStakingHelper(_stakingAddr);
    }

    function updateLaunchTime(uint256 _newLaunchTime) public onlyOwner {
        require(_newLaunchTime > 0, "New time can't be zero");
        
        LaunchTime = _newLaunchTime;
    }

    function updateRedeemPeriod(uint256 _newRedeemPeriod) public onlyOwner {
        require(_newRedeemPeriod > 0, "New time can't be zero");

        RedeemPeriod = _newRedeemPeriod;
    }
    
    function updateMintPeriod(uint256 _newMintPeriod) public onlyOwner {
        require(_newMintPeriod > 0, "New time can't be zero");

        MintPeriod = _newMintPeriod;
    }

    function updateDay(uint256 _newDay2SEC) public onlyOwner {
        require(_newDay2SEC > 0, "New day can't be zero");
        
        DAY2SEC = _newDay2SEC;
    }

    function updateMaxLuckyCounts(uint256 _newMax) public onlyOwner {
        require(_newMax > 0, "New Max can't be zero");
        
        MAX_LUCKY_COUNTS = _newMax;
    }

    function updateTsukiMinimum(uint256 _newMini) public onlyOwner {
        require(_newMini > 0, "New Mini amount can't be zero");
        
        minimumTsukiAmount = _newMini;
    }

    function withDrawToken(address token, uint256 amount) public onlyOwner {
        require(token != address(0), "Token address can't be zero address");
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "Amount can't exceed the contract balance");
        IERC20(token).transfer(msg.sender, amount);
    }
}