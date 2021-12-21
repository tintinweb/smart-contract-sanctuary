// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITulipFarm.sol";
import "./interfaces/ITulipToken.sol";
import "./libraries/SortitionSumTreeFactory.sol";
import "./libraries/UniformRandomNumber.sol";

contract TulipFarm is ITulipFarm, Ownable {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    using SafeMath for uint256;

    bytes32 private constant TREE_KEY = keccak256("TulipFarm/Staking");
    uint256 private constant MAX_TREE_LEAVES = 5;

    // Staked-weighted odds
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    uint256 public testNumber;

    enum RoundState {
        OPEN,
        DRAWING,
        CLOSED
    }

    struct UserInfo {
        uint256 amount; // How many Land Tokens the User Staked
        uint256 blockNumberLastStaked; // Block Number when user last staked
    }

    struct PrizeInfo {
        uint256[] id; // This is filled be filled by the Oracle/Keeper
        bool winner; // This is filled by us to specify that this user won
        bool claimed; // This is filled when the user claims the prize
    }

    struct RoundInfo {
        uint256 roundId; // ID of the round
        RoundState roundState; // Current state of the round
    }

    struct LotteryCandidate {
        address implementation;
        uint256 proposedTime;
    }

    /**
        totalStaked is used to keep track of the amount of LAND tokens
        staked through the functions, this is used in the Drawing calculation.

        We do not want to use IERC20(LAND).balanceOf(address(this)) as users can
        directly send LAND tokens to this contract and break the drawing
        calculation.
    */
    uint256 public totalStaked;
    address public landToken;
    address public tulipNFTToken;
    address public lotteryContract;

    // The minimum time it has to pass before a lottery candidate can be approved.
    uint256 public immutable approvalDelay;

    // The last proposed lottery to switch to.
    LotteryCandidate public lotteryCandidate;

    // Map of all the users which have been deposited into this contract
    mapping(address => UserInfo) public userInfo;

    // List of rounds
    RoundInfo[] public roundInfo;

    // Mapping the rounds to the winners of those roundes
    mapping(uint256 => mapping(address => PrizeInfo)) public winners;

    event PrizeClaimed(address indexed winner, uint256 id);
    event NewLotteryCandidate(address implementation);
    event UpgradeLottery(address implementation);
    event RoundDrawStarted(uint256 currentRound);
    event RoundDrawFinished(uint256 currentRound);
    event WinnerSet(address winner);

    constructor(
        address _landToken,
        address _tulipNFTToken,
        uint256 _approvalDelay
    ) public {
        landToken = _landToken;
        tulipNFTToken = _tulipNFTToken;
        approvalDelay = _approvalDelay;
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);

        // Start the rounds off in drawing phase
        roundInfo.push(RoundInfo({roundId: 1, roundState: RoundState.OPEN}));
    }

    modifier doesRoundExist(uint256 _pid) {
        require(_pid < totalRounds(), "TULIPFARM: ERROR ROUND DOESN'T EXIST!");
        _;
    }

    modifier onlyLottery() {
        require(msg.sender == lotteryContract, "TULIPFARM: ERROR NOT LOTTERY!");
        _;
    }

    /// @notice Returns the user's chance of winning.
    function chanceOf(address user) external view override returns (uint256) {
        return sortitionSumTrees.stakeOf(TREE_KEY, bytes32(uint256(user)));
    }

    function totalRounds() public view returns (uint256) {
        return roundInfo.length;
    }

    function enterStaking(uint256 _amount) external override {
        RoundInfo storage round = roundInfo[totalRounds().sub(1)];
        UserInfo storage user = userInfo[msg.sender];

        require(_amount >= 0, "TULIPFARM: AMOUNTS <= 0 NOT ALLOWED!");
        require(
            round.roundState == RoundState.OPEN,
            "TULIPFARM: ROUND NOT OPEN!"
        );

        IERC20(landToken).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        user.amount = user.amount.add(_amount);
        user.blockNumberLastStaked = block.number;
        totalStaked = totalStaked.add(_amount);
        sortitionSumTrees.set(
            TREE_KEY,
            user.amount,
            bytes32(uint256(msg.sender))
        );
    }

    function leaveStaking(uint256 _amount) external override {
        UserInfo storage user = userInfo[msg.sender];
        RoundInfo storage round = roundInfo[totalRounds().sub(1)];

        require(_amount >= 0, "TULIPFARM: AMOUNT <= 0 NOT ALLOWED!");
        require(
            _amount <= user.amount,
            "TULIPFARM: CANNOT UNSTAKE MORE THAN THE USER STAKED AMOUNT!"
        );
        require(
            round.roundState == RoundState.OPEN,
            "TULIPFARM: ROUND NOT OPEN!"
        );

        user.amount = user.amount.sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        IERC20(landToken).transfer(address(msg.sender), _amount);
        sortitionSumTrees.set(
            TREE_KEY,
            user.amount,
            bytes32(uint256(msg.sender))
        );
    }

    /// @notice Selects a user using a random number.  The random number will
    ///         be uniformly bounded to the total Stake.
    /// @param randomNumber The random number to use to select a user.
    /// @return The winner
    function draw(uint256 randomNumber)
        external
        view
        override
        returns (address)
    {
        address selected;
        if (totalStaked == 0) {
            selected = address(0);
        } else {
            uint256 token = UniformRandomNumber.uniform(
                randomNumber,
                totalStaked
            );
            selected = address(
                uint256(sortitionSumTrees.draw(TREE_KEY, token))
            );
        }
        return selected;
    }

    function claimPrize(uint256 _pid) external doesRoundExist(_pid) {
        RoundInfo storage round = roundInfo[_pid];
        PrizeInfo storage prize = winners[_pid][msg.sender];
        require(
            round.roundState == RoundState.CLOSED,
            "TULIPFARM: ROUND NOT CLOSED!"
        );
        require(!prize.claimed, "TULIPFARM: PRIZE ALREADY CLAIMED FOR ROUND!");
        require(prize.winner, "TULIPFARM: NOT A WINNER!");

        // Set claimed as true so user won't be able to re-mint the token
        prize.claimed = true;

        for (uint256 i = 0; i < prize.id.length; i++) {
            ITulipToken(tulipNFTToken).mint(msg.sender, prize.id[i]);
            emit PrizeClaimed(msg.sender, prize.id[i]);
        }
    }

    function startDraw() external override onlyLottery {
        require(totalStaked > 0, "TULIPFARM: NO USERS!");
        uint256 currentRound = totalRounds().sub(1);
        RoundInfo storage round = roundInfo[currentRound];
        require(
            round.roundState == RoundState.OPEN,
            "TULIPFARM: ROUND IS NOT OPEN!"
        );
        round.roundState = RoundState.DRAWING;
        emit RoundDrawStarted(currentRound);
    }

    function finishDraw() external override onlyLottery {
        uint256 currentRound = totalRounds().sub(1);
        RoundInfo storage round = roundInfo[currentRound];
        require(
            round.roundState == RoundState.DRAWING,
            "TULIPFARM: ROUND IS NOT DRAWING!"
        );
        round.roundState = RoundState.CLOSED;
        roundInfo.push(
            RoundInfo({
                roundId: currentRound.add(1),
                roundState: RoundState.OPEN
            })
        );
        emit RoundDrawFinished(currentRound);
    }

    function setWinner(address _winner) external override onlyLottery {
        uint256 currentRound = totalRounds().sub(1);
        PrizeInfo storage prize = winners[currentRound][_winner];
        RoundInfo storage round = roundInfo[currentRound];
        require(
            round.roundState == RoundState.DRAWING,
            "TULIPFARM: ROUND IS NOT DRAWING!"
        );
        prize.id.push(
            ITulipToken(tulipNFTToken).incrementToBeMinted()
        );
        prize.winner = true;
        prize.claimed = false; // Should already be false by default
        emit WinnerSet(_winner);
    }

    /**
     * @dev Sets the candidate for the new lottery to use with this staking
     *      contract.
     * @param _implementation The address of the candidate lottery.
     */
    function proposeLottery(address _implementation) public onlyOwner {
        lotteryCandidate = LotteryCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
        });

        emit NewLotteryCandidate(_implementation);
    }

    /**
     * @dev It switches the active lottery for the lottery candidate. After upgrading, the
     * candidate implementation is set to the 0x00 address, and proposedTime to a time
     * happening in +100 years for safety.
     */
    function upgradeLottery() public onlyOwner {
        require(
            lotteryCandidate.implementation != address(0),
            "TULIPFARM: THERE IS NO CANDIDATE!"
        );

        if (lotteryContract != address(0)) {
            require(
                lotteryCandidate.proposedTime.add(approvalDelay) <
                    block.timestamp,
                "TULIPFARM: DELAY HAS NOT PASSED!"
            );
        }

        emit UpgradeLottery(lotteryCandidate.implementation);

        lotteryContract = lotteryCandidate.implementation;
        lotteryCandidate.implementation = address(0);
        lotteryCandidate.proposedTime = 5000000000;
    }

    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_token != landToken, "TulipFarm: Can't drain LAND tokens!");
        IERC20(_token).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITulipFarm {
    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function setWinner(address _winner) external;

    function startDraw() external;

    function finishDraw() external;

    function chanceOf(address user) external view returns (uint256);

    function draw(uint256 randomNumber) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITulipToken {
    function setBaseURI(string memory _newURI) external;

    function isMinter(address _minterAddress) external view returns (bool);

    function changeMinterRole(address _minter, bool _role) external;

    function mint(address _to, uint256 _id) external;

    function totalTokensMinted() external view returns (uint256);

    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function incrementToBeMinted() external returns (uint256);

    function totalTokensToBeMinted() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: UNLICENSED

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

pragma solidity >=0.6.0 <0.8.0;

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
    function uniform(uint256 _entropy, uint256 _upperBound)
        internal
        pure
        returns (uint256)
    {
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