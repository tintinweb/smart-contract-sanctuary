//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface/ICoinDeedFactory.sol";
import "./interface/ICoinDeedDeployer.sol";
import "./CoinDeed.sol";

contract CoinDeedDeployer is ICoinDeedDeployer {

    function deploy(
        address[3] memory addressArgs,
        uint256 stakingAmount,
        ICoinDeedFactory.Pair memory pair,
        uint256 deedSize,
        ICoinDeedFactory.ExecutionTime memory executionTime,
        uint8 leverage,
        uint256 managementFee,
        ICoinDeedFactory.RiskMitigation memory riskMitigation,
        ICoinDeedFactory.BrokerConfig memory brokerConfig
    ) external override returns (address) {

        CoinDeed coinDeed = new CoinDeed(
            msg.sender,
            addressArgs[0],
            addressArgs[1],
            addressArgs[2],
            stakingAmount,
            pair,
            deedSize,
            executionTime,
            leverage,
            managementFee,
            riskMitigation,
            brokerConfig
        );
        return address(coinDeed);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager
    );

    event StakeAdded(
        address indexed coinDeed,
        address indexed broker,
        uint256 indexed amount
    );

    event StateChanged(
        address indexed coinDeed,
        DeedState state
    );

    event DeedCanceled(
        address indexed coinDeed,
        address indexed deedAddress
    );

    event SwapExecuted(
        address indexed coinDeed,
        uint256 indexed tokenBought
    );

    event BuyIn(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event ExitDeed(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event PayOff(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event LeverageChanged(
        address indexed coinDeed,
        address indexed salePercentage
    );

    event BrokersEnabled(
        address indexed coinDeed
    );


    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    struct Pair {address tokenA; address tokenB;}

    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    struct RiskMitigation {
        uint256 trigger;
        uint256 leverage;
    }

    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }

    /**
    * DeedManager calls to create deed contract
    */
    function createDeed(Pair calldata pair,
        uint256 deedSize,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ExecutionTime calldata executionTime,
        uint8 leverage,
        uint256 managementFee,
        RiskMitigation calldata riskMitigation,
        BrokerConfig calldata brokerConfig) external;

    /**
    * Returns number of Open deeds to able to browse them
    */
    function openDeedCount() external view returns (uint256);

    /**
    * Returns number of completed deeds to able to browse them
    */
    function completedDeedCount() external view returns (uint256);

    /**
    * Returns number of pending deeds to able to browse them
    */
    function pendingDeedCount() external view returns (uint256);

    function setMaxLeverage(uint8 maxLeverage_) external;

    function wholesaleFactoryAddress() external view returns (address);

    function lendingPoolAddress() external view returns (address);

    function coinDeedDeployerAddress() external view returns (address);

    function maxLeverage() external view returns (uint8);

    function platformFee() external view returns (uint256);

    function setPlatformFee(uint256 platformFee_) external;

    function managerDeedCount(address manager) external view returns (uint256);

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external;

    function emitStateChanged(
        DeedState state
    ) external;

    function emitDeedCanceled(
        address deedAddress
    ) external;

    function emitSwapExecuted(
        uint256 tokenBought
    ) external;

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external;

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external;

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external;

    function emitLeverageChanged(
        address salePercentage
    ) external;

    function emitBrokersEnabled() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeedFactory.sol";

interface ICoinDeedDeployer {

    function deploy(
        address[3] memory addressArgs,
        uint256 stakingAmount,
        ICoinDeedFactory.Pair memory pair,
        uint256 deedSize,
        ICoinDeedFactory.ExecutionTime memory executionTime,
        uint8 leverage,
        uint256 managementFee,
        ICoinDeedFactory.RiskMitigation memory riskMitigation,
        ICoinDeedFactory.BrokerConfig memory brokerConfig
    ) external returns (address);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface/IToken.sol";
import "./interface/ICoinDeed.sol";
import "./interface/ILendingPool.sol";
import "./interface/IOracle.sol";
import "./interface/ICoinDeedFactory.sol";
import "./interface/IWholesaleFactory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoinDeed is ICoinDeed, AccessControl {

    using SafeMath for uint256;

    address internal constant UNISWAP_ROUTER_1_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;

    IUniswapV2Router01 public uniswapRouter1;
    address public WETH;

    address public coinDeedAdmin;
    ICoinDeedFactory public coinDeedFactory;
    address public manager;
    ICoinDeedFactory.Pair public pair;
    uint256 public deedSize;
    ICoinDeedFactory.ExecutionTime public executionTime;
    uint8 public leverage;
    uint256 public managementFee;
    uint256 public totalManagementFee;
    uint256 public totalPlatformFee;

    ICoinDeedFactory.RiskMitigation public riskMitigation;
    ICoinDeedFactory.BrokerConfig public brokerConfig;
    IToken private deedToken;
    ICoinDeedFactory.DeedState public state;
    ILendingPool public lendingPool;
    uint256 public totalSupply;
    uint256 public totalReturn;
    uint256 public totalStake;

    uint256 public totalLoan;
    uint256 public totalTokenB;

    uint256 wholesaleId;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public feeClaimed;
    uint256 public totalFeeClaimed;

    mapping(address => uint256) public buyIns;

    mapping(address => uint256) public loans;

    bytes32 public constant MANAGER = keccak256("MANAGER");

    constructor(address coinDeedFactoryAddress, address coinDeedAdmin_, address deedTokenAddress, address manager_,
        uint256 stakingAmount,
        ICoinDeedFactory.Pair memory pair_,
        uint256 deedSize_,
        ICoinDeedFactory.ExecutionTime memory executionTime_,
        uint8 leverage_,
        uint256 managementFee_,
        ICoinDeedFactory.RiskMitigation memory riskMitigation_,
        ICoinDeedFactory.BrokerConfig memory brokerConfig_) {

        uniswapRouter1 = IUniswapV2Router01(UNISWAP_ROUTER_1_ADDRESS);
        WETH = uniswapRouter1.WETH();

        _setupRole(MANAGER, manager_);
        _setRoleAdmin(MANAGER, DEFAULT_ADMIN_ROLE);

        coinDeedFactory = ICoinDeedFactory(coinDeedFactoryAddress);
        lendingPool = ILendingPool(coinDeedFactory.lendingPoolAddress());
        coinDeedAdmin = coinDeedAdmin_;
        deedToken = IToken(deedTokenAddress);
        manager = manager_;
        pair = pair_;

        _edit(deedSize_, leverage_, managementFee_);
        _editExecutionTime(executionTime_);
        _editRiskMitigation(riskMitigation_);
        brokerConfig = brokerConfig_;

        state = ICoinDeedFactory.DeedState.SETUP;
        _stake(manager, stakingAmount);
    }

    function _onlyInState(ICoinDeedFactory.DeedState state_) private view {
        require(state == state_, "Deed is not in correct state.");
    }

    function _onlyInStates(ICoinDeedFactory.DeedState[2] memory states)  private view  {

        bool found = false;

        for (uint i = 0; i < states.length; i++) {
            if (state == states[i]) {
                found = true;
            }
        }
        require(found, "Deed is not in correct state.");
    }

    modifier onlyInState(ICoinDeedFactory.DeedState state_) {
        _onlyInState(state_);
        _;
    }


    modifier onlyInStates(ICoinDeedFactory.DeedState[2] memory states) {
        _onlyInStates(states);
        _;
    }


    function reserveWholesale(uint256 saleId) external override {
        require(msg.sender == address(coinDeedFactory) || msg.sender == manager, "Only Deed manager or factory it self can reserve a wholesale.");

        IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedFactory.wholesaleFactoryAddress());
        IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(saleId);

        require(wholesale.tokenOffered == pair.tokenB, "Offered token in whokesale does not match with the deed.");
        require(wholesale.tokenRequested == pair.tokenA, "Requested token in whokesale does not match with the deed.");
        require(wholesale.minSaleAmount <= deedSize, "minSaleAmount is bigger then the deedsize.");

        wholesaleFactory.reserveWholesale(saleId);
        wholesaleId = saleId;
    }

    function _checkIfDeedIsReady() internal {

        address[] memory path = new address[](2);
        path[0] = pair.tokenA;
        path[1] = address(deedToken);
        uint[] memory amounts = uniswapRouter1.getAmountsOut(deedSize, path);
        if (totalStake >= amounts[0]) {
            state = ICoinDeedFactory.DeedState.READY;
            coinDeedFactory.emitStateChanged(state);
        }
    }

    function _stake(address supplier, uint256 amount) internal {
        stakes[supplier] = stakes[supplier] + amount;
        totalStake += amount;
        coinDeedFactory.emitStakeAdded(supplier, amount);
        _checkIfDeedIsReady();
    }

    function _managerOrBrokerEnabled() private view {
        require(msg.sender == manager || brokerConfig.allowed, "You are not the manager and brokers are not allowed.");
    }
    function stake(uint256 amount) onlyInState(ICoinDeedFactory.DeedState.SETUP) external override {
        _managerOrBrokerEnabled();
        deedToken.transferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount);
    }

    function stakeEth() onlyInState(ICoinDeedFactory.DeedState.SETUP) external payable override {
        _managerOrBrokerEnabled();

        uint256 deedTokenAmount = _swapEthToDeedCoin(msg.value);
        _stake(msg.sender, deedTokenAmount);
    }

    function stakeDifferentToken(address tokenAddress, uint256 amount) onlyInState(ICoinDeedFactory.DeedState.SETUP) external override {
        _managerOrBrokerEnabled();

        uint256 deedTokenAmount = _swapToDeedCoin(true, tokenAddress, amount);
        _stake(msg.sender, deedTokenAmount);
    }


    function editBrokerConfig(ICoinDeedFactory.BrokerConfig memory brokerConfig_) onlyRole(MANAGER) onlyInState(ICoinDeedFactory.DeedState.SETUP) public override {
        _editBrokerConfig(brokerConfig_);
    }

    function editRiskMitigation(ICoinDeedFactory.RiskMitigation memory riskMitigation_) onlyRole(MANAGER) onlyInState(ICoinDeedFactory.DeedState.SETUP) public override {
        _editRiskMitigation(riskMitigation_);
    }

    function editExecutionTime(ICoinDeedFactory.ExecutionTime memory executionTime_) onlyRole(MANAGER) onlyInState(ICoinDeedFactory.DeedState.SETUP) public override {
        _editExecutionTime(executionTime_);
    }

    function editBasicInfo(uint256 deedSize_, uint8 leverage_, uint256 managementFee_) onlyRole(MANAGER) onlyInState(ICoinDeedFactory.DeedState.SETUP) public override {
        require(totalStake == stakes[msg.sender], "This fields can not be changed after a broker stakes.");
        _edit(deedSize_, leverage_, managementFee_);

    }

    function exitDeed() onlyInState(ICoinDeedFactory.DeedState.OPEN) public override {

        uint256 buyIn_ = buyIns[msg.sender];
        buyIns[msg.sender] = 0;
        uint256 exitAmount = 0;
        if (totalSupply > 0) {
            exitAmount = totalTokenB.mul(buyIn_).div(totalSupply);
        }
        if (exitAmount > totalTokenB) {
            exitAmount = exitAmount;
        }
        // todo: need a function in lending pool to check current balance
        lendingPool.withdraw(pair.tokenB, exitAmount);
        _transfer(pair.tokenB, payable(msg.sender), exitAmount);
        totalTokenB = totalTokenB.sub(exitAmount);
        coinDeedFactory.emitExitDeed(msg.sender, exitAmount);

    }

    function edit(uint256 deedSize_,
        ICoinDeedFactory.ExecutionTime memory executionTime_,
        uint8 leverage_,
        uint256 managementFee_,
        ICoinDeedFactory.RiskMitigation memory riskMitigation_,
        ICoinDeedFactory.BrokerConfig memory brokerConfig_) onlyRole(MANAGER) onlyInState(ICoinDeedFactory.DeedState.SETUP) public override {

        _edit(deedSize_, leverage_, managementFee_);
        _editExecutionTime(executionTime_);
        _editRiskMitigation(riskMitigation_);
        _editBrokerConfig(brokerConfig_);
    }

    function cancel() onlyInStates([ICoinDeedFactory.DeedState.SETUP, ICoinDeedFactory.DeedState.READY]) external override {
        bool canCancel = false;
        if (hasRole(MANAGER, address(msg.sender))) {
          canCancel = true;
        } else if (state == ICoinDeedFactory.DeedState.SETUP && block.timestamp > executionTime.recruitingEndTimestamp) {
          canCancel = true;
        } else if (totalSupply < deedSize && block.timestamp > executionTime.buyTimestamp) {
          canCancel = true;
        }
        if (!canCancel) {
          revert("Only manager can cancel the deed or wait for buy time to pass");
        }

        state = ICoinDeedFactory.DeedState.CANCELED;
        deedToken.transfer(manager, stakes[manager]);
        stakes[manager] = 0;
    }

    function withDrawStake() onlyInStates([ICoinDeedFactory.DeedState.SETUP, ICoinDeedFactory.DeedState.CANCELED]) external override {
        if (state == ICoinDeedFactory.DeedState.SETUP) {
            require(executionTime.recruitingEndTimestamp < block.timestamp, "You can not withdraw before recruiting ends.");
        }
        require(msg.sender != manager, "Managers can not withdraw their stake.");
        deedToken.transfer(msg.sender, stakes[msg.sender]);
        stakes[msg.sender] = 0;

    }

    function buyInEth() onlyInState(ICoinDeedFactory.DeedState.READY) external payable override {
        if (pair.tokenA == WETH) {
            IWETH(WETH).deposit{value : msg.value}();
            _buyIn(msg.value);
        } else {
            uint256 tokenAmount = _swapEthToToken(msg.value, pair.tokenA);
            _buyIn(tokenAmount);
        }

    }

    function buyIn(uint256 amount) onlyInState(ICoinDeedFactory.DeedState.READY) external override {
        IERC20 tokenA = IERC20(pair.tokenA);
        tokenA.transferFrom(msg.sender, address(this), amount);
        _buyIn(amount);
    }

    function buyInDifferentToken(address tokenAddress, uint256 amount) onlyInState(ICoinDeedFactory.DeedState.READY) external override {
        uint256 tokenAmount = _swapTokenToToken(true, tokenAddress, amount, pair.tokenA);
        _buyIn(tokenAmount);
    }

    function _buyIn(uint256 amount) internal {
        uint256 maxBuyIn = deedSize.sub(totalSupply);
        uint256 platformFee = coinDeedFactory.platformFee();

        uint256 _amount = amount;
        if (_amount > maxBuyIn) {
          _amount = maxBuyIn;
          uint256 diff = amount.sub(_amount);
          _transfer(pair.tokenA, payable(msg.sender), diff);
        }

        totalSupply = totalSupply.add(_amount);
        buyIns[msg.sender] = buyIns[msg.sender] + _amount;
        coinDeedFactory.emitBuyIn(msg.sender, _amount);
    }

    function payOffEth() onlyInStates([ICoinDeedFactory.DeedState.READY, ICoinDeedFactory.DeedState.CLOSED]) external payable override {
        uint256 tokenAmount = _swapEthToToken(msg.value, address(deedToken));
        _payOff(tokenAmount);
    }

    function payOffDifferentToken(address tokenAddress, uint256 amount) onlyInStates([ICoinDeedFactory.DeedState.READY, ICoinDeedFactory.DeedState.CLOSED]) external override {
        uint256 tokenAmount = _swapTokenToToken(true, tokenAddress, amount, address(deedToken));
        _payOff(tokenAmount);
    }

    function payOff(uint256 amount) onlyInStates([ICoinDeedFactory.DeedState.READY, ICoinDeedFactory.DeedState.CLOSED]) external override {
        _payOff(amount);
    }

    function _payOff(uint256 amount) internal {
        if (amount > loans[msg.sender]) {
            totalLoan = totalLoan.sub(loans[msg.sender]);
            loans[msg.sender] = 0;
            uint256 diff = amount.sub(loans[msg.sender]);
            deedToken.transfer(msg.sender, diff);
            coinDeedFactory.emitPayOff(msg.sender, loans[msg.sender]);
        } else {
            totalLoan = totalLoan.sub(amount);
            loans[msg.sender] = loans[msg.sender].sub(amount);
            coinDeedFactory.emitPayOff(msg.sender, amount);
        }
        coinDeedFactory.emitPayOff(msg.sender, amount);
    }

    function buy() onlyInState(ICoinDeedFactory.DeedState.READY) external override {
        require(block.timestamp >= executionTime.buyTimestamp, "Buy action must be executed once buy time has passed");

        uint256 platformFee = coinDeedFactory.platformFee();
        totalManagementFee = totalSupply.mul(managementFee).div(10000);
        totalPlatformFee = totalSupply.mul(platformFee).div(10000);
        uint256 ownFunds = totalSupply.sub(totalManagementFee).sub(totalPlatformFee);
        totalLoan = ownFunds * (leverage - 1 );
        lendingPool.borrow(pair.tokenA, totalLoan);
        uint256 amountToSwap = ownFunds + totalLoan;

        if(pair.tokenA == address(0x00)) {
            require(amountToSwap <= address(this).balance, "Ether balance must be enough.");
        } else {
            require(amountToSwap <= IERC20(pair.tokenA).balanceOf(address(this)), "ERC20 balance must be enough.");
        }

        // use wholesale to do the swap first
        if (wholesaleId != 0) {
            IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedFactory.wholesaleFactoryAddress());
            IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(wholesaleId);

            // make sure we have enough total supply to execute wholesale
            if (amountToSwap >= wholesale.requestedAmount) {
                if (pair.tokenA == address(0x00)) {
                    wholesaleFactory.executeWholesale{value : wholesale.requestedAmount}(wholesaleId);
                } else {
                    IERC20(pair.tokenA).approve(address(wholesaleFactory), wholesale.requestedAmount);
                    wholesaleFactory.executeWholesale(wholesaleId);
                }
                amountToSwap = amountToSwap.sub(wholesale.requestedAmount);
            }
        }

        // if we still have balance left, use uniswap to complete the rest
        if (amountToSwap > 0) {
            if (pair.tokenA == address(0x00)) {
                _swapEthToToken(amountToSwap, pair.tokenB);
            } else {
                _swapTokenToToken(false, pair.tokenA, amountToSwap, pair.tokenB);
            }
        }

        // by now we should have all the tokenB
        if (pair.tokenB == address(0x00)) {
            totalTokenB = address(this).balance;
            // deposit the funds in lending pool
            lendingPool.deposit{value : totalTokenB}(pair.tokenB, totalTokenB);
        } else {
            IERC20 tokenB = IERC20(pair.tokenB);
            totalTokenB = tokenB.balanceOf(address(this));
            // deposit the funds in lending pool
            tokenB.approve(address(lendingPool), totalTokenB);
            lendingPool.deposit(pair.tokenB, totalTokenB);
        }
        state = ICoinDeedFactory.DeedState.OPEN;
        coinDeedFactory.emitStateChanged(state);
    }

    function sell() onlyInState(ICoinDeedFactory.DeedState.OPEN) external override {
        require(block.timestamp >= executionTime.sellTimestamp, "Sell action must be executed once sell time has passed");
        uint256 amountToSwap = totalTokenB;

        // if we still have balance left, use uniswap to complete the rest
        if (amountToSwap > 0) {
            // todo: need a function in lending pool to check current balance
            lendingPool.withdraw(pair.tokenB, amountToSwap);
            if (pair.tokenB == address(0x00)) {
                _swapEthToToken(amountToSwap, pair.tokenA);
            } else {
                _swapTokenToToken(false, pair.tokenB, amountToSwap, pair.tokenA);
            }
        }

        // by now we should have all the tokenA
        if (pair.tokenA == address(0x00)) {
            totalReturn = address(this).balance;
        } else {
            totalReturn = IERC20(pair.tokenA).balanceOf(address(this));
        }
        state = ICoinDeedFactory.DeedState.CLOSED;
        coinDeedFactory.emitStateChanged(state);
    }

    function claimBalance() onlyInStates([ICoinDeedFactory.DeedState.CLOSED, ICoinDeedFactory.DeedState.CANCELED]) external override {
        uint256 claimAmount = 0;

        if (state == ICoinDeedFactory.DeedState.CLOSED) {
          // buyer can claim tokenA in the same proportion as their buyins
          claimAmount = totalReturn.mul(buyIns[msg.sender]).div(totalSupply);

          // just a sanity check in case division rounds up
          if (claimAmount > totalReturn) {
              claimAmount = totalReturn;
          }
          totalReturn = totalReturn.sub(claimAmount);
        } else {
          // buyer can claim tokenA back
          claimAmount = buyIns[msg.sender];
        }

        // if user has a loan to pay, pay the loan by swapping in deed token
        // the _payoff function takes care of sending back left over deed token
        if (loans[msg.sender] > 0) {
            uint256 deedTokenAmount = _swapTokenToToken(false, pair.tokenA, claimAmount, address(deedToken));
            _payOff(deedTokenAmount);
        } else {
            _transfer(pair.tokenA, payable(msg.sender), claimAmount);
        }

        // reset globals
        totalSupply = totalSupply.sub(buyIns[msg.sender]);
        buyIns[msg.sender] = 0;
        if (state == ICoinDeedFactory.DeedState.CLOSED) {
          totalReturn = totalReturn.sub(claimAmount);
        }
    }

    function claimManagementFee() onlyInState(ICoinDeedFactory.DeedState.CLOSED) external override {
        require(msg.sender == manager || brokerConfig.allowed, "You are not the manager and brokers are not allowed.");

        uint256 fee = _managementFeeForSender();

        require(feeClaimed[msg.sender] == 0, "Validate");

        feeClaimed[msg.sender] = fee;
        totalFeeClaimed = totalFeeClaimed.add(fee);

        uint256 feeInDeedToken = _convertTokens(pair.tokenA, fee, address(deedToken));
        deedToken.mint(msg.sender, feeInDeedToken);
        //TODO transfer the tokenA to treasury

    }

    function _convertTokens(address tokenA, uint256 tokenAAmount, address tokenB) internal returns (uint256 tokenBAmount){
        ILendingPool.PoolInfo memory tokenAPool = lendingPool.poolInfo(tokenA);
        IOracle tokenAOracle = IOracle(tokenAPool.oracle);

        ILendingPool.PoolInfo memory tokenBPool = lendingPool.poolInfo(address(tokenB));
        IOracle tokenBOracle = IOracle(tokenBPool.oracle);

        uint256 intermediateAmount = tokenAAmount
        .mul(10 ** (lendingPool.POOL_DECIMALS().sub(tokenAPool.decimals)))
        .mul(uint256(tokenAOracle.latestAnswer()))
        .div(10 ** tokenAPool.oracleDecimals);

        tokenBAmount = intermediateAmount
        .mul(10 ** (lendingPool.POOL_DECIMALS().sub(tokenBPool.decimals)))
        .mul(uint256(tokenBOracle.latestAnswer()))
        .div(10 ** tokenBPool.oracleDecimals);
    }

    function _managementFee() view internal returns (uint256) {
        return totalReturn.mul(managementFee).div(10000);
    }

    function _managementFeeForSender() view internal returns (uint256) {
        return totalManagementFee.mul(stakes[msg.sender]).div(totalStake);
    }

    function changeLeverage(uint256 salePercentage) external override {

    }

    function _edit(uint256 deedSize_, uint8 leverage_, uint256 managementFee_) internal {
        require(leverage_ <= coinDeedFactory.maxLeverage(), "Leverage can not be greater than maxLeverage.");
        deedSize = deedSize_;
        leverage = leverage_;
        managementFee = managementFee_;
    }

    function _editExecutionTime(ICoinDeedFactory.ExecutionTime memory executionTime_) internal {
        require(executionTime_.recruitingEndTimestamp > block.timestamp, "RecruitingEnd action must be in future.");
        require(executionTime_.recruitingEndTimestamp < executionTime_.buyTimestamp, "RecruitingEnd action must be before buy.");
        require(executionTime_.buyTimestamp < executionTime_.sellTimestamp, "Buy action must be before sell.");
        executionTime = executionTime_;
    }

    function _editRiskMitigation(ICoinDeedFactory.RiskMitigation memory riskMitigation_) internal {
        riskMitigation = riskMitigation_;
    }

    function _editBrokerConfig(ICoinDeedFactory.BrokerConfig memory brokerConfig_) internal {
        if (brokerConfig_.allowed && !brokerConfig.allowed) {
            coinDeedFactory.emitBrokersEnabled();
        }
        brokerConfig = brokerConfig_;
    }

    function _swapToDeedCoin(bool pullFunds, address tokenAddress, uint256 amount) internal virtual returns (uint256 deedTokenAmount){
        return _swapTokenToToken(pullFunds, tokenAddress, amount, address(deedToken));
    }

    function _swapTokenToToken(bool pullFunds, address token1Address, uint256 amount, address token2Address) internal virtual returns (uint256 deedTokenAmount){
        IERC20 token1 = IERC20(token1Address);
        if (pullFunds) {
            token1.transferFrom(msg.sender, address(this), amount);
        }
        token1.approve(address(uniswapRouter1), amount);
        address[] memory path = new address[](2);
        path[0] = token1Address;
        path[1] = token2Address;

        uint[] memory amounts = uniswapRouter1.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _swapEthToDeedCoin(uint256 amount) internal virtual returns (uint256 deedTokenAmount){
        return _swapEthToToken(amount, address(deedToken));
    }

    function _swapEthToToken(uint256 amount, address token) internal virtual returns (uint256 deedTokenAmount){
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(token);

        uint[] memory amounts = uniswapRouter1.swapExactETHForTokens{value : amount}(0, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _transfer(address token, address payable recipient, uint256 amount) internal {
        if (token == address(0x00)) {
            recipient.send(amount);
        } else {
            IERC20 token = IERC20(token);
            token.transfer(recipient, amount);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IToken is IERC20, IAccessControl, IERC165 {


    function mint(address _to, uint256 _amount) external;


    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeedFactory.sol";

interface ICoinDeed {



    /**
    *  Reserve a wholesale to swap on execution time
    */
    function reserveWholesale(uint256 wholesaleId) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    */
    function stake(uint256 amount) external;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    function stakeEth() external payable;

    /**
    *  Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    *  Uses exchange to swap token to DeedCoin
    */
    function stakeDifferentToken(address token, uint256 amount) external;

    /**
    *  Brokers can withdraw their stake
    */
    function withDrawStake() external;

    /**
    *  Edit Broker Config
    */
    function editBrokerConfig(ICoinDeedFactory.BrokerConfig memory brokerConfig) external;

    /**
    *  Edit RiskMitigation
    */
    function editRiskMitigation(ICoinDeedFactory.RiskMitigation memory riskMitigation) external;

    /**
    *  Edit ExecutionTime
    */
    function editExecutionTime(ICoinDeedFactory.ExecutionTime memory executionTime) external;

    /**
    *  Edit DeedInfo
    */
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee) external;

    /**
    *  Edit
    */
    function edit(uint256 deedSize,
        ICoinDeedFactory.ExecutionTime memory executionTime,
        uint8 leverage,
        uint256 managementFee,
        ICoinDeedFactory.RiskMitigation memory riskMitigation,
        ICoinDeedFactory.BrokerConfig memory brokerConfig) external;

    /**
     * Initial swap to buy the tokens
     */
    function buy() external;

    /**
     * Final swap to buy the tokens
     */
    function sell() external;

    /**
    *  Cancels deed if it is not started yet.
    */
    function cancel() external;

    /**
    *  Buyers buys in from the deed
    */
    function buyIn(uint256 amount) external;

    /**
    *  Buyers buys in from the deed with native coin
    */
    function buyInEth() external payable;

    /**
     *  Buyers buys in from the deed with another ERC20
     */
    function buyInDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers pays of their loan
    */
    function payOff(uint256 amount) external;

    /**
    *  Buyers pays of their loan with native coin
    */
    function payOffEth() external payable;

    /**
     *  Buyers pays of their loan with with another ERC20
     */
    function payOffDifferentToken(address tokenAddress, uint256 amount) external;

    /**
    *  Buyers claims their balance if the deed is completed.
    */
    function claimBalance() external;

    /**
    *  Brokers and DeedManager claims their rewards.
    */
    function claimManagementFee() external;

    /**
    *  System changes leverage to be sure that the loan can be paid.
    */
    function changeLeverage(uint256 salePercentage) external;

    /**
    *  Buyers can leave deed before escrow closes.
    */
    function exitDeed() external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./IOracle.sol";

interface ILendingPool {

    struct UserAssetInfo {
        uint256 amount;
        uint256 collateral;
        uint256 borrow;
    }

    // Info of each user.
    struct UserInfo {
        uint256 totalCollateral;
        uint256 totalBorrow;
        bool inBlackList;
    }

    // Info of each pool.
    struct PoolInfo {
        address oracle;
        uint256 oracleDecimals;
        uint256 decimals;
        uint16 apyReward; // reward
        uint16 apyBorrow; // borrow
    }

    function poolInfo(address tokenAddress) external returns (PoolInfo memory);

    function initialize(address _ethOracle) external;

    function POOL_DECIMALS() external returns (uint256);

    function createPool(
        address _tokenAddress,
        address _oracle,
        uint256 _oracleDecimals,
        uint16 _apyReward,
        uint16 _apyBorrow
    ) external;

    function updatePool(
        address _tokenAddress,
        uint256 _decimals, // remove
        address _oracle,
        uint256 _oracleDecimals,
        uint16 _apyReward,
        uint16 _apyBorrow
    ) external;

    function setBlackList(address _blacklistAddress, bool _isBlacklist)
    external;

    // Stake tokens to Pool
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    // Collateral tokens from STAKING.
    function setCollateral(address _tokenAddress, uint256 _amount) external;

    // Borrow
    function borrow(address _tokenAddress, uint256 _amount) external;

    // Pay
    function repay(
        address _tokenAddress,
        uint256 _amount,
        uint256 _fee
    ) external payable;

    // withdraw collateral
    function withdrawCollateral(address _tokenAddress, uint256 _amount)
    external;

    // Withdraw tokens from STAKING.
    function withdraw(address _tokenAddress, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWholesaleFactory {

    enum WholesaleState {OPEN, RESERVED, CANCELLED, COMPLETED, WITHDRAWN}

    struct Wholesale {
        address offeredBy;
        address tokenOffered;
        address tokenRequested;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 minSaleAmount;
        uint256 deadline;
        address reservedTo;
        WholesaleState state;

    }


    event WholesaleCreated(
        uint256 indexed saleId,
        address indexed offeredBy
    );

    event WholesaleCanceled(
        uint256 indexed saleId
    );

    event WholesaleReserved(
        uint256 indexed saleId,
        address indexed reservedBy
    );

    event WholesaleUnreserved(
        uint256 indexed saleId
    );

    event WholesaleExecuted(
        uint256 indexed saleId,
        uint256 indexed tokenOfferedAmount
    );

    event WholesaleWithdrawn(
        uint256 indexed saleId,
        address indexed tokenAddress,
        uint256 indexed amount
    );

    /**
    * Returns number of Open sales to able to browse them
    */
    function openSaleCount() external view returns (uint256);

    /**
    * Returns number of Reserved sales to able to browse them
    */
    function reservedSaleCount() external view returns (uint256);

    /**
    * Returns number of completed sales to able to browse them
    */
    function completedSaleCount() external view returns (uint256);

    /**
    * Returns number of cancelled sales to able to browse them
    */
    function cancelledSaleCount() external view returns (uint256);

    /**
    * Seller creates a wholesale
    */
    function createWholesale(address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo) external;

    /**
    * Seller creates a wholesale with native coin
    */
    function createWholesaleEth(
        address tokenRequested,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo) external payable;

    /**
    * Seller cancels a wholesale before it is reserved
    */
    function cancelWholesale(uint256 saleId) external;

    /**
     * Deed reserves a wholesale
     */
    function reserveWholesale(uint256 saleId) external;

    /**
     * Deed triggers a wholesale
     */
    function executeWholesale(uint256 saleId) external payable;

    /**
     * Returns a wholesale with Id
     */
    function getWholesale(uint256 saleId) external returns (Wholesale memory);

    /**
     * Reserves a wholesale to a deed by seller
     */
    function reserveWholesaleToDeed(uint256 saleId, address deedAddress) external;

    /**
     * Cancels reservation n a wholesale by a deed by seller
     */
    function cancelReservation(uint256 saleId) external;

    /**
     * Withdraw funds from a wholesale
     */
    function withdraw(uint256 saleId) external;

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}