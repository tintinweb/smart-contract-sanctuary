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

import "./interfaces/IRadarBondsTreasury.sol";
import "./interfaces/IRadarBond.sol";
import "./interfaces/IRadarStaking.sol";
import "./external/IUniswapV2Pair.sol";
import "./external/IERC20Extra.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RadarBond is IRadarBond {

    using SafeERC20 for IERC20;

    mapping(address => BondInfo) private bonds;
    mapping(address => uint256) flashProtection;
    mapping(address => bool) trustedOrigins;
    BondTerms private terms;

    address private TREASURY;
    address private STAKING;
    address private immutable PAYOUT_ASSET;
    address private immutable BOND_ASSET;

    uint256 private constant DISCOUNT_DIVISOR = 10000;

    uint256 private totalLPDeposited = 0;

    modifier onlyManager {
        require(msg.sender == getManager(), "Unauthorized");
        _;
    }

    modifier flashLocked {
        if (!trustedOrigins[tx.origin]) {
            require(block.number > flashProtection[tx.origin], "Flash Protection");
        }
        flashProtection[tx.origin] = block.number;
        _;
    }

    constructor (
        address _treasury,
        address _payoutAsset,
        address _bondAsset,
        address _staking,
        uint256 _depositLimit, // bondAsset is LP token, so this limit max reward of payout token per user
        uint256 _vestingTime,
        uint256 _bondDiscount,
        uint256 _minPrice
    ) {
        TREASURY = _treasury;
        PAYOUT_ASSET = _payoutAsset;
        BOND_ASSET = _bondAsset;
        STAKING = _staking;
        terms = BondTerms({
            bondPayoutLimit: _depositLimit,
            vestingTime: _vestingTime,
            bondDiscount: _bondDiscount,
            minPrice: _minPrice
        });
    }

    // Manager functions
    function changeTerms(
        uint256 _depositLimit, // bondAsset is LP token, so this limit max reward of payout token per user
        uint256 _vestingTime,
        uint256 _bondDiscount,
        uint256 _minPrice
    ) external onlyManager {
        terms = BondTerms({
            bondPayoutLimit: _depositLimit,
            vestingTime: _vestingTime,
            bondDiscount: _bondDiscount,
            minPrice: _minPrice
        });
    }

    function changeTreasury(address _newTreasury) external onlyManager {
        TREASURY = _newTreasury;
    }

    function changeStaking(address _newStaking) external onlyManager {
        STAKING = _newStaking;
    }

    function setTrustedOrigin(address _origin, bool _status) external onlyManager {
        trustedOrigins[_origin] = _status;
    }

    // Bond functions
    function bond(uint256 _amount, uint256 _minReward) external override flashLocked {
        require(_amount <= getMaxBondAmount(), "Bond too big");
        (uint256 _reward, uint256 _spotPrice) = _calculateReward(_amount);
        require(_reward >= _minReward, "Slippage minReward");
        require(_spotPrice >= terms.minPrice, "Price too low for bond minting");

        IERC20(BOND_ASSET).safeTransferFrom(msg.sender, TREASURY, _amount);
        uint256 _rewardPayout = IRadarBondsTreasury(TREASURY).getReward(_reward);

        bonds[msg.sender] = BondInfo({
            payout: (_rewardPayout + bonds[msg.sender].payout),
            updateTimestamp: block.timestamp,
            leftToVest: terms.vestingTime
        });

        totalLPDeposited = totalLPDeposited + _amount;

        emit BondCreated(msg.sender, _amount, bonds[msg.sender].payout, (block.timestamp + terms.vestingTime));
    }

    function redeem(bool _stake) external override flashLocked {
        BondInfo memory userBond = bonds[msg.sender];

        uint256 _delta = block.timestamp - userBond.updateTimestamp;
        uint256 _vestingTime = userBond.leftToVest;
        uint256 _payout;
        uint256 _leftToVest;

        require(userBond.payout > 0 && _vestingTime > 0, "Bond does not exist");

        if (_delta >= _vestingTime) {
            _payout = userBond.payout;
            _leftToVest = 0;
            delete bonds[msg.sender];
        } else {
            _payout = (userBond.payout * _delta) / _vestingTime;
            _leftToVest = (userBond.leftToVest - _delta);

            bonds[msg.sender] = BondInfo({
                payout: (userBond.payout - _payout),
                leftToVest: _leftToVest,
                updateTimestamp: block.timestamp
            });
        }

        _giveReward(msg.sender, _payout, _stake);
        emit BondRedeemed(
            msg.sender,
            _payout,
            (userBond.payout - _payout),
            _leftToVest,
            _stake
        );
    }

    function _giveReward(address _receiver, uint256 _amount, bool _stake) internal {
        if (_stake) {
            IERC20(PAYOUT_ASSET).safeApprove(STAKING, _amount);
            IRadarStaking(STAKING).stake(_amount, _receiver);
        } else {
            IERC20(PAYOUT_ASSET).safeTransfer(_receiver, _amount);
        }
    }

    // Internal functions
    function _rewardToLPBondAsset(uint256 _payoutAssetAmount) internal view returns (uint256) {
        
        uint256 _value = (_payoutAssetAmount * DISCOUNT_DIVISOR) / (terms.bondDiscount + DISCOUNT_DIVISOR);
        _value = _value / 2;

        (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(BOND_ASSET).getReserves();
        uint256 _totalSupply = IUniswapV2Pair(BOND_ASSET).totalSupply();
        address _token0 = IUniswapV2Pair(BOND_ASSET).token0();

        uint256 _bondAssetAmount;
        if (_token0 == PAYOUT_ASSET) {
            _bondAssetAmount = (_value * _totalSupply) / _reserve0;
        } else {
            _bondAssetAmount = (_value * _totalSupply) / _reserve1;
        }

        return _bondAssetAmount;
    }

    function _calculateReward(uint256 _bondAssetAmount) internal view returns (uint256, uint256) {
        (uint256 _value, uint256 _price) = _getPayoutAssetValueFromBondAsset(_bondAssetAmount);

        uint256 _reward = _value + ((_value * terms.bondDiscount) / DISCOUNT_DIVISOR);

        return (_reward, _price);
        
    }

    function _getPayoutAssetValueFromBondAsset(uint256 _bondAssetAmount) internal view returns (uint256, uint256) {
        (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(BOND_ASSET).getReserves();
        uint256 _totalSupply = IUniswapV2Pair(BOND_ASSET).totalSupply();
        address _token0 = IUniswapV2Pair(BOND_ASSET).token0();
        address _token1 = IUniswapV2Pair(BOND_ASSET).token1();
        uint8 _token0Decimals = IERC20Extra(_token0).decimals();
        uint8 _token1Decimals = IERC20Extra(_token1).decimals();

        uint256 _value;
        uint256 _price;
        if (_token0 == PAYOUT_ASSET) {
            _value = ((_reserve0 * _bondAssetAmount) / _totalSupply) * 2;
            _price = (_reserve1 * (10**_token0Decimals)) / _reserve0;
        } else {
            _value = ((_reserve1 * _bondAssetAmount) / _totalSupply) * 2;
            _price = (_reserve0 * (10**_token1Decimals)) / _reserve1;
        }

        return (_value, _price);
    }

    // State getters

    function getTotalLPDeposited() external view override returns (uint256) {
        return totalLPDeposited;
    }

    function getManager() public view override returns (address) {
        return IRadarBondsTreasury(TREASURY).getOwner();
    }

    function getBondingTerms() external view override returns (BondTerms memory) {
        return terms;
    }

    function getBond(address _owner) external view override returns (BondInfo memory) {
        return bonds[_owner];
    }

    function getTreasury() external view override returns (address) {
        return TREASURY;
    }

    function getStaking() external view override returns (address) {
        return STAKING;
    }

    function getPayoutAsset() external view override returns (address) {
        return PAYOUT_ASSET;
    }

    function getBondAsset() external view override returns (address) {
        return BOND_ASSET;
    }

    function estimateReward(uint256 _bondAssetAmount) external override view returns (uint256) {
        (uint256 _reward, ) =  _calculateReward(_bondAssetAmount);
        return _reward;
    }

    function getIsTrustedOrigin(address _origin) external override view returns (bool) {
        return trustedOrigins[_origin];
    }

    function getMaxBondAmount() public view override returns (uint256) {
        uint256 _bondLimit = _rewardToLPBondAsset(terms.bondPayoutLimit);
        uint256 _payoutLeftTreasury = IRadarBondsTreasury(TREASURY).getBondTokenAllowance(address(this));
        uint256 _treasuryLimit = _rewardToLPBondAsset(_payoutLeftTreasury);
        if (_bondLimit < _treasuryLimit) {
            return _bondLimit;
        } else {
            return _treasuryLimit;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Extra {
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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
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
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
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

pragma solidity ^0.8.0;

interface IRadarBond {

    struct BondTerms {
        uint256 bondPayoutLimit; // bond reward limit in RADAR
        uint256 vestingTime; // Vesting time in seconds
        uint256 bondDiscount; // % of deposit in rewards (divisor 10000)
        uint256 minPrice; // minimum price in terms of RADAR/OTHER LP where bonds will be emmited
    }

    struct BondInfo {
        uint256 leftToVest; // how many seconds to full vesting
        uint256 updateTimestamp; // When was the bond created/updated
        uint256 payout; // payout in RADAR when fully vested
    }

    event BondCreated(address indexed owner, uint256 bondedAssets, uint256 payout, uint256 vestingDate);
    event BondRedeemed(address indexed owner, uint256 payoutRedeemed, uint256 payoutRemaining, uint256 vestingRemaining, bool tokensStaked);

    function getBondingTerms() external view returns (BondTerms memory);

    function getBond(address _owner) external view returns (BondInfo memory);

    function getTotalLPDeposited() external view returns (uint256);

    function getManager() external view returns (address);

    function getTreasury() external view returns (address);

    function getStaking() external view returns (address);

    function getPayoutAsset() external view returns (address);

    function getBondAsset() external view returns (address);

    function getMaxBondAmount() external view returns (uint256); 

    function estimateReward(uint256 _bondAssetAmount) external view returns (uint256);

    function getIsTrustedOrigin(address _origin) external view returns (bool);

    function bond(uint256 _amount, uint256 _minReward) external;

    function redeem(bool _stake) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRadarBondsTreasury {

    event BondDataUpdated(address bond, bool enabled, uint256 allowance, uint256 fee);
    event OwnershipPassed(address oldOwner, address newOwner);

    // Bond Functions

    function getReward(uint256 _rewardAmount) external returns (uint256);
    
    // State Getters
    function getOwner() external view returns (address);

    function getPendingOwner() external view returns (address);

    function getDAO() external view returns (address);

    function getToken() external view returns (address);

    function getIsRegisteredBond(address _bond) external view returns (bool);

    function getBondTokenAllowance(address _bond) external view returns (uint256);

    function getBondFee(address _bond) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRadarStaking {

    event RewardAdded(uint256 rewardAmount);
    event Staked(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);
    event GotReward(address indexed who, uint256 rewardAmount);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stake(uint256 amount, address target) external;

    function withdraw(uint256 amount) external;

    function exit() external;

    function getReward() external;
}