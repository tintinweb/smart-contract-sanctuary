// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/SafeMath.sol";
import "./interfaces/IVeeProxyController.sol";
import "./interfaces/IERC20.sol";
import "./VeeSystemController.sol";
import "./interfaces/compound/CEtherInterface.sol";
import "./interfaces/uniswap/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/compound/CTokenInterfaces.sol";
import "./interfaces/uniswap/IUniswapV2Factory.sol";
import "./interfaces/uniswap/IUniswapV2Pair.sol";
import "./interfaces/uniswap/IUniswapV2Router02.sol";
/**
 * @title  Vee's proxy Contract
 * @notice Implementation of the {VeeProxyController} interface.
 * @author Vee.Finance
 */
contract VeeProxyController is IVeeProxyController, VeeSystemController, Initializable{    
    using SafeMath for uint256;

   address private _priceOracleAddress;
   address private _cether;
   IUniswapV2Router02 private _router;


    /**
     * @dev increasing number for generating random.
     */
    uint256 private nonce;

    /**
     * @dev Comptroller is the risk management layer of the Compound protocol.
     */
    // ComptrollerInterface public comptroller;

    


    enum StateCode {
            EXECUTE,
            EXPIRED,
            NOT_RUN
        }



    /**
     * @dev Order data
     */
    struct Order {
        address orderOwner;
        address ctokenA;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 stopHighPairPrice;
        uint256 stopLowPairPrice;
        uint256 expiryDate;
        bool    autoRepay;
        uint256 maxSlippage;
    }

    /**
     * @dev Orders
     */
    mapping (bytes32 => Order) public orders;

    receive() payable external{}
    /**
     * @dev Sets the values for {comptroller} and {router}.
     */
    // function initialize(address comptroller_, address router_, address cether,address veeFactoryAddress, address veeSwapAddress, address veeOracleAddress) public initializer {
    //     _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
    //     _setRoleAdmin(EXECUTOR_ROLE,    PROXY_ADMIN_ROLE);

    //     // deployer + self administration
    //     _setupRole(PROXY_ADMIN_ROLE, _msgSender());
    //     _setupRole(PROXY_ADMIN_ROLE, address(this));

    //     // executor
    //     _setupRole(EXECUTOR_ROLE, _msgSender());   

    //     comptroller = ComptrollerInterface(comptroller_);   

    //     veeProxyFactory = VeeProxyFactory(veeFactoryAddress);
    //     veeSwap = AbsVeeSwap(veeSwapAddress);
    //     veeOracle = IVeePriceOracle(veeOracleAddress);
    //     _cether = cether;

    //     _notEntered = true;
    // }

    constructor (address router_, address cether){
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE,    PROXY_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(PROXY_ADMIN_ROLE, _msgSender());
        _setupRole(PROXY_ADMIN_ROLE, address(this));

        // executor
        _setupRole(EXECUTOR_ROLE, _msgSender());   

        _cether = cether;
        _router = IUniswapV2Router02(router_);
        _notEntered = true;
    }


     /**
     * @dev Sender create a stop-limit order with the below conditions.
     *
     * @param orderOwner  The address of order owner
     * @param ctokenA     The address of ctoken A
     * @param tokenA      The address of token A
     * @param tokenB      The address of token B
     * @param amountA     The token A amount
     * @param stopHighPairPrice  limit token pair price
     * @param stopLowPairPrice   stop token pair price
     * @param expiryDate   expiry date
     * @param autoRepay    if automatically repay borrow after trading
     * @param maxSlippage    if automatically repay borrow after trading
     *
     * @return orderId 
     */
    function createOrderERC20ToERC20(address orderOwner, address ctokenA, address tokenA, address tokenB, uint256 amountA, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external veeLock(uint8(VeeLockState.LOCK_CREATE)) override returns (bytes32 orderId){
        require(orderOwner != address(0), "createOrder: invalid order owner");
        require(ctokenA != address(0), "createOrder: invalid ctoken A");
        require(stopHighPairPrice != 0, "createOrder: invalid limit price");
        require(stopLowPairPrice != 0, "createOrder: invalid stop limit");
        require(amountA != 0, "createOrder: amountA can't be zero.");
        require(expiryDate > block.timestamp, "createOrder: expiry date must be in future.");
        
        {
            IERC20 erc20TokenA = IERC20(tokenA);
            uint256 allowance = erc20TokenA.allowance(msg.sender, address(this));
            require(allowance >= amountA,"allowance must bigger than amountA");
            assert(erc20TokenA.transferFrom(msg.sender, address(this), amountA));
        }
        
       // swap tokens
       uint256[] memory amounts = swapERC20ToERC20(tokenA, amountA, tokenB, maxSlippage);
       orderId = keccak256(abi.encode(orderOwner, amountA, tokenA, tokenB, getRandom()));
    
       emit OnTokenSwapped(orderId, orderOwner, tokenA, tokenB, amounts[0], amounts[1]);
       emit OnOrderCreated(orderId, orderOwner, tokenA, tokenB, amountA, stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);

        {
            Order memory order = Order(orderOwner, ctokenA, tokenA, tokenB, amountA, amounts[1], stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);
            orders[orderId] = order;
        }
       
    }

    function createOrderERC20ToETH(address orderOwner, address ctokenA, address tokenA, uint256 amountA, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external veeLock(uint8(VeeLockState.LOCK_CREATE)) override returns (bytes32 orderId){
        require(orderOwner != address(0), "createOrder: invalid order owner");
        require(ctokenA != address(0), "createOrder: invalid ctoken A");
        require(stopHighPairPrice != 0, "createOrder: invalid limit price");
        require(stopLowPairPrice != 0, "createOrder: invalid stop limit");
        require(amountA != 0, "createOrder: amountA can't be zero.");
        require(expiryDate > block.timestamp, "createOrder: expiry date must be in future.");
        
        {
            IERC20 erc20TokenA = IERC20(tokenA);
            uint256 allowance = erc20TokenA.allowance(msg.sender, address(this));
            require(allowance >= amountA,"allowance must bigger than amountA");
            assert(erc20TokenA.transferFrom(msg.sender, address(this), amountA));
        }
        
       // swap tokens
       address tokenB = _router.WETH();
       uint256[] memory amounts = swapERC20ToETH(tokenA, amountA, maxSlippage);
       orderId = keccak256(abi.encode(orderOwner, amountA, tokenA, tokenB, getRandom()));
    
       emit OnTokenSwapped(orderId, orderOwner, tokenA, tokenB, amounts[0], amounts[1]);
       emit OnOrderCreated(orderId, orderOwner, tokenA, tokenB, amountA, stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);

        {
            Order memory order = Order(orderOwner, ctokenA, tokenA, tokenB, amountA, amounts[1], stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);
            orders[orderId] = order;
        }
       
    }


    function createOrderETHToERC20(address orderOwner, address cETH,  address tokenB, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external override veeLock(uint8(VeeLockState.LOCK_CREATE)) payable returns (bytes32 orderId){
        require(orderOwner != address(0), "createOrder: invalid order owner");
        require(cETH != address(0), "createOrder: invalid ctoken A");
        require(stopHighPairPrice != 0, "createOrder: invalid limit price");
        require(stopLowPairPrice != 0, "createOrder: invalid stop limit");
        require(msg.value != 0, "createOrder: eth amount can't be zero.");
        require(expiryDate > block.timestamp, "createOrder: expiry date must be in future.");

       // swap tokens
       address tokenA = _router.WETH();
       assert(tokenA != address(0));

       uint256[] memory amounts =  swapETHToERC20(tokenB, maxSlippage);
       orderId = keccak256(abi.encode(orderOwner, msg.value, tokenA, tokenB, getRandom()));
    
       emit OnTokenSwapped(orderId, orderOwner, tokenA, tokenB, amounts[0], amounts[1]);
       emit OnOrderCreated(orderId, orderOwner, tokenA, tokenB, msg.value, stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);

       Order memory order = Order(orderOwner, cETH, tokenA, tokenB, msg.value, amounts[1], stopHighPairPrice, stopLowPairPrice, expiryDate, autoRepay, maxSlippage);
       orders[orderId] = order;
    }

     /**
     * @dev check if the stop-limit order is expired or should be executed if the price reaches the stop/limit value.
     *
     * @param orderId  The order id     
     *
     * @return status code: 
     *                     StateCode.EXECUTE: can execute.
     *                     StateCode.EXPIRED: expired.
     *                     StateCode.NOT_RUN: not yet reach limit or stop.
     */
    function checkOrder(bytes32 orderId) external view override returns (uint8) {
        Order memory order = orders[orderId];
        require(order.orderOwner != address(0), "checkOrder: invalid order id");
             
        uint256 currentPrice =  getPairPrice(order.tokenA, order.tokenB, order.amountA);

        if(order.expiryDate <= block.timestamp){
            return (uint8(StateCode.EXPIRED));
        }

        else{
            if(currentPrice >= order.stopHighPairPrice || currentPrice <= order.stopLowPairPrice){
                return (uint8(StateCode.EXECUTE));
            }else{
                return (uint8(StateCode.NOT_RUN));
            }
        }
    }

     /**
     * @dev check if the stop-limit order is expired or should be executed if the price reaches the stop/limit value.
     *
     * @param orderId  The order id     
     *
     * @return true: success, false: failure.
     *                     
     */
    function executeOrder(bytes32 orderId) external onlyExecutor nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) override returns (bool){
        Order memory order = orders[orderId];
        require(order.orderOwner != address(0), "executeOrder: invalid order id");       

        uint256 price = getPairPrice(order.tokenA, order.tokenB, order.amountA);    

        if(price >= order.stopHighPairPrice || price <= order.stopLowPairPrice){
            uint256[] memory amounts;
            if(order.tokenB == _router.WETH()){
                amounts = swapETHToERC20(order.tokenB, order.maxSlippage);
            }else{
                if(order.tokenA == _router.WETH()){
                    amounts = swapERC20ToETH(order.tokenB, order.amountB, order.maxSlippage);
                }else{
                    amounts = swapERC20ToERC20(order.tokenA, order.amountA, order.tokenB, order.maxSlippage);
                }
            }
            emit OnTokenSwapped(orderId, order.orderOwner, order.tokenB, order.tokenA, amounts[0], amounts[1]);
            require(amounts[1] != 0, "executeOrder: failed to swap tokens"); 

            uint256 newAmountA = amounts[1];
            uint256 charges    = 0;

            address weth = _router.WETH();
            if(order.autoRepay){
                uint256 borrowedTotal = CTokenInterface(order.ctokenA).borrowBalanceStored(order.orderOwner);
                uint256 repayAmount = order.amountA;

                //In method repayBorrow() the repay borrowing amount must be less and equal than total borrowing of the user in tokenA.
                //if not, an exception will occur.
                //If borrowing amount of the stop-limit order is less and equal than total borrowing amount, then repay the borrowing amount of the order.
                //if borrowing amount of the stop-limit order is above than total borrowing amount, then repay total borrowing amount of the user in tokenA.
                if (borrowedTotal < order.amountA) {
                    repayAmount = borrowedTotal;
                }
                if (newAmountA > repayAmount) {
                    charges = newAmountA.sub(repayAmount);
                }
                if (charges > 0) {
                    if (repayAmount > 0) {
                        repayBorrow(order.ctokenA, order.orderOwner, repayAmount);
                    }
                    if(weth == order.tokenA){
                        // IWETH(weth).withdraw(charges);
                        payable(order.orderOwner).transfer(charges);
                    }else{
                        assert(IERC20(order.tokenA).transfer(order.orderOwner, charges));
                    }
                    
                 }else{
                     repayBorrow(order.ctokenA, order.orderOwner, newAmountA);
                 }             
             }else{
                if(weth == order.tokenA){
                    // IWETH(weth).withdraw(newAmountA);
                    payable(order.orderOwner).transfer(newAmountA);
                }else{
                    assert(IERC20(order.tokenA).transfer(order.orderOwner, newAmountA));
                }               
             }

             delete orders[orderId];
             emit OnOrderExecuted(orderId, newAmountA);
             return true;
        }else{
            return false;
        }
    }

//for test only
       function executeOrderTest(bytes32 orderId, bool istest, uint256 nTestNewAmountA) external onlyExecutor nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) returns (bool){
         Order memory order = orders[orderId];
        require(order.orderOwner != address(0), "executeOrder: invalid order id");       

        uint256 price = getPairPrice(order.tokenA, order.tokenB, order.amountA);       

        if(price >= order.stopHighPairPrice || price <= order.stopLowPairPrice || istest){
             uint256[] memory amounts;
            if(order.tokenB == _router.WETH()){
                amounts = swapETHToERC20(order.tokenB, order.maxSlippage);
            }else{
                if(order.tokenA == _router.WETH()){
                    amounts = swapERC20ToETH(order.tokenB, order.amountB, order.maxSlippage);
                }else{
                    amounts = swapERC20ToERC20(order.tokenA, order.amountA, order.tokenB, order.maxSlippage);
                }
            }
            emit OnTokenSwapped(orderId, order.orderOwner, order.tokenB, order.tokenA, amounts[0], amounts[1]);
            require(amounts[1] != 0, "executeOrder: failed to swap tokens"); 

            uint256 newAmountA = amounts[1];
            uint256 charges    = 0;

            if(istest) {
                newAmountA = nTestNewAmountA;
            }
            address weth = _router.WETH();
            if(order.autoRepay){
                uint256 borrowedTotal = CTokenInterface(order.ctokenA).borrowBalanceStored(order.orderOwner);
                uint256 repayAmount = order.amountA;

                //In method repayBorrow() the repay borrowing amount must be less and equal than total borrowing of the user in tokenA.
                //if not, an exception will occur.
                //If borrowing amount of the stop-limit order is less and equal than total borrowing amount, then repay the borrowing amount of the order.
                //if borrowing amount of the stop-limit order is above than total borrowing amount, then repay total borrowing amount of the user in tokenA.                
                if (borrowedTotal < order.amountA) {
                    repayAmount = borrowedTotal;
                }
                if (newAmountA > repayAmount) {
                    charges = newAmountA.sub(repayAmount);
                }
                 if (charges > 0) {
                    if (repayAmount > 0) {
                        repayBorrow(order.ctokenA, order.orderOwner, repayAmount);
                    }
                    if(weth == order.tokenA){
                        // IWETH(weth).withdraw(charges);
                        payable(order.orderOwner).transfer(charges);
                    }else{
                        assert(IERC20(order.tokenA).transfer(order.orderOwner, charges));
                    }
                    
                 }else{
                     repayBorrow(order.ctokenA, order.orderOwner, newAmountA);
                 }             
             }else{
                if(weth == order.tokenA){
                    // IWETH(weth).withdraw(newAmountA);
                    payable(order.orderOwner).transfer(newAmountA);
                }else{
                    assert(IERC20(order.tokenA).transfer(order.orderOwner, newAmountA));
                }               
             }

             delete orders[orderId];
             emit OnOrderExecuted(orderId, newAmountA);
             return true;
        }else{
            return false;
        }
    }

    /**
     * @dev cancel a valid order.
      *
     * @param orderId  The order id     
     *
     * @return Whether or not the canceling order succeeded
     *
     */
    function cancelOrder(bytes32 orderId) external nonReentrant veeLock(uint8(VeeLockState.LOCK_CANCELORDER)) override returns(bool){
        Order memory order = orders[orderId];
        require(order.orderOwner != address(0), "cancelOrder: invalid order id");
        require(hasRole(EXECUTOR_ROLE, msg.sender) || msg.sender == order.orderOwner, "cancelOrder: no permission to cancel order");
        address weth = _router.WETH();
        if(order.tokenB == weth){
            // IWETH(weth).withdraw(order.amountB);
            payable(order.orderOwner).transfer(order.amountB);
        }else{
            IERC20 erc20TokenB = IERC20(order.tokenB);
            assert(erc20TokenB.transfer(order.orderOwner, order.amountB));
        }
        delete orders[orderId];
        emit OnOrderCanceled(orderId, order.amountB);

        return true;
    }

    /**
     * @dev get a valid order.
      *
     * @param orderId  The order id     
     *
     * @return orderOwner  The address of order owner
     *         ctokenA     The address of ctoken A
     *         tokenA      The address of token A
     *         tokenB      The address of token B
     *         amountA     The token A amount
     *         stopHighPairPrice  limit token pair price
     *         stopLowPairPrice   stop token pair price
     *         expiryDate   expiry date
     *         autoRepay    if automatically repay borrow after trading
     *
     */
    function getOrderDetail(bytes32 orderId) external view override returns(address orderOwner, address ctokenA, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage){
        Order memory order = orders[orderId];
        require(order.orderOwner != address(0), "getOrder: invalid order id");   
        orderOwner = order.orderOwner;
        ctokenA    = order.ctokenA;
        tokenA     = order.tokenA;
        tokenB     = order.tokenB;
        amountA    = order.amountA;
        amountB    = order.amountB;    
        stopHighPairPrice = order.stopHighPairPrice;
        stopLowPairPrice  = order.stopLowPairPrice;     
        expiryDate = order.expiryDate;
        autoRepay  = order.autoRepay;  
        maxSlippage = order.maxSlippage;         
    }

    /**
     * @dev Repay user's borrow.
     *
     * @param cToken      The address of ctoken A
     * @param borrower    The address of order owner
     * @param repayAmount The amount  of token A     
     *
     * @return ret 0: success, otherwise a failure.
     *
     */   
    function repayBorrow(address cToken, address borrower, uint repayAmount) internal returns(uint256 ret) {
        if(cToken == _cether) {
            CEtherInterface cether = CEtherInterface(cToken);
            cether.repayBorrowBehalf{value:repayAmount}(borrower);
        }else{
            CErc20Interface cErc20Inst = CErc20Interface(cToken);
            CErc20Storage cErc20StorageInst = CErc20Storage(cToken);
            address underlyingAddress = cErc20StorageInst.underlying();
            require(underlyingAddress != address(0), "repayBorrow: invalid underlying Address");

            IERC20 erc20Inst = IERC20(underlyingAddress);
            require(erc20Inst.approve(cToken, repayAmount), "repayBorrow: failed to approve");        
        
            ret = cErc20Inst.repayBorrowBehalf(borrower, repayAmount);
            require(ret == 0, "repayBorrow: failed to call repayBorrowBehalf");  
        }
             
    }   

    /**
     * @dev set executor role by administrator.
     *
     * @param newExecutor  The address of new executor   
     *
     */
    function setExecutor(address newExecutor) external override onlyAdmin {
        require(newExecutor != address(0), "setExecutor: address of Executor is invalid");
        grantRole(EXECUTOR_ROLE, newExecutor);     
   }

    /**
     * @dev remove an executor role from list by administrator.
     *
     * @param executor  The address of an executor   
     *
     */
    function removeExecutor(address executor) external override onlyAdmin {
        require(executor != address(0), "removeExecutor: address of executor is invalid");
        revokeRole(EXECUTOR_ROLE, executor);      
   }
   

    /**
     * @dev generate random number.     
     *
     */
   function getRandom() private returns (uint256) {
       nonce++;
       uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) ;
       randomnumber = randomnumber + 1;                
       return randomnumber;
    }
    

    function swapERC20ToERC20(address tokenA,uint256 amountA, address tokenB,uint256 maxSlippage) public  returns (uint256[] memory){
        require(tokenA != address(0), "swap: invalid token A");
        require(tokenB != address(0), "swap: invalid token B");

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        // approve Uniswap to swap tokens    
        uint256 allowance = IERC20(tokenA).allowance(address(this), address(_router));
        if(allowance < amountA){
            require(IERC20(tokenA).approve(address(_router), amountA), "swap: failed to approve");
        }   
    
        uint256 deadline = (block.timestamp + 99999999);
        uint256[] memory amounts;
        uint256 amountOutMin = getMinAmountOut(tokenA,tokenB,amountA,maxSlippage);
        amounts = _router.swapExactTokensForTokens(amountA, amountOutMin, path, address(this), deadline);
        return amounts;
    }

    function swapETHToERC20(address tokenB,uint256 maxSlippage) public payable returns (uint256[] memory){
        require(tokenB != address(0), "swap: invalid token B");

        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = tokenB;
    
        uint256 deadline = (block.timestamp + 99999999);
        uint256[] memory amounts;
        uint256 amountOutMin = getMinAmountOut(_router.WETH(),tokenB,msg.value,maxSlippage);
        amounts = _router.swapExactETHForTokens{value:msg.value}(amountOutMin, path, address(this), deadline);
        return amounts;
    }

    function swapERC20ToETH(address tokenA,uint256 amountA, uint256 maxSlippage) public  returns (uint256[] memory){
        require(tokenA != address(0), "swap: invalid token A");

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = _router.WETH();

        // approve Uniswap to swap tokens    
        uint256 allowance = IERC20(tokenA).allowance(address(this), address(_router));
        if(allowance < amountA){
            require(IERC20(tokenA).approve(address(_router), amountA), "swap: failed to approve");
        }   
    
        uint256 deadline = (block.timestamp + 99999999);
        uint256[] memory amounts;
        uint256 amountOutMin = getMinAmountOut(tokenA,_router.WETH(),amountA,maxSlippage);
        amounts = _router.swapExactTokensForETH(amountA, amountOutMin, path, payable(address(this)), deadline);
        
        return amounts;
    }

    function getMinAmountOut(address tokenA, address tokenB, uint amountA, uint256 maxSlippage)  internal view returns (uint256 minAmountOut) {
        require(amountA != 0, "getMinAmountOut: amountA can't be zero");

        // IUniswapV2Router02 UniswapV2Router = router;
        IUniswapV2Factory UniswapV2Factory = IUniswapV2Factory(_router.factory());
        address factoryAddress = UniswapV2Factory.getPair(tokenA, tokenB);
        require(factoryAddress != address(0), "getMinAmountOut: token pair not found");

        IUniswapV2Pair UniswapV2Pair = IUniswapV2Pair(factoryAddress);
        (uint256 Res0, uint256 Res1,) = UniswapV2Pair.getReserves();        
        uint256 amountOut= _router.getAmountOut(amountA, Res0, Res1) ;  
        minAmountOut = amountOut - ((amountOut * maxSlippage) / 10**18/ 100);      
    }


    function getPairPrice(address tokenA, address tokenB, uint amountA) internal view returns(uint256 price){
        require(amountA != 0, "getPairPrice: amountA can't be zero");

        IUniswapV2Router02 UniswapV2Router = _router;
        IUniswapV2Factory UniswapV2Factory = IUniswapV2Factory(UniswapV2Router.factory());
        address factoryAddress = UniswapV2Factory.getPair(tokenA, tokenB);
        require(factoryAddress != address(0), "getPairPrice: token pair not found");

        IUniswapV2Pair UniswapV2Pair = IUniswapV2Pair(factoryAddress);
        (uint256 Res0, uint256 Res1,) = UniswapV2Pair.getReserves();        
        price = _router.getAmountOut(amountA, Res0, Res1) * 10**18 / amountA;  
        require(price != 0, "executeOrder: failed to get PairPrice"); 
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/AccessControl.sol";
// import "./proxy/IVeeImplement.sol";


/**
 * @title  Vee system controller
 * @notice Implementation of contractor management .
 * @author Vee.Finance
 */

contract VeeSystemController is AccessControl {
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE   =  keccak256("EXECUTOR_ROLE");

    enum VeeLockState { LOCK_CREATE, LOCK_EXECUTEDORDER, LOCK_CANCELORDER, LOCK_SETORACLE, LOCK_SETSWAP}

    
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @dev Lock All external functions
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockAll = 0; 

    /**
     * @dev Lock createOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockCreate = 0; 

    /**
     * @dev Lock executeOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockExecute = 0; 

     /**
     * @dev Lock cancelOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockCancel = 0; 

    /**
     * @dev Lock setVeeDex
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockSetOracle = 0; 

    /**
     * @dev Lock setSwap
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockSetSwap = 0; 

    /**
     * @dev Lock the System
     * 0 unlock 1 lock
     */
    uint8 private _sysLockState = 0;


    // address private _implementationAddress;

    /**
     * @dev Modifier throws if called methods have been locked by administrator.
     */
    modifier veeLock(uint8 lockType) {
        require(_sysLockState == 0,"veeLock: Lock System");
        require(_veeUnLockAll == 0,"veeLock: Lock All");

        if(lockType == uint8(VeeLockState.LOCK_CREATE)){
            require(_veeUnLockCreate == 0,"veeLock: Lock Create");
        }else if(lockType == uint8(VeeLockState.LOCK_EXECUTEDORDER)){
            require(_veeUnLockExecute == 0,"veeLock: Lock Execute");
        }else if(lockType == uint8(VeeLockState.LOCK_CANCELORDER)){
            require(_veeUnLockCancel == 0,"veeLock: Lock Cancel");
        }else if(lockType == uint8(VeeLockState.LOCK_SETORACLE)){
            require(_veeUnLockSetOracle == 0,"veeLock: Lock Set Oracle");
        }else if(lockType == uint8(VeeLockState.LOCK_SETSWAP)){
            require(_veeUnLockSetSwap == 0,"veeLock: Lock Set Swap");
        }
        _;        
    }

    /**
     * @dev Modifier throws if called by any account other than the administrator.
     */
    modifier onlyAdmin() {
        require(hasRole(PROXY_ADMIN_ROLE, _msgSender()), "VeeSystemController: Admin permission required");
        _;
    }
    
    /**
     * @dev Modifier throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        require(hasRole(EXECUTOR_ROLE, _msgSender()), "VeeSystemController: Executor permission required");
        _;
    }
 
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "nonReentrant: Warning re-entered!");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

     /**
     * @dev set state for locking some or all of functions or whole system.
     *
     * @param sysLockState     Lock whole system
     * @param veeUnLockAll     Lock all of functions
     * @param veeUnLockCreate  Lock create order
     * @param veeUnLockExecute Lock execute order
     * @param veeUnLockCancel  Lock cancel order
     * @param veeUnLockSetOracle  Lock set vee price oracle
     *
     */
    function setState(uint8 sysLockState, uint8 veeUnLockAll, uint8 veeUnLockCreate, uint8 veeUnLockExecute, uint8 veeUnLockCancel ,uint8 veeUnLockSetOracle) external onlyAdmin {
        _sysLockState       = sysLockState;
        _veeUnLockAll       = veeUnLockAll;
        _veeUnLockCreate    = veeUnLockCreate;
        _veeUnLockExecute   = veeUnLockExecute;
        _veeUnLockCancel    = veeUnLockCancel;
        _veeUnLockSetOracle = veeUnLockSetOracle;
    }


    // function implementation()  external view override returns (address) {
    //     return _implementationAddress;
    // }
    
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

/**
 * @dev Interface of the IVeeProxyController
 */
interface IVeeProxyController {  

    /*** Order Events ***/
    /**
     * @notice Event emitted when the order are created.
     */
	event OnOrderCreated(bytes32 indexed orderId, address indexed orderOwner, address indexed tokenA, address tokenB,uint amountA, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage);

    /**
     * @notice Event emitted when the order are canceled.
     */
    event OnOrderCanceled(bytes32 indexed orderId, uint256 amount);

    /**
     * @notice Event emitted when the order are Executed.
     */
	event OnOrderExecuted(bytes32 indexed orderId, uint256 amount);    

    /**
     * @notice Event emitted when the token pair are exchanged.    
     */
	event OnTokenSwapped(bytes32 indexed orderId, address indexed orderOwner, address tokenA, address tokenB, uint256 amountA, uint256 amountB);

     /**
     * @notice Event emitted when repay borrow. 
     */
    event OnRepayBorrow(address borrower, address borrowToken, uint256 borrowAmount);

    function createOrderERC20ToERC20(address orderOwner, address ctokenA, address tokenA, address tokenB, uint256 amountA, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external returns (bytes32);

    function createOrderERC20ToETH(address orderOwner, address ctokenA, address tokenA, uint256 amountA, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external returns (bytes32);

    function createOrderETHToERC20(address orderOwner, address cETH,  address tokenB, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage) external payable returns (bytes32);

    function checkOrder(bytes32 orderId) external view returns (uint8);

    function executeOrder(bytes32 orderId) external returns (bool);

    function cancelOrder(bytes32 orderId) external returns(bool);

    function getOrderDetail(bytes32 orderId) external view returns(address orderOwner, address ctokenA, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 stopHighPairPrice, uint256 stopLowPairPrice, uint256 expiryDate, bool autoRepay,uint256 maxSlippage);

    function setExecutor(address newExecutor) external;

    function removeExecutor(address executor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CEtherInterface{
    function repayBorrowBehalf(address borrower) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;


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

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint);
    function balanceOf(address owner) external view virtual returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view virtual returns (uint);
    function supplyRatePerBlock() external view virtual returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) public view virtual returns (uint);
    function exchangeRateCurrent() public virtual returns (uint);
    function exchangeRateStored() public view virtual returns (uint);
    function getCash() external view virtual returns (uint);
    function accrueInterest() public virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint);
    function _acceptAdmin() external virtual returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) public virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external virtual returns (uint);
    function sweepToken(EIP20NonStandardInterface token) external virtual;


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CTokenInterfaces.sol";

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint[] memory);
    function exitMarket(address cToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external virtual returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external virtual;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external virtual returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external virtual;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external virtual;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external virtual returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    /*** custom funtions ***/

    function getAssetsIn(address account) external virtual returns (CTokenInterface[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @ return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @ return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @ return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract IUniswapV2Router01 {
    function factory() external pure virtual returns (address);
    function WETH() external pure virtual returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable virtual returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        virtual
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        virtual
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view virtual returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IUniswapV2Router01.sol';

abstract contract IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable virtual;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
        mapping (address => bool) members;
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

