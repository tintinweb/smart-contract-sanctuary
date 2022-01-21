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

interface IRadarBridgeFeeManager {
    function getBridgeFee(address _token, address _sender, uint256 _amount, bytes32 _destChain, address _destAddress) external view returns (uint256);

    function getFeeBase() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../extra/IBridgedToken.sol";
import "./utils/SignatureLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRadarBridgeFeeManager.sol";

contract RadarBridge {

    using SafeERC20 for IERC20;

    address private owner;
    address private pendingOwner;
    address private feeManager;
    bytes32 private CHAIN;

    mapping(bytes32 => bool) private doubleSpendingProtection;
    mapping(bytes32 => bool) private nonceDoubleSpendingProtection;

    mapping(address => bool) private isSupportedToken;
    mapping(address => bool) private tokenToHandlerType; // 0 - transfers, 1 - mint/burn, BridgedToken
    mapping(bytes32 => address) private idToToken;
    mapping(address => bytes32) private tokenToId;
    mapping(bytes32 => address) private idToRouter;

    address[] private supportedTokens;

    event SupportedTokenAdded(address token, bool handlerType, bytes32 tokenId, address router);
    event SupportedTokenRemoved(address token, bytes32 tokenId);

    event TokensBridged(
        bytes32 tokenId,
        uint256 amount,
        bytes32 destinationChain,
        address destinationAddress,
        uint256 timestamp,
        uint256 feeAmount,
        uint256 receiveAmount
    );
    event TokensClaimed(
        bytes32 tokenId,
        uint256 amount,
        bytes32 sourceChain,
        uint256 bridgeTimestamp,
        bytes32 nonce,
        address destinationAddress
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    // Management
    function initialize(bytes32 _chain) public {
        require(owner == address(0), "Contract already initialized");
        require(implementation() != address(0), "Only delegates can call this");
        CHAIN = _chain;
        owner = msg.sender;
    }

    function upgrade(address _newRadarBridge) external onlyOwner {
        assembly {
            // solium-disable-line
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _newRadarBridge
            )
        }
    }

    function sendOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid Owner Address");
        pendingOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Unauthorized");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function addSupportedToken(address _token, bool _handlerType, bytes32 _tokenID, address _router) external onlyOwner {
        require(!isSupportedToken[_token] && tokenToId[_token] == "", "Token already exists");
        require(idToToken[_tokenID] == address(0), "Token ID already being used");

        isSupportedToken[_token] = true;
        supportedTokens.push(_token);
        tokenToHandlerType[_token] = _handlerType;
        tokenToId[_token] = _tokenID;
        idToToken[_tokenID] = _token;
        idToRouter[_tokenID] = _router;
        emit SupportedTokenAdded(_token, _handlerType, _tokenID, _router);
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(isSupportedToken[_token], "Token is not supported");

        isSupportedToken[_token] = false;
        uint256 _length = supportedTokens.length;
        for (uint256 i = 0; i < _length; i++) {
            if (supportedTokens[i] == _token) {
                if (i < _length - 1) {
                    supportedTokens[i] = supportedTokens[_length - 1];
                }
                supportedTokens.pop();
                break;
            }
        }
        bytes32 _tokenId = tokenToId[_token];
        tokenToId[_token] = "";
        idToToken[_tokenId] = address(0);
        idToRouter[_tokenId] = address(0);
        emit SupportedTokenRemoved(_token, _tokenId);
    }

    function changeTokenRouter(bytes32 _tokenId, address _newRouter, bytes memory signature) external {
        require(isSupportedToken[idToToken[_tokenId]], "Token not supported");

        // Verify Signature
        bytes32 message = keccak256(abi.encodePacked(bytes32("PASS OWNERSHIP"), _tokenId, _newRouter, CHAIN));
        require(SignatureLibrary.verify(message, signature, idToRouter[_tokenId]) == true, "Invalid Signature");

        // Change Router
        idToRouter[_tokenId] = _newRouter;
    }

    function changeFeeManager(address _newFeeManager) external onlyOwner {
        feeManager = _newFeeManager;
    }
    
