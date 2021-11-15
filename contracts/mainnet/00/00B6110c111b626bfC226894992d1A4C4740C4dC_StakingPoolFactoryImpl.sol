// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Fee.sol";

contract FlatRateCommission is Fee, Ownable {
    uint256 public immutable feeRaiseTimeout;
    uint256 public immutable maxRaise; // 500 = 5%
    uint256 public constant BASE = 1E4;
    uint256 public rate;
    uint256 public timeoutTimestamp;

    /// @notice Event emmited when a contract is created
    /// @param commission commission charged by the pool
    event FlatRateCommissionCreated(uint256 commission);

    /// @notice event fired when setRate function is called and successful
    /// @param newRate commission charged by the pool effective immediatly
    /// @param timeout timestamp for a new change if raising the fee
    event FlatRateChanged(uint256 newRate, uint256 timeout);

    constructor(
        uint256 _rate,
        uint256 _feeRaiseTimeout,
        uint256 _maxRaise
    ) {
        rate = _rate;
        feeRaiseTimeout = _feeRaiseTimeout;
        maxRaise = _maxRaise;
        emit FlatRateChanged(_rate, timeoutTimestamp);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        uint256 commission = (rewardAmount * rate) / BASE;

        // cap commission to 100%
        return commission > rewardAmount ? rewardAmount : commission;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setRate(uint256 newRate) external onlyOwner {
        if (newRate > rate) {
            require(
                timeoutTimestamp <= block.timestamp,
                "FlatRateCommission: the fee raise timeout is not expired yet"
            );
            require(
                (newRate - rate) <= maxRaise,
                "FlatRateCommission: the fee raise is over the maximum allowed percentage value"
            );
            timeoutTimestamp = block.timestamp + feeRaiseTimeout;
        }
        rate = newRate;
        emit FlatRateChanged(newRate, timeoutTimestamp);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Gas tax based commission model
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Fee.sol";
import "./oracle/GasOracle.sol";
import "./oracle/PriceOracle.sol";

contract GasTaxCommission is Fee, Ownable {
    uint256 public immutable feeRaiseTimeout;
    uint256 public immutable maxRaise; // 21000 is one simple tx
    GasOracle public immutable gasOracle;

    PriceOracle public immutable priceOracle;
    uint256 public timeoutTimestamp;

    uint256 public gas;

    /// @notice event fired when setGas function is called and successful
    /// @param timeout timestamp for a new change if raising the fee
    event GasTaxChanged(uint256 newGas, uint256 timeout);

    constructor(
        address _gasOracle,
        address _priceOracle,
        uint256 _gas,
        uint256 _feeRaiseTimeout,
        uint256 _maxRaise
    ) {
        gasOracle = GasOracle(_gasOracle);
        priceOracle = PriceOracle(_priceOracle);
        gas = _gas;
        feeRaiseTimeout = _feeRaiseTimeout;
        maxRaise = _maxRaise;
        emit GasTaxChanged(_gas, timeoutTimestamp);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        // get gas price (in Wei) from chainlink oracle, at https://data.chain.link/fast-gas-gwei
        uint256 gasPrice = gasOracle.getGasPrice();

        // gas fee (in Wei) charged by pool manager
        uint256 gasFee = gasPrice * gas;

        // get Wei price of 1 CTSI
        uint256 ctsiPrice = priceOracle.getPrice();

        // convert gas in Wei to gas in CTSI
        uint256 gasFeeCTSI = ctsiPrice > 0
            ? (gasFee * (10**18)) / ctsiPrice
            : 0;

        // this is the commission, maxed by the reward
        return gasFeeCTSI > rewardAmount ? rewardAmount : gasFeeCTSI;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setGas(uint256 newGasCommission) external onlyOwner {
        if (newGasCommission > gas) {
            require(
                timeoutTimestamp <= block.timestamp,
                "GasTaxCommission: the fee raise timeout is not expired yet"
            );
            require(
                (newGasCommission - gas) <= maxRaise,
                "GasTaxCommission: the fee raise is over the maximum allowed gas value"
            );
            timeoutTimestamp = block.timestamp + feeRaiseTimeout;
        }
        gas = newGasCommission;
        emit GasTaxChanged(newGasCommission, timeoutTimestamp);
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Factory of staking pools
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/StakingPool.sol";
import "./interfaces/StakingPoolFactory.sol";
import "./FlatRateCommission.sol";
import "./GasTaxCommission.sol";

contract StakingPoolFactoryImpl is Ownable, Pausable, StakingPoolFactory {
    address public referencePool;
    address public immutable gasOracle;
    address public immutable priceOracle;
    uint256 public immutable feeRaiseTimeout;
    uint256 public immutable maxGasRaise;
    uint256 public immutable maxFeePercentageRaise;

    address public pos;

    event ReferencePoolChanged(address indexed pool);
    event PoSAddressChanged(address indexed _pos);

    receive() external payable {}

    constructor(
        address _gasOracle,
        address _priceOracle,
        address _pos,
        uint256 _feeRaiseTimeout,
        uint256 _maxGasRaise,
        uint256 _maxFeePercentageRaise
    ) {
        require(
            _gasOracle != address(0),
            "StakingPoolFactoryImpl: parameter can not be zero address."
        );
        require(
            _priceOracle != address(0),
            "StakingPoolFactoryImpl: parameter can not be zero address."
        );
        gasOracle = _gasOracle;
        priceOracle = _priceOracle;
        feeRaiseTimeout = _feeRaiseTimeout;
        maxGasRaise = _maxGasRaise;
        maxFeePercentageRaise = _maxFeePercentageRaise;
        pos = _pos;
    }

    /// @notice Change the pool reference implementation
    function setReferencePool(address _referencePool) external onlyOwner {
        referencePool = _referencePool;
        emit ReferencePoolChanged(_referencePool);
    }

    /// @notice Change the pos address
    function setPoSAddress(address _pos) external onlyOwner {
        pos = _pos;
        emit PoSAddressChanged(_pos);
    }

    /// @notice Creates a new staking pool
    /// emits NewStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        external
        payable
        override
        whenNotPaused
        returns (address)
    {
        require(
            referencePool != address(0),
            "StakingPoolFactoryImpl: undefined reference pool"
        );
        FlatRateCommission fee = new FlatRateCommission(
            commission,
            feeRaiseTimeout,
            maxFeePercentageRaise
        );
        address payable deployed = payable(Clones.clone(referencePool));
        StakingPool pool = StakingPool(deployed);
        pool.initialize(address(fee), pos);
        pool.transferOwnership(msg.sender);
        fee.transferOwnership(msg.sender);
        // sends msg.value to complete hiring process
        pool.selfhire{value: msg.value}(); //@dev: ignore reentrancy guard warning

        // returns unused user payment
        payable(msg.sender).transfer(msg.value); //@dev: ignore reentrancy guard warning

        emit NewFlatRateCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    function createGasTaxCommission(uint256 gas)
        external
        payable
        override
        whenNotPaused
        returns (address)
    {
        require(
            referencePool != address(0),
            "StakingPoolFactoryImpl: undefined reference pool"
        );
        GasTaxCommission fee = new GasTaxCommission(
            gasOracle,
            priceOracle,
            gas,
            feeRaiseTimeout,
            maxGasRaise
        );
        address payable deployed = payable(Clones.clone(referencePool));
        StakingPool pool = StakingPool(deployed);
        pool.initialize(address(fee), pos);
        pool.transferOwnership(msg.sender);
        fee.transferOwnership(msg.sender);
        // sends msg.value to complete hiring process
        pool.selfhire{value: msg.value}(); //@dev: ignore reentrancy guard warning

        // returns unused user payment
        payable(msg.sender).transfer(msg.value); //@dev: ignore reentrancy guard warning

        emit NewGasTaxCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    /// @notice Returns configuration for the working pools of the current version
    /// @return _pos address for the PoS contract
    function getPoS() external view override returns (address _pos) {
        return pos;
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0 <0.9.0;

/// @title Calculator of pool owner commission for each block reward
/// @author Danilo Tuler
/// @notice This provides flexibility for different commission models
interface Fee {
    /// @notice calculates the total amount of the reward that will be directed to the pool owner
    /// @return amount of tokens taken by the pool owner as commission
    function getCommission(uint256 posIndex, uint256 rewardAmount)
        external
        view
        returns (uint256);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

import "./StakingPoolManagement.sol";
import "./StakingPoolProducer.sol";
import "./StakingPoolStaking.sol";
import "./StakingPoolUser.sol";
import "./StakingPoolWorker.sol";

/// @title Staking Pool interface
/// @author Danilo Tuler
/// @notice This interface aggregates all facets of a staking pool.
/// It is broken down into the following sub-interfaces:
/// - StakingPoolManagement: management operations on the pool, called by the owner
/// - StakingPoolProducer: operations related to block production
/// - StakingPoolStaking: interaction between the pool and the staking contract
/// - StakingPoolUser: interaction between the pool users and the pool
/// - StakingPoolWorker: interaction between the pool and the worker node
interface StakingPool is
    StakingPoolManagement,
    StakingPoolProducer,
    StakingPoolStaking,
    StakingPoolUser,
    StakingPoolWorker
{
    /// @notice initialize pool (from reference)
    function initialize(address fee, address _pos) external;

    /// @notice Transfer ownership of pool to its deployer
    function transferOwnership(address newOwner) external;

    /// @notice updates the internal settings for important pieces of the Cartesi PoS system
    function update() external;
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolFactory {
    /// @notice Creates a new staking pool using a flat commission model
    /// emits NewFlatRateCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        external
        payable
        returns (address);

    /// @notice Creates a new staking pool using a gas tax commission model
    /// emits NewGasTaxCommissionStakingPool with the parameters of the new pool
    /// @return new pool address
    function createGasTaxCommission(uint256 gas)
        external
        payable
        returns (address);

    /// @notice Returns configuration for the working pools of the current version
    /// @return _pos address for the PoS contract
    function getPoS() external view returns (address _pos);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of the commission contract
    event NewFlatRateCommissionStakingPool(address indexed pool, address fee);

    /// @notice Event emmited when a pool is created
    /// @param pool address of the new pool
    /// @param fee address of thhe commission contract
    event NewGasTaxCommissionStakingPool(address indexed pool, address fee);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolManagement {
    /// @notice sets a name for the pool using ENS service
    function setName(string memory name) external;

    /// @notice pauses new staking on the pool
    function pause() external;

    /// @notice unpauses new staking on the pool
    function unpause() external;

    /// @notice Event emmited when a pool is rename
    event StakingPoolRenamed(string name);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool and the PoS block production.
/// @author Danilo Tuler
/// @notice This interface provides an opportunity to handle the necessary logic
/// after a block is produced.
/// A commission is taken from the block reward, and the remaining stays in the pool,
/// raising the pool share value, and being further staked.
interface StakingPoolProducer {
    /// @notice routes produceBlock to POS contract and
    /// updates internal states of the pool
    /// @return true when everything went fine
    function produceBlock(uint256 _index) external returns (bool);

    /// @notice this event is emitted at every produceBlock call
    /// reward is the block reward
    /// commission is how much CTSI is directed to the pool owner
    event BlockProduced(uint256 reward, uint256 commission);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool and the staking contract
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool and the staking contract,
/// including staking, unstaking and withdrawing.
/// Tokens staked by pool users will stay at the pool until the pool owner decides to
/// stake them in the staking contract. On the other hand, tokens unstaked by pool users
/// are added to a required liquidity accumulator, and must be unstaked and withdrawn from
/// the staking contract.
interface StakingPoolStaking {
    /// @notice Move tokens from pool to staking or vice-versa, according to required liquidity.
    /// If the pool has more liquidity then necessary, it stakes tokens.
    /// If the pool has less liquidity then necessary, and has not started an unstake, it unstakes.
    /// If the pool has less liquity than necessary, and has started an unstake, it withdraws if possible.
    function rebalance() external;

    /// @notice provide information for offchain about the amount for each
    /// staking operation on the main Staking contract
    /// @return stake amount of tokens that can be staked
    /// @return unstake amount of tokens that must be unstaked to add liquidity
    /// @return withdraw amount of tokens that can be withdrawn to add liquidity
    function amounts()
        external
        view
        returns (
            uint256 stake,
            uint256 unstake,
            uint256 withdraw
        );
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

/// @title Interaction between a pool user and a pool
/// @author Danilo Tuler
/// @notice This interface models all interactions between a pool user and a pool,
/// including staking, unstaking and withdrawing. A pool user always holds pool shares.
/// When a user stakes tokens, he immediately receive shares. When he unstakes shares
/// he is asking to release tokens. Those tokens need to be withdrawn by an additional
/// call to withdraw()
interface StakingPoolUser {
    /// @notice Deposit tokens to user pool balance
    /// @param amount amount of token deposited in the pool
    function deposit(uint256 amount) external;

    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param amount amount of tokens to convert to shares
    function stake(uint256 amount) external;

    /// @notice Unstake an specified amount of shares of the calling user
    /// @dev Shares are immediately converted to tokens, and added to the pool liquidity requirement
    function unstake(uint256 shares) external;

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer tokens from user pool account to user's wallet
    function withdraw(uint256 amount) external;

    /// @notice Returns the amount of tokens that can be immediately withdrawn by the calling user
    /// @dev there is no way to know the exact time in the future the requested tokens will be available
    /// @return the amount of tokens that can be immediately withdrawn by the calling user
    function getWithdrawBalance() external returns (uint256);

    /// @notice Tokens were deposited, available for staking or withdrawal
    /// @param user address of msg.sender
    /// @param amount amount of tokens deposited by the user
    /// @param stakeTimestamp instant when the amount can be staked
    event Deposit(address indexed user, uint256 amount, uint256 stakeTimestamp);

    /// @notice Tokens were deposited, they count as shares immediatly
    /// @param user address of msg.sender
    /// @param amount amount deposited by the user
    /// @param shares number of shares emitted for user
    event Stake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Request to unstake tokens. Additional liquidity requested for the pool
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param shares number of shares being liquidated
    event Unstake(address indexed user, uint256 amount, uint256 shares);

    /// @notice Withdraw performed by a user
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(address indexed user, uint256 amount);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity >=0.7.0;

interface StakingPoolWorker {
    /// @notice allows for the pool to act on its own behalf when producing blocks.
    function selfhire() external payable;

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable;

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external;

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external;
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity ^0.8.0;

interface GasOracle {
    /// @notice Returns current network gas price
    /// @return value of gas price
    function getGasPrice() external view returns (uint256);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity >=0.5.0 <0.9.0;

interface PriceOracle {
    /// @notice Returns price of CTSI in ETH
    /// @return value of 1 ETH in CTSI
    function getPrice() external view returns (uint256);
}

