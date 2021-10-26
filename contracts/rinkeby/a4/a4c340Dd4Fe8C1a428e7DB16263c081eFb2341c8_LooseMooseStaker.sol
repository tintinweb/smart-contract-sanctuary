// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// LooseMooseNFT staking contract
// Deposit LooseMoose, receive 10 ANTLER per NFT per day
contract LooseMooseStaker is IERC721Receiver {
    using SafeMath for uint256;

    mapping (address => uint256[]) public stakedTokens;
    mapping (address => uint256)   public rewards;
    mapping (address => uint256)   public lastUpdated;
    
    IERC721     public stakingToken; // LooseMoose
    IERC20      public rewardToken;  // ANTLER

    uint256 REWARD_PER_TOKEN_PER_DAY = 10 * 10**18; // 10 ANTLER
    uint256 ONE_DAY = 60*60*24; // Seconds in a day

    event ClaimRewards(address indexed user, address indexed to, uint256 amount);
    event Stake(address indexed user, uint256[] tokens);
    event StakeOnERC721Received(address indexed user, uint256 token);
    event Unstake(address indexed user, uint256[] tokens);    

    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC721(_stakingToken);
        rewardToken = IERC20(_rewardToken);

    }

    
    function getPendingRewards(address _user) public view returns (uint256) {
        return rewards[_user]
            .add((block.timestamp.sub(lastUpdated[_user]))
            .mul(stakedTokens[_user].length)
            .mul(REWARD_PER_TOKEN_PER_DAY)
            .div(ONE_DAY));
    }

    function updateRewards(address _user) private {
        if (lastUpdated[_user] == block.timestamp) return;
        rewards[_user] = getPendingRewards(_user);
        lastUpdated[_user] = block.timestamp;
    }

    function stake(uint256[] calldata _tokens) external {
        require(_tokens.length > 0, "Staker: empty input");
        updateRewards(msg.sender);
        for (uint256 i = 0; i < _tokens.length; i++) {
            stakingToken.transferFrom(msg.sender, address(this), _tokens[i]);
            stakedTokens[msg.sender].push(_tokens[i]);
        }
        emit Stake(msg.sender, _tokens);
    }

    function unstake(uint256[] calldata _tokens) external {
        require(_tokens.length > 0, "Staker: empty input");
        updateRewards(msg.sender);

        // Search for _tokens in stakedTokens[msg.sender], and remove using swap and pop once found.
        for (uint256 i = 0; i < _tokens.length; i++) {
            bool foundToken = false;
            for (uint256 j = 0; j < stakedTokens[msg.sender].length; j++) {
                if (_tokens[i] == stakedTokens[msg.sender][j]) {
                    // Found element in staked tokens array - swap with last element and remove last element
                    (stakedTokens[msg.sender][j], stakedTokens[msg.sender][(stakedTokens[msg.sender].length)-1]) =
                        (stakedTokens[msg.sender][(stakedTokens[msg.sender].length)-1], stakedTokens[msg.sender][j]);
                    stakedTokens[msg.sender].pop();
                    foundToken = true;
                    break;
                }
            }
            require(foundToken, "Staker: invalid input: token not already staked");
            stakingToken.safeTransferFrom(address(this), msg.sender, _tokens[i]);
        }
        
        emit Unstake(msg.sender, _tokens);
    }

    function claimRewards(address _to) external {
        updateRewards(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "Staker: rewards balance is 0");
        rewards[msg.sender] = 0;
        require(rewardToken.transfer(_to, reward), "Staker: reward token transfer failed"); // Might wanna use SafeERC20 if transferring unknown tokens, but that is not our case
        emit ClaimRewards(msg.sender, _to, reward);
    }

    // Implementing to be able to support safeTransferFrom transfers to this contract.
    // This is just for safety, the recommended flow is using proper stake() function for gas savings.
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        updateRewards(from);
        stakedTokens[from].push(tokenId);
        emit StakeOnERC721Received(from, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    /* 
        ####################################################
        ################## View functions ##################
        ####################################################

    */

    function getStakedTokens(address _user) external view returns (uint256[] memory) {
        return stakedTokens[_user];
    }

    function getTotalStaked() external view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    function getPendingRewards() external view returns (uint256) {
        return getPendingRewards(msg.sender);
    }

    function getData() external view returns (uint256 rewardPerDay, uint256 totalStaked, uint256[] memory userStaked, uint256 pendingRewards) {
        rewardPerDay = REWARD_PER_TOKEN_PER_DAY;
        totalStaked = stakingToken.balanceOf(address(this));
        userStaked = stakedTokens[msg.sender];
        pendingRewards = getPendingRewards(msg.sender);
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}