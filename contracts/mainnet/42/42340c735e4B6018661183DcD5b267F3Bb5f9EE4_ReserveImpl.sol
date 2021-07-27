/*
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Decimal.sol";

/**
 * @title IManagedToken
 * @notice Generic interface for ERC20 tokens that can be minted and burned by their owner
 * @dev Used by Dollar and Stake in this protocol
 */
interface IManagedToken {

    /**
     * @notice Mints `amount` tokens to the {owner}
     * @param amount Amount of token to mint
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns `amount` tokens from the {owner}
     * @param amount Amount of token to burn
     */
    function mint(uint256 amount) external;
}

/**
 * @title IGovToken
 * @notice Generic interface for ERC20 tokens that have Compound-governance features
 * @dev Used by Stake and other compatible reserve-held tokens
 */
interface IGovToken {

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external;
}

/**
 * @title IReserve
 * @notice Interface for the protocol reserve
 */
interface IReserve {
    /**
     * @notice The price that one ESD can currently be sold to the reserve for
     * @dev Returned as a Decimal.D256
     *      Normalizes for decimals (e.g. 1.00 USDC == Decimal.one())
     * @return Current ESD redemption price
     */
    function redeemPrice() external view returns (Decimal.D256 memory);
}

interface IRegistry {
    /**
     * @notice USDC token contract
     */
    function usdc() external view returns (address);

    /**
     * @notice Compound protocol cUSDC pool
     */
    function cUsdc() external view returns (address);

    /**
     * @notice ESD stablecoin contract
     */
    function dollar() external view returns (address);

    /**
     * @notice ESDS governance token contract
     */
    function stake() external view returns (address);

    /**
     * @notice ESD reserve contract
     */
    function reserve() external view returns (address);

    /**
     * @notice ESD governor contract
     */
    function governor() external view returns (address);

    /**
     * @notice ESD timelock contract, owner for the protocol
     */
    function timelock() external view returns (address);

    /**
     * @notice Migration contract to bride v1 assets with current system
     */
    function migrator() external view returns (address);

    /**
     * @notice Registers a new address for USDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setUsdc(address newValue) external;

    /**
     * @notice Registers a new address for cUSDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setCUsdc(address newValue) external;

    /**
     * @notice Registers a new address for ESD
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setDollar(address newValue) external;

    /**
     * @notice Registers a new address for ESDS
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setStake(address newValue) external;

    /**
     * @notice Registers a new address for the reserve
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setReserve(address newValue) external;

    /**
     * @notice Registers a new address for the governor
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setGovernor(address newValue) external;

    /**
     * @notice Registers a new address for the timelock
     * @dev Owner only - governance hook
     *      Does not automatically update the owner of all owned protocol contracts
     * @param newValue New address to register
     */
    function setTimelock(address newValue) external;

