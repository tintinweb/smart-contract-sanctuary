/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// File: @openzeppelin\contracts\math\SafeMath.sol
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\SafeMathUint8.sol

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
library SafeMathUint8 {
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
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMathUnit8: addition overflow");

        return c;
    }
}

// File: contracts\RigelGift.sol

/// @title RigelGift is responsible for managing crypto rewards and airdrops
contract RigelGift is Ownable {
    using SafeMath for uint256;
    using SafeMathUint8 for uint8;

    uint8 public _maxBuyableSpins;
    uint8 public _maxReferralSpins;

    address public _RGPTokenAddress;
    address public _RGPTokenReceiver;

    uint256 public _rewardProjectCounter;
    uint256 public _perSpinFee = 10 * 10**18;
    uint256 public _subscriptionFee = 10 * 10**18;

    // address _RGPTokenAddress = "0x4af5ff1a60a6ef6c7c8f9c4e304cd9051fca3ec0";

    constructor() public {
        _RGPTokenReceiver = _msgSender();
        _maxBuyableSpins = 5;
        _maxReferralSpins = 5;
        _rewardProjectCounter = 1;
    }

    // Defining a ticker reward inforamtion
    struct TickerInfo {
        address token;
        uint256 rewardAmount;
        uint256 difficulty_numerator;
        uint256 difficulty_denominator;
        string text;
    }

    // Defining a project reward inforamtion
    struct TokenInfo {
        address token;
        uint256 balance;
    }

    // Defining a Project Reward
    struct RewardProject {
        bool status;
        address projOwner;
        uint256 retryCount;
        uint256 retryPeriod;
        uint256 rewardProjectID;
        uint256 claimedCount;
        string description;
    }

    // Defining a User Reward Claim Data
    struct UserClaimData {
        uint8 bSpinAvlb;
        uint8 bSpinUsed;
        uint8 rSpinAvlb;
        uint8 rSpinUsed;
        uint256 time;
        uint256 pSpin;
    }

    // All tickers for a given RewardProject
    mapping(uint256 => TickerInfo[]) public rewardTickers;

    // All rewards for a given RewardProject
    mapping(uint256 => TokenInfo[]) public rewardTokens;

    // Mapping of the ProjectReward and its information
    mapping(uint256 => RewardProject) public rewardProjMapping;

    // Mapping of the project, rewardees and their claim data
    mapping(uint256 => mapping(address => UserClaimData)) public projectClaims;

    // Simply all projectIDs for traversing
    uint256[] public rewardProjects;

    // Event when a Reward Project is created
    event RewardProjectCreate(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is edited by owner
    event RewardProjectEdit(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );
    // Event when a Reward Project is closed by owner
    event RewardProjectClose(
        address indexed projectOwner,
        uint256 indexed projectIndex
    );

    // Event when an user buys spins
    event SpinBought(
        uint256 indexed projectIndex,
        address indexed buyer,
        uint8 indexed count
    );

    // Event when an user earns a spin
    event SpinEarned(
        uint256 indexed projectIndex,
        address indexed linkCreator,
        address indexed linkUser
    );

    modifier onlyProjectOwner(uint256 projectID) {
        RewardProject memory proj = rewardProjMapping[projectID];
        require(
            proj.projOwner == _msgSender(),
            "RigelGift: ProjectOwnerOnly Task"
        );
        _;
    }

    modifier onlyActiveProject(uint256 projectID) {
        RewardProject memory proj = rewardProjMapping[projectID];
        require(proj.status == true, "RigelGift: Reward Project inactive");
        _;
    }

    //create the reward project
    function createRewardProject(
        uint256 retryCount,
        uint256 retryPeriod,
        string calldata description,
        bytes[] calldata rewards,
        bytes[] calldata tickerInfo
    ) external {
        // RGP Tokens must be approved for transfer
        require(
            IERC20(_RGPTokenAddress).transferFrom(
                _msgSender(),
                _RGPTokenReceiver,
                _subscriptionFee
            ),
            "RigelGift: Transfer of subscription fee failed"
        );

        bool status = _setRewards(_rewardProjectCounter, rewards);
        require(status == true, "RigelGift: Set Reward Tokens failed");

        status = _setTickers(_rewardProjectCounter, tickerInfo);
        require(status == true, "RigelGift: Set Reward Ticker failed");

        RewardProject memory rewardProj =
            RewardProject(
                true,
                _msgSender(),
                retryCount,
                retryPeriod,
                _rewardProjectCounter,
                0,
                description
            );
        rewardProjMapping[_rewardProjectCounter] = rewardProj;
        rewardProjects.push(_rewardProjectCounter);

        emit RewardProjectCreate(_msgSender(), _rewardProjectCounter);

        _rewardProjectCounter = _rewardProjectCounter.add(1);
    }

    function _setRewards(uint256 projectID, bytes[] calldata rewards)
        private
        returns (bool status)
    {
        for (uint8 i = 0; i < rewards.length; i++) {
            (address token, uint256 balance) =
                abi.decode(rewards[i], (address, uint256));
            require(token != address(0), "RigelGift: Zero address token");
            // check for token balances ?
            TokenInfo memory t = TokenInfo(token, balance);
            rewardTokens[projectID].push(t);
        }
        return true;
    }

    function _setTickers(uint256 projectID, bytes[] calldata tickerInfo)
        private
        returns (bool status)
    {
        // uint256 length = tickerInfo.length;
        // if(length != 8 || length != 12){
        //     revert("RigelGift: Inadequate ticker length");
        // }

        for (uint8 i = 0; i < tickerInfo.length; i++) {
            (
                address token,
                uint256 amount,
                uint256 numerator,
                uint256 denominator,
                string memory message
            ) =
                abi.decode(
                    tickerInfo[i],
                    (address, uint256, uint256, uint256, string)
                );

            if (token != address(0)) {
                if (numerator == 0 || denominator == 0) {
                    revert(
                        "RigelGift: Incorrect difficulty for non zero address"
                    );
                }
            }

            TickerInfo memory ticker =
                TickerInfo(token, amount, numerator, denominator, message);
            rewardTickers[projectID].push(ticker);
        }
        return true;
    }

    //edit rewards
    function editRewardProject(
        uint256 projectID,
        uint256 retryCount,
        uint256 retryPeriod,
        bytes[] calldata tickerInfo
    ) external onlyProjectOwner(projectID) onlyActiveProject(projectID) {
        RewardProject storage proj = rewardProjMapping[projectID];
        proj.retryCount = retryCount;
        proj.retryPeriod = retryPeriod;
        delete rewardTickers[projectID];
        bool status = _setTickers(projectID, tickerInfo);
        require(status == true, "RigelGift: Set Reward Ticker failed");

        emit RewardProjectEdit(_msgSender(), projectID);
    }

    //withdraw amounts and close project
    function closeProjectWithdrawTokens(uint256 projectID)
        external
        onlyProjectOwner(projectID)
        onlyActiveProject(projectID)
    {
        RewardProject storage proj = rewardProjMapping[projectID];

        //transfer balance reward tokens to project owner
        TokenInfo[] storage rewards = rewardTokens[projectID];
        for (uint8 i = 0; i < rewards.length; i++) {
            TokenInfo storage reward = rewards[i];
            uint256 tempBalance = reward.balance;
            reward.balance = 0;
            IERC20(reward.token).transfer(_msgSender(), tempBalance);
        }

        //set reward project to inactive status
        proj.status = false;

        emit RewardProjectClose(_msgSender(), projectID);
    }

    //claim rewards
    function claimReward(uint256 projectID, uint8 tickerNum)
        public
        onlyActiveProject(projectID)
    {
        RewardProject storage proj = rewardProjMapping[projectID];
        proj.claimedCount = proj.claimedCount.add(1);

        TickerInfo memory ticker = rewardTickers[projectID][tickerNum];

        if (ticker.token == address(0)) {
            setClaimData(projectID);
            return;
        }

        TokenInfo storage chosenReward;
        TokenInfo[] storage rewardInfos = rewardTokens[projectID];
        for (uint8 i = 0; i < rewardInfos.length; i++) {
            if (rewardInfos[i].token == ticker.token) {
                chosenReward = rewardInfos[i];
                break;
            }
        }

        isEligibleForReward(projectID);

        chosenReward.balance = chosenReward.balance.sub(
            ticker.rewardAmount,
            "RigelGift: RewardProject token balance insufficient"
        );

        setClaimData(projectID);

        IERC20(ticker.token).transfer(_msgSender(), ticker.rewardAmount);
    }

    function isEligibleForReward(uint256 projectID)
        public
        view
        onlyActiveProject(projectID)
    {
        RewardProject memory proj = rewardProjMapping[projectID];

        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        if (!(isBoughtSpinsAvlb(claim) || isReferrralSpinsAvlb(claim))) {
            require(
                block.timestamp >= (claim.time + proj.retryPeriod),
                "RigelGift: Claim before retry period"
            );

            require(
                claim.pSpin < proj.retryCount,
                "RigelGift: Address claim limit reached"
            );
        }
    }

    // Checks if any bought spins are available
    function isBoughtSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If BoughtSpins Available and BoughtSpins Used are equal that means they are used up
        if (claim.bSpinAvlb == claim.bSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Checks if any referral spins are available
    function isReferrralSpinsAvlb(UserClaimData memory claim)
        private
        pure
        returns (bool)
    {
        // If RefferalSpins Available and ReferralSpins Used are equal that means they are used up
        if (claim.rSpinAvlb == claim.rSpinUsed) {
            return false;
        } else {
            return true;
        }
    }

    // Captures and updates the claim Data w.r.t all spin types
    function setClaimData(uint256 projectID) private {
        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        if (isBoughtSpinsAvlb(claim)) {
            claim.bSpinUsed = claim.bSpinUsed.add(1);
        } else if (isReferrralSpinsAvlb(claim)) {
            claim.rSpinUsed = claim.rSpinUsed.add(1);
        } else {
            claim.time = now;
            claim.pSpin = claim.pSpin.add(1);
        }

        projectClaims[projectID][_msgSender()] = claim;
    }

    // Set the subscription fee, settable only be the owner
    function setSubscriptionFee(uint256 fee) external onlyOwner {
        _subscriptionFee = fee;
    }

    // Set the buy spin fee, settable only be the owner
    function setPerSpinFee(uint256 fee) external onlyOwner {
        _perSpinFee = fee;
    }

    // Set the RGP receiver address
    function setRGPReveiverAddress(address rgpReceiver) external onlyOwner {
        require(
            rgpReceiver != address(0),
            "RigelGift: RGP Token receiver is zero address"
        );

        _RGPTokenReceiver = rgpReceiver;
    }

    // Set the RGP Token address
    function setRGPTokenAddress(address rgpToken) external onlyOwner {
        _RGPTokenAddress = rgpToken;
    }

    // Set maxbuyable spins per user address, per project
    function setMaxBuyableSpins(uint8 count) external onlyOwner {
        _maxBuyableSpins = count;
    }

    // Allows user to buy specified spins for the specified project
    function buySpin(uint256 projectID, uint8 spinCount)
        external
        onlyActiveProject(projectID)
    {
        UserClaimData memory claim = projectClaims[projectID][_msgSender()];

        // Eligible to buy spins only upto specified limit
        require(
            claim.bSpinAvlb + spinCount <= _maxBuyableSpins,
            "RigelGift: SpinCount beyond specified limit"
        );

        // RGP Tokens must be approved for transfer
        require(
            IERC20(_RGPTokenAddress).transferFrom(
                _msgSender(),
                _RGPTokenReceiver,
                _perSpinFee * spinCount
            ),
            "RigelGift: Buy Spin failed due to transfer error"
        );

        // Update Available spins
        claim.bSpinAvlb = claim.bSpinAvlb.add(spinCount);
        projectClaims[projectID][_msgSender()] = claim;

        emit SpinBought(projectID, _msgSender(), spinCount);
    }

    // Set max referral spins per user address, per project that can be earned
    function setMaxReferralSpins(uint8 count) external onlyOwner {
        _maxReferralSpins = count;
    }

    function claimAndAddReferralSpin(
        uint256 projectID,
        uint8 tickerNum,
        address linkCreator
    ) external onlyActiveProject(projectID) {
        // user claims reward
        claimReward(projectID, tickerNum);

        require(
            linkCreator != _msgSender(),
            "RigelGift: Cannot Use referral link to self"
        );

        if (linkCreator != address(0)) {
            UserClaimData memory claim = projectClaims[projectID][linkCreator];

            // Eligible to earn referral spins only upto specified limit
            if (claim.rSpinAvlb + 1 <= _maxReferralSpins) {
                claim.rSpinAvlb = claim.rSpinAvlb.add(1);
                projectClaims[projectID][linkCreator] = claim;

                emit SpinEarned(projectID, linkCreator, _msgSender());
            }
        }
    }
}