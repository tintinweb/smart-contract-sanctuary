/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.5.12;

contract ICErc20 {
    address public underlying;
    function mint(uint256 mintAmount) external returns (uint);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
}


contract GemLike {
    function allowance(address, address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
}

contract ValueLike {
    function peek() public returns (uint, bool);
}

contract SaiTubLike {
    function skr() public view returns (GemLike);
    function gem() public view returns (GemLike);
    function gov() public view returns (GemLike);
    function sai() public view returns (GemLike);
    function pep() public view returns (ValueLike);
    function vox() public view returns (VoxLike);
    function bid(uint) public view returns (uint);
    function ink(bytes32) public view returns (uint);
    function tag() public view returns (uint);
    function tab(bytes32) public returns (uint);
    function rap(bytes32) public returns (uint);
    function draw(bytes32, uint) public;
    function shut(bytes32) public;
    function exit(uint) public;
    function give(bytes32, address) public;
}

contract VoxLike {
    function par() public returns (uint);
}

contract JoinLike {
    function ilk() public returns (bytes32);
    function gem() public returns (GemLike);
    function dai() public returns (GemLike);
    function join(address, uint) public;
    function exit(address, uint) public;
}
contract VatLike {
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function hope(address) public;
    function frob(bytes32, address, address, address, int, int) public;
}

contract ManagerLike {
    function vat() public view returns (address);
    function urns(uint) public view returns (address);
    function open(bytes32, address) public returns (uint);
    function frob(uint, int, int) public;
    function give(uint, address) public;
    function move(uint, address, uint) public;
}

contract OtcLike {
    function getPayAmount(address, address, uint) public view returns (uint);
    function buyAllAmount(address, uint, address, uint) public;
}
/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/



/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/



/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/





/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as `account`'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}



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






/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard is Initializable {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}



/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/



/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/



/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 */
library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}
/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */



/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* internal */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack.length = 0;
        tree.nodes.length = 0;
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.length--;
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* internal Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return The index at which leaves start, the values of the returned leaves, and whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) internal view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) internal view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

   function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
       SortitionSumTree storage tree = self.sortitionSumTrees[_key];
       if (tree.nodes.length == 0) {
           return 0;
       } else {
           return tree.nodes[0];
       }
   }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}



/**
 * @author Brendan Asselstine
 * @notice Tracks committed and open balances for addresses.  Affords selection of an address by indexing all committed balances.
 *
 * Balances are tracked in Draws.  There is always one open Draw.  Deposits are always added to the open Draw.
 * When a new draw is opened, the previous opened draw is committed.
 *
 * The committed balance for an address is the total of their balances for committed Draws.
 * An address's open balance is their balance in the open Draw.
 */
library DrawManager {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    using SafeMath for uint256;

    /**
     * The ID to use for the selection tree.
     */
    bytes32 public constant TREE_OF_DRAWS = "TreeOfDraws";

    uint8 public constant MAX_BRANCHES_PER_NODE = 10;

    /**
     * Stores information for all draws.
     */
    struct State {
        /**
         * Each Draw stores it's address balances in a sortitionSumTree.  Draw trees are indexed using the Draw index.
         * There is one root sortitionSumTree that stores all of the draw totals.  The root tree is indexed using the constant TREE_OF_DRAWS.
         */
        SortitionSumTreeFactory.SortitionSumTrees sortitionSumTrees;

        /**
         * Stores the consolidated draw index that an address deposited to.
         */
        mapping(address => uint256) consolidatedDrawIndices;

        /**
         * Stores the last Draw index that an address deposited to.
         */
        mapping(address => uint256) latestDrawIndices;

        /**
         * Stores a mapping of Draw index => Draw total
         */
        mapping(uint256 => uint256) __deprecated__drawTotals;

        /**
         * The current open Draw index
         */
        uint256 openDrawIndex;

        /**
         * The total of committed balances
         */
        uint256 __deprecated__committedSupply;
    }

    /**
     * @notice Opens the next Draw and commits the previous open Draw (if any).
     * @param self The drawState this library is attached to
     * @return The index of the new open Draw
     */
    function openNextDraw(State storage self) public returns (uint256) {
        if (self.openDrawIndex == 0) {
            // If there is no previous draw, we must initialize
            self.sortitionSumTrees.createTree(TREE_OF_DRAWS, MAX_BRANCHES_PER_NODE);
        } else {
            // else add current draw to sortition sum trees
            bytes32 drawId = bytes32(self.openDrawIndex);
            uint256 drawTotal = openSupply(self);
            self.sortitionSumTrees.set(TREE_OF_DRAWS, drawTotal, drawId);
        }
        // now create a new draw
        uint256 drawIndex = self.openDrawIndex.add(1);
        self.sortitionSumTrees.createTree(bytes32(drawIndex), MAX_BRANCHES_PER_NODE);
        self.openDrawIndex = drawIndex;

        return drawIndex;
    }

    /**
     * @notice Deposits the given amount into the current open draw by the given user.
     * @param self The DrawManager state
     * @param _addr The address to deposit for
     * @param _amount The amount to deposit
     */
    function deposit(State storage self, address _addr, uint256 _amount) public requireOpenDraw(self) onlyNonZero(_addr) {
        bytes32 userId = bytes32(uint256(_addr));
        uint256 openDrawIndex = self.openDrawIndex;

        // update the current draw
        uint256 currentAmount = self.sortitionSumTrees.stakeOf(bytes32(openDrawIndex), userId);
        currentAmount = currentAmount.add(_amount);
        drawSet(self, openDrawIndex, currentAmount, _addr);

        uint256 consolidatedDrawIndex = self.consolidatedDrawIndices[_addr];
        uint256 latestDrawIndex = self.latestDrawIndices[_addr];

        // if this is the user's first draw, set it
        if (consolidatedDrawIndex == 0) {
            self.consolidatedDrawIndices[_addr] = openDrawIndex;
        // otherwise, if the consolidated draw is not this draw
        } else if (consolidatedDrawIndex != openDrawIndex) {
            // if a second draw does not exist
            if (latestDrawIndex == 0) {
                // set the second draw to the current draw
                self.latestDrawIndices[_addr] = openDrawIndex;
            // otherwise if a second draw exists but is not the current one
            } else if (latestDrawIndex != openDrawIndex) {
                // merge it into the first draw, and update the second draw index to this one
                uint256 consolidatedAmount = self.sortitionSumTrees.stakeOf(bytes32(consolidatedDrawIndex), userId);
                uint256 latestAmount = self.sortitionSumTrees.stakeOf(bytes32(latestDrawIndex), userId);
                drawSet(self, consolidatedDrawIndex, consolidatedAmount.add(latestAmount), _addr);
                drawSet(self, latestDrawIndex, 0, _addr);
                self.latestDrawIndices[_addr] = openDrawIndex;
            }
        }
    }

    /**
     * @notice Deposits into a user's committed balance, thereby bypassing the open draw.
     * @param self The DrawManager state
     * @param _addr The address of the user for whom to deposit
     * @param _amount The amount to deposit
     */
    function depositCommitted(State storage self, address _addr, uint256 _amount) public requireCommittedDraw(self) onlyNonZero(_addr) {
        bytes32 userId = bytes32(uint256(_addr));
        uint256 consolidatedDrawIndex = self.consolidatedDrawIndices[_addr];

        // if they have a committed balance
        if (consolidatedDrawIndex != 0 && consolidatedDrawIndex != self.openDrawIndex) {
            uint256 consolidatedAmount = self.sortitionSumTrees.stakeOf(bytes32(consolidatedDrawIndex), userId);
            drawSet(self, consolidatedDrawIndex, consolidatedAmount.add(_amount), _addr);
        } else { // they must not have any committed balance
            self.latestDrawIndices[_addr] = consolidatedDrawIndex;
            self.consolidatedDrawIndices[_addr] = self.openDrawIndex.sub(1);
            drawSet(self, self.consolidatedDrawIndices[_addr], _amount, _addr);
        }
    }

    /**
     * @notice Withdraws a user's committed and open draws.
     * @param self The DrawManager state
     * @param _addr The address whose balance to withdraw
     */
    function withdraw(State storage self, address _addr) public requireOpenDraw(self) onlyNonZero(_addr) {
        uint256 consolidatedDrawIndex = self.consolidatedDrawIndices[_addr];
        uint256 latestDrawIndex = self.latestDrawIndices[_addr];

        if (consolidatedDrawIndex != 0) {
            drawSet(self, consolidatedDrawIndex, 0, _addr);
            delete self.consolidatedDrawIndices[_addr];
        }

        if (latestDrawIndex != 0) {
            drawSet(self, latestDrawIndex, 0, _addr);
            delete self.latestDrawIndices[_addr];
        }
    }

    /**
     * @notice Withdraw's from a user's open balance
     * @param self The DrawManager state
     * @param _addr The user to withdrawn from
     * @param _amount The amount to withdraw
     */
    function withdrawOpen(State storage self, address _addr, uint256 _amount) public requireOpenDraw(self) onlyNonZero(_addr) {
        bytes32 userId = bytes32(uint256(_addr));
        uint256 openTotal = self.sortitionSumTrees.stakeOf(bytes32(self.openDrawIndex), userId);

        require(_amount <= openTotal, "DrawMan/exceeds-open");

        uint256 remaining = openTotal.sub(_amount);

        drawSet(self, self.openDrawIndex, remaining, _addr);
    }

    /**
     * @notice Withdraw's from a user's committed balance.  Fails if the user attempts to take more than available.
     * @param self The DrawManager state
     * @param _addr The user to withdraw from
     * @param _amount The amount to withdraw.
     */
    function withdrawCommitted(State storage self, address _addr, uint256 _amount) public requireCommittedDraw(self) onlyNonZero(_addr) {
        bytes32 userId = bytes32(uint256(_addr));
        uint256 consolidatedDrawIndex = self.consolidatedDrawIndices[_addr];
        uint256 latestDrawIndex = self.latestDrawIndices[_addr];

        uint256 consolidatedAmount = 0;
        uint256 latestAmount = 0;
        uint256 total = 0;

        if (latestDrawIndex != 0 && latestDrawIndex != self.openDrawIndex) {
            latestAmount = self.sortitionSumTrees.stakeOf(bytes32(latestDrawIndex), userId);
            total = total.add(latestAmount);
        }

        if (consolidatedDrawIndex != 0 && consolidatedDrawIndex != self.openDrawIndex) {
            consolidatedAmount = self.sortitionSumTrees.stakeOf(bytes32(consolidatedDrawIndex), userId);
            total = total.add(consolidatedAmount);
        }

        // If the total is greater than zero, then consolidated *must* have the committed balance
        // However, if the total is zero then the consolidated balance may be the open balance
        if (total == 0) {
            return;
        }

        require(_amount <= total, "Pool/exceed");

        uint256 remaining = total.sub(_amount);

        // if there was a second amount that needs to be updated
        if (remaining > consolidatedAmount) {
            uint256 secondRemaining = remaining.sub(consolidatedAmount);
            drawSet(self, latestDrawIndex, secondRemaining, _addr);
        } else if (latestAmount > 0) { // else delete the second amount if it exists
            delete self.latestDrawIndices[_addr];
            drawSet(self, latestDrawIndex, 0, _addr);
        }

        // if the consolidated amount needs to be destroyed
        if (remaining == 0) {
            delete self.consolidatedDrawIndices[_addr];
            drawSet(self, consolidatedDrawIndex, 0, _addr);
        } else if (remaining < consolidatedAmount) {
            drawSet(self, consolidatedDrawIndex, remaining, _addr);
        }
    }

    /**
     * @notice Returns the total balance for an address, including committed balances and the open balance.
     */
    function balanceOf(State storage drawState, address _addr) public view returns (uint256) {
        return committedBalanceOf(drawState, _addr).add(openBalanceOf(drawState, _addr));
    }

    /**
     * @notice Returns the total committed balance for an address.
     * @param self The DrawManager state
     * @param _addr The address whose committed balance should be returned
     * @return The total committed balance
     */
    function committedBalanceOf(State storage self, address _addr) public view returns (uint256) {
        uint256 balance = 0;

        uint256 consolidatedDrawIndex = self.consolidatedDrawIndices[_addr];
        uint256 latestDrawIndex = self.latestDrawIndices[_addr];

        if (consolidatedDrawIndex != 0 && consolidatedDrawIndex != self.openDrawIndex) {
            balance = self.sortitionSumTrees.stakeOf(bytes32(consolidatedDrawIndex), bytes32(uint256(_addr)));
        }

        if (latestDrawIndex != 0 && latestDrawIndex != self.openDrawIndex) {
            balance = balance.add(self.sortitionSumTrees.stakeOf(bytes32(latestDrawIndex), bytes32(uint256(_addr))));
        }

        return balance;
    }

    /**
     * @notice Returns the open balance for an address
     * @param self The DrawManager state
     * @param _addr The address whose open balance should be returned
     * @return The open balance
     */
    function openBalanceOf(State storage self, address _addr) public view returns (uint256) {
        if (self.openDrawIndex == 0) {
            return 0;
        } else {
            return self.sortitionSumTrees.stakeOf(bytes32(self.openDrawIndex), bytes32(uint256(_addr)));
        }
    }

    /**
     * @notice Returns the open Draw balance for the DrawManager
     * @param self The DrawManager state
     * @return The open draw total balance
     */
    function openSupply(State storage self) public view returns (uint256) {
        return self.sortitionSumTrees.total(bytes32(self.openDrawIndex));
    }

    /**
     * @notice Returns the committed balance for the DrawManager
     * @param self The DrawManager state
     * @return The total committed balance
     */
    function committedSupply(State storage self) public view returns (uint256) {
        return self.sortitionSumTrees.total(TREE_OF_DRAWS);
    }

    /**
     * @notice Updates the Draw balance for an address.
     * @param self The DrawManager state
     * @param _drawIndex The Draw index
     * @param _amount The new balance
     * @param _addr The address whose balance should be updated
     */
    function drawSet(State storage self, uint256 _drawIndex, uint256 _amount, address _addr) internal {
        bytes32 drawId = bytes32(_drawIndex);
        bytes32 userId = bytes32(uint256(_addr));
        uint256 oldAmount = self.sortitionSumTrees.stakeOf(drawId, userId);

        if (oldAmount != _amount) {
            // If the amount has changed

            // Update the Draw's balance for that address
            self.sortitionSumTrees.set(drawId, _amount, userId);

            // if the draw is committed
            if (_drawIndex != self.openDrawIndex) {
                // Get the new draw total
                uint256 newDrawTotal = self.sortitionSumTrees.total(drawId);

                // update the draw in the committed tree
                self.sortitionSumTrees.set(TREE_OF_DRAWS, newDrawTotal, drawId);
            }
        }
    }

   /**
     * @notice Selects an address by indexing into the committed tokens using the passed token.
     * If there is no committed supply, the zero address is returned.
     * @param self The DrawManager state
     * @param _token The token index to select
     * @return The selected address
     */
    function draw(State storage self, uint256 _token) public view returns (address) {
        // If there is no one to select, just return the zero address
        if (committedSupply(self) == 0) {
            return address(0);
        }
        require(_token < committedSupply(self), "Pool/ineligible");
        bytes32 drawIndex = self.sortitionSumTrees.draw(TREE_OF_DRAWS, _token);
        uint256 drawSupply = self.sortitionSumTrees.total(drawIndex);
        uint256 drawToken = _token % drawSupply;
        return address(uint256(self.sortitionSumTrees.draw(drawIndex, drawToken)));
    }

    /**
     * @notice Selects an address using the entropy as an index into the committed tokens
     * The entropy is passed into the UniformRandomNumber library to remove modulo bias.
     * @param self The DrawManager state
     * @param _entropy The random entropy to use
     * @return The selected address
     */
    function drawWithEntropy(State storage self, bytes32 _entropy) public view returns (address) {
        uint256 bound = committedSupply(self);
        address selected;
        if (bound == 0) {
            selected = address(0);
        } else {
            selected = draw(self, UniformRandomNumber.uniform(uint256(_entropy), bound));
        }
        return selected;
    }

    modifier requireOpenDraw(State storage self) {
        require(self.openDrawIndex > 0, "Pool/no-open");
        _;
    }

    modifier requireCommittedDraw(State storage self) {
        require(self.openDrawIndex > 1, "Pool/no-commit");
        _;
    }

    modifier onlyNonZero(address _addr) {
        require(_addr != address(0), "Pool/not-zero");
        _;
    }
}



