// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import './SafeMath.sol';
import './IERC20.sol';
import './ERC20.sol';
import './SafeERC20.sol';
import './Address.sol';
import './EnumerableSet.sol';
import './Context.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './Pausable.sol';
import './IUniRouter02.sol';

interface IDragonLair {
    function enter(uint256 _quickAmount) external ;

    function leave(uint256 _dQuickAmount) external ;

    // returns the total amount of QUICK an address has in the contract including fees earned
    function QUICKBalance(address _account) external view returns (uint256 ) ;

    //returns how much QUICK someone gets for depositing dQUICK
    function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint256 ) ;

    //returns how much dQUICK someone gets for depositing QUICK
    function QUICKForDQUICK(uint256 _quickAmount) external view returns (uint256 );
}

 interface IBitGuruFarm {
    function   setAccBonus(uint256 _pid,uint256 _bonusAmt) external ;
    function   GetLastDepositBlock (uint256 _pid,address _user)  external view returns (uint256);

    }

contract Strat_Guru is Ownable, ReentrancyGuard, Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public farmContractAddress; // address of farm, eg, Hecopool,PCS, Thugs etc.
    uint256 public pid; // pid of pool
    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    address public uniRouterAddress; // uniswap, pancakeswap,mdex etc

    address public constant midAddress =0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;//wmatic

    address public GuruFarmAddress;
    address public GuruAddress;
    address public govAddress = 0xb53A994eC9f46889D85F33a2953453FF405Ce6a0; //
    address public govTGSAddress = 0xb53A994eC9f46889D85F33a2953453FF405Ce6a0; //TGS
    address public rewardsMigratorAddress = 0x50F62f2E3d168b77d29dA2ACd47609731772fD2a;
    bool public onlyGov = true;
    bool public half = true;

    uint256 public lastEarnBlock = 0;
    uint256 public lastQuickdQuickRate = 0;
    uint256 public QuickdQuickRateDeltaPerBlock = 0;
    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 110;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300;

    uint256 public buyBackRate = 800;
    uint256 public constant buyBackRateMax = 10000; // 100 = 1%
    uint256 public constant buyBackRateUL = 3000;
    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public bonusRate = 2000;
    uint256 public constant bonusRateMax = 10000; // 100 = 1%
    uint256 public constant bonusRateUL = 3000;
    address public bonusToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;//wmatic
    address public Quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;//Quick

    uint256 public entranceFeeFactor = 10000; // < 0.1% entrance fee - goes to pool + prevents front-running
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public withdrawFeeFactor = 9950; // 0.1% withdraw fee - goes to pool
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9500; //

    uint256 public shortTimewithdrawFeeFactor = 10000; // 0.1% withdraw fee - goes to pool
    uint256 public constant shortTimewithdrawFeeFactorMax = 10000;
    uint256 public constant shortTimewithdrawFeeFactorLL = 9900; //

    uint256 public depositTimeFactor = 129600;
    uint256 public depositTimeFactorMAX = 23328000;

    address[] public earnedToGuruPath;
    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;
    address[] public  QuickToGuruPath ;

    constructor(
        address _GuruFarmAddress,
        address _GuruAddress,
        address _farmContractAddress,
        uint256 _pid,
        address _wantAddress,
        address _earnedAddress,
        address _uniRouterAddress
    ) public {

        GuruFarmAddress = _GuruFarmAddress;
        GuruAddress = _GuruAddress;
        farmContractAddress = _farmContractAddress;
        pid = _pid;
        wantAddress = _wantAddress;
        earnedAddress = _earnedAddress;
        uniRouterAddress = _uniRouterAddress;
        QuickToGuruPath =  [Quick,midAddress,GuruAddress];
        transferOwnership(GuruFarmAddress);
    }

    // Receives new deposits from user
    function deposit(address _userAddress, uint256 _wantAmt)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        uint256  entrancewantAmt = _wantAmt
                                .mul(entranceFeeFactor)
                                .div(entranceFeeFactorMax);
        uint256  entranceFee = _wantAmt.sub(entrancewantAmt);
         if(entranceFee>0)
         {
            IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , entranceFee);
         }

        _wantAmt = entrancewantAmt;
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if(_wantAmt<wantAmt)
        {
            uint256 plus  = wantAmt.sub(_wantAmt);
            IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , plus);
        }
        else
        {
            _wantAmt = wantAmt;
        }

        uint256 sharesAdded =   IDragonLair(farmContractAddress).QUICKForDQUICK(_wantAmt);

        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, _wantAmt);
        IDragonLair(farmContractAddress).enter(_wantAmt);


        sharesTotal = sharesTotal.add(sharesAdded);
        wantLockedTotal = IDragonLair(farmContractAddress).dQUICKForQUICK(sharesTotal);
        return sharesAdded;
    }

    function withdraw(address _userAddress, uint256 _wantAmt)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");


        uint256 dQuickAmttoWithdraw =IDragonLair(farmContractAddress).QUICKForDQUICK(_wantAmt);
        wantLockedTotal = IDragonLair(farmContractAddress).dQUICKForQUICK(sharesTotal);
        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }
        IDragonLair(farmContractAddress).leave( dQuickAmttoWithdraw);

        uint256  withdrawFee = 0;

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            withdrawFee = _wantAmt.sub(_wantAmt.mul(withdrawFeeFactor).div(
                withdrawFeeFactorMax));
            if(withdrawFee>0)
            {
                if(half)
                {
                    buyBack(withdrawFee.div(2));
                    IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee.div(2));
                }
                else
                {
                    IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee);
                }

            }

            _wantAmt = _wantAmt.sub(withdrawFee);
        }

        if(shortTimewithdrawFeeFactor<shortTimewithdrawFeeFactorMax)
        {

            uint256 lstDblk = IBitGuruFarm(GuruFarmAddress).GetLastDepositBlock(pid,_userAddress);
            if((block.number)<  lstDblk.add(depositTimeFactor)  && lstDblk>0)
            {
                withdrawFee = _wantAmt.sub(_wantAmt.mul(shortTimewithdrawFeeFactor).div(shortTimewithdrawFeeFactorMax));
                if(withdrawFee>0)
                {
                    if(half)
                    {
                        buyBack(withdrawFee.div(2));
                        IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee.div(2));
                    }
                    else
                    {
                        IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee);
                    }
                }
                _wantAmt = _wantAmt.sub(withdrawFee);

            }

        }
        uint256 sharesRemoved = dQuickAmttoWithdraw;
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        wantLockedTotal = IDragonLair(farmContractAddress).dQUICKForQUICK(sharesTotal);

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if(_wantAmt<wantAmt)
        {
            uint256 plus  = wantAmt.sub(_wantAmt);
            IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , plus);
        }
        else
        {
            _wantAmt = wantAmt;
        }
        IERC20(wantAddress).safeTransfer(GuruFarmAddress, _wantAmt);

        return sharesRemoved;
    }

    //in fact,calc apr factor
    function earn() external whenNotPaused {

        if (onlyGov) {
            require(msg.sender == govAddress, "Not authorised");
        }

        wantLockedTotal = IDragonLair(farmContractAddress).dQUICKForQUICK(sharesTotal);
        uint256 nowBlock =  block.number;
        uint256 QuickdQuickRate =  wantLockedTotal.mul(1000000000).div(sharesTotal);
        if( (nowBlock>lastEarnBlock.add(150)) && QuickdQuickRate>lastQuickdQuickRate.add(1))
        {
            QuickdQuickRateDeltaPerBlock = (QuickdQuickRate.sub(lastQuickdQuickRate)).div(nowBlock.sub(lastEarnBlock));
            lastEarnBlock = nowBlock;
            lastQuickdQuickRate = QuickdQuickRate;
        }

    }

    function buyBack( uint256 bonus) internal  {

        if (bonus > 0) {

                IERC20(Quick).safeIncreaseAllowance(
                        uniRouterAddress,
                        bonus
                    );
                IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        bonus,
                         0,
                        QuickToGuruPath,
                        buyBackAddress,
                        now + 60 );

        }

    }

    function pause() external {
        require(msg.sender == govAddress, "Not authorised");
        _pause();
    }

    function unpause() external {
        require(msg.sender == govAddress, "Not authorised");
        _unpause();
    }

    function setEntranceFeeFactor(uint256 _entranceFeeFactor) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_entranceFeeFactor > entranceFeeFactorLL, "!safe - too low");
        require(_entranceFeeFactor <= entranceFeeFactorMax, "!safe - too high");
        entranceFeeFactor = _entranceFeeFactor;
    }

    function setWithdrawFeeFactor(uint256 _withdrawFeeFactor) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_withdrawFeeFactor > withdrawFeeFactorLL, "!safe - too low");
        require(_withdrawFeeFactor <= withdrawFeeFactorMax, "!safe - too high");
        withdrawFeeFactor = _withdrawFeeFactor;
    }

    function setShortWithdrawFeeFactor(uint256 _shortTimewithdrawFeeFactor) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_shortTimewithdrawFeeFactor > shortTimewithdrawFeeFactorLL, "!safe - too low");
        require(_shortTimewithdrawFeeFactor <= shortTimewithdrawFeeFactorMax, "!safe - too high");
        shortTimewithdrawFeeFactor = _shortTimewithdrawFeeFactor;
    }

    function setGov(address _govAddress) external {
        require(msg.sender == govAddress, "!gov");
        govAddress = _govAddress;
    }

    function setOnlyGov(bool _onlyGov) external {
        require(msg.sender == govAddress, "!gov");
        onlyGov = _onlyGov;
    }
      function setHalf(bool _half) external {
        require(msg.sender == govAddress, "!gov");
        half = _half;
    }

    function setRewardsMigratorAddress(address _rewardsMigratorAddress) external {
        require(msg.sender == govAddress, "!gov");
        require(_rewardsMigratorAddress != address(0), "zero address");
        rewardsMigratorAddress = _rewardsMigratorAddress;
    }

     function setGovTGS(address _govTGSAddress) external {
        require(msg.sender == govTGSAddress, "!govTGS");
        govTGSAddress = _govTGSAddress;
    }

    function inCaseTokensGetStuck( address _token,uint256 _amount,address _to) external {
        require(msg.sender == govTGSAddress, "!govTGS");
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

   function setDepositTimeFactor(uint256 _depositTimeFactor) external {
        require(_depositTimeFactor <= depositTimeFactorMAX, "Not authorised");
        require(msg.sender == govAddress, "Not authorised");
        depositTimeFactor = _depositTimeFactor;
    }
}