// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Pausable is Context {
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
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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


contract Ownable is Context {
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


contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract StakingPool is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC1155 public apeToken;
    address private apeOwner;
    mapping(address => uint256[]) public staked;
    mapping(address => uint256[]) public stakedFemales;
    mapping(address => uint256[]) public stakedMales;
    mapping(address => uint256) public stakedBabies;
    mapping(uint256 => bool) private femaleId;
    mapping(uint256 => bool) private maleId;
    mapping(uint256 => bool) private babyId;
    mapping(uint256 => uint256[]) private babyOf;
    mapping(uint256 => uint256) private birth;
    mapping(uint256 => uint256) public breedingEnd;
    mapping(uint256 => uint256) private maxBabies;
    mapping(uint256 => uint256) private multiplier;
    mapping(address => uint256) public userMultiplier;
    uint256[] public certificates;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _apeToken, address _apeOwner) public {
        apeToken = IERC1155(_apeToken);
        apeOwner = _apeOwner;
    }

    /* ========== STAKING FUNCTIONS ========== */

    function deposit() external payable {
        // todo remove this function before deployment
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .div(_totalSupply)
                    .mul(userMultiplier[msg.sender]) // multipliers = 2, 3, 4
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            msg.sender.transfer(reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = address(this).balance;
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== INITIATE FUNCTIONS ========== */

    function initiateBaby(uint256[] memory id) external onlyOwner {
        uint256 i;
        for (i=0; i < id.length; i++) {
            babyId[id[i]] = true;
            emit BabyInitiated(id[i]);
        }
    }

    function initiateBabies(uint256[] memory female, uint256[] memory baby) external onlyOwner {
        require(female.length == baby.length, "!length");
        uint256 i;
        for (i=0; i < female.length; i++) {
            babyOf[female[i]].push(baby[i]);
            emit BabyMatched(female[i], baby[i]);
        }
    }

    function initiateCertificates(uint256[] memory certificate) external onlyOwner {
        uint256 i;
        for (i=0; i < certificate.length; i++) {
                certificates.push(certificate[i]);
        }
    }

    function initiateFemale(uint256[] memory female, uint256[] memory _maxBabies) external onlyOwner {
        require(female.length == _maxBabies.length, "!length");
        uint256 i;
        for (i=0; i < female.length; i++) {
            femaleId[female[i]] = true;
            maxBabies[female[i]] = _maxBabies[i];
            emit FemaleInitiated(female[i], _maxBabies[i]);
        }
    }

    function initiateMale(uint256[] memory male, uint256[] memory _multiplier) external onlyOwner {
        require(male.length == _multiplier.length, "!length");
        uint256 i;
        for (i=0; i < male.length; i++) {
            maleId[male[i]] = true;
            multiplier[male[i]] = _multiplier[i];
            emit MaleInitiated(male[i], _multiplier[i]);
        }
    }

    function _calculateUserMultiplier() internal {
        uint256 femaleLength = stakedFemales[msg.sender].length;
        uint256 maleLength = stakedMales[msg.sender].length;
        uint256 certificateLength = _haveCertificate(msg.sender);
        uint256 familyCount = femaleLength > maleLength ? maleLength : femaleLength;
        if(familyCount >= stakedBabies[msg.sender] / 2) {
            familyCount = stakedBabies[msg.sender] / 2;
        } else {
            if(femaleLength < maleLength && (maleLength - femaleLength) >= 2) {
                uint256 estimateAddCount = (maleLength - femaleLength) / 2;
                estimateAddCount = estimateAddCount > certificateLength ? certificateLength : estimateAddCount;
                familyCount = (familyCount + estimateAddCount) < stakedBabies[msg.sender] / 2 ? (familyCount + estimateAddCount) : stakedBabies[msg.sender] / 2;
            }
        }
        uint256 multiplierSum = 0;
        for(uint256 i=0; i< familyCount; i++) {
            multiplierSum += multiplier[stakedMales[msg.sender][i]];
        }
        userMultiplier[msg.sender] = multiplierSum;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _stake(uint256 tokenId) internal whenNotPaused updateReward(msg.sender) {
        if (femaleId[tokenId] == true) {
            stakedFemales[msg.sender].push(tokenId);
            // start breeding
            _breeding();
        } else if (maleId[tokenId] == true) {
            stakedMales[msg.sender].push(tokenId);
            // start breeding
            _breeding();
        } else if (babyId[tokenId] == true) {
            stakedBabies[msg.sender]++;
        } else {
            revert("wrong ape");
        }
        // start pay rewards
        if (_eligibleForRewards()) {
            _balances[msg.sender] = 1e18;
        }
        // _totalSupply++;
        staked[msg.sender].push(tokenId);
        // calculate family state and multiplier
        _calculateUserMultiplier();
        apeToken.safeTransferFrom(msg.sender, address(this), tokenId, 1, "0x0");
        emit Staked(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenId) external {
        uint i;
        uint256 length = tokenId.length;
        _totalSupply -= userMultiplier[msg.sender];
        for (i=0; i < length; i++) {
            _stake(tokenId[i]);
        }
        _totalSupply += userMultiplier[msg.sender];
    }

    function withdrawAll() external {
        uint i;
        uint256 length = staked[msg.sender].length;
        _totalSupply -= userMultiplier[msg.sender];
        for (i=0; i < length; i++) {
            _withdraw(staked[msg.sender][0]);
        }
    }

    function exit() external {
        uint i;
        uint256 length = staked[msg.sender].length;
        for (i=0; i < length; i++) {
            _withdraw(staked[msg.sender][0]);
        }
        getReward();
    }

    function claimBaby() external nonReentrant whenNotPaused returns(uint256) {
        require(stakedFemales[msg.sender].length >= 1, "female not staked");

        for(uint256 i=0; i < stakedFemales[msg.sender].length; i++) {
            if(_breedingTime(stakedFemales[msg.sender][i]) && breedingEnd[stakedFemales[msg.sender][i]] != 0) {
                uint256 female = stakedFemales[msg.sender][i];
                uint256 _maxBabies = maxBabies[female];
                if(birth[female]+1 <= _maxBabies){
                    breedingEnd[female] = now + 10 days;
                    apeToken.safeTransferFrom(apeOwner, msg.sender, babyOf[female][birth[female]], 1, "0x0");
                    emit Claimed(msg.sender, babyOf[female][birth[female]]);
                    birth[female]++;
                }
            }
        }
    }

    function getBaby(uint256 female) external view returns(uint256) {
        return babyOf[female][birth[female]];
    }

    function _withdraw(uint256 tokenId) internal whenNotPaused updateReward(msg.sender) {
      require(_isStaked(tokenId),"not staked");
        if (femaleId[tokenId] == true) {
            stakedFemales[msg.sender].pop();
            breedingEnd[tokenId] = 0; // start breeding again
        } else if (maleId[tokenId] == true) {
            stakedMales[msg.sender].pop();
            if( stakedMales[msg.sender].length < stakedFemales[msg.sender].length ) {
                breedingEnd[stakedFemales[msg.sender][stakedFemales[msg.sender].length - 1]] = 0;
            }
            // breedingEnd[msg.sender] = 0;
            // update current multiplier
            userMultiplier[msg.sender] = 0;
        } else {
            stakedBabies[msg.sender]--;
        }
        if (_eligibleForRewards()) {
            _balances[msg.sender] = 1e18;
        } else {
            _balances[msg.sender] = 0;
        }
        // _totalSupply--;
        _remove(tokenId);
        apeToken.safeTransferFrom(address(this), msg.sender, tokenId, 1, "0x0");
        emit Withdrawn(msg.sender, tokenId);
    }

    function _eligibleForRewards() internal view returns(bool) {
        if (stakedBabies[msg.sender] >= 2 && stakedFemales[msg.sender].length >= 1 && stakedMales[msg.sender].length >= 1) {
            return true;
        }
        if (stakedBabies[msg.sender] >= 2 && stakedMales[msg.sender].length >= 2) {
            if (_haveCertificate(msg.sender) > 0) {
                return true;
            }
        }
    }

    function _haveCertificate(address owner) internal view returns(uint256) {
        uint256 count = 0;
        for (uint256 index = 0; index < certificates.length; index++) {
            for(uint256 i=0; i< stakedMales[owner].length;i++) {
                if (stakedMales[owner][i] == certificates[index]) {
                    count++;
                    break;
                }
            }
        }
        return count;
    }

    function _breeding() internal {
        if (stakedFemales[msg.sender].length >= 1 && stakedMales[msg.sender].length >= 1) {
            if(stakedFemales[msg.sender].length <= stakedMales[msg.sender].length) {
                breedingEnd[stakedFemales[msg.sender][stakedFemales[msg.sender].length - 1]] = now + 10 days;
            }
            if(stakedFemales[msg.sender].length > stakedMales[msg.sender].length) {
                breedingEnd[stakedFemales[msg.sender][stakedMales[msg.sender].length - 1]] = now + 10 days;
            }
        }
    }

    function _breedingTime(uint256 tokenId) internal view returns(bool) {
        if (breedingEnd[tokenId] == 0) {
            return false;
        }
        if (now > breedingEnd[tokenId]) {
            return true;
        }
    }

    function _isStaked(uint256 tokenId) internal view returns(bool) {
        for (uint256 index = 0; index < staked[msg.sender].length; index++) {
            if (staked[msg.sender][index] == tokenId) {
                return true;
            }
        }
    }

    function _remove(uint256 tokenId) internal {
        uint256[] memory id = staked[msg.sender];
        for (uint256 index = 0; index < id.length; index++) {
            if (id[index] == tokenId) {
                staked[msg.sender][index] = staked[msg.sender][id.length-1];
                staked[msg.sender].pop();
                return;
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    receive() payable external {}

    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function withdrawEther() external onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getStaked(address owner) external view returns (uint256[] memory) {
        return staked[owner];
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);
    event Claimed(address indexed user, uint256 tokenId);
    event Recovered(address token, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event BabyInitiated(uint256 babyId);
    event FemaleInitiated(uint256 femaleId, uint256 maxBabies);
    event MaleInitiated(uint256 maleId, uint256 multiplier);
    event BabyMatched(uint256 femaleId, uint256 babyId);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}