/**
 * @title FixidityLib
 * @author Gadi Guy, Alberto Cuesta Canada
 * @notice This library provides fixed point arithmetic with protection against
 * overflow. 
 * All operations are done with int256 and the operands must have been created 
 * with any of the newFrom* functions, which shift the comma digits() to the 
 * right and check for limits.
 * When using this library be sure of using maxNewFixed() as the upper limit for
 * creation of fixed point numbers. Use maxFixedMul(), maxFixedDiv() and
 * maxFixedAdd() if you want to be certain that those operations don't 
 * overflow.
 */
library FixidityLib {

    /**
     * @notice Number of positions that the comma is shifted to the right.
     */
    function digits() public pure returns(uint8) {
        return 24;
    }
    
    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 10^digits()
     * Hardcoded to 24 digits.
     */
    function fixed1() public pure returns(int256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() public pure returns(int256) {
        return 1000000000000;
    }

    /**
     * @notice Maximum value that can be represented in an int256
     * @dev Test maxInt256() equals 2^255 -1
     */
    function maxInt256() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * @notice Minimum value that can be represented in an int256
     * @dev Test minInt256 equals (2^255) * (-1)
     */
    function minInt256() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * @dev deployment. 
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Minimum value that can be converted to fixed point. Optimize for
     * deployment. 
     * @dev Test minNewFixed() equals -(maxInt256()) / fixed1()
     * Hardcoded to 24 digits.
     */
    function minNewFixed() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as an addition operator.
     * @dev Test maxFixedAdd() equals maxInt256()-1 / 2
     * Test add(maxFixedAdd(),maxFixedAdd()) equals maxFixedAdd() + maxFixedAdd()
     * Test add(maxFixedAdd()+1,maxFixedAdd()) throws 
     * Test add(-maxFixedAdd(),-maxFixedAdd()) equals -maxFixedAdd() - maxFixedAdd()
     * Test add(-maxFixedAdd(),-maxFixedAdd()-1) throws 
     */
    function maxFixedAdd() public pure returns(int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * @notice Maximum negative value that can be safely in a subtraction.
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() public pure returns(int256) {
        return -28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }

    /**
     * @notice Maximum value that can be safely used as a multiplication operator.
     * @dev Calculated as sqrt(maxInt256()*fixed1()). 
     * Be careful with your sqrt() implementation. I couldn't find a calculator
     * that would give the exact square root of maxInt256*fixed1 so this number
     * is below the real number by no more than 3*10**28. It is safe to use as
     * a limit for your multiplications, although powers of two of numbers over
     * this value might still work.
     * Test multiply(maxFixedMul(),maxFixedMul()) equals maxFixedMul() * maxFixedMul()
     * Test multiply(maxFixedMul(),maxFixedMul()+1) throws 
     * Test multiply(-maxFixedMul(),maxFixedMul()) equals -maxFixedMul() * maxFixedMul()
     * Test multiply(-maxFixedMul(),maxFixedMul()+1) throws 
     * Hardcoded to 24 digits.
     */
    function maxFixedMul() public pure returns(int256) {
        return 240615969168004498257251713877715648331380787511296;
    }

    /**
     * @notice Maximum value that can be safely used as a dividend.
     * @dev divide(maxFixedDiv,newFixedFraction(1,fixed1())) = maxInt256().
     * Test maxFixedDiv() equals maxInt256()/fixed1()
     * Test divide(maxFixedDiv(),multiply(mulPrecision(),mulPrecision())) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,multiply(mulPrecision(),mulPrecision())) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDiv() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as a divisor.
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() public pure returns(int256) {
        return 1000000000000000000000000000000000000000000000000;
    }

    /**
     * @notice Converts an int256 to fixed point units, equivalent to multiplying
     * by 10^digits().
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(int256 x)
        public
        pure
        returns (int256)
    {
        require(x <= maxNewFixed());
        require(x >= minNewFixed());
        return x * fixed1();
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(int256 x)
        public
        pure
        returns (int256)
    {
        return x / fixed1();
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to a different fixed precision representation.
     * Both the origin and destination precisions must be 38 or less digits.
     * Origin values with a precision higher than the destination precision
     * will be truncated accordingly.
     * @dev 
     * Test convertFixed(1,0,0) returns 1;
     * Test convertFixed(1,1,1) returns 1;
     * Test convertFixed(1,1,0) returns 0;
     * Test convertFixed(1,0,1) returns 10;
     * Test convertFixed(10,1,0) returns 1;
     * Test convertFixed(10,0,1) returns 100;
     * Test convertFixed(100,1,0) returns 10;
     * Test convertFixed(100,0,1) returns 1000;
     * Test convertFixed(1000,2,0) returns 10;
     * Test convertFixed(1000,0,2) returns 100000;
     * Test convertFixed(1000,2,1) returns 100;
     * Test convertFixed(1000,1,2) returns 10000;
     * Test convertFixed(maxInt256,1,0) returns maxInt256/10;
     * Test convertFixed(maxInt256,0,1) throws
     * Test convertFixed(maxInt256,38,0) returns maxInt256/(10**38);
     * Test convertFixed(1,0,38) returns 10**38;
     * Test convertFixed(maxInt256,39,0) throws
     * Test convertFixed(1,0,39) throws
     */
    function convertFixed(int256 x, uint8 _originDigits, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        require(_originDigits <= 38 && _destinationDigits <= 38);
        
        uint8 decimalDifference;
        if ( _originDigits > _destinationDigits ){
            decimalDifference = _originDigits - _destinationDigits;
            return x/(uint128(10)**uint128(decimalDifference));
        }
        else if ( _originDigits < _destinationDigits ){
            decimalDifference = _destinationDigits - _originDigits;
            // Cast uint8 -> uint128 is safe
            // Exponentiation is safe:
            //     _originDigits and _destinationDigits limited to 38 or less
            //     decimalDifference = abs(_destinationDigits - _originDigits)
            //     decimalDifference < 38
            //     10**38 < 2**128-1
            require(x <= maxInt256()/uint128(10)**uint128(decimalDifference));
            require(x >= minInt256()/uint128(10)**uint128(decimalDifference));
            return x*(uint128(10)**uint128(decimalDifference));
        }
        // _originDigits == digits()) 
        return x;
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to that of this library. The _originDigits parameter is the
     * precision of x. Values with a precision higher than FixidityLib.digits()
     * will be truncated accordingly.
     */
    function newFixed(int256 x, uint8 _originDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, _originDigits, digits());
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a different representation. The _destinationDigits parameter is the
     * precision of the output x. Values with a precision below than 
     * FixidityLib.digits() will be truncated accordingly.
     */
    function fromFixed(int256 x, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, digits(), _destinationDigits);
    }

    /**
     * @notice Converts two int256 representing a fraction to fixed point units,
     * equivalent to multiplying dividend and divisor by 10^digits().
     * @dev 
     * Test newFixedFraction(maxFixedDiv()+1,1) fails
     * Test newFixedFraction(1,maxFixedDiv()+1) fails
     * Test newFixedFraction(1,0) fails     
     * Test newFixedFraction(0,1) returns 0
     * Test newFixedFraction(1,1) returns fixed1()
     * Test newFixedFraction(maxFixedDiv(),1) returns maxFixedDiv()*fixed1()
     * Test newFixedFraction(1,fixed1()) returns 1
     * Test newFixedFraction(1,fixed1()-1) returns 0
     */
    function newFixedFraction(
        int256 numerator, 
        int256 denominator
        )
        public
        pure
        returns (int256)
    {
        require(numerator <= maxNewFixed());
        require(denominator <= maxNewFixed());
        require(denominator != 0);
        int256 convertedNumerator = newFixed(numerator);
        int256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }

    /**
     * @notice Returns the integer part of a fixed point number.
     * @dev 
     * Test integer(0) returns 0
     * Test integer(fixed1()) returns fixed1()
     * Test integer(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test integer(-fixed1()) returns -fixed1()
     * Test integer(newFixed(-maxNewFixed())) returns -maxNewFixed()*fixed1()
     */
    function integer(int256 x) public pure returns (int256) {
        return (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Returns the fractional part of a fixed point number. 
     * In the case of a negative number the fractional is also negative.
     * @dev 
     * Test fractional(0) returns 0
     * Test fractional(fixed1()) returns 0
     * Test fractional(fixed1()-1) returns 10^24-1
     * Test fractional(-fixed1()) returns 0
     * Test fractional(-fixed1()+1) returns -10^24-1
     */
    function fractional(int256 x) public pure returns (int256) {
        return x - (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Converts to positive if negative.
     * Due to int256 having one more negative number than positive numbers 
     * abs(minInt256) reverts.
     * @dev 
     * Test abs(0) returns 0
     * Test abs(fixed1()) returns -fixed1()
     * Test abs(-fixed1()) returns fixed1()
     * Test abs(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test abs(newFixed(minNewFixed())) returns -minNewFixed()*fixed1()
     */
    function abs(int256 x) public pure returns (int256) {
        if (x >= 0) {
            return x;
        } else {
            int256 result = -x;
            assert (result > 0);
            return result;
        }
    }

    /**
     * @notice x+y. If any operator is higher than maxFixedAdd() it 
     * might overflow.
     * In solidity maxInt256 + 1 = minInt256 and viceversa.
     * @dev 
     * Test add(maxFixedAdd(),maxFixedAdd()) returns maxInt256()-1
     * Test add(maxFixedAdd()+1,maxFixedAdd()+1) fails
     * Test add(-maxFixedSub(),-maxFixedSub()) returns minInt256()
     * Test add(-maxFixedSub()-1,-maxFixedSub()-1) fails
     * Test add(maxInt256(),maxInt256()) fails
     * Test add(minInt256(),minInt256()) fails
     */
    function add(int256 x, int256 y) public pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(int256 x, int256 y) public pure returns (int256) {
        return add(x,-y);
    }

    /**
     * @notice x*y. If any of the operators is higher than maxFixedMul() it 
     * might overflow.
     * @dev 
     * Test multiply(0,0) returns 0
     * Test multiply(maxFixedMul(),0) returns 0
     * Test multiply(0,maxFixedMul()) returns 0
     * Test multiply(maxFixedMul(),fixed1()) returns maxFixedMul()
     * Test multiply(fixed1(),maxFixedMul()) returns maxFixedMul()
     * Test all combinations of (2,-2), (2, 2.5), (2, -2.5) and (0.5, -0.5)
     * Test multiply(fixed1()/mulPrecision(),fixed1()*mulPrecision())
     * Test multiply(maxFixedMul()-1,maxFixedMul()) equals multiply(maxFixedMul(),maxFixedMul()-1)
     * Test multiply(maxFixedMul(),maxFixedMul()) returns maxInt256() // Probably not to the last digits
     * Test multiply(maxFixedMul()+1,maxFixedMul()) fails
     * Test multiply(maxFixedMul(),maxFixedMul()+1) fails
     */
    function multiply(int256 x, int256 y) public pure returns (int256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        int256 x1 = integer(x) / fixed1();
        int256 x2 = fractional(x);
        int256 y1 = integer(y) / fixed1();
        int256 y2 = fractional(y);
        
        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        int256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1); // Overflow x1y1
        
        // x1y1 needs to be multiplied back by fixed1
        // solium-disable-next-line mixedcase
        int256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1()); // Overflow x1y1 * fixed1
        x1y1 = fixed_x1y1;

        int256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1); // Overflow x2y1

        int256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2); // Overflow x1y2

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        int256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2); // Overflow x2y2

        // result = fixed1() * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixed1();
        int256 result = x1y1;
        result = add(result, x2y1); // Add checks for overflow
        result = add(result, x1y2); // Add checks for overflow
        result = add(result, x2y2); // Add checks for overflow
        return result;
    }
    
    /**
     * @notice 1/x
     * @dev 
     * Test reciprocal(0) fails
     * Test reciprocal(fixed1()) returns fixed1()
     * Test reciprocal(fixed1()*fixed1()) returns 1 // Testing how the fractional is truncated
     * Test reciprocal(2*fixed1()*fixed1()) returns 0 // Testing how the fractional is truncated
     */
    function reciprocal(int256 x) public pure returns (int256) {
        require(x != 0);
        return (fixed1()*fixed1()) / x; // Can't overflow
    }

    /**
     * @notice x/y. If the dividend is higher than maxFixedDiv() it 
     * might overflow. You can use multiply(x,reciprocal(y)) instead.
     * There is a loss of precision on division for the lower mulPrecision() decimals.
     * @dev 
     * Test divide(fixed1(),0) fails
     * Test divide(maxFixedDiv(),1) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,1) throws
     * Test divide(maxFixedDiv(),maxFixedDiv()) returns fixed1()
     */
    function divide(int256 x, int256 y) public pure returns (int256) {
        if (y == fixed1()) return x;
        require(y != 0);
        require(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}






/**
 * @title Blocklock
 * @author Brendan Asselstine
 * @notice A time lock with a cooldown period.  When locked, the contract will remain locked until it is unlocked manually
 * or the lock duration expires.  After the contract is unlocked, it cannot be locked until the cooldown duration expires.
 */
library Blocklock {
  using SafeMath for uint256;

  struct State {
    uint256 lockedAt;
    uint256 unlockedAt;
    uint256 lockDuration;
    uint256 cooldownDuration;
  }

  /**
   * @notice Sets the duration of the lock.  This how long the lock lasts before it expires and automatically unlocks.
   * @param self The Blocklock state
   * @param lockDuration The duration, in blocks, that the lock should last.
   */
  function setLockDuration(State storage self, uint256 lockDuration) public {
    require(lockDuration > 0, "Blocklock/lock-min");
    self.lockDuration = lockDuration;
  }

  /**
   * @notice Sets the cooldown duration in blocks.  This is the number of blocks that must pass before being able to
   * lock again.  The cooldown duration begins when the lock duration expires, or when it is unlocked manually.
   * @param self The Blocklock state
   * @param cooldownDuration The duration of the cooldown, in blocks.
   */
  function setCooldownDuration(State storage self, uint256 cooldownDuration) public {
    require(cooldownDuration > 0, "Blocklock/cool-min");
    self.cooldownDuration = cooldownDuration;
  }

  /**
   * @notice Returns whether the state is locked at the given block number.
   * @param self The Blocklock state
   * @param blockNumber The current block number.
   */
  function isLocked(State storage self, uint256 blockNumber) public view returns (bool) {
    uint256 endAt = lockEndAt(self);
    return (
      self.lockedAt != 0 &&
      blockNumber >= self.lockedAt &&
      blockNumber < endAt
    );
  }

  /**
   * @notice Locks the state at the given block number.
   * @param self The Blocklock state
   * @param blockNumber The block number to use as the lock start time
   */
  function lock(State storage self, uint256 blockNumber) public {
    require(canLock(self, blockNumber), "Blocklock/no-lock");
    self.lockedAt = blockNumber;
  }

  /**
   * @notice Manually unlocks the lock.
   * @param self The Blocklock state
   * @param blockNumber The block number at which the lock is being unlocked.
   */
  function unlock(State storage self, uint256 blockNumber) public {
    self.unlockedAt = blockNumber;
  }

  /**
   * @notice Returns whether the Blocklock can be locked at the given block number
   * @param self The Blocklock state
   * @param blockNumber The block number to check against
   * @return True if we can lock at the given block number, false otherwise.
   */
  function canLock(State storage self, uint256 blockNumber) public view returns (bool) {
    uint256 endAt = lockEndAt(self);
    return (
      self.lockedAt == 0 ||
      blockNumber >= endAt.add(self.cooldownDuration)
    );
  }

  function cooldownEndAt(State storage self) internal view returns (uint256) {
    return lockEndAt(self).add(self.cooldownDuration);
  }

  function lockEndAt(State storage self) internal view returns (uint256) {
    uint256 endAt = self.lockedAt.add(self.lockDuration);
    // if we unlocked early
    if (self.unlockedAt >= self.lockedAt && self.unlockedAt < endAt) {
      endAt = self.unlockedAt;
    }
    return endAt;
  }
}

/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/








/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}




/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 *  their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}




/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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



/**
 * @dev Implementation of the {IERC777} interface.
 *
 * Largely taken from the OpenZeppelin ERC777 contract.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 *
 * It is important to note that no Mint events are emitted.  Tokens are minted in batches
 * by a state change in a tree data structure, so emitting a Mint event for each user
 * is not possible.
 *
 */
contract PoolToken is Initializable, IERC20, IERC777 {
  using SafeMath for uint256;
  using Address for address;

  /**
   * Event emitted when a user or operator redeems tokens
   */
  event Redeemed(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  // We inline the result of the following hashes because Solidity doesn't resolve them at compile time.
  // See https://github.com/ethereum/solidity/issues/4024.

  // keccak256("ERC777TokensSender")
  bytes32 constant internal TOKENS_SENDER_INTERFACE_HASH =
      0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
      0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  // keccak256("ERC777Token")
  bytes32 constant internal TOKENS_INTERFACE_HASH =
      0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;

  // keccak256("ERC20Token")
  bytes32 constant internal ERC20_TOKENS_INTERFACE_HASH =
      0xaea199e31a596269b42cdafd93407f14436db6e4cad65417994c2eb37381e05a;

  string internal _name;
  string internal _symbol;

  // This isn't ever read from - it's only used to respond to the defaultOperators query.
  address[] internal _defaultOperatorsArray;

  // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
  mapping(address => bool) internal _defaultOperators;

  // For each account, a mapping of its operators and revoked default operators.
  mapping(address => mapping(address => bool)) internal _operators;
  mapping(address => mapping(address => bool)) internal _revokedDefaultOperators;

  // ERC20-allowances
  mapping (address => mapping (address => uint256)) internal _allowances;

  // The Pool that is bound to this token
  BasePool internal _pool;

  /**
   * @notice Initializes the PoolToken.
   * @param name The name of the token
   * @param symbol The token symbol
   * @param defaultOperators The default operators who are allowed to move tokens
   */
  function init (
    string memory name,
    string memory symbol,
    address[] memory defaultOperators,
    BasePool pool
  ) public initializer {
      require(bytes(name).length != 0, "PoolToken/name");
      require(bytes(symbol).length != 0, "PoolToken/symbol");
      require(address(pool) != address(0), "PoolToken/pool-zero");

      _name = name;
      _symbol = symbol;
      _pool = pool;

      _defaultOperatorsArray = defaultOperators;
      for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
          _defaultOperators[_defaultOperatorsArray[i]] = true;
      }

      // register interfaces
      ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_INTERFACE_HASH, address(this));
      ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC20_TOKENS_INTERFACE_HASH, address(this));
  }

  /**
   * @notice Returns the address of the Pool contract
   * @return The address of the pool contract
   */
  function pool() public view returns (BasePool) {
      return _pool;
  }

  /**
   * @notice Calls the ERC777 transfer hook, and emits Redeemed and Transfer.  Can only be called by the Pool contract.
   * @param from The address from which to redeem tokens
   * @param amount The amount of tokens to redeem
   */
  function poolRedeem(address from, uint256 amount) external onlyPool {
      _callTokensToSend(from, from, address(0), amount, '', '');

      emit Redeemed(from, from, amount, '', '');
      emit Transfer(from, address(0), amount);
  }

  /**
    * @dev See {IERC777-name}.
    */
  function name() public view returns (string memory) {
      return _name;
  }

  /**
    * @dev See {IERC777-symbol}.
    */
  function symbol() public view returns (string memory) {
      return _symbol;
  }

  /**
    * @dev See {ERC20Detailed-decimals}.
    *
    * Always returns 18, as per the
    * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
    */
  function decimals() public view returns (uint8) {
      return 18;
  }

  /**
    * @dev See {IERC777-granularity}.
    *
    * This implementation always returns `1`.
    */
  function granularity() public view returns (uint256) {
      return 1;
  }

  /**
    * @dev See {IERC777-totalSupply}.
    */
  function totalSupply() public view returns (uint256) {
      return _pool.committedSupply();
  }

  /**
    * @dev See {IERC20-balanceOf}.
    */
  function balanceOf(address _addr) external view returns (uint256) {
      return _pool.committedBalanceOf(_addr);
  }

  /**
    * @dev See {IERC777-send}.
    *
    * Also emits a {Transfer} event for ERC20 compatibility.
    */
  function send(address recipient, uint256 amount, bytes calldata data) external {
      _send(msg.sender, msg.sender, recipient, amount, data, "");
  }

  /**
    * @dev See {IERC20-transfer}.
    *
    * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
    * interface if it is a contract.
    *
    * Also emits a {Sent} event.
    */
  function transfer(address recipient, uint256 amount) external returns (bool) {
      require(recipient != address(0), "PoolToken/transfer-zero");

      address from = msg.sender;

      _callTokensToSend(from, from, recipient, amount, "", "");

      _move(from, from, recipient, amount, "", "");

      _callTokensReceived(from, from, recipient, amount, "", "", false);

      return true;
  }

  /**
    * @dev Allows a user to withdraw their tokens as the underlying asset.
    *
    * Also emits a {Transfer} event for ERC20 compatibility.
    */
  function redeem(uint256 amount, bytes calldata data) external {
      _redeem(msg.sender, msg.sender, amount, data, "");
  }

  /**
    * @dev See {IERC777-burn}.  Not currently implemented.
    *
    * Also emits a {Transfer} event for ERC20 compatibility.
    */
  function burn(uint256, bytes calldata) external {
      revert("PoolToken/no-support");
  }

  /**
    * @dev See {IERC777-isOperatorFor}.
    */
  function isOperatorFor(
      address operator,
      address tokenHolder
  ) public view returns (bool) {
      return operator == tokenHolder ||
          (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
          _operators[tokenHolder][operator];
  }

  /**
    * @dev See {IERC777-authorizeOperator}.
    */
  function authorizeOperator(address operator) external {
      require(msg.sender != operator, "PoolToken/auth-self");

      if (_defaultOperators[operator]) {
          delete _revokedDefaultOperators[msg.sender][operator];
      } else {
          _operators[msg.sender][operator] = true;
      }

      emit AuthorizedOperator(operator, msg.sender);
  }

  /**
    * @dev See {IERC777-revokeOperator}.
    */
  function revokeOperator(address operator) external {
      require(operator != msg.sender, "PoolToken/revoke-self");

      if (_defaultOperators[operator]) {
          _revokedDefaultOperators[msg.sender][operator] = true;
      } else {
          delete _operators[msg.sender][operator];
      }

      emit RevokedOperator(operator, msg.sender);
  }

  /**
    * @dev See {IERC777-defaultOperators}.
    */
  function defaultOperators() public view returns (address[] memory) {
      return _defaultOperatorsArray;
  }

  /**
    * @dev See {IERC777-operatorSend}.
    *
    * Emits {Sent} and {Transfer} events.
    */
  function operatorSend(
      address sender,
      address recipient,
      uint256 amount,
      bytes calldata data,
      bytes calldata operatorData
  )
  external
  {
      require(isOperatorFor(msg.sender, sender), "PoolToken/not-operator");
      _send(msg.sender, sender, recipient, amount, data, operatorData);
  }

  /**
    * @dev See {IERC777-operatorBurn}.
    *
    * Currently not supported
    */
  function operatorBurn(address, uint256, bytes calldata, bytes calldata) external {
      revert("PoolToken/no-support");
  }

  /**
    * @dev Allows an operator to redeem tokens for the underlying asset on behalf of a user.
    *
    * Emits {Redeemed} and {Transfer} events.
    */
  function operatorRedeem(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
      require(isOperatorFor(msg.sender, account), "PoolToken/not-operator");
      _redeem(msg.sender, account, amount, data, operatorData);
  }

  /**
    * @dev See {IERC20-allowance}.
    *
    * Note that operator and allowance concepts are orthogonal: operators may
    * not have allowance, and accounts with allowance may not be operators
    * themselves.
    */
  function allowance(address holder, address spender) public view returns (uint256) {
      return _allowances[holder][spender];
  }

  /**
    * @dev See {IERC20-approve}.
    *
    * Note that accounts cannot have allowance issued by their operators.
    */
  function approve(address spender, uint256 value) external returns (bool) {
      address holder = msg.sender;
      _approve(holder, spender, value);
      return true;
  }

  /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
      return true;
  }

  /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "PoolToken/negative"));
      return true;
  }

  /**
  * @dev See {IERC20-transferFrom}.
  *
  * Note that operator and allowance concepts are orthogonal: operators cannot
  * call `transferFrom` (unless they have allowance), and accounts with
  * allowance cannot call `operatorSend` (unless they are operators).
  *
  * Emits {Sent}, {Transfer} and {Approval} events.
  */
  function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
      require(recipient != address(0), "PoolToken/to-zero");
      require(holder != address(0), "PoolToken/from-zero");

      address spender = msg.sender;

      _callTokensToSend(spender, holder, recipient, amount, "", "");

      _move(spender, holder, recipient, amount, "", "");
      _approve(holder, spender, _allowances[holder][spender].sub(amount, "PoolToken/exceed-allow"));

      _callTokensReceived(spender, holder, recipient, amount, "", "", false);

      return true;
  }

  /**
   * Called by the associated Pool to emit `Mint` events.
   * @param amount The amount that was minted
   */
  function poolMint(uint256 amount) external onlyPool {
    _mintEvents(address(_pool), address(_pool), amount, '', '');
  }

  /**
    * Emits {Minted} and {IERC20-Transfer} events.
    */
  function _mintEvents(
      address operator,
      address account,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
  )
  internal
  {
      emit Minted(operator, account, amount, userData, operatorData);
      emit Transfer(address(0), account, amount);
  }

  /**
    * @dev Send tokens
    * @param operator address operator requesting the transfer
    * @param from address token holder address
    * @param to address recipient address
    * @param amount uint256 amount of tokens to transfer
    * @param userData bytes extra information provided by the token holder (if any)
    * @param operatorData bytes extra information provided by the operator (if any)
    */
  function _send(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
  )
      private
  {
      require(from != address(0), "PoolToken/from-zero");
      require(to != address(0), "PoolToken/to-zero");

      _callTokensToSend(operator, from, to, amount, userData, operatorData);

      _move(operator, from, to, amount, userData, operatorData);

      _callTokensReceived(operator, from, to, amount, userData, operatorData, false);
  }

  /**
    * @dev Redeems tokens for the underlying asset.
    * @param operator address operator requesting the operation
    * @param from address token holder address
    * @param amount uint256 amount of tokens to redeem
    * @param data bytes extra information provided by the token holder
    * @param operatorData bytes extra information provided by the operator (if any)
    */
  function _redeem(
      address operator,
      address from,
      uint256 amount,
      bytes memory data,
      bytes memory operatorData
  )
      private
  {
      require(from != address(0), "PoolToken/from-zero");

      _callTokensToSend(operator, from, address(0), amount, data, operatorData);

      _pool.withdrawCommittedDepositFrom(from, amount);

      emit Redeemed(operator, from, amount, data, operatorData);
      emit Transfer(from, address(0), amount);
  }

  /**
   * @notice Moves tokens from one user to another.  Emits Sent and Transfer events.
   */
  function _move(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
  )
      private
  {
      _pool.moveCommitted(from, to, amount);

      emit Sent(operator, from, to, amount, userData, operatorData);
      emit Transfer(from, to, amount);
  }

  /**
   * Approves of a token spend by a spender for a holder.
   * @param holder The address from which the tokens are spent
   * @param spender The address that is spending the tokens
   * @param value The amount of tokens to spend
   */
  function _approve(address holder, address spender, uint256 value) private {
      require(spender != address(0), "PoolToken/from-zero");

      _allowances[holder][spender] = value;
      emit Approval(holder, spender, value);
  }

  /**
    * @dev Call from.tokensToSend() if the interface is registered
    * @param operator address operator requesting the transfer
    * @param from address token holder address
    * @param to address recipient address
    * @param amount uint256 amount of tokens to transfer
    * @param userData bytes extra information provided by the token holder (if any)
    * @param operatorData bytes extra information provided by the operator (if any)
    */
  function _callTokensToSend(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
  )
      internal notLocked
  {
      address implementer = ERC1820_REGISTRY.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
      if (implementer != address(0)) {
          IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
      }
  }

  /**
    * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
    * tokensReceived() was not registered for the recipient
    * @param operator address operator requesting the transfer
    * @param from address token holder address
    * @param to address recipient address
    * @param amount uint256 amount of tokens to transfer
    * @param userData bytes extra information provided by the token holder (if any)
    * @param operatorData bytes extra information provided by the operator (if any)
    * @param requireReceptionAck whether to require that, if the recipient is a contract, it has registered a IERC777Recipient
    */
  function _callTokensReceived(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData,
      bool requireReceptionAck
  )
      private
  {
      address implementer = ERC1820_REGISTRY.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
      if (implementer != address(0)) {
          IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
      } else if (requireReceptionAck) {
          require(!to.isContract(), "PoolToken/no-recip-inter");
      }
  }

  /**
   * @notice Requires the sender to be the pool contract
   */
  modifier onlyPool() {
    require(msg.sender == address(_pool), "PoolToken/only-pool");
    _;
  }

  /**
   * @notice Requires the contract to be unlocked
   */
  modifier notLocked() {
    require(!_pool.isLocked(), "PoolToken/is-locked");
    _;
  }
}


