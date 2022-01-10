//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../access/BumperAccessControl.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IMarketStates.sol";
import "../interfaces/IProtocolConfig.sol";

contract Market is IMarket, BumperAccessControl
{
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IERC20 public immutable bToken;
    IERC20 public immutable stable;
    IERC20 public immutable bump;
      
    address public config;
    address public bumper;
    address public state;

    modifier takerTermEnds(uint id) {
        require(block.timestamp > (allTakerPositions[id].start + allTakerPositions[id].term), "!end");
        _;
    }

    modifier makerTermEnds(uint id) {
        require(block.timestamp > (allMakerPositions[id].start + allMakerPositions[id].term), "!end");
        _;
    }

    modifier onlyBumper() {
        require(msg.sender == bumper);
        _;
    }

    /* TAKER DATA */
    struct TakerPosition {
        address owner;
        uint index;
        uint assetAmount;
        uint32 risk; 
        uint start;
        uint32 term;
        uint floor;
        bool autorenew;
    }

    uint public takerPosIndex;

    uint public AP;
    uint public AR;
    uint public L;

    mapping(uint=>TakerPosition) allTakerPositions;

    /* MAKER DATA */
    struct MakerPosition {
        address owner;
        uint index;
        uint stableAmount;
        uint start;
        uint32 term;
    }

    uint makerPosIndex;
    uint public CP;
    uint public CR;
    uint public B;
    uint public D;

    mapping(uint => MakerPosition) public allMakerPositions;

    /* GENERAL DATA */
    struct UserPositions {
        uint[] taker;
        uint[] maker;
    }
    mapping(address=>UserPositions) accounts;
    uint totalBumpAmount;

    constructor(address _token, address _stable, address _config) { 
        token = IERC20(_token);
        stable = IERC20(_stable);
        config = _config;
        bump = IERC20( IProtocolConfig(_config).getBump() );
        bToken = IERC20( IProtocolConfig(_config).getBToken(_token) );
        state = IProtocolConfig(_config).getStateHistory();
    }

    function calcNewTakerPosition(uint amount, uint risk, uint32 term) public view 
        returns (uint fee, uint floor) 
    {
        floor = amount * IMarketStates(state).getCurrentPrice(address(token)) * risk/1000 * (10**18) / (2**64);
        fee = amount/2000; // test only - 0.2%  
    }

    function calcNewMakerPosition(uint amount, uint32 term) public pure returns (uint fee){
        return (1); // test only
    }

    function calcMakerPositionForClose( uint amount, uint start, uint32 term ) public pure returns (uint yield){
        return 1; // test only
    }

    function premium(uint amount, uint32 risk, uint32 term) external view override returns (uint) {
        return 0;
    }

    function getUserPositions(address account) public view returns (UserPositions memory user){
        user = accounts[account];
    }

    function protect(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external override returns (uint id) {
        require(amount > 0, "zero" );
        
        (uint fee, uint floor)  = calcNewTakerPosition(amount, risk, term);        
        TakerPosition memory pos = TakerPosition({
            owner: account,
            index: takerPosIndex,
            assetAmount: amount,
            risk: risk,
            start: block.timestamp,
            term: term,
            floor: floor,
            autorenew: autorenew
        });

        // add new taker position to users profile
        accounts[account].taker.push(pos.index);

        allTakerPositions[takerPosIndex] = pos;

        // update market state variables
        AP += amount;
        AR += fee;
        L += pos.floor;
        B += amount;        

        takerPosIndex ++;

        return pos.index;
    }

    function close(address account, uint id) external override takerTermEnds(id) {
        require(account == allTakerPositions[id].owner, "!auth");

        TakerPosition storage pos = allTakerPositions[id];
        require(pos.start != 0, "closed");

        token.safeTransfer(account, pos.assetAmount );       
        B -= pos.assetAmount;
        CP -= pos.assetAmount;

        // calc 
        uint posSizeInStable = pos.assetAmount * uint(IMarketStates(state).getCurrentPrice(address(token)) * (10**18) / (2**64) );
        uint claim = pos.floor > posSizeInStable ? (pos.floor - posSizeInStable) : 0;
        uint premium = pos.assetAmount/20; // test only 5%

        //(uint premium, uint ) = calcTakerPositionForClose(pos.assetAmount, pos.start, pos.term, pos.risk);
        //stable.safeTransfer(account, yield );
        //CR += yield;

        delete allTakerPositions[id];
    }

    function claim(address account, uint id) external override {

    }

    function deposit(address account, uint amount, uint32 term) external override returns (uint id) {

        require(amount > 0, "zero" );

        (uint fee) = calcNewMakerPosition(amount, term);

        stable.safeTransferFrom(account, address(this), amount + fee );      
        D += amount;
        CR += fee;


        MakerPosition memory pos = MakerPosition({
            owner: account,
            index: takerPosIndex,
            stableAmount: amount,
            start: block.timestamp,
            term: term
        });

        accounts[account].maker.push(pos.index);
        allMakerPositions[makerPosIndex] = pos;

        makerPosIndex++;
    }

    function withdraw(address account, uint id) external override {
        require(account == allMakerPositions[id].owner, "!auth");

        MakerPosition storage pos = allMakerPositions[id];
        require(pos.start != 0, "closed");

        (uint yield) = calcMakerPositionForClose(pos.stableAmount, pos.start, pos.term);
        pos.start = 0; // mark as closed

        stable.safeTransfer(account, pos.stableAmount + yield );       
        // totalStableAmount -= pos.stableAmount;
        // totalYieldAmount += yield;
    }

    function rebalance() external override {

    }

    function protectETH(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external payable override returns (uint id) {

    }

    /// @notice Withdraw for govenance
    function govWithdraw(address _token, address to, uint amount) external override onlyGovernance {
        IERC20(_token).safeTransfer(to, amount);
    }

    /// @notice Get market state parameters
    function getState() external view override returns (int128 _AP, int128 _AR, int128 _CP, int128 _CR, int128 _B, int128 _L, int128 _D) {
        return (toInt128(AP),toInt128(AR),toInt128(CP),toInt128(CR),toInt128(B),toInt128(L),toInt128(D));
    }

    function toInt128(uint a) public pure returns (int128) {
        return int128 (int256(a * (2**64)/(10**18)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        //require(whitelist[_msgSender()], "!whitelist"); //ToDo:
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "!ownerOrWhitelist"
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyOwner {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyOwner {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMarket {
    function premium(uint amount, uint32 risk, uint32 term) external view returns (uint);
    function protect(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external returns (uint id);
    function protectETH(address account, uint amount, uint32 risk, uint32 term, bool autorenew) external payable returns (uint id);
    function close(address account, uint id) external;
    function claim(address account, uint id) external;
    function deposit(address account, uint amount, uint32 term) external returns (uint id);
    function withdraw(address account, uint id) external;
    function rebalance() external;    
    function govWithdraw(address token, address to, uint amount) external; // only governance
    function getState() external view returns (int128 AP, int128 AR, int128 CP, int128 CR, int128 B, int128 L, int128 D);

// NEED TO DISCUSS WITH SAM
//    function liquidate(uint id) external;
//    function handleTransfer(address from, address to, uint amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../market/State.sol";

interface IMarketStates {
    function getCurrentPrice(address token) external view returns (uint);
    function getCurrentState(address token) external view 
        returns (MarketState memory data);
    function getStateAt(address token, uint index) external view 
        returns (MarketState memory data);   
    function updateState(address[] memory tokens) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../configuration/MarketConfig.sol";

interface IProtocolConfig {
    function getVersion() external view returns (uint16);
    function getStable() external view returns (address);
    function getConfig(address token) external view returns (MarketConfig memory config);
    function getBToken(address token) external view returns (address);
    function getMarket(address token) external view returns (address);
    function getETHMarket() external view returns (address);
    function getBump() external view returns (address);
    function getStateHistory() external view returns (address);
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketState {    
    int128 price;
    int128 AccelNorm;
    int128 VelNorm;        
    int128 AP;
    int128 AR;
    int128 L;
    int128 CP;
    int128 CR;
    int128 B;
    int128 D; 
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

struct MarketConfig {
    int128[2] U_Lambda;
    int128[2] U_Ref;
    int128[2] U_Max;
    int128    U_Speed;
    int128[6] W_Lambda;
    int128[6] W_Ref;
    int128[6] W_Max;
    int128    W_Speed;
    int128    gamma;
    int128    lambdaGamma;    
    int128    delta;    
    int128    lambdaDelta;
    int128    eps;
    int128    V_Max;
    int128    VRF_Max;
    int128    LRF_Max;
    int128    PRF_Max;
}