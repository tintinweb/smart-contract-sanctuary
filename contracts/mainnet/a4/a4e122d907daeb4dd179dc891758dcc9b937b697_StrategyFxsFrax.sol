pragma solidity ^0.6.7;

import "./StrategyStakingRewardsBase.sol";
import "./IStakingRewards.sol";

abstract contract StrategyFraxFarmBase is StrategyStakingRewardsBase {
    
    // FXS reward staking contracts
    address public FXS_FRAX_UNI_STAKING_CONTRACT = 0xda2c338350a0E59Ce71CDCED9679A3A590Dd9BEC;
    address public FXS_FRAX_SUSHI_STAKING_CONTRACT = 0x35302f77E5Bd7A93cbec05d585e414e14B2A84a8;

    // Token addresses
    address public fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public frax = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    // LP Token addresses
    address public FXS_FRAX_UNI_LP = 0xE1573B9D29e2183B1AF0e743Dc2754979A40D237;
    address public FXS_FRAX_SUSHI_LP = 0xc218001e3D102e3d1De9bf2c0F7D9626d76C6f30;

    // 15% performance fee to pay for gas (est. cost of calling harvest() is $100+), remainder will be staked
    uint256 public keepFXS = 1500;
    uint256 public constant keepFXSmax = 10000;

    // Uniswap swap paths
    address[] public fxs_frax_path;
    address[] public sushi_fxs_path;

    constructor(
        address _stakingContract,
        address _want,
        address _strategist
    )
        public
        StrategyStakingRewardsBase(
            _stakingContract,
            _want,
            _strategist
        )
    {
        fxs_frax_path = new address[](2);
        fxs_frax_path[0] = fxs;
        fxs_frax_path[1] = frax;

        sushi_fxs_path = new address[](3);
        sushi_fxs_path[0] = sushi;
        sushi_fxs_path[1] = weth;
        sushi_fxs_path[2] = fxs;
    }

    // **** State Mutations ****

    function harvest() public override onlyOwner {
        // Collects FXS tokens
        IStakingRewards(stakingContract).getReward();
        
        //Swap 1/2 of FXS for Frax
        uint256 _fxsBalance = IERC20(fxs).balanceOf(address(this));
        if (_fxsBalance > 0) {
            _swapUniswapWithPath(fxs_frax_path, _fxsBalance.div(2));
        }
        
        // Add liquidity for FXS/FRAX
        uint256 _frax = IERC20(frax).balanceOf(address(this));
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_frax > 0 && _fxs > 0) {
            //should be no danger in giving the router infinite approval, the Curve depositer does the same thing
            //IERC20(frax).safeApprove(currentRouter, 0);
            //IERC20(frax).safeApprove(currentRouter, _frax);
            //IERC20(fxs).safeApprove(currentRouter, 0);
            //IERC20(fxs).safeApprove(currentRouter, _fxs);

            IUniswapRouterV2(currentRouter).addLiquidity(
                frax,
                fxs,
                _frax,
                _fxs,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            // Costs more to claim dust than it's worth 
            /*IERC20(frax).safeTransfer(
                strategist,
                IERC20(frax).balanceOf(address(this))
            );
            IERC20(fxs).safeTransfer(
                strategist,
                IERC20(fxs).balanceOf(address(this))
            );*/
        }

        //Send performance fee to strategist
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 performanceFee = _want.mul(keepFXS).div(keepFXSmax);
            IERC20(want).safeTransfer(
                strategist,
                performanceFee
            );
        }

        // Stake the LP tokens
        // We don't ever distribute the performance fee in _distributePerformanceFeesAndDeposit(), it should be renamed tbh
        _distributePerformanceFeesAndDeposit();
    }

    //Due to the lower total value of Sushi tokens farmed, converting Sushi to FXS/FRAX LP has been split into a different function to save gas
    function exchangeSushiForUnderlying() public onlyOwner {
        //Swap Sushi to FXS (routed through Sushi -> ETH -> FXS)
        uint256 _sushiBalance = IERC20(sushi).balanceOf(address(this));
        if (_sushiBalance > 0) {
            _swapUniswapWithPath(sushi_fxs_path, _sushiBalance);
        }
        
        //Swap 1/2 of FXS for Frax
        uint256 _fxsBalance = IERC20(fxs).balanceOf(address(this));
        if (_fxsBalance > 0) {
            _swapUniswapWithPath(fxs_frax_path, _fxsBalance.div(2));
        }
        
        // Add liquidity for FXS/FRAX
        uint256 _frax = IERC20(frax).balanceOf(address(this));
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_frax > 0 && _fxs > 0) {
            IUniswapRouterV2(currentRouter).addLiquidity(
                frax,
                fxs,
                _frax,
                _fxs,
                0,
                0,
                address(this),
                now + 60
            );
        }

        //Send performance fee to strategist
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 performanceFee = _want.mul(keepFXS).div(keepFXSmax);
            IERC20(want).safeTransfer(
                strategist,
                performanceFee
            );
        }

        // Stake the LP tokens
        // We don't ever distribute the performance fee in _distributePerformanceFeesAndDeposit(), it should be renamed tbh
        _distributePerformanceFeesAndDeposit();
    }

    function salvage(address recipient, address token, uint256 amount) public onlyOwner {
        //Sushi is the only token that will remain in this contract in any sizable amount after any function calls, so block it from being salvaged
        require(token != sushi);
        IERC20(token).safeTransfer(recipient, amount);
    }

    function migrate() external {
        require(msg.sender == jar, "unauthorized");
        //Withdraw all staked tokens and remove FXS/FRAX liquidity from Uniswap
        _withdrawSome(balanceOfPool());
        uint256 amount = IERC20(FXS_FRAX_UNI_LP).balanceOf(address(this));

        IERC20(FXS_FRAX_UNI_LP).safeApprove(uniRouter, 0);
        IERC20(FXS_FRAX_UNI_LP).safeApprove(uniRouter, amount);
        IUniswapRouterV2(uniRouter).removeLiquidity(
                fxs,
                frax,
                amount,
                0,
                0,
                address(this),
                now + 60
            );

        //Change from Uniswap to Sushiswap
        currentRouter = sushiRouter;
        stakingContract = FXS_FRAX_SUSHI_STAKING_CONTRACT;
        want = FXS_FRAX_SUSHI_LP;

        // Add FXS/FRAX liquidity to Sushiswap
        uint256 _frax = IERC20(frax).balanceOf(address(this));
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        IUniswapRouterV2(sushiRouter).addLiquidity(
                frax,
                fxs,
                _frax,
                _fxs,
                0,
                0,
                address(this),
                now + 60
            );

        //Deposit to FXS_FRAX_SUSHI_STAKING_CONTRACT
        deposit();
    }
}

contract StrategyFxsFrax is StrategyFraxFarmBase {

    constructor(address _strategist)
        public
        StrategyFraxFarmBase(
            FXS_FRAX_UNI_STAKING_CONTRACT,
            FXS_FRAX_UNI_LP,
            _strategist
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyFxsFrax";
    }

    //Give the Uniswap and Sushiswap routers infinite approval to save gas, since they are known not to be malicious
    function approveForever() public onlyOwner {
        IERC20(frax).approve(uniRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        IERC20(fxs).approve(uniRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        IERC20(frax).approve(sushiRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        IERC20(fxs).approve(sushiRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        IERC20(sushi).approve(sushiRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }
}