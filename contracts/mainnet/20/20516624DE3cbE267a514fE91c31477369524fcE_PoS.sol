// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CartesiMath {
    using SafeMath for uint256;
    mapping(uint256 => uint256) log2tableTimes1M;

    constructor() {
        log2tableTimes1M[1] = 0;
        log2tableTimes1M[2] = 1000000;
        log2tableTimes1M[3] = 1584962;
        log2tableTimes1M[4] = 2000000;
        log2tableTimes1M[5] = 2321928;
        log2tableTimes1M[6] = 2584962;
        log2tableTimes1M[7] = 2807354;
        log2tableTimes1M[8] = 3000000;
        log2tableTimes1M[9] = 3169925;
        log2tableTimes1M[10] = 3321928;
        log2tableTimes1M[11] = 3459431;
        log2tableTimes1M[12] = 3584962;
        log2tableTimes1M[13] = 3700439;
        log2tableTimes1M[14] = 3807354;
        log2tableTimes1M[15] = 3906890;
        log2tableTimes1M[16] = 4000000;
        log2tableTimes1M[17] = 4087462;
        log2tableTimes1M[18] = 4169925;
        log2tableTimes1M[19] = 4247927;
        log2tableTimes1M[20] = 4321928;
        log2tableTimes1M[21] = 4392317;
        log2tableTimes1M[22] = 4459431;
        log2tableTimes1M[23] = 4523561;
        log2tableTimes1M[24] = 4584962;
        log2tableTimes1M[25] = 4643856;
        log2tableTimes1M[26] = 4700439;
        log2tableTimes1M[27] = 4754887;
        log2tableTimes1M[28] = 4807354;
        log2tableTimes1M[29] = 4857980;
        log2tableTimes1M[30] = 4906890;
        log2tableTimes1M[31] = 4954196;
        log2tableTimes1M[32] = 5000000;
        log2tableTimes1M[33] = 5044394;
        log2tableTimes1M[34] = 5087462;
        log2tableTimes1M[35] = 5129283;
        log2tableTimes1M[36] = 5169925;
        log2tableTimes1M[37] = 5209453;
        log2tableTimes1M[38] = 5247927;
        log2tableTimes1M[39] = 5285402;
        log2tableTimes1M[40] = 5321928;
        log2tableTimes1M[41] = 5357552;
        log2tableTimes1M[42] = 5392317;
        log2tableTimes1M[43] = 5426264;
        log2tableTimes1M[44] = 5459431;
        log2tableTimes1M[45] = 5491853;
        log2tableTimes1M[46] = 5523561;
        log2tableTimes1M[47] = 5554588;
        log2tableTimes1M[48] = 5584962;
        log2tableTimes1M[49] = 5614709;
        log2tableTimes1M[50] = 5643856;
        log2tableTimes1M[51] = 5672425;
        log2tableTimes1M[52] = 5700439;
        log2tableTimes1M[53] = 5727920;
        log2tableTimes1M[54] = 5754887;
        log2tableTimes1M[55] = 5781359;
        log2tableTimes1M[56] = 5807354;
        log2tableTimes1M[57] = 5832890;
        log2tableTimes1M[58] = 5857980;
        log2tableTimes1M[59] = 5882643;
        log2tableTimes1M[60] = 5906890;
        log2tableTimes1M[61] = 5930737;
        log2tableTimes1M[62] = 5954196;
        log2tableTimes1M[63] = 5977279;
        log2tableTimes1M[64] = 6000000;
        log2tableTimes1M[65] = 6022367;
        log2tableTimes1M[66] = 6044394;
        log2tableTimes1M[67] = 6066089;
        log2tableTimes1M[68] = 6087462;
        log2tableTimes1M[69] = 6108524;
        log2tableTimes1M[70] = 6129283;
        log2tableTimes1M[71] = 6149747;
        log2tableTimes1M[72] = 6169925;
        log2tableTimes1M[73] = 6189824;
        log2tableTimes1M[74] = 6209453;
        log2tableTimes1M[75] = 6228818;
        log2tableTimes1M[76] = 6247927;
        log2tableTimes1M[77] = 6266786;
        log2tableTimes1M[78] = 6285402;
        log2tableTimes1M[79] = 6303780;
        log2tableTimes1M[80] = 6321928;
        log2tableTimes1M[81] = 6339850;
        log2tableTimes1M[82] = 6357552;
        log2tableTimes1M[83] = 6375039;
        log2tableTimes1M[84] = 6392317;
        log2tableTimes1M[85] = 6409390;
        log2tableTimes1M[86] = 6426264;
        log2tableTimes1M[87] = 6442943;
        log2tableTimes1M[88] = 6459431;
        log2tableTimes1M[89] = 6475733;
        log2tableTimes1M[90] = 6491853;
        log2tableTimes1M[91] = 6507794;
        log2tableTimes1M[92] = 6523561;
        log2tableTimes1M[93] = 6539158;
        log2tableTimes1M[94] = 6554588;
        log2tableTimes1M[95] = 6569855;
        log2tableTimes1M[96] = 6584962;
        log2tableTimes1M[97] = 6599912;
        log2tableTimes1M[98] = 6614709;
        log2tableTimes1M[99] = 6629356;
        log2tableTimes1M[100] = 6643856;
        log2tableTimes1M[101] = 6658211;
        log2tableTimes1M[102] = 6672425;
        log2tableTimes1M[103] = 6686500;
        log2tableTimes1M[104] = 6700439;
        log2tableTimes1M[105] = 6714245;
        log2tableTimes1M[106] = 6727920;
        log2tableTimes1M[107] = 6741466;
        log2tableTimes1M[108] = 6754887;
        log2tableTimes1M[109] = 6768184;
        log2tableTimes1M[110] = 6781359;
        log2tableTimes1M[111] = 6794415;
        log2tableTimes1M[112] = 6807354;
        log2tableTimes1M[113] = 6820178;
        log2tableTimes1M[114] = 6832890;
        log2tableTimes1M[115] = 6845490;
        log2tableTimes1M[116] = 6857980;
        log2tableTimes1M[117] = 6870364;
        log2tableTimes1M[118] = 6882643;
        log2tableTimes1M[119] = 6894817;
        log2tableTimes1M[120] = 6906890;
        log2tableTimes1M[121] = 6918863;
        log2tableTimes1M[122] = 6930737;
        log2tableTimes1M[123] = 6942514;
        log2tableTimes1M[124] = 6954196;
        log2tableTimes1M[125] = 6965784;
        log2tableTimes1M[126] = 6977279;
        log2tableTimes1M[127] = 6988684;
        log2tableTimes1M[128] = 7000000;
    }

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    function log2ApproxTimes1M(uint256 _num) public view returns (uint256) {
        require (_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
           _num = _num >> 1;
           leading += 1;
       }
       return (leading.mul(uint256(1000000))).add(log2tableTimes1M[_num]);
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.7.0;


contract Decorated {
    // This contract defines several modifiers but does not use
    // them - they will be used in derived contracts.
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Cannot be called now");
        _;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


pragma solidity ^0.7.0;


interface Instantiator {

    modifier onlyInstantiated(uint256 _index) virtual;

    modifier onlyActive(uint256 _index) virtual;

    modifier increasesNonce(uint256 _index) virtual;

    function isActive(uint256 _index) external view returns (bool);

    function getNonce(uint256 _index) external view returns (uint256);

    function isConcerned(uint256 _index, address _user) external view returns (bool);

    function getSubInstances(uint256 _index, address) external view returns (address[] memory _addresses, uint256[] memory _indices);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.7.0;

import "./Instantiator.sol";

abstract contract InstantiatorImpl is Instantiator {
    uint256 public currentIndex = 0;

    mapping(uint256 => bool) internal active;
    mapping(uint256 => uint256) internal nonce;

    modifier onlyInstantiated(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        _;
    }

    modifier onlyActive(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        require(isActive(_index), "Index inactive");
        _;
    }

    modifier increasesNonce(uint256 _index) override {
        nonce[_index]++;
        _;
    }

    function isActive(uint256 _index) public override view returns (bool) {
        return (active[_index]);
    }

    function getNonce(uint256 _index)
        public
        override
        view
        onlyActive(_index)
        returns (uint256 currentNonce)
    {
        return nonce[_index];
    }

    function deactivate(uint256 _index) internal {
        active[_index] = false;
        nonce[_index] = 0;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerAuthManager
/// @author Danilo Tuler
pragma solidity ^0.7.0;

interface WorkerAuthManager {
    /// @notice Gives worker permission to act on a DApp
    /// @param _workerAddress address of the worker node to given permission
    /// @param _dappAddress address of the dapp that permission will be given to
    function authorize(address _workerAddress, address _dappAddress) external;

    /// @notice Removes worker's permission to act on a DApp
    /// @param _workerAddress address of the proxy that will lose permission
    /// @param _dappAddresses addresses of dapps that will lose permission
    function deauthorize(address _workerAddress, address _dappAddresses)
        external;

    /// @notice Returns is the dapp is authorized to be called by that worker
    /// @param _workerAddress address of the worker
    /// @param _dappAddress address of the DApp
    function isAuthorized(address _workerAddress, address _dappAddress)
        external
        view
        returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice A DApp has been authorized by a user for a worker
    event Authorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );

    /// @notice A DApp has been deauthorized by a user for a worker
    event Deauthorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Block Selector

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@cartesi/util/contracts/CartesiMath.sol";
import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";

contract BlockSelector is InstantiatorImpl, Decorated, CartesiMath {
    using SafeMath for uint256;

    uint256 constant C_256 = 256; // 256 blocks
    uint256 constant DIFFICULTY_BASE_MULTIPLIER = 256000000; //256 M
    uint256 constant ADJUSTMENT_BASE = 1000000; // 1M

    struct BlockSelectorCtx {
        // @dev the order of variables are important for storage packing
        // 32 bytes constants
        uint256 minDifficulty; // lower bound for difficulty
        // 32 bytes var
        uint256 difficulty; // difficulty parameter defines how big the interval will be

        // 20 bytes constants
        address posManagerAddress;

        // 4 bytes constants
        uint32 difficultyAdjustmentParameter; // how fast the difficulty gets adjusted to reach the desired interval, number * 1000000
        uint32 targetInterval; // desired block selection interval in ethereum blocks

        // 4 bytes var
        uint32 blockCount; // how many blocks have been created
        uint32 ethBlockCheckpoint; // ethereum block number when current selection started
    }

    mapping(uint256 => BlockSelectorCtx) internal instance;

    event BlockProduced(
        uint256 indexed index,
        address indexed producer,
        uint32 blockNumber,
        uint256 roundDuration,
        uint256 difficulty
    );

    modifier onlyAfterGoalDefinition(uint256 _index){
        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        require(
            block.number >= instance[_index].ethBlockCheckpoint + 1,
            "Goal for new block hasnt been decided yet"
        );
        _;

    }

    /// @notice Instantiates a BlockSelector structure
    /// @param _minDifficulty lower bound for difficulty parameter
    /// @param _initialDifficulty starting difficulty
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// according to the difference between time passed and target interval.
    /// @param _targetInterval how often we want produce noether blocks, in ethereum blocks
    /// @param _posManagerAddress address of ProofOfStake that will use this instance
    function instantiate(
        uint256 _minDifficulty,
        uint256 _initialDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        address _posManagerAddress
    ) public returns (uint256)
    {
        instance[currentIndex].minDifficulty = _minDifficulty;
        instance[currentIndex].difficulty = _initialDifficulty;
        instance[currentIndex].difficultyAdjustmentParameter = _difficultyAdjustmentParameter;
        instance[currentIndex].targetInterval = _targetInterval;
        instance[currentIndex].posManagerAddress = _posManagerAddress;

        instance[currentIndex].ethBlockCheckpoint = uint32(block.number); // first selection starts when the instance is created

        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Calculates the log of the random number between the goal and callers address
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address to calculate log of random
    /// @return log of random number between goal and callers address * 1M
    function getLogOfRandom(uint256 _index, address _user) internal view returns (uint256) {
        // seed for goal takes a block in the future (+1) so it is harder to manipulate
        bytes32 currentGoal = blockhash(
            getSeed(uint256(instance[_index].ethBlockCheckpoint + 1), block.number)
        );
        bytes32 hashedAddress = keccak256(abi.encodePacked(_user));
        uint256 distance = uint256(keccak256(abi.encodePacked(hashedAddress, currentGoal)));

        return CartesiMath.log2ApproxTimes1M(distance);
    }

    /// @notice Produces a block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user address that has the right to produce block
    /// @param _weight number that will weight the random number, will be the number of staked tokens
    function produceBlock(
        uint256 _index,
        address _user,
        uint256 _weight
    )
    public
    onlyAfterGoalDefinition(_index)
    returns (bool)
    {
        BlockSelectorCtx storage bsc = instance[_index];

        require(_weight > 0, "Caller can't have zero staked tokens");
        require(msg.sender == bsc.posManagerAddress, "Function can only be called by pos address");

        if (canProduceBlock(_index, _user, _weight)) {
            emit BlockProduced(
                _index,
                _user,
                bsc.blockCount,
                getSelectionBlockDuration(_index),
                bsc.difficulty
            );

            return _blockProduced(_index);
        }

        return false;
    }

    /// @notice Check if address is allowed to produce block
    /// @param _index the index of the instance of block selector you want to interact with
    /// @param _user the address that is gonna get checked
    /// @param _weight number that will weight the random number, most likely will be the number of staked tokens
    function canProduceBlock(uint256 _index, address _user, uint256 _weight) public view returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        // cannot produce if block selector goal hasnt been decided yet
        // goal is defined the block after selection was reset
        if (block.number <= bsc.ethBlockCheckpoint + 1) {
            return false;
        }

        uint256 blockDuration = getSelectionBlockDuration(_index);

        return (
            (_weight.mul(blockDuration)) > bsc.difficulty.mul((DIFFICULTY_BASE_MULTIPLIER - getLogOfRandom(_index, _user)))
        );
    }

    /// @notice Block produced, declare producer and adjust difficulty
    /// @param _index the index of the instance of block selector you want to interact with
    function _blockProduced(uint256 _index) private returns (bool) {
        BlockSelectorCtx storage bsc = instance[_index];

        // adjust difficulty
        bsc.difficulty = getNewDifficulty(
            bsc.minDifficulty,
            bsc.difficulty,
            uint32((block.number).sub(uint256(bsc.ethBlockCheckpoint))),
            bsc.targetInterval,
            bsc.difficultyAdjustmentParameter
        );

        _reset(_index);
        return true;
    }

    /// @notice Reset instance, advancing round and choosing new goal
    /// @param _index the index of the instance of block selector you want to interact with
    function _reset(uint256 _index) private {
        BlockSelectorCtx storage bsc = instance[_index];

        bsc.blockCount++;
        bsc.ethBlockCheckpoint = uint32(block.number);
    }

    function getSeed(
        uint256 _previousTarget,
        uint256 _currentBlock
    )
    internal
    pure
    returns (uint256)
    {
        uint256 diff = _currentBlock.sub(_previousTarget);
        uint256 res = diff.div(C_256);

        // if difference is multiple of 256 (256, 512, 1024)
        // preserve old target
        if (diff % C_256 == 0) {
            return _previousTarget.add((res - 1).mul(C_256));
        }

        return _previousTarget.add(res.mul(C_256));
    }

    /// @notice Calculates new difficulty parameter
    /// @param _minDiff minimum difficulty of instance
    /// @param _oldDiff is the difficulty of previous round
    /// @param _blocksPassed how many ethereum blocks have passed
    /// @param _targetInterval is how long a round is supposed to take
    /// @param _adjustmentParam is how fast the difficulty gets adjusted,
    ///         should be number * 1000000
    function getNewDifficulty(
        uint256 _minDiff,
        uint256 _oldDiff,
        uint32 _blocksPassed,
        uint32 _targetInterval,
        uint32 _adjustmentParam
    )
    internal
    pure
    returns (uint256)
    {
        // @dev to save gas on evaluation, instead of returning the _oldDiff when the target
        // was exactly matched - we increase the difficulty.
        if (_blocksPassed <= _targetInterval) {
            return _oldDiff.add(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);
        }

        uint256 newDiff = _oldDiff.sub(_oldDiff.mul(_adjustmentParam).div(ADJUSTMENT_BASE) + 1);

        return newDiff > _minDiff ? newDiff : _minDiff;
    }

    /// @notice Returns the number of blocks
    /// @param _index the index of the instance of block selector to be interact with
    /// @return number of blocks
    function getBlockCount(uint256 _index) public view returns (uint32) {
        return instance[_index].blockCount;
    }

    /// @notice Returns current difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty of current selection
    function getDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].difficulty;
    }

    /// @notice Returns min difficulty
    /// @param _index the index of the instance of block selector to be interact with
    /// @return min difficulty of instance
    function getMinDifficulty(uint256 _index) public view returns (uint256) {
        return instance[_index].minDifficulty;
    }

    /// @notice Returns difficulty adjustment parameter
    /// @param _index the index of the instance of block selector to be interact with
    /// @return difficulty adjustment parameter
    function getDifficultyAdjustmentParameter(
        uint256 _index
    )
    public
    view
    returns (uint32)
    {
        return instance[_index].difficultyAdjustmentParameter;
    }

    /// @notice Returns target interval
    /// @param _index the index of the instance of block selector to be interact with
    /// @return target interval
    function getTargetInterval(uint256 _index) public view returns (uint32) {
        return instance[_index].targetInterval;
    }

    /// @notice Returns time since last selection started, in ethereum blocks
    /// @param _index the index of the instance of block selector to be interact with
    /// @return number of etheereum blocks passed since last selection started
    /// @dev block duration resets every 256 blocks
    function getSelectionBlockDuration(uint256 _index)
    public
    view
    returns (uint256)
    {
        BlockSelectorCtx storage bsc = instance[_index];

        uint256 goalBlock = uint256(bsc.ethBlockCheckpoint + 1);

        // target hasnt been set
        if (goalBlock >= block.number) return 0;

        uint256 blocksPassed = (block.number).sub(goalBlock);

        // if blocksPassed is multiple of 256, 256 blocks have passed
        // this avoids blocksPassed going to zero right before target change
        if (blocksPassed % C_256 == 0) return C_256;

        return blocksPassed % C_256;
    }

    function getState(uint256 _index, address _user)
    public view returns (uint256[5] memory _uintValues) {
        BlockSelectorCtx storage i = instance[_index];

        uint256[5] memory uintValues = [
            block.number,
            i.ethBlockCheckpoint + 1, // initial selection goal
            i.difficulty,
            getSelectionBlockDuration(_index), // blocks passed
            getLogOfRandom(_index, _user)
        ];

        return uintValues;
    }

    function isConcerned(uint256, address) public override pure returns (bool) {
        return false; // isConcerned is only for the main concern (PoS)
    }

    function getSubInstances(uint256, address)
        public override pure returns (address[] memory _addresses,
            uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        a = new address[](0);
        i = new uint256[](0);

        return (a, i);
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Proof of Stake
/// @author Felipe Argento

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/WorkerAuthManager.sol";

import "./Staking.sol";
import "./BlockSelector.sol";
import "./RewardManager.sol";

contract PoS is Ownable, InstantiatorImpl, Decorated {
    using SafeMath for uint256;

    struct PoSCtx {
        uint256 blockSelectorIndex;
        BlockSelector blockSelector;
        Staking staking;
        RewardManager rewardManager;
        WorkerAuthManager workerAuth;
    }

    mapping(uint256 => PoSCtx) internal instance;

    event Rewarded(
        uint256 indexed index,
        address indexed worker,
        address indexed user,
        uint256 reward
    );

    event NewChain (
        uint256 indexed index,
        address stakingAddress,
        address blockSelectorAddress,
        address workerAuthAddress,
        uint256 minimumDifficulty,
        uint256 initialDifficulty,
        uint32 difficultyAdjustmentParameter,
        uint32 targetInterval,
        address ctsiAddress,
        uint256 maxReward,
        uint256 minReward,
        uint256 distNumerator,
        uint256 distDenominator
    );
    /// @notice Instantiates a Proof of Stake
    /// @param _stakingAddress address of StakingInterface
    /// @param _blockSelectorAddress address of blockSelector contract
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// according to the difference between time passed and desired draw time interval.
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _ctsiAddress address of token instance being used
    /// @param _maxReward maximum reward that this contract pays
    /// @param _minReward minimum reward that this contract pays
    /// @param _distNumerator multiplier factor to define reward amount
    /// @param _distDenominator dividing factor to define reward amount
    function instantiate(
        address _stakingAddress,
        address _blockSelectorAddress,
        address _workerAuthAddress,
        uint256 _minimumDifficulty,
        uint256 _initialDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,

        // RewardManager constructor parameters
        address _ctsiAddress,
        uint256 _maxReward,
        uint256 _minReward,
        uint256 _distNumerator,
        uint256 _distDenominator
    ) public onlyOwner() returns (uint256) {

        // index is incremented at the beggining to stop reentrancy possibilities
        // TODO: study using ReentrancyGuard contract
        currentIndex++;

        instance[currentIndex - 1].staking = Staking(_stakingAddress);
        instance[currentIndex - 1].blockSelector = BlockSelector(
            _blockSelectorAddress
        );

        instance[currentIndex - 1].workerAuth = WorkerAuthManager(
            _workerAuthAddress
        );

        active[currentIndex - 1] = true;

        // there is no reentrancy because the bytecode is included in this contract
        instance[currentIndex - 1].rewardManager = new RewardManager(
            address(this),
            _ctsiAddress,
            _maxReward,
            _minReward,
            _distNumerator,
            _distDenominator
        );

        instance[currentIndex - 1].blockSelectorIndex = instance[currentIndex -
            1]
            .blockSelector
            .instantiate(
            _minimumDifficulty,
            _initialDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            address(this)
        );

        emit NewChain (
            currentIndex - 1,
            _stakingAddress,
            _blockSelectorAddress,
            _workerAuthAddress,
            _minimumDifficulty,
            _initialDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _ctsiAddress,
            _maxReward,
            _minReward,
            _distNumerator,
            _distDenominator
        );

        return currentIndex - 1;
    }

    /// @notice Produce a block
    /// @param _index the index of the instance of pos you want to interact with
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256 _index) public returns (bool) {
        PoSCtx storage pos = instance[_index];

        require(
            pos.workerAuth.isAuthorized(msg.sender, address(this)),
            "msg.sender is not authorized to make this call"
        );

        address user = pos.workerAuth.getOwner(msg.sender);

        require(
            pos.blockSelector.produceBlock(
                pos.blockSelectorIndex,
                user,
                pos.staking.getStakedBalance(user)
            ),
            "User couldnt produce a block successfully"
        );

        uint256 currentReward = pos.rewardManager.getCurrentReward();

        pos.rewardManager.reward(user, currentReward);
        emit Rewarded(
            _index,
            msg.sender,
            user,
            currentReward
        );

        return true;
    }

    /// @notice Get reward manager address
    /// @param _index index of instance
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].rewardManager);
    }

    /// @notice Get block selector address
    /// @param _index index of instance
    /// @return address of instance's block selector
    function getBlockSelectorAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].blockSelector);
    }

    /// @notice Get block selector index
    /// @param _index index of instance
    /// @return index of instance's block selector
    function getBlockSelectorIndex(uint256 _index)
        public
        view
        returns (uint256)
    {
        return instance[_index].blockSelectorIndex;
    }

    /// @notice Get staking address
    /// @param _index index of instance
    /// @return address of instance's staking contract
    function getStakingAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].staking);
    }

    /// @notice Get state of a particular instance
    /// @param _index index of instance
    /// @param _user address of user
    /// @return bool if user is eligible to produce next block
    /// @return address of user that was chosen to build the block
    /// @return current reward paid by the network for that block
    function getState(uint256 _index, address _user)
        public
        view
        returns (
            bool,
            address,
            uint256
        )
    {
        PoSCtx storage pos = instance[_index];
        return (
            pos.blockSelector.canProduceBlock(
                pos.blockSelectorIndex,
                _user,
                pos.staking.getStakedBalance(_user)
            ),
            _user,
            pos.rewardManager.getCurrentReward()
        );
    }

    function isConcerned(uint256 _index, address _user)
        public
        override
        view
        returns (bool)
    {
        PoSCtx storage pos = instance[_index];
        return pos.staking.getStakedBalance(_user) > 0;
    }

    function getSubInstances(uint256 _index, address)
        public
        override
        view
        returns (address[] memory _addresses, uint256[] memory _indices)
    {
        PoSCtx storage pos = instance[_index];

        address[] memory a;
        uint256[] memory i;

        a = new address[](1);
        i = new uint256[](1);

        a[0] = address(pos.blockSelector);
        i[0] = pos.blockSelectorIndex;
        return (a, i);
    }

    function terminate(uint256 _index) public onlyOwner() {
        PoSCtx storage pos = instance[_index];
        require(
            pos.rewardManager.getCurrentReward() == 0,
            "RewardManager still holds funds"
        );
        deactivate(_index);
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title RewardManager
/// @author Felipe Argento


pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardManager {
    using SafeMath for uint256;

    uint256 immutable minReward;
    uint256 immutable maxReward;
    uint256 immutable distNumerator;
    uint256 immutable distDenominator;
    address immutable operator;
    IERC20 immutable ctsi;

    /// @notice Creates contract
    /// @param _operator address of the operator
    /// @param _ctsiAddress address of token instance being used
    /// @param _maxReward maximum reward that this contract pays
    /// @param _minReward minimum reward that this contract pays
    /// @param _distNumerator multiplier factor to define reward amount
    /// @param _distDenominator dividing factor to define reward amount
    constructor(
        address _operator,
        address _ctsiAddress,
        uint256 _maxReward,
        uint256 _minReward,
        uint256 _distNumerator,
        uint256 _distDenominator
    ) {

        operator = _operator;
        ctsi = IERC20(_ctsiAddress);

        minReward = _minReward;
        maxReward = _maxReward;
        distNumerator = _distNumerator;
        distDenominator = _distDenominator;
    }

    /// @notice Rewards address
    /// @param _address address be rewarded
    /// @param _amount reward
    /// @dev only the pos contract can call this
    function reward(address _address, uint256 _amount) public {
        require(msg.sender == operator, "Only the operator contract can call this function");

        ctsi.transfer(_address, _amount);
    }

    /// @notice Get RewardManager's balance
    function getBalance() public view returns (uint256) {
        return ctsi.balanceOf(address(this));
    }

    /// @notice Get current reward amount
    function getCurrentReward() public view returns (uint256) {
        uint256 cReward = (getBalance().mul(distNumerator)).div(distDenominator);
        cReward = cReward > minReward? cReward : minReward;
        cReward = cReward > maxReward? maxReward : cReward;

        return cReward > getBalance()? getBalance() : cReward;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity ^0.7.0;

interface Staking {

    /// @notice Returns total amount of tokens counted as stake
    /// @param _userAddress user to retrieve staked balance from
    /// @return finalized staked of _userAddress
    function getStakedBalance(
        address _userAddress) external view returns (uint256);

    /// @notice Returns the timestamp when next deposit can be finalized
    /// @return timestamp of when finalizeStakes() is callable
    function getMaturingTimestamp(address _userAddress) external view returns (uint256);

    /// @notice Returns the timestamp when next withdraw can be finalized
    /// @return timestamp of when finalizeWithdraw() is callable
    function getReleasingTimestamp(address _userAddress) external view returns (uint256);


    /// @notice Returns the balance waiting/ready to be matured
    /// @return amount that will get staked after finalization
    function getMaturingBalance(address _userAddress) external view  returns (uint256);

    /// @notice Returns the balance waiting/ready to be released
    /// @return amount that will get withdrew after finalization
    function getReleasingBalance(address _userAddress) external view  returns (uint256);


    /// @notice Deposit CTSI to be staked. The money will turn into staked
    ///         balance after timeToStake days
    /// @param _amount The amount of tokens that are gonna be deposited.
    function stake(uint256 _amount) external;

    /// @notice Remove tokens from staked balance. The money can
    ///         be released after timeToRelease seconds, if the
    ///         function withdraw is called.
    /// @param _amount The amount of tokens that are gonna be unstaked.
    function unstake(uint256 _amount) external;

    /// @notice Transfer tokens to user's wallet.
    /// @param _amount The amount of tokens that are gonna be transferred.
    function withdraw(uint256 _amount) external;

    // events
    /// @notice CTSI tokens were deposited, they count as stake after _maturationDate
    /// @param user address of msg.sender
    /// @param amount amount deposited for staking
    /// @param maturationDate date when the stake can be finalized
    event Stake(
        address indexed user,
        uint256 amount,
        uint256 maturationDate
    );

    /// @notice Unstake tokens, moving them to releasing structure
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param maturationDate date when the tokens can be withdrew
    event Unstake(
        address indexed user,
        uint256 amount,
        uint256 maturationDate
    );

    /// @notice Withdraw process was finalized
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(
        address indexed user,
        uint256 amount
    );
}