/*

_____/\\\\\\\\\__________________________________/\\\\____________/\\\\______________________________        
 ___/\\\\\\\\\\\\\_______________________________\/\\\\\\________/\\\\\\______________________________       
  __/\\\/////////\\\___/\\\\\\\\\_________________\/\\\//\\\____/\\\//\\\______________________________      
   _\/\\\_______\/\\\__/\\\/////\\\_____/\\\\\\\\__\/\\\\///\\\/\\\/_\/\\\_____/\\\\\\\\___/\\\____/\\\_     
    _\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\____/\\\/////\\\_\/\\\__\///\\\/___\/\\\___/\\\/////\\\_\///\\\/\\\/__    
     _\/\\\/////////\\\_\/\\\//////____/\\\\\\\\\\\__\/\\\____\///_____\/\\\__/\\\\\\\\\\\____\///\\\/____   
      _\/\\\_______\/\\\_\/\\\_________\//\\///////___\/\\\_____________\/\\\_\//\\///////______/\\\/\\\___  
       _\/\\\_______\/\\\_\/\\\__________\//\\\\\\\\\\_\/\\\_____________\/\\\__\//\\\\\\\\\\__/\\\/\///\\\_ 
        _\///________\///__\///____________\//////////__\///______________\///____\//////////__\///____\///__

Margin V2.3 (upgradeable dex address, config contract, owed and input params in the OnOpenPositionEvent)

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Uniswap.sol";
import "./interfaces/IUniMexFactory.sol";
import "./interfaces/IUniMexPool.sol";
import "./interfaces/ISwapPathCreator.sol";
import "./interfaces/IPositionAmountChecker.sol";
import "./interfaces/IUniMexStaking.sol";
import "./interfaces/IUnimexConfig.sol";

/**
 * Margin contract. Does not support tokens with fees on transfers
 */
