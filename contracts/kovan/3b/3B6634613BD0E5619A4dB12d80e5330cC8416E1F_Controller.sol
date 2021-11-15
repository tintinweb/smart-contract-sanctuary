pragma solidity 0.5.16;

import "./Governable.sol";

contract Controllable is Governable {

  constructor(address _storage) Governable(_storage) public {
  }

  modifier onlyController() {
    require(store.isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((store.isController(msg.sender) || store.isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return store.controller();
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./hardworkInterface/IController.sol";
import "./hardworkInterface/IStrategy.sol";
import "./hardworkInterface/IVault.sol";
import "./FeeRewardForwarder.sol";
import "./Governable.sol";
import "./HardRewards.sol";

contract Controller is IController, Governable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // external parties
    address public feeRewardForwarder;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public greyList;

    // All vaults that we have
    mapping (address => bool) public vaults;

    // Rewards for hard work. Nullable.
    HardRewards public hardRewards;

    uint256 public constant profitSharingNumerator = 5;
    uint256 public constant profitSharingDenominator = 100;

    event SharePriceChangeLog(
      address indexed vault,
      address indexed strategy,
      uint256 oldSharePrice,
      uint256 newSharePrice,
      uint256 timestamp
    );

    modifier validVault(address _vault){
        require(vaults[_vault], "vault does not exist");
        _;
    }

    modifier confirmSharePrice(
        address vault,
        uint256 hint,
        uint256 deviationNumerator,
        uint256 deviationDenominator
    ) {
        uint256 sharePrice = IVault(vault).getPricePerFullShare();
        uint256 resolution = 1e18;
        if (sharePrice > hint) {
            require(
                sharePrice.mul(resolution).div(hint) <= deviationNumerator.mul(resolution).div(deviationDenominator),
                "share price deviation"
            );
        } else {
            require(
                hint.mul(resolution).div(sharePrice) <= deviationNumerator.mul(resolution).div(deviationDenominator),
                "share price deviation"
            );
        }
        _;
    }

    mapping (address => bool) public hardWorkers;

    modifier onlyHardWorkerOrGovernance() {
        require(hardWorkers[msg.sender] || (msg.sender == governance()),
        "only hard worker can call this");
        _;
    }

    constructor(address _storage, address _feeRewardForwarder)
    Governable(_storage) public {
        require(_feeRewardForwarder != address(0), "feeRewardForwarder should not be empty");
        feeRewardForwarder = _feeRewardForwarder;
    }

    function addHardWorker(address _worker) public onlyGovernance {
      require(_worker != address(0), "_worker must be defined");
      hardWorkers[_worker] = true;
    }

    function removeHardWorker(address _worker) public onlyGovernance {
      require(_worker != address(0), "_worker must be defined");
      hardWorkers[_worker] = false;
    }

    function hasVault(address _vault) external returns (bool) {
      return vaults[_vault];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function setFeeRewardForwarder(address _feeRewardForwarder) public onlyGovernance {
      require(_feeRewardForwarder != address(0), "new reward forwarder should not be empty");
      feeRewardForwarder = _feeRewardForwarder;
    }

    function addVaultAndStrategy(address _vault, address _strategy) external onlyGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        vaults[_vault] = true;
        // no need to protect against sandwich, because there will be no call to withdrawAll
        // as the vault and strategy is brand new
        IVault(_vault).setStrategy(_strategy);
    }

    function getPricePerFullShare(address _vault) public view returns(uint256) {
        return IVault(_vault).getPricePerFullShare();
    }

    function doHardWork(address _vault,
        uint256 hint,
        uint256 deviationNumerator,
        uint256 deviationDenominator
    ) external
    confirmSharePrice(_vault, hint, deviationNumerator, deviationDenominator)
    onlyHardWorkerOrGovernance
    validVault(_vault) {
        uint256 oldSharePrice = IVault(_vault).getPricePerFullShare();
        IVault(_vault).doHardWork();
        if (address(hardRewards) != address(0)) {
            // rewards are an option now
            hardRewards.rewardMe(msg.sender, _vault);
        }
        emit SharePriceChangeLog(
          _vault,
          IVault(_vault).strategy(),
          oldSharePrice,
          IVault(_vault).getPricePerFullShare(),
          block.timestamp
        );
    }

    function withdrawAll(address _vault,
        uint256 hint,
        uint256 deviationNumerator,
        uint256 deviationDenominator
    ) external
    confirmSharePrice(_vault, hint, deviationNumerator, deviationDenominator)
    onlyGovernance
    validVault(_vault) {
        IVault(_vault).withdrawAll();
    }

    function setStrategy(address _vault,
        address strategy,
        uint256 hint,
        uint256 deviationNumerator,
        uint256 deviationDenominator
    ) external
    confirmSharePrice(_vault, hint, deviationNumerator, deviationDenominator)
    onlyGovernance
    validVault(_vault) {
        IVault(_vault).setStrategy(strategy);
    }

    function setHardRewards(address _hardRewards) external onlyGovernance {
        hardRewards = HardRewards(_hardRewards);
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(address _strategy, address _token, uint256 _amount) external onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvagable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }

    function notifyFee(address underlying, uint256 fee) external {
      if (fee > 0) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), fee);
        IERC20(underlying).safeApprove(feeRewardForwarder, 0);
        IERC20(underlying).safeApprove(feeRewardForwarder, fee);
        FeeRewardForwarder(feeRewardForwarder).poolNotifyFixedTarget(underlying, fee);
      }
    }
}

pragma solidity 0.5.16;

import "./Governable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./hardworkInterface/IRewardPool.sol";
import "./uniswap/interfaces/IUniswapV2Router02.sol";

contract FeeRewardForwarder is Governable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public farm;

  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  
  address constant public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address constant public renBTC = address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
  address constant public sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
  address constant public dego = address(0x88EF27e69108B2633F8E1C184CC37940A075cC02);
  address constant public uni = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
  address constant public comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
  address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

  address constant public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

  address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  mapping (address => mapping (address => address[])) public uniswapRoutes;

  // grain 
  // grain is a burnable ERC20 token that is deployed by Harvest
  // we sell crops to buy back grain and burn it
  address public grain;
  uint256 public grainShareNumerator;
  uint256 public grainShareDenominator;

  // In case we're not buying back grain immediately,
  // we liquidate the crops into the grainBackerToken
  // and send it to an EOA `grainBuybackReserve`
  bool public grainImmediateBuyback;
  address public grainBackerToken;
  address public grainBuybackReserve;
  
  // the targeted reward token to convert everything to
  address public targetToken;
  address public profitSharingPool;

  address constant public uniswapRouterV2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  event TokenPoolSet(address token, address pool);

  constructor(address _storage, address _farm, address _grain) public Governable(_storage) {
    require(_grain != address(0), "_grain not defined");
    require(_farm != address(0), "_farm not defined");
    grain = _grain;
    farm = _farm;

    // preset for the already in use crops
    uniswapRoutes[weth][farm] = [weth, usdc, farm];
    uniswapRoutes[dai][farm] = [dai, weth, usdc, farm];
    uniswapRoutes[usdc][farm] = [usdc, farm];
    uniswapRoutes[usdt][farm] = [usdt, weth, usdc, farm];

    uniswapRoutes[wbtc][farm] = [wbtc, weth, usdc, farm];
    uniswapRoutes[renBTC][farm] = [renBTC, weth, usdc, farm];
    uniswapRoutes[sushi][farm] = [sushi, weth, usdc, farm];
    uniswapRoutes[dego][farm] = [dego, weth, usdc, farm];
    uniswapRoutes[crv][farm] = [crv, weth, usdc, farm];
    uniswapRoutes[comp][farm] = [comp, weth, usdc, farm];
    
    // Route to grain is always to farm then to grain.
    // So we will just use the existing route to buy FARM first
    // then sell partially to grain.
    uniswapRoutes[grain][farm] = [grain, farm];
    uniswapRoutes[farm][grain] = [farm, grain];

    // preset for grainBacker (usdc or weth)
    //weth
    uniswapRoutes[dai][weth] = [dai, weth];
    uniswapRoutes[usdc][weth] = [usdc, weth];
    uniswapRoutes[usdt][weth] = [usdt, weth];

    uniswapRoutes[wbtc][weth] = [wbtc, weth];
    uniswapRoutes[renBTC][weth] = [renBTC, weth];
    uniswapRoutes[sushi][weth] = [sushi, weth];
    uniswapRoutes[dego][weth] = [dego, weth];
    uniswapRoutes[crv][weth] = [crv, weth];
    uniswapRoutes[comp][weth] = [comp, weth];

    // usdc
    uniswapRoutes[weth][usdc] = [weth, usdc];
    uniswapRoutes[dai][usdc] = [dai, weth, usdc];
    uniswapRoutes[usdt][usdc] = [usdt, weth, usdc];

    uniswapRoutes[wbtc][usdc] = [wbtc, weth, usdc];
    uniswapRoutes[renBTC][usdc] = [renBTC, weth, usdc];
    uniswapRoutes[sushi][usdc] = [sushi, weth, usdc];
    uniswapRoutes[dego][usdc] = [dego, weth, usdc];
    uniswapRoutes[crv][usdc] = [crv, weth, usdc];
    uniswapRoutes[comp][usdc] = [comp, weth, usdc];
  }

  /*
  *   Set the pool that will receive the reward token
  *   based on the address of the reward Token
  */
  function setTokenPool(address _pool) public onlyGovernance {
    // To buy back grain, our `targetToken` needs to be FARM
    require(farm == IRewardPool(_pool).rewardToken(), "Rewardpool's token is not FARM");
    profitSharingPool = _pool;
    targetToken = farm;
    emit TokenPoolSet(targetToken, _pool);
  }

  /**
  * Sets the path for swapping tokens to the to address
  * The to address is not validated to match the targetToken,
  * so that we could first update the paths, and then,
  * set the new target
  */
  function setConversionPath(address from, address to, address[] memory _uniswapRoute)
  public onlyGovernance {
    require(from == _uniswapRoute[0],
      "The first token of the Uniswap route must be the from token");
    require(to == _uniswapRoute[_uniswapRoute.length - 1],
      "The last token of the Uniswap route must be the to token");
    uniswapRoutes[from][to] = _uniswapRoute;
  }

  // Transfers the funds from the msg.sender to the pool
  // under normal circumstances, msg.sender is the strategy
  function poolNotifyFixedTarget(address _token, uint256 _amount) external {
    uint256 remainingAmount = _amount;
    // Note: targetToken could only be FARM or NULL. 
    // it is only used to check that the rewardPool is set.
    if (targetToken == address(0)) {
      return; // a No-op if target pool is not set yet
    }
    if (_token == farm) {
      // this is already the right token
      // Note: Under current structure, this would be FARM.
      // This would pass on the grain buy back as it would be the special case
      // designed for NotifyHelper calls
      // This is assuming that NO strategy would notify profits in FARM
      IERC20(_token).safeTransferFrom(msg.sender, profitSharingPool, _amount);
      IRewardPool(profitSharingPool).notifyRewardAmount(_amount);
    } else {
      // If grainImmediateBuyback is set to false, then funds to buy back grain needs to be sent to an address

      if (grainShareNumerator != 0 && !grainImmediateBuyback) {
        require(grainBuybackReserve != address(0), "grainBuybackReserve should not be empty");
        uint256 balanceToSend = _amount.mul(grainShareNumerator).div(grainShareDenominator);
        remainingAmount = _amount.sub(balanceToSend);
        
        // If the liquidation path is set, liquidate to grainBackerToken and send it over
        // if not, send the crops immediately
        // this also covers the case when the _token is the grainBackerToken
        if(uniswapRoutes[_token][grainBackerToken].length > 1){
          IERC20(_token).safeTransferFrom(msg.sender, address(this), balanceToSend);
          liquidate(_token, grainBackerToken, balanceToSend);
          // send the grainBackerToken to the reserve
          IERC20(grainBackerToken).safeTransfer(grainBuybackReserve, IERC20(grainBackerToken).balanceOf(address(this)));
        } else {
          IERC20(_token).safeTransferFrom(msg.sender, grainBuybackReserve, balanceToSend);
        }
      }

      // we need to convert _token to FARM
      if (uniswapRoutes[_token][farm].length > 1) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), remainingAmount);
        uint256 balanceToSwap = IERC20(_token).balanceOf(address(this));
        liquidate(_token, farm, balanceToSwap);

        // if grain buyback is activated, then sell some FARM to buy and burn grain
        if(grainShareNumerator != 0 && grainImmediateBuyback) {
          uint256 balanceToBuyback = (IERC20(farm).balanceOf(address(this))).mul(grainShareNumerator).div(grainShareDenominator);
          liquidate(farm, grain, balanceToBuyback);

          // burn all the grains in this contract
          ERC20Burnable(grain).burn(IERC20(grain).balanceOf(address(this)));
        }

        // now we can send this token forward
        uint256 convertedRewardAmount = IERC20(farm).balanceOf(address(this));
        IERC20(farm).safeTransfer(profitSharingPool, convertedRewardAmount);
        IRewardPool(profitSharingPool).notifyRewardAmount(convertedRewardAmount);
      } else { 
        // else the route does not exist for this token
        // do not take any fees and revert. 
        // It's better to set the liquidation path then perform it again, 
        // rather then leaving the funds in controller
        revert("FeeRewardForwarder: liquidation path doesn't exist"); 
      }
    }
  }

  function liquidate(address _from, address _to, uint256 balanceToSwap) internal {
    if(balanceToSwap > 0){
      IERC20(_from).safeApprove(uniswapRouterV2, 0);
      IERC20(_from).safeApprove(uniswapRouterV2, balanceToSwap);

      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        balanceToSwap,
        1, // we will accept any amount
        uniswapRoutes[_from][_to],
        address(this),
        block.timestamp
      );
    }
  }

  function setGrainBuybackRatio(uint256 _grainShareNumerator, uint256 _grainShareDenominator) public onlyGovernance {
    require(_grainShareDenominator >= _grainShareNumerator, "numerator cannot be greater than denominator");
    require(_grainShareDenominator != 0, "_grainShareDenominator cannot be 0");
    
    grainShareNumerator = _grainShareNumerator;
    grainShareDenominator = _grainShareDenominator;
  }

  function setGrainConfig(
    uint256 _grainShareNumerator, 
    uint256 _grainShareDenominator, 
    bool _grainImmediateBuyback, 
    address _grainBackerToken,
    address _grainBuybackReserve
  ) external onlyGovernance {
    require(_grainBuybackReserve != address(0), "_grainBuybackReserve is empty");
    // grainBackerToken can be address(0), this way the forwarder will send the crops directly
    // since it cannot find a path.
    // grainShareNumerator can be 0, this means that no grain is being bought back
    setGrainBuybackRatio(_grainShareNumerator, _grainShareDenominator);

    grainImmediateBuyback = _grainImmediateBuyback;
    grainBackerToken = _grainBackerToken;
    grainBuybackReserve = _grainBuybackReserve;
  }

}

