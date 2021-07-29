/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract OrderProtocol {
  
    
    address private manager;

    bool createAccountFlag = true;

    //Account Contract map
    //User address => Account contract address
    mapping(address => address) private accountMap;
    address [] private accountList;
  
    event AccountCreate(address user, address account);


    function getAccountContractAddress(address user) public view returns(address) {
        return accountMap[user];
    }
    
    function createAccount(address user) public payable {
        require((createAccountFlag == false && msg.sender == user)  || msg.sender == accountCreator );
        require(accountMap[user] == address(0));
        
        //Deploy Account contract whose owner is user.
        OrderProtocolWallet account =  new OrderProtocolWallet(user);
        accountMap[user] = address(account);
        accountList.push(address(account));
        emit AccountCreate(user, address(account));
    }
    
    function getAccountList() public view returns(address [] memory) {
        return accountList;
    }
    
    function setCreateAccountFlag(bool flag) public onlyManager payable {
        if(flag == false){
            createAccountFlag = flag;
        }
    }
    
    function setAccountCreatorAddress(address creator) public onlyManager payable {
        accountCreator = creator;
    }
    

    constructor() {
        manager = msg.sender;
    }


    modifier onlyManager() {
        require (msg.sender == manager);
        _;
    }
    
    address private accountCreator;

}

