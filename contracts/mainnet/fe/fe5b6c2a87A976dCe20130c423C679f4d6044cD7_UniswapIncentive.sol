/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// hevm: flattened sources of ./contracts/token/UniswapIncentive.sol
pragma solidity >=0.4.0 >=0.5.0 >=0.6.2 >=0.6.0 <0.7.0 >=0.6.0 <0.8.0 >=0.6.2 <0.7.0 >=0.6.2 <0.8.0;
pragma experimental ABIEncoderV2;

////// ./contracts/core/IPermissions.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_5 {
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

////// ./contracts/token/IFei.sol
/* pragma solidity ^0.6.2; */

/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/token/ERC20/IERC20.sol"; */

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IFei is IERC20_5 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address account, address incentive) external;

    // ----------- Getters -----------

    function incentiveContract(address account) external view returns (address);
}

////// ./contracts/core/ICore.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./IPermissions.sol"; */
/* import "../token/IFei.sol"; */

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event FeiUpdate(address indexed _fei);
    event TribeUpdate(address indexed _tribe);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event TribeAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setFei(address token) external;

    function setTribe(address token) external;

    function setGenesisGroup(address _genesisGroup) external;

    function allocateTribe(address to, uint256 amount) external;

    // ----------- Genesis Group only state changing api -----------

    function completeGenesisGroup() external;

    // ----------- Getters -----------

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20_5);

    function genesisGroup() external view returns (address);

    function hasGenesisGroupCompleted() external view returns (bool);
}

////// ./contracts/external/SafeMathCopy.sol
// SPDX-License-Identifier: MIT

/* pragma solidity ^0.6.0; */

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
library SafeMathCopy { // To avoid namespace collision between openzeppelin safemath and uniswap safemath
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

////// ./contracts/external/Decimal.sol
/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./SafeMathCopy.sol"; */

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMathCopy for uint256;

    // ============ Constants ============

    uint256 private constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}
////// ./contracts/oracle/IOracle.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "../external/Decimal.sol"; */

/// @title generic oracle interface for Fei Protocol
/// @author Fei Protocol
interface IOracle {
    // ----------- Events -----------

    event Update(uint256 _peg);

    // ----------- State changing API -----------

    function update() external returns (bool);

    // ----------- Getters -----------

    function read() external view returns (Decimal.D256 memory, bool);

    function isOutdated() external view returns (bool);

}

////// ./contracts/refs/ICoreRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "../core/ICore.sol"; */

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed _core);

    // ----------- Governor only state changing api -----------

    function setCore(address core) external;

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20_5);

    function feiBalance() external view returns (uint256);

    function tribeBalance() external view returns (uint256);
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/Address.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.2 <0.8.0; */

/**
 * @dev Collection of functions related to the address type
 */