pragma solidity 0.5.16;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Governable.sol";
import "./Controllable.sol";

contract HardRewards is Controllable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Rewarded(address indexed recipient, address indexed vault, uint256 amount);

  // token used for rewards
  IERC20 public token;

  // how many tokens per each block
  uint256 public blockReward;

  // vault to the last rewarded block
  mapping(address => uint256) public lastReward;

  constructor(address _storage, address _token)
  Controllable(_storage) public {
    token = IERC20(_token);
  }

  /**
  * Called from the controller after hard work has been done. Defensively avoid
  * reverting the transaction in this function.
  */
  function rewardMe(address recipient, address vault) external onlyController {
    if (address(token) == address(0) || blockReward == 0) {
      // no rewards now
      emit Rewarded(recipient, vault, 0);
      return;
    }

    if (lastReward[vault] == 0) {
      // vault does not exist
      emit Rewarded(recipient, vault, 0);
      return;
    }

    uint256 span = block.number.sub(lastReward[vault]);
    uint256 reward = blockReward.mul(span);

    if (reward > 0) {
      uint256 balance = token.balanceOf(address(this));
      uint256 realReward = balance >= reward ? reward : balance;
      if (realReward > 0) {
        token.safeTransfer(recipient, realReward);
      }
      emit Rewarded(recipient, vault, realReward);
    } else {
      emit Rewarded(recipient, vault, 0);
    }
    lastReward[vault] = block.number;
  }

  function addVault(address _vault) external onlyGovernance {
    lastReward[_vault] = block.number;
  }

  function removeVault(address _vault) external onlyGovernance {
    delete (lastReward[_vault]);
  }

  /**
  * Transfers tokens for the new rewards cycle. Allows for changing the rewards setting
  * at the same time.
  */
  function load(address _token, uint256 _rate, uint256 _amount) external onlyGovernance {
    token = IERC20(_token);
    blockReward = _rate;
    if (address(token) != address(0) && _amount > 0) {
      token.safeTransferFrom(msg.sender, address(this), _amount);
    }
  }
}

pragma solidity 0.5.16;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity 0.5.16;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault, uint256 hint, uint256 devianceNumerator, uint256 devianceDenominator) external;
    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

pragma solidity 0.5.16;

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

pragma solidity 0.5.16;

interface IStrategy {
    
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

pragma solidity 0.5.16;

interface IVault {

    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;
    function setVaultFractionToInvest(uint256 numerator, uint256 denominator) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 {
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

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