contract OrderProtocolWallet {
      
    struct Order { 
        address routerAddress;
        uint routerFunction;
        address factoryAddress;
        
        uint id;
        address[] conditionPath;
        uint conditionValue;
        uint conditionOperator;
        
        address[] swapPath;
        uint value;
        uint slippage;
        uint time;
        uint createdDate;
    }

    event OrderDelete(uint id, uint time);
    event OrderCreate(uint id, uint time);
    event OrderSend(uint id,  address indexed sender, uint time);



    address private orderProtocolTokenAddress = 0x6b1636b23c7f7545c6bFFA6EBe5e793cFA80D28A;
    
    Order[] private orders;
    address private owner;
    uint private orderCounter = 1;
    
    constructor(address ownerAddress) {
        owner = ownerAddress;
    }
    
    function getOwner() public view returns(address){
        
        return owner;
    }
    
    function withdraw(uint amount) onlyOwner public returns(bool) {
        require(amount <= address(this).balance);
        payable(owner).transfer(amount);
        return true;

    }
    
    function withdrawToken(address tokenAddress, uint amount) onlyOwner public {
        IERC20 token = IERC20(tokenAddress);
        require(amount <= token.balanceOf(address(this)));

        token.transfer(owner, amount);
    }
    
    
    
    function getOrdersLength() public view returns(uint){
        return orders.length;
    }
    
    function getOrder(uint index ) public view returns(Order memory){
        return orders[index];
    }
    
    function deleteOrder(uint orderId ) public onlyOwner payable{
        uint index = 0;
        bool found = false;
        for (uint i = 0; i < orders.length; i++) {
            if(orders[i].id == orderId){
                index = i;
                found = true;
                break;
            }
        }
        if(found == true){
            for (uint i = index; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            delete orders[orders.length - 1];
            orders.pop();
            emit OrderDelete(orderId, block.timestamp);
        }
        
    }
    
    function deleteSentOrder(uint orderId ) private{
        uint index = 0;
        bool found = false;
        for (uint i = 0; i < orders.length; i++) {
            if(orders[i].id == orderId){
                index = i;
                found = true;
                break;
            }
        }
        if(found == true){
            for (uint i = index; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            delete orders[orders.length - 1];
            orders.pop();
        }
    }
    
    function hasEnoughOrderProtocol(uint amount, address user) private view returns (bool){
        IERC20 token = IERC20(orderProtocolTokenAddress);
        if(amount <= token.balanceOf(user)){
            return true;
        }
        return false;
    }
    
    function createOrder(address routerAddress, uint routerFunction, address factoryAddress, address[] memory conditionPath, uint conditionValue,uint conditionOperator , address[] memory swapPath, uint value, uint slippage, uint time) public onlyOwner payable{
        require (value > 0);

        Order memory order = Order(routerAddress, routerFunction, factoryAddress, orderCounter, conditionPath, conditionValue, conditionOperator ,  swapPath, value, slippage, time, block.timestamp);
        orderCounter += 1;
        orders.push(order);
        emit OrderCreate(orderCounter - 1, block.timestamp);
    }
    
    function sendOrder(uint orderId)  public payable{
        require (checkOrder(orderId) == true);
        require ( hasEnoughOrderProtocol(10000 ether, msg.sender));

        uint j=0;
        for (j = 0; j < orders.length; j += 1) {  
            Order memory order = orders[j];
            if(order.id == orderId){
                

                DEXRouter router = DEXRouter(order.routerAddress);
                uint256[] memory values = router.getAmountsOut(  order.value,   order.swapPath);
                uint amountValue = values[values.length - 1];
                
                uint slippage = order.slippage;
                if(slippage <= 0){
                    slippage = 0;
                }
                if(slippage > 100){
                    slippage = 0;
                }
                amountValue = amountValue * (100 - slippage);
                amountValue = amountValue / 100;
                
                uint done = 0;
                
                if(order.routerFunction == 0){
                    router.swapExactETHForTokens{value: order.value}(
                    amountValue,  
                    order.swapPath,
                    address(this), 
                    block.timestamp + order.time);
                    done = 1;
                }else if(order.routerFunction == 1){
                    //approve token
                    approveToken(order.factoryAddress, order.routerAddress, order.swapPath);
                    router.swapExactTokensForETH(
                        order.value,
                        amountValue,  
                        order.swapPath,
                        address(this), 
                        block.timestamp + order.time);
                    done = 1;
                }else if(order.routerFunction == 2){
                    //approve token
                    approveToken(order.factoryAddress, order.routerAddress, order.swapPath);

                    router.swapExactTokensForTokens(
                        order.value,
                        amountValue,  
                        order.swapPath,
                        address(this), 
                        block.timestamp + order.time);
                    done = 1;
                }
                
                if(done == 1) {
                    deleteSentOrder(orderId);
                    payable(msg.sender).transfer(0.1 ether);
                    emit OrderSend(orderId, msg.sender, block.timestamp);
                }

            }
        } 
    }
    
    function approveToken(address factoryAddress, address routerAddress, address[] memory path) private {
        DEXFactory factory = DEXFactory(factoryAddress);
        address symbol1 = path[0];
        address symbol2 = path[path.length-1];
        
        address pairAddress = factory.getPair(symbol1, symbol2);
        DEXPair pair = DEXPair(pairAddress);
        uint256 amount = pair.allowance(address(this), routerAddress);
        if(amount < 115792089237316195423570985008687907853269984665640564039457584007913129639935) {
            pair.approve(routerAddress, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        }
        
        IERC20 token = IERC20(symbol1);
        uint256 amount2 = token.allowance(address(this), routerAddress);
        if(amount2 < 115792089237316195423570985008687907853269984665640564039457584007913129639935) {
            token.approve(routerAddress, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        }
    }
    
    
    function checkOrder(uint orderId) public view returns(bool) {
        if(checkOrderCondition(orderId) != true) {
           return false;
        }
        if(address(this).balance < 0.1 ether) {
           return false;
        }

        uint j=0;
        for (j = 0; j < orders.length; j += 1) {  
            Order memory order = orders[j];
            if(order.id == orderId){
                if(order.routerFunction == 0){
                    if(address(this).balance >= ((0.1 ether) + order.value)) {
                        return true;
                    }
                }else{
                    address tokenAddress = order.swapPath[0];
                    IERC20 token = IERC20(tokenAddress);
                    if(order.value <= token.balanceOf(address(this))){
                        return true;
                    }
                }
                return false;
            }
        } 
        
        
        return false;
        
    }


    function checkOrderCondition(uint orderId) public view returns(bool) {
        uint j=0;
        for (j = 0; j < orders.length; j += 1) {  
            Order memory order = orders[j];
            if(order.id == orderId){
                
                DEXRouter router = DEXRouter(order.routerAddress);
                uint256[] memory values = router.getAmountsOut(  1 ether,   order.conditionPath);
                uint priceValue = values[values.length - 1];
                if(priceValue == 0){
                    return false;
                }
                
                if(order.conditionOperator == 0){
                    // >=
                    return priceValue >= order.conditionValue;
                }
                else if(order.conditionOperator == 1){
                    // >
                    return priceValue > order.conditionValue;
                }
                else if(order.conditionOperator == 2){
                    // ==
                    return priceValue == order.conditionValue;
                }
                else if(order.conditionOperator == 3){
                    // <
                    return priceValue < order.conditionValue;
                }
                else if(order.conditionOperator == 4){
                    // <=
                    return priceValue <= order.conditionValue;
                }
                return false;

            }
        } 
        
        return false;
    }
    
    function getCheckOrderConditionPrice(uint orderId) public view returns(uint) {
        uint j=0;
        for (j = 0; j < orders.length; j += 1) {  
            Order memory order = orders[j];
            if(order.id == orderId){
                
                DEXRouter router = DEXRouter(order.routerAddress);
                uint256[] memory values = router.getAmountsOut(  1 ether,   order.conditionPath);
                uint priceValue = values[values.length - 1];
                if(priceValue == 0){
                    return 98;
                }
                return priceValue;
                

            }
        } 
        
        return 99;
    }
    
    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    fallback() external payable { }

    receive() external payable {  }

}

interface IERC20 {
    
    function decimals() external view returns (uint8);
    
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

contract DEXFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair) {}

}

contract DEXPair {
    function allowance(address owner, address spender) external view returns (uint) {}

    function approve(address spender, uint value) external returns (bool) {}
}

contract DEXRouter {
   
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts){}
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts){}
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts){}
        
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts){}
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts){}
        
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts){}
        

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB){}
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut){}
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn){}
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts){}
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts){}
}