pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Helper } from "./helpers.sol";

import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    Account,
    Actions,
    Types,
    ISoloMargin,
    ICallee,
    DSAInterface
} from "./interfaces.sol";

import { DydxFlashloanBase } from "./dydxBase.sol";

contract DydxFlashloaner is Helper, ICallee, DydxFlashloanBase {
    using SafeERC20 for IERC20;


    event LogFlashLoan(
        address indexed dsa,
        address token,
        uint256 amount,
        uint route
    );

    event LogWhitelistSig(bytes4 indexed sig, bool whitelist);

    /**
    * @dev Check if sig is whitelisted
    * @param _sig bytes4
    */
    function checkWhitelisted(bytes4 _sig) public view returns(bool) {
        return whitelistedSigs[_sig];
    }
    

    /**
    * @dev Whitelists / Blacklists a given sig
    * @param _sigs list of sigs
    * @param _whitelist list of bools indicate whitelist/blacklist
    */
    function whitelistSigs(bytes4[] memory _sigs, bool[] memory _whitelist) public isMaster {
        require(_sigs.length == _whitelist.length, "arr-lengths-unequal");
        for (uint i = 0; i < _sigs.length; i++) {
            require(!whitelistedSigs[_sigs[i]], "already-enabled");
            whitelistedSigs[_sigs[i]] = _whitelist[i];
            emit LogWhitelistSig(_sigs[i], _whitelist[i]);
        }
    }

    function updateMakerConnect(address _makerConnect) external isMaster {
        require(_makerConnect != address(0), "not-valid-address");
        makerConnect = _makerConnect;
    }

    function updateAaveV2Connect(address _aaveV2Connect) external isMaster {
        require(_aaveV2Connect != address(0), "not-valid-address");
        aaveV2Connect = _aaveV2Connect;
    }
    
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        require(sender == address(this), "not-same-sender");
        require(msg.sender == soloAddr, "not-solo-dydx-sender");
        CastData memory cd;
        (cd.dsa, cd.route, cd.token, cd.amount, cd.callData) = abi.decode(
            data,
            (address, uint256, address, uint256, bytes)
        );

        bool isWeth = cd.route != 0 || cd.token == ethAddr;
        if (isWeth) {
            wethContract.withdraw(wethContract.balanceOf(address(this)));
        }

        selectBorrow(cd.route, cd.token, cd.amount);

        if (cd.token == ethAddr) {
            payable(cd.dsa).transfer(cd.amount);
        } else {
            IERC20(cd.token).safeTransfer(cd.dsa, cd.amount);
        }


        Address.functionCall(cd.dsa, cd.callData, "DSA-flashloan-fallback-failed");

        selectPayback(cd.route, cd.token);

        if (isWeth) {
            wethContract.deposit{value: address(this).balance}();
        }
    }

    function routeDydx(address token, uint256 amount, bytes memory data) internal {
        uint256 _amount = amount;

        uint256 route = 0;
        address _token;
        if (token == daiAddr) {
            uint256 dydxDaiAmt = daiContract.balanceOf(soloAddr);
            if (amount > dydxDaiAmt) {
                uint256 dydxWEthAmt = wethContract.balanceOf(soloAddr);
                route = 1;
                _amount = sub(dydxWEthAmt, 10000);
                _token = wethAddr;
            } else {
                _token = token;
            }
        } else if (token != ethAddr && token != usdcAddr) {
            uint256 dydxWEthAmt = wethContract.balanceOf(soloAddr);
            route = 2;
            _amount = sub(dydxWEthAmt, 10000);
            _token = wethAddr;
        } else {
            _token = token == ethAddr ? wethAddr : token;
        }
        
        IERC20 _tokenContract = IERC20(_token);
        uint256 _marketId = _getMarketIdFromTokenAddress(soloAddr, _token);

        _tokenContract.approve(soloAddr, _amount + 2);

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(_marketId, _amount);
        operations[1] = _getCallAction(encodeDsaCastData(msg.sender, route, token, amount, data));
        operations[2] = _getDepositAction(_marketId, _amount + 2);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        uint256 initialBal = add(_tokenContract.balanceOf(address(this)), address(this).balance);

        solo.operate(accountInfos, operations);

        uint256 finalBal = add(_tokenContract.balanceOf(address(this)), address(this).balance);

        if (_token == wethAddr) {
            uint256 _dif = wmul(_amount, 10000000000); // Taking margin of 0.00000001%
            require(sub(initialBal, finalBal) <= _dif, "eth-amount-paid-less");
        } else {
            uint256 _decimals = TokenInterface(token).decimals();
            uint _dif = wmul(convertTo18(_amount, _decimals), 200000000000); // Taking margin of 0.0000002%
            require(convertTo18(sub(initialBal, finalBal), _decimals) <= _dif, "token-amount-paid-less");
        }
            
        emit LogFlashLoan(
            msg.sender,
            token,
            amount,
            route
        );

    }

    function initiateFlashLoan(	
        address token,	
        uint256 amount,	
        bytes calldata data	
    ) external isDSA isWhitelisted(data) {	
        routeDydx(token, amount, data);	
    }
}

