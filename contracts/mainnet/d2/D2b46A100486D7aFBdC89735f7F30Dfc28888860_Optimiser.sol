/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: 4_deploy-defarm/Optimiser/SafeMath.sol

pragma solidity ^0.6.12;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, 'SafeMath:INVALID_ADD');
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, 'SafeMath:OVERFLOW_SUB');
        c = a - b;
    }

    function mul(uint a, uint b, uint decimal) internal pure returns (uint) {
        uint dc = 10**decimal;
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "SafeMath: multiple overflow");
        uint c1 = c0 + (dc / 2);
        require(c1 >= c0, "SafeMath: multiple overflow");
        uint c2 = c1 / dc;
        return c2;
    }

    function div(uint256 a, uint256 b, uint decimal) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint dc = 10**decimal;
        uint c0 = a * dc;
        require(a == 0 || c0 / a == dc, "SafeMath: division internal");
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "SafeMath: division internal");
        uint c2 = c1 / b;
        return c2;
    }
}

// File: 4_deploy-defarm/Optimiser/TransferHelper.sol

pragma solidity ^0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: 4_deploy-defarm/Optimiser/UniformRandomNumber.sol

/**
Copyright 2019 PoolTogether LLC

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

pragma solidity 0.6.12;

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


// File: 4_deploy-defarm/Optimiser/SortitionSumTreeFactory.sol

pragma solidity ^0.6.12;

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
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
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
                    tree.stack.pop();
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
     *  @return startIndex The index at which leaves start
     *  @return values The values of the returned leaves
     *  @return hasMore Whether there are more for pagination.
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
     *  @return ID The drawn ID.
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
     *  @return value The associated value.
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
// File: 4_deploy-defarm/Optimiser/Optimiser.sol

pragma solidity 0.6.12;






contract Optimiser {
    using SafeMath for uint;
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    struct PoolInfo {
        uint total_weightage;
        uint rate_reward;
    }
    
    struct SessionInfo {
        uint total_reward;
        uint start_timestamp;
        uint end_timestamp;
        bool can_claim;      // upon session ended, enable user to claim reward
        bool deposit_paused; // access control
        bool claim_paused;   // access control
    }

    struct UserInfo {
        uint purchase_counter;
    }

    struct UserSessionInfo {
        uint tvl;
        uint num_of_ticket;
        uint first_deposit_timestamp;
        uint penalty_until_timestamp;
        bool has_purchased; // once purchased in the session, always is true
        bool has_claimed;   // reward only can claim once
    }
    
    struct UserPoolInfo {
        uint weightage;
        uint num_of_ticket;
        bool claimed;
    }

    // mapping (session ID => session info)
    mapping(uint => SessionInfo) private session;
    
    // mapping (session ID => pool category => pool information)
    mapping(uint => mapping(uint => PoolInfo)) private pool;
    
    // mapping (user address => session ID => pool category => user purchased information)
    mapping(address => mapping(uint => mapping(uint => UserPoolInfo))) private user_pool;
    
    // mapping (user address => session ID => user info by session)
    mapping(address => mapping(uint => UserSessionInfo)) private user_session;
    
    // mapping (user address => user personal info)
    mapping(address => UserInfo) private user_info;

    // mapping (pool category ID => rate reward) master lookup
    mapping(uint => uint) public pool_reward_list;
    
    // mapping (pool category ID => chances of user enter the pool) lookup
    mapping(uint => uint) public pool_chances;
    
    mapping(address => bool) public access_permission;
    
    bool    private initialized;
    bool    public stop_next_session; // toggle for session will auto continue or not
    bool    public swap_payment;      // payment will swap to DEX and burn

    address public  owner;          // owner who deploy the contract
    address public  tube;           // TUBE2 token contract
    address public  tube_chief;     // TUBE Chief contract
    address public  dev;            // development address
    address public  utility;        // other usage purpose
    address public  buyback;        // upon user hit penalty, transfer for buyback
    address public  uniswap_router; // dex router address
    address public  signer;         // website validation

    uint    private  preseed;            // RNG seed
    uint    public  session_id;          // current session ID
    uint    public  session_minute;      // session duration
    uint    public  category_size;       // current pool category size
    uint    public  eth_per_ticket;      // how many ETH to buy 1 ticket
    uint    public  rate_buyback;        // fund distribution for buyback TUBE
    uint    public  rate_dev;            // fund distrubtion for dev team
    uint    public  rate_penalty;        // claim penalty rate
    uint    public  penalty_base_minute; // claim penalty basis duration
    uint    public  DECIMAL;             // ether unit decimal
    uint    public  PER_UNIT;            // ether unit
    uint[]  public  multiplier_list;     // multiplier list
    
    uint256 constant private MAX_TREE_LEAVES = 5;
    bytes32 constant private TREE_KEY        = keccak256("JACKPOT");
    
    SortitionSumTreeFactory.SortitionSumTrees private sortitionSumTrees;

    event PurchaseTicket(uint session_id, uint multiplier_rate, uint pool_index, uint eth_per_ticket, uint tvl, uint weightage, uint timestamp, address buyer);
    event Claim(uint session_id, uint claimable, uint actual_claimable, uint penalty_amount, uint timestamp, address buyer);
    event CompletePot(uint conclude_session, uint reward_amount, uint timestamp);
    event UpdateMultiplierList(uint[] multiplier_list);
    event UpdatePenaltySetting(uint rate_penalty, uint penalty_base_minute);
    event UpdateContracts(address tube, address tube_chief, address buyback, address dev, address utility, address uniswap_router, address signer);
    event UpdateRewardBySessionId(uint session_id, uint amount);
    event UpdateRewardPermission(address _address, bool status);
    event UpdateAccessPermission(address _address, bool status);
    event UpdatePoolCategory(uint new_max_category, uint[] reward_rates, uint[] chance_rates);
    event UpdateSessionEndTimestamp(uint end_timestamp);
    event UpdateStopNextSession(bool status);
    event UpdateSwapPayment(bool status);
    event UpdateSessionMinute(uint minute);
    event UpdatePaymentRateDistribution(uint rate_buyback, uint rate_dev);
    event UpdateToggleBySession(uint session_id, bool deposit_paused, bool claim_paused);
    event UpdateEthPerTicket(uint eth_per_ticket);
    event TransferOwner(address old_owner, address new_owner);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier hasAccessPermission {
        require(access_permission[msg.sender], "no access permission");
        _;
    }

    /*
    * init function after contract deployment
    */
    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);
        
        owner = msg.sender;
        
        // constant value
        DECIMAL  = 18;
        PER_UNIT = 1000000000000000000;
        
        // multipliers (1.5, 3, 6, 9)
        multiplier_list.push(1500000000000000000);
        multiplier_list.push(3000000000000000000);
        multiplier_list.push(6000000000000000000);
        multiplier_list.push(9000000000000000000);
        
        // reward distribution: P1[0] 33%, P2[1] 33%, P3[2] 33%
        // chances enter pool : P1[0] 50%, P2[1] 30%, P3[2] 20%
        category_size = 3;
        pool_reward_list[0] = 333333333333333333;
        pool_reward_list[1] = 333333333333333333;
        pool_reward_list[2] = 333333333333333333;
        _updatePoolChances(0, 500000000000000000);
        _updatePoolChances(1, 300000000000000000);
        _updatePoolChances(2, 200000000000000000);

        // per session duration 7 day
        session_minute = 10080;
        session_id     = 2;
        
        // ticket price (0.2 ETH)
        eth_per_ticket = 200000000000000000;
        
        // payment received distribution (remaining 10% will for utility)
        rate_buyback = 700000000000000000;
        rate_dev     = 200000000000000000;
        
        // penalty setting (30%, base lock up to 30 day)
        rate_penalty        = 300000000000000000;
        penalty_base_minute = 43200;
        
        // contract linking
        tube           = 0xdA86006036540822e0cd2861dBd2fD7FF9CAA0e8;
        tube_chief     = 0x5fe65B1172E148d1Ac4F44fFc4777c2D4731ee8f;
        dev            = 0xAd451FBEaee85D370ca953D2020bb0480c2Cfc45;
        buyback        = 0x702b11a838429Edca4Ea0e80c596501F1a4F4c28;
        utility        = 0x4679025788c92187d44BdA852e9fF97229e3109b;
        uniswap_router = 0x37D7f26405103C9Bc9D8F9352Cf32C5b655CBe02;
        signer         = 0xd916731C0063E0c8D93552bE0a021c9Ae15ff183;

        // permission
        access_permission[msg.sender] = true;
    }

    /*
    * user purchase ticket and join current session jackpot
    * @params tvl - input from front end with signature validation 
    */
    function purchaseTicket(uint _tvl, uint counter, bytes memory signature) public payable {
        require(!session[session_id].deposit_paused, "deposit paused");
        require(session[session_id].end_timestamp > block.timestamp, "jackpot ended");
        require(msg.value == eth_per_ticket, "invalid payment");
        require(counter > user_info[msg.sender].purchase_counter, 'EXPIRED COUNTER'); // prevent replay attack
        require(_verifySign(signer, msg.sender, _tvl, counter, signature), "invalid signature");

        // replace user purchase counter number
        user_info[msg.sender].purchase_counter = counter;
        
        // uniform lowest bound number is 0
        // result format is in array index so max upper bound number need to minus 1
        uint mul_index  = UniformRandomNumber.uniform(_rngSeed(), multiplier_list.length);
        uint pool_index = _pickPoolIndex();
        
        // tvl should source from maximizer pool. (LP staked value * weightage)
        uint actual_weightage = _tvl.mul(multiplier_list[mul_index], DECIMAL);
        
        pool[session_id][pool_index].total_weightage                = pool[session_id][pool_index].total_weightage.add(actual_weightage);
        user_pool[msg.sender][session_id][pool_index].weightage     = user_pool[msg.sender][session_id][pool_index].weightage.add(actual_weightage);
        user_pool[msg.sender][session_id][pool_index].num_of_ticket = user_pool[msg.sender][session_id][pool_index].num_of_ticket.add(1);
        user_session[msg.sender][session_id].tvl                    = user_session[msg.sender][session_id].tvl.add(_tvl);
        user_session[msg.sender][session_id].num_of_ticket          = user_session[msg.sender][session_id].num_of_ticket.add(1);
        user_session[msg.sender][session_id].has_purchased          = true;
        
        if (swap_payment) {
            _paymentDistributionDex(msg.value);
        } else {
            _paymentDistributionBuyback(msg.value);    
        }

        // withdrawal penalty set once
        // -> block.timestamp + 30 day + session(end - now)
        if (user_session[msg.sender][session_id].penalty_until_timestamp <= 0) {
            user_session[msg.sender][session_id].first_deposit_timestamp = block.timestamp;
            user_session[msg.sender][session_id].penalty_until_timestamp = session[session_id].end_timestamp.add(penalty_base_minute * 60);
        }
        
        emit PurchaseTicket(session_id, multiplier_list[mul_index], pool_index, eth_per_ticket, _tvl, actual_weightage, block.timestamp, msg.sender);
    }

    /*
    * user claim reward by session
    */
    function claimReward(uint _session_id) public {
        require(session[_session_id].can_claim, "claim not enable");
        require(!session[_session_id].claim_paused, "claim paused");
        require(!user_session[msg.sender][_session_id].has_claimed, "reward claimed");

        uint claimable = 0;
        for (uint pcategory = 0; pcategory < category_size; pcategory++) {
            claimable = claimable.add(_userReward(msg.sender, _session_id, pcategory, session[_session_id].total_reward));
        }
        
        uint actual_claimable = _rewardAfterPenalty(msg.sender, claimable, _session_id);
        uint penalty_amount   = claimable.sub(actual_claimable);

        // gas saving. transfer penalty amount for buyback
        if (claimable != actual_claimable) {
            TransferHelper.safeTransfer(tube, buyback, penalty_amount);    
        }

        TransferHelper.safeTransfer(tube, msg.sender, actual_claimable);
        user_session[msg.sender][_session_id].has_claimed = true;
        
        emit Claim(_session_id, claimable, actual_claimable, penalty_amount, block.timestamp, msg.sender);
    }
    
    /*
    * get current session ended
    */
    function getCurrentSessionEnded() public view returns(bool) {
        return (session[session_id].end_timestamp <= block.timestamp);
    }

    /*
    * get user in pool detail via pool category
    */
    function getUserPoolInfo(address _address, uint _session_id, uint _pool_category) public view returns(uint, uint, bool) {
        return (
            user_pool[_address][_session_id][_pool_category].weightage,
            user_pool[_address][_session_id][_pool_category].num_of_ticket,
            user_pool[_address][_session_id][_pool_category].claimed
        );
    }
    
    /*
    * get user information
    */
    function getUserInfo(address _address) public view returns(uint) {
        return (user_info[_address].purchase_counter);
    }

    /*
    * get user in the session
    */
    function getUserSessionInfo(address _address, uint _session_id) public view returns(uint, uint, bool, bool, uint, uint) {
        return (
            user_session[_address][_session_id].tvl,
            user_session[_address][_session_id].num_of_ticket,
            user_session[_address][_session_id].has_purchased,
            user_session[_address][_session_id].has_claimed,
            user_session[_address][_session_id].first_deposit_timestamp,
            user_session[_address][_session_id].penalty_until_timestamp
        );
    }

    /*
    * get user has participant on current jackpot session or not
    */
    function getCurrentSessionJoined(address _address) public view returns (bool) {
        return user_session[_address][session_id].has_purchased;
    }

    /*
    * get pool info
    */
    function getPool(uint _session_id, uint _pool_category) public view returns(uint, uint) {
        return (
            pool[_session_id][_pool_category].total_weightage,
            pool[_session_id][_pool_category].rate_reward    
        );
    }

    /*
    * get session info
    */
    function getSession(uint _session_id) public view returns(uint, uint, uint, bool, bool, bool) {
       return (
           session[_session_id].total_reward,
           session[_session_id].start_timestamp,
           session[_session_id].end_timestamp,
           session[_session_id].deposit_paused,
           session[_session_id].can_claim,
           session[_session_id].claim_paused
        );
    }
    
    /*
    * get all pool reward by session ID
    */
    function getPoolRewardBySession(uint _session_id) public view returns(uint, uint[] memory) {
        uint reward_tube  = 0;
        if (_session_id == session_id) {
             reward_tube = reward_tube.add(ITubeChief(tube_chief).getJackpotReward());
        }

        // local reward + pending tube chief reward
        uint reward_atm            = reward_tube.add(session[_session_id].total_reward);
        uint[] memory pool_rewards = new uint[](category_size);

        for (uint pcategory = 0; pcategory < category_size; pcategory++) {
            pool_rewards[pcategory] = reward_atm.mul(pool[_session_id][pcategory].rate_reward, DECIMAL);
        }

        return (category_size, pool_rewards);
    }

    /*
    * get user reward by session ID
    */
    function getUserRewardBySession(address _address, uint _session_id) public view returns (uint, uint) {
        uint reward_atm = session[_session_id].total_reward;

        if (_session_id == session_id) {
             reward_atm = reward_atm.add(ITubeChief(tube_chief).getJackpotReward());
        }

        uint claimable = 0;
        for (uint pcategory = 0; pcategory < category_size; pcategory++) {
            claimable = claimable.add(_userReward(_address, _session_id, pcategory, reward_atm));
        }

        uint max_claimable = claimable;

        claimable = _rewardAfterPenalty(_address, claimable, _session_id);

        return (max_claimable, claimable);
    }

    /*
    * start jackpot new session
    */
    function initPot() public hasAccessPermission {
        _startPot();
    }

    /*
    * update ticket prcing
    */
    function updateEthPerTicket(uint _eth_per_ticket) public hasAccessPermission {
        eth_per_ticket = _eth_per_ticket;
        emit UpdateEthPerTicket(eth_per_ticket);
    }
    
    /*
    * update jackpot control toggle by session ID
    */
    function updateToggleBySession(uint _session_id, bool _deposit_paused, bool _claim_paused) public hasAccessPermission {
        session[_session_id].deposit_paused = _deposit_paused;
        session[_session_id].claim_paused   = _claim_paused;
        emit UpdateToggleBySession(_session_id, _deposit_paused, _claim_paused);
    }

    /*
    * update current session end timestamp
    */
    function updateSessionEndTimestamp(uint end_timestamp) public hasAccessPermission {
        session[session_id].end_timestamp = end_timestamp;
        emit UpdateSessionEndTimestamp(end_timestamp);
    }

    /*
    * resetup pool category size and reward distribution
    * XX update will reflect immediately
    */
    function updateMultiplierList(uint[] memory _multiplier_list) public hasAccessPermission {
       multiplier_list = _multiplier_list;
       emit UpdateMultiplierList(multiplier_list);
    }

    /*
    * update penatly setting
    */
    function updatePenaltySetting(uint _rate_penalty, uint _penalty_base_minute) public hasAccessPermission {
        rate_penalty        = _rate_penalty;
        penalty_base_minute = _penalty_base_minute;
        emit UpdatePenaltySetting(rate_penalty, penalty_base_minute);
    }
    
    /*
    * update payment rate distribution to each sectors
    * (!) rate utility will auto result in (1 - rate_buyback - rate_dev)
    */
    function updatePaymentRateDistribution(uint _rate_buyback, uint _rate_dev) public hasAccessPermission {
        rate_buyback = _rate_buyback;
        rate_dev     = _rate_dev;
        emit UpdatePaymentRateDistribution(rate_buyback, rate_dev);
    }

    /*
    * update contract addresses
    */
    function updateContracts(
        address _tube,
        address _tube_chief,
        address _buyback,
        address _dev,
        address _utility,
        address _uniswap_router,
        address _signer
    ) public hasAccessPermission {
        tube           = _tube;
        tube_chief     = _tube_chief;
        buyback        = _buyback;
        dev            = _dev;
        utility        = _utility;
        uniswap_router = _uniswap_router;
        signer         = _signer;
        emit UpdateContracts(tube, tube_chief, buyback, dev, utility, uniswap_router, signer);
    }

    /*
    * resetup pool category size and reward distribution
    * @param new_max_category - total pool size
    * @param reward_rates     - each pool reward distribution rate
    * @param chance_rates     - change rate of user will enter the pool
    * XX pool reward rate update will reflect on next session
    * XX pool chance rate update will reflect now
    * XX may incur high gas fee
    */
    function updatePoolCategory(uint new_max_category, uint[] memory reward_rates, uint[] memory chance_rates) public hasAccessPermission {
        require(reward_rates.length == category_size, "invalid input size");

        // remove old setting
        for (uint i = 0; i < category_size; i++) {
            delete pool_reward_list[i];
            delete pool_chances[i];
            _updatePoolChances(i, 0);
        }

        // add new setting
        for (uint i = 0; i < new_max_category; i++) {
            pool_reward_list[i] = reward_rates[i];
            _updatePoolChances(i, chance_rates[i]);
        }

        category_size = new_max_category;
        
        emit UpdatePoolCategory(new_max_category, reward_rates, chance_rates);
    }

    /*
    * update stop next session status
    */
    function updateStopNextSession(bool status) public hasAccessPermission {
        stop_next_session = status;
        emit UpdateStopNextSession(status);
    }
    
    /*
    * update jackpot duration
    * XX update reflect on next session
    */
    function updateSessionMinute(uint minute) public hasAccessPermission {
        session_minute = minute;
        emit UpdateSessionMinute(minute);
    }
    
    /*
    * update swap payment method
    */
    function updateSwapPayment(bool status) public hasAccessPermission {
        swap_payment = status;
        emit UpdateSwapPayment(status);
    }

    /*
    * update access permission
    */
    function updateAccessPermission(address _address, bool status) public onlyOwner {
        access_permission[_address] = status;
        emit UpdateAccessPermission(_address, status);
    }

    /*
    * conclude current session and start new session
    * - transferJackpot
    * - completePot
    */
    function completePot() public hasAccessPermission {
        require(session[session_id].end_timestamp <= block.timestamp, "session not end");

        /*
        * 1. main contract will transfer TUBE to this contract
        * 2. update the total reward amount for current session
        */
        uint conclude_session = session_id;
        uint reward_amount    = ITubeChief(tube_chief).transferJackpotReward();

        session[conclude_session].total_reward = session[conclude_session].total_reward.add(reward_amount);
        session[conclude_session].can_claim    = true;
        session_id = session_id.add(1);
        
        if (!stop_next_session) {
            _startPot();
        }
        
        // if pool weightage is empty, transfer pool reward to buyback
        for (uint pcategory = 0; pcategory < category_size; pcategory++) {
            if (pool[conclude_session][pcategory].total_weightage > 0) {
                continue;
            }
            uint amount = session[conclude_session].total_reward.mul(pool[conclude_session][pcategory].rate_reward, DECIMAL);
            TransferHelper.safeTransfer(tube, buyback, amount);
        }
        
        emit CompletePot(conclude_session, reward_amount, block.timestamp);
    }
    
    /*
    * transfer ownership. proceed wisely. only owner executable
    */
    function transferOwner(address new_owner) public onlyOwner {
        emit TransferOwner(owner, new_owner);
        owner = new_owner;
    }
    
    /*
    * emergency collect token from the contract. only owner executable
    */
    function emergencyCollectToken(address token, uint amount) public onlyOwner {
        TransferHelper.safeTransfer(token, owner, amount);
    }

    /*
    * emergency collect eth from the contract. only owner executable
    */
    function emergencyCollectEth(uint amount) public onlyOwner {
        address payable owner_address = payable(owner);
        TransferHelper.safeTransferETH(owner_address, amount);
    }

    function _userReward(address _address, uint _session_id, uint _pool_category, uint _total_reward) internal view returns (uint) {
        // (Z / Total Z of all users) x P1 / P2 / P3 TUBE2 = X amount of reward
        uint total_weight = pool[_session_id][_pool_category].total_weightage;
        
        if (total_weight <= 0 || user_pool[_address][_session_id][_pool_category].claimed) {
            return 0;
        }

        uint user_weight = user_pool[_address][_session_id][_pool_category].weightage;
        uint rate        = pool[_session_id][_pool_category].rate_reward;

        return user_weight.div(total_weight, DECIMAL).mul(_total_reward, DECIMAL).mul(rate, DECIMAL);
    }

    function _startPot() internal {
        session[session_id].start_timestamp = block.timestamp;
        session[session_id].end_timestamp   = block.timestamp.add(session_minute * 60);
        
        // init P1, P2, P3
        for (uint i = 0; i < category_size; i++) {
            pool[session_id][i].rate_reward = pool_reward_list[i];
        }
    }

    function _paymentDistributionDex(uint amount) internal {
        uint buyback_amount = amount.mul(rate_buyback, DECIMAL);
        uint dev_amount     = amount.mul(rate_dev, DECIMAL);
        uint utility_amount = amount.sub(buyback_amount).sub(dev_amount);
        uint tube_swapped   = _swapEthToTUBE(buyback_amount);
        
        TransferHelper.safeTransfer(tube, address(0), tube_swapped);
        TransferHelper.safeTransferETH(dev, dev_amount);
        TransferHelper.safeTransferETH(utility, utility_amount);
    }
    
    function _paymentDistributionBuyback(uint amount) internal {
        /*
        * distribution plan (initial)
        * buyback     - 70% (buyback)
        * masternode  - 20% (dev)
        * leaderboard - 10% (utility)
        */
        uint buyback_amount = amount.mul(rate_buyback, DECIMAL);
        uint dev_amount     = amount.mul(rate_dev, DECIMAL);
        uint utility_amount = amount.sub(buyback_amount).sub(dev_amount);

        TransferHelper.safeTransferETH(buyback, buyback_amount);
        TransferHelper.safeTransferETH(dev, dev_amount);
        TransferHelper.safeTransferETH(utility, utility_amount);
    }

    function _rngSeed() internal returns (uint) {
        uint seed = uint256(keccak256(abi.encode(block.number, msg.sender, preseed)));
        preseed   = seed;
        return seed;
    }

    function _swapEthToTUBE(uint amount) internal returns (uint) {
        require(amount > 0, "empty swap amount");

        TransferHelper.safeApprove(tube, uniswap_router, amount);
        
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswap_router).WETH();
        path[1] = tube;
        
        // lower down the receive expectation to prevent high failure
        uint buffer_rate = 980000000000000000;
        uint deadline    = block.timestamp.add(60);
        uint[] memory amount_out_min = new uint[](2);

        amount_out_min        = IUniswapV2Router02(uniswap_router).getAmountsOut(amount, path);
        amount_out_min[1]     = amount_out_min[1].mul(buffer_rate, DECIMAL);
        uint[] memory swapped = IUniswapV2Router02(uniswap_router).swapExactETHForTokens{ value: amount }(amount_out_min[1], path, address(this), deadline);

        return swapped[1];
    }

    function _rewardAfterPenalty(address _address, uint reward_amount, uint _session_id) internal view returns (uint) {
        /*
        * calculate the reward amount after penalty condition
        *
        * 1. get the withdrawable amount
        * 2. get the withdraw penalty rate
        * 3. get time ratio: (userPenaltyEndTime - now) / (penalty_base_minute * 60)
        * 4. result = [full reward] x [penalty rate] x [time ratio]
        */
        if (user_session[_address][_session_id].penalty_until_timestamp >= block.timestamp) {
           uint end            = user_session[_address][_session_id].penalty_until_timestamp;
           uint diff_now       = end.sub(block.timestamp);
           uint time_ratio     = diff_now.div(penalty_base_minute * 60, DECIMAL);
           uint penalty_amount = reward_amount.mul(rate_penalty, DECIMAL).mul(time_ratio, DECIMAL);

           reward_amount = reward_amount.sub(penalty_amount);
        }
        return reward_amount;
    }
    
    function _updatePoolChances(uint pool_index, uint chance_rate) internal {
        pool_chances[pool_index] = chance_rate;
        sortitionSumTrees.set(TREE_KEY, chance_rate, bytes32(uint256(pool_index)));
    }
    
    function _pickPoolIndex() internal returns (uint) {
        return uint256(sortitionSumTrees.draw(TREE_KEY, _rngSeed()));
    }

    /*
    * VerifySignature
    */
    function _getMessageHash(address buyer, uint tvl, uint counter) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(buyer, tvl, counter));
    }

    function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function _verifySign(address _signer, address buyer, uint tvl, uint counter, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = _getMessageHash(buyer, tvl, counter);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        return _recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

interface ITubeChief {
    function getJackpotReward() external view returns (uint);
    function transferJackpotReward() external returns (uint);
}