/**
 * @title The Pool contract
 * @author Brendan Asselstine
 * @notice This contract allows users to pool deposits into Compound and win the accrued interest in periodic draws.
 * Funds are immediately deposited and withdrawn from the Compound cToken contract.
 * Draws go through three stages: open, committed and rewarded in that order.
 * Only one draw is ever in the open stage.  Users deposits are always added to the open draw.  Funds in the open Draw are that user's open balance.
 * When a Draw is committed, the funds in it are moved to a user's committed total and the total committed balance of all users is updated.
 * When a Draw is rewarded, the gross winnings are the accrued interest since the last reward (if any).  A winner is selected with their chances being
 * proportional to their committed balance vs the total committed balance of all users.
 *
 *
 * With the above in mind, there is always an open draw and possibly a committed draw.  The progression is:
 *
 * Step 1: Draw 1 Open
 * Step 2: Draw 2 Open | Draw 1 Committed
 * Step 3: Draw 3 Open | Draw 2 Committed | Draw 1 Rewarded
 * Step 4: Draw 4 Open | Draw 3 Committed | Draw 2 Rewarded
 * Step 5: Draw 5 Open | Draw 4 Committed | Draw 3 Rewarded
 * Step X: ...
 */
contract BasePool is Initializable, ReentrancyGuard {
  using DrawManager for DrawManager.State;
  using SafeMath for uint256;
  using Roles for Roles.Role;
  using Blocklock for Blocklock.State;

  bytes32 internal constant ROLLED_OVER_ENTROPY_MAGIC_NUMBER = bytes32(uint256(1));

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  // We inline the result of the following hashes because Solidity doesn't resolve them at compile time.
  // See https://github.com/ethereum/solidity/issues/4024.

  // keccak256("PoolTogetherRewardListener")
  bytes32 constant internal REWARD_LISTENER_INTERFACE_HASH =
      0x68f03b0b1a978ee238a70b362091d993343460bc1a2830ab3f708936d9f564a4;

  /**
   * Emitted when a user deposits into the Pool.
   * @param sender The purchaser of the tickets
   * @param amount The size of the deposit
   */
  event Deposited(address indexed sender, uint256 amount);

  /**
   * Emitted when a user deposits into the Pool and the deposit is immediately committed
   * @param sender The purchaser of the tickets
   * @param amount The size of the deposit
   */
  event DepositedAndCommitted(address indexed sender, uint256 amount);

  /**
   * Emitted when Sponsors have deposited into the Pool
   * @param sender The purchaser of the tickets
   * @param amount The size of the deposit
   */
  event SponsorshipDeposited(address indexed sender, uint256 amount);

  /**
   * Emitted when an admin has been added to the Pool.
   * @param admin The admin that was added
   */
  event AdminAdded(address indexed admin);

  /**
   * Emitted when an admin has been removed from the Pool.
   * @param admin The admin that was removed
   */
  event AdminRemoved(address indexed admin);

  /**
   * Emitted when a user withdraws from the pool.
   * @param sender The user that is withdrawing from the pool
   * @param amount The amount that the user withdrew
   */
  event Withdrawn(address indexed sender, uint256 amount);

  /**
   * Emitted when a user withdraws their sponsorship and fees from the pool.
   * @param sender The user that is withdrawing
   * @param amount The amount they are withdrawing
   */
  event SponsorshipAndFeesWithdrawn(address indexed sender, uint256 amount);

  /**
   * Emitted when a user withdraws from their open deposit.
   * @param sender The user that is withdrawing
   * @param amount The amount they are withdrawing
   */
  event OpenDepositWithdrawn(address indexed sender, uint256 amount);

  /**
   * Emitted when a user withdraws from their committed deposit.
   * @param sender The user that is withdrawing
   * @param amount The amount they are withdrawing
   */
  event CommittedDepositWithdrawn(address indexed sender, uint256 amount);

  /**
   * Emitted when an address collects a fee
   * @param sender The address collecting the fee
   * @param amount The fee amount
   * @param drawId The draw from which the fee was awarded
   */
  event FeeCollected(address indexed sender, uint256 amount, uint256 drawId);

  /**
   * Emitted when a new draw is opened for deposit.
   * @param drawId The draw id
   * @param feeBeneficiary The fee beneficiary for this draw
   * @param secretHash The committed secret hash
   * @param feeFraction The fee fraction of the winnings to be given to the beneficiary
   */
  event Opened(
    uint256 indexed drawId,
    address indexed feeBeneficiary,
    bytes32 secretHash,
    uint256 feeFraction
  );

  /**
   * Emitted when a draw is committed.
   * @param drawId The draw id
   */
  event Committed(
    uint256 indexed drawId
  );

  /**
   * Emitted when a draw is rewarded.
   * @param drawId The draw id
   * @param winner The address of the winner
   * @param entropy The entropy used to select the winner
   * @param winnings The net winnings given to the winner
   * @param fee The fee being given to the draw beneficiary
   */
  event Rewarded(
    uint256 indexed drawId,
    address indexed winner,
    bytes32 entropy,
    uint256 winnings,
    uint256 fee
  );

  /**
   * Emitted when a RewardListener call fails
   * @param drawId The draw id
   * @param winner The address that one the draw
   * @param impl The implementation address of the RewardListener
   */
  event RewardListenerFailed(
    uint256 indexed drawId,
    address indexed winner,
    address indexed impl
  );

  /**
   * Emitted when the fee fraction is changed.  Takes effect on the next draw.
   * @param feeFraction The next fee fraction encoded as a fixed point 18 decimal
   */
  event NextFeeFractionChanged(uint256 feeFraction);

  /**
   * Emitted when the next fee beneficiary changes.  Takes effect on the next draw.
   * @param feeBeneficiary The next fee beneficiary
   */
  event NextFeeBeneficiaryChanged(address indexed feeBeneficiary);

  /**
   * Emitted when an admin pauses the contract
   */
  event DepositsPaused(address indexed sender);

  /**
   * Emitted when an admin unpauses the contract
   */
  event DepositsUnpaused(address indexed sender);

  /**
   * Emitted when the draw is rolled over in the event that the secret is forgotten.
   */
  event RolledOver(uint256 indexed drawId);

  struct Draw {
    uint256 feeFraction; //fixed point 18
    address feeBeneficiary;
    uint256 openedBlock;
    bytes32 secretHash;
    bytes32 entropy;
    address winner;
    uint256 netWinnings;
    uint256 fee;
  }

  /**
   * The Compound cToken that this Pool is bound to.
   */
  ICErc20 public cToken;

  /**
   * The fee beneficiary to use for subsequent Draws.
   */
  address public nextFeeBeneficiary;

  /**
   * The fee fraction to use for subsequent Draws.
   */
  uint256 public nextFeeFraction;

  /**
   * The total of all balances
   */
  uint256 public accountedBalance;

  /**
   * The total deposits and winnings for each user.
   */
  mapping (address => uint256) internal balances;

  /**
   * A mapping of draw ids to Draw structures
   */
  mapping(uint256 => Draw) internal draws;

  /**
   * A structure that is used to manage the user's odds of winning.
   */
  DrawManager.State internal drawState;

  /**
   * A structure containing the administrators
   */
  Roles.Role internal admins;

  /**
   * Whether the contract is paused
   */
  bool public paused;

  Blocklock.State internal blocklock;

  PoolToken public poolToken;

  /**
   * @notice Initializes a new Pool contract.
   * @param _owner The owner of the Pool.  They are able to change settings and are set as the owner of new lotteries.
   * @param _cToken The Compound Finance MoneyMarket contract to supply and withdraw tokens.
   * @param _feeFraction The fraction of the gross winnings that should be transferred to the owner as the fee.  Is a fixed point 18 number.
   * @param _feeBeneficiary The address that will receive the fee fraction
   */
  function init (
    address _owner,
    address _cToken,
    uint256 _feeFraction,
    address _feeBeneficiary,
    uint256 _lockDuration,
    uint256 _cooldownDuration
  ) public initializer {
    require(_owner != address(0), "Pool/owner-zero");
    require(_cToken != address(0), "Pool/ctoken-zero");
    cToken = ICErc20(_cToken);
    _addAdmin(_owner);
    _setNextFeeFraction(_feeFraction);
    _setNextFeeBeneficiary(_feeBeneficiary);
    initBlocklock(_lockDuration, _cooldownDuration);
  }

  function setPoolToken(PoolToken _poolToken) external onlyAdmin {
    require(address(poolToken) == address(0), "Pool/token-was-set");
    require(address(_poolToken.pool()) == address(this), "Pool/token-mismatch");
    poolToken = _poolToken;
  }

  function initBlocklock(uint256 _lockDuration, uint256 _cooldownDuration) internal {
    blocklock.setLockDuration(_lockDuration);
    blocklock.setCooldownDuration(_cooldownDuration);
  }

  /**
   * @notice Opens a new Draw.
   * @param _secretHash The secret hash to commit to the Draw.
   */
  function open(bytes32 _secretHash) internal {
    drawState.openNextDraw();
    draws[drawState.openDrawIndex] = Draw(
      nextFeeFraction,
      nextFeeBeneficiary,
      block.number,
      _secretHash,
      bytes32(0),
      address(0),
      uint256(0),
      uint256(0)
    );
    emit Opened(
      drawState.openDrawIndex,
      nextFeeBeneficiary,
      _secretHash,
      nextFeeFraction
    );
  }

  /**
   * @notice Emits the Committed event for the current open draw.
   */
  function emitCommitted() internal {
    uint256 drawId = currentOpenDrawId();
    emit Committed(drawId);
    if (address(poolToken) != address(0)) {
      poolToken.poolMint(openSupply());
    }
  }

  /**
   * @notice Commits the current open draw, if any, and opens the next draw using the passed hash.  Really this function is only called twice:
   * the first after Pool contract creation and the second immediately after.
   * Can only be called by an admin.
   * May fire the Committed event, and always fires the Open event.
   * @param nextSecretHash The secret hash to use to open a new Draw
   */
  function openNextDraw(bytes32 nextSecretHash) public onlyAdmin {
    if (currentCommittedDrawId() > 0) {
      require(currentCommittedDrawHasBeenRewarded(), "Pool/not-reward");
    }
    if (currentOpenDrawId() != 0) {
      emitCommitted();
    }
    open(nextSecretHash);
  }

  /**
   * @notice Ignores the current draw, and opens the next draw.
   * @dev This function will be removed once the winner selection has been decentralized.
   * @param nextSecretHash The hash to commit for the next draw
   */
  function rolloverAndOpenNextDraw(bytes32 nextSecretHash) public onlyAdmin {
    rollover();
    openNextDraw(nextSecretHash);
  }

  /**
   * @notice Rewards the current committed draw using the passed secret, commits the current open draw, and opens the next draw using the passed secret hash.
   * Can only be called by an admin.
   * Fires the Rewarded event, the Committed event, and the Open event.
   * @param nextSecretHash The secret hash to use to open a new Draw
   * @param lastSecret The secret to reveal to reward the current committed Draw.
   * @param _salt The salt that was used to conceal the secret
   */
  function rewardAndOpenNextDraw(bytes32 nextSecretHash, bytes32 lastSecret, bytes32 _salt) public onlyAdmin {
    reward(lastSecret, _salt);
    openNextDraw(nextSecretHash);
  }

  /**
   * @notice Rewards the winner for the current committed Draw using the passed secret.
   * The gross winnings are calculated by subtracting the accounted balance from the current underlying cToken balance.
   * A winner is calculated using the revealed secret.
   * If there is a winner (i.e. any eligible users) then winner's balance is updated with their net winnings.
   * The draw beneficiary's balance is updated with the fee.
   * The accounted balance is updated to include the fee and, if there was a winner, the net winnings.
   * Fires the Rewarded event.
   * @param _secret The secret to reveal for the current committed Draw
   * @param _salt The salt that was used to conceal the secret
   */
  function reward(bytes32 _secret, bytes32 _salt) public onlyAdmin onlyLocked requireCommittedNoReward nonReentrant {
    // require that there is a committed draw
    // require that the committed draw has not been rewarded
    uint256 drawId = currentCommittedDrawId();

    Draw storage draw = draws[drawId];

    require(draw.secretHash == keccak256(abi.encodePacked(_secret, _salt)), "Pool/bad-secret");

    // derive entropy from the revealed secret
    bytes32 entropy = keccak256(abi.encodePacked(_secret));

    _reward(drawId, draw, entropy);
  }

  function _reward(uint256 drawId, Draw storage draw, bytes32 entropy) internal {
    blocklock.unlock(block.number);
    // Select the winner using the hash as entropy
    address winningAddress = calculateWinner(entropy);

    // Calculate the gross winnings
    uint256 underlyingBalance = balance();

    uint256 grossWinnings;

    // It's possible when the APR is zero that the underlying balance will be slightly lower than the accountedBalance
    // due to rounding errors in the Compound contract.
    if (underlyingBalance > accountedBalance) {
      grossWinnings = capWinnings(underlyingBalance.sub(accountedBalance));
    }

    // Calculate the beneficiary fee
    uint256 fee = calculateFee(draw.feeFraction, grossWinnings);

    // Update balance of the beneficiary
    balances[draw.feeBeneficiary] = balances[draw.feeBeneficiary].add(fee);

    // Calculate the net winnings
    uint256 netWinnings = grossWinnings.sub(fee);

    draw.winner = winningAddress;
    draw.netWinnings = netWinnings;
    draw.fee = fee;
    draw.entropy = entropy;

    // If there is a winner who is to receive non-zero winnings
    if (winningAddress != address(0) && netWinnings != 0) {
      // Updated the accounted total
      accountedBalance = underlyingBalance;

      // Update balance of the winner
      balances[winningAddress] = balances[winningAddress].add(netWinnings);

      // Enter their winnings into the open draw
      drawState.deposit(winningAddress, netWinnings);

      callRewarded(winningAddress, netWinnings, drawId);
    } else {
      // Only account for the fee
      accountedBalance = accountedBalance.add(fee);
    }

    emit Rewarded(
      drawId,
      winningAddress,
      entropy,
      netWinnings,
      fee
    );
    emit FeeCollected(draw.feeBeneficiary, fee, drawId);
  }

  /**
   * @notice Calls the reward listener for the winner, if a listener exists.
   * @dev Checks for a listener using the ERC1820 registry.  The listener is given a gas stipend of 200,000 to run the function.
   * The number 200,000 was selected because it's safely above the gas requirements for PoolTogether [Pod](https://github.com/pooltogether/pods) contract.
   *
   * @param winner The winner.  If they have a listener registered in the ERC1820 registry it will be called.
   * @param netWinnings The amount that was won.
   * @param drawId The draw id that was won.
   */
  function callRewarded(address winner, uint256 netWinnings, uint256 drawId) internal {
    address impl = ERC1820_REGISTRY.getInterfaceImplementer(winner, REWARD_LISTENER_INTERFACE_HASH);
    if (impl != address(0)) {
      (bool success,) = impl.call.gas(200000)(abi.encodeWithSignature("rewarded(address,uint256,uint256)", winner, netWinnings, drawId));
      if (!success) {
        emit RewardListenerFailed(drawId, winner, impl);
      }
    }
  }

  /**
   * @notice A function that skips the reward for the committed draw id.
   * @dev This function will be removed once the entropy is decentralized.
   */
  function rollover() public onlyAdmin requireCommittedNoReward {
    uint256 drawId = currentCommittedDrawId();

    Draw storage draw = draws[drawId];
    draw.entropy = ROLLED_OVER_ENTROPY_MAGIC_NUMBER;

    emit RolledOver(
      drawId
    );

    emit Rewarded(
      drawId,
      address(0),
      ROLLED_OVER_ENTROPY_MAGIC_NUMBER,
      0,
      0
    );
  }

  /**
   * @notice Ensures that the winnings don't overflow.  Note that we can make this integer max, because the fee
   * is always less than zero (meaning the FixidityLib.multiply will always make the number smaller)
   */
  function capWinnings(uint256 _grossWinnings) internal pure returns (uint256) {
    uint256 max = uint256(FixidityLib.maxNewFixed());
    if (_grossWinnings > max) {
      return max;
    }
    return _grossWinnings;
  }

  /**
   * @notice Calculate the beneficiary fee using the passed fee fraction and gross winnings.
   * @param _feeFraction The fee fraction, between 0 and 1, represented as a 18 point fixed number.
   * @param _grossWinnings The gross winnings to take a fraction of.
   */
  function calculateFee(uint256 _feeFraction, uint256 _grossWinnings) internal pure returns (uint256) {
    int256 grossWinningsFixed = FixidityLib.newFixed(int256(_grossWinnings));
    // _feeFraction *must* be less than 1 ether, so it will never overflow
    int256 feeFixed = FixidityLib.multiply(grossWinningsFixed, FixidityLib.newFixed(int256(_feeFraction), uint8(18)));
    return uint256(FixidityLib.fromFixed(feeFixed));
  }

  /**
   * @notice Allows a user to deposit a sponsorship amount.  The deposit is transferred into the cToken.
   * Sponsorships allow a user to contribute to the pool without becoming eligible to win.  They can withdraw their sponsorship at any time.
   * The deposit will immediately be added to Compound and the interest will contribute to the next draw.
   * @param _amount The amount of the token underlying the cToken to deposit.
   */
  function depositSponsorship(uint256 _amount) public unlessDepositsPaused nonReentrant {
    // Transfer the tokens into this contract
    require(token().transferFrom(msg.sender, address(this), _amount), "Pool/t-fail");

    // Deposit the sponsorship amount
    _depositSponsorshipFrom(msg.sender, _amount);
  }

  /**
   * @notice Deposits the token balance for this contract as a sponsorship.
   * If people erroneously transfer tokens to this contract, this function will allow us to recoup those tokens as sponsorship.
   */
  function transferBalanceToSponsorship() public unlessDepositsPaused {
    // Deposit the sponsorship amount
    _depositSponsorshipFrom(address(this), token().balanceOf(address(this)));
  }

  /**
   * @notice Deposits into the pool under the current open Draw.  The deposit is transferred into the cToken.
   * Once the open draw is committed, the deposit will be added to the user's total committed balance and increase their chances of winning
   * proportional to the total committed balance of all users.
   * @param _amount The amount of the token underlying the cToken to deposit.
   */
  function depositPool(uint256 _amount) public requireOpenDraw unlessDepositsPaused nonReentrant notLocked {
    // Transfer the tokens into this contract
    require(token().transferFrom(msg.sender, address(this), _amount), "Pool/t-fail");

    // Deposit the funds
    _depositPoolFrom(msg.sender, _amount);
  }

  /**
   * @notice Deposits sponsorship for a user
   * @param _spender The user who is sponsoring
   * @param _amount The amount they are sponsoring
   */
  function _depositSponsorshipFrom(address _spender, uint256 _amount) internal {
    // Deposit the funds
    _depositFrom(_spender, _amount);

    emit SponsorshipDeposited(_spender, _amount);
  }

  /**
   * @notice Deposits into the pool for a user.  The deposit will be open until the next draw is committed.
   * @param _spender The user who is depositing
   * @param _amount The amount the user is depositing
   */
  function _depositPoolFrom(address _spender, uint256 _amount) internal {
    // Update the user's eligibility
    drawState.deposit(_spender, _amount);

    _depositFrom(_spender, _amount);

    emit Deposited(_spender, _amount);
  }

  /**
   * @notice Deposits into the pool for a user.  The deposit is made part of the currently committed draw
   * @param _spender The user who is depositing
   * @param _amount The amount to deposit
   */
  function _depositPoolFromCommitted(address _spender, uint256 _amount) internal notLocked {
    // Update the user's eligibility
    drawState.depositCommitted(_spender, _amount);

    _depositFrom(_spender, _amount);

    emit DepositedAndCommitted(_spender, _amount);
  }

  /**
   * @notice Deposits into the pool for a user.  Updates their balance and transfers their tokens into this contract.
   * @param _spender The user who is depositing
   * @param _amount The amount they are depositing
   */
  function _depositFrom(address _spender, uint256 _amount) internal {
    // Update the user's balance
    balances[_spender] = balances[_spender].add(_amount);

    // Update the total of this contract
    accountedBalance = accountedBalance.add(_amount);

    // Deposit into Compound
    require(token().approve(address(cToken), _amount), "Pool/approve");
    require(cToken.mint(_amount) == 0, "Pool/supply");
  }

  /**
   * Withdraws the given amount from the user's deposits.  It first withdraws from their sponsorship,
   * then their open deposits, then their committed deposits.
   *
   * @param amount The amount to withdraw.
   */
  function withdraw(uint256 amount) public nonReentrant notLocked {
    uint256 remainingAmount = amount;
    // first sponsorship
    uint256 sponsorshipAndFeesBalance = sponsorshipAndFeeBalanceOf(msg.sender);
    if (sponsorshipAndFeesBalance < remainingAmount) {
      withdrawSponsorshipAndFee(sponsorshipAndFeesBalance);
      remainingAmount = remainingAmount.sub(sponsorshipAndFeesBalance);
    } else {
      withdrawSponsorshipAndFee(remainingAmount);
      return;
    }

    // now pending
    uint256 pendingBalance = drawState.openBalanceOf(msg.sender);
    if (pendingBalance < remainingAmount) {
      _withdrawOpenDeposit(msg.sender, pendingBalance);
      remainingAmount = remainingAmount.sub(pendingBalance);
    } else {
      _withdrawOpenDeposit(msg.sender, remainingAmount);
      return;
    }

    // now committed.  remainingAmount should not be greater than committed balance.
    _withdrawCommittedDeposit(msg.sender, remainingAmount);
  }

  /**
   * @notice Withdraw the sender's entire balance back to them.
   */
  function withdraw() public nonReentrant notLocked {
    uint256 committedBalance = drawState.committedBalanceOf(msg.sender);

    uint256 balance = balances[msg.sender];
    // Update their chances of winning
    drawState.withdraw(msg.sender);
    _withdraw(msg.sender, balance);

    if (address(poolToken) != address(0)) {
      poolToken.poolRedeem(msg.sender, committedBalance);
    }

    emit Withdrawn(msg.sender, balance);
  }

  /**
   * Withdraws only from the sender's sponsorship and fee balances
   * @param _amount The amount to withdraw
   */
  function withdrawSponsorshipAndFee(uint256 _amount) public {
    uint256 sponsorshipAndFees = sponsorshipAndFeeBalanceOf(msg.sender);
    require(_amount <= sponsorshipAndFees, "Pool/exceeds-sfee");
    _withdraw(msg.sender, _amount);

    emit SponsorshipAndFeesWithdrawn(msg.sender, _amount);
  }

  /**
   * Returns the total balance of the user's sponsorship and fees
   * @param _sender The user whose balance should be returned
   */
  function sponsorshipAndFeeBalanceOf(address _sender) public view returns (uint256) {
    return balances[_sender].sub(drawState.balanceOf(_sender));
  }

  /**
   * Withdraws from the user's open deposits
   * @param _amount The amount to withdraw
   */
  function withdrawOpenDeposit(uint256 _amount) public nonReentrant notLocked {
    _withdrawOpenDeposit(msg.sender, _amount);
  }

  function _withdrawOpenDeposit(address sender, uint256 _amount) internal {
    drawState.withdrawOpen(sender, _amount);
    _withdraw(sender, _amount);

    emit OpenDepositWithdrawn(sender, _amount);
  }

  /**
   * Withdraws from the user's committed deposits
   * @param _amount The amount to withdraw
   */
  function withdrawCommittedDeposit(uint256 _amount) public nonReentrant notLocked returns (bool)  {
    _withdrawCommittedDeposit(msg.sender, _amount);
    return true;
  }

  function _withdrawCommittedDeposit(address sender, uint256 _amount) internal {
    _withdrawCommittedDepositAndEmit(sender, _amount);
    if (address(poolToken) != address(0)) {
      poolToken.poolRedeem(sender, _amount);
    }
  }

  /**
   * Allows the associated PoolToken to withdraw for a user; useful when redeeming through the token.
   * @param _from The user to withdraw from
   * @param _amount The amount to withdraw
   */
  function withdrawCommittedDepositFrom(
    address _from,
    uint256 _amount
  ) external onlyToken notLocked returns (bool)  {
    return _withdrawCommittedDepositAndEmit(_from, _amount);
  }

  /**
   * A function that withdraws committed deposits for a user and emits the corresponding events.
   * @param _from User to withdraw for
   * @param _amount The amount to withdraw
   */
  function _withdrawCommittedDepositAndEmit(address _from, uint256 _amount) internal returns (bool) {
    drawState.withdrawCommitted(_from, _amount);
    _withdraw(_from, _amount);

    emit CommittedDepositWithdrawn(_from, _amount);

    return true;
  }

  /**
   * @notice Allows the associated PoolToken to move committed tokens from one user to another.
   * @param _from The account to move tokens from
   * @param _to The account that is receiving the tokens
   * @param _amount The amount of tokens to transfer
   */
  function moveCommitted(
    address _from,
    address _to,
    uint256 _amount
  ) external onlyToken onlyCommittedBalanceGteq(_from, _amount) notLocked returns (bool) {
    balances[_from] = balances[_from].sub(_amount, "move could not sub amount");
    balances[_to] = balances[_to].add(_amount);
    drawState.withdrawCommitted(_from, _amount);
    drawState.depositCommitted(_to, _amount);

    return true;
  }

  /**
   * @notice Transfers tokens from the cToken contract to the sender.  Updates the accounted balance.
   */
  function _withdraw(address _sender, uint256 _amount) internal {
    uint256 balance = balances[_sender];

    require(_amount <= balance, "Pool/no-funds");

    // Update the user's balance
    balances[_sender] = balance.sub(_amount);

    // Update the total of this contract
    accountedBalance = accountedBalance.sub(_amount);

    // Withdraw from Compound and transfer
    require(cToken.redeemUnderlying(_amount) == 0, "Pool/redeem");
    require(token().transfer(_sender, _amount), "Pool/transfer");
  }

  /**
   * @notice Returns the id of the current open Draw.
   * @return The current open Draw id
   */
  function currentOpenDrawId() public view returns (uint256) {
    return drawState.openDrawIndex;
  }

  /**
   * @notice Returns the id of the current committed Draw.
   * @return The current committed Draw id
   */
  function currentCommittedDrawId() public view returns (uint256) {
    if (drawState.openDrawIndex > 1) {
      return drawState.openDrawIndex - 1;
    } else {
      return 0;
    }
  }

  /**
   * @notice Returns whether the current committed draw has been rewarded
   * @return True if the current committed draw has been rewarded, false otherwise
   */
  function currentCommittedDrawHasBeenRewarded() internal view returns (bool) {
    Draw storage draw = draws[currentCommittedDrawId()];
    return draw.entropy != bytes32(0);
  }

  /**
   * @notice Gets information for a given draw.
   * @param _drawId The id of the Draw to retrieve info for.
   * @return Fields including:
   *  feeFraction: the fee fraction
   *  feeBeneficiary: the beneficiary of the fee
   *  openedBlock: The block at which the draw was opened
   *  secretHash: The hash of the secret committed to this draw.
   *  entropy: the entropy used to select the winner
   *  winner: the address of the winner
   *  netWinnings: the total winnings less the fee
   *  fee: the fee taken by the beneficiary
   */
  function getDraw(uint256 _drawId) public view returns (
    uint256 feeFraction,
    address feeBeneficiary,
    uint256 openedBlock,
    bytes32 secretHash,
    bytes32 entropy,
    address winner,
    uint256 netWinnings,
    uint256 fee
  ) {
    Draw storage draw = draws[_drawId];
    feeFraction = draw.feeFraction;
    feeBeneficiary = draw.feeBeneficiary;
    openedBlock = draw.openedBlock;
    secretHash = draw.secretHash;
    entropy = draw.entropy;
    winner = draw.winner;
    netWinnings = draw.netWinnings;
    fee = draw.fee;
  }

  /**
   * @notice Returns the total of the address's balance in committed Draws.  That is, the total that contributes to their chances of winning.
   * @param _addr The address of the user
   * @return The total committed balance for the user
   */
  function committedBalanceOf(address _addr) external view returns (uint256) {
    return drawState.committedBalanceOf(_addr);
  }

  /**
   * @notice Returns the total of the address's balance in the open Draw.  That is, the total that will *eventually* contribute to their chances of winning.
   * @param _addr The address of the user
   * @return The total open balance for the user
   */
  function openBalanceOf(address _addr) external view returns (uint256) {
    return drawState.openBalanceOf(_addr);
  }

  /**
   * @notice Returns a user's total balance.  This includes their sponsorships, fees, open deposits, and committed deposits.
   * @param _addr The address of the user to check.
   * @return The user's current balance.
   */
  function totalBalanceOf(address _addr) external view returns (uint256) {
    return balances[_addr];
  }

  /**
   * @notice Returns a user's committed balance.  This is the balance of their Pool tokens.
   * @param _addr The address of the user to check.
   * @return The user's current balance.
   */
  function balanceOf(address _addr) external view returns (uint256) {
    return drawState.committedBalanceOf(_addr);
  }

  /**
   * @notice Calculates a winner using the passed entropy for the current committed balances.
   * @param _entropy The entropy to use to select the winner
   * @return The winning address
   */
  function calculateWinner(bytes32 _entropy) public view returns (address) {
    return drawState.drawWithEntropy(_entropy);
  }

  /**
   * @notice Returns the total committed balance.  Used to compute an address's chances of winning.
   * @return The total committed balance.
   */
  function committedSupply() public view returns (uint256) {
    return drawState.committedSupply();
  }

  /**
   * @notice Returns the total open balance.  This balance is the number of tickets purchased for the open draw.
   * @return The total open balance
   */
  function openSupply() public view returns (uint256) {
    return drawState.openSupply();
  }

  /**
   * @notice Calculates the total estimated interest earned for the given number of blocks
   * @param _blocks The number of block that interest accrued for
   * @return The total estimated interest as a 18 point fixed decimal.
   */
  function estimatedInterestRate(uint256 _blocks) public view returns (uint256) {
    return supplyRatePerBlock().mul(_blocks);
  }

  /**
   * @notice Convenience function to return the supplyRatePerBlock value from the money market contract.
   * @return The cToken supply rate per block
   */
  function supplyRatePerBlock() public view returns (uint256) {
    return cToken.supplyRatePerBlock();
  }

  /**
   * @notice Sets the beneficiary fee fraction for subsequent Draws.
   * Fires the NextFeeFractionChanged event.
   * Can only be called by an admin.
   * @param _feeFraction The fee fraction to use.
   * Must be between 0 and 1 and formatted as a fixed point number with 18 decimals (as in Ether).
   */
  function setNextFeeFraction(uint256 _feeFraction) public onlyAdmin {
    _setNextFeeFraction(_feeFraction);
  }

  function _setNextFeeFraction(uint256 _feeFraction) internal {
    require(_feeFraction <= 1 ether, "Pool/less-1");
    nextFeeFraction = _feeFraction;

    emit NextFeeFractionChanged(_feeFraction);
  }

  /**
   * @notice Sets the fee beneficiary for subsequent Draws.
   * Can only be called by admins.
   * @param _feeBeneficiary The beneficiary for the fee fraction.  Cannot be the 0 address.
   */
  function setNextFeeBeneficiary(address _feeBeneficiary) public onlyAdmin {
    _setNextFeeBeneficiary(_feeBeneficiary);
  }

  /**
   * @notice Sets the fee beneficiary for subsequent Draws.
   * @param _feeBeneficiary The beneficiary for the fee fraction.  Cannot be the 0 address.
   */
  function _setNextFeeBeneficiary(address _feeBeneficiary) internal {
    require(_feeBeneficiary != address(0), "Pool/not-zero");
    nextFeeBeneficiary = _feeBeneficiary;

    emit NextFeeBeneficiaryChanged(_feeBeneficiary);
  }

  /**
   * @notice Adds an administrator.
   * Can only be called by administrators.
   * Fires the AdminAdded event.
   * @param _admin The address of the admin to add
   */
  function addAdmin(address _admin) public onlyAdmin {
    _addAdmin(_admin);
  }

  /**
   * @notice Checks whether a given address is an administrator.
   * @param _admin The address to check
   * @return True if the address is an admin, false otherwise.
   */
  function isAdmin(address _admin) public view returns (bool) {
    return admins.has(_admin);
  }

  /**
   * @notice Checks whether a given address is an administrator.
   * @param _admin The address to check
   * @return True if the address is an admin, false otherwise.
   */
  function _addAdmin(address _admin) internal {
    admins.add(_admin);

    emit AdminAdded(_admin);
  }

  /**
   * @notice Removes an administrator
   * Can only be called by an admin.
   * Admins cannot remove themselves.  This ensures there is always one admin.
   * @param _admin The address of the admin to remove
   */
  function removeAdmin(address _admin) public onlyAdmin {
    require(admins.has(_admin), "Pool/no-admin");
    require(_admin != msg.sender, "Pool/remove-self");
    admins.remove(_admin);

    emit AdminRemoved(_admin);
  }

  /**
   * Requires that there is a committed draw that has not been rewarded.
   */
  modifier requireCommittedNoReward() {
    require(currentCommittedDrawId() > 0, "Pool/committed");
    require(!currentCommittedDrawHasBeenRewarded(), "Pool/already");
    _;
  }

  /**
   * @notice Returns the token underlying the cToken.
   * @return An ERC20 token address
   */
  function token() public view returns (IERC20) {
    return IERC20(cToken.underlying());
  }

  /**
   * @notice Returns the underlying balance of this contract in the cToken.
   * @return The cToken underlying balance for this contract.
   */
  function balance() public returns (uint256) {
    return cToken.balanceOfUnderlying(address(this));
  }

  /**
   * @notice Locks the movement of tokens (essentially the committed deposits and winnings)
   * @dev The lock only lasts for a duration of blocks.  The lock cannot be relocked until the cooldown duration completes.
   */
  function lockTokens() public onlyAdmin {
    blocklock.lock(block.number);
  }

  /**
   * @notice Unlocks the movement of tokens (essentially the committed deposits)
   */
  function unlockTokens() public onlyAdmin {
    blocklock.unlock(block.number);
  }

  /**
   * Pauses all deposits into the contract.  This was added so that we can slowly deprecate Pools.  Users can continue
   * to collect rewards and withdraw, but eventually the Pool will grow smaller.
   *
   * emits DepositsPaused
   */
  function pauseDeposits() public unlessDepositsPaused onlyAdmin {
    paused = true;

    emit DepositsPaused(msg.sender);
  }

  /**
   * @notice Unpauses all deposits into the contract
   *
   * emits DepositsUnpaused
   */
  function unpauseDeposits() public whenDepositsPaused onlyAdmin {
    paused = false;

    emit DepositsUnpaused(msg.sender);
  }

  /**
   * @notice Check if the contract is locked.
   * @return True if the contract is locked, false otherwise
   */
  function isLocked() public view returns (bool) {
    return blocklock.isLocked(block.number);
  }

  /**
   * @notice Returns the block number at which the lock expires
   * @return The block number at which the lock expires
   */
  function lockEndAt() public view returns (uint256) {
    return blocklock.lockEndAt();
  }

  /**
   * @notice Check cooldown end block
   * @return The block number at which the cooldown ends and the contract can be re-locked
   */
  function cooldownEndAt() public view returns (uint256) {
    return blocklock.cooldownEndAt();
  }

  /**
   * @notice Returns whether the contract can be locked
   * @return True if the contract can be locked, false otherwise
   */
  function canLock() public view returns (bool) {
    return blocklock.canLock(block.number);
  }

  /**
   * @notice Duration of the lock
   * @return Returns the duration of the lock in blocks.
   */
  function lockDuration() public view returns (uint256) {
    return blocklock.lockDuration;
  }

  /**
   * @notice Returns the cooldown duration.  The cooldown period starts after the Pool has been unlocked.
   * The Pool cannot be locked during the cooldown period.
   * @return The cooldown duration in blocks
   */
  function cooldownDuration() public view returns (uint256) {
    return blocklock.cooldownDuration;
  }

  /**
   * @notice requires the pool not to be locked
   */
  modifier notLocked() {
    require(!blocklock.isLocked(block.number), "Pool/locked");
    _;
  }

  /**
   * @notice requires the pool to be locked
   */
  modifier onlyLocked() {
    require(blocklock.isLocked(block.number), "Pool/unlocked");
    _;
  }

  /**
   * @notice requires the caller to be an admin
   */
  modifier onlyAdmin() {
    require(admins.has(msg.sender), "Pool/admin");
    _;
  }

  /**
   * @notice Requires an open draw to exist
   */
  modifier requireOpenDraw() {
    require(currentOpenDrawId() != 0, "Pool/no-open");
    _;
  }

  /**
   * @notice Requires deposits to be paused
   */
  modifier whenDepositsPaused() {
    require(paused, "Pool/d-not-paused");
    _;
  }

  /**
   * @notice Requires deposits not to be paused
   */
  modifier unlessDepositsPaused() {
    require(!paused, "Pool/d-paused");
    _;
  }

  /**
   * @notice Requires the caller to be the pool token
   */
  modifier onlyToken() {
    require(msg.sender == address(poolToken), "Pool/only-token");
    _;
  }

  /**
   * @notice requires the passed user's committed balance to be greater than or equal to the passed amount
   * @param _from The user whose committed balance should be checked
   * @param _amount The minimum amount they must have
   */
  modifier onlyCommittedBalanceGteq(address _from, uint256 _amount) {
    uint256 committedBalance = drawState.committedBalanceOf(_from);
    require(_amount <= committedBalance, "not enough funds");
    _;
  }
}