    /**
     * @notice Registers a new address for the v1 migration contract
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setMigrator(address newValue) external;
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "../Interfaces.sol";

/**
 * @title Implementation
 * @notice Common functions and accessors across upgradeable, ownable contracts
 */
contract Implementation {

    /**
     * @notice Emitted when {owner} is updated with `newOwner`
     */
    event OwnerUpdate(address newOwner);

    /**
     * @notice Emitted when {registry} is updated with `newRegistry`
     */
    event RegistryUpdate(address newRegistry);

    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
     */
    bytes32 private constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant OWNER_SLOT = keccak256("emptyset.v2.implementation.owner");

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant REGISTRY_SLOT = keccak256("emptyset.v2.implementation.registry");

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant NOT_ENTERED_SLOT = keccak256("emptyset.v2.implementation.notEntered");

    // UPGRADEABILITY

    /**
     * @notice Returns the current implementation
     * @return Address of the current implementation
     */
    function implementation() external view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Returns the current proxy admin contract
     * @return Address of the current proxy admin contract
     */
    function admin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    // REGISTRY

    /**
     * @notice Updates the registry contract
     * @dev Owner only - governance hook
     *      If registry is already set, the new registry's timelock must match the current's
     * @param newRegistry New registry contract
     */
    function setRegistry(address newRegistry) external onlyOwner {
        IRegistry registry = registry();

        // New registry must have identical owner
        require(newRegistry != address(0), "Implementation: zero address");
        require(
            (address(registry) == address(0) && Address.isContract(newRegistry)) ||
                IRegistry(newRegistry).timelock() == registry.timelock(),
            "Implementation: timelocks must match"
        );

        _setRegistry(newRegistry);

        emit RegistryUpdate(newRegistry);
    }

    /**
     * @notice Updates the registry contract
     * @dev Internal only
     * @param newRegistry New registry contract
     */
    function _setRegistry(address newRegistry) internal {
        bytes32 position = REGISTRY_SLOT;
        assembly {
            sstore(position, newRegistry)
        }
    }

    /**
     * @notice Returns the current registry contract
     * @return Address of the current registry contract
     */
    function registry() public view returns (IRegistry reg) {
        bytes32 slot = REGISTRY_SLOT;
        assembly {
            reg := sload(slot)
        }
    }

    // OWNER

    /**
     * @notice Takes ownership over a contract if none has been set yet
     * @dev Needs to be called initialize ownership after deployment
     *      Ensure that this has been properly set before using the protocol
     */
    function takeOwnership() external {
        require(owner() == address(0), "Implementation: already initialized");

        _setOwner(msg.sender);

        emit OwnerUpdate(msg.sender);
    }

    /**
     * @notice Updates the owner contract
     * @dev Owner only - governance hook
     * @param newOwner New owner contract
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(this), "Implementation: this");
        require(Address.isContract(newOwner), "Implementation: not contract");

        _setOwner(newOwner);

        emit OwnerUpdate(newOwner);
    }

    /**
     * @notice Updates the owner contract
     * @dev Internal only
     * @param newOwner New owner contract
     */
    function _setOwner(address newOwner) internal {
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }

    /**
     * @notice Owner contract with admin permission over this contract
     * @return Owner contract
     */
    function owner() public view returns (address o) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            o := sload(slot)
        }
    }

    /**
     * @dev Only allow when the caller is the owner address
     */
    modifier onlyOwner {
        require(msg.sender == owner(), "Implementation: not owner");

        _;
    }

    // NON REENTRANT

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(notEntered(), "Implementation: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(true);
    }

    /**
     * @notice The entered status of the current call
     * @return entered status
     */
    function notEntered() internal view returns (bool ne) {
        bytes32 slot = NOT_ENTERED_SLOT;
        assembly {
            ne := sload(slot)
        }
    }

    /**
     * @notice Updates the entered status of the current call
     * @dev Internal only
     * @param newNotEntered New entered status
     */
    function _setNotEntered(bool newNotEntered) internal {
        bytes32 position = NOT_ENTERED_SLOT;
        assembly {
            sstore(position, newNotEntered)
        }
    }

    // SETUP

    /**
     * @notice Hook to surface arbitrary logic to be called after deployment by owner
     * @dev Governance hook
     *      Does not ensure that it is only called once because it is permissioned to governance only
     */
    function setup() external onlyOwner {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _setNotEntered(true);
        _setup();
    }

    /**
     * @notice Override to provide addition setup logic per implementation
     */
    function _setup() internal { }
}

