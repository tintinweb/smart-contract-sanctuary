/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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




contract PrivatePresale {

    using SafeERC20 for IERC20;

    uint256 private _privatePrice = 20;
    uint256 public _totalCollected;
    uint256 private _oldCollected = 0;
    uint256 private _newCollected = 0;
    uint256 public _walletLimit = 4*10**(18);
    uint256 public _softCap = 5*10**(18);
    uint256 public _txCount;
    bool public _tgeHappened = false;
    uint256 private _tgeToCollect = 15000;
    uint256 private _normalCollect = 10625;

    uint256 private _1Collect;
    uint256 private _2Collect;
    uint256 private _3Collect;
    uint256 private _4Collect;
    uint256 private _5Collect;
    uint256 private _6Collect;
    uint256 private _7Collect;
    uint256 private _8Collect;


    // Declare BUSD token
    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 - Mainnet BUSD Address
    // 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee - Testnet BUSD Address
    IERC20 busd = IERC20(address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee));

    IERC20 msn = IERC20(address(0xDa44884bd71E1A22a30Ef5577d6271B90Cf2006D));
    
    bool public _privateOpen;

    event DepositSuccesful(address _sender, uint256 _value, uint256 _totalValue);

    address public _owner;
    mapping(address => presaleWallet) _inPresale;

    struct presaleWallet {
        bool _isWhiteListed;
        uint256 _amount;
        uint256 _txCount;
        uint256 _tokenAmount;
        uint256 _newAmount;
        bool _tgeCollect;
        uint256 _numOfCollectTX;
        uint256 _nextCollect;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "OnlyOwner: You're not the owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    function busdBalance() public view returns(uint256) {
        return busd.balanceOf(address(this));
    }

    function privateRound() public payable {
        require(_privateOpen == true,"PrivateRound: Private Round is Closed");

        _newCollected = busd.balanceOf(address(this));
        uint256 _txCollected = _newCollected - _oldCollected;
        _oldCollected = _newCollected;
        require(_txCollected > 0,"PrivateRound: You sent 0 BUSD");
        require(_inPresale[msg.sender]._amount + _txCollected <= _walletLimit, "PrivateRound: Wallet limit has been reached");
        _totalCollected += _txCollected;
        _txCount ++;

        _inPresale[msg.sender]._isWhiteListed = true;
        _inPresale[msg.sender]._amount += _txCollected;
        _inPresale[msg.sender]._txCount ++;
        _inPresale[msg.sender]._tokenAmount += (_txCollected*10**2)/_privatePrice;

        emit DepositSuccesful(msg.sender, _txCollected, _inPresale[msg.sender]._amount);
    }

    function openPrivateRound(bool _bool) public onlyOwner {
        _privateOpen = _bool;
    }

    function changePrivatePrice(uint256 _newPrice) public onlyOwner {
        _privatePrice = _newPrice;
    }

    function closePresale() public onlyOwner {
        require(_softCap <= _totalCollected,"ClosePresale Error: Soft Cap has not been reached");
        busd.safeTransfer(msg.sender, _totalCollected);
        _totalCollected = 0;
        _privateOpen = false;
    }
    
    function tgeHappened(bool _bool) public onlyOwner {
        _tgeHappened = _bool;
        _1Collect += 2 weeks;
        _2Collect += 4 weeks;
        _3Collect += 6 weeks;
        _4Collect += 8 weeks;
        _5Collect += 10 weeks;
        _6Collect += 12 weeks;
        _7Collect += 14 weeks;
        _8Collect += 16 weeks;
    }

    function isWhitelisted(address _address) public view returns (bool){
        if (_inPresale[_address]._isWhiteListed == true)
            return true;
        else    
            return false;
    }
    
    function claimTokens() public {
        require(_tgeHappened == true, "Claim Error: TGE has not yet happened");
        if (_inPresale[msg.sender]._tgeCollect == false) {
            uint256 _amountToCollect = (_inPresale[msg.sender]._tokenAmount*10**3)/_tgeToCollect;
            _inPresale[msg.sender]._tgeCollect == true;
            _inPresale[msg.sender]._newAmount -= _amountToCollect;
            _inPresale[msg.sender]._nextCollect += 2 weeks;
            _inPresale[msg.sender]._numOfCollectTX ++;

            require(_inPresale[msg.sender]._newAmount >= _amountToCollect, "You have not enought tokens left");
            // send tokens

            msn.safeTransfer(msg.sender, _amountToCollect);

        } else {
            require(_inPresale[msg.sender]._numOfCollectTX < 8, "Claim Error: You have already claimed all tokens");
            require(_inPresale[msg.sender]._tokenAmount > 0,"Claim Error: You have already claimed all tokens");

            if (_inPresale[msg.sender]._numOfCollectTX == 1) {
                require(block.timestamp >= _1Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 2) {
                require(block.timestamp >= _2Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 3) {
                require(block.timestamp >= _3Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 4) {
                require(block.timestamp >= _4Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 5) {
                require(block.timestamp >= _5Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 6) {
                require(block.timestamp >= _6Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 7) {
                require(block.timestamp >= _7Collect,"Claim Error: Claim Time has not been reached");
            } else if (_inPresale[msg.sender]._numOfCollectTX == 8) {
                require(block.timestamp >= _8Collect,"Claim Error: Claim Time has not been reached");
            }
            uint256 _amountToCollect = (_inPresale[msg.sender]._tokenAmount*10**3)/_normalCollect;
            require(_inPresale[msg.sender]._newAmount >= _amountToCollect, "You have not enought tokens left");
            _inPresale[msg.sender]._newAmount -= _amountToCollect;
             _inPresale[msg.sender]._numOfCollectTX ++;

            //send tokens
            msn.safeTransfer(msg.sender, _amountToCollect);
        }
    }

    function depositAmount(address _address) public view returns (uint256) {
        require(_inPresale[_address]._isWhiteListed == true, "PresaleError: Address has not participated");
        return(_inPresale[_address]._amount);
    }

    receive() external payable {
        revert('You cannot directly send money to this smart contract');
    }

}