contract ScdMcdMigration {
    SaiTubLike                  public tub;
    VatLike                     public vat;
    ManagerLike                 public cdpManager;
    JoinLike                    public saiJoin;
    JoinLike                    public wethJoin;
    JoinLike                    public daiJoin;

    constructor(
        address tub_,           // SCD tub contract address
        address cdpManager_,    // MCD manager contract address
        address saiJoin_,       // MCD SAI collateral adapter contract address
        address wethJoin_,      // MCD ETH collateral adapter contract address
        address daiJoin_        // MCD DAI adapter contract address
    ) public {
        tub = SaiTubLike(tub_);
        cdpManager = ManagerLike(cdpManager_);
        vat = VatLike(cdpManager.vat());
        saiJoin = JoinLike(saiJoin_);
        wethJoin = JoinLike(wethJoin_);
        daiJoin = JoinLike(daiJoin_);

        require(wethJoin.gem() == tub.gem(), "non-matching-weth");
        require(saiJoin.gem() == tub.sai(), "non-matching-sai");

        tub.gov().approve(address(tub), uint(-1));
        tub.skr().approve(address(tub), uint(-1));
        tub.sai().approve(address(tub), uint(-1));
        tub.sai().approve(address(saiJoin), uint(-1));
        wethJoin.gem().approve(address(wethJoin), uint(-1));
        daiJoin.dai().approve(address(daiJoin), uint(-1));
        vat.hope(address(daiJoin));
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    // Function to swap SAI to DAI
    // This function is to be used by users that want to get new DAI in exchange of old one (aka SAI)
    // wad amount has to be <= the value pending to reach the debt ceiling (the minimum between general and ilk one)
    function swapSaiToDai(
        uint wad
    ) external {
        // Get wad amount of SAI from user's wallet:
        saiJoin.gem().transferFrom(msg.sender, address(this), wad);
        // Join the SAI wad amount to the `vat`:
        saiJoin.join(address(this), wad);
        // Lock the SAI wad amount to the CDP and generate the same wad amount of DAI
        vat.frob(saiJoin.ilk(), address(this), address(this), address(this), toInt(wad), toInt(wad));
        // Send DAI wad amount as a ERC20 token to the user's wallet
        daiJoin.exit(msg.sender, wad);
    }

    // Function to swap DAI to SAI
    // This function is to be used by users that want to get SAI in exchange of DAI
    // wad amount has to be <= the amount of SAI locked (and DAI generated) in the migration contract SAI CDP
    function swapDaiToSai(
        uint wad
    ) external {
        // Get wad amount of DAI from user's wallet:
        daiJoin.dai().transferFrom(msg.sender, address(this), wad);
        // Join the DAI wad amount to the vat:
        daiJoin.join(address(this), wad);
        // Payback the DAI wad amount and unlocks the same value of SAI collateral
        vat.frob(saiJoin.ilk(), address(this), address(this), address(this), -toInt(wad), -toInt(wad));
        // Send SAI wad amount as a ERC20 token to the user's wallet
        saiJoin.exit(msg.sender, wad);
    }

    // Function to migrate a SCD CDP to MCD one (needs to be used via a proxy so the code can be kept simpler). Check MigrationProxyActions.sol code for usage.
    // In order to use migrate function, SCD CDP debtAmt needs to be <= SAI previously deposited in the SAI CDP * (100% - Collateralization Ratio)
    function migrate(
        bytes32 cup
    ) external returns (uint cdp) {
        // Get values
        uint debtAmt = tub.tab(cup);    // CDP SAI debt
        uint pethAmt = tub.ink(cup);    // CDP locked collateral
        uint ethAmt = tub.bid(pethAmt); // CDP locked collateral equiv in ETH

        // Take SAI out from MCD SAI CDP. For this operation is necessary to have a very low collateralization ratio
        // This is not actually a problem as this ilk will only be accessed by this migration contract,
        // which will make sure to have the amounts balanced out at the end of the execution.
        vat.frob(
            bytes32(saiJoin.ilk()),
            address(this),
            address(this),
            address(this),
            -toInt(debtAmt),
            0
        );
        saiJoin.exit(address(this), debtAmt); // SAI is exited as a token

        // Shut SAI CDP and gets WETH back
        tub.shut(cup);      // CDP is closed using the SAI just exited and the MKR previously sent by the user (via the proxy call)
        tub.exit(pethAmt);  // Converts PETH to WETH

        // Open future user's CDP in MCD
        cdp = cdpManager.open(wethJoin.ilk(), address(this));

        // Join WETH to Adapter
        wethJoin.join(cdpManager.urns(cdp), ethAmt);

        // Lock WETH in future user's CDP and generate debt to compensate the SAI used to paid the SCD CDP
        (, uint rate,,,) = vat.ilks(wethJoin.ilk());
        cdpManager.frob(
            cdp,
            toInt(ethAmt),
            toInt(mul(debtAmt, 10 ** 27) / rate + 1) // To avoid rounding issues we add an extra wei of debt
        );
        // Move DAI generated to migration contract (to recover the used funds)
        cdpManager.move(cdp, address(this), mul(debtAmt, 10 ** 27));
        // Re-balance MCD SAI migration contract's CDP
        vat.frob(
            bytes32(saiJoin.ilk()),
            address(this),
            address(this),
            address(this),
            0,
            -toInt(debtAmt)
        );

        // Set ownership of CDP to the user
        cdpManager.give(cdp, msg.sender);
    }
}




/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}


