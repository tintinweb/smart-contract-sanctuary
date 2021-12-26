// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "IERC20.sol";
import "SafeERC20.sol"; 

interface HistoricalPriceConsumerV3 {
  function getLatestPriceX1e6(address) external view returns (int);

}

interface VaultV0 {
    function expiry() external returns (uint);  
    function COLLAT_ADDRESS() external returns (address); 
    function PRICE_FEED() external returns (address);
    function LINK_AGGREGATOR() external returns (address);
    
    /* Multisig Alpha */
    function setOwner(address newOwner) external;
    function settleStrike_MM(uint priceX1e6) external;
    function setExpiry(uint arbitraryExpiry) external;
    function setMaxCap(uint newDepositCap) external;
    function setMaker(address newMaker) external;
    function setPriceFeed(HistoricalPriceConsumerV3 newPriceFeed) external;
    function emergencyWithdraw() external;
    function depositOnBehalf(address tgt, uint256 amt) external;
    function setAllowInteraction(bool _flag) external;
}

contract OwnerProxy {
    using SafeERC20 for IERC20;
    
    address public multisigAlpha;
    address public multisigBeta;
    address public teamKey;

    address public multisigAlpha_pending;
    address public multisigBeta_pending;
    address public teamKey_pending;
    
    mapping(bytes32 => uint) public queuedPriceFeed;
    
    event PriceFeedQueued(address indexed _vault, address pricedFeed);
    
    constructor() {
      multisigAlpha = msg.sender;
      multisigBeta  = msg.sender;
      teamKey       = msg.sender;
    }
    
    function setMultisigAlpha(address _newMultisig) external {
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      multisigAlpha_pending = _newMultisig;
    }

    function setMultisigBeta(address _newMultisig) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta, "!multisigAlpha/Beta");
      multisigBeta_pending = _newMultisig;
    }
    
    function setTeamKey(address _newTeamKey) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta || msg.sender == teamKey, "!ownerKey");
      teamKey_pending = _newTeamKey;
    }
    
    function acceptMultisigAlpha() external {
      require(msg.sender == multisigAlpha_pending, "!multisigAlpha_pending");
      multisigAlpha = multisigAlpha_pending;
    }

    function acceptMultisigBeta() external {
      require(msg.sender == multisigBeta_pending, "!multisigBeta_pending");
      multisigBeta = multisigBeta_pending;
    }

    function acceptTeamKey() external {
      require(msg.sender == teamKey_pending, "!teamKey_pending");
      teamKey = teamKey_pending;
    }
    
    function setOwner(VaultV0 _vault, address _newOwner) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.setOwner(_newOwner);
    }
    
    function emergencyWithdraw(VaultV0 _vault) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.emergencyWithdraw();
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS());
      COLLAT.safeTransfer(multisigAlpha, COLLAT.balanceOf( address(this) ));
      require(COLLAT.balanceOf(address(this)) == 0, "eWithdraw transfer failed."); 
    }
    
    function queuePriceFeed(VaultV0 _vault, HistoricalPriceConsumerV3 _priceFeed) external {
      if        (msg.sender == multisigAlpha) {  // multisigAlpha can instantly change the price feed 
        _vault.setPriceFeed(_priceFeed);
        return;
      } else if (msg.sender == multisigBeta) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] == 0) {
          queuedPriceFeed[hashedParams] = block.timestamp + 1 days;
          emit PriceFeedQueued(address(_vault), address(_priceFeed));
        } else {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked"); 
          _vault.setPriceFeed(_priceFeed);
        }
      } else if (msg.sender == teamKey) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] > 0) {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked");
          _vault.setPriceFeed(_priceFeed);
        }
      } else {
        revert("Not Privileged Key");
      }
    }

    function settleStrike_MM(VaultV0 _vault, uint _priceX1e6) external {
      if   (msg.sender == multisigAlpha) { // Arbitrary price setting
        _vault.settleStrike_MM(_priceX1e6);
      } else {
        uint curPrice = uint(HistoricalPriceConsumerV3(_vault.PRICE_FEED()).getLatestPriceX1e6(_vault.LINK_AGGREGATOR()));
        uint upperBound = curPrice;
        uint lowerBound = curPrice; 
        if (msg.sender == multisigBeta) {   // +/- 20% price set
          upperBound = curPrice * 1200 / 1000;
          lowerBound = curPrice *  800 / 1000;
        } else if (msg.sender == teamKey) { // +/- 5% price set
          upperBound = curPrice * 1050 / 1000;
          lowerBound = curPrice *  950 / 1000;        
        } else {
          revert("Not Owner Keys");
        }
        if (_priceX1e6 > upperBound) revert("Price too high");
        if (_priceX1e6 < lowerBound) revert("Price too low");
        _vault.settleStrike_MM(_priceX1e6);       
      }
    }
    
    function setExpiry(VaultV0 _vault, uint _expiry) external {
      require(msg.sender == multisigBeta, "Not multisigBeta");
      require(_vault.expiry() > 0, "Expired");
      require(_expiry < _vault.expiry(), "Can only set expiry nearer");
      require(_expiry > block.timestamp + 1 hours, "At least 1 hour buffer");
      _vault.setExpiry(_expiry);
    }
    
    
    function depositOnBehalf(VaultV0 _vault, address _onBehalfOf, uint _amt) external {
      require(msg.sender == teamKey, "Not teamKey");
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS()); 
      COLLAT.transferFrom(msg.sender, address(this), _amt);
      COLLAT.approve(address(_vault), _amt);
      _vault.depositOnBehalf(_onBehalfOf, _amt);
      require(COLLAT.balanceOf(address(this)) == 0, "Balance Left On OwnerProxy");
    }
    
    function setMaxCap(VaultV0 _vault, uint _maxCap) external {
      require(msg.sender == teamKey, "Not teamKey");
      _vault.setMaxCap(_maxCap);
    }   
    
    function setAllowInteraction(VaultV0 _vault, bool _flag) external {
      require(msg.sender == teamKey, "Not teamKey");
      require(_vault.expiry() == 0, "Not Expired");
      _vault.setAllowInteraction(_flag);
    }

    function setMaker(VaultV0 _vault, address _newMaker) external {
      if (msg.sender == multisigBeta) {  
        _vault.setMaker(_newMaker);
      } else if (msg.sender == teamKey) {
        require(_vault.expiry() == 0, "Not Expired");      
        _vault.setMaker(_newMaker);
      } else {
       revert("!teamKey,!musigBeta");
      }
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

import "IERC20.sol";
import "Address.sol";

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