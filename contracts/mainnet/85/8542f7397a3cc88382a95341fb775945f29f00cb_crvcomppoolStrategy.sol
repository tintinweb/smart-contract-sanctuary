pragma solidity >0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../../interfaces/deba/IRewardPool.sol";
import "./../../interfaces/uniswap/IUniswapV2Router02.sol";

contract FeeRewardForwarder {
  using SafeERC20 for IERC20;

  /** 
  *   These are tokens that we are integrating and are interested in.
  *   Tokens that are being used in our vaults/stragies.
  *   Keep & add only those relevant for specific Deba Vaults/Strategies.
  *   They are here in order to build the uniswap paths needed to trade them.
  */
  address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public yfi = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);
  address constant public link = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
  
  mapping (address => mapping (address => address[])) public uniswapRoutes;

  /**
  * The targeted reward token to convert everything to (what the pool needs to receive).
  * This is the token tied to the RewardPool that this FeeRewardForwarder is 
  * connected to at any point in time.
  * If the token that is sent to the Forwarder is the correct one, nothing happens.
  * If it isn't the `targetToken`, then it gets converted to the `targetToken` first.
   */
  address public targetToken; // Is always the RewardPool.rewardToken()
  address public profitSharingPool; // Address of the RewardPool.

  address public uniswapRouterV2;
  
  address public governance;

  event TokenPoolSet(address token, address pool);

  /**
  *   Sets governance address.
  *   Sets the Uniswap router address.
  *   Builds the Uniswap paths.
  */
  constructor(address _storage, address _uniswapRouterV2) public {
    governance = msg.sender;
    require(_uniswapRouterV2 != address(0), "uniswapRouterV2 not defined");
    uniswapRouterV2 = _uniswapRouterV2;
    // these are for mainnet, but they won't impact Ropsten
    uniswapRoutes[ycrv][dai] = [ycrv, weth, dai];
    uniswapRoutes[link][dai] = [link, weth, dai];
    uniswapRoutes[weth][dai] = [weth, dai];
    uniswapRoutes[yfi][dai] = [yfi, weth, dai];
  }

  function setGovernance(address _gov) external {
    require(msg.sender == governance, '!governance');
    governance = _gov;
  }

  /*
  *   Sets the RewardPool that will receive the reward token.
  *   Sets the targetToken of this contract based on 
  *   the address of the RewardPool.
  */
  function setTokenPool(address _pool) public {
    require(msg.sender == governance, '!governance');
    targetToken = IRewardPool(_pool).rewardToken();
    profitSharingPool = _pool;
    emit TokenPoolSet(targetToken, _pool);
  }

  /**
  *   Sets the path for swapping tokens to the to address
  *   The `to` address is not validated to match the targetToken,
  *   so that we could first update the paths, and then,
  *   set the new target.
  */
  function setConversionPath(address from, address to, address[] memory _uniswapRoute) public {
    require(msg.sender == governance, '!governance');
    require(from == _uniswapRoute[0],
      "The first token of the Uniswap route must be the from token");
    require(to == _uniswapRoute[_uniswapRoute.length - 1],
      "The last token of the Uniswap route must be the to token");
    uniswapRoutes[from][to] = _uniswapRoute;
  }

  /**
  * Main Function
  *
  * Forwards the funds from the msg.sender to the pool
  * under normal circumstances, msg.sender is the strategy.
  */
  function poolNotifyFixedTarget(address _token, uint256 _amount) external {
    if (targetToken == address(0)) {
      return; // a No-op if target pool is not set yet
    }
    if (_token == targetToken) {
      // this is already the right token
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
      IRewardPool(profitSharingPool).notifyRewardAmount(_amount);
    } else {
      // we need to convert
      if (uniswapRoutes[_token][targetToken].length > 1) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeApprove(uniswapRouterV2, 0);
        IERC20(_token).safeApprove(uniswapRouterV2, balanceToSwap);

        IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
          balanceToSwap,
          1, // we will accept any amount
          uniswapRoutes[_token][targetToken],
          address(this),
          block.timestamp
        );
        // now we can send this token forward
        uint256 convertedRewardAmount = IERC20(targetToken).balanceOf(address(this));
        IERC20(targetToken).safeTransfer(profitSharingPool, convertedRewardAmount);
        IRewardPool(profitSharingPool).notifyRewardAmount(convertedRewardAmount);
      }
      // else the route does not exist for this token
      // do not take any fees
    }
  }
}

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./FeeRewardForwarder.sol";