library Address_2 {
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

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context_2 {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/Pausable.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/* import "./Context.sol"; */

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable_2 is Context_2 {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

////// ./contracts/refs/CoreRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./ICoreRef.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/Pausable.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/Address.sol"; */

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable_2 {
    ICore private _core;

    /// @notice CoreRef constructor
    /// @param core Fei Core to reference
    constructor(address core) public {
        _core = ICore(core);
    }

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier ifBurnerSelf() {
        if (_core.isBurner(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) ||
            _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyFei() {
        require(msg.sender == address(fei()), "CoreRef: Caller is not FEI");
        _;
    }

    modifier onlyGenesisGroup() {
        require(
            msg.sender == _core.genesisGroup(),
            "CoreRef: Caller is not GenesisGroup"
        );
        _;
    }

    modifier postGenesis() {
        require(
            _core.hasGenesisGroupCompleted(),
            "CoreRef: Still in Genesis Period"
        );
        _;
    }

    modifier nonContract() {
        require(!Address_2.isContract(msg.sender), "CoreRef: Caller is a contract");
        _;
    }

    /// @notice set new Core reference address
    /// @param core the new core address
    function setCore(address core) external override onlyGovernor {
        _core = ICore(core);
        emit CoreUpdate(core);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function fei() public view override returns (IFei) {
        return _core.fei();
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function tribe() public view override returns (IERC20_5) {
        return _core.tribe();
    }

    /// @notice fei balance of contract
    /// @return fei amount held
    function feiBalance() public view override returns (uint256) {
        return fei().balanceOf(address(this));
    }

    /// @notice tribe balance of contract
    /// @return tribe amount held
    function tribeBalance() public view override returns (uint256) {
        return tribe().balanceOf(address(this));
    }

    function _burnFeiHeld() internal {
        fei().burn(feiBalance());
    }

    function _mintFei(uint256 amount) internal {
        fei().mint(address(this), amount);
    }
}

////// ./contracts/refs/IOracleRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "../oracle/IOracle.sol"; */

/// @title OracleRef interface
/// @author Fei Protocol
interface IOracleRef {
    // ----------- Events -----------

    event OracleUpdate(address indexed _oracle);

    // ----------- State changing API -----------

    function updateOracle() external returns (bool);

    // ----------- Governor only state changing API -----------

    function setOracle(address _oracle) external;

    // ----------- Getters -----------

    function oracle() external view returns (IOracle);

    function peg() external view returns (Decimal.D256 memory);

    function invert(Decimal.D256 calldata price)
        external
        pure
        returns (Decimal.D256 memory);
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol
/* pragma solidity >=0.5.0; */

interface IUniswapV2Pair_3 {
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

////// /home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
/* pragma solidity >=0.6.2; */

interface IUniswapV2Router01_2 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol
/* pragma solidity >=0.6.2; */

/* import './IUniswapV2Router01.sol'; */

interface IUniswapV2Router02_2 is IUniswapV2Router01_2 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

////// ./contracts/refs/IUniRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/token/ERC20/IERC20.sol"; */
/* import "../external/Decimal.sol"; */

/// @title UniRef interface
/// @author Fei Protocol
interface IUniRef {
    // ----------- Events -----------

    event PairUpdate(address indexed _pair);

    // ----------- Governor only state changing api -----------

    function setPair(address _pair) external;

    // ----------- Getters -----------

    function router() external view returns (IUniswapV2Router02_2);

    function pair() external view returns (IUniswapV2Pair_3);

    function token() external view returns (address);

    function getReserves()
        external
        view
        returns (uint256 feiReserves, uint256 tokenReserves);

    function deviationBelowPeg(
        Decimal.D256 calldata price,
        Decimal.D256 calldata peg
    ) external pure returns (Decimal.D256 memory);

    function liquidityOwned() external view returns (uint256);
}

////// ./contracts/refs/OracleRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./IOracleRef.sol"; */
/* import "./CoreRef.sol"; */

/// @title Reference to an Oracle
/// @author Fei Protocol
/// @notice defines some utilities around interacting with the referenced oracle
abstract contract OracleRef is IOracleRef, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice the oracle reference by the contract
    IOracle public override oracle;

    /// @notice OracleRef constructor
    /// @param _core Fei Core to reference
    /// @param _oracle oracle to reference
    constructor(address _core, address _oracle) public CoreRef(_core) {
        _setOracle(_oracle);
    }

    /// @notice sets the referenced oracle
    /// @param _oracle the new oracle to reference
    function setOracle(address _oracle) external override onlyGovernor {
        _setOracle(_oracle);
    }

    /// @notice invert a peg price
    /// @param price the peg price to invert
    /// @return the inverted peg as a Decimal
    /// @dev the inverted peg would be X per FEI
    function invert(Decimal.D256 memory price)
        public
        pure
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    /// @notice updates the referenced oracle
    /// @return true if the update is effective
    function updateOracle() public override returns (bool) {
        return oracle.update();
    }

    /// @notice the peg price of the referenced oracle
    /// @return the peg as a Decimal
    /// @dev the peg is defined as FEI per X with X being ETH, dollars, etc
    function peg() public view override returns (Decimal.D256 memory) {
        (Decimal.D256 memory _peg, bool valid) = oracle.read();
        require(valid, "OracleRef: oracle invalid");
        return _peg;
    }

    function _setOracle(address _oracle) internal {
        oracle = IOracle(_oracle);
        emit OracleUpdate(_oracle);
    }
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/math/SignedSafeMath.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath_2 {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/SafeCast.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast_2 {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/lib/contracts/libraries/Babylonian.sol
// SPDX-License-Identifier: GPL-3.0-or-later

/* pragma solidity >=0.4.0; */

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian_3 {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

////// ./contracts/refs/UniRef.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/math/SignedSafeMath.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/utils/SafeCast.sol"; */
/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/uniswap/lib/contracts/libraries/Babylonian.sol"; */
/* import "./OracleRef.sol"; */
/* import "./IUniRef.sol"; */

/// @title A Reference to Uniswap
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Uniswap
/// @dev the uniswap pair should be FEI and another asset
abstract contract UniRef is IUniRef, OracleRef {
    using Decimal for Decimal.D256;
    using Babylonian_3 for uint256;
    using SignedSafeMath_2 for int256;
    using SafeMathCopy for uint256;
    using SafeCast_2 for uint256;
    using SafeCast_2 for int256;

    /// @notice the Uniswap router contract
    IUniswapV2Router02_2 public override router;

    /// @notice the referenced Uniswap pair contract
    IUniswapV2Pair_3 public override pair;

    /// @notice UniRef constructor
    /// @param _core Fei Core to reference
    /// @param _pair Uniswap pair to reference
    /// @param _router Uniswap Router to reference
    /// @param _oracle oracle to reference
    constructor(
        address _core,
        address _pair,
        address _router,
        address _oracle
    ) public OracleRef(_core, _oracle) {
        _setupPair(_pair);

        router = IUniswapV2Router02_2(_router);

        _approveToken(address(fei()));
        _approveToken(token());
        _approveToken(_pair);
    }

    /// @notice set the new pair contract
    /// @param _pair the new pair
    /// @dev also approves the router for the new pair token and underlying token
    function setPair(address _pair) external override onlyGovernor {
        _setupPair(_pair);

        _approveToken(token());
        _approveToken(_pair);
    }

    /// @notice the address of the non-fei underlying token
    function token() public view override returns (address) {
        address token0 = pair.token0();
        if (address(fei()) == token0) {
            return pair.token1();
        }
        return token0;
    }

    /// @notice pair reserves with fei listed first
    /// @dev uses the max of pair fei balance and fei reserves. Mitigates attack vectors which manipulate the pair balance
    function getReserves()
        public
        view
        override
        returns (uint256 feiReserves, uint256 tokenReserves)
    {
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (feiReserves, tokenReserves) = address(fei()) == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return (feiReserves, tokenReserves);
    }

    /// @notice get deviation from peg as a percent given price
    /// @dev will return Decimal.zero() if above peg
    function deviationBelowPeg(
        Decimal.D256 calldata price,
        Decimal.D256 calldata peg
    ) external pure override returns (Decimal.D256 memory) {
        return _deviationBelowPeg(price, peg);
    }

    /// @notice amount of pair liquidity owned by this contract
    /// @return amount of LP tokens
    function liquidityOwned() public view override returns (uint256) {
        return pair.balanceOf(address(this));
    }

    /// @notice ratio of all pair liquidity owned by this contract
    function _ratioOwned() internal view returns (Decimal.D256 memory) {
        uint256 balance = liquidityOwned();
        uint256 total = pair.totalSupply();
        return Decimal.ratio(balance, total);
    }

    /// @notice returns true if price is below the peg
    /// @dev counterintuitively checks if peg < price because price is reported as FEI per X
    function _isBelowPeg(Decimal.D256 memory peg) internal view returns (bool) {
        (Decimal.D256 memory price, , ) = _getUniswapPrice();
        return peg.lessThan(price);
    }

    /// @notice approves a token for the router
    function _approveToken(address _token) internal {
        uint256 maxTokens = uint256(-1);
        IERC20_5(_token).approve(address(router), maxTokens);
    }

    function _setupPair(address _pair) internal {
        pair = IUniswapV2Pair_3(_pair);
        emit PairUpdate(_pair);
    }

    function _isPair(address account) internal view returns (bool) {
        return address(pair) == account;
    }

    /// @notice utility for calculating absolute distance from peg based on reserves
    /// @param reserveTarget pair reserves of the asset desired to trade with
    /// @param reserveOther pair reserves of the non-traded asset
    /// @param peg the target peg reported as Target per Other
    function _getAmountToPeg(
        uint256 reserveTarget,
        uint256 reserveOther,
        Decimal.D256 memory peg
    ) internal pure returns (uint256) {
        uint256 radicand = peg.mul(reserveTarget).mul(reserveOther).asUint256();
        uint256 root = radicand.sqrt();
        if (root > reserveTarget) {
            return (root - reserveTarget).mul(1000).div(997);
        }
        return (reserveTarget - root).mul(1000).div(997);
    }

    /// @notice calculate amount of Fei needed to trade back to the peg
    function _getAmountToPegFei(
        uint256 feiReserves,
        uint256 tokenReserves,
        Decimal.D256 memory peg
    ) internal pure returns (uint256) {
        return _getAmountToPeg(feiReserves, tokenReserves, peg);
    }

    /// @notice calculate amount of the not Fei token needed to trade back to the peg
    function _getAmountToPegOther(
        uint256 feiReserves,
        uint256 tokenReserves,
        Decimal.D256 memory peg
    ) internal pure returns (uint256) {
        return _getAmountToPeg(tokenReserves, feiReserves, invert(peg));
    }

    /// @notice get uniswap price and reserves
    /// @return price reported as Fei per X
    /// @return reserveFei fei reserves
    /// @return reserveOther non-fei reserves
    function _getUniswapPrice()
        internal
        view
        returns (
            Decimal.D256 memory,
            uint256 reserveFei,
            uint256 reserveOther
        )
    {
        (reserveFei, reserveOther) = getReserves();
        return (
            Decimal.ratio(reserveFei, reserveOther),
            reserveFei,
            reserveOther
        );
    }

    /// @notice get final uniswap price after hypothetical FEI trade
    /// @param amountFei a signed integer representing FEI trade. Positive=sell, negative=buy
    /// @param reserveFei fei reserves
    /// @param reserveOther non-fei reserves
    function _getFinalPrice(
        int256 amountFei,
        uint256 reserveFei,
        uint256 reserveOther
    ) internal pure returns (Decimal.D256 memory) {
        uint256 k = reserveFei.mul(reserveOther);
        int256 signedReservesFei = reserveFei.toInt256();
        int256 amountFeiWithFee = amountFei > 0 ? amountFei.mul(997).div(1000) : amountFei; // buys already have fee factored in on uniswap's other token side

        uint256 adjustedReserveFei = signedReservesFei.add(amountFeiWithFee).toUint256();
        uint256 adjustedReserveOther = k / adjustedReserveFei;
        return Decimal.ratio(adjustedReserveFei, adjustedReserveOther); // alt: adjustedReserveFei^2 / k
    }

    /// @notice return the percent distance from peg before and after a hypothetical trade
    /// @param amountIn a signed amount of FEI to be traded. Positive=sell, negative=buy
    /// @return initialDeviation the percent distance from peg before trade
    /// @return finalDeviation the percent distance from peg after hypothetical trade
    /// @dev deviations will return Decimal.zero() if above peg
    function _getPriceDeviations(int256 amountIn)
        internal
        view
        returns (
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation,
            Decimal.D256 memory _peg,
            uint256 feiReserves,
            uint256 tokenReserves
        )
    {
        _peg = peg();

        (Decimal.D256 memory price, uint256 reserveFei, uint256 reserveOther) =
            _getUniswapPrice();
        initialDeviation = _deviationBelowPeg(price, _peg);

        Decimal.D256 memory finalPrice =
            _getFinalPrice(amountIn, reserveFei, reserveOther);
        finalDeviation = _deviationBelowPeg(finalPrice, _peg);

        return (
            initialDeviation,
            finalDeviation,
            _peg,
            reserveFei,
            reserveOther
        );
    }

    /// @notice return current percent distance from peg
    /// @dev will return Decimal.zero() if above peg
    function _getDistanceToPeg()
        internal
        view
        returns (Decimal.D256 memory distance)
    {
        (Decimal.D256 memory price, , ) = _getUniswapPrice();
        return _deviationBelowPeg(price, peg());
    }

    /// @notice get deviation from peg as a percent given price
    /// @dev will return Decimal.zero() if above peg
    function _deviationBelowPeg(
        Decimal.D256 memory price,
        Decimal.D256 memory peg
    ) internal pure returns (Decimal.D256 memory) {
        // If price <= peg, then FEI is more expensive and above peg
        // In this case we can just return zero for deviation
        if (price.lessThanOrEqualTo(peg)) {
            return Decimal.zero();
        }
        Decimal.D256 memory delta = price.sub(peg, "Impossible underflow");
        return delta.div(peg);
    }
}

////// ./contracts/token/IIncentive.sol
/* pragma solidity ^0.6.2; */

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    // ----------- Fei only state changing api -----------

    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

////// ./contracts/token/IUniswapIncentive.sol
/* pragma solidity ^0.6.2; */
/* pragma experimental ABIEncoderV2; */

/* import "./IIncentive.sol"; */
/* import "../external/Decimal.sol"; */

/// @title UniswapIncentive interface
/// @author Fei Protocol
interface IUniswapIncentive is IIncentive {
    // ----------- Events -----------

    event TimeWeightUpdate(uint256 _weight, bool _active);

    event GrowthRateUpdate(uint256 _growthRate);

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    // ----------- Governor only state changing api -----------

    function setExemptAddress(address account, bool isExempt) external;

    function setTimeWeightGrowth(uint32 growthRate) external;

    function setTimeWeight(
        uint32 weight,
        uint32 growth,
        bool active
    ) external;

    // ----------- Getters -----------

    function isIncentiveParity() external view returns (bool);

    function isExemptAddress(address account) external view returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function TIME_WEIGHT_GRANULARITY() external view returns (uint32);

    function getGrowthRate() external view returns (uint32);

    function getTimeWeight() external view returns (uint32);

    function isTimeWeightActive() external view returns (bool);

    function getBuyIncentive(uint256 amount)
        external
        view
        returns (
            uint256 incentive,
            uint32 weight,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        );

    function getSellPenalty(uint256 amount)
        external
        view
        returns (
            uint256 penalty,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        );

    function getSellPenaltyMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view returns (Decimal.D256 memory);

    function getBuyIncentiveMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view returns (Decimal.D256 memory);
}

////// ./contracts/utils/SafeMath32.sol
// SPDX-License-Identifier: MIT

// SafeMath for 32 bit integers inspired by OpenZeppelin SafeMath
/* pragma solidity ^0.6.0; */

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
library SafeMath32 {
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
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
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
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

        return c;
    }
}

////// /home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/math/Math.sol
// SPDX-License-Identifier: MIT

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math_4 {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

////// ./contracts/token/UniswapIncentive.sol
/* pragma solidity ^0.6.0; */
/* pragma experimental ABIEncoderV2; */

/* import "/home/brock/git_pkgs/fei-protocol-core/contracts/openzeppelin/contracts/math/Math.sol"; */
/* import "./IUniswapIncentive.sol"; */
/* import "../utils/SafeMath32.sol"; */
/* import "../refs/UniRef.sol"; */

/// @title Uniswap trading incentive contract
/// @author Fei Protocol
/// @dev incentives are only appplied if the contract is appointed as a Minter or Burner, otherwise skipped
contract UniswapIncentive is IUniswapIncentive, UniRef {
    using Decimal for Decimal.D256;
    using SafeMath32 for uint32;
    using SafeMathCopy for uint256;

    struct TimeWeightInfo {
        uint32 blockNo;
        uint32 weight;
        uint32 growthRate;
        bool active;
    }

    TimeWeightInfo private timeWeightInfo;

    /// @notice the granularity of the time weight and growth rate
    uint32 public constant override TIME_WEIGHT_GRANULARITY = 100_000;

    mapping(address => bool) private _exempt;

    /// @notice UniswapIncentive constructor
    /// @param _core Fei Core to reference
    /// @param _oracle Oracle to reference
    /// @param _pair Uniswap Pair to incentivize
    /// @param _router Uniswap Router
    constructor(
        address _core,
        address _oracle,
        address _pair,
        address _router,
        uint32 _growthRate
    ) public UniRef(_core, _pair, _router, _oracle) {
        _setTimeWeight(0, _growthRate, false);
    }

    function incentivize(
        address sender,
        address receiver,
        address,
        uint256 amountIn
    ) external override onlyFei {
        require(sender != receiver, "UniswapIncentive: cannot send self");
        updateOracle();

        if (_isPair(sender)) {
            _incentivizeBuy(receiver, amountIn);
        }

        if (_isPair(receiver)) {
            _incentivizeSell(sender, amountIn);
        }
    }

    /// @notice set an address to be exempted from Uniswap trading incentives
    /// @param account the address to update
    /// @param isExempt a flag for whether to exempt or unexempt
    function setExemptAddress(address account, bool isExempt)
        external
        override
        onlyGovernor
    {
        _exempt[account] = isExempt;
        emit ExemptAddressUpdate(account, isExempt);
    }

    /// @notice set the time weight growth function
    function setTimeWeightGrowth(uint32 growthRate)
        external
        override
        onlyGovernor
    {
        TimeWeightInfo memory tw = timeWeightInfo;
        timeWeightInfo = TimeWeightInfo(
            tw.blockNo,
            tw.weight,
            growthRate,
            tw.active
        );
        emit GrowthRateUpdate(growthRate);
    }

    /// @notice sets all of the time weight parameters
    /// @param weight the stored last time weight
    /// @param growth the growth rate of the time weight per block
    /// @param active a flag signifying whether the time weight is currently growing or not
    function setTimeWeight(
        uint32 weight,
        uint32 growth,
        bool active
    ) external override onlyGovernor {
        _setTimeWeight(weight, growth, active);
    }

    /// @notice the growth rate of the time weight per block
    function getGrowthRate() public view override returns (uint32) {
        return timeWeightInfo.growthRate;
    }

    /// @notice the time weight of the current block
    /// @dev factors in the stored block number and growth rate if active
    function getTimeWeight() public view override returns (uint32) {
        TimeWeightInfo memory tw = timeWeightInfo;
        if (!tw.active) {
            return 0;
        }

        uint32 blockDelta = block.number.toUint32().sub(tw.blockNo);
        return tw.weight.add(blockDelta * tw.growthRate);
    }

    /// @notice returns true if time weight is active and growing at the growth rate
    function isTimeWeightActive() public view override returns (bool) {
        return timeWeightInfo.active;
    }

    /// @notice returns true if account is marked as exempt
    function isExemptAddress(address account)
        public
        view
        override
        returns (bool)
    {
        return _exempt[account];
    }

    /// @notice return true if burn incentive equals mint
    function isIncentiveParity() public view override returns (bool) {
        uint32 weight = getTimeWeight();
        if (weight == 0) {
            return false;
        }

        (Decimal.D256 memory price, , ) = _getUniswapPrice();
        Decimal.D256 memory deviation = _deviationBelowPeg(price, peg());
        if (deviation.equals(Decimal.zero())) {
            return false;
        }

        Decimal.D256 memory incentive = _calculateBuyIncentiveMultiplier(deviation, deviation, weight);
        Decimal.D256 memory penalty = _calculateSellPenaltyMultiplier(deviation);
        return incentive.equals(penalty);
    }

    /// @notice get the incentive amount of a buy transfer
    /// @param amount the FEI size of the transfer
    /// @return incentive the FEI size of the mint incentive
    /// @return weight the time weight of thhe incentive
    /// @return _initialDeviation the Decimal deviation from peg before a transfer
    /// @return _finalDeviation the Decimal deviation from peg after a transfer
    /// @dev calculated based on a hypothetical buy, applies to any ERC20 FEI transfer from the pool
    function getBuyIncentive(uint256 amount)
        public
        view
        override
        returns (
            uint256 incentive,
            uint32 weight,
            Decimal.D256 memory _initialDeviation,
            Decimal.D256 memory _finalDeviation
        )
    {
        int256 signedAmount = amount.toInt256();
        // A buy withdraws FEI from uni so use negative amountIn
        (
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation,
            Decimal.D256 memory peg,
            uint256 reserveFei,
            uint256 reserveOther
        ) = _getPriceDeviations(
            -1 * signedAmount
        );
        weight = getTimeWeight();

        // buy started above peg
        if (initialDeviation.equals(Decimal.zero())) {
            return (0, weight, initialDeviation, finalDeviation);
        }

        uint256 incentivizedAmount = amount;
        // if buy ends above peg, only incentivize amount to peg
        if (finalDeviation.equals(Decimal.zero())) {
            incentivizedAmount = _getAmountToPegFei(reserveFei, reserveOther, peg);
        }

        Decimal.D256 memory multiplier =
            _calculateBuyIncentiveMultiplier(initialDeviation, finalDeviation, weight);
        incentive = multiplier.mul(incentivizedAmount).asUint256();
        return (incentive, weight, initialDeviation, finalDeviation);
    }

    /// @notice get the burn amount of a sell transfer
    /// @param amount the FEI size of the transfer
    /// @return penalty the FEI size of the burn incentive
    /// @return _initialDeviation the Decimal deviation from peg before a transfer
    /// @return _finalDeviation the Decimal deviation from peg after a transfer
    /// @dev calculated based on a hypothetical sell, applies to any ERC20 FEI transfer to the pool
    function getSellPenalty(uint256 amount)
        public
        view
        override
        returns (
            uint256 penalty,
            Decimal.D256 memory _initialDeviation,
            Decimal.D256 memory _finalDeviation
        )
    {
        int256 signedAmount = amount.toInt256();

        (
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation,
            Decimal.D256 memory peg,
            uint256 reserveFei,
            uint256 reserveOther
        ) = _getPriceDeviations(signedAmount);

        // if trafe ends above peg, it was always above peg and no penalty needed
        if (finalDeviation.equals(Decimal.zero())) {
            return (0, initialDeviation, finalDeviation);
        }

        uint256 incentivizedAmount = amount;
        // if trade started above but ended below, only penalize amount going below peg
        if (initialDeviation.equals(Decimal.zero())) {
            uint256 amountToPeg = _getAmountToPegFei(reserveFei, reserveOther, peg);
            incentivizedAmount = amount.sub(
                amountToPeg,
                "UniswapIncentive: Underflow"
            );
        }

        Decimal.D256 memory multiplier =
            _calculateIntegratedSellPenaltyMultiplier(initialDeviation, finalDeviation);
        penalty = multiplier.mul(incentivizedAmount).asUint256();
        return (penalty, initialDeviation, finalDeviation);
    }

    /// @notice returns the multiplier used to calculate the sell penalty
    /// @param initialDeviation the percent from peg at start of trade
    /// @param finalDeviation the percent from peg at the end of trade
    function getSellPenaltyMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view override returns (Decimal.D256 memory) {
        return _calculateIntegratedSellPenaltyMultiplier(initialDeviation, finalDeviation);
    }

    /// @notice returns the multiplier used to calculate the buy reward
    /// @param initialDeviation the percent from peg at start of trade
    /// @param finalDeviation the percent from peg at the end of trade
    function getBuyIncentiveMultiplier(
        Decimal.D256 calldata initialDeviation,
        Decimal.D256 calldata finalDeviation
    ) external view override returns (Decimal.D256 memory) {
        return _calculateBuyIncentiveMultiplier(initialDeviation, finalDeviation, getTimeWeight());
    }

    function _incentivizeBuy(address target, uint256 amountIn)
        internal
        ifMinterSelf
    {
        if (isExemptAddress(target)) {
            return;
        }

        (
            uint256 incentive,
            uint32 weight,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        ) = getBuyIncentive(amountIn);

        _updateTimeWeight(initialDeviation, finalDeviation, weight);
        if (incentive != 0) {
            fei().mint(target, incentive);
        }
    }

    function _incentivizeSell(address target, uint256 amount)
        internal
        ifBurnerSelf
    {
        if (isExemptAddress(target)) {
            return;
        }

        (
            uint256 penalty,
            Decimal.D256 memory initialDeviation,
            Decimal.D256 memory finalDeviation
        ) = getSellPenalty(amount);

        uint32 weight = getTimeWeight();
        _updateTimeWeight(initialDeviation, finalDeviation, weight);

        if (penalty != 0) {
            require(penalty < amount, "UniswapIncentive: Burn exceeds trade size");
            fei().burnFrom(address(pair), penalty); // burn from the recipient which is the pair
        }
    }

    function _calculateBuyIncentiveMultiplier(
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint32 weight
    ) internal pure returns (Decimal.D256 memory) {
        Decimal.D256 memory correspondingPenalty =
            _calculateIntegratedSellPenaltyMultiplier(finalDeviation, initialDeviation); // flip direction
        Decimal.D256 memory buyMultiplier =
            initialDeviation.mul(uint256(weight)).div(
                uint256(TIME_WEIGHT_GRANULARITY)
            );

        if (correspondingPenalty.lessThan(buyMultiplier)) {
            return correspondingPenalty;
        }

        return buyMultiplier;
    }

    // The sell penalty smoothed over the curve
    function _calculateIntegratedSellPenaltyMultiplier(Decimal.D256 memory initialDeviation, Decimal.D256 memory finalDeviation)
        internal
        pure
        returns (Decimal.D256 memory)
    {
        if (initialDeviation.equals(finalDeviation)) {
            return _calculateSellPenaltyMultiplier(initialDeviation);
        }
        Decimal.D256 memory numerator = _sellPenaltyBound(finalDeviation).sub(_sellPenaltyBound(initialDeviation));
        Decimal.D256 memory denominator = finalDeviation.sub(initialDeviation);

        Decimal.D256 memory multiplier = numerator.div(denominator);
        if (multiplier.greaterThan(Decimal.one())) {
            return Decimal.one();
        }
        return multiplier;
    }

    function _sellPenaltyBound(Decimal.D256 memory deviation)
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return deviation.pow(3).mul(33);
    }

    function _calculateSellPenaltyMultiplier(Decimal.D256 memory deviation)
        internal
        pure
        returns (Decimal.D256 memory)
    {
        Decimal.D256 memory multiplier = deviation.mul(deviation).mul(100); // m^2 * 100
        if (multiplier.greaterThan(Decimal.one())) {
            return Decimal.one();
        }
        return multiplier;
    }

    function _updateTimeWeight(
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint32 currentWeight
    ) internal {
        // Reset when trade ends above peg
        if (finalDeviation.equals(Decimal.zero())) {
            _setTimeWeight(0, getGrowthRate(), false);
            return;
        }
        // when trade starts above peg but ends below, activate time weight
        if (initialDeviation.equals(Decimal.zero())) {
            _setTimeWeight(0, getGrowthRate(), true);
            return;
        }

        // when trade starts and ends below the peg, update the values
        uint256 updatedWeight = uint256(currentWeight);
        // Partial buy should update time weight
        if (initialDeviation.greaterThan(finalDeviation)) {
            Decimal.D256 memory remainingRatio =
                finalDeviation.div(initialDeviation);
            updatedWeight = remainingRatio
                .mul(uint256(currentWeight))
                .asUint256();
        }

        // cap incentive at max penalty
        uint256 maxWeight =
            finalDeviation
                .mul(100)
                .mul(uint256(TIME_WEIGHT_GRANULARITY))
                .asUint256(); // m^2*100 (sell) = t*m (buy)
        updatedWeight = Math_4.min(updatedWeight, maxWeight);
        _setTimeWeight(updatedWeight.toUint32(), getGrowthRate(), true);
    }

    function _setTimeWeight(
        uint32 weight,
        uint32 growthRate,
        bool active
    ) internal {
        uint32 currentGrowth = getGrowthRate();

        uint32 blockNo = block.number.toUint32();

        timeWeightInfo = TimeWeightInfo(blockNo, weight, growthRate, active);

        emit TimeWeightUpdate(weight, active);
        if (currentGrowth != growthRate) {
            emit GrowthRateUpdate(growthRate);
        }
    }
}