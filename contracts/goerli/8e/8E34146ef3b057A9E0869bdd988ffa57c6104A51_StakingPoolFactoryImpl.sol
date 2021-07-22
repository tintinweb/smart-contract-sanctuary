// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

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

/*
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
    uint256 public BASE = 1E4;
    uint256 public rate;

    /// @notice Event emmited when a contract is created
    /// @param commission commission charged by the pool
    event FlatRateCommissionCreated(uint256 commission);

    /// @notice event fired when setRate function is called and successful
    event FlatRateChanged(uint256 newRate);

    constructor(uint256 _rate) {
        rate = _rate;
        emit FlatRateChanged(_rate);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        return (rewardAmount * rate) / BASE;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setRate(uint256 newRate) external onlyOwner {
        require(
            newRate < rate,
            "newRate needs to be strictly smaller than current rate."
        );
        rate = newRate;
        emit FlatRateChanged(newRate);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Fee.sol";

contract GasTaxCommission is Fee, Ownable {
    AggregatorInterface public immutable gasOracle;

    IUniswapV2Pair public immutable priceOracle;

    uint256 public gas;

    /// @notice event fired when setGas function is called and successful
    event GasTaxChanged(uint256 newGas);

    constructor(
        address _chainlinkOracle,
        address _uniswapOracle,
        uint256 _gas
    ) {
        gasOracle = AggregatorInterface(_chainlinkOracle);
        priceOracle = IUniswapV2Pair(_uniswapOracle);
        gas = _gas;
        emit GasTaxChanged(_gas);
    }

    /// @notice calculates the total amount of the reward that will be directed to the PoolManager
    /// @return commissionTotal is the amount subtracted from the rewardAmount
    function getCommission(uint256, uint256 rewardAmount)
        external
        view
        override
        returns (uint256)
    {
        // get gas price from chainlink oracle
        // https://data.chain.link/fast-gas-gwei#operator-chainlayer
        uint256 gasPrice = uint256(gasOracle.latestAnswer());

        // gas fee (in ETH) charged by pool manager
        uint256 gasFee = gasPrice * gas;

        // get CTSI/ETH reserves
        (
            uint112 reserveCTSI,
            uint112 reserveETH,
            uint32 _blockTimestampLast
        ) = priceOracle.getReserves();

        // convert gas in ETH to gas in CTSI

        // if there is no ETH reserve, we can't calculate
        if (reserveETH == 0) {
            return 0;
        }
        uint256 gasFeeCTSI = (gasFee * reserveCTSI) / reserveETH;

        // this is the commission, maxed by the reward
        return gasFeeCTSI > rewardAmount ? rewardAmount : gasFeeCTSI;
    }

    /// @notice allows for the poolManager to reduce how much they want to charge for the block production tx
    function setGas(uint256 newGasCommission) external onlyOwner {
        require(
            newGasCommission < gas,
            "newGasCommission needs to be strictly smaller than the current value."
        );
        gas = newGasCommission;
        emit GasTaxChanged(newGasCommission);
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
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/StakingPool.sol";
import "./interfaces/StakingPoolFactory.sol";
import "./FlatRateCommission.sol";
import "./GasTaxCommission.sol";

contract StakingPoolFactoryImpl is Ownable, Pausable, StakingPoolFactory {
    address public referencePool;
    address public immutable chainlinkOracle;
    address public immutable uniswapOracle;

    event ReferencePoolChanged(address indexed pool);

    constructor(address _chainlinkOracle, address _uniswapOracle) {
        require(
            _chainlinkOracle != address(0),
            "StakingPoolFactoryImpl: parameter can not be zero address."
        );
        require(
            _uniswapOracle != address(0),
            "StakingPoolFactoryImpl: parameter can not be zero address."
        );
        chainlinkOracle = _chainlinkOracle;
        uniswapOracle = _uniswapOracle;
    }

    /// @notice Change the pool reference implementation
    function setReferencePool(address _referencePool) public onlyOwner {
        referencePool = _referencePool;
        emit ReferencePoolChanged(_referencePool);
    }

    /// @notice Creates a new staking pool
    /// emits NewStakingPool with the parameters of the new pool
    /// @return new pool address
    function createFlatRateCommission(uint256 commission)
        public
        payable
        override
        whenNotPaused
        returns (address)
    {
        require(
            referencePool != address(0),
            "StakingPoolFactoryImpl: undefined reference pool"
        );
        FlatRateCommission fee = new FlatRateCommission(commission);
        address payable deployed = payable(Clones.clone(referencePool));
        StakingPool pool = StakingPool(deployed);
        pool.initialize(address(fee), 0);
        pool.transferOwnership(msg.sender);
        fee.transferOwnership(msg.sender);
        pool.selfhire{value: msg.value}();

        emit NewFlatRateCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    function createGasTaxCommission(uint256 gas)
        public
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
            chainlinkOracle,
            uniswapOracle,
            gas
        );
        address payable deployed = payable(Clones.clone(referencePool));
        StakingPool pool = StakingPool(deployed);
        pool.initialize(address(fee), 0);
        pool.transferOwnership(msg.sender);
        fee.transferOwnership(msg.sender);
        pool.selfhire{value: msg.value}();

        emit NewGasTaxCommissionStakingPool(address(pool), address(fee));
        return address(pool);
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
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
    function initialize(address fee, uint256 stakeLock) external;

    /// @notice Transfer ownership of pool to its deployer
    function transferOwnership(address newOwner) external;
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
    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param amount amount of tokens deposited in the pool
    function stake(uint256 amount) external;

    /// @notice Unstake an specified amount of shares of the calling user
    /// @dev Shares are immediately converted to tokens, and added to the pool liquidity requirement
    function unstake(uint256 shares) external;

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer all free tokens for the calling user
    function withdraw() external;

    /// @notice Returns the amount of tokens that can be immediately withdrawn by the calling user
    /// @dev there is no way to know the exact time in the future the requested tokens will be available
    /// @return the amount of tokens that can be immediately withdrawn by the calling user
    function getWithdrawBalance() external returns (uint256);

    /// @notice Tokens were deposited, they count as shares immediatly
    /// @param user address of msg.sender
    /// @param amount amount deposited by the user
    /// @param shares number of shares emitted for user
    /// @param unlockTimestamp instant when the stake can be unstaked
    event Stake(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 unlockTimestamp
    );

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

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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