/**
 * @title MCDAwarePool
 * @author Brendan Asselstine [email protected]
 * @notice This contract is a Pool that is aware of the new Multi-Collateral Dai.  It uses the ERC777Recipient interface to
 * detect if it's being transferred tickets from the old single collateral Dai (Sai) Pool.  If it is, it migrates the Sai to Dai
 * and immediately deposits the new Dai as committed tickets for that user.  We are knowingly bypassing the committed period for
 * users to encourage them to migrate to the MCD Pool.
 */
contract MCDAwarePool is BasePool, IERC777Recipient {
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
      0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  uint256 internal constant DEFAULT_LOCK_DURATION = 40;
  uint256 internal constant DEFAULT_COOLDOWN_DURATION = 80;

  /**
   * @notice The address of the ScdMcdMigration contract (see https://github.com/makerdao/developerguides/blob/master/mcd/upgrading-to-multi-collateral-dai/upgrading-to-multi-collateral-dai.md#direct-integration-with-smart-contracts)
   */
  ScdMcdMigration public scdMcdMigration;

  /**
   * @notice The address of the Sai Pool contract
   */
  MCDAwarePool public saiPool;

  /**
   * @notice Initializes the contract.
   * @param _owner The initial administrator of the contract
   * @param _cToken The Compound cToken to bind this Pool to
   * @param _feeFraction The fraction of the winnings to give to the beneficiary
   * @param _feeBeneficiary The beneficiary who receives the fee
   */
  function init (
    address _owner,
    address _cToken,
    uint256 _feeFraction,
    address _feeBeneficiary,
    uint256 lockDuration,
    uint256 cooldownDuration
  ) public initializer {
    super.init(
      _owner,
      _cToken,
      _feeFraction,
      _feeBeneficiary,
      lockDuration,
      cooldownDuration
    );
    initRegistry();
    initBlocklock(lockDuration, cooldownDuration);
  }

  /**
   * @notice Used to initialize the BasePool contract after an upgrade.  Registers the MCDAwarePool with the ERC1820 registry so that it can receive tokens, and inits the block lock.
   */
  function initMCDAwarePool(uint256 lockDuration, uint256 cooldownDuration) public {
    initRegistry();
    if (blocklock.lockDuration == 0) {
      initBlocklock(lockDuration, cooldownDuration);
    }
  }

  function initRegistry() internal {
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }

  function initMigration(ScdMcdMigration _scdMcdMigration, MCDAwarePool _saiPool) public onlyAdmin {
    _initMigration(_scdMcdMigration, _saiPool);
  }

  function _initMigration(ScdMcdMigration _scdMcdMigration, MCDAwarePool _saiPool) internal {
    require(address(scdMcdMigration) == address(0), "Pool/init");
    require(address(_scdMcdMigration) != address(0), "Pool/mig-def");
    scdMcdMigration = _scdMcdMigration;
    saiPool = _saiPool; // may be null
  }

  /**
   * @notice Called by an ERC777 token when tokens are sent, transferred, or minted.  If the sender is the original Sai Pool
   * and this pool is bound to the Dai token then it will accept the transfer, migrate the tokens, and deposit on behalf of
   * the sender.  It will reject all other tokens.
   *
   * If there is a committed draw this function will mint the user tickets immediately, otherwise it will place them in the
   * open prize.  This is to encourage migration.
   *
   * @param from The sender
   * @param amount The amount they are transferring
   */
  function tokensReceived(
    address, // operator
    address from,
    address, // to address can't be anything but us because we don't implement ERC1820ImplementerInterface
    uint256 amount,
    bytes calldata,
    bytes calldata
  ) external unlessDepositsPaused {
    require(msg.sender == address(saiPoolToken()), "Pool/sai-only");
    require(address(token()) == address(daiToken()), "Pool/not-dai");

    // cash out of the Pool.  This call transfers sai to this contract
    saiPoolToken().redeem(amount, '');

    // approve of the transfer to the migration contract
    saiToken().approve(address(scdMcdMigration), amount);

    // migrate the sai to dai.  The contract now has dai
    scdMcdMigration.swapSaiToDai(amount);

    if (currentCommittedDrawId() > 0) {
      // now deposit the dai as tickets
      _depositPoolFromCommitted(from, amount);
    } else {
      _depositPoolFrom(from, amount);
    }
  }

  /**
   * @notice Returns the address of the PoolSai pool token contract
   * @return The address of the Sai PoolToken contract
   */
  function saiPoolToken() internal view returns (PoolToken) {
    if (address(saiPool) != address(0)) {
      return saiPool.poolToken();
    } else {
      return PoolToken(0);
    }
  }

  /**
   * @notice Returns the address of the Sai token
   * @return The address of the sai token
   */
  function saiToken() public returns (GemLike) {
    return scdMcdMigration.saiJoin().gem();
  }

  /**
   * @notice Returns the address of the Dai token
   * @return The address of the Dai token.
   */
  function daiToken() public returns (GemLike) {
    return scdMcdMigration.daiJoin().dai();
  }
}