contract ProfitNotifier {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public profitSharingNumerator;
  uint256 public profitSharingDenominator;

  address public feeRewardForwarder; // Address of the `FeeRewardForwarder` contract.

  event ProfitLog(
    uint256 oldBalance,
    uint256 newBalance,
    uint256 feeAmount,
    uint256 timestamp
  );

  constructor() {
    // persist in the state for immutability of the fee
    // means fee = 30%
    profitSharingNumerator = 25; 
    profitSharingDenominator = 100;
    require(profitSharingNumerator < profitSharingDenominator, "invalid profit share");
  }

  /* 
  / This fn takes in the old balance (pre-profit) and the new balance (after profit).
  / It uses this info to calculate the profit (old balance - new balance).
  / After computing the profit, it computes the fee (30% of profit in our case).
  / Finally it sends the fee amount to the `FeeRewardForwarder` contract and notifies it.
  */
  function notifyProfit(uint256 oldBalance, uint256 newBalance, address underlying) internal {
    if (newBalance > oldBalance) {
      uint256 profit = newBalance.sub(oldBalance);
      uint256 feeAmount = profit.mul(profitSharingNumerator).div(profitSharingDenominator);
      emit ProfitLog(oldBalance, newBalance, feeAmount, block.timestamp);

      if (feeAmount > 0) {
        IERC20(underlying).safeApprove(feeRewardForwarder, 0);
        IERC20(underlying).safeApprove(feeRewardForwarder, feeAmount);
        require(feeRewardForwarder != address(0), 'burning porfits!');
        FeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying, feeAmount);
      }
    } else {
      emit ProfitLog(oldBalance, newBalance, 0, block.timestamp);
    }
  }
}

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../../interfaces/dforce/Rewards.sol";
import "../../../interfaces/dforce/Token.sol";
import "./../../../interfaces/compound/CTokenInterfaces.sol";
// import "../../../interfaces/1inch/IOneSplitAudit.sol";
import "./../../../interfaces/uniswap/IUniswapV2Router02.sol";

import "./../../../interfaces/curve/Gauge.sol";
import "./../../../interfaces/curve/Mintr.sol";
import "./../../../interfaces/curve/Curve.sol";
import "./../ProfitNotifier.sol";