contract UniMexMargin is Ownable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    address private immutable BASE_TOKEN_ADDRESS;
    IERC20 public immutable BASE_TOKEN;

    address public immutable WETH_ADDRESS;

    uint256 public constant MAG = 1e18;
    uint256 public constant LIQUIDATION_MARGIN = 1.1e18; //10%
    uint256 public thresholdGasPrice = 3e8; //gas price in wei used to calculate bonuses for liquidation, sl, tp
    uint32 public borrowInterestPercentScaled = 100; //10%
    uint256 public constant YEAR = 31536000;
    uint256 public positionNonce = 0;
    bool public paused = false;
    IPositionAmountChecker public positionAmountChecker;

    uint256 public amountThresholds;

    struct Position {
        uint256 owed;
        uint256 input;
        uint256 commitment;
        address token;
        bool isShort;
        uint32 startTimestamp;
        uint32 borrowInterest;
        address owner;
        uint32 stopLossPercent;
        uint32 takeProfitPercent;
    }

    struct Limit {
        uint256 amount;
        uint256 minimalSwapAmount;
        address token;
        bool isShort;
        uint32 validBefore;
        uint32 leverageScaled;
        address owner;
        uint32 takeProfitPercent;
        uint32 stopLossPercent;
        uint256 escrowAmount;
    }
    
    mapping(bytes32 => Position) public positionInfo;
    mapping(bytes32 => Limit) public limitOrders;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public escrow;
    
    IUniMexStaking public staking;
    IUniMexFactory public immutable unimex_factory;
    IUniswapV2Factory public uniswap_factory;
    IUniswapV2Router02 public uniswap_router;
    ISwapPathCreator public swapPathCreator;
    IUnimexConfig public immutable unimexConfig;

    event OnClosePosition(
        bytes32 indexed positionId,
        address token,
        address indexed owner,
        uint256 owed,
        uint256 input,
        uint256 commitment,
        uint32 startTimestamp,
        bool isShort,
        uint256 borrowInterest,
        uint256 liquidationBonus, //amount that went to liquidator when position was liquidated. 0 if position was closed
        uint256 scaledCloseRate // busd/token multiplied by 1e18
    );

    event OnOpenPosition(
        address indexed sender,
        bytes32 positionId,
        bool isShort,
        address indexed token,
        uint256 scaledLeverage,
        uint256 owed,
        uint256 input,
        uint32 takeProfitPercent,
        uint32 stopLossPercent
    );

    event OnAddCommitment(
        bytes32 indexed positionId,
        uint256 amount
    );

    event OnLimitOrder(
        bytes32 indexed limitOrderId,
        address indexed owner,
        address token,
        uint256 amount,
        uint256 minimalSwapAmount,
        uint256 leverageScaled,
        uint32 validBefore,
        uint256 escrowAmount,
        uint32 takeProfitPercent,
        uint32 stopLossPercent,
        bool isShort
    );

    event OnLimitOrderCancelled(
        bytes32 indexed limitOrderId
    );

    event OnLimitOrderCompleted(
        bytes32 indexed limitOrderId,
        bytes32 positionId
    );

    event OnTakeProfit(
        bytes32 indexed positionId,
        uint256 positionInput,
        uint256 swapAmount,
        address token,
        bool isShort
    );

    event OnStopLoss(
        bytes32 indexed positionId,
        uint256 positionInput,
        uint256 swapAmount,
        address token,
        bool isShort
    );

    //to prevent flashloans
    modifier isHuman() {
        require(msg.sender == tx.origin);
        _;
    }

    constructor(
        address _staking,
        address _factory,
        address _busd,
        address _weth,
        address _uniswap_factory,
        address _uniswap_router,
        address _swapPathCreator,
        address _unimexConfig
    ) public {
        staking = IUniMexStaking(_staking);
        unimex_factory = IUniMexFactory(_factory);
        BASE_TOKEN_ADDRESS = _busd;
        BASE_TOKEN = IERC20(_busd);
        uniswap_factory = IUniswapV2Factory(_uniswap_factory);
        uniswap_router = IUniswapV2Router02(_uniswap_router);
        swapPathCreator = ISwapPathCreator(_swapPathCreator);
        unimexConfig = IUnimexConfig(_unimexConfig);

        WETH_ADDRESS = _weth;

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        amountThresholds = 275;
    }

    function deposit(uint256 _amount) public {
        BASE_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
    }

    function withdraw(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        BASE_TOKEN.safeTransfer(msg.sender, _amount);
    }

    function calculateBorrowInterest(bytes32 positionId) public view returns (uint256) {
        Position storage position = positionInfo[positionId];
        uint256 loanTime = block.timestamp.sub(position.startTimestamp);
        return position.owed.mul(loanTime).mul(position.borrowInterest).div(1000).div(YEAR);
    }

    function openShortPosition(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, 0, 0];
        _openPosition(msg.sender, token, true, values);
    }

    function openLongPosition(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, 0, 0];
        _openPosition(msg.sender, token, false, values);
    }

    function openShortPositionWithSlTp(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount,
        uint256 takeProfitPercent, uint256 stopLossPercent) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, takeProfitPercent, stopLossPercent];
        _openPosition(msg.sender, token, true, values);
    }

    function openLongPositionWithSlTp(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount,
            uint256 takeProfitPercent, uint256 stopLossPercent) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, takeProfitPercent, stopLossPercent];
        _openPosition(msg.sender, token, false, values);
    }

    /**
    * values[0] amount
    * values[1] scaledLeverage
    * values[2] minimalSwapAmount
    * values[3] takeProfitPercent
    * values[4] stopLossPercent
    */
    function _openPosition(address owner, address token, bool isShort, uint256[5] memory values)
                                                                        private nonReentrant returns (bytes32) {
        require(!paused, "PAUSED");
        require(values[0] > 0, "AMOUNT_ZERO");
        require(values[4] < 1e6, "STOPLOSS EXCEEDS MAX");
        address pool = unimex_factory.getPool(address(isShort ? IERC20(token) : BASE_TOKEN));

        require(pool != address(0), "POOL_DOES_NOT_EXIST");
        require(values[1] <= unimexConfig.getMaxLeverage(token).mul(MAG), "LEVERAGE_EXCEEDS_MAX");

        if(address(positionAmountChecker) != address(0)) {
            (address baseToken, address quoteToken) = isShort ? (token, BASE_TOKEN_ADDRESS) : (BASE_TOKEN_ADDRESS, token);
            require(positionAmountChecker.checkPositionAmount(baseToken, quoteToken, values[0], values[1]),
                "NOT_ENOUGH_UNISWAP_LIQUIDITY");
        }

        uint256 amountInBusd = isShort ? swapPathCreator.calculateConvertedValue(token, BASE_TOKEN_ADDRESS, values[0]) : values[0];
        uint256 commitment = getCommitment(amountInBusd, values[1]);
        uint256 commitmentWithLb = commitment.add(calculateAutoCloseBonus());
        require(balanceOf[owner] >= commitmentWithLb, "NO_BALANCE");

        IUniMexPool(pool).borrow(values[0]);

        uint256 swap;

        {
            (address baseToken, address quoteToken) = isShort ? (token, BASE_TOKEN_ADDRESS) : (BASE_TOKEN_ADDRESS, token);
            swap = swapTokens(baseToken, quoteToken, values[0]);
            require(swap >= values[2], "INSUFFICIENT_SWAP");
        }

        uint256 fees = (swap.mul(4)).div(1000);

        swap = swap.sub(fees);

        if(!isShort) {
            fees = swapTokens(token, BASE_TOKEN_ADDRESS, fees); // convert fees to BUSD
        }

        transferFees(fees, pool);

        transferUserToEscrow(owner, owner, commitmentWithLb);

        positionNonce = positionNonce + 1; //possible overflow is ok
        bytes32 positionId = getPositionId(
            owner,
            token,
            values[0],
            values[1],
            positionNonce
        );

        Position memory position = Position({
            owed: values[0],
            input: swap,
            commitment: commitmentWithLb,
            token: token,
            isShort: isShort,
            startTimestamp: uint32(block.timestamp),
            owner: owner,
            borrowInterest: borrowInterestPercentScaled,
            takeProfitPercent: uint32(values[3]),
            stopLossPercent: uint32(values[4])
        });

        positionInfo[positionId] = position;
        emit OnOpenPosition(owner, positionId, isShort, token, values[1], values[0], swap, position.takeProfitPercent,
            position.stopLossPercent);
        if(position.takeProfitPercent > 0) {
            emit OnTakeProfit(positionId, swap, position.takeProfitPercent, token, isShort);
        }
        if(position.stopLossPercent > 0) {
            emit OnStopLoss(positionId, swap, position.stopLossPercent, token, isShort);
        }
        return positionId;
    }

    /**
    * @dev add additional commitment to an opened position. The amount
    * must be initially approved
    * @param positionId id of the position to add commitment
    * @param amount the amount to add to commitment
    */
    function addCommitmentToPosition(bytes32 positionId, uint256 amount) public {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        position.commitment = position.commitment.add(amount);
        BASE_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        escrow[position.owner] = escrow[position.owner].add(amount);
        emit OnAddCommitment(positionId, amount);
    }

    /**
    * @dev allows anyone to close position if it's loss exceeds threshold
    */
    function setStopLoss(bytes32 positionId, uint32 percentAmount) public {
        require(percentAmount < 1e6, "STOPLOSS EXCEEDS MAX");
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "NOT_OWNER");
        position.stopLossPercent = percentAmount;
        emit OnStopLoss(positionId, position.input, percentAmount, position.token, position.isShort);
    }

    /**
    * @dev allows anyone to close position if it's profit exceeds threshold
    */
    function setTakeProfit(bytes32 positionId, uint32 percentAmount) public {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "NOT_OWNER");
        position.takeProfitPercent = percentAmount;
        emit OnTakeProfit(positionId, position.input, percentAmount, position.token, position.isShort);
    }

    function autoClose(bytes32 positionId) public isHuman {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);

        //check constraints
        (address baseToken, address quoteToken) = position.isShort ? (BASE_TOKEN_ADDRESS, position.token) : (position.token, BASE_TOKEN_ADDRESS);
        uint256 swapAmount = swapPathCreator.calculateConvertedValue(baseToken, quoteToken, position.input);
        uint256 hundredPercent = 1e6;
        require((position.takeProfitPercent != 0 && position.owed.mul(hundredPercent.add(position.takeProfitPercent)).div(hundredPercent) <= swapAmount) ||
            (position.stopLossPercent != 0 && position.owed.mul(hundredPercent.sub(position.stopLossPercent)).div(hundredPercent) >= swapAmount), "SL_OR_TP_UNAVAILABLE");

        //withdraw bonus from position commitment
        uint256 closeBonus = calculateAutoCloseBonus();
        position.commitment = position.commitment.sub(closeBonus);
        BASE_TOKEN.safeTransfer(msg.sender, closeBonus);
        transferEscrowToUser(position.owner, address(0), closeBonus);
        _closePosition(positionId, position, 0);
    }

    function calculateAutoOpenBonus() public view returns(uint256) {
        return thresholdGasPrice.mul(510000);
    }

    function calculateAutoCloseBonus() public view returns(uint256) {
        return thresholdGasPrice.mul(270000);
    }

    /**
    * @dev opens position that can be opened at a specific price
    */
    function openLimitOrder(address token, bool isShort, uint256 amount, uint256 minimalSwapAmount,
            uint256 leverageScaled, uint32 validBefore, uint32 takeProfitPercent, uint32 stopLossPercent) public  {
        require(!paused, "PAUSED");
        require(stopLossPercent < 1e6, "STOPLOSS EXCEEDS MAX");
        require(validBefore > block.timestamp, "INCORRECT_EXP_DATE");
        uint256[3] memory values256 = [amount, minimalSwapAmount, leverageScaled];
        uint32[3] memory values32 = [validBefore, takeProfitPercent, stopLossPercent];
        _openLimitOrder(token, isShort, values256, values32);
    }

    /**
    * @dev values256[0] - amount
    *      values256[1] - minimal swap amount
    *      values256[2] - scaled leverage
    *      values32[0] - valid before
    *      values32[1] - take profit percent
    *      values32[2] - stop loss percent
    */
    function _openLimitOrder(address token, bool isShort, uint256[3] memory values256, uint32[3] memory values) private {
        uint256 escrowAmount; //stack depth optimization
        {
            uint256 commitment = isShort ? getCommitment(values256[1], values256[2]) : getCommitment(values256[0], values256[2]);
            escrowAmount = commitment.add(calculateAutoOpenBonus()).add(calculateAutoCloseBonus());
            require(balanceOf[msg.sender] >= escrowAmount, "INSUFFICIENT_BALANCE");
            transferUserToEscrow(msg.sender, msg.sender, escrowAmount);
        }

        bytes32 limitOrderId = _getLimitOrderId(token, values256[0], values256[1], values256[2],
            values[0], msg.sender, isShort);
        Limit memory limitOrder = Limit({
            token: token,
            amount: values256[0],
            minimalSwapAmount: values256[1],
            leverageScaled: uint32(values256[2].div(1e14)),
            validBefore: values[0],
            owner: msg.sender,
            escrowAmount: escrowAmount,
            isShort: isShort,
            takeProfitPercent: values[1],
            stopLossPercent: values[2]
        });
        limitOrders[limitOrderId] = limitOrder;
        emitLimitOrderEvent(limitOrderId, token, values256, values, escrowAmount, isShort);
    }

    function emitLimitOrderEvent(bytes32 limitOrderId, address token, uint256[3] memory values256,
        uint32[3] memory values, uint256 escrowAmount, bool isShort) private  {
        emit OnLimitOrder(limitOrderId, msg.sender, token, values256[0], values256[1], values256[2], values[0], escrowAmount,
            values[1], values[2], isShort);
    }

    function cancelLimitOrder(bytes32 limitOrderId) public {
        Limit storage limitOrder = limitOrders[limitOrderId];
        require(limitOrder.owner == msg.sender, "NOT_OWNER");
        transferEscrowToUser(limitOrder.owner, limitOrder.owner, limitOrder.escrowAmount);
        delete limitOrders[limitOrderId];
        emit OnLimitOrderCancelled(limitOrderId);
    }

    function autoOpen(bytes32 limitOrderId) public isHuman {
        //get limit order
        Limit storage limitOrder = limitOrders[limitOrderId];
        require(limitOrder.owner != address(0), "NO_ORDER");
        require(limitOrder.validBefore >= uint32(block.timestamp), "EXPIRED");

        //check open rate
        (address baseToken, address quoteToken) = limitOrder.isShort ? (limitOrder.token, BASE_TOKEN_ADDRESS) : (BASE_TOKEN_ADDRESS, limitOrder.token);
        uint256 swapAmount = swapPathCreator.calculateConvertedValue(baseToken, quoteToken, limitOrder.amount);
        require(swapAmount >= limitOrder.minimalSwapAmount, "LIMIT_NOT_SATISFIED");

        uint256 openBonus = calculateAutoOpenBonus();
        //transfer bonus from escrow to caller
        BASE_TOKEN.transfer(msg.sender, openBonus);

        transferEscrowToUser(limitOrder.owner, limitOrder.owner, limitOrder.escrowAmount.sub(openBonus));
        transferEscrowToUser(limitOrder.owner, address(0), openBonus);

        //open position for user
        uint256[5] memory values = [limitOrder.amount, uint256(limitOrder.leverageScaled.mul(1e14)),
            limitOrder.minimalSwapAmount, uint256(limitOrder.takeProfitPercent), uint256(limitOrder.stopLossPercent)];

        bytes32 positionId = _openPosition(limitOrder.owner, limitOrder.token, limitOrder.isShort, values);

        //delete order id
        delete limitOrders[limitOrderId];
        emit OnLimitOrderCompleted(limitOrderId, positionId);
    }

    function _getLimitOrderId(address token, uint256 amount, uint256 minSwapAmount,
            uint256 scaledLeverage, uint256 validBefore, address owner, bool isShort) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, amount, minSwapAmount, scaledLeverage, validBefore,
            owner, isShort));
    }

    function _checkPositionIsOpen(Position storage position) private view {
        require(position.owner != address(0), "NO_OPEN_POSITION");
    }

    function closePosition(bytes32 positionId, uint256 minimalSwapAmount) external isHuman {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "BORROWER_ONLY");
        _closePosition(positionId, position, minimalSwapAmount);
    }

    function _closePosition(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private nonReentrant{
        uint256 scaledRate;
        if(position.isShort) {
            scaledRate = _closeShort(positionId, position, minimalSwapAmount);
        }else{
            scaledRate = _closeLong(positionId, position, minimalSwapAmount);
        }
        deletePosition(positionId, position, 0, scaledRate);
    }

    function _closeShort(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private returns (uint256){
        uint256 input = position.input;
        uint256 owed = position.owed;
        uint256 commitment = position.commitment;

        address pool = unimex_factory.getPool(position.token);

        uint256 poolInterestInTokens = calculateBorrowInterest(positionId);
        uint256 swap = swapTokens(BASE_TOKEN_ADDRESS, position.token, input);
        require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
        uint256 scaledRate = calculateScaledRate(input, swap);
        require(swap >= owed.add(poolInterestInTokens).mul(input).div(input.add(commitment)), "LIQUIDATE_ONLY");

        bool isProfit = owed < swap;
        uint256 amount;

        uint256 fees = poolInterestInTokens > 0 ? swapPathCreator.calculateConvertedValue(position.token, address(BASE_TOKEN), poolInterestInTokens) : 0;
        if(isProfit) {
            uint256 profitInTokens = swap.sub(owed);
            amount = swapTokens(position.token, BASE_TOKEN_ADDRESS, profitInTokens); //profit in eth
        } else {
            uint256 commitmentInTokens = swapTokens(BASE_TOKEN_ADDRESS, position.token, commitment);
            uint256 remainder = owed.sub(swap);
            require(commitmentInTokens >= remainder, "LIQUIDATE_ONLY");
            amount = swapTokens(position.token, BASE_TOKEN_ADDRESS, commitmentInTokens.sub(remainder)); //return to user's balance
        }
        if(isProfit) {
            if(amount >= fees) {
                transferEscrowToUser(position.owner, position.owner, commitment);
                transferToUser(position.owner, amount.sub(fees));
            } else {
                uint256 remainder = fees.sub(amount);
                transferEscrowToUser(position.owner, position.owner, commitment.sub(remainder));
                transferEscrowToUser(position.owner, address(0), remainder);
            }
        } else {
            require(amount >= fees, "LIQUIDATE_ONLY"); //safety check
            transferEscrowToUser(position.owner, address(0x0), commitment);
            transferToUser(position.owner, amount.sub(fees));
        }
        transferFees(fees, pool);

        transferToPool(pool, position.token, owed);

        return scaledRate;
    }

    function _closeLong(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private returns (uint256){
        uint256 input = position.input;
        uint256 owed = position.owed;
        address pool = unimex_factory.getPool(BASE_TOKEN_ADDRESS);

        uint256 fees = calculateBorrowInterest(positionId);
        uint256 swap = swapTokens(position.token, BASE_TOKEN_ADDRESS, input);
        require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
        uint256 scaledRate = calculateScaledRate(swap, input);
        require(swap.add(position.commitment) >= owed.add(fees), "LIQUIDATE_ONLY");

        uint256 commitment = position.commitment;

        bool isProfit = swap >= owed;
        if(isProfit) {
            uint256 amount = swap.sub(owed);
            transferToPool(pool, BASE_TOKEN_ADDRESS, owed);
            if(fees <= amount) {
                transferEscrowToUser(position.owner, position.owner, commitment);
                transferToUser(position.owner, amount.sub(fees));
            } else {
                transferEscrowToUser(position.owner, position.owner, commitment.sub(fees.sub(amount)));
            }
        } else {
            uint256 amount = commitment.sub(owed.sub(swap));
            transferToPool(pool, BASE_TOKEN_ADDRESS, owed);
            transferEscrowToUser(position.owner, address(0x0), commitment);
            transferToUser(position.owner, amount.sub(fees));
        }
        transferFees(fees, pool);

        return scaledRate;
    }


    /**
    * @dev helper function, indicates when a position can be liquidated.
    * Liquidation threshold is when position input plus commitment can be converted to 110% of owed tokens
    */
    function canLiquidate(bytes32 positionId) public view returns(bool) {
        Position storage position = positionInfo[positionId];
        uint256 liquidationBonus = calculateAutoCloseBonus();
        uint256 canReturn;
        if(position.isShort) {
            uint256 positionBalance = position.input.add(position.commitment);
            uint256 valueToConvert = positionBalance < liquidationBonus ? 0 : positionBalance.sub(liquidationBonus);
            canReturn = swapPathCreator.calculateConvertedValue(BASE_TOKEN_ADDRESS, position.token, valueToConvert);
        } else {
            uint256 canReturnOverall = swapPathCreator.calculateConvertedValue(position.token, BASE_TOKEN_ADDRESS, position.input)
                    .add(position.commitment);
            canReturn = canReturnOverall < liquidationBonus ? 0 : canReturnOverall.sub(liquidationBonus);
        }
        uint256 poolInterest = calculateBorrowInterest(positionId);
        return canReturn < position.owed.add(poolInterest).mul(LIQUIDATION_MARGIN).div(MAG);
    }

    /**
    * @dev Liquidates position and sends a liquidation bonus from user's commitment to a caller.
    */
    function liquidatePosition(bytes32 positionId, uint256 minimalSwapAmount) external isHuman nonReentrant {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        uint256 canReturn;
        uint256 poolInterest = calculateBorrowInterest(positionId);

        uint256 liquidationBonus = calculateAutoCloseBonus();
        uint256 liquidatorBonus;
        uint256 scaledRate;
        if(position.isShort) {
            uint256 positionBalance = position.input.add(position.commitment);
            uint256 valueToConvert;
            (valueToConvert, liquidatorBonus) = _safeSubtract(positionBalance, liquidationBonus);
            canReturn = swapTokens(BASE_TOKEN_ADDRESS, position.token, valueToConvert);
            require(canReturn >= minimalSwapAmount, "INSUFFICIENT_SWAP");
            scaledRate = calculateScaledRate(valueToConvert, canReturn);
        } else {
            uint256 swap = swapTokens(position.token, BASE_TOKEN_ADDRESS, position.input);
            require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
            scaledRate = calculateScaledRate(swap, position.input);
            uint256 canReturnOverall = swap.add(position.commitment);
            (canReturn, liquidatorBonus) = _safeSubtract(canReturnOverall, liquidationBonus);
        }
        require(canReturn < position.owed.add(poolInterest).mul(LIQUIDATION_MARGIN).div(MAG), "CANNOT_LIQUIDATE");

        _liquidate(position, canReturn, poolInterest);

        transferEscrowToUser(position.owner, address(0x0), position.commitment);
        BASE_TOKEN.safeTransfer(msg.sender, liquidatorBonus);

        deletePosition(positionId, position, liquidatorBonus, scaledRate);
    }

    function _liquidate(Position memory position, uint256 canReturn, uint256 fees) private {
        address baseToken = position.isShort ? position.token : BASE_TOKEN_ADDRESS;
        address pool = unimex_factory.getPool(baseToken);
        if(canReturn > position.owed) {
            transferToPool(pool, baseToken, position.owed);
            uint256 remainder = canReturn.sub(position.owed);
            if(remainder > fees) { //can pay fees completely
                if(position.isShort) {
                    remainder = swapTokens(position.token, BASE_TOKEN_ADDRESS, remainder);
                    if(fees > 0) { //with fees == 0 calculation is reverted with "UV2: insufficient input amount"
                        fees = swapPathCreator.calculateConvertedValue(position.token, BASE_TOKEN_ADDRESS, fees);
                        if(fees > remainder) { //safety check
                            fees = remainder;
                        }
                    }
                }
                transferFees(fees, pool);
                transferToUser(position.owner, remainder.sub(fees));
            } else { //all is left is for fees
                if(position.isShort) {
                    //convert remainder to busd
                    remainder = swapTokens(position.token, BASE_TOKEN_ADDRESS, canReturn.sub(position.owed));
                }
                transferFees(remainder, pool);
            }
        } else {
            //return to pool all that's left
            uint256 correction = position.owed.sub(canReturn);
            IUniMexPool(pool).distributeCorrection(correction);
            transferToPool(pool, baseToken, canReturn);
        }
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        staking = IUniMexStaking(_staking);
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner public {
        paused = true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner public {
        paused = false;
    }

    function setThresholdGasPrice(uint256 gasPrice) public {
        require(hasRole(LIQUIDATOR_ROLE, msg.sender), "NOT_LIQUIDATOR");
        require(gasPrice <= 5000e9, "GAS PRICE EXCEEDS MAX");
        thresholdGasPrice = gasPrice;
    }

    /**
    * @dev set interest rate for tokens owed from pools. Scaled to 10 (e.g. 150 is 15%)
    */
    function setBorrowPercent(uint32 _newPercentScaled) external onlyOwner {
        require(borrowInterestPercentScaled <= 1000, "interest exceeds max");
        borrowInterestPercentScaled = _newPercentScaled;
    }

    function calculateScaledRate(uint256 busdAmount, uint256 tokenAmount) private pure returns (uint256 scaledRate) {
        if(tokenAmount == 0) {
            return 0;
        }
        return busdAmount.mul(MAG).div(tokenAmount);
    }

    function transferUserToEscrow(address from, address to, uint256 amount) private {
        require(balanceOf[from] >= amount);
        balanceOf[from] = balanceOf[from].sub(amount);
        escrow[to] = escrow[to].add(amount);
    }

    function transferEscrowToUser(address from, address to, uint256 amount) private {
        require(escrow[from] >= amount);
        escrow[from] = escrow[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function transferToUser(address to, uint256 amount) private {
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function getPositionId(
        address maker,
        address token,
        uint256 amount,
        uint256 leverage,
        uint256 nonce
    ) private pure returns (bytes32 positionId) {
        //date acts as a nonce
        positionId = keccak256(
            abi.encodePacked(maker, token, amount, leverage, nonce)
        );
    }

    function swapTokens(address baseToken, address quoteToken, uint256 input) private returns (uint256 swap) {
        if(input == 0) {
            return 0;
        }
        IERC20(baseToken).approve(address(uniswap_router), input);
        address[] memory path = swapPathCreator.getPath(baseToken, quoteToken);
        uint256 balanceBefore = IERC20(quoteToken).balanceOf(address(this));

        IUniswapV2Router02(uniswap_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            input,
            0, //checks are done after swap in caller functions
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = IERC20(quoteToken).balanceOf(address(this));
        swap = balanceAfter.sub(balanceBefore);
    }

    function getCommitment(uint256 _amount, uint256 scaledLeverage) private pure returns (uint256 commitment) {
        commitment = (_amount.mul(MAG)).div(scaledLeverage);
    }

    function transferFees(uint256 busdFees, address pool) private {
        uint256 fees = swapTokens(BASE_TOKEN_ADDRESS, WETH_ADDRESS, busdFees); // convert fees to ETH
        uint256 halfFees = fees.div(2);

        // Pool fees
        IERC20(WETH_ADDRESS).approve(pool, halfFees);
        IUniMexPool(pool).distribute(halfFees);

        // Staking Fees
        IERC20(WETH_ADDRESS).approve(address(staking), fees.sub(halfFees));
        staking.distribute(fees.sub(halfFees));
    }

    function transferToPool(address pool, address token, uint256 amount) private {
        IERC20(token).approve(pool, amount);
        IUniMexPool(pool).repay(amount);
    }


    function _safeSubtract(uint256 from, uint256 amount) private pure returns (uint256 remainder, uint256 subtractedAmount) {
        if(from < amount) {
            remainder = 0;
            subtractedAmount = from;
        } else {
            remainder = from.sub(amount);
            subtractedAmount = amount;
        }
    }

    function setAmountThresholds(uint32 leverage5) public onlyOwner {
        amountThresholds = leverage5;
    }

    function deletePosition(bytes32 positionId, Position storage position, uint256 liquidatedAmount, uint256 scaledRate) private {
        emit OnClosePosition(
            positionId,
            position.token,
            position.owner,
            position.owed,
            position.input,
            position.commitment,
            position.startTimestamp,
            position.isShort,
            position.borrowInterest,
            liquidatedAmount,
            scaledRate
        );
        delete positionInfo[positionId];
    }

    function setSwapPathCreator(address newAddress) external onlyOwner {
        require(newAddress != address(0), "ZERO ADDRESS");
        swapPathCreator = ISwapPathCreator(newAddress);
    }

    function setPositionAmountChecker(address checker) external onlyOwner {
        positionAmountChecker = IPositionAmountChecker(checker);
    }

    function updateUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(0), "zero address");
        uniswap_router = IUniswapV2Router02(newAddress);
    }

    function updateUniswapFactory(address newAddress) external onlyOwner {
        require(newAddress != address(0), "zero address");
        uniswap_factory = IUniswapV2Factory(newAddress);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address a, address b) external view returns (address p);
}

interface IUniswapV2Router02 {
    function WETH() external returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UV2: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UV2: ZERO_ADDRESS');
    }
    
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UV2: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UV2: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
//        pair = address(uint(keccak256(abi.encodePacked(
//                hex'ff',
//                factory,
//                keccak256(abi.encodePacked(token0, token1)),
//                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
//            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniMexFactory {
  function getPool(address) external view returns(address);
  function getMaxLeverage(address) external view returns(uint256);
  function allowedMargins(address) external view returns (bool);
  function utilizationScaled(address token) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniMexPool {
    function borrow(uint256 _amount) external;
    function distribute(uint256 _amount) external;
    function distributeCorrections(uint256 _amount) external;
    function repay(uint256 _amount) external returns (bool);
    function distributeCorrection(uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ISwapPathCreator {

    function getPath(address baseToken, address quoteToken) external view returns (address[] memory);

    function calculateConvertedValue(address baseToken, address quoteToken, uint256 amount) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IPositionAmountChecker {

    function checkPositionAmount(address baseToken, address quoteToken, uint256 amount, uint256 leverageScaled) external view returns (bool);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniMexStaking {
    function distribute(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUnimexConfig {

    function getMaxLeverage(address token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

