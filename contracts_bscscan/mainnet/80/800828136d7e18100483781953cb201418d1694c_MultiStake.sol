/**
 *Submitted for verification at BscScan.com on 2021-11-29
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

contract MultiStake is Ownable {
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

    mapping(address => mapping(address => Deposits)) private deposits;
    mapping(uint64 => Rates) public rates;
    mapping(address => mapping(address => bool)) private hasStaked;
    mapping(address => uint256) public userCap;
    mapping(address => uint256) public poolCap;
    mapping(address => uint256) public payOut;

    address public tokenAddressA;
    address public tokenAddressB;
    uint256 public rewardBalanceA;
    uint256 public rewardBalanceB;
    uint256 public stakedTotalA;
    uint256 public stakedTotalB;
    uint256 public stakedCapA;
    uint256 public stakedCapB;
    uint256 public totalRewardA;
    uint256 public totalRewardB;
    uint64 public index;
    uint64 public rate;
    uint256 public conversionAtoB; //tolerance factor = 10**6
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
     *   tokenAddressA_ contract address of the token A
     *   tokenAddressB_ contract address of the token B
     *   conversionAtoB_ tokenA to tokenB conversion multiplied by 10**6
     *   rate_ Effective interest rate for the pool multiplied by 100
     *   lockDuration_ lock duration of the pool in days
     *   stakedCapA_ Cap amount for token A in the pool
     *   stakedCapB_ Cap amount for token B in the pool
     *   payOutA_ payOut ratio for token A
     *   payOutB_ payOut ratio for token B
     */
    constructor(
        string memory name_,
        address tokenAddressA_,
        address tokenAddressB_,
        uint256 conversionAtoB_,
        uint64 rate_,
        uint256 lockDuration_,
        uint256 stakedCapA_,
        uint256 stakedCapB_,
        uint256 payOutA_,
        uint256 payOutB_
    ) public Ownable() {
        name = name_;
        require(tokenAddressA_ != address(0), "Zero token A address");
        tokenAddressA = tokenAddressA_;
        require(tokenAddressB_ != address(0), "Zero token B address");
        tokenAddressB = tokenAddressB_;
        require(conversionAtoB_ > 0, "Zero conversion rate A to B");
        conversionAtoB = conversionAtoB_;
        require(lockDuration_ > 0, "Zero lock days");
        lockDuration = lockDuration_;
        require(rate_ != 0, "Zero interest rate");
        rate = rate_;
        rates[index] = Rates(rate, block.timestamp);
        require(stakedCapA_ > 0, "Zero cap amount for token A");
        poolCap[tokenAddressA] = stakedCapA_;
        require(stakedCapB_ > 0, "Zero cap amount for token B");
        poolCap[tokenAddressB] = stakedCapB_;
        require(payOutA_ != 0, "Zero Payout ratio of token A");
        payOut[tokenAddressA] = payOutA_;
        require(payOutB_ != 0, "Zero Payout ratio of token B");
        payOut[tokenAddressB] = payOutB_;
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

    function changeLockDuration(uint256 lockduration_) external onlyOwner {
        lockDuration = lockduration_;
    }

    /**
     *  Requirements:
     *  `tokenAddress_` token address to set user cap
     *  `amount_` user cap for token address
     *  @dev to set interest rates
     */
    function setUserCap(address tokenAddress_, uint256 amount_)
        external
        onlyOwner
    {
        require(
            tokenAddress_ == tokenAddressA || tokenAddress_ == tokenAddressB,
            "Wrong token address for the pool"
        );
        userCap[tokenAddress_] = amount_;
    }

    /**
     *  Requirements:
     *  `payOutA_` Ratio of reward payout for token A
     *  `payOutB_` Ratio of reward payout for token B
     *  @dev to set interest rates
     */
    function setPayout(uint256 payOutA_, uint256 payOutB_) external onlyOwner {
        payOut[tokenAddressA] = payOutA_;
        payOut[tokenAddressB] = payOutB_;
    }

    function stakedTotal(address token) external view returns (uint256) {
        if (token == tokenAddressA) return stakedTotalA;
        if (token == tokenAddressB) return stakedTotalB;
    }

    /**
     *  Requirements:
     *  `rewardAmount` rewards to be added to the staking contract
     *  @dev to add rewards to the staking contract
     *  once the allowance is given to this contract for 'rewardAmount' by the user
     */
    function addReward(uint256 rewardAmount, address tokenAddress)
        external
        _validTokenAddress(tokenAddress)
        _hasAllowance(msg.sender, rewardAmount, tokenAddress)
        returns (bool)
    {
        require(rewardAmount > 0, "Reward must be positive");
        address from = msg.sender;

        if (!_payMe(from, rewardAmount, tokenAddress)) {
            return false;
        }

        if (tokenAddress == tokenAddressA) {
            totalRewardA = totalRewardA.add(rewardAmount);
            rewardBalanceA = rewardBalanceA.add(rewardAmount);
        } else {
            totalRewardB = totalRewardB.add(rewardAmount);
            rewardBalanceB = rewardBalanceB.add(rewardAmount);
        }

        return true;
    }

    /**
     *  Requirements:
     *  `user` User wallet address
     *  @dev returns user staking data
     */
    function userDeposits(address user, address tokenAddress)
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
        if (hasStaked[user][tokenAddress]) {
            return (
                deposits[user][tokenAddress].depositAmount,
                deposits[user][tokenAddress].depositTime,
                deposits[user][tokenAddress].endTime,
                deposits[user][tokenAddress].userIndex,
                deposits[user][tokenAddress].paid
            );
        }
    }

    function stakeBoth(uint256 amountA, uint256 amountB)
        external
        returns (bool)
    {
        //extra checks before execution;
        address from = msg.sender;
        require(!hasStaked[from][tokenAddressA], "Already Staked Token A");
        require(!hasStaked[from][tokenAddressB], "Already Staked Token B");
        bool stakeA = stake(amountA, tokenAddressA);
        require(stakeA, "Staking token A failed");
        bool stakeB = stake(amountB, tokenAddressB);
        require(stakeB, "Staking token B failed");
        return true;
    }

    /**
     *  Requirements:
     *  `amount` Amount to be staked
     *  `tokenAddress` Token address to stake
     /**
     *  @dev to stake 'amount' value of tokens 
     *  once the user has given allowance to the staking contract
     */
    function stake(uint256 amount, address tokenAddress)
        public
        _validTokenAddress(tokenAddress)
        _hasAllowance(msg.sender, amount, tokenAddress)
        returns (bool)
    {
        require(amount > 0, "Can't stake 0 amount");
        require(
            amount <= userCap[tokenAddress],
            "Amount is greater than limit"
        );
        uint256 poolRemaining;
        if (tokenAddress == tokenAddressA) {
            poolRemaining = poolCap[tokenAddress].sub(stakedTotalA);
        } else {
            poolRemaining = poolCap[tokenAddress].sub(stakedTotalB);
        }
        require(poolRemaining > 0, "Pool limit reached");
        if (amount > poolRemaining) {
            amount = poolRemaining;
        }
        address from = msg.sender;
        require(!hasStaked[from][tokenAddress], "Already Staked");
        return (_stake(from, amount, tokenAddress));
    }

    function _stake(
        address from,
        uint256 amount,
        address token
    ) private returns (bool) {
        if (!_payMe(from, amount, token)) {
            return false;
        }

        hasStaked[from][token] = true;

        deposits[from][token] = Deposits(
            amount,
            block.timestamp,
            block.timestamp.add((lockDuration.mul(86400))), //lockDuration * 24 * 3600
            index,
            false
        );

        emit Staked(token, from, amount);

        if (token == tokenAddressA) {
            stakedTotalA = stakedTotalA.add(amount);
        } else {
            stakedTotalB = stakedTotalB.add(amount);
        }
        return true;
    }

    function emergencyWithdrawBoth() external returns (bool) {
        //extra checks before executing;
        address from = msg.sender;
        require(
            block.timestamp >= deposits[from][tokenAddressA].endTime,
            "Requesting before lock time token A"
        );
        require(
            block.timestamp >= deposits[from][tokenAddressB].endTime,
            "Requesting before lock time token B"
        );
        bool withdrawA = emergencyWithdraw(tokenAddressA);
        require(withdrawA, "Error paying token A");
        bool withdrawB = emergencyWithdraw(tokenAddressB);
        require(withdrawB, "Error paying token B");
        return true;
    }

    function emergencyWithdraw(address token) public returns (bool) {
        address from = msg.sender;
        require(hasStaked[from][token], "No stakes found for user");
        require(
            block.timestamp >= deposits[from][token].endTime,
            "Requesting before lock time"
        );
        require(!deposits[from][token].paid, "Already paid out");

        return (_emergencyWithdraw(from, token));
    }

    function _emergencyWithdraw(address from, address token)
        private
        returns (bool)
    {
        uint256 amount = deposits[from][token].depositAmount;
        deposits[from][token].paid = true;
        hasStaked[from][token] = false; //Check-Effects-Interactions pattern

        bool principalPaid = _payDirect(from, amount, token);
        require(principalPaid, "Error paying");
        emit PaidOut(token, from, amount, 0);

        return true;
    }

    function withdrawBoth() external returns (bool) {
        //extra checks before executing;
        address from = msg.sender;
        require(
            block.timestamp >= deposits[from][tokenAddressA].endTime,
            "Requesting before lock time token A"
        );
        require(
            block.timestamp >= deposits[from][tokenAddressB].endTime,
            "Requesting before lock time token B"
        );
        bool withdrawA = withdraw(tokenAddressA);
        require(withdrawA, "Error paying token A");
        bool withdrawB = withdraw(tokenAddressB);
        require(withdrawB, "Error paying token B");
        return true;
    }

    function withdraw(address token)
        public
        _validTokenAddress(token)
        returns (bool)
    {
        address from = msg.sender;
        require(hasStaked[from][token], "No stakes found for user");
        require(
            block.timestamp >= deposits[from][token].endTime,
            "Requesting before lock time"
        );
        require(!deposits[from][token].paid, "Already paid out");

        return (_withdraw(from, token));
    }

    function _withdraw(address from, address token) private returns (bool) {
        (uint256 rewardA, uint256 rewardB) = _calculate(from, token);
        require(
            rewardA <= rewardBalanceA && rewardB <= rewardBalanceB,
            "Not enough rewards"
        );

        bool paidA = _payDirect(from, rewardA, tokenAddressA);
        require(paidA, "Error paying rewards of token A");

        bool paidB = _payDirect(from, rewardB, tokenAddressB);
        require(paidB, "Error paying rewards of token B");

        bool paidAmount = _emergencyWithdraw(from, token);
        require(paidAmount, "Error paying deposit amount");

        return true;
    }

    function calculate(address from, address token)
        external
        view
        returns (uint256, uint256)
    {
        return _calculate(from, token);
    }

    function _calculate(address from, address token)
        private
        view
        returns (uint256, uint256)
    {
        if (!hasStaked[from][token]) return (0, 0);
        (
            uint256 amount,
            uint256 depositTime,
            uint256 endTime,
            uint64 userIndex
        ) = (
            deposits[from][token].depositAmount,
            deposits[from][token].depositTime,
            deposits[from][token].endTime,
            deposits[from][token].userIndex
        );

        uint256 amount1 = amount;
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
                );
                if (token == tokenAddressA) {
                    uint256 test = payOut[tokenAddressA].mul(10000).div(
                        payOut[tokenAddressA].add(payOut[tokenAddressB])
                    );
                    interest = interest.mul(test).div(10000);
                } else {
                    uint256 test = payOut[tokenAddressB].mul(10000).div(
                        payOut[tokenAddressA].add(payOut[tokenAddressB])
                    );
                    interest = interest.mul(test).div(10000);
                }
                amount = amount.add(interest);
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
            .div(_lockduration.mul(10000));

            if (token == tokenAddressA) {
                uint256 test = payOut[tokenAddressA].mul(10000).div(
                    payOut[tokenAddressA].add(payOut[tokenAddressB])
                );
                interest = interest.mul(test).div(10000);
            } else {
                uint256 test = payOut[tokenAddressB].mul(10000).div(
                    payOut[tokenAddressA].add(payOut[tokenAddressB])
                );
                interest = interest.mul(test).div(10000);
            }
            amount = amount.add(interest);
        }

        uint256 rewardA;
        uint256 rewardB;

        if (token == tokenAddressA) {
            rewardA = amount.sub(amount1);
            uint256 test = payOut[tokenAddressB].mul(1000000).div(
                payOut[tokenAddressA]
            );
            rewardB = rewardA.mul(conversionAtoB).mul(test).div(10**12);
        } else {
            rewardB = amount.sub(amount1);
            uint256 test = payOut[tokenAddressA].mul(1000000).div(
                payOut[tokenAddressB]
            );
            rewardA = rewardB.mul(10**6).mul(test).div(conversionAtoB).div(
                1000000
            );
        }

        return (rewardA, rewardB);
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
        return ERC20Interface.transferFrom(allower, receiver, amount);
    }

    function _payDirect(
        address to,
        uint256 amount,
        address token
    ) private returns (bool) {
        ERC20Interface = IERC20(token);
        return ERC20Interface.transfer(to, amount);
    }

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    modifier _validTokenAddress(address token) {
        require(
            token == tokenAddressA || token == tokenAddressB,
            "Invalid token address"
        );
        _;
    }
}