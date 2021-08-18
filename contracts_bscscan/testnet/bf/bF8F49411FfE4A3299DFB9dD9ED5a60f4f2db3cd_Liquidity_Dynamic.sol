/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// Liquidity contract with pegged value
pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.5.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity 0.5.16;

contract Context {
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity 0.5.16;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

pragma solidity 0.5.16;

contract Liquidity_Dynamic is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) private hasStaked;
    mapping(address => uint256) private depositAmount;

    string public name;
    address public tokenAddress;
    address public rewardTokenAddress;
    uint256 public stakedTotal;
    uint256 public totalReward;
    uint256 public rewardBalance;
    uint256 public stakedBalance;
    uint256 public lockDuration;
    uint256 public totalParticipants;
    uint256 public stakingStart;
    uint256 public stakingEnd;
    uint256 public withdrawStart;

    IERC20 public ERC20Interface;

    /**
     * @dev Emitted when user stakes 'stakedAmount' value of tokens
     */
    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 stakedAmount_
    );

    /**
     * @dev Emitted when user withdraws his stakings
     */
    event PaidOut(
        address indexed token,
        address indexed rewardToken,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    /**
     *   @param
     *   name_ name of the contract
     *   tokenAddress_ contract address of the token
     *   rewardTokenAddress_ contract address of the reward token
     *   lockduration_ duration in days
     */
    constructor(
        string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint256 lockDuration_,
        uint256 stakingStart_,
        uint256 stakingEnd_
    ) public Ownable() {
        name = name_;
        require(tokenAddress_ != address(0), "Token address: 0 address");
        tokenAddress = tokenAddress_;
        require(
            rewardTokenAddress_ != address(0),
            "Reward token address: 0 address"
        );
        rewardTokenAddress = rewardTokenAddress_;
        lockDuration = lockDuration_;
        require(stakingStart_ > block.timestamp && stakingEnd_ > stakingStart_, "Invalid block periods");
        stakingStart = stakingStart_;
        stakingEnd = stakingEnd_;
        withdrawStart = stakingEnd.add(lockDuration.mul(3600));
    }

    /**
     * @dev to add rewards to the staking contract
     * once the allowance is given to this contract for 'rewardAmount' by the user
     */
    function addReward(uint256 rewardAmount)
        external
        _hasAllowance(msg.sender, rewardAmount, rewardTokenAddress)
        returns (bool)
    {
        require(block.timestamp < withdrawStart, "Period ended");
        require(rewardAmount > 0, "Reward must be positive");

        if (!_payMe(msg.sender, rewardAmount, rewardTokenAddress)) {
            return false;
        }
        totalReward = totalReward.add(rewardAmount);
        rewardBalance = rewardBalance.add(rewardAmount);
        return true;
    }

    /**
     * @dev returns user staking data
     */
    function userDeposits(address user) external view returns (uint256) {
        if (hasStaked[user]) {
            return (depositAmount[user]);
        }
    }

    /**
     * Requirements:
     * - 'amount' Amount to be staked
     /**
     * @dev to stake 'amount' value of tokens 
     * once the user has given allowance to the staking contract
     */
    function stake(uint256 amount)
        external
        _realAddress(msg.sender)
        _hasAllowance(msg.sender, amount, tokenAddress)
        returns (bool)
    {
        require(amount > 0, "Can't stake 0 amount");
        require(block.timestamp >= stakingStart, "Staking period yet to start");
        require(block.timestamp < stakingEnd, "Staking period closed");
        return _stake(msg.sender, amount);
    }

    function _stake(address staker, uint256 amount) private returns (bool) {
        if (hasStaked[staker]) {
            if (!_payMe(staker, amount, tokenAddress)) {
                return false;
            }
            depositAmount[staker] = depositAmount[staker].add(amount);
        } else {
            if (!_payMe(staker, amount, tokenAddress)) {
                return false;
            }
            hasStaked[staker] = true;
            depositAmount[staker] = amount;
            totalParticipants = totalParticipants.add(1);
        }

        // Transfer is completed
        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        emit Staked(tokenAddress, staker, amount);

        return true;
    }

    /**
     * @dev to withdraw user stakings after the lock period ends.
     */
    function withdraw() external _realAddress(msg.sender) returns (bool) {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(
            block.timestamp >= withdrawStart,
            "Requesting before lock time"
        );
        return (_withdraw(msg.sender));
    }

    function _withdraw(address from) private returns (bool) {
        uint256 reward = _calculate(from);
        uint256 amount = depositAmount[from];
        require(reward <= rewardBalance, "Not enough rewards");

        stakedBalance = stakedBalance.sub(amount);
        rewardBalance = rewardBalance.sub(reward);
        hasStaked[from] = false; //Check-Effects-Interactions pattern
        totalParticipants = totalParticipants.sub(1);

        bool principalPaid = _payDirect(from, amount, tokenAddress);
        bool rewardPaid = _payDirect(from, reward, rewardTokenAddress);
        require(principalPaid && rewardPaid, "Error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, reward);

        return true;
    }

    function emergencyWithdraw()
        external
        _realAddress(msg.sender)
        returns (bool)
    {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(
            block.timestamp >= withdrawStart,
            "Requesting before lock time"
        );

        return (_emergencyWithdraw(msg.sender));
    }

    function _emergencyWithdraw(address from) private returns (bool) {
        uint256 amount = depositAmount[from];
        stakedBalance = stakedBalance.sub(amount);
        hasStaked[from] = false; //Check-Effects-Interactions pattern
        totalParticipants = totalParticipants.sub(1);

        bool principalPaid = _payDirect(from, amount, tokenAddress);
        require(principalPaid, "Error paying");
        emit PaidOut(tokenAddress, address(0), from, amount, 0);

        return true;
    }

    /**
     * @param
     * from user wallet address
     * @dev to calculate the rewards based on user staked 'amount'
     */
    function calculate(address from) external view returns (uint256) {
        return _calculate(from);
    }

    function _calculate(address from) private view returns (uint256) {
        if (!hasStaked[from] || block.timestamp < stakingEnd) return 0;
        require(totalReward > 0, "No rewards added to the pool");
        uint256 amount = depositAmount[from];
        uint256 reward = amount.mul(totalReward).div(stakedTotal);
        return reward;
    }

    function _payMe(
        address payer,
        uint256 amount,
        address token
    ) private returns (bool) {
        return _payTo(payer, address(this), amount, token);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount,
        address token
    ) private _hasAllowance(allower, amount, token) returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    function _payDirect(
        address to,
        uint256 amount,
        address token
    ) private returns (bool) {
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransfer(to, amount);
        return true;
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}