/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020, 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @notice Library that defines a fixed-point number with 18 decimal places.
 *
 * audit-info: Extended from dYdX's Decimal library:
 *             https://github.com/dydxprotocol/solo/blob/master/contracts/protocol/lib/Decimal.sol
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    /**
     * @notice Fixed-point base for Decimal.D256 values
     */
    uint256 constant BASE = 10**18;

    // ============ Structs ============


    /**
     * @notice Main struct to hold Decimal.D256 state
     * @dev Represents the number value / BASE
     */
    struct D256 {
        /**
         * @notice Underlying value of the Decimal.D256
         */
        uint256 value;
    }

    // ============ Static Functions ============

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 0.0
     * @return Decimal.D256 representation of 0.0
     */
    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent 1.0
     * @return Decimal.D256 representation of 1.0
     */
    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a`
     * @param a Integer to transform to Decimal.D256 type
     * @return Decimal.D256 representation of integer`a`
     */
    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    /**
     * @notice Returns a new Decimal.D256 struct initialized to represent `a` / `b`
     * @param a Numerator of ratio to transform to Decimal.D256 type
     * @param b Denominator of ratio to transform to Decimal.D256 type
     * @return Decimal.D256 representation of ratio `a` / `b`
     */
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

    /**
     * @notice Adds integer `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to add to `self`
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts integer `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Integer to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        uint256 amount = b.mul(BASE);
        return D256({ value: self.value > amount ? self.value.sub(amount) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to multiply `self` by
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Divides Decimal.D256 `self` by integer `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Integer to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b, reason) });
    }

    /**
     * @notice Exponentiates Decimal.D256 `self` to the power of integer `b`
     * @dev Not optimized - is only suitable to use with small exponents
     * @param self Original Decimal.D256 number
     * @param b Integer exponent
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Adds Decimal.D256 `b` to Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to add to `self`
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @dev Reverts on underflow with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Subtracts Decimal.D256 `b` from Decimal.D256 `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to subtract from `self`
     * @return 0 on underflow, or the Resulting Decimal.D256
     */
    function subOrZero(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value > b.value ? self.value.sub(b.value) : 0 });
    }

    /**
     * @notice Multiplies Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to multiply `self` by
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @return Resulting Decimal.D256
     */
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

    /**
     * @notice Divides Decimal.D256 `self` by Decimal.D256 `b`
     * @dev Reverts on divide-by-zero with reason `reason`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to divide `self` by
     * @param reason Revert reason
     * @return Resulting Decimal.D256
     */
    function div(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value, reason) });
    }

    /**
     * @notice Checks if `b` is equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is equal to `self`
     */
    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    /**
     * @notice Checks if `b` is greater than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than `self`
     */
    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    /**
     * @notice Checks if `b` is less than `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than `self`
     */
    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    /**
     * @notice Checks if `b` is greater than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is greater than or equal to `self`
     */
    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    /**
     * @notice Checks if `b` is less than or equal to `self`
     * @param self Original Decimal.D256 number
     * @param b Decimal.D256 to compare
     * @return Whether `b` is less than or equal to `self`
     */
    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    /**
     * @notice Checks if `self` is equal to 0
     * @param self Original Decimal.D256 number
     * @return Whether `self` is equal to 0
     */
    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    /**
     * @notice Truncates the decimal part of `self` and returns the integer value as a uint256
     * @param self Original Decimal.D256 number
     * @return Truncated Integer value as a uint256
     */
    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ General Math ============

    /**
     * @notice Determines the minimum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting minimum Decimal.D256
     */
    function min(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return lessThan(a, b) ? a : b;
    }

    /**
     * @notice Determines the maximum of `a` and `b`
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return Resulting maximum Decimal.D256
     */
    function max(D256 memory a, D256 memory b) internal pure returns (Decimal.D256 memory) {
        return greaterThan(a, b) ? a : b;
    }

    // ============ Core Methods ============

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @return Resulting Decimal.D256 number
     */
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

    /**
     * @notice Multiplies `target` by ratio `numerator` / `denominator`
     * @dev Internal only - helper
     *      Reverts on divide-by-zero with reason `reason`
     * @param target Original Integer number
     * @param numerator Integer numerator of ratio
     * @param denominator Integer denominator of ratio
     * @param reason Revert reason
     * @return Resulting Decimal.D256 number
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator,
        string memory reason
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator, reason);
    }

    /**
     * @notice Compares Decimal.D256 `a` to Decimal.D256 `b`
     * @dev Internal only - helper
     * @param a First Decimal.D256 number to compare
     * @param b Second Decimal.D256 number to compare
     * @return 0 if a < b, 1 if a == b, 2 if a > b
     */
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

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";

/**
 * @title TimeUtils
 * @notice Library that accompanies Decimal to convert unix time into Decimal.D256 values
 */
library TimeUtils {
    /**
     * @notice Number of seconds in a single day
     */
    uint256 private constant SECONDS_IN_DAY = 86400;

    /**
     * @notice Converts an integer number of seconds to a Decimal.D256 amount of days
     * @param s Number of seconds to convert
     * @return Equivalent amount of days as a Decimal.D256
     */
    function secondsToDays(uint256 s) internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(s, SECONDS_IN_DAY);
    }
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../Interfaces.sol";
import "../lib/Decimal.sol";
import "../lib/TimeUtils.sol";
import "./ReserveState.sol";
import "./ReserveVault.sol";

