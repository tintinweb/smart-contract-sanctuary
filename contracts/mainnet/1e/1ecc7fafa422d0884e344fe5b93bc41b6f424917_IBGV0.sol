// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./upgradeability/CustomOwnable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/UserLibrary.sol";
import "./libraries/IBGLibrary.sol";
import "./libraries/InvestmentLibrary.sol";
import "./interfaces/IIBGEvents.sol";

contract IBGV0 is IIBGEvents, CustomOwnable, ReentrancyGuard {
    using SafeMath for uint;
    using UserLibrary for UserLibrary.User;
    using IBGLibrary for IBGLibrary.IBGPlan;
    using InvestmentLibrary for InvestmentLibrary.Investment;

    IERC20 public usdt;
    IERC20 ibg;
    IERC20 bgbf;
    address rootNode;

    mapping(address => UserLibrary.User) public users;
    mapping(address => IBGLibrary.IBGPlan) public IBGPlanDetails;
    mapping(address => mapping(uint => InvestmentLibrary.Investment)) public cycleDetails;

    bool internal _initialized;

    uint public constant SERVICE_START_TIME = 1619521871;

    uint private constant DECIMAL_FACTOR = 10**6;
    uint private constant DECIMAL_FACTOR_IBG = 10**18;
    uint private constant SECONDS_IN_DAY = 86400;
    uint private constant IBG_TO_USDT = 1 * DECIMAL_FACTOR_IBG;

    uint private constant MAX_PACKS = 6;
    uint private constant MAX_PLANS = 3;

    uint private constant IBG_PERCENTAGE = 20;
    uint private constant BGBF_PERCENTAGE = 10;
    uint private constant MAX_CURRENT_PLAN = DECIMAL_FACTOR_IBG ** 2;

    uint private constant MAX_ELIGIBLE_REFERRER_WALKS = 25;

    uint ibgPercentage;
    uint bgbfPercentage;
    uint maxPacks;
    uint maxPlans;
    uint public maxWalks;
    uint public IBGToUsdt;
    uint public increaseIBGAfterLimit;
    uint public increaseRateIBG;
    uint public totalIBGDistributed;
    address treasuryWallet;
    address directCommissionWallet;
    address yieldMatchingWallet;
    address yieldWallet;

    uint lastRate;

    mapping(uint => string) public plans;
    mapping(uint => bool) public planActiveStatus;
    mapping(uint => uint) public packPrice;
    mapping(uint => uint) public stakingTime;
    mapping(uint => uint) public yieldRate;
    mapping(uint => uint) public directReferralRate;
    mapping(uint => uint) public yieldMatchingRate;

    modifier onlyBeforeLaunch() {
        require(block.timestamp < SERVICE_START_TIME, "IBGV0: Service Expired");
        _;
    }

    function initialize(address _governance, address _ibg, address _usdt, address _treasuryWallet) external {
        require(!_initialized, 'IBGV0: INVALID');
        _initialized = true;
        _setOwner(_governance);
        usdt = IERC20(_usdt);
        ibg = IERC20(_ibg);
        rootNode = _treasuryWallet;
        treasuryWallet = _treasuryWallet;
        directCommissionWallet = _treasuryWallet;
        yieldMatchingWallet = _treasuryWallet;
        yieldWallet = _treasuryWallet;


        users[rootNode].investmentCount = 1;

        ibgPercentage = IBG_PERCENTAGE;
        bgbfPercentage = BGBF_PERCENTAGE;

        IBGToUsdt = IBG_TO_USDT;
        increaseRateIBG = 10 * 10**16;
        increaseIBGAfterLimit = 100000 * DECIMAL_FACTOR_IBG;
        maxPacks = MAX_PACKS;
        maxPlans = MAX_PLANS;
        maxWalks = MAX_ELIGIBLE_REFERRER_WALKS;

        directReferralRate[1] = 40;
        directReferralRate[2] = 30;
        directReferralRate[3] = 20;

        plans[1] = "IBG";
        plans[2] = "BGBF";
        plans[3] = "BLENDED";

        planActiveStatus[1] = true;

        packPrice[1] = 100 * DECIMAL_FACTOR;
        packPrice[2] = 1000 * DECIMAL_FACTOR;
        packPrice[3] = 5000 * DECIMAL_FACTOR;
        packPrice[4] = 10000 * DECIMAL_FACTOR;
        packPrice[5] = 50000 * DECIMAL_FACTOR;
        packPrice[6] = 100000 * DECIMAL_FACTOR;

        stakingTime[1] = 30;
        stakingTime[2] = 60;
        stakingTime[3] = 90;

        yieldRate[stakingTime[1]] = 5;
        yieldRate[stakingTime[2]] = 6;
        yieldRate[stakingTime[3]] = 7;

        yieldMatchingRate[1] = 30;
        yieldMatchingRate[2] = 20;
        yieldMatchingRate[3] = 10;
        yieldMatchingRate[4] = 10;
        yieldMatchingRate[5] = 10;

        users[rootNode].currentPlan = MAX_CURRENT_PLAN;

        emit Registration(rootNode, address(0), block.timestamp);
    }

    function setPackagePercentage(uint _value, uint plan) public onlyOwner {
        require(_value > 0 && _value <= 100, "IBGV0: Invalid percentage");
        if(plan == 1) {
            ibgPercentage = _value;
        } else if(plan == 2) {
            bgbfPercentage = _value;
        }
    }

    function registerAdmin(address _user, address _referrer, uint _pack, uint _plan, uint stakingPeriod) external virtual onlyOwner onlyBeforeLaunch nonReentrant {
        _register(_user, _referrer, _pack, _plan, stakingPeriod, true);
    }

    function register(address _referrer, uint _pack, uint _plan, uint stakingPeriod) external virtual nonReentrant {
        _register(msg.sender, _referrer, _pack, _plan, stakingPeriod, false);
    }

    function _register(address _user, address _referrer, uint _pack, uint _plan, uint stakingPeriod, bool isAdmin) private {
        require(_pack >= 1 && _pack <= maxPacks, 'IBGV0: Invalid Pack');
        require(_plan >= 1 && _plan <= maxPlans, 'IBGV0: Invalid Plan');
        require(planActiveStatus[_plan], 'IBGV0: Plan is not active yet');
        require(stakingPeriod >= 1 && stakingPeriod <= 3, 'IBGV0: Invalid staking period');
        require(!users[_user].exists(), 'IBGV0: User_Exists');
        require(users[_referrer].exists(), 'IBGV0: Referrer does not exists');

        uint value = packPrice[_pack];

        if (!isAdmin) {
            TransferHelper.safeTransferFrom(address(usdt), _user, address(this), value);
        }

        users[_user].referrer = _referrer;
        users[_referrer].referralCount++;

        emit Registration(_user, _referrer, block.timestamp);

        _investment(_user, _pack, _plan, value, stakingPeriod, isAdmin);
    }

    function investmentAdmin(address _user, uint _pack, uint _plan, uint stakingPeriod) external virtual onlyOwner onlyBeforeLaunch nonReentrant {
        require(_pack >= 1 && _pack <= maxPacks, 'IBGV0: Invalid Pack');
        require(_plan >= 1 && _plan <= maxPlans, 'IBGV0: Invalid Plan');
        require(planActiveStatus[_plan], 'IBGV0: Plan is not active yet');
        require(stakingPeriod >= 1 && stakingPeriod <= 3, 'IBGV0: Invalid staking period');
        require(users[_user].exists(), "IBGV0: User not registered yet");

        _investment(_user, _pack, _plan, packPrice[_pack], stakingPeriod, true);
    }

    function investment(uint _pack, uint _plan, uint stakingPeriod) external virtual nonReentrant {
        require(_pack >= 1 && _pack <= maxPacks, 'IBGV0: Invalid Pack');
        require(_plan >= 1 && _plan <= maxPlans, 'IBGV0: Invalid Plan');
        require(planActiveStatus[_plan], 'IBGV0: Plan is not active yet');
        require(stakingPeriod >= 1 && stakingPeriod <= 3, 'IBGV0: Invalid staking period');
        require(users[msg.sender].exists(), "IBGV0: User not registered yet");

        uint value = packPrice[_pack];
        TransferHelper.safeTransferFrom(address(usdt), msg.sender, address(this), value);
        _investment(msg.sender, _pack, _plan, value, stakingPeriod, false);
    }

    function _investment(address _user, uint _pack, uint _plan, uint currentPackAmount, uint stakingPeriod, bool isAdmin) private {
        users[_user].investmentCount++;
        users[_user].currentPlan = users[_user].currentPlan.add(currentPackAmount);

        InvestmentLibrary.Investment storage cycle = cycleDetails[_user][users[_user].investmentCount];
        cycle.investmentTime = block.timestamp;
        cycle.plan = _plan;
        cycle.stakingPeriod = stakingTime[stakingPeriod];
        cycle.yieldRateValue = yieldRate[stakingTime[stakingPeriod]];
        if(_plan == 1) {
            uint iBGAmount = (currentPackAmount.mul(DECIMAL_FACTOR_IBG)).div(DECIMAL_FACTOR);

            if (!isAdmin) {
                iBGAmount = ((iBGAmount).mul(DECIMAL_FACTOR_IBG)).div(IBGToUsdt);
                TransferHelper.safeTransfer(address(usdt), treasuryWallet, currentPackAmount.mul((uint(100)).sub(ibgPercentage)).div(100));
            }

            cycle.investment = iBGAmount;
            totalIBGDistributed = totalIBGDistributed.add(iBGAmount);
            IBGPlanDetails[_user].IBGTokens = IBGPlanDetails[_user].IBGTokens.add(iBGAmount);
            IBGPlanDetails[_user].stakedIBGTokens = IBGPlanDetails[_user].stakedIBGTokens.add(iBGAmount);

            emit StakedToken(_user, iBGAmount, _plan, block.timestamp, stakingPeriod);

            calculateIBGTokenPrice();

            if (!isAdmin) {
                commisionTransfer(_user, users[_user].referrer, currentPackAmount, (currentPackAmount.mul(ibgPercentage).div(100)), ibgPercentage);
            }
        }

        emit PackPurchased(_user, _pack, _plan, currentPackAmount, block.timestamp);
    }

    function iBGYieldCommission(address user, address reciever, uint currentPlan, uint yieldDistributionAmount) private {
        uint level = 1;
        TransferHelper.safeTransfer(address(ibg), yieldMatchingWallet, (yieldDistributionAmount.mul(20)).div(100));

        while(level <= 5) {
            uint amount = (yieldDistributionAmount.mul(yieldMatchingRate[level]).div(100));
            if(reciever == address(0)) {
                TransferHelper.safeTransfer(address(ibg), rootNode, amount);
                IBGPlanDetails[rootNode].IBGYieldMatchingIncome = IBGPlanDetails[rootNode].IBGYieldMatchingIncome.add(amount);

                emit YieldMatchingIncome(user, rootNode, amount, level, block.timestamp);
            } else {
                if(users[reciever].currentPlan >= currentPlan) {
                    TransferHelper.safeTransfer(address(ibg), reciever, amount);
                    IBGPlanDetails[reciever].IBGYieldMatchingIncome = IBGPlanDetails[reciever].IBGYieldMatchingIncome.add(amount);

                    emit YieldMatchingIncome(user, reciever, amount, level, block.timestamp);
                }
                else {
                    uint newAmount = ((amount).mul(users[reciever].currentPlan).div(currentPlan));
                    TransferHelper.safeTransfer(address(ibg), reciever, newAmount);
                    IBGPlanDetails[reciever].IBGYieldMatchingIncome = IBGPlanDetails[reciever].IBGYieldMatchingIncome.add(newAmount);

                    emit YieldMatchingIncome(user, reciever, newAmount, level, block.timestamp);

                    uint lostIncome = amount.sub(newAmount);
                    IBGPlanDetails[reciever].IBGYieldMatchingLostIncome = IBGPlanDetails[reciever].IBGYieldMatchingLostIncome.add(lostIncome);

                    address eligibleUser = getEligibleReceiver(users[reciever].referrer, users[user].currentPlan);
                    TransferHelper.safeTransfer(address(ibg), eligibleUser, lostIncome);
                    IBGPlanDetails[eligibleUser].IBGYieldMatchingIncome = IBGPlanDetails[eligibleUser].IBGYieldMatchingIncome.add(lostIncome);

                    emit YieldMatchingLostIncome(reciever, eligibleUser, lostIncome, level, block.timestamp);
                    emit YieldMatchingIncome(user, eligibleUser, lostIncome, level, block.timestamp);
                }
            }

            reciever = users[reciever].referrer;
            level++;
        }
    }

    function commisionTransfer(address _from, address _receiver, uint currentPlan, uint distributeAmount, uint _basePercentage) private {
        TransferHelper.safeTransfer(address(usdt), directCommissionWallet, (distributeAmount.mul(10)).div(100));
        uint level = 1;
        while(level <= 3) {
            uint amount;
            amount = ((distributeAmount).mul(directReferralRate[level])).div(100);
            if(_receiver == address(0)) {
                TransferHelper.safeTransfer(address(usdt), rootNode, amount);
                users[rootNode].directReferrerIncome = users[rootNode].directReferrerIncome.add(amount);
                emit DirectReferralIncome(_from, rootNode, amount, level, block.timestamp);
            } else {
                if(users[_receiver].currentPlan >= currentPlan) {
                    TransferHelper.safeTransfer(address(usdt), _receiver, amount);
                    users[_receiver].directReferrerIncome = users[_receiver].directReferrerIncome.add(amount);
                    emit DirectReferralIncome(_from, _receiver, amount, level, block.timestamp);
                } else {
                    uint newAmount = (((users[_receiver].currentPlan).mul(_basePercentage)).div(100));
                    newAmount = ((newAmount).mul(directReferralRate[level])).div(100);

                    TransferHelper.safeTransfer(address(usdt), _receiver, newAmount);
                    users[_receiver].directReferrerIncome = users[_receiver].directReferrerIncome.add(newAmount);
                    emit DirectReferralIncome(_from, _receiver, newAmount, level, block.timestamp);

                    uint lostIncome = amount - newAmount;
                    users[_receiver].lostIncome = users[_receiver].lostIncome.add(lostIncome);

                    address eligibleUser = getEligibleReceiver(users[_receiver].referrer, users[_from].currentPlan);
                    TransferHelper.safeTransfer(address(usdt), eligibleUser, lostIncome);
                    users[eligibleUser].directReferrerIncome = users[eligibleUser].directReferrerIncome.add(lostIncome);
                    emit LostIncome(_receiver, eligibleUser, lostIncome, level, block.timestamp);
                    emit DirectReferralIncome(_from, eligibleUser, lostIncome, level, block.timestamp);
                }
            }

            _receiver = users[_receiver].referrer;
            level++;
        }
    }

    function getEligibleReceiver(address _receiver, uint currentPlan) private view returns(address) {
        uint walks;
        while (_receiver != address(0) && walks++ < maxWalks) {
            if (users[_receiver].currentPlan >= currentPlan) {
                return _receiver;
            }
            _receiver = users[_receiver].referrer;
        }

        return rootNode;
    }

    function setMaxWalks(uint walks) external onlyOwner {
        require(walks > 0, 'IBGV0: Invalid walks');
        maxWalks = walks;
    }

    function withdrawYield(bool onlyYield) external virtual nonReentrant {
        _withdrawIBGYield(msg.sender, users[msg.sender].investmentCount, onlyYield);
    }

    function _withdrawIBGYield(address user, uint cycles, bool onlyYield) private {
        uint totalYield;
        uint totalInvestment;
        for(uint i = 1; i <= cycles; i++) {
            InvestmentLibrary.Investment storage cycle = cycleDetails[user][i];

            if(!cycle.isUnstaked && cycle.plan == 1) {
                uint daysDiff = (block.timestamp.sub(cycle.investmentTime)).div(SECONDS_IN_DAY);
                uint count;
                if(daysDiff >= (cycle.stakingPeriod)) {
                    count = (cycle.stakingPeriod).div(30);
                    cycleDetails[user][i].isUnstaked = true;
                    IBGPlanDetails[user].stakedIBGTokens = IBGPlanDetails[user].stakedIBGTokens.sub(cycle.investment);
                    totalYield = totalYield.add(((cycle.investment).mul(count.mul(cycle.yieldRateValue))).div(100));
                    IBGPlanDetails[user].withdrawnYield = IBGPlanDetails[user].withdrawnYield.add(totalYield);
                    totalInvestment = totalInvestment.add(cycle.investment);
                }
            } else {
                totalInvestment = totalInvestment.add(cycle.investment);
            }
        }

        totalInvestment = totalInvestment.sub(IBGPlanDetails[user].withdrawnInvestment);
        if (!onlyYield) {
            require(totalInvestment > 0 || totalYield > 0, "IBGV0: Zero Yield and Investment");
        } else {
            require(totalYield > 0, "IBGV0: Zero Yield");
        }


        if(totalInvestment > 0 && !onlyYield) {
            TransferHelper.safeTransfer(address(ibg), user, totalInvestment);
            IBGPlanDetails[user].withdrawnInvestment = IBGPlanDetails[user].withdrawnInvestment.add(totalInvestment);
            demotePack(user, (totalInvestment.mul(IBGToUsdt)).div(DECIMAL_FACTOR_IBG));
        }

        if(totalYield == 0) {
            return;
        }

        uint yieldAmount = (totalYield.mul(95)).div(100);
        TransferHelper.safeTransfer(address(ibg), yieldWallet, ((totalYield).mul(5)).div(100));
        IBGPlanDetails[user].IBGYieldIncome = IBGPlanDetails[user].IBGYieldIncome.add(((yieldAmount).mul(90)).div(100));
        TransferHelper.safeTransfer(address(ibg), user, ((yieldAmount).mul(90)).div(100));
        emit YieldIncome(msg.sender, ((yieldAmount).mul(90)).div(100), block.timestamp);

        iBGYieldCommission(user, users[user].referrer, users[user].currentPlan, (yieldAmount.mul(10)).div(100));
    }

    function demotePack(address user, uint amount) private {
        amount = (amount.mul(DECIMAL_FACTOR)).div(DECIMAL_FACTOR_IBG);
        if(users[user].currentPlan >= amount) {
            users[user].currentPlan = users[user].currentPlan.sub(amount);
        } else {
            users[user].currentPlan = 0;
        }
    }

    function calculateYieldAndInvestment(address user) public view returns(uint withdrawableYield, uint withdrawableInvestment){
        uint totalYield;
        uint totalInvestment;

        for(uint i = 1; i <= users[user].investmentCount; i++) {
            InvestmentLibrary.Investment storage cycle = cycleDetails[user][i];
            if(!cycle.isUnstaked && cycle.plan == 1) {
                uint daysDiff = (block.timestamp.sub(cycle.investmentTime)).div(SECONDS_IN_DAY);
                uint count;
                if(daysDiff >= (cycle.stakingPeriod)) {
                    count = (cycle.stakingPeriod).div(30);
                    totalYield = totalYield.add(((cycle.investment).mul(count.mul(cycle.yieldRateValue))).div(100));
                    totalInvestment = totalInvestment.add(cycle.investment);
                }
            } else {
                totalInvestment = totalInvestment.add(cycle.investment);
            }
        }
        totalInvestment = totalInvestment.sub(IBGPlanDetails[user].withdrawnInvestment);
        return ((totalYield.mul(95)).div(100), totalInvestment);
    }

    function calculateIBGTokenPrice() private {
        uint newValue = totalIBGDistributed.div(increaseIBGAfterLimit);
        if(newValue > lastRate) {
            lastRate = newValue;
            newValue = newValue.mul(increaseRateIBG);
            IBGToUsdt = (1 * DECIMAL_FACTOR_IBG).add(newValue);
        }
    }

    function getInvestmentDetails(address _user, uint _id) external view returns (uint plan, uint investmentAmount, uint investmentTime, uint stakingPeriod, bool isUnstaked) {
        return(
            cycleDetails[_user][_id].plan,
            cycleDetails[_user][_id].investment,
            cycleDetails[_user][_id].investmentTime,
            cycleDetails[_user][_id].stakingPeriod,
            cycleDetails[_user][_id].isUnstaked
        );
    }

    function updateDirectReferralRate(uint index, uint value) external virtual onlyOwner {
        require(index > 0 && index < 4, 'IBGV0: Index length must be between 1 to 3');
        require(value > 0 && value <= 100,'IBGV0: Invalid Value');
        directReferralRate[index] = value;
    }

    function updateYieldMatchingRate(uint index, uint value) external virtual onlyOwner {
        require(index > 0 && index < 6, 'IBGV0: Index length must be between 1 to 5');
        require(value > 0 && value <= 100,'IBGV0: Invalid Value');
        yieldMatchingRate[index] = value;
    }


    function updatePack(uint packNumber, uint price) external virtual onlyOwner returns(uint, uint) {
        require((packNumber > 0 && packNumber <= maxPacks.add(1)), "IBGV0: Invalid PackNumber");
        require(price > 0, "IBGV0: Invalid Packprice");
        packPrice[packNumber] = price;

        if(packNumber > maxPacks) {
            maxPacks = packNumber;
        }

        return(packNumber, packPrice[packNumber]);
    }

    function updatePlan(uint planNumber, string calldata planName) external virtual onlyOwner returns(uint, string memory) {
        require((planNumber > 0 && planNumber <= maxPlans.add(1)), "IBGV0: Invalid PlanNumber");
        require(keccak256(abi.encodePacked(planName)) != keccak256(abi.encodePacked('')), "IBGV0: Invalid Plan name");
        plans[planNumber] = planName;

        if(planNumber > maxPlans) {
            maxPlans = planNumber;
        }

        return(planNumber, plans[planNumber]);
    }

    function updateStakingTime(uint timeIndex, uint timeValue) external virtual onlyOwner returns(uint, uint) {
        require(timeIndex > 0, 'IBGV0: Invalid TimeIndex');
        require(timeValue > 0, 'IBGV0: Invalid TimeValue');
        stakingTime[timeIndex] = timeValue;
        return(timeIndex, stakingTime[timeIndex]);

    }

    function updateYieldRate(uint timeInDays, uint yieldValue) external virtual onlyOwner returns(uint, uint) {
        require(timeInDays > 0, 'IBGV0: Invalid YieldIndex');
        require(yieldValue > 0, 'IBGV0: Invalid YieldValue');
        yieldRate[timeInDays] = yieldValue;
        return(timeInDays, yieldRate[timeInDays]);
    }

    function updateBGBFToken(address _token) external virtual onlyOwner {
        require(_token != address(0), "IBGV0: Invalid Token Address");
        bgbf = IERC20(_token);
    }

    function updatePlanStatus(uint plan, bool status) external virtual onlyOwner {
        require(planActiveStatus[plan] != status, "IBGV0: Plan already has required status");
        require(plan >= 1 && plan <= maxPlans, 'IBGV0: Invalid Plan');
        planActiveStatus[plan] = status;
    }

    function updateTreasuryWallet(address _newWallet) external virtual onlyOwner {
        require(_newWallet != address(0), 'IBGV0: Invalid Address');
        require(_newWallet != treasuryWallet, "IBGV0: Wallet is same as previous");
        treasuryWallet = _newWallet;
    }

    function updateDirectCommissionWallet(address _newWallet) external virtual onlyOwner {
        require(_newWallet != address(0), 'IBGV0: Invalid Address');
        require(_newWallet != directCommissionWallet, "IBGV0: Wallet is same as previous");
        directCommissionWallet = _newWallet;
    }

    function updateYieldMatchingWallet(address _newWallet) external virtual onlyOwner {
        require(_newWallet != address(0), 'IBGV0: Invalid Address');
        require(_newWallet != yieldMatchingWallet, "IBGV0: Wallet is same as previous");
        yieldMatchingWallet = _newWallet;
    }

    function updateYieldWallet(address _newWallet) external virtual onlyOwner {
        require(_newWallet != address(0), 'IBGV0: Invalid Address');
        require(_newWallet != yieldWallet, "IBGV0: Wallet is same as previous");
        yieldWallet = _newWallet;
    }

    function walletBalance() external virtual onlyOwner {
        uint value = ibg.balanceOf(address(this));

        require(value > 0, "IBGV0: Invalid balance");
        TransferHelper.safeTransfer(address(ibg), treasuryWallet, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor () {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title CustomOwnable
 * @dev This contract has the owner address providing basic authorization control
 */
contract CustomOwnable {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    // Owner of the contract
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner(), "CustomOwnable: FORBIDDEN");
        _;
    }

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "CustomOwnable: FORBIDDEN");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library UserLibrary {

    struct User {
        uint referralCount;
        uint directReferrerIncome;
        uint lostIncome;
        uint currentPlan;
        uint investmentCount;
        address referrer;
    }

    function exists(User storage self) internal view returns (bool) {
        return self.investmentCount > 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library IBGLibrary {

    struct IBGPlan {
        uint IBGTokens;
        uint stakedIBGTokens;
        uint IBGYieldIncome;
        uint IBGYieldMatchingIncome;
        uint IBGYieldMatchingLostIncome;
        uint withdrawnInvestment;
        uint withdrawnYield;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library InvestmentLibrary {

    struct Investment {
        uint plan;
        uint investment;
        uint investmentTime;
        uint stakingPeriod;
        uint yieldRateValue;
        bool isUnstaked;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IIBGEvents {

    event Registration(address indexed _user, address indexed referrer, uint registrationTime);
    event PackPurchased(address indexed _user, uint indexed _pack, uint _plan, uint currentPackAmount, uint time);
    event StakedToken(address indexed stakedBy, uint amountStaked, uint plan, uint time, uint stakingPeriod);
    event DirectReferralIncome(address indexed _from, address indexed receiver, uint incomeRecieved, uint indexed level, uint time);
    event LostIncome(address indexed _from, address indexed reciever, uint incomeLost, uint indexed level, uint time);
    event YieldIncome(address indexed user, uint yieldRecieved, uint time);
    event YieldMatchingIncome(address indexed _from, address indexed receiver, uint incomeRecieved, uint indexed level, uint time);
    event YieldMatchingLostIncome(address indexed _from, address indexed reciever, uint matchingLostIncome, uint indexed level, uint time);
}

