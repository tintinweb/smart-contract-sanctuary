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

import './IStakingRewards.sol';
import './IUniRouter02.sol';

 interface IBitGuruFarm {
    function   setAccBonus(uint256 _pid,uint256 _bonusAmt) external ;
    function   GetLastDepositBlock (uint256 _pid,address _user)  external view returns (uint256);

    }

contract Strat_Guru is Ownable, ReentrancyGuard, Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isAutoComp; //

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

    uint256 public lastEarnBlock = 0;
    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 110;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300;

    uint256 public buyBackRate = 2500;
    uint256 public constant buyBackRateMax = 10000; // 100 = 1%
    uint256 public constant buyBackRateUL = 3000;
    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public bonusRate = 500;
    uint256 public constant bonusRateMax = 10000; // 100 = 1%
    uint256 public constant bonusRateUL = 3000;
    address public bonusToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;//wmatic

    uint256 public entranceFeeFactor = 9990; // < 0.1% entrance fee - goes to pool + prevents front-running
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public withdrawFeeFactor = 10000; // 0.1% withdraw fee - goes to pool
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9950; //

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
    address[] public  earnedToBonusPath ;



    constructor(

        address _GuruFarmAddress,
        address _GuruAddress,

        bool _isAutoComp,
        address _farmContractAddress,
        uint256 _pid,
        address _wantAddress,
        address _token0Address,
        address _token1Address,
        address _earnedAddress,


        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        address _uniRouterAddress
    ) public {

        GuruFarmAddress = _GuruFarmAddress;
        GuruAddress = _GuruAddress;


        isAutoComp = _isAutoComp;
        wantAddress = _wantAddress;
        earnedAddress = _earnedAddress;
        pid = _pid;

        if (isAutoComp) {

            token0Address = _token0Address;
            token1Address = _token1Address;


            farmContractAddress = _farmContractAddress;



            uniRouterAddress = _uniRouterAddress;

            earnedToGuruPath = [earnedAddress, midAddress, GuruAddress];
            if (midAddress == earnedAddress) {
                earnedToGuruPath = [midAddress, GuruAddress];
            }
            earnedToBonusPath =  [earnedAddress,bonusToken];

            earnedToToken0Path = _earnedToToken0Path;
            earnedToToken1Path = _earnedToToken1Path;

            token0ToEarnedPath = _token0ToEarnedPath;

            token1ToEarnedPath = _token1ToEarnedPath;

        }

        transferOwnership(GuruFarmAddress);
    }

    // Receives new deposits from user
    function deposit(address _userAddress, uint256 _wantAmt)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        uint256 balBefore = IERC20(wantAddress).balanceOf(address(this));
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );
        _wantAmt  = IERC20(wantAddress).balanceOf(address(this)).sub(balBefore);
        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0) {

            uint256  entrancewantAmt = _wantAmt
                                .mul(entranceFeeFactor)
                                .div(entranceFeeFactorMax);
            uint256  entranceFee = _wantAmt.sub(entrancewantAmt);
            IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , entranceFee);

            _wantAmt = entrancewantAmt;

            sharesAdded = _wantAmt
                .mul(sharesTotal)
                .div(wantLockedTotal);

        }
        sharesTotal = sharesTotal.add(sharesAdded);

        if (isAutoComp) {
            _farm();
        } else {
            wantLockedTotal = wantLockedTotal.add(_wantAmt);
        }

        return sharesAdded;
    }

    function farm() public nonReentrant {
        _farm();
    }

    function _farm() internal {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        IStakingRewards(farmContractAddress).stake( wantAmt);
    }

    function withdraw(address _userAddress, uint256 _wantAmt)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");


        if (isAutoComp) {

             IStakingRewards(farmContractAddress).withdraw(_wantAmt);
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);
        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        uint256  withdrawFee = 0;

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            withdrawFee = _wantAmt.sub(_wantAmt.mul(withdrawFeeFactor).div(
                withdrawFeeFactorMax));
            if(withdrawFee>0)
            {
                IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee);
            }

            _wantAmt = _wantAmt.sub(withdrawFee);
        }

        uint256 lstDblk = IBitGuruFarm(GuruFarmAddress).GetLastDepositBlock(pid,_userAddress);

        if((block.number)<  lstDblk.add(depositTimeFactor)  && lstDblk>0 && shortTimewithdrawFeeFactor<shortTimewithdrawFeeFactorMax)
        {
            withdrawFee = _wantAmt.sub(_wantAmt.mul(shortTimewithdrawFeeFactor).div(
                shortTimewithdrawFeeFactorMax));
            if(withdrawFee>0)
            {
                IERC20(wantAddress).safeTransfer(rewardsMigratorAddress , withdrawFee);
            }
            _wantAmt = _wantAmt.sub(withdrawFee);

        }

        wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        IERC20(wantAddress).safeTransfer(GuruFarmAddress, _wantAmt);

        return sharesRemoved;
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens
    function earn(uint256 poolid) external whenNotPaused returns (uint256) {
        require(isAutoComp, "!isAutoComp");
        if (onlyGov) {
            require(msg.sender == govAddress, "Not authorised");
        }

       // Harvest farm tokens


        IStakingRewards(farmContractAddress).getReward();

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);
        uint256 bonus = earnedAmt;//fhxg
        earnedAmt = distributeBonus(poolid,earnedAmt);
        bonus = bonus.sub(earnedAmt);//fhxg
        earnedAmt = buyBack(earnedAmt);



        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            earnedAmt
        );

        if (earnedAddress != token0Address) {
            // Swap half earned to token0
            //IPancakeRouter02(uniRouterAddress)

            IUniRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                earnedAmt.div(2),
                0,
                earnedToToken0Path,
                address(this),
                now + 60
            );
        }

        if (earnedAddress != token1Address) {
            // Swap half earned to token1
            //IPancakeRouter02(uniRouterAddress)
            IUniRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                earnedAmt.div(2),
                0,
                earnedToToken1Path,
                address(this),
                now + 60
            );
        }

        // Get want tokens, ie. add liquidity
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );
            //IPancakeRouter02(uniRouterAddress).addLiquidity(
            IUniRouter02(uniRouterAddress).addLiquidity(
                token0Address,
                token1Address,
                token0Amt,
                token1Amt,
                0,
                0,
                address(this),
                now + 60
            );
        }

        lastEarnBlock = block.number;

        _farm();
        return bonus;
    }


    function buyBack(uint256 _earnedAmt) internal returns (uint256) {
        if (buyBackRate <= 0) {
            return _earnedAmt;
        }

        uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            buyBackAmt
        );

        //IPancakeRouter02(uniRouterAddress)
        IUniRouter02(uniRouterAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            buyBackAmt,
            0,
            earnedToGuruPath,
            buyBackAddress,
            now + 60
        );

        return _earnedAmt.sub(buyBackAmt);
    }

    function distributeFees(uint256 _earnedAmt) internal returns (uint256) {
        if (_earnedAmt > 0) {
            // Performance fee
            if (controllerFee > 0) {
                uint256 fee =
                    _earnedAmt.mul(controllerFee).div(controllerFeeMax);
                IERC20(earnedAddress).safeTransfer(rewardsMigratorAddress, fee);
                _earnedAmt = _earnedAmt.sub(fee);

            }

        }

        return _earnedAmt;
    }
    function distributeBonus(uint256 poolid,uint256 _earnedAmt) internal returns (uint256) {

        if (_earnedAmt > 0) {
            // Performance fee
            if (bonusRate > 0) {

                //分红
                uint256 bonus =
                    _earnedAmt.mul(bonusRate).div(bonusRateMax);



                if (earnedAddress != bonusToken) {
                    IERC20(earnedAddress).safeIncreaseAllowance(
                        uniRouterAddress,
                        bonus
                    );
                    IUniRouter02(uniRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        bonus,
                         0,
                        earnedToBonusPath,
                        address(this),
                        now + 60 );

                }
                uint256 bonusTokenNum = IERC20(bonusToken).balanceOf(address(this));

                IERC20(bonusToken).safeTransfer(GuruFarmAddress, bonusTokenNum);
                IBitGuruFarm(GuruFarmAddress).setAccBonus(poolid,bonusTokenNum);
                _earnedAmt = _earnedAmt.sub(bonus);

            }

        }
        return _earnedAmt;
    }

    function convertDustToEarned() external whenNotPaused {
        require(isAutoComp, "!isAutoComp");
       if (onlyGov) {
            require(msg.sender == govAddress, "Not authorised");
        }

        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Address != earnedAddress && token0Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );

            // Swap all dust tokens to earned tokens
            //IPancakeRouter02(uniRouterAddress)
            IUniRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token0Amt,
                0,
                token0ToEarnedPath,
                address(this),
                now + 60
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Address != earnedAddress && token1Amt > 0) {
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );

            // Swap all dust tokens to earned tokens
            //IPancakeRouter02(uniRouterAddress)
            IUniRouter02(uniRouterAddress)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                token1Amt,
                0,
                token1ToEarnedPath,
                address(this),
                now + 60
            );
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
    function setDepositTimeFactor(uint256 _depositTimeFactor) external {

        require(_depositTimeFactor <= depositTimeFactorMAX, "Too High");
        require(msg.sender == govAddress, "Not authorised");
        depositTimeFactor = _depositTimeFactor;
    }


    function setControllerFee(uint256 _controllerFee) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_controllerFee <= controllerFeeUL, "too high");
        controllerFee = _controllerFee;
    }

    function setbuyBackRate(uint256 _buyBackRate) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_buyBackRate <= buyBackRateUL, "too high");
        buyBackRate = _buyBackRate;
    }

    function setbonusRate(uint256 _bonusRate) external {
        require(msg.sender == govAddress, "Not authorised");
        require(_bonusRate <= bonusRateUL, "too high");
        bonusRate = _bonusRate;
    }

    function setGov(address _govAddress) external {
        require(msg.sender == govAddress, "!gov");
        govAddress = _govAddress;
    }

    function setBonusToken(address _bonusToken) external {
        require(msg.sender == govAddress, "!gov");
        bonusToken = _bonusToken;
        earnedToBonusPath =  [earnedAddress,bonusToken];
    }

    function setOnlyGov(bool _onlyGov) external {
        require(msg.sender == govAddress, "!gov");
        onlyGov = _onlyGov;
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



}