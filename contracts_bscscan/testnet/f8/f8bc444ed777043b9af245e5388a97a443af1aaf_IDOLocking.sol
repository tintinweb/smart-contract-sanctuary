/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

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

pragma solidity 0.5.16;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

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

pragma solidity 0.5.16;

contract IDOLocking is Ownable {
    using SafeMath for uint256;

    /**
     *  @dev Structs to store user staking data.
     */
    struct Deposits {
        uint256 depositAmount;
        uint256 depositTime;
        uint256 endTime;
        uint64 userIndex;
        bool paid;
    }

    /**
     *  @dev Structs to store interest rate change.
     */
    struct Rates {
        uint64 newInterestRate;
        uint256 timeStamp;
    }

    mapping(address => Deposits) private deposits;
    mapping(uint64 => Rates) public rates;
    mapping(address => bool) private hasStaked;

    address public tokenAddress;
    uint256 public stakedBalance;
    uint256 public rewardBalance;
    uint256 public stakedTotal;
    uint256 public totalReward;
    uint64 public index;
    uint64 public rate;
    uint256 public lockDuration;
    string public name;

    IERC20 public ERC20Interface;

    /**
     *  @dev Emitted when user stakes 'stakedAmount' value of tokens
     */
    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 stakedAmount_
    );

    /**
     *  @dev Emitted when user withdraws his stakings
     */
    event PaidOut(
        address indexed token,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    /**
     *   @param
     *   name_ name of the contract
     *   tokenAddress_ contract address of the token
     *   rate_ rate multiplied by 100
     *   lockduration_ duration in days
     */
    constructor(
        string memory name_,
        address tokenAddress_,
        uint64 rate_,
        uint256 lockDuration_
    ) public Ownable() {
        name = name_;
        require(tokenAddress_ != address(0), "Zero token address");
        tokenAddress = tokenAddress_;
        lockDuration = lockDuration_;
        require(rate_ != 0, "Zero interest rate");
        rate = rate_;
        rates[index] = Rates(rate, block.timestamp);
    }

    /**
     *  Requirements:
     *  `rate_` New effective interest rate multiplied by 100
     *  @dev to set interest rates
     */
    function setRate(uint64 rate_) external onlyOwner {
        require(rate_ != 0, "Zero interest rate");
        rate = rate_;
        index++;
        rates[index] = Rates(rate_, block.timestamp);
    }

    /**
     *  Requirements:
     *  `lockduration_' lock days
     *  @dev to set lock duration days
     */
    function changeLockDuration(uint256 lockduration_) external onlyOwner {
        lockDuration = lockduration_;
    }

    /**
     *  Requirements:
     *  `rewardAmount` rewards to be added to the staking contract
     *  @dev to add rewards to the staking contract
     *  once the allowance is given to this contract for 'rewardAmount' by the user
     */
    function addReward(uint256 rewardAmount)
        external
        _hasAllowance(msg.sender, rewardAmount)
        returns (bool)
    {
        require(rewardAmount > 0, "Reward must be positive");
        address from = msg.sender;

        if (!_payMe(from, rewardAmount)) {
            return false;
        }

        totalReward = totalReward.add(rewardAmount);
        rewardBalance = rewardBalance.add(rewardAmount);
        return true;
    }

    /**
     *  Requirements:
     *  `user` User wallet address
     *  @dev returns user staking data
     */
    function userDeposits(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        if (hasStaked[user]) {
            return (
                deposits[user].depositAmount,
                deposits[user].depositTime,
                deposits[user].endTime,
                deposits[user].userIndex,
                deposits[user].paid
            );
        }
    }

    /**
     *  Requirements:
     *  `amount` Amount to be staked
     /**
     *  @dev to stake 'amount' value of tokens 
     *  once the user has given allowance to the staking contract
     */
    function stake(uint256 amount)
        external
        _hasAllowance(msg.sender, amount)
        returns (bool)
    {
        require(amount > 0, "Can't stake 0 amount");
        address from = msg.sender;
        require(!hasStaked[from], "Already Staked");
        return (_stake(from, amount));
    }

    function _stake(address from, uint256 amount) private returns (bool) {
        if (!_payMe(from, amount)) {
            return false;
        }

        hasStaked[from] = true;

        deposits[from] = Deposits(
            amount,
            block.timestamp,
            block.timestamp.add((lockDuration.mul(86400))), //lockDuration * 24 * 3600
            index,
            false
        );

        emit Staked(tokenAddress, from, amount);

        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        return true;
    }

    /**
     * @dev to withdraw user stakings after the lock period ends.
     */
    function withdraw() external returns (bool) {
        address from = msg.sender;
        require(hasStaked[from], "No stakes found for user");
        require(
            block.timestamp >= deposits[from].endTime,
            "Requesting before lock time"
        );
        require(!deposits[from].paid, "Already paid out");
        return (_withdraw(from));
    }

    function _withdraw(address from) private returns (bool) {
        uint256 payOut = _calculate(from);
        uint256 amount = deposits[from].depositAmount;
        uint256 reward = payOut.sub(amount);
        require(reward <= rewardBalance, "Not enough rewards");

        stakedBalance = stakedBalance.sub(amount);
        rewardBalance = rewardBalance.sub(reward);
        deposits[from].paid = true;
        hasStaked[from] = false;

        if (_payDirect(from, payOut)) {
            emit PaidOut(tokenAddress, from, amount, reward);
            return true;
        }
        return false;
    }

    function emergencyWithdraw() external returns (bool) {
        address from = msg.sender;
        require(hasStaked[from], "No stakes found for user");
        require(
            block.timestamp >= deposits[from].endTime,
            "Requesting before lock time"
        );
        require(!deposits[from].paid, "Already paid out");

        return (_emergencyWithdraw(from));
    }

    function _emergencyWithdraw(address from) private returns (bool) {
        uint256 amount = deposits[from].depositAmount;
        stakedBalance = stakedBalance.sub(amount);
        deposits[from].paid = true;
        hasStaked[from] = false; //Check-Effects-Interactions pattern

        bool principalPaid = _payDirect(from, amount);
        require(principalPaid, "Error paying");
        emit PaidOut(tokenAddress, from, amount, 0);

        return true;
    }

    /**
     *  Requirements:
     *  `from` User wallet address
     * @dev to calculate the rewards based on user staked 'amount'
     * 'userIndex' - the index of the interest rate at the time of user stake.
     * 'depositTime' - time of staking
     */
    function calculate(address from) external view returns (uint256) {
        return _calculate(from);
    }

    function _calculate(address from) private view returns (uint256) {
        if (!hasStaked[from]) return 0;
        (
            uint256 amount,
            uint256 depositTime,
            uint256 endTime,
            uint64 userIndex
        ) =
            (
                deposits[from].depositAmount,
                deposits[from].depositTime,
                deposits[from].endTime,
                deposits[from].userIndex
            );

        uint256 time;
        uint256 interest;
        uint256 _lockduration = endTime.sub(depositTime);
        for (uint64 i = userIndex; i < index; i++) {
            //loop runs till the latest index/interest rate change
            if (endTime < rates[i + 1].timeStamp) {
                //if the change occurs after the endTime loop breaks
                break;
            } else {
                time = rates[i + 1].timeStamp.sub(depositTime);
                interest = amount.mul(rates[i].newInterestRate).mul(time).div(
                    _lockduration.mul(10000)
                ); //replace with (_lockduration * 10000)
                amount += interest;
                depositTime = rates[i + 1].timeStamp;
                userIndex++;
            }
        }

        if (depositTime < endTime) {
            //final calculation for the remaining time period
            time = endTime.sub(depositTime);

            interest = time
                .mul(amount)
                .mul(rates[userIndex].newInterestRate)
                .div(_lockduration.mul(10000)); //replace with (lockduration * 10000)

            amount += interest;
        }

        return (amount);
    }

    function _payMe(address payer, uint256 amount) private returns (bool) {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount
    ) private _hasAllowance(allower, amount) returns (bool) {
        ERC20Interface = IERC20(tokenAddress);
        return ERC20Interface.transferFrom(allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount) private returns (bool) {
        ERC20Interface = IERC20(tokenAddress);
        return ERC20Interface.transfer(to, amount);
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = IERC20(tokenAddress);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}