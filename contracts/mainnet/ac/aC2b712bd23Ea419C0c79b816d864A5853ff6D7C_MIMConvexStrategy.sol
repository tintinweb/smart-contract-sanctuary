// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IConvexVault.sol';
import '../interfaces/ICurvePool.sol';
import '../interfaces/IStableSwap2Pool.sol';
import '../interfaces/IStableSwap3Pool.sol';
import './BaseStrategy.sol';
import '../interfaces/ExtendedIERC20.sol';
import '../interfaces/ICVXMinter.sol';
import '../interfaces/IHarvester.sol';

contract MIMConvexStrategy is BaseStrategy {
    // used for Crv -> weth -> [mim/3crv] -> mimCrv route
    address public immutable crv;
    address public immutable cvx;

    address public immutable mim;
    address public immutable crv3;

    uint256 public immutable pid;
    IConvexVault public immutable convexVault;
    address public immutable mimCvxDepositLP;
    IConvexRewards public immutable crvRewards;
    IStableSwap2Pool public immutable stableSwap2Pool;
    IStableSwap3Pool public immutable stableSwap3Pool;

    /**
     * @param _name The strategy name
     * @param _want The desired token of the strategy
     * @param _crv The address of CRV
     * @param _cvx The address of CVX
     * @param _weth The address of WETH
     * @param _mim The address of MIM
     * @param _crv3 The address of 3CRV
     * @param _stableSwap3Pool The address of the 3CRV pool
     * @param _pid The pool id of convex
     * @param _convexVault The address of the convex vault
     * @param _stableSwap2Pool The address of the stable swap pool
     * @param _controller The address of the controller
     * @param _manager The address of the manager
     * @param _routerArray The address array of routers for swapping tokens
     */
    constructor(
        string memory _name,
        address _want,
        address _crv,
        address _cvx,
        address _weth,
        address _mim,
        address _crv3,
        IStableSwap3Pool _stableSwap3Pool,
        uint256 _pid,
        IConvexVault _convexVault,
        IStableSwap2Pool _stableSwap2Pool,
        address _controller,
        address _manager,
        address[] memory _routerArray
    ) public BaseStrategy(_name, _controller, _manager, _want, _weth, _routerArray) {
        require(address(_crv) != address(0), '!_crv');
        require(address(_cvx) != address(0), '!_cvx');
        require(address(_mim) != address(0), '!_mim');
        require(address(_crv3) != address(0), '!_crv3');
        require(address(_convexVault) != address(0), '!_convexVault');
        require(address(_stableSwap2Pool) != address(0), '!_stableSwap2Pool');
        require(address(_stableSwap3Pool) != address(0), '!_stableSwap3Pool');

        (, address _token, , address _crvRewards, , ) = _convexVault.poolInfo(_pid);
        crv = _crv;
        cvx = _cvx;
        mim = _mim;
        crv3 = _crv3;
        pid = _pid;
        convexVault = _convexVault;
        mimCvxDepositLP = _token;
        crvRewards = IConvexRewards(_crvRewards);
        stableSwap2Pool = _stableSwap2Pool;
        stableSwap3Pool = _stableSwap3Pool;
        // Required to overcome "Stack Too Deep" error
        _setApprovals(
            _want,
            _crv,
            _cvx,
            _mim,
            _crv3,
            address(_convexVault),
            address(_stableSwap2Pool),
            _routerArray
        );
        _setApprovals3crv(address(_stableSwap3Pool));
    }
    
    function _setApprovals3crv(address _stableSwap3Pool) internal {
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(0)).safeApprove(_stableSwap3Pool, type(uint256).max);
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(1)).safeApprove(_stableSwap3Pool, type(uint256).max);
        IERC20(IStableSwap3Pool(_stableSwap3Pool).coins(2)).safeApprove(_stableSwap3Pool, type(uint256).max);    	
    }

    function _setApprovals(
        address _want,
        address _crv,
        address _cvx,
        address _mim,
        address _crv3,
        address _convexVault,
        address _stableSwap2Pool,
        address[] memory _routerArray
    ) internal {
        IERC20(_want).safeApprove(address(_convexVault), type(uint256).max);
        for(uint i=0; i<_routerArray.length; i++) {
            address _router = _routerArray[i];
            IERC20(_crv).safeApprove(address(_router), 0);
            IERC20(_crv).safeApprove(address(_router), type(uint256).max);
            IERC20(_cvx).safeApprove(address(_router), 0);
            IERC20(_cvx).safeApprove(address(_router), type(uint256).max);
        }
        IERC20(_mim).safeApprove(address(_stableSwap2Pool), type(uint256).max);
        IERC20(_crv3).safeApprove(address(_stableSwap2Pool), type(uint256).max);
        IERC20(_want).safeApprove(address(_stableSwap2Pool), type(uint256).max);
    }

    function _deposit() internal override {
        if (balanceOfWant() > 0) {
            convexVault.depositAll(pid, true);
        }
    }

    function _claimReward() internal {
        crvRewards.getReward(address(this), true);
    }

    function _addLiquidity(uint256 estimate) internal {
        uint256[2] memory amounts;
        amounts[1] = IERC20(crv3).balanceOf(address(this));
        stableSwap2Pool.add_liquidity(amounts, estimate);
    }

    function _addLiquidity3CRV(uint256 estimate) internal {
        uint256[3] memory amounts;
        (address targetCoin, uint256 targetIndex) = getMostPremium();
        amounts[targetIndex] = IERC20(targetCoin).balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, estimate);
    }

    function getMostPremium() public view returns (address, uint256) {
        uint256 daiBalance = stableSwap3Pool.balances(0);
        uint256 usdcBalance = (stableSwap3Pool.balances(1)).mul(10**18).div(ExtendedIERC20(stableSwap3Pool.coins(1)).decimals());
        uint256 usdtBalance = (stableSwap3Pool.balances(2)).mul(10**12); 

        if (daiBalance <= usdcBalance && daiBalance <= usdtBalance) {
            return (stableSwap3Pool.coins(0), 0);
        }

        if (usdcBalance <= daiBalance && usdcBalance <= usdtBalance) {
            return (stableSwap3Pool.coins(1), 1);
        }

        if (usdtBalance <= daiBalance && usdtBalance <= usdcBalance) {
            return (stableSwap3Pool.coins(2), 2);
        }

        return (stableSwap3Pool.coins(0), 0); // If they're somehow equal, we just want DAI
    }

    function _harvest(uint256[] calldata _estimates) internal override {
        _claimReward();
        uint256 _cvxBalance = IERC20(cvx).balanceOf(address(this));
        if (_cvxBalance > 0) {
            _swapTokens(cvx, weth, _cvxBalance, _estimates[0]);
        }

        uint256 _extraRewardsLength = crvRewards.extraRewardsLength();
        for (uint256 i = 0; i < _extraRewardsLength; i++) {
            address _rewardToken = IConvexRewards(crvRewards.extraRewards(i)).rewardToken();
            uint256 _extraRewardBalance = IERC20(_rewardToken).balanceOf(address(this));
            if (_extraRewardBalance > 0) {
                _swapTokens(_rewardToken, weth, _extraRewardBalance, _estimates[i+1]);
            }
        }
	// RouterIndex 1 sets router to Uniswap to swap WETH->YAXIS
        uint256 _remainingWeth = _payHarvestFees(crv, _estimates[_extraRewardsLength + 1], _estimates[_extraRewardsLength + 2], 1);
        if (_remainingWeth > 0) {
            (address _token, ) = getMostPremium(); // stablecoin we want to convert to
            _swapTokens(weth, _token, _remainingWeth, _estimates[_extraRewardsLength + 3]);
            _addLiquidity3CRV(_estimates[_extraRewardsLength + 4]);
            _addLiquidity(_estimates[_extraRewardsLength + 4]);
            _deposit();
        }
    }

    function getEstimates() external view returns (uint256[] memory) {
               
        uint rewardsLength = crvRewards.extraRewardsLength();
        uint256[] memory _estimates = new uint256[](rewardsLength.add(5));
        address[] memory _path = new address[](2);
        uint256[] memory _amounts;
        uint256 _notSlippage = ONE_HUNDRED_PERCENT.sub(IHarvester(manager.harvester()).slippage());
        uint256 wethAmount;

        // Estimates for CVX -> WETH
        _path[0] = cvx;
        _path[1] = weth;
        _amounts = router.getAmountsOut(
            // Calculating CVX minted
            (crvRewards.earned(address(this)))
            .mul(ICVXMinter(cvx).totalCliffs().sub(ICVXMinter(cvx).maxSupply().div(ICVXMinter(cvx).reductionPerCliff())))
            .div(ICVXMinter(cvx).totalCliffs()),
            _path
        );
        _estimates[0]= _amounts[1].mul(_notSlippage).div(ONE_HUNDRED_PERCENT);

        wethAmount += _estimates[0];

        // Estimates for extra rewards -> WETH
        
        if (rewardsLength > 0) {
            for (uint256 i = 0; i < rewardsLength; i++) {
                _path[0] = IConvexRewards(crvRewards.extraRewards(i)).rewardToken();
                _path[1] = weth;
                _amounts = router.getAmountsOut(
                    IConvexRewards(crvRewards.extraRewards(i)).earned(address(this)),
                    _path
                );
                _estimates[i + 1] = _amounts[1].mul(_notSlippage).div(ONE_HUNDRED_PERCENT);

                wethAmount += _estimates[i + 1];
            }
        }

        // Estimates for CRV -> WETH
        _path[0] = crv;
        _path[1] = weth;
        _amounts = router.getAmountsOut(
            crvRewards.earned(address(this)),
            _path
        );
        _estimates[rewardsLength + 1] = _amounts[1].mul(_notSlippage).div(ONE_HUNDRED_PERCENT);

        wethAmount += _estimates[rewardsLength + 1];

        // Estimates WETH -> YAXIS
        _path[0] = weth;
        _path[1] = manager.yaxis();
        // Set to UniswapV2 to calculate output for YAXIS
        _amounts = ISwap(routerArray[1]).getAmountsOut(wethAmount.mul(manager.treasuryFee()).div(ONE_HUNDRED_PERCENT), _path);
        _estimates[rewardsLength + 2] = _amounts[1].mul(_notSlippage).div(ONE_HUNDRED_PERCENT);
        
        // Estimates for WETH -> Stablecoin
        (address _targetCoin,) = getMostPremium(); 
        _path[0] = weth;
        _path[1] = _targetCoin;
        _amounts = router.getAmountsOut(
            wethAmount - _amounts[0],
            _path
        );
        _estimates[rewardsLength + 3] = _amounts[1].mul(_notSlippage).div(ONE_HUNDRED_PERCENT);

        // Estimates for Stablecoin -> 3CRV
        _estimates[rewardsLength + 4] = (_amounts[1].mul(10**(18-ExtendedIERC20(_targetCoin).decimals())).div(stableSwap3Pool.get_virtual_price())).mul(_notSlippage).div(ONE_HUNDRED_PERCENT);
        // Estimates for 3CRV -> MIM-3CRV is the same 3CRV estimate
        
        return _estimates;
    }

    function _withdrawAll() internal override {
        convexVault.withdrawAll(pid);
    }

    function _withdraw(uint256 _amount) internal override {
        convexVault.withdraw(pid, _amount);
    }

    function balanceOfPool() public view override returns (uint256) {
        return IERC20(mimCvxDepositLP).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IConvexVault {
    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function deposit(
        uint256 pid,
        uint256 amount,
        bool stake
    ) external returns (bool);

    function depositAll(uint256 pid, bool stake) external returns (bool);

    function withdraw(uint256 pid, uint256 amount) external returns (bool);

    function withdrawAll(uint256 pid) external returns (bool);
}

interface IConvexRewards {
    function getReward(address _account, bool _claimExtras) external returns (bool);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

    function balances(uint256) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IStableSwap2Pool {
    function get_virtual_price() external view returns (uint256);

    function balances(uint256) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

pragma solidity 0.6.12;

interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function balances(uint) external view returns (uint);
    function coins(uint) external view returns (address);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint dy);
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity(uint _amount, uint[3] calldata amounts) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IStableSwap3Pool.sol";
import "../interfaces/ISwap.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IController.sol";

/**
 * @title BaseStrategy
 * @notice The BaseStrategy is an abstract contract which all
 * yAxis strategies should inherit functionality from. It gives
 * specific security properties which make it hard to write an
 * insecure strategy.
 * @notice All state-changing functions implemented in the strategy
 * should be internal, since any public or externally-facing functions
 * are already handled in the BaseStrategy.
 * @notice The following functions must be implemented by a strategy:
 * - function _deposit() internal virtual;
 * - function _harvest() internal virtual;
 * - function _withdraw(uint256 _amount) internal virtual;
 * - function _withdrawAll() internal virtual;
 * - function balanceOfPool() public view override virtual returns (uint256);
 */
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    address public immutable override want;
    address public immutable override weth;
    address public immutable controller;
    IManager public immutable override manager;
    string public override name;
    address[] public routerArray;
    ISwap public override router;

    /**
     * @param _controller The address of the controller
     * @param _manager The address of the manager
     * @param _want The desired token of the strategy
     * @param _weth The address of WETH
     * @param _routerArray The addresses of routers for swapping tokens
     */
    constructor(
        string memory _name,
        address _controller,
        address _manager,
        address _want,
        address _weth,
        address[] memory _routerArray
    ) public {
        name = _name;
        want = _want;
        controller = _controller;
        manager = IManager(_manager);
        weth = _weth;
        require(_routerArray.length > 0, "Must input at least one router");
        routerArray = _routerArray;
        router = ISwap(_routerArray[0]);
        for(uint i = 0; i < _routerArray.length; i++) {
            IERC20(_weth).safeApprove(address(_routerArray[i]), 0);
            IERC20(_weth).safeApprove(address(_routerArray[i]), type(uint256).max);
        }
        
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Approves a token address to be spent by an address
     * @param _token The address of the token
     * @param _spender The address of the spender
     * @param _amount The amount to spend
     */
    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    )
        external
    {
        require(msg.sender == manager.governance(), "!governance");
        _token.safeApprove(_spender, 0);
        _token.safeApprove(_spender, _amount);
    }

    /**
     * @notice Sets the address of the ISwap-compatible router
     * @param _routerArray The addresses of routers
     * @param _tokenArray The addresses of tokens that need to be approved by the strategy
     */
     function setRouter(
        address[] calldata _routerArray,
        address[] calldata _tokenArray
    )
        external
    {
        require(msg.sender == manager.governance(), "!governance");
        routerArray = _routerArray;
        router = ISwap(_routerArray[0]);
        address _router;
        uint256 _routerLength = _routerArray.length;
        uint256 _tokenArrayLength = _tokenArray.length;
        for(uint i = 0; i < _routerLength; i++) {
            _router = _routerArray[i];
            IERC20(weth).safeApprove(_router, 0);
            IERC20(weth).safeApprove(_router, type(uint256).max);
            for(uint j = 0; j < _tokenArrayLength; j++) {
                IERC20(_tokenArray[j]).safeApprove(_router, 0);
                IERC20(_tokenArray[j]).safeApprove(_router, type(uint256).max);
            }
        }

    }
    
    /**
     * @notice Sets the default ISwap-compatible router
     * @param _routerIndex Gets the address of the router from routerArray
     */
     function setDefaultRouter(
        uint256 _routerIndex
    )
        external
    {
    	require(msg.sender == manager.governance(), "!governance");
    	router = ISwap(routerArray[_routerIndex]);
    }

    /**
     * CONTROLLER-ONLY FUNCTIONS
     */

    /**
     * @notice Deposits funds to the strategy's pool
     */
    function deposit()
        external
        override
        onlyController
    {
        _deposit();
    }

    /**
     * @notice Harvest funds in the strategy's pool
     */
    function harvest(
        uint256[] calldata _estimates
    )
        external
        override
        onlyController
    {
        _harvest(_estimates);
    }

    /**
     * @notice Sends stuck want tokens in the strategy to the controller
     */
    function skim()
        external
        override
        onlyController
    {
        IERC20(want).safeTransfer(controller, balanceOfWant());
    }

    /**
     * @notice Sends stuck tokens in the strategy to the controller
     * @param _asset The address of the token to withdraw
     */
    function withdraw(
        address _asset
    )
        external
        override
        onlyController
    {
        require(want != _asset, "want");

        IERC20 _assetToken = IERC20(_asset);
        uint256 _balance = _assetToken.balanceOf(address(this));
        _assetToken.safeTransfer(controller, _balance);
    }

    /**
     * @notice Initiated from a vault, withdraws funds from the pool
     * @param _amount The amount of the want token to withdraw
     */
    function withdraw(
        uint256 _amount
    )
        external
        override
        onlyController
    {
        uint256 _balance = balanceOfWant();
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(controller, _amount);
    }

    /**
     * @notice Withdraws all funds from the strategy
     */
    function withdrawAll()
        external
        override
        onlyController
    {
        _withdrawAll();

        uint256 _balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(controller, _balance);
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the strategy's balance of the want token plus the balance of pool
     */
    function balanceOf()
        external
        view
        override
        returns (uint256)
    {
        return balanceOfWant().add(balanceOfPool());
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the balance of the pool
     * @dev Must be implemented by the strategy
     */
    function balanceOfPool()
        public
        view
        virtual
        override
        returns (uint256);

    /**
     * @notice Returns the balance of the want token on the strategy
     */
    function balanceOfWant()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * INTERNAL FUNCTIONS
     */

    function _deposit()
        internal
        virtual;

    function _harvest(
        uint256[] calldata _estimates
    )
        internal
        virtual;

    function _payHarvestFees(
        address _poolToken,
        uint256 _estimatedWETH,
        uint256 _estimatedYAXIS,
        uint256 _routerIndex
    )
        internal
        returns (uint256 _wethBal)
    {
        uint256 _amount = IERC20(_poolToken).balanceOf(address(this));
        _swapTokens(_poolToken, weth, _amount, _estimatedWETH);
        _wethBal = IERC20(weth).balanceOf(address(this));

        if (_wethBal > 0) {
            // get all the necessary variables in a single call
            (
                address yaxis,
                address treasury,
                uint256 treasuryFee
            ) = manager.getHarvestFeeInfo();

            uint256 _fee;

            // pay the treasury with YAX
            if (treasuryFee > 0 && treasury != address(0)) {
                _fee = _wethBal.mul(treasuryFee).div(ONE_HUNDRED_PERCENT);

                _swapTokensWithRouterIndex(weth, yaxis, _fee, _estimatedYAXIS, _routerIndex);
                IERC20(yaxis).safeTransfer(treasury, IERC20(yaxis).balanceOf(address(this)));
            }

            // return the remaining WETH balance
            _wethBal = IERC20(weth).balanceOf(address(this));
        }
    }

    function _swapTokensWithRouterIndex(
        address _input,
        address _output,
        uint256 _amount,
        uint256 _expected,
        uint256 _routerIndex
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = _input;
        path[1] = _output;
        ISwap(routerArray[_routerIndex]).swapExactTokensForTokens(
            _amount,
            _expected,
            path,
            address(this),
            // The deadline is a hardcoded value that is far in the future.
            1e10
        );
    }
    
    function _swapTokens(
        address _input,
        address _output,
        uint256 _amount,
        uint256 _expected
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = _input;
        path[1] = _output;
        router.swapExactTokensForTokens(
            _amount,
            _expected,
            path,
            address(this),
            // The deadline is a hardcoded value that is far in the future.
            1e10
        );
    }

    function _withdraw(
        uint256 _amount
    )
        internal
        virtual;

    function _withdrawAll()
        internal
        virtual;

    function _withdrawSome(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 _before = IERC20(want).balanceOf(address(this));
        _withdraw(_amount);
        uint256 _after = IERC20(want).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    /**
     * MODIFIERS
     */

    modifier onlyStrategist() {
        require(msg.sender == manager.strategist(), "!strategist");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "!controller");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface ExtendedIERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICVXMinter {
    function maxSupply() external view returns (uint256);
    function totalCliffs() external view returns (uint256);
    function reductionPerCliff() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IHarvester {
    function addStrategy(address, address, uint256) external;
    function manager() external view returns (IManager);
    function removeStrategy(address, address, uint256) external;
    function slippage() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface ISwap {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external;
    function getAmountsOut(uint256, address[] calldata) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IManager {
    function addVault(address) external;
    function allowedControllers(address) external view returns (bool);
    function allowedConverters(address) external view returns (bool);
    function allowedStrategies(address) external view returns (bool);
    function allowedVaults(address) external view returns (bool);
    function controllers(address) external view returns (address);
    function getHarvestFeeInfo() external view returns (address, address, uint256);
    function getToken(address) external view returns (address);
    function governance() external view returns (address);
    function halted() external view returns (bool);
    function harvester() external view returns (address);
    function insuranceFee() external view returns (uint256);
    function insurancePool() external view returns (address);
    function insurancePoolFee() external view returns (uint256);
    function pendingStrategist() external view returns (address);
    function removeVault(address) external;
    function stakingPool() external view returns (address);
    function stakingPoolShareFee() external view returns (uint256);
    function strategist() external view returns (address);
    function treasury() external view returns (address);
    function treasuryFee() external view returns (uint256);
    function withdrawalProtectionFee() external view returns (uint256);
    function yaxis() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";
import "./ISwap.sol";

interface IStrategy {
    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function deposit() external;
    function harvest(uint256[] calldata) external;
    function manager() external view returns (IManager);
    function name() external view returns (string memory);
    function router() external view returns (ISwap);
    function skim() external;
    function want() external view returns (address);
    function weth() external view returns (address);
    function withdraw(address) external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

interface IStrategyExtended {
    function getEstimates() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IManager.sol";

interface IController {
    function balanceOf() external view returns (uint256);
    function converter(address _vault) external view returns (address);
    function earn(address _strategy, address _token, uint256 _amount) external;
    function investEnabled() external view returns (bool);
    function harvestStrategy(address _strategy, uint256[] calldata _estimates) external;
    function manager() external view returns (IManager);
    function strategies() external view returns (uint256);
    function withdraw(address _token, uint256 _amount) external;
    function withdrawAll(address _strategy, address _convert) external;
}