/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/





interface IComptroller {
  function claimComp(address holder, ICErc20[] calldata cTokens) external;
}


contract AutonomousPool is MCDAwarePool {

  event PrizePeriodSecondsUpdated(uint256 prizePeriodSeconds);

  event ComptrollerUpdated(IComptroller comptroller);

  event CompRecipientUpdated(address compRecipient);

  event AwardStarted();

  event AwardCompleted();

  uint256 public lastAwardTimestamp;
  uint256 public prizePeriodSeconds;
  IComptroller public comptroller;
  IERC20 public comp;
  address public compRecipient;

  event TransferredComp(
    address indexed recipient,
    uint256 amount
  );

  function initializeAutonomousPool(
    uint256 _prizePeriodSeconds,
    IERC20 _comp,
    IComptroller _comptroller
  ) external {
    require(address(comp) == address(0), "AutonomousPool/already-init");
    require(address(_comp) != address(0), "AutonomousPool/comp-not-defined");
    require(address(_comptroller) != address(0), "AutonomousPool/comptroller-not-defined");
    comp = _comp;
    _setPrizePeriodSeconds(_prizePeriodSeconds);
    _setComptroller(_comptroller);
  }

  function setPrizePeriodSeconds(uint256 _prizePeriodSeconds) external onlyAdmin {
    _setPrizePeriodSeconds(_prizePeriodSeconds);
  }

  function _setPrizePeriodSeconds(uint256 _prizePeriodSeconds) internal {
    require(_prizePeriodSeconds > 0, "AutonomousPool/pp-gt-zero");
    prizePeriodSeconds = _prizePeriodSeconds;

    emit PrizePeriodSecondsUpdated(prizePeriodSeconds);
  }

  function setComptroller(IComptroller _comptroller) external onlyAdmin {
    _setComptroller(_comptroller);
  }

  function _setComptroller(IComptroller _comptroller) internal {
    comptroller = _comptroller;

    emit ComptrollerUpdated(comptroller);
  }

  function setCompRecipient(address _compRecipient) external onlyAdmin {
    compRecipient = _compRecipient;

    emit CompRecipientUpdated(compRecipient);
  }

  /// @notice Returns whether the prize period has ended.
  function isPrizePeriodEnded() public view returns (bool) {
    return remainingTime() == 0;
  }

  function claimAndTransferCOMP() public returns (uint256) {
    if (address(comptroller) == address(0)) {
      return 0;
    }
    ICErc20[] memory cTokens = new ICErc20[](1);
    cTokens[0] = cToken;
    comptroller.claimComp(address(this), cTokens);
    return transferCOMP();
  }

  function transferCOMP() public returns (uint256) {
    if (compRecipient == address(0)) {
      return 0;
    }

    uint256 amount = comp.balanceOf(address(this));
    comp.transfer(compRecipient, amount);

    emit TransferredComp(compRecipient, amount);

    return amount;
  }

  /**
   * @notice Locks the movement of tokens (essentially the committed deposits and winnings)
   * @dev The lock only lasts for a duration of blocks.  The lock cannot be relocked until the cooldown duration completes.
   */
  function lockTokens() public requireInitialized onlyPrizePeriodEnded {
    blocklock.lock(block.number);

    emit AwardStarted();
  }

  /// @notice Starts the award process.  The prize period must have ended.
  /// @dev Essentially an alias for lockTokens()
  function startAward() public {
    lockTokens();
  }

  /**
   * @notice Rewards the current committed draw using the passed secret, commits the current open draw, and opens the next draw using the passed secret hash.
   * Can only be called by an admin.
   * Fires the Rewarded event, the Committed event, and the Open event.
   */
  function completeAward() external requireInitialized onlyLocked nonReentrant {
    // if there is a committed draw, it can be awarded
    if (currentCommittedDrawId() > 0) {
      _reward();
    }
    if (currentOpenDrawId() != 0) {
      emitCommitted();
    }
    _open();
    lastAwardTimestamp = _currentTime();

    emit AwardCompleted();
  }

  /**
   * @notice Rewards the winner for the current committed Draw using the passed secret.
   * The gross winnings are calculated by subtracting the accounted balance from the current underlying cToken balance.
   * A winner is calculated using the revealed secret.
   * If there is a winner (i.e. any eligible users) then winner's balance is updated with their net winnings.
   * The draw beneficiary's balance is updated with the fee.
   * The accounted balance is updated to include the fee and, if there was a winner, the net winnings.
   * Fires the Rewarded event.
   */
  function _reward() internal {
    // require that there is a committed draw
    // require that the committed draw has not been rewarded
    uint256 drawId = currentCommittedDrawId();
    Draw storage draw = draws[drawId];
    bytes32 entropy = blockhash(block.number - 1);
    _reward(drawId, draw, entropy);
  }

  /**
   * @notice Opens a new Draw.
   */
  function _open() internal {
    drawState.openNextDraw();
    draws[drawState.openDrawIndex] = Draw(
      nextFeeFraction,
      nextFeeBeneficiary,
      block.number,
      bytes32(0),
      bytes32(0),
      address(0),
      uint256(0),
      uint256(0)
    );
    emit Opened(
      drawState.openDrawIndex,
      nextFeeBeneficiary,
      bytes32(0),
      nextFeeFraction
    );
  }

  function canStartAward() public view returns (bool) {
    return _isAutonomousPoolInitialized() && isPrizePeriodEnded();
  }

  function canCompleteAward() public view returns (bool) {
    return _isAutonomousPoolInitialized() && blocklock.isLocked(block.number);
  }

  function elapsedTime() public view returns (uint256) {
    return _currentTime().sub(lastAwardTimestamp);
  }

  function remainingTime() public view returns (uint256) {
    uint256 elapsed = elapsedTime();
    if (elapsed > prizePeriodSeconds) {
      return 0;
    } else {
      return prizePeriodSeconds.sub(elapsed);
    }
  }

  function _currentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function _isAutonomousPoolInitialized() internal view returns (bool) {
    return address(comp) != address(0);
  }

  function openNextDraw(bytes32 nextSecretHash) public {
    revert('AutonomousPool/deprecated');
  }

  function rolloverAndOpenNextDraw(bytes32 nextSecretHash) public {
    revert('AutonomousPool/deprecated');
  }

  function rewardAndOpenNextDraw(bytes32 nextSecretHash, bytes32 lastSecret, bytes32 _salt) public {
    revert('AutonomousPool/deprecated');
  }

  function reward(bytes32 _secret, bytes32 _salt) public {
    revert('AutonomousPool/deprecated');
  }

  modifier onlyPrizePeriodEnded() {
    require(isPrizePeriodEnded(), "AutonomousPool/prize-period-not-ended");
    _;
  }

  modifier requireInitialized() {
    require(address(comp) != address(0), "AutonomousPool/not-init");
    _;
  }
}