    // Bridge Functions
    function bridgeTokens(
        address _token,
        uint256 _amount,
        bytes32 _destChain,
        address _destAddress
    ) external {
        require(isSupportedToken[_token], "Token not supported");
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Not enough tokens");
        require(_destChain != CHAIN, "Cannot send to same chain");
        require(_amount > 0, "Amount cannot be 0");

        bytes32 _tokenId = tokenToId[_token];
        bool _handlerType = tokenToHandlerType[_token];
        uint256 _fee = 0;

        if (feeManager != address(0)) {
            uint256 _userFee;
            uint256 _feeBase;

            // Use try/catch to prvevent rogue bridge locking
            try IRadarBridgeFeeManager(feeManager).getBridgeFee(_token, msg.sender, _amount, _destChain, _destAddress) returns (uint256 _val) {
                _userFee = _val;
            } catch {
                _userFee = 0;
            }

            if (_userFee != 0) {
                try IRadarBridgeFeeManager(feeManager).getFeeBase() returns (uint256 _val2) {
                    _feeBase = _val2;
                } catch {
                    _feeBase = 0;
                }
                
                // fee cannot be larger than 10%
                if (_feeBase != 0 && (_userFee * 10) <= _feeBase) {
                    _fee = (_amount * _userFee) / _feeBase;
                }
            }
        }

        // Transfer tokens
        if (_handlerType) {
            // burn
            IBridgedToken(_token).burn(msg.sender, _amount);
            if (_fee != 0) {
                IBridgedToken(_token).mint(feeManager, _fee);
            }
        } else {
            // transfer
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            if (_fee != 0) {
                IERC20(_token).safeTransfer(feeManager, _fee);
            }
        }

        emit TokensBridged(
            _tokenId,
            _amount,
            _destChain,
            _destAddress,
            block.timestamp,
            _fee,
            _amount-_fee
        );
    }

    function claimTokens(
        bytes32 _tokenId,
        uint256 _amount,
        bytes32 _srcChain,
        bytes32 _destChain,
        uint256 _srcTimestamp,
        bytes32 _nonce,
        address _destAddress,
        bytes calldata _signature
    ) external {
        address _token = idToToken[_tokenId];

        require(_token != address(0) && isSupportedToken[_token], "Token not supported.");
        require(_destChain == CHAIN, "Claiming tokens on wrong chain");

        bytes32 message = keccak256(abi.encodePacked(
            _tokenId,
            _amount,
            _srcChain,
            _destChain,
            _srcTimestamp,
            _nonce,
            _destAddress
        ));
        require(doubleSpendingProtection[message] == false, "Double Spending");
        require(nonceDoubleSpendingProtection[_nonce] == false, "Nonce Double Spending");
        require(SignatureLibrary.verify(message, _signature, idToRouter[_tokenId]) == true, "Router Signature Invalid");

        doubleSpendingProtection[message] = true;
        nonceDoubleSpendingProtection[_nonce] = true;

        bool _handlerType = tokenToHandlerType[_token];

        if (_handlerType) {
            // mint
            IBridgedToken(_token).mint(_destAddress, _amount);
        } else {
            // transfer
            IERC20(_token).safeTransfer(_destAddress, _amount);
        }

        emit TokensClaimed(_tokenId, _amount, _srcChain, _srcTimestamp, _nonce, _destAddress);
    }
    // State Getters
    function getOwner() external view returns (address) {
        return owner;
    }

    function getChain() external view returns (bytes32) {
        return CHAIN;
    }

    function getFeeManager() external view returns (address) {
        return feeManager;
    }
    
    function implementation() public view returns (address radarBridge_) {
        assembly {
            // solium-disable-line
            radarBridge_ := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        return radarBridge_;
    }

    function getIsSupportedToken(address _token) external view returns (bool) {
        return isSupportedToken[_token];
    }

    function getTokenHandlerType(address _token) external view returns (bool) {
        return tokenToHandlerType[_token];
    }

    function getTokenId(address _token) external view returns (bytes32) {
        return tokenToId[_token];
    }

    function getTokenById(bytes32 _id) external view returns (address) {
        return idToToken[_id];
    }

    function getSupportedTokensLength() external view returns (uint) {
        return supportedTokens.length;
    }

    function getSupportedTokenByIndex(uint _index) external view returns (address) {
        return supportedTokens[_index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SignatureLibrary {

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message:\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        bytes32 _message, bytes memory _signature, address _signer
    )
        internal pure returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_message);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgedToken {

    function getBridge() external view returns (address);

    function getMigrator() external view returns (address);

    function acceptMigratorAuthority() external;

    function mint(address, uint256) external;

    function burn(address, uint256) external;
}