/**
 * @title ReserveComptroller
 * @notice Reserve accounting logic for managing the ESD stablecoin.
 */
contract ReserveComptroller is ReserveAccessors, ReserveVault {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when `account` purchases `mintAmount` ESD from the reserve for `costAmount` USDC
     */
    event Mint(address indexed account, uint256 mintAmount, uint256 costAmount);

    /**
     * @notice Emitted when `account` sells `costAmount` ESD to the reserve for `redeemAmount` USDC
     */
    event Redeem(address indexed account, uint256 costAmount, uint256 redeemAmount);

    /**
     * @notice Helper constant to convert ESD to USDC and vice versa
     */
    uint256 private constant USDC_DECIMAL_DIFF = 1e12;

    // EXTERNAL

    /**
     * @notice The total value of the reserve-owned assets denominated in USDC
     * @return Reserve total value
     */
    function reserveBalance() public view returns (uint256) {
        uint256 internalBalance = _balanceOf(registry().usdc(), address(this));
        uint256 vaultBalance = _balanceOfVault();
        return internalBalance.add(vaultBalance);
    }

    /**
     * @notice The ratio of the {reserveBalance} to total ESD issuance
     * @dev Assumes 1 ESD = 1 USDC, normalizing for decimals
     * @return Reserve ratio
     */
    function reserveRatio() public view returns (Decimal.D256 memory) {
        uint256 issuance = _totalSupply(registry().dollar());
        return issuance == 0 ? Decimal.one() : Decimal.ratio(_fromUsdcAmount(reserveBalance()), issuance);
    }

    /**
     * @notice The price that one ESD can currently be sold to the reserve for
     * @dev Returned as a Decimal.D256
     *      Normalizes for decimals (e.g. 1.00 USDC == Decimal.one())
     *      Equivalent to the current reserve ratio less the current redemption tax (if any)
     * @return Current ESD redemption price
     */
    function redeemPrice() public view returns (Decimal.D256 memory) {
        return Decimal.min(reserveRatio(), Decimal.one());
    }

    /**
     * @notice Mints `amount` ESD to the caller in exchange for an equivalent amount of USDC
     * @dev Non-reentrant
     *      Normalizes for decimals
     *      Caller must approve reserve to transfer USDC
     * @param amount Amount of ESD to mint
     */
    function mint(uint256 amount) external nonReentrant {
        uint256 costAmount = _toUsdcAmount(amount);

        // Take the ceiling to ensure no "free" ESD is minted
        costAmount = _fromUsdcAmount(costAmount) == amount ? costAmount : costAmount.add(1);

        _transferFrom(registry().usdc(), msg.sender, address(this), costAmount);
        _supplyVault(costAmount);
        _mintDollar(msg.sender, amount);

        emit Mint(msg.sender, amount, costAmount);
    }

    /**
     * @notice Burns `amount` ESD from the caller in exchange for USDC at the rate of {redeemPrice}
     * @dev Non-reentrant
     *      Normalizes for decimals
     *      Caller must approve reserve to transfer ESD
     * @param amount Amount of ESD to mint
     */
    function redeem(uint256 amount) external nonReentrant {
        uint256 redeemAmount = _toUsdcAmount(redeemPrice().mul(amount).asUint256());

        _transferFrom(registry().dollar(), msg.sender, address(this), amount);
        _burnDollar(amount);
        _redeemVault(redeemAmount);
        _transfer(registry().usdc(), msg.sender, redeemAmount);

        emit Redeem(msg.sender, amount, redeemAmount);
    }

    // INTERNAL

    /**
     * @notice Mints `amount` ESD to `account`
     * @dev Internal only
     * @param account Account to receive minted ESD
     * @param amount Amount of ESD to mint
     */
    function _mintDollar(address account, uint256 amount) internal {
        address dollar = registry().dollar();

        IManagedToken(dollar).mint(amount);
        IERC20(dollar).safeTransfer(account, amount);
    }

    /**
     * @notice Burns `amount` ESD held by the reserve
     * @dev Internal only
     * @param amount Amount of ESD to burn
     */
    function _burnDollar(uint256 amount) internal {
        IManagedToken(registry().dollar()).burn(amount);
    }

    /**
     * @notice `token` balance of `account`
     * @dev Internal only
     * @param token Token to get the balance for
     * @param account Account to get the balance of
     */
    function _balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    /**
     * @notice Total supply of `token`
     * @dev Internal only
     * @param token Token to get the total supply of
     */
    function _totalSupply(address token) internal view returns (uint256) {
        return IERC20(token).totalSupply();
    }

    /**
     * @notice Safely transfers `amount` `token` from the caller to `receiver`
     * @dev Internal only
     * @param token Token to transfer
     * @param receiver Account to receive the tokens
     * @param amount Amount to transfer
     */
    function _transfer(address token, address receiver, uint256 amount) internal {
        IERC20(token).safeTransfer(receiver, amount);
    }

    /**
     * @notice Safely transfers `amount` `token` from the `sender` to `receiver`
     * @dev Internal only
            Requires `amount` allowance from `sender` for caller
     * @param token Token to transfer
     * @param sender Account to send the tokens
     * @param receiver Account to receive the tokens
     * @param amount Amount to transfer
     */
    function _transferFrom(address token, address sender, address receiver, uint256 amount) internal {
        IERC20(token).safeTransferFrom(sender, receiver, amount);
    }

    /**
     * @notice Converts ESD amount to USDC amount
     * @dev Private only
     *      Converts an 18-decimal ERC20 amount to a 6-decimals ERC20 amount
     * @param dec18Amount 18-decimal ERC20 amount
     * @return 6-decimals ERC20 amount
     */
    function _toUsdcAmount(uint256 dec18Amount) internal pure returns (uint256) {
        return dec18Amount.div(USDC_DECIMAL_DIFF);
    }

    /**
     * @notice Convert USDC amount to ESD amount
     * @dev Private only
     *      Converts a 6-decimal ERC20 amount to an 18-decimals ERC20 amount
     * @param usdcAmount 6-decimal ERC20 amount
     * @return 18-decimals ERC20 amount
     */
    function _fromUsdcAmount(uint256 usdcAmount) internal pure returns (uint256) {
        return usdcAmount.mul(USDC_DECIMAL_DIFF);
    }
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ReserveSwapper.sol";
import "../common/Implementation.sol";
import "./ReserveIssuer.sol";

/**
 * @title ReserveImpl
 * @notice Top-level Reserve contract that extends all other reserve sub-contracts
 * @dev This contract should be used an implementation contract for an AdminUpgradeabilityProxy
 */
contract ReserveImpl is IReserve, ReserveComptroller, ReserveIssuer, ReserveSwapper { }

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../Interfaces.sol";
import "./ReserveState.sol";

/**
 * @title ReserveIssuer
 * @notice Logic to manage the supply of ESDS
 */
contract ReserveIssuer is ReserveAccessors {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /**
      * @notice Emitted when `account` mints `amount` of ESDS
      */
    event MintStake(address account, uint256 mintAmount);

    /**
      * @notice Emitted when `amount` of ESDS is burned from the reserve
      */
    event BurnStake(uint256 burnAmount);

    /**
     * @notice Mints new ESDS tokens to a specified `account`
     * @dev Non-reentrant
     *      Owner only - governance hook
     *      ESDS maxes out at ~79b total supply (2^96/10^18) due to its 96-bit limitation
     *      Will revert if totalSupply exceeds this maximum
     * @param account Account to mint ESDS to
     * @param amount Amount of ESDS to mint
     */
    function mintStake(address account, uint256 amount) public onlyOwner {
        address stake = registry().stake();

        IManagedToken(stake).mint(amount);
        IERC20(stake).safeTransfer(account, amount);

        emit MintStake(account, amount);
    }

    /**
     * @notice Burns all reserve-held ESDS tokens
     * @dev Non-reentrant
     *      Owner only - governance hook
     */
    function burnStake() public onlyOwner {
        address stake = registry().stake();

        uint256 stakeBalance = IERC20(stake).balanceOf(address(this));
        IManagedToken(stake).burn(stakeBalance);

        emit BurnStake(stakeBalance);
    }
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../lib/Decimal.sol";
import "../common/Implementation.sol";

/**
 * @title ReserveTypes
 * @notice Contains all reserve state structs
 */
contract ReserveTypes {

    /**
     * @notice Stores state for a single order
     */
    struct Order {
        /**
         * @notice price (takerAmount per makerAmount) for the order as a Decimal
         */
        Decimal.D256 price;

        /**
         * @notice total available amount of the maker token
         */
        uint256 amount;
    }

    /**
     * @notice Stores state for the entire reserve
     */
    struct State {

        /**
         * @notice Mapping of all registered limit orders
         */
        mapping(address => mapping(address => ReserveTypes.Order)) orders;
    }
}

/**
 * @title ReserveState
 * @notice Reserve state
 */
contract ReserveState {

    /**
     * @notice Entirety of the reserve contract state
     * @dev To upgrade state, append additional state variables at the end of this contract
     */
    ReserveTypes.State internal _state;
}

/**
 * @title ReserveAccessors
 * @notice Reserve state accessor helpers
 */
contract ReserveAccessors is Implementation, ReserveState {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    // SWAPPER

    /**
     * @notice Full state of the `makerToken`-`takerToken` order
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @return Specified order
     */
    function order(address makerToken, address takerToken) public view returns (ReserveTypes.Order memory) {
        return _state.orders[makerToken][takerToken];
    }

    /**
     * @notice Sets the `price` and `amount` of the specified `makerToken`-`takerToken` order
     * @dev Internal only
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param price Price as a ratio of takerAmount:makerAmount times 10^18
     * @param amount Amount to decrement in ESD
     */
    function _updateOrder(address makerToken, address takerToken, uint256 price, uint256 amount) internal {
        _state.orders[makerToken][takerToken] = ReserveTypes.Order({price: Decimal.D256({value: price}), amount: amount});
    }

    /**
     * @notice Decrements the available amount of the specified `makerToken`-`takerToken` order
     * @dev Internal only
            Reverts when insufficient amount with reason `reason`
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param amount Amount to decrement in ESD
     * @param reason revert reason
     */
    function _decrementOrderAmount(address makerToken, address takerToken, uint256 amount, string memory reason) internal {
        _state.orders[makerToken][takerToken].amount = _state.orders[makerToken][takerToken].amount.sub(amount, reason);
    }
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ReserveComptroller.sol";

/**
 * @title ReserveSwapper
 * @notice Logic for managing outstanding reserve limit orders.
 *         Since the reserve is autonomous, it cannot use traditional DEXs without being front-run. The `ReserveSwapper`
 *         allows governance to place outstanding limit orders selling reserve assets in exchange for assets the reserve
 *         wishes to purchase. This is the main mechanism by which the reserve may diversify itself, or buy back ESDS
 *         using generated rewards.
 */
contract ReserveSwapper is ReserveComptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when `amount` of the `makerToken`-`takerToken` order is registered with price `price`
     */
    event OrderRegistered(address indexed makerToken, address indexed takerToken, uint256 price, uint256 amount);

    /**
     * @notice Emitted when the reserve pays `takerAmount` of `takerToken` in exchange for `makerAmount` of `makerToken`
     */
    event Swap(address indexed makerToken, address indexed takerToken, uint256 takerAmount, uint256 makerAmount);

    /**
     * @notice Sets the `price` and `amount` of the specified `makerToken`-`takerToken` order
     * @dev Owner only - governance hook
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param price Price as a ratio of takerAmount:makerAmount times 10^18
     * @param amount Amount of the makerToken that reserve wishes to sell - uint256(-1) indicates all reserve funds
     */
    function registerOrder(address makerToken, address takerToken, uint256 price, uint256 amount) external onlyOwner {
        _updateOrder(makerToken, takerToken, price, amount);

        emit OrderRegistered(makerToken, takerToken, price, amount);
    }

    /**
     * @notice Purchases `makerToken` from the reserve in exchange for `takerAmount` of `takerToken`
     * @dev Non-reentrant
     *      Uses the state-defined price for the `makerToken`-`takerToken` order
     *      Maker and taker tokens must be different
     *      Cannot swap ESD
     * @param makerToken Token that the caller wishes to buy
     * @param takerToken Token that the caller wishes to sell
     * @param takerAmount Amount of takerToken to sell
     */
    function swap(address makerToken, address takerToken, uint256 takerAmount) external nonReentrant {
        address dollar = registry().dollar();
        require(makerToken != dollar, "ReserveSwapper: unsupported token");
        require(takerToken != dollar, "ReserveSwapper: unsupported token");
        require(makerToken != takerToken, "ReserveSwapper: tokens equal");

        ReserveTypes.Order memory order = order(makerToken, takerToken);
        uint256 makerAmount = Decimal.from(takerAmount).div(order.price, "ReserveSwapper: no order").asUint256();

        if (order.amount != uint256(-1))
            _decrementOrderAmount(makerToken, takerToken, makerAmount, "ReserveSwapper: insufficient amount");

        _transferFrom(takerToken, msg.sender, address(this), takerAmount);
        _transfer(makerToken, msg.sender, makerAmount);

        emit Swap(makerToken, takerToken, takerAmount, makerAmount);
    }
}

/*
    Copyright 2021 Empty Set Squad <[email protected]>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../Interfaces.sol";
import "../lib/Decimal.sol";
import "./ReserveState.sol";

/**
 * @title ReserveVault
 * @notice Logic to passively manage USDC reserve with low-risk strategies
 * @dev Currently uses Compound to lend idle USDC in the reserve
 */
contract ReserveVault is ReserveAccessors {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Decimal for Decimal.D256;

    /**
     * @notice Emitted when `amount` USDC is supplied to the vault
     */
    event SupplyVault(uint256 amount);

    /**
     * @notice Emitted when `amount` USDC is redeemed from the vault
     */
    event RedeemVault(uint256 amount);

    /**
     * @notice Total value of the assets managed by the vault
     * @dev Denominated in USDC
     * @return Total value of the vault
     */
    function _balanceOfVault() internal view returns (uint256) {
        ICErc20 cUsdc = ICErc20(registry().cUsdc());

        Decimal.D256 memory exchangeRate = Decimal.D256({value: cUsdc.exchangeRateStored()});
        return exchangeRate.mul(cUsdc.balanceOf(address(this))).asUint256();
    }

    /**
     * @notice Supplies `amount` USDC to the external protocol for reward accrual
     * @dev Supplies to the Compound USDC lending pool
     * @param amount Amount of USDC to supply
     */
    function _supplyVault(uint256 amount) internal {
        address cUsdc = registry().cUsdc();

        IERC20(registry().usdc()).safeApprove(cUsdc, amount);
        require(ICErc20(cUsdc).mint(amount) == 0, "ReserveVault: supply failed");

        emit SupplyVault(amount);
    }

    /**
     * @notice Redeems `amount` USDC from the external protocol for reward accrual
     * @dev Redeems from the Compound USDC lending pool
     * @param amount Amount of USDC to redeem
     */
    function _redeemVault(uint256 amount) internal {
        require(ICErc20(registry().cUsdc()).redeemUnderlying(amount) == 0, "ReserveVault: redeem failed");

        emit RedeemVault(amount);
    }

    /**
     * @notice Claims all available governance rewards from the external protocol
     * @dev Owner only - governance hook
     *      Claims COMP accrued from lending on the USDC pool
     */
    function claimVault() external onlyOwner {
        ICErc20(registry().cUsdc()).comptroller().claimComp(address(this));
    }

    /**
     * @notice Delegates voting power to `delegatee` for `token` governance token held by the reserve
     * @dev Owner only - governance hook
     *      Works for all COMP-based governance tokens
     * @param token Governance token to delegate voting power
     * @param delegatee Account to receive reserve's voting power
     */
    function delegateVault(address token, address delegatee) external onlyOwner {
        IGovToken(token).delegate(delegatee);
    }
}

/**
 * @title ICErc20
 * @dev Compound ICErc20 interface
 */
contract ICErc20 {
    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint256);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint256);

    /**
     * @notice Get the token balance of the `account`
     * @param account The address of the account to query
     * @return The number of tokens owned by `account`
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
      * @notice Contract which oversees inter-cToken operations
      */
    function comptroller() public view returns (IComptroller);
}

/**
 * @title IComptroller
 * @dev Compound IComptroller interface
 */
contract IComptroller {

    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) public;
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity >=0.5.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}