contract crvcomppoolStrategy is ProfitNotifier {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant curvecompPool = address(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    address public constant mainAsset = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    address public constant curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant curvecompGauge = address(0x7ca5b0a2910B33e9759DC7dDB0413949071D7575);
    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant cDai = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address[] public CRV2DAI;

    address public vault;
    address public governance;
    address public agent;

    constructor(address _vault, address _agent) {
        vault = _vault;
        governance = msg.sender;
        agent = _agent;

        CRV2DAI = [crv, weth, dai];
    }

    function setRewardForwarder(address _new) external {
        require(msg.sender == governance, '!governance');
        feeRewardForwarder = _new;
    }

    function setProfitSharingDenominator(uint256 _new) external {
        require(msg.sender == governance, '!governance');
        profitSharingDenominator = _new;
    }

    function setGovernance(address _gov) external {
        require(msg.sender == governance, '!governance');
        governance = _gov;
    }

    function setAgent(address _agent) external {
        require(msg.sender == governance, '!governance');
        agent = _agent;
    }

    function setVault(address _vault) external {
        require(msg.sender == governance, '!governance');
        vault = _vault;
    }

    function underlyingBalanceGauge() public view returns(uint256){
        return Gauge(curvecompGauge).balanceOf(address(this));
    }

    function underlyingBalance() public view returns(uint256){
        return IERC20(mainAsset).balanceOf(address(this)).add(underlyingBalanceGauge());
    }

    function _withdrawStrategy(uint256 _amount) internal returns(uint256) {
        uint256 _before = IERC20(mainAsset).balanceOf(address(this));
        Gauge(curvecompGauge).withdraw(_amount);
        uint256 _after = IERC20(mainAsset).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawStrategyAll() internal {
        uint256 _staked = Gauge(curvecompGauge).balanceOf(address(this));
        Gauge(curvecompGauge).withdraw(_staked);
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == vault || msg.sender == governance, '!governance');
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_amount > _balance){
            _amount = _withdrawStrategy(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        require(vault != address(0), 'burning funds');
        IERC20(mainAsset).safeTransfer(vault, _amount);
    }

    function liquidate() public {
        require(msg.sender == vault || msg.sender == governance, '!governance');
        // _harvestProfits();
        _withdrawStrategyAll();

        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        require(vault != address(0), 'burning funds');
        IERC20(mainAsset).safeTransfer(vault, _balance);
    }

    function deposit() public {
        uint256 _balance = IERC20(mainAsset).balanceOf(address(this));
        if(_balance > 0) {
            // Stake
            IERC20(mainAsset).safeApprove(curvecompGauge, 0);
            IERC20(mainAsset).safeApprove(curvecompGauge, _balance);
            Gauge(curvecompGauge).deposit(_balance);
        }
    }

    function _harvestProfits() internal {
        uint256 _balanceBeforeDAI = IERC20(dai).balanceOf(address(this));
        Mintr(curveMinter).mint(curvecompGauge);
        uint256 _crvBalance = IERC20(crv).balanceOf(address(this));
        if(_crvBalance > 0){
            IERC20(crv).safeApprove(uniswapRouter, 0);
            IERC20(crv).safeApprove(uniswapRouter, _crvBalance);
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(_crvBalance, uint256(0), CRV2DAI, address(this), block.timestamp.add(1800));
            uint256 _balanceAfterDAI = IERC20(dai).balanceOf(address(this));
            notifyProfit(_balanceBeforeDAI, _balanceAfterDAI, dai);
            uint256 _profit = IERC20(dai).balanceOf(address(this));
            if(_profit > 0){

                // Convert to cDai
                IERC20(dai).safeApprove(cDai, 0);
                IERC20(dai).safeApprove(cDai, _profit);
                CErc20Interface(cDai).mint(_profit);
                // Deposit to pool
                uint256 _cBal = IERC20(cDai).balanceOf(address(this));
                IERC20(cDai).safeApprove(curvecompPool, 0);
                IERC20(cDai).safeApprove(curvecompPool, _cBal);
                ICurveFi(curvecompPool).add_liquidity([_cBal, uint256(0)], 0);
            }
        }
    }

    function harvestProfits() public {
        require(msg.sender == agent || msg.sender == governance, '!governance');
        _harvestProfits();
        deposit();
    }
}

pragma solidity ^0.7.0;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";

interface CTokenStorage {
    // /**
    //  * @dev Guard variable for re-entrancy checks
    //  */
    // bool internal _notEntered;

    // /**
    //  * @notice EIP-20 token name for this token
    //  */
    // string public name;

    // /**
    //  * @notice EIP-20 token symbol for this token
    //  */
    // string public symbol;

    // /**
    //  * @notice EIP-20 token decimals for this token
    //  */
    // uint8 public decimals;


    // uint internal constant borrowRateMaxMantissa = 0.0005e16;

    // uint internal constant reserveFactorMaxMantissa = 1e18;

    // /**
    //  * @notice Administrator for this contract
    //  */
    // address payable public admin;

    // /**
    //  * @notice Pending administrator for this contract
    //  */
    // address payable public pendingAdmin;

    // /**
    //  * @notice Contract which oversees inter-cToken operations
    //  */
    // ComptrollerInterface public comptroller;

    // /**
    //  * @notice Model which tells what the current interest rate should be
    //  */
    // InterestRateModel public interestRateModel;

    // uint internal initialExchangeRateMantissa;

    // /**
    //  * @notice Fraction of interest currently set aside for reserves
    //  */
    // uint public reserveFactorMantissa;

    // /**
    //  * @notice Block number that interest was last accrued at
    //  */
    // uint public accrualBlockNumber;

    // /**
    //  * @notice Accumulator of the total earned interest rate since the opening of the market
    //  */
    // uint public borrowIndex;

    // /**
    //  * @notice Total amount of outstanding borrows of the underlying in this market
    //  */
    // uint public totalBorrows;

    // /**
    //  * @notice Total amount of reserves of the underlying held in this market
    //  */
    // uint public totalReserves;

    // /**
    //  * @notice Total number of tokens in circulation
    //  */
    // uint public totalSupply;

    // mapping (address => uint) internal accountTokens;

    // mapping (address => mapping (address => uint)) internal transferAllowances;

    // /**
    //  * @notice Container for borrow balance information
    //  * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
    //  * @member interestIndex Global borrowIndex as of the most recent balance-changing action
    //  */
    // struct BorrowSnapshot {
    //     uint principal;
    //     uint interestIndex;
    // }

    // mapping(address => BorrowSnapshot) internal accountBorrows;
}

interface CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    // bool public constant isCToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function isCToken() external returns(bool);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint);
}

interface CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    // address public underlying;
}

interface CErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}

interface CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    // address public implementation;
}

interface CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) external;
}

interface CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external;
}

pragma solidity ^0.7.0;

interface ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    // bool public isComptroller;

    function isComptroller() external returns(bool);
    function markets(address) external returns(bool, uint256, bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);

    function claimComp(address) external;
}

pragma solidity ^0.7.0;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
interface InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    // bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // renBTC pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;
    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;
    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

interface Zap {
    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface Mintr {
    function mint(address) external;
}

pragma solidity >0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Unifying the interface with the Synthetix Reward Pool 
interface IRewardPool {
  function rewardToken() external view returns (address);
  function lpToken() external view returns (address);
  function duration() external view returns (uint256);

  function periodFinish() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);

  function stake(uint256 amountWei) external;

  // `balanceOf` would give the amount staked. 
  // As this is 1 to 1, this is also the holder's share
  function balanceOf(address holder) external view returns (uint256);
  // total shares & total lpTokens staked
  function totalSupply() external view returns(uint256);

  function withdraw(uint256 amountWei) external;
  function exit() external;

  // get claimed rewards
  function earned(address holder) external view returns (uint256);

  // claim rewards
  function getReward() external;

  // notify
  function notifyRewardAmount(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface dRewards {
    function withdraw(uint256) external;

    function getReward() external;

    function stake(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function exit() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface dERC20 {
    function mint(address, uint256) external;

    function redeem(address, uint256) external;

    function getTokenBalance(address) external view returns (uint256);

    function getExchangeRate() external view returns (uint256);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}