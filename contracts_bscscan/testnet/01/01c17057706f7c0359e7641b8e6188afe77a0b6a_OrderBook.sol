/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

contract OrderBook
{
    uint256 ONE_HUNDRED = 100000000000000000000;
    address public owner;
    address public feeTo;
    address public networkcoinaddress;
    uint256 public commonAdminFee;
    uint256 public networkCoinAdminFee;
    mapping(address => uint256) tokenAdminFee;    
    mapping(uint => uint256) orderRemainingAmount;
    mapping(uint => uint256 ) orderValue;

    //Remaining amount Order Id > total remaining 
    mapping(uint => uint256 ) remainingOrderValue;

    mapping(uint => uint256 ) adminFeeCommonPart;
    mapping(uint => uint256 ) adminFeeCoinFromPart;
    mapping(uint => uint256 ) adminFeeDiscount;
    mapping(uint => uint256 ) adminFeePaid;

    mapping(uint => uint) public orderBlock;

    struct Order
    {
        uint id;
        uint status; //0 = Pending_Execution | 1 = Executed | 2 = Canceled || 9 = Canceled by Admin || 19 = Canceled Forced by Admin
        uint buySell; //0 = Buy | 1 = Sell         
        uint creationDate;
        address walletAccountOwner;
        uint256 amount;
        uint256 price;
        address rightCoin;
        address leftCoin;
        address coinSend;
        address coinReceive;
    }

    Order[] public orderList;

    struct OrderDetail
    {
        uint executionDate;
        uint cancelDate;
        uint changeDate;
        uint execOrderId;
        uint256 execAmount;
        uint256 execPrice;
        uint orderBlock;
    }

    struct OrderAdminFee
    {
        uint256 adminFeeCommonPart;
        uint256 adminFeeCoinFromPart;
        uint256 adminFeeDiscount;
        uint256 adminFeePaid;
    }

    mapping(address=> mapping(address => uint[])) private orderListFromPair; //save id for coin pair (left/right)
    mapping(address=> uint[]) private orderListFromOwner; //All orders of order owner

    //Order Id > Order Detail
    mapping(uint => OrderDetail[]) public orderDetailList; // HOW TO SAVE: orderDetailList[orderList.length].executionDate = block.timestamp;

    event OnOrderCreation(uint id, address walletAccountOwner,uint buysell, uint256 orderAmount, uint256 price, address coinSend, address coinReceive);
    event OnOrderExecuted(uint orderId, uint orderMatchId, address orderCoinReceive, address orderMatchCoinReceive, uint256 orderReceiveAmt, uint256 orderMatchReceiveAmt,uint256 refundDifPrice);
    event OnOrderCanceled(uint orderId, address orderCoinSend, uint256 orderCancelRefundAmt);

    constructor() 
    {
        owner = msg.sender;
        feeTo = owner;
        networkcoinaddress = address(0x1110000000000000000100000000000000000111);
        commonAdminFee = 16000000000000000; //0.016
        networkCoinAdminFee = 8000000000000000; //0.008
    }

    struct Discount
    {
        uint256 minbalance;
        uint256 percent;
    }

    mapping (address => Discount[]) private tokenDiscount;
    address[] private discountTokenList;

    struct adminFeeDiscountDetail
    {
        address token;
        uint256 minbalance;
        uint256 percent;
    }

    function setOwner(address newOwner) external returns (bool success)
    {
        require(msg.sender == owner,"FN"); //Forbidden
        owner = newOwner;
        return true;
    }

    function setNetworkCoinAddress(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
        return true;
    }

    function setNetworkCoinAdminFee(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner,"FN"); //Forbidden
        networkCoinAdminFee = newValue;
        return true;
    }
    
    function setFeeTo(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        feeTo = newValue;
        return true;
    }

    function setCommonAdminFee(uint256 newValue) external returns (bool success)
    {
        require(msg.sender == owner,"FN"); //Forbidden
        commonAdminFee = newValue;
        return true;
    }

    function setTokenAdminFee(address token, uint256 adminFee) external returns (bool result)
    {
        require(msg.sender == owner,"FN"); //Forbidden
        tokenAdminFee[token] = adminFee;
        return true;
    }

    function addTokenDiscount(address token, uint256 minbalance, uint256 percent) external returns (bool success)
    {
        require(msg.sender == owner, "FN"); //Forbidden
        require(token != networkcoinaddress, "INVTK"); //Discount only for Tokens
        
        tokenDiscount[token].push(Discount({
            minbalance: minbalance,
            percent: percent            
        }));
        
        uint added = 0;
        for(uint ix = 0; ix < discountTokenList.length; ix++)
        {
            if(discountTokenList[ix] == token)
            {
                added = 1;
                break;
            }
        }
        
        if(added == 0)
        {
            discountTokenList.push(token);
        }
        
        return true;
    }
    
    function removeTokenDiscount(address token, uint discountIndex) external
    {
        require(msg.sender == owner, "FN"); //Forbidden
        
        uint discountLen = tokenDiscount[token].length;

        //Swap last to index
        if(discountLen > 1)
        {
            tokenDiscount[token][discountIndex] = tokenDiscount[token][discountLen - 1];
        }

        //Delete dirty last
        if(discountLen > 0)
        {
            tokenDiscount[token].pop();
        }
    }
    
    function setExistingTokenDiscount(address token, uint discountIndex, uint minbalance, uint percent) external returns (bool success)
    {
        require(msg.sender == owner, "FN"); //Forbidden

        tokenDiscount[token][discountIndex].minbalance = minbalance;
        tokenDiscount[token][discountIndex].percent = percent;
        return true;
    }
    
    function getTokenDiscountLength(address token) external view returns (uint)
    {
        return tokenDiscount[token].length;
    }

    function getTokenAdminFee(address token) external view returns (uint256 tokenFee)
    {   
        return tokenAdminFee[address(token)];
    }

    function getTotalTokenAdminFee(address token) external view returns (uint256 tokenFee)
    {   
        return safeAdd(commonAdminFee, tokenAdminFee[address(token)]);
    }

    function getTotalNetworkCoinAdminFee() external view returns (uint256 adminFee)
    {   
        return safeAdd(commonAdminFee, networkCoinAdminFee);
    }

    function getOrderValue(uint orderid) external view returns (uint256 order_Value)
    {   
        return orderValue[orderid];
    }

    function getOrderRemainingAmount(uint orderid) external view returns (uint256 order_RemainingAmount)
    {   
        return orderRemainingAmount[orderid];
    }

    function getRemainingOrderValue(uint orderid) external view returns (uint256 remaining_OrderValue)
    {   
        return remainingOrderValue[orderid];
    }

    function getPendingOrderListFromPair(address leftCoin, address rightCoin) external view returns(Order[] memory)
    {
        Order[] memory result = new Order[]( orderListFromPair[leftCoin][rightCoin].length );

        for(uint ix = 0; ix < orderListFromPair[leftCoin][rightCoin].length; ix++)
        {
            if( orderList[ orderListFromPair[leftCoin][rightCoin][ix] - 1 ].status == 0 )
            {
                result[ix] = orderList[ orderListFromPair[leftCoin][rightCoin][ix] - 1 ];
            }
        }

        return result;
    }

    function getOrderListDetailSize(uint orderId) external view returns(uint)
    {
        return  orderDetailList[orderId].length;
    }

    function getOrderAdminFee(uint orderid) external view returns (OrderAdminFee memory)
    {        
        return OrderAdminFee({
            adminFeeCommonPart: adminFeeCommonPart[orderid],
            adminFeeCoinFromPart: adminFeeCoinFromPart[orderid],
            adminFeeDiscount: adminFeeDiscount[orderid],
            adminFeePaid: adminFeePaid[orderid]
        });
    }

    function getTokenDiscountByIndex(address token, uint discountIndex) external view returns (Discount memory)
    {
        return tokenDiscount[token][discountIndex];
    }
    
    function getTokenDiscountByBalance() public view returns (uint256 discountPercent)
    {
        uint256 result = 0;
        
        for(uint ixTk = 0; ixTk < discountTokenList.length; ixTk++)
        {
            address token = discountTokenList[ixTk];
            
            uint256 userBalance = 0;
            if(token != networkcoinaddress)
            {
                userBalance = ERC20(token).balanceOf(msg.sender);
            }
            else
            {
                userBalance = msg.sender.balance;
            }
            
            for(uint ix = 0; ix < tokenDiscount[token].length; ix++)
            {
                if(userBalance >= tokenDiscount[token][ix].minbalance) //Has balance enough to get this discount
                {
                    if(tokenDiscount[token][ix].percent > result) //Is a discount percent better than before
                    {
                        result = tokenDiscount[token][ix].percent;
                    }
                }
            }

        }
        
        return result;
    }

    function getOrderFromOwner(address ownerAddress) external view returns (uint[] memory)
    {
        return orderListFromOwner[ownerAddress];
    }

    function getOrderFromOwnerForStatus(address ownerAddress, uint status) external view returns(uint[] memory)
    {
        uint[] memory result = new uint[]( orderListFromOwner[ownerAddress].length);

        for(uint ix = 0; ix < orderListFromOwner[ownerAddress].length; ix++)
        {
            if( orderList[ orderListFromOwner[ownerAddress][ix] - 1 ].status == status )
            {
                result[ix] = orderListFromOwner[ownerAddress][ix];
            }
        }

        return result;
    }

    function getAdminFeeDiscountDetail() external view returns (adminFeeDiscountDetail memory) 
    {
        uint256 result = 0;
        address tokenResult = address(0);
        uint256 minbalanceResult = 0;

        for(uint ixTk = 0; ixTk < discountTokenList.length; ixTk++)
        {
            address token = discountTokenList[ixTk];
            uint256 userBalance = 0;
            if(token != networkcoinaddress)
            {
                userBalance = ERC20(token).balanceOf(msg.sender);
            }
            else
            {
                userBalance = msg.sender.balance;
            }
            
            for(uint ix = 0; ix < tokenDiscount[token].length; ix++)
            {
                if(userBalance >= tokenDiscount[token][ix].minbalance) //Has balance enough to get this discount
                {
                    if(tokenDiscount[token][ix].percent > result) //Is a discount percent better than before
                    {
                        result = tokenDiscount[token][ix].percent;
                        tokenResult = token;
                        minbalanceResult = tokenDiscount[token][ix].minbalance;
                    }
                }
            }
        }
        
        return adminFeeDiscountDetail({
            token: tokenResult,
            minbalance: minbalanceResult,
            percent: result
        });
    }

    function createOrderUsingNetworkCoin(uint buysell, uint256 price, address leftCoin, address rightCoin) external payable returns (bool success) 
    {
        require(msg.value > 0, "LOW");

        uint256 discountPerc = getTokenDiscountByBalance();
        require(discountPerc <= ONE_HUNDRED, "INVPERC"); //FeeDiscount: Invalid percent fee value
        uint256 adminFee = safeAdd(commonAdminFee, networkCoinAdminFee); //0,03
        
        if(discountPerc > 0)
        {
            if(safeDiv(safeMul(adminFee, discountPerc),ONE_HUNDRED) < adminFee)
            {
                adminFee = safeSub(adminFee,safeDiv(safeMul(adminFee, discountPerc),ONE_HUNDRED));
            }
            else
            {
                adminFee = 0; //No admin fee
            }
        }

        require(msg.value > adminFee, "LOWFEE");
        
        uint256 orderAmount = buysell == 0 ? safeDivFloat(safeSub(msg.value, adminFee), price,ERC20(leftCoin).decimals()) : safeSub(msg.value, adminFee);
        
        payable(feeTo).transfer(adminFee); //send adminfee
        
        orderList.push(Order({
            id: safeAdd(orderList.length, 1),
            status: 0,
            buySell: buysell,
            creationDate: block.timestamp,  
            walletAccountOwner: msg.sender, 
            amount: orderAmount,
            price:price,
            leftCoin:leftCoin,
            rightCoin:rightCoin,
            coinSend: buysell == 0 ? rightCoin : leftCoin,
            coinReceive: buysell == 0 ? leftCoin : rightCoin
        }));

        orderRemainingAmount[orderList.length] = orderAmount;
        orderValue[orderList.length] = safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals());
        remainingOrderValue[orderList.length] = safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals());
        adminFeeCommonPart[orderList.length] = commonAdminFee;
        adminFeeCoinFromPart[orderList.length] = networkCoinAdminFee;
        adminFeeDiscount[orderList.length] = discountPerc;
        adminFeePaid[orderList.length] = adminFee;

        orderListFromPair[leftCoin][rightCoin].push(orderList.length);
        orderListFromOwner[msg.sender].push(orderList.length);

        orderBlock[orderList.length] = block.number;

        while(orderRemainingAmount[orderList.length] > 0)
        {
            Order memory orderMatch = getOrderMatch(orderList.length);

            if(orderMatch.id != 0)
            {
                executeOrder( orderList[ orderList.length - 1 ], orderMatch);
            }
            else
            {
                break;
            }
        }

        emit OnOrderCreation(orderList.length,  msg.sender, buysell, orderAmount, price, buysell == 0 ? rightCoin : leftCoin, buysell == 0 ? leftCoin : rightCoin);

        return true;

    }

    function createOrderUsingToken(ERC20 token, uint256 orderAmount, uint buysell, uint256 price, address leftCoin, address rightCoin) external payable returns (bool success) 
    {
        uint256 allowance = token.allowance(msg.sender, address(this));

        if(buysell == 0)
        {
            
            require(allowance >= safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals()), "AL"); // Check the token allowance. Use approve function.
        }
        else
        {
            require(allowance >= orderAmount, "AL"); // Check the token allowance. Use approve function.
        }
        
        require(orderAmount > 0, "LOW");
        uint256 adminFee = safeAdd(commonAdminFee, tokenAdminFee[address(token)]);

        uint256 discountPerc = getTokenDiscountByBalance();
        require(discountPerc <= ONE_HUNDRED, "INVPERC"); //FeeDiscount: Invalid percent fee value
                
        if(discountPerc > 0)
        {
            if(safeDiv(safeMul(adminFee, discountPerc),ONE_HUNDRED) < adminFee)
            {
                adminFee = safeSub(adminFee,safeDiv(safeMul(adminFee, discountPerc),ONE_HUNDRED));
            }
            else
            {
                adminFee = 0; //No admin fee
            }

        }
        
        require(msg.value >= adminFee, "LOWFEE");

        payable(feeTo).transfer(adminFee); //send adminfee
        
        token.transferFrom(msg.sender, address(this), buysell == 0 ? safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals()) : orderAmount); //store balance on contract
        
        orderList.push(Order({
            id: safeAdd(orderList.length, 1),            
            status: 0,
            buySell: buysell,
            creationDate: block.timestamp,
            walletAccountOwner: msg.sender,
            amount: orderAmount,
            price:price,
            leftCoin:leftCoin,
            rightCoin:rightCoin,
            coinSend: buysell == 0 ? rightCoin : leftCoin,
            coinReceive: buysell == 0 ? leftCoin : rightCoin
        }));

        orderRemainingAmount[orderList.length] = orderAmount;
        orderValue[orderList.length] = safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals());
        remainingOrderValue[orderList.length] = safeMulFloat(price, orderAmount,leftCoin== networkcoinaddress ? 18 : ERC20(leftCoin).decimals());
        adminFeeCommonPart[orderList.length] = commonAdminFee;
        adminFeeCoinFromPart[orderList.length] = tokenAdminFee[address(token)];
        adminFeeDiscount[orderList.length] = discountPerc;
        adminFeePaid[orderList.length] = adminFee;

        orderListFromPair[leftCoin][rightCoin].push(orderList.length);
        orderListFromOwner[msg.sender].push(orderList.length);

        orderBlock[orderList.length] = block.number;
        
        while(orderRemainingAmount[orderList.length] > 0)
        {
            Order memory orderMatch = getOrderMatch(orderList.length);

            if(orderMatch.id != 0)
            {
                executeOrder( orderList[ orderList.length - 1 ], orderMatch);
            }
            else
            {
                break;
            }
        }

        emit OnOrderCreation(orderList.length,  msg.sender, buysell, orderAmount, price, buysell == 0 ? rightCoin : leftCoin, buysell == 0 ? leftCoin : rightCoin);

        return true;

    }

    function getOrderMatch(uint orderId) internal view returns (Order memory)
    {
        Order memory myOrder = orderList[orderId-1];
        Order memory result;

        for(uint ix = 0; ix<orderList.length; ix++)
        {
            Order memory orderMatch = orderList[ix];

            if(orderMatch.status !=0)
            {
                continue;
            }

            if(orderMatch.walletAccountOwner == myOrder.walletAccountOwner)
            {
                continue;
            }

            if(orderMatch.coinSend != myOrder.coinReceive || orderMatch.coinReceive != myOrder.coinSend)
            {
                continue;                
            }

            if(myOrder.buySell == 0)
            {
                if(orderMatch.buySell != 1)
                {
                    continue;
                }

                if(orderMatch.price <= myOrder.price)
                {
                    if(result.id == 0)
                    {
                        result = orderMatch;
                    }
                    else
                    {
                        if(result.price > orderMatch.price)
                        {
                            result = orderMatch;
                        }
                        else if(result.price == orderMatch.price)
                        {
                            if(result.creationDate > orderMatch.creationDate)
                            {
                                result = orderMatch;
                            }
                        }
                    }
                }
            }
            else
            {
                if(orderMatch.buySell != 0)
                {
                    continue;
                }

                if(orderMatch.price >= myOrder.price)
                {
                    if(result.id == 0)
                    {
                        result = orderMatch;
                    }
                    else
                    {
                        if(result.price < orderMatch.price)
                        {
                            result = orderMatch;
                        }
                        else if(result.price == orderMatch.price)
                        {
                            if(result.creationDate > orderMatch.creationDate)
                            {
                                result = orderMatch;
                            }
                        }
                    }

                }
            }
        }

        return result;
    }

    function executeOrder(Order memory order, Order memory orderMatch) internal returns (uint executed)
    {        
        if(order.buySell == 0)
        {
            //Total Exec Sell Order
            //Total Exec Buy Order
            if(orderRemainingAmount[orderMatch.id] == orderRemainingAmount[order.id])
            {                
                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[orderMatch.id], orderMatch.price, orderMatch.coinSend == networkcoinaddress ? 18 : ERC20(orderMatch.coinSend).decimals()); //amount to send - execution                   
                require (remainingOrderValue[order.id] >= orderValueSend,"INVREAMT");
                uint256 refundDifPrice = safeSub(remainingOrderValue[order.id], orderValueSend); //calculates price difference 
                uint256 orderAmountSend = orderRemainingAmount[orderMatch.id];

                //transfer executed amount to seller wallet
                if(orderMatch.coinReceive == networkcoinaddress)
                {   
                    payable(orderMatch.walletAccountOwner).transfer(orderValueSend);

                    //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {
                        payable(order.walletAccountOwner).transfer(refundDifPrice);
                    }
                }
                else
                {                    
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderValueSend);

                    //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {                   
                        ERC20(order.coinSend).transfer(order.walletAccountOwner, refundDifPrice);
                    }
                }

                //transfer executed amount to buyer wallet
                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderAmountSend);
                    
                }
                else
                {
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderAmountSend);
                }

                //Clean remaining amount (total executed)
                orderRemainingAmount[orderMatch.id] = 0;
                orderRemainingAmount[order.id] = 0;

                //Clean remaining order amount (total executed)
                remainingOrderValue[orderMatch.id] = 0;
                remainingOrderValue[order.id] = 0;

                //Status changed to Executed
                orderList[orderMatch.id - 1].status = 1;
                orderList[order.id - 1].status = 1; 

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,
                    execAmount: orderAmountSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,
                    execAmount: orderValueSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));
                
                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderAmountSend,orderValueSend,refundDifPrice);
                return 1;

            }
            else if(orderRemainingAmount[orderMatch.id] < orderRemainingAmount[order.id])
            {
                //Total Exec Sell Order
                //Partial Exec Buy Order
                
                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[orderMatch.id], orderMatch.price, orderMatch.coinSend == networkcoinaddress ? 18 : ERC20(orderMatch.coinSend).decimals()); //amount to send - execution
                require (remainingOrderValue[order.id] >= orderValueSend,"INVREAMT1");
                uint256 orderAmountSend = orderRemainingAmount[orderMatch.id];

                //transfer executed amount to seller wallet
                if(orderMatch.coinReceive == networkcoinaddress)
                {
                    payable(orderMatch.walletAccountOwner).transfer(orderValueSend);
                }
                else
                {                    
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderValueSend);
                }

                //transfer executed amount to buyer wallet

                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderAmountSend);                    
                }
                else
                {
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderAmountSend);
                }

                //Clean remaining amount (total executed)
                orderRemainingAmount[orderMatch.id] = 0;

                //Update remaining amount
                orderRemainingAmount[order.id] =  safeSub(orderRemainingAmount[order.id], orderAmountSend);

                //Clean remaining order amount (total executed)
                remainingOrderValue[orderMatch.id] = 0;

                //Update remaining order amount
                remainingOrderValue[order.id] = safeSub(remainingOrderValue[order.id], orderValueSend);

                //Status changed to Executed
                orderList[orderMatch.id - 1].status = 1;                

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,
                    execAmount: orderAmountSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,
                    execAmount: orderValueSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));

                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderAmountSend,orderValueSend,0);
                return 1;
            }
            else
            {
                //Partial Exec Sell Order
                //Total Exec Buy Order
                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[order.id], orderMatch.price, orderMatch.coinSend == networkcoinaddress ? 18 : ERC20(orderMatch.coinSend).decimals()); //amount to send - execution
                require (remainingOrderValue[order.id] >= orderValueSend,"INVREAMT");
                uint256 refundDifPrice = safeSub(remainingOrderValue[order.id], orderValueSend); //calculates price difference 
                uint256 orderAmountSend = orderRemainingAmount[order.id];

                //transfer executed amount to seller wallet
                if(orderMatch.coinReceive == networkcoinaddress)
                {
                    payable(orderMatch.walletAccountOwner).transfer(orderValueSend);

                    //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {
                        payable(order.walletAccountOwner).transfer(refundDifPrice);
                    }
                }
                else
                {                    
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderValueSend);

                   //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {                      
                        ERC20(order.coinSend).transfer(order.walletAccountOwner, refundDifPrice);
                    }
                }

                //transfer executed amount to buyer wallet

                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderAmountSend);
                    
                }
                else
                {
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderAmountSend);
                }

                //Update remaining amount
                orderRemainingAmount[orderMatch.id] = safeSub(orderRemainingAmount[orderMatch.id], orderAmountSend);
                //Clean remaining amount (total executed)
                orderRemainingAmount[order.id] = 0;

                //Update remaining order amount
                remainingOrderValue[orderMatch.id] = safeSub(remainingOrderValue[orderMatch.id], orderValueSend);
                //Clean remaining order amount (total executed)
                remainingOrderValue[order.id] = 0;

                //Status changed to Executed                
                orderList[order.id - 1].status = 1; 

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,
                    execAmount: orderAmountSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,
                    execAmount: orderValueSend,
                    execPrice: orderMatch.price,
                    orderBlock: block.number
                }));

                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderAmountSend,orderValueSend,refundDifPrice);
                return 1;
            }
        }
        else if(order.buySell == 1)
        {
            //Total Exec Buy Order
            //Total Exec Sell Order
            if(orderRemainingAmount[orderMatch.id] == orderRemainingAmount[order.id])
            {
                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[order.id], order.price, order.coinSend == networkcoinaddress ? 18 : ERC20(order.coinSend).decimals()); //amount to send - execution
                require (remainingOrderValue[orderMatch.id] >= orderValueSend,"INVREAMT");
                uint256 refundDifPrice = safeSub(remainingOrderValue[orderMatch.id], orderValueSend); //calculates price difference 
                uint256 orderAmountSend = orderRemainingAmount[order.id];

                //transfer executed amount to seller wallet
                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderValueSend);

                    //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {
                        payable(orderMatch.walletAccountOwner).transfer(refundDifPrice);
                    }
                }
                else
                {                    
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderValueSend);

                    //transfer price difference to buyer
                    if(refundDifPrice > 0)
                    {
                        ERC20(orderMatch.coinSend).transfer(orderMatch.walletAccountOwner, refundDifPrice);
                    }
                }

                //transfer executed amount to buyer wallet

                if(orderMatch.coinReceive == networkcoinaddress)
                {
                    payable(orderMatch.walletAccountOwner).transfer(orderAmountSend);
                }
                else
                {
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderAmountSend);
                }

                //Clean remaining amount (total executed)
                orderRemainingAmount[orderMatch.id] = 0;
                orderRemainingAmount[order.id] = 0;

                //Clean remaining order amount (total executed)
                remainingOrderValue[orderMatch.id] = 0;
                remainingOrderValue[order.id] = 0;

                //Status changed to Executed
                orderList[orderMatch.id - 1].status = 1;
                orderList[order.id - 1].status = 1; 

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,                    
                    execAmount: orderValueSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,
                    execAmount: orderAmountSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));

                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderValueSend,orderAmountSend,refundDifPrice);
                return 1;

            }
            else if(orderRemainingAmount[orderMatch.id] < orderRemainingAmount[order.id])
            {
                //Total Exec Buy Order
                //Partial Exec Sell Order

                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[orderMatch.id], order.price, order.coinSend == networkcoinaddress ? 18 : ERC20(order.coinSend).decimals()); //amount to send - execution
                require (remainingOrderValue[orderMatch.id] >= orderValueSend,"INVREAMT1");
                uint256 refundDifPrice = safeSub(remainingOrderValue[orderMatch.id], orderValueSend); //calculates price difference 

                uint256 orderAmountSend = orderRemainingAmount[orderMatch.id];

                //transfer executed amount to seller wallet             

                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderValueSend);

                    if(refundDifPrice > 0)
                    {
                        //transfer price difference to buyer
                        payable(orderMatch.walletAccountOwner).transfer(refundDifPrice);
                    }
                }
                else
                {                    
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderValueSend);
                    
                    if(refundDifPrice > 0)
                    {
                        //transfer price difference to buyer                        
                        ERC20(orderMatch.coinSend).transfer(orderMatch.walletAccountOwner, refundDifPrice);
                    }
                }

                //transfer executed amount to buyer wallet

                if(orderMatch.coinReceive == networkcoinaddress)
                {
                    payable(orderMatch.walletAccountOwner).transfer(orderAmountSend);
                }
                else
                {
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderAmountSend);
                }

                //Clean remaining amount (total executed)
                orderRemainingAmount[orderMatch.id] = 0;
                //Update remaining amount
                orderRemainingAmount[order.id] =  safeSub(orderRemainingAmount[order.id], orderAmountSend);

                //Clean remaining order amount (total executed)
                remainingOrderValue[orderMatch.id] = 0;
                //Update remaining order amount
                remainingOrderValue[order.id] = safeSub(remainingOrderValue[order.id], orderValueSend);

                //Status changed to Executed
                orderList[orderMatch.id - 1].status = 1;                

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,
                    execAmount: orderValueSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,                    
                    execAmount: orderAmountSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));

                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderValueSend,orderAmountSend,refundDifPrice);
                return 1;
            }
            else
            {
                //Partial Exec Buy Order
                //Total Exec Sell Order
                uint256 orderValueSend = safeMulFloat(orderRemainingAmount[order.id], order.price, order.coinSend == networkcoinaddress ? 18 : ERC20(order.coinSend).decimals()); //amount to send - execution
                require (remainingOrderValue[orderMatch.id] >= orderValueSend,"INVREAMT");
                
                uint256 orderAmountSend = orderRemainingAmount[order.id];

                //transfer executed amount to seller wallet   
                if(order.coinReceive == networkcoinaddress)
                {
                    payable(order.walletAccountOwner).transfer(orderValueSend);
                }
                else
                {                    
                    ERC20(order.coinReceive).transfer(order.walletAccountOwner, orderValueSend);
                }

                //transfer executed amount to buyer wallet 

                if(orderMatch.coinReceive == networkcoinaddress)
                {
                    payable(orderMatch.walletAccountOwner).transfer(orderAmountSend);
                    
                }
                else
                {
                    ERC20(orderMatch.coinReceive).transfer(orderMatch.walletAccountOwner, orderAmountSend);
                }

                //Update remaining amount
                orderRemainingAmount[orderMatch.id] = safeSub(orderRemainingAmount[orderMatch.id], orderAmountSend);
                 //Clean remaining amount (total executed)
                orderRemainingAmount[order.id] = 0;

                //Update remaining order amount
                remainingOrderValue[orderMatch.id] = safeSub(remainingOrderValue[orderMatch.id], orderValueSend);
                //Clean remaining order amount (total executed)
                remainingOrderValue[order.id] = 0;

                //Status changed to Executed                
                orderList[order.id - 1].status = 1; 

                //Set order match details
                orderDetailList[orderMatch.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: order.id,
                    execAmount: orderValueSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));
                
                //Set order details
                orderDetailList[order.id].push(OrderDetail({
                    executionDate: block.timestamp,
                    cancelDate: 0,
                    changeDate: block.timestamp,
                    execOrderId: orderMatch.id,                    
                    execAmount: orderAmountSend,
                    execPrice:order.price,
                    orderBlock: block.number
                }));

                emit OnOrderExecuted(order.id, orderMatch.id,order.coinReceive,orderMatch.coinReceive,orderValueSend,orderAmountSend,0);
                return 1;
            }
        }
    }

    function cancelOrder(uint orderId) external returns (bool success) 
    {   
        require(orderList[orderId-1].status == 0, "NOTSTATUSCANC"); //check order is pending

        require(orderList[orderId-1].walletAccountOwner ==  msg.sender || owner ==  msg.sender,"FN"); //check wallet owner FN = Forbidden
        
        uint256 refundCancelAmount = 0;

        if(orderList[orderId-1].buySell == 0)
        {
            refundCancelAmount = remainingOrderValue[orderList[orderId-1].id];
        }
        else
        {
            refundCancelAmount = orderRemainingAmount[orderList[orderId-1].id];
        }
        
        //transfer remaining sent amount to wallet owner
        if(orderList[orderId-1].coinSend == networkcoinaddress)
        {
            payable(orderList[orderId-1].walletAccountOwner).transfer(refundCancelAmount);
            
        }
        else
        {
            ERC20(orderList[orderId-1].coinSend).transfer(orderList[orderId-1].walletAccountOwner, refundCancelAmount);
        }

        //Clean remaining amount (refund)
        orderRemainingAmount[orderList[orderId-1].id] = 0;

        //Clean remaining order amount (refund)
        remainingOrderValue[orderList[orderId-1].id] = 0;

        //Status changed to Canceled
        if(orderList[orderId-1].walletAccountOwner != msg.sender)
        {
            orderList[orderList[orderId-1].id - 1].status = 9; //order cancel by admin
        }
        else
        {
            orderList[orderList[orderId-1].id - 1].status = 2; //order cancel by user
        }
        
        //Set order match details
        orderDetailList[orderList[orderId-1].id].push(OrderDetail({
            executionDate: 0,
            cancelDate: block.timestamp,
            changeDate: block.timestamp,
            execOrderId: 0,
            execAmount: refundCancelAmount,
            execPrice:0,
            orderBlock: block.number
        }));
        
        emit OnOrderCanceled(orderList[orderId-1].id, orderList[orderId-1].coinSend,refundCancelAmount);
        return true;
    }

    function transferFund(ERC20 token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Withdraw of deposit value
        if(address(token) != networkcoinaddress)
        {
            //Withdraw token
            token.transfer(to, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(to).transfer(amountInWei);
        }
    }

    function transferFundAndOrderCancel(ERC20 token, address to, uint256 amountInWei, uint orderId) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(orderList[orderId-1].status == 0, "NOTSTATUSCANC"); //check order is pending
        require(orderList[orderId-1].walletAccountOwner == to,"FNWallet"); //check wallet owner
        require(orderList[orderId-1].coinSend == address(token),"WRONGCOIN"); //check order sent token

        //Check pending amount for order 
        if(orderList[orderId-1].buySell == 0)
        {
            require(remainingOrderValue[orderList[orderId-1].id]<=amountInWei,"FAMT"); //Check amount send > than remaining amount in order
        }
        else
        {
            require(orderRemainingAmount[orderList[orderId-1].id]<=amountInWei,"FAMT1"); //Check amount send > than remaining amount in order
        }

        //Withdraw of deposit value
        if(address(token) != networkcoinaddress)
        {
            //Withdraw token
            token.transfer(to, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(to).transfer(amountInWei);
        }

        //Clean remaining amount (refund)
        orderRemainingAmount[orderList[orderId-1].id] = 0;

        //Clean remaining order amount (refund)
        remainingOrderValue[orderList[orderId-1].id] = 0;

        //Status changed to Canceled Forced by Admin
        orderList[orderList[orderId-1].id - 1].status = 19;
        
        //Set order match details
        orderDetailList[orderList[orderId-1].id].push(OrderDetail({
            executionDate: 0,
            cancelDate: block.timestamp,
            changeDate: block.timestamp,
            execOrderId: 0,
            execAmount: amountInWei,
            execPrice:0,
            orderBlock: block.number
        }));

        emit OnOrderCanceled(orderList[orderId-1].id, orderList[orderId-1].coinSend,amountInWei);
    }

    //Safe Math Functions
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeDivFloat(uint256 a, uint256 b, uint decimals) internal pure returns (uint256) 
    {
        uint _a  = a * safePow(10, uint256(decimals));
        return safeDiv(_a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}