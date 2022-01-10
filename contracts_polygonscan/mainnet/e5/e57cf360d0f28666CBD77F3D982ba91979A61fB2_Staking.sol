// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/* DESCRIPTION
- Users can deposit approved tokens into the contract, such as fake BTC/ETH/DAI ERC20 tokens into the contract
- owner can issue staking rewards to be paid for in wei. 1 wei for each usd value of the tokens staked 
- users can stake and unstake at any time
*/

contract Staking is Ownable {
    using Address for address payable;

    // TODO: IERC20 => balance. balance of each token so that TVL can be calculated in frontend
    mapping(IERC20 => mapping(address => uint256)) public stakingBalances; // ?: token to user to balance
    mapping(address => uint256) public uniqueTokensStaked; // ?: user address => num of unique tokens
    mapping(IERC20 => address) public tokenPriceFeed; // ?: if a token addresses with price feeds are allowed tokens
    address[] public stakers; // ?: each staker needs to have at least 1 token staked. pop() address from array once a user unstakes all of his tokens
    IERC20[] public allowedTokens;

    // constructor() {}

    function numberOfStakers() public view returns (uint256) {
        return stakers.length;
    }

    function numberOfAllowedTokens() public view returns (uint256) {
        return allowedTokens.length;
    }

    function isTokenAllowed(IERC20 _tokenAddress) public view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (_tokenAddress == allowedTokens[i]) return true;
        }
        return false;
    }

    modifier tokenIsAllowed(IERC20 _tokenAddress) {
        require(isTokenAllowed(_tokenAddress), "Token is not allowed");
        _;
    }

    function getStakerIndex(address _client) public view returns (int256) {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == _client) return int256(i); // ?: return the index if _client is a staker
        }

        return -1; // ?: return -1 if _client is not a staker
    }

    event StakeTokens(IERC20 tokenAddress, address staker);
    // !: approval needs to be done before this function is called
    function stakeTokens(IERC20 _tokenAddress, uint256 _amount) public tokenIsAllowed(_tokenAddress) {
        require(_amount > 0, "Staking amount must be greater than 0");
        // ?: allowance check is done in the transferFrom function
        IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);

        // ?: if msg.sender is not already a staker, add him to stakers[] and set uniqueTokensStaked to 1 since it's his first token
        if (getStakerIndex(_msgSender()) == -1) {
            stakers.push(_msgSender());
        }

        // ?: if you have no _tokenAddress staked, increase uniqueTokensStaked by 1.
        if (stakingBalances[_tokenAddress][_msgSender()] == 0) {
            uniqueTokensStaked[_msgSender()] += 1;
        }

        stakingBalances[_tokenAddress][_msgSender()] += _amount;
        emit StakeTokens(_tokenAddress, _msgSender());
    }

    event UnstakeTokens(IERC20 tokenAddress, address unstaker);
    function unstakeTokens(IERC20 _tokenAddress, uint256 _amount) public tokenIsAllowed(_tokenAddress) {
        require(_amount > 0, "Staking amount must be greater than 0");
        require(stakingBalances[_tokenAddress][_msgSender()] >= _amount, "Staked balance is lower than unstaking amount");

        stakingBalances[_tokenAddress][_msgSender()] -= _amount;

        // ?: if this user no longer has any of this token staked, decrease uniqueTokensStaked
        if (stakingBalances[_tokenAddress][_msgSender()] == 0) {
            uniqueTokensStaked[_msgSender()] -= 1;
        }

        // ?: if the user has no more unique tokens after unstaking this one, remove him from the stakers[]
        int256 stakerIndex = getStakerIndex(_msgSender());
        if (uniqueTokensStaked[_msgSender()] == 0 && (stakerIndex != -1)) {
            stakers[uint256(stakerIndex)] = stakers[stakers.length - 1];
            stakers.pop();
        }

        IERC20(_tokenAddress).transfer(_msgSender(), _amount);
        emit UnstakeTokens(_tokenAddress, _msgSender());
    }

    function addAllowedToken(IERC20 _tokenAddress, address _oracleAddress) public onlyOwner {
        if (!isTokenAllowed(_tokenAddress)) {
            allowedTokens.push(_tokenAddress);
        }
        tokenPriceFeed[_tokenAddress] = _oracleAddress;
    }

    function getTokenValue(IERC20 _tokenAddress)
        public
        view
        tokenIsAllowed(_tokenAddress)
        returns (int256 price, uint8 decimals)
    {
        address priceFeedAddress = tokenPriceFeed[_tokenAddress];
        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeedAddress);

        (, price, , , ) = oracle.latestRoundData();
        decimals = oracle.decimals();
    }

    function getUserSingleTokenUSDValue(address _user, IERC20 _tokenAddress)
        public
        view
        tokenIsAllowed(_tokenAddress)
        returns (uint256)
    {
        uint256 userTokenBalance = stakingBalances[_tokenAddress][_user];
        if (userTokenBalance == 0) return 0;

        (int256 price, uint8 decimals) = getTokenValue(_tokenAddress);
        // ?: userTokenBalance has 18 decimals, so divide it by 10**18.
        // ?: price from the oracle has <decimals> number of decimals, so divide by 10**decimals
        return (uint256(price) * userTokenBalance) / (10**decimals) / (10**18);
    }

    function getUserTotalUSDValue(address _user) public view returns (uint256) {
        if (uniqueTokensStaked[_user] == 0) return 0; // ?: if no tokens staked, value=0

        uint256 totalUSDValue = 0;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            totalUSDValue += getUserSingleTokenUSDValue(_user, allowedTokens[i]);
        }

        return totalUSDValue;
    }

    // TODO: get TVL

    // ?: in wei, since the reward is 1 wei for $1 of staked token USD value
    function totalStakingRewards() public view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < stakers.length; i++) {
            total += getUserTotalUSDValue(stakers[i]);
        }

        return total;
    }

    // !: extremely gas inefficient way to issue tokens
    function issueTokens() public onlyOwner {
        require(address(this).balance >= totalStakingRewards(), "Contract has insufficient ETH for token issuance");

        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint256 userTotalUSDValue = getUserTotalUSDValue(recipient);

            payable(recipient).sendValue(userTotalUSDValue); // ?: 1 wei for each USD that their tokens are worth
        }
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function contractEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ?: return all eth back to the owner
    function rug() public onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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