contract InstaPoolV2Implementation is DydxFlashloaner {
    function initialize(
        uint256 _vaultId,
        address _makerConnect,
        address _aaveV2Connect
    ) public {
        require(vaultId == 0 && makerConnect == address(0) && aaveV2Connect == address(0), "already-Initialized");
        wethContract.approve(wethAddr, uint256(-1));
        vaultId = _vaultId;
        makerConnect = _makerConnect;
        aaveV2Connect = _aaveV2Connect;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.7.0;

import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    Account,
    Actions,
    Types,
    ISoloMargin
} from "./interfaces.sol";

import { DSMath } from "../../common/math.sol";

import {Variables} from "./variables.sol";


contract Setup is Variables {
    IndexInterface public constant instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    ListInterface public constant instaList = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

    address public constant soloAddr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant daiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    TokenInterface constant wethContract = TokenInterface(wethAddr);
    TokenInterface constant daiContract = TokenInterface(daiAddr);
    TokenInterface constant usdcContract = TokenInterface(usdcAddr);
    ISoloMargin constant solo = ISoloMargin(soloAddr);

    /**
    * @dev modifier to check if msg.sender is a master 
    */
    modifier isMaster() {
        require(msg.sender == instaIndex.master(), "not-master");
        _;
    }

    /**
    * @dev Converts the encoded data to sig.
    * @param data encoded data
    */
    function convertDataToSig(bytes memory data) internal pure returns(bytes4 sig) {
        bytes memory _data = data;
        assembly {
            sig := mload(add(_data, 32))
        } 
    }

    /**
    * @dev modifier to check if data's sig is whitelisted
    */
    modifier isWhitelisted(bytes memory _data) {
        require(whitelistedSigs[convertDataToSig(_data)], "sig-not-whitelisted");
        _;
    }

    /**
     * FOR SECURITY PURPOSE
     * only Smart DEFI Account can access the liquidity pool contract
     */
    modifier isDSA {
        uint64 id = instaList.accountID(msg.sender);
        require(id != 0, "not-dsa-id");
        _;
    }

    struct CastData {
        address dsa;
        uint route;
        address token;
        uint256 amount;
        bytes callData;
    }
}

contract Helper is Setup, DSMath {
    function convertTo18(uint256 _amt, uint _dec) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function encodeDsaCastData(
        address dsa,
        uint route,
        address token,
        uint256 amount,
        bytes memory data
    ) internal pure returns (bytes memory _data) {
        _data = abi.encode(dsa, route, token, amount, data);
    }

    function spell(address _target, bytes memory _data) internal {
        require(_target != address(0), "target-invalid");
        assembly {
        let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
        switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    function masterSpell(address _target, bytes calldata _data) external isMaster {
        spell(_target, _data);
    }

    function selectBorrow(uint256 route, address token, uint256 amt) internal {
        if (route == 0) {
            return;
        } else if (route == 1) {
            bytes memory _dataOne = abi.encodeWithSignature("deposit(uint256,uint256)", vaultId, uint256(-1));
            bytes memory _dataTwo = abi.encodeWithSignature("borrow(uint256,uint256)", vaultId, amt);
            spell(makerConnect, _dataOne);
            spell(makerConnect, _dataTwo);
        } else if (route == 2) {
            bytes memory _dataOne = abi.encodeWithSignature("deposit(address,uint256)", ethAddr, uint256(-1));
            bytes memory _dataTwo = abi.encodeWithSignature("borrow(address,uint256,uint256)", token, amt, 2);
            spell(aaveV2Connect, _dataOne);
            spell(aaveV2Connect, _dataTwo);
        } else {
            revert("route-not-found");
        }
    }

    function selectPayback(uint256 route, address token) internal {
        if (route == 0) {
            return;
        } else if (route == 1) {
            bytes memory _dataOne = abi.encodeWithSignature("payback(uint256,uint256)", vaultId, uint256(-1));
            bytes memory _dataTwo = abi.encodeWithSignature("withdraw(uint256,uint256)", vaultId, uint256(-1));
            spell(makerConnect, _dataOne);
            spell(makerConnect, _dataTwo);
        } else if (route == 2) {
            bytes memory _dataOne = abi.encodeWithSignature("payback(address,uint256,uint256)", token, uint256(-1), 2);
            bytes memory _dataTwo = abi.encodeWithSignature("withdraw(address,uint256)", ethAddr, uint256(-1));
            spell(aaveV2Connect, _dataOne);
            spell(aaveV2Connect, _dataTwo);
        } else {
            revert("route-not-found");
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface DSAInterface {
    function flashCallback(
        address sender,
        address token,
        uint256 amount,
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external;
}

interface IndexInterface {
    function master() external view returns (address);
}

interface ListInterface {
    function accountID(address) external view returns (uint64);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);
}

interface Account {
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

interface Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}

interface Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface ISoloMargin {
    struct OperatorArg {
        address operator;
        bool trusted;
    }

    function getMarketTokenAddress(uint256 marketId)
        external
        view
        returns (address);

    function getNumMarkets() external view returns (uint256);

    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    function getAccountWei(Account.Info calldata account, uint256 marketId)
        external
        view
        returns (Types.Wei memory);
}

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info calldata accountInfo,
        bytes calldata data
    ) external;
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Account, Actions, Types, ISoloMargin } from "./interfaces.sol";

contract DydxFlashloanBase {
    function _getMarketIdFromTokenAddress(address _solo, address token)
        internal
        view
        returns (uint256)
    {
        ISoloMargin solo = ISoloMargin(_solo);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == token) {
                return i;
            }
        }

        revert("No marketId found for provided token");
    }

    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint marketId, uint256 amount)
        internal
        view
        returns (Actions.ActionArgs memory)
    {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }
}

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(x, y);
    }

    function sub(uint x, uint y) internal virtual pure returns (uint z) {
        z = SafeMath.sub(x, y);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.mul(x, y);
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.div(x, y);
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }
}

pragma solidity ^0.7.0;

contract Variables {
    // Maker connector
    address public makerConnect;

    // AaveV2 connector
    address public aaveV2Connect;

    // Maker ETH-A Vault ID
    uint256 public vaultId;

    // Whitelisted Sigs;
    mapping (bytes4 => bool) public whitelistedSigs;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}