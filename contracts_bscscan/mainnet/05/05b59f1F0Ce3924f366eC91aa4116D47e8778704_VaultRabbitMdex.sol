// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IRabbit.sol";
import "./VaultBase.sol";
import "./MdexStrat.sol";

//Investment strategy
contract VaultRabbitMdex is VaultBase, MdexStrat{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public fairLaunchPid;

    address public constant RABBIT = 0x95a1199EBA84ac5f19546519e287d43D2F0E1b41;
    IBank public constant RabbitBank = IBank(0xc18907269640D11E2A91D7204f33C5115Ce3419e);
    IFairLaunch public constant FairLaunch = IFairLaunch(0x81C1e8A6f8eB226aA7458744c5e12Fc338746571);
    address public constant CAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function initialize (
        address _stakingToken,
        uint256 _fairLaunchPid,
        address _config
    ) external initializer {
        fairLaunchPid = _fairLaunchPid;

        _VaultBase_init(_config, address(RabbitBank));
        _StratMdex_init(_stakingToken, RABBIT);

        _safeApprove(_stakingToken, address(RabbitBank));
        address ibToken = _ibToken();
        _safeApprove(ibToken, address(FairLaunch));

        _safeApprove(stakingToken, CAKE_ROUTER);
        _safeApprove(reawardToken, CAKE_ROUTER);
        _safeApprove(CAKE, CAKE_ROUTER);
        _safeApprove(WBNB, CAKE_ROUTER);
        IPineconeFarm pineconeFarm = config.pineconeFarm();
        _safeApprove(CAKE, address(pineconeFarm));
    }

    receive() external payable {}

    /* ========== public view ========== */

    function farmPid() public view returns(uint256) {
        return fairLaunchPid;
    }

    function stakeType() public pure returns(StakeType) {
        return StakeType.Rabbit_Mdex;
    }

    function earned0Address() public view returns(address) {
        return stakingToken;
    }

    function earned1Address() public view returns(address) {
        return config.PCT();
    }

    function userInfoOf(address _user, uint256 _addPct) public view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ) 
    {
        UserAssetInfo storage user = users[_user];
        depositedAt = user.depositedAt;
        depositAmt = user.depositAmt;
        (earned0Amt, earned1Amt) = pendingRewards(_user);
        earned1Amt = earned1Amt.add(_addPct);
        withdrawbaleAmt = withdrawableBalanceOf(_user);
        uint256 wantAmt = depositAmt.add(earned0Amt);

        IPineconeConfig _config = config;
        uint256 wantValue = wantAmt.mul(_config.priceOfToken(stakingToken)).div(UNIT);
        uint256 earned1Value = earned1Amt.mul(_config.priceOfPct()).div(UNIT);
        balanceValue = wantValue.add(earned1Value);
    }

    function tvl() public view returns(uint256 priceInUsd) {
        (uint256 wantAmt, uint256 rabbitAmt, uint256 mdexAmt) = balance();
        IPineconeConfig _config = config;
        uint256 wantTvl = wantAmt.mul(_config.priceOfToken(stakingToken)).div(UNIT);
        uint256 rabbitTvl = rabbitAmt.mul(_config.priceOfToken(RABBIT)).div(UNIT);
        uint256 mdexTvl = mdexAmt.mul(_config.priceOfToken(MDEX)).div(UNIT);
        return wantTvl.add(rabbitTvl).add(mdexTvl);
    }

    function balance() public view returns(uint256 wantAmt, uint256 rabbitAmt, uint256 mdexAmt) {
        IRabbitCalculator rabbitCalculator = config.rabbitCalculator();
        wantAmt = rabbitCalculator.balanceOf(_stakingTokenForRabbit(), fairLaunchPid, address(this));
        rabbitAmt = FairLaunch.pendingRabbit(fairLaunchPid, address(this));
        mdexAmt = _stakingMdex();
        uint256 pendingMdex = _pendingMdex();
        mdexAmt = mdexAmt.add(pendingMdex);
    }

    function balanceOf(address _user) public view returns(uint256 wantAmt, uint256 mdexAmt) {
        if (sharesTotal == 0) {
            return (0,0);
        }

        wantAmt = 0;
        mdexAmt = _pendingMdex(_user);
        uint256 shares = sharesOf(_user);
        if (shares != 0) {
            (wantAmt,,) = balance();
            wantAmt = wantAmt.mul(shares).div(sharesTotal);
        }
    }

    function earnedOf(address _user) public view returns(uint256 wantAmt, uint256 mdexAmt) {
        UserAssetInfo storage user = users[_user];
        (wantAmt, mdexAmt) = balanceOf(_user);
        if (wantAmt > user.depositAmt) {
            wantAmt = wantAmt.sub(user.depositAmt);
        } else {
            wantAmt = 0;
        }
    }

    function pendingRewardsValue() public view returns(uint256 priceInUsd) {
        uint256 pendingRabbit = FairLaunch.pendingRabbit(fairLaunchPid, address(this));
        uint256 amt = IERC20(RABBIT).balanceOf(address(this));
        pendingRabbit = pendingRabbit.add(amt);
        uint256 pendingMdex = _pendingMdex();

        IPineconeConfig _config = config;
        uint256 rabbitValue = pendingRabbit.mul(_config.priceOfToken(RABBIT)).div(UNIT);
        uint256 mdexValue = pendingMdex.mul(_config.priceOfToken(MDEX)).div(UNIT);
        return rabbitValue.add(mdexValue);
    }

    function pendingRewards(address _user) public view returns(uint256 wantAmt, uint256 pctAmt)
    {
        if (sharesTotal == 0) {
            return (0, 0);
        }

        (uint256 wantAmt0, uint256 mdexAmt) = earnedOf(_user);
        wantAmt = wantAmt0;
        IPineconeConfig _config = config;
        uint256 mdexToAmt = _config.getAmountsOut(mdexAmt, MDEX, stakingToken, ROUTER);
        wantAmt = wantAmt.add(mdexToAmt);
        uint256 fee = performanceFee(wantAmt);
        pctAmt = _config.tokenAmountPctToMint(stakingToken, fee);
        wantAmt = wantAmt.sub(fee);
    }

    /* ========== public write ========== */
    function deposit(uint256 _wantAmt, address _user)
        public
        onlyOwner
        whenNotPaused
        returns(uint256)
    {
        IERC20(stakingToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        UserAssetInfo storage user = users[_user];
        user.depositedAt = block.timestamp;
        user.depositAmt = user.depositAmt.add(_wantAmt);

        uint256 sharesAdded = _wantAmt;
        
        (uint256 wantTotal,,) = balance();
        if (wantTotal > 0 && sharesTotal >0) {
            sharesAdded = sharesAdded
                .mul(sharesTotal)
                .div(wantTotal);
        }
        
        _earn();
        sharesTotal = sharesTotal.add(sharesAdded);
        uint256 pending = user.shares.mul(accPerShareOfMdex).div(1e12).sub(user.rewardPaid);
        user.pending = user.pending.add(pending);
        user.shares = user.shares.add(sharesAdded);
        user.rewardPaid = user.shares.mul(accPerShareOfMdex).div(1e12);

        return sharesAdded;
    }

    function farm() public nonReentrant 
    {
        _farm();
    }

    function earn() public whenNotPaused onlyGov
    {
       _earn();
    }

    function withdrawAll(address _user)
        public 
        onlyOwner
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        require(sharesTotal > 0, "sharesTotal is 0");

        UserAssetInfo storage user = users[_user];
        require(user.shares > 0, "user.shares is 0");
        require(user.depositAmt > 0, "depositAmt <= 0");

        uint256 wantAmt = user.depositAmt;
        (uint256 earnedWantAmt, uint256 mdexAmt) = earnedOf(_user);

        _withdrawWant(wantAmt.add(earnedWantAmt));
        _withdrawMdex(mdexAmt);

        uint256 swapAmt = _swap(stakingToken, mdexAmt, _tokenPath(MDEX, stakingToken), ROUTER);
        earnedWantAmt = earnedWantAmt.add(swapAmt);

        address wNativeRelayer = config.wNativeRelayer();
        //withdraw fee
        {
            uint256 withdrawFeeAmt = 0;
            bool hasFee = (user.depositedAt.add(minDepositTimeWithNoFee) > block.timestamp) ? true : false;
            if (hasFee) {
                withdrawFeeAmt = wantAmt.mul(withdrawFeeFactor).div(feeMax);
                _safeTransfer(stakingToken, devAddress, withdrawFeeAmt, wNativeRelayer);
                wantAmt = wantAmt.sub(withdrawFeeAmt);
            }
        }

        //performace fee
        (uint256 fee, uint256 pctAmt) = _distributePerformanceFees(earnedWantAmt, _user);
        earnedWantAmt = earnedWantAmt.sub(fee);
        wantAmt = wantAmt.add(earnedWantAmt);

        {
            uint256 balanceAmt = IERC20(stakingToken).balanceOf(address(this));
            if (wantAmt > balanceAmt) {
                wantAmt = balanceAmt;
            }
            _safeTransfer(stakingToken, _user, wantAmt, wNativeRelayer);
        }

        if (user.shares > sharesTotal) {
            sharesTotal = 0;
        } else {
            sharesTotal = sharesTotal.sub(user.shares);
        }
        user.shares = 0;
        user.depositAmt = 0;
        user.depositedAt = 0;
        user.pending = 0;
        user.rewardPaid = 0;
    
        _earn();
        return (wantAmt, earnedWantAmt, pctAmt);
    }

    function withdraw(uint256 _wantAmt, address _user)
        public 
        onlyOwner
        nonReentrant
        returns (uint256, uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        UserAssetInfo storage user = users[_user];
        require(user.shares > 0, "user.shares is 0");
        require(user.depositAmt > 0, "depositAmt <= 0");

        (uint256 wantAmt, uint256 sharesRemoved) = _withdraw(_wantAmt, _user);
        _earn();
        sharesTotal = sharesTotal.sub(sharesRemoved);
        uint256 pending = user.shares.mul(accPerShareOfMdex).div(1e12).sub(user.rewardPaid);
        user.pending = user.pending.add(pending);
        user.shares = user.shares.sub(sharesRemoved);
        user.rewardPaid = user.shares.mul(accPerShareOfMdex).div(1e12);

        return (wantAmt, sharesRemoved);
    }

    function claim(address _user) 
        public 
        onlyOwner
        nonReentrant
        returns(uint256, uint256)
    {
        (uint256 rewardAmt, uint256 pct) = _claim(_user);
        _earn();
        UserAssetInfo storage user = users[_user];
        user.pending = 0;
        user.rewardPaid = user.shares.mul(accPerShareOfMdex).div(1e12);
        return (rewardAmt, pct);
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount)
        public
        onlyGov
    {
        require(_token != config.PCT(), "!safe");
        require(_token != stakingToken, "!safe");
        require(_token != RABBIT, "!safe");
        require(_token != MDEX, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /* ========== private methord ========== */
    function _farm() private 
    {
        if (stakingToken == WBNB) {
            uint256 wantAmt = IERC20(stakingToken).balanceOf(address(this));
            if (wantAmt > 0) {
                address wNativeRelayer = config.wNativeRelayer();
                IERC20(WBNB).safeTransfer(wNativeRelayer, wantAmt);
                IWNativeRelayer(wNativeRelayer).withdraw(wantAmt);
            }
            wantAmt = address(this).balance;
            if (wantAmt > 0) {
                IBank(stratAddress).deposit{value:wantAmt}(address(0), wantAmt);
            }
        } else {
            uint256 wantAmt = IERC20(stakingToken).balanceOf(address(this));
            if (wantAmt > 0) {
                IBank(stratAddress).deposit(stakingToken, wantAmt);
            }
        }

        uint256 ibAmt = IERC20(_ibToken()).balanceOf(address(this));
        if (ibAmt > 0) {
            FairLaunch.deposit(address(this), fairLaunchPid, ibAmt);
        }

        _reawardTokenToMdex();
        _claimMdex();
        _farmMdex();
    }

    function _earn() private {
         //auto compounding rabbit + mdex
        if (lastEarnBlock >= block.number) return;
        if (FairLaunch.pendingRabbit(fairLaunchPid, address(this)) > 0) {
            FairLaunch.harvest(fairLaunchPid);
        }
        _farm();
        lastEarnBlock = block.number;
    }

    function _withdraw(uint256 _wantAmt, address _user) private returns(uint256, uint256) {
        UserAssetInfo storage user = users[_user];
        (uint256 wantTotal,,) = balance();
        if (_wantAmt > user.depositAmt) {
            _wantAmt = user.depositAmt;
        }
        user.depositAmt = user.depositAmt.sub(_wantAmt);
        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantTotal);
        if (sharesRemoved > user.shares) {
            sharesRemoved = user.shares;
        }
    
        _withdrawWant(_wantAmt);
        uint256 wantAmt = IERC20(stakingToken).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        address wNativeRelayer = config.wNativeRelayer();
        bool hasFee = (user.depositedAt.add(minDepositTimeWithNoFee) > block.timestamp) ? true : false;
        if (hasFee) {
            uint256 withdrawFeeAmt = _wantAmt.mul(withdrawFeeFactor).div(feeMax);
            _safeTransfer(stakingToken, devAddress, withdrawFeeAmt, wNativeRelayer);
            _wantAmt = _wantAmt.sub(withdrawFeeAmt);
        }
        _safeTransfer(stakingToken, _user, _wantAmt, wNativeRelayer);

        return (_wantAmt, sharesRemoved);
    }

    function _withdrawWant(uint256 amount) private  {
        if (amount == 0) return;
        amount = RabbitBank.ibTokenCalculation(_stakingTokenForRabbit(), amount);
        IRabbitCalculator rabbitCalculator = config.rabbitCalculator();
        uint256 amt = rabbitCalculator.balanceOfib(fairLaunchPid, address(this));
        if (amount > amt) {
            amount = amt;
        }
        FairLaunch.withdraw(address(this), fairLaunchPid, amount);
        RabbitBank.withdraw(_stakingTokenForRabbit(), amount);
        if (stakingToken == WBNB && address(this).balance > 0) {
            IWETH(WBNB).deposit{value:address(this).balance}();
        }
    }

    function _claim(address _user) private returns(uint256, uint256) {
        (uint256 wantAmt, uint256 mdexAmt) = earnedOf(_user);
        if (wantAmt == 0 && mdexAmt == 0) {
            return(0,0);
        }
        UserAssetInfo storage user = users[_user];
        (uint256 wantTotal,,) = balance();
        uint256 sharesRemoved = wantAmt.mul(sharesTotal).div(wantTotal);
        if (sharesRemoved > user.shares) {
            sharesRemoved = user.shares;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        user.shares = user.shares.sub(sharesRemoved);
        //clean dust shares
        if (user.shares > 0 && user.shares < dust) {
            sharesTotal = sharesTotal.sub(user.shares);
            user.shares = 0;
        } 

        _withdrawWant(wantAmt);
        _withdrawMdex(mdexAmt);

        uint256 swapAmt = _swap(stakingToken, mdexAmt, _tokenPath(MDEX, stakingToken), ROUTER);
        wantAmt = wantAmt.add(swapAmt);

        uint256 balanceAmt = IERC20(stakingToken).balanceOf(address(this));
        if (wantAmt > balanceAmt) {
            wantAmt = balanceAmt;
        }

        //performance fee
        (uint256 fee, uint256 pctAmt) = _distributePerformanceFees(wantAmt, _user);
        wantAmt = wantAmt.sub(fee);
        _safeTransfer(stakingToken, _user, wantAmt, config.wNativeRelayer());
        return (wantAmt, pctAmt);
    }

    function _distributePerformanceFees(uint256 _wantAmt, address _user) private returns(uint256 fee, uint256 pct) {
        if (_wantAmt <= dust) {
            return (0, 0);
        }

        pct = 0;
        fee = performanceFee(_wantAmt);
        if (fee > 0) {
            IPineconeFarm pineconeFarm = config.pineconeFarm();
            uint256 profit = config.getAmountsOut(fee, stakingToken, WBNB, CAKE_ROUTER);
            pct = pineconeFarm.mintForProfit(_user, profit, false);

            uint256 cakeAmt = _swap(CAKE, fee, _tokenPath(stakingToken, CAKE), CAKE_ROUTER);
            if (cakeAmt > 0) {
                pineconeFarm.stakeRewardsTo(address(pineconeFarm), cakeAmt);
            }
        }
    }

    function _stakingTokenForRabbit() private view returns(address) {
        return (stakingToken == WBNB ) ? address(0) : stakingToken;
    }

    function _ibToken() private view returns(address) {
        IRabbitCalculator calculator = config.rabbitCalculator();
        address ibToken = calculator.ibToken(_stakingTokenForRabbit());
        return ibToken;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBank {

  function totalToken(address token) external view returns (uint256);

  function deposit(address token, uint256 amount) external payable;

  function withdraw(address token, uint256 pAmount) external;

  function config() external view returns(IBankConfig);

  function ibTokenCalculation(address token, uint256 amount) view external returns(uint256);
}

interface IBankConfig {

    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    function getReserveBps() external view returns (uint256);

    function getLiquidateBps() external view returns (uint256);
}

interface IFairLaunch {
  function poolLength() external view returns (uint256);

  function addPool(
    uint256 _allocPoint,
    address _stakeToken,
    bool _withUpdate
  ) external;

  function setPool(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external;

  function pendingRabbit(uint256 _pid, address _user) external view returns (uint256);

  function updatePool(uint256 _pid) external;

  function deposit(address _for, uint256 _pid, uint256 _amount) external;

  function withdraw(address _for, uint256 _pid, uint256 _amount) external;

  function withdrawAll(address _for, uint256 _pid) external;

  function harvest(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IPineconeConfig.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract VaultBase is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public govAddress; // timelock contract
    address public devAddress; 

    uint256 public withdrawFeeFactor; // 0.5% fee for withdrawals within 3 days
    uint256 public constant withdrawFeeFactorUL = 50; // 0.5% is the max withdraw fee settable.
    uint256 public minDepositTimeWithNoFee;
    uint256 public commission; // commission on profits for mint pct
    uint256 public constant commissionUL = 3000; // max 30%
    uint256 public constant feeMax = 10000;

    uint256 public lastEarnBlock;

    IPineconeConfig public config;
    address public stratAddress;

    function _VaultBase_init(address _config, address _stratAddress) internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        withdrawFeeFactor = 50;
        minDepositTimeWithNoFee = 3 days;
        commission = 3000;
        lastEarnBlock = 0;
        devAddress = msg.sender;
        govAddress = msg.sender;
        config = IPineconeConfig(_config);
        stratAddress = _stratAddress;

        transferOwnership(address(config.pineconeFarm()));
    }

    modifier onlyGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }

    modifier onlyDev() {
        require(msg.sender == devAddress, "!dev");
        _;
    }

    /* ========== onlyDev ========== */
    function pause() onlyDev external {
        _pause();
    }

    function unpause() onlyDev external {
        _unpause();
    }

    function setDevAddress(address _devAddress) onlyDev public {
        devAddress = _devAddress;
    }

    function setCommission(uint256 _commission) onlyDev public {
        require(_commission <= commissionUL, "too high");
        commission = _commission;
    }

    function setConfig(address _config) onlyDev public {
        config = IPineconeConfig(_config);
    }

    /* ========== onlyGov ========== */
    function setGovAddress(address _govAddress) onlyGov public {
        govAddress = _govAddress;
    }

    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) onlyGov public {
        require(_withdrawFeeFactor <= withdrawFeeFactorUL, "too high");
        withdrawFeeFactor = _withdrawFeeFactor;
    }

    function setMinDepositTime(uint256 _minDepositTimeWithNoFee) public onlyGov {
        minDepositTimeWithNoFee = _minDepositTimeWithNoFee;
    }

    function performanceFee(uint256 _profit) public view returns(uint256) {
        return _profit.mul(commission).div(feeMax);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IBoardRoomMDX.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IWNativeRelayer.sol";

contract MdexStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserAssetInfo
    {
        uint256 depositAmt;
        uint256 depositedAt;
        uint256 shares;
        uint256 pending;
        uint256 rewardPaid;
    }

    uint256 public sharesTotal;
    mapping (address=>UserAssetInfo) users;

    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public constant MDEX = 0x9C65AB58d8d978DB963e63f2bfB7121627e3a739;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant ROUTER = 0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8; 

    IBoardRoomMDX public constant mdexMaster = IBoardRoomMDX(0x6aEE12e5Eb987B3bE1BA8e621BE7C4804925bA68);
    uint256 public constant mpid = 4;

    IMasterChef public constant cakeMaster = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    uint256 public constant cpid = 0;

    address public stakingToken;
    address public reawardToken;

    uint256 internal constant dust = 1000;
    uint256 internal constant UNIT = 1e18;

    uint256 public totalStakingMdexAmount;
    uint256 public accPerShareOfMdex;

    /* ========== public view ========== */
    function sharesOf(address _user) public view returns(uint256) {
        return users[_user].shares;
    }

    function depositAmtOf(address _user) public view returns(uint256) {
        return users[_user].depositAmt;
    }

    function depositedAt(address _user) public view returns(uint256) {
        return users[_user].depositedAt;
    }

    function withdrawableBalanceOf(address _user) public virtual view returns(uint256) {
        return users[_user].depositAmt;
    }

    function userOf(address _user) public view returns(
        uint256 _depositAmt, 
        uint256 _depositedAt, 
        uint256 _shares,
        uint256 _pending,
        uint256 _rewardPaid
    ) {
        UserAssetInfo storage user = users[_user];
        _depositAmt = user.depositAmt;
        _depositedAt = user.depositedAt;
        _shares = user.shares;
        _pending = user.pending;
        _rewardPaid = user.rewardPaid;
    }

    function pendingMdex() public view returns(uint256) {
        return _pendingMdex();
    }

    function pendingMdexPerShare() public view returns(uint256) {
        if (sharesTotal == 0) {
            return 0;
        }

        uint256 perShare = _pendingMdex().mul(1e12).div(sharesTotal);
        return perShare;
    }

    /* ========== internal method ========== */

    function _StratMdex_init(address _stakingToken, address _reawardToken) internal {
        stakingToken = _stakingToken;
        reawardToken = _reawardToken;
        sharesTotal = 0;
        totalStakingMdexAmount = 0;
        accPerShareOfMdex = 0;

        _safeApprove(stakingToken, ROUTER);
        _safeApprove(reawardToken, ROUTER);
        _safeApprove(MDEX, ROUTER);
        _safeApprove(WBNB, ROUTER);
        _safeApprove(CAKE, ROUTER);
        _safeApprove(MDEX, address(mdexMaster));
    }

    function _tokenPath(address _token0, address _token1) internal pure returns(address[] memory path) {
        require(_token0 != _token1, "_token0 == _token1");
        if (_token0 == WBNB || _token1 == WBNB) {
            path = new address[](2);
            path[0] = _token0;
            path[1] = _token1;
        } else {
            path = new address[](3);
            path[0] = _token0;
            path[1] = WBNB;
            path[2] = _token1;
        }
    }

    function _stakingMdex() internal view returns(uint256) {
        return totalStakingMdexAmount;
    }

    function _pendingMdex() internal view returns(uint256) {
        return mdexMaster.pending(mpid, address(this));
    }

    function _pendingMdex(address _user) internal view returns(uint256) {
        UserAssetInfo storage user = users[_user];
        uint256 perShare = pendingMdexPerShare();
        perShare = perShare.add(accPerShareOfMdex);
        uint256 pending = user.pending.add(user.shares.mul(perShare).div(1e12).sub(user.rewardPaid));
        return pending;
    }

    function _reawardTokenToMdex() internal returns(uint256) {
        uint256 amount = IERC20(reawardToken).balanceOf(address(this));
        if (amount > dust) {
            return _swap(MDEX, amount, _tokenPath(reawardToken, MDEX), ROUTER);
        }
        return 0;
    }

    function _farmMdex() internal {
        uint256 amount = IERC20(MDEX).balanceOf(address(this));
        if (amount > dust) {
            mdexMaster.deposit(mpid, amount);
            totalStakingMdexAmount = totalStakingMdexAmount.add(amount);

            if (sharesTotal > 0) {
                accPerShareOfMdex = accPerShareOfMdex.add(amount.mul(1e12).div(sharesTotal));
            }
        }
    }

    function _withdrawMdex(uint256 _amount) internal {
        if (_amount == 0 || IERC20(MDEX).balanceOf(address(this)) >= _amount) return;
        uint256 _amt = _stakingMdex();
        if (_amount > _amt) {
            _amount = _amt;
        }
        mdexMaster.withdraw(mpid, _amount);
        totalStakingMdexAmount = totalStakingMdexAmount.sub(_amount);
    }

    function _claimMdex() internal {
        mdexMaster.withdraw(mpid, 0);
    }

    function _stakingCake() internal view returns(uint256) {
        (uint amount,) = cakeMaster.userInfo(cpid, address(this));
        return amount;
    }

    function _pendingCake() internal view returns(uint256) {
        return cakeMaster.pendingCake(cpid, address(this));
    }

    function _reawardCakeToMdex() internal returns(uint256) {
        uint256 amount = IERC20(CAKE).balanceOf(address(this));
        if (amount > dust) {
            _swap(MDEX, amount, _tokenPath(CAKE, MDEX), ROUTER);
        }
    }

    function _farmCake() internal {
        uint256 wantAmt = IERC20(CAKE).balanceOf(address(this));
        if (wantAmt > 0) {
            cakeMaster.enterStaking(wantAmt);
        }
    }

    function _claimCake() internal {
        cakeMaster.leaveStaking(0);
    }

    function _withdrawCake(uint256 amount, bool claim) internal {
        uint256 stakingAmount = _stakingCake();
        if (amount > stakingAmount) {
            amount = stakingAmount;
        }
        uint256 cakeBalance = IERC20(CAKE).balanceOf(address(this));
        if (cakeBalance < amount) {
            cakeMaster.leaveStaking(amount.sub(cakeBalance));
        } else {
            if (claim) {
                _claimCake();
            }
        }
    }

    function _safeApprove(address token, address spender) internal {
        if (token != address(0) && IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, uint256(~0));
        }
    }

    function _safeTransfer(address _token, address _to, uint256 _amount, address wNativeRelayer) internal {
        if (_amount == 0) return;

        if (_token == WBNB) {
            IERC20(WBNB).safeTransfer(wNativeRelayer, _amount);
            IWNativeRelayer(wNativeRelayer).withdraw(_amount);
            SafeERC20.safeTransferETH(_to, _amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    function _swap(address token, uint256 amount, address[] memory path, address router) internal returns(uint256) {
        if (amount == 0 || path.length == 0) return 0;

        uint256 amt = IERC20(path[0]).balanceOf(address(this));
        if (amount > amt) {
            amount = amt;
        }

        uint256 beforeAmount = IERC20(token).balanceOf(address(this));
        IPancakeRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            now + 60
        );

        uint256 afterAmount = IERC20(token).balanceOf(address(this));
        if (afterAmount > beforeAmount) {
            return afterAmount.sub(beforeAmount);
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IDashboard.sol";
import "./IPinecone.sol";

interface IPineconeConfig {
    function PCT() external view returns(address);
    function alpacaCalculator() external view returns(IAlpacaCalculator);
    function priceCalculator() external view returns(IPriceCalculator);
    function wexCalculator() external view returns(IWexCalculator);
    function pineconeFarm() external view returns(IPineconeFarm);
    function priceOfToken(address _token) external view returns(uint256);
    function priceOfPct() external view returns(uint256);
    function tokenAmountPctToMint(address _token, uint256 _profit) external view returns(uint256);
    function getAmountsOut(uint256 amount, address token0, address token1, address router) external view returns (uint256);
    function wNativeRelayer() external view returns (address);
    function rabbitCalculator() external view returns(IRabbitCalculator);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/SafeERC20.sol";
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPriceCalculator {
    function getAmountsOut(uint256 amount, address[] memory path) external view returns (uint256);
    function pricesInUSD(address[] memory assets) external view returns (uint256[] memory);
    function valueOfAsset(address asset, uint256 amount) external view returns (uint256 valueInBNB, uint256 valueInUSD);
    function priceOfBNB() external view returns (uint256);
    function priceOfCake() external view returns (uint256);
    function priceOfPct() external view returns (uint256);
    function priceOfToken(address token) external view returns(uint256);
    function pctToken() external view returns(address);
}

interface IAlpacaCalculator {
    function balanceOf(address vault, uint256 pid, address account) external view returns(uint256);
    function balanceOfib(address vault, uint256 pid, address account) external view returns(uint256);
    function vaultApr(address vault, uint256 pid) external view returns(uint256 _apr, uint256 _alpacaApr);
    function ibTokenCalculation(address vault, uint256 amount) external view returns(uint256);
}

interface IWexCalculator {
    function wexPoolDailyApr() external view returns(uint256);
}

interface IMdexCalculator {
    function mdexPoolDailyApr() external view returns(uint256);
}

interface IRabbitCalculator {
    function balanceOf(address token, uint256 pid, address account) external view returns(uint256);
    function balanceOfib(uint256 pid, address account) external view returns(uint256);
    function vaultApr(address token, uint256 pid) external view returns(uint256 _apr, uint256 _rabbitApr);
    function ibToken(address token) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

enum StakeType {
    None,
    Alpaca_Wex,
    Cake_Wex,
    RewardsCake_Wex,
    PCTPair,
    Rabbit_Mdex,
    Cake_Mdex,
    RewardsCake_Mdex
}

interface IPineconeFarm {
    function add(uint256 _allocPCTPoint, address _want, bool _withUpdate, address _strat) external returns(uint256);
    function set(uint256 _pid, uint256 _allocPCTPoint, bool _withUpdate) external;
    function setMinter(address _minter, bool _canMint) external;
    function mintForProfit(address _to, uint256 _cakeProfit, bool _updatePCTRewards) external returns(uint256);
    function stakeRewardsTo(address _to, uint256 _amount) external;
    function setCakeRewardsPid(uint256 _cakeRewardsPid) external;
    function setPctPerBlock(uint256 _PCTPerBlock, uint256 _startBlock) external;
    function amountPctToMint(uint256 _bnbProfit) external view returns (uint256);
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function dailyEarnedAmount(uint256 _pid) external view returns(uint256);
    function pineconeStratAddress(uint256 _pid) external view returns(address);
    function poolInfoOf(uint256 _pid) external view returns(address want, address strat);
    function userInfoOfPool(uint256 _pid, address _user) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function claimBNB() external;
}

interface IPineconeStrategy {
    function earn() external;
    function farm() external;
    function pause() external;
    function unpause() external;
    function sharesTotal() external view returns (uint256);
    function sharesOf(address _user) external view returns(uint256);
    function withdrawableBalanceOf(address _user) external view returns(uint256);
    function deposit(uint256 _wantAmt, address _user) external returns(uint256);
    function depositForPresale(uint256 _wantAmt, address _user) external returns(uint256);
    function withdraw(uint256 _wantAmt, address _user) external returns(uint256, uint256);
    function withdrawAll(address _user) external returns(uint256, uint256, uint256);
    function claim(address _user) external returns(uint256, uint256);
    function claimBNB(uint256 shares, address _user) external returns(uint256);
    function pendingBNB(uint256 _shares, address _user) external view returns(uint256);
    function stakeType() external view returns(StakeType);
    function earned0Address() external view returns(address);
    function earned1Address() external view returns(address);
    function performanceFee(uint256 _profit) external view returns(uint256);
    function stratAddress() external view returns(address);
    function tvl() external view returns(uint256 priceInUsd);
    function farmPid() external view returns(uint256);
    function userInfoOf(address _user, uint256 _addPct) external view 
        returns(
            uint256 depositedAt, 
            uint256 depositAmt,
            uint256 balanceValue,
            uint256 earned0Amt,
            uint256 earned1Amt,
            uint256 withdrawbaleAmt
        ); 
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function stakingToken() external view returns(address);
    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) external;
}

interface IOwner {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBoardRoomMDX {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pending(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() view external returns(uint256);
    function totalAllocPoint() view external returns(uint256);

    function poolInfo(uint256 _pid) view external returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare);
    function userInfo(uint256 _pid, address _account) view external returns(uint256 amount, uint256 rewardDebt);
    function poolLength() view external returns(uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) view external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWNativeRelayer {
  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

