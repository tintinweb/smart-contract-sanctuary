// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "./Wallet.sol";
import "./SafeMath.sol";

contract Dex is Wallet{

    using SafeMath for uint256;

    enum Side{
        BUY, //0
        SELL //1
    }

    //создаем объект заказ
    struct Order{

        uint id; //id заказа
        address trader; //адрес пользователя заказа
        Side side; //статус
        bytes32 ticker; //токен
        uint amount; //сумма
        uint price; //цена
        uint filled; //amount of elements in MarketOrder
    }

    // mapping{
    //     токен:{
    //         статус:заказ,
    //         side:Order,
    //     },

    function getUser() public view returns(address){
        return msg.sender;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) orderBook;

    function getOrderBook(bytes32 ticker, Side side) public view returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    //sorting orderBook - better price can be first in top the orderBook
    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public payable{
        Order[] storage orders = orderBook[ticker][uint(side)];
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
        if(side == Side.BUY){
            require(balances[msg.sender][ticker] >= amount.mul(price), "You haven't enough amount");
            orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0));
            uint max = 0;
            for(uint j = 0; j < orders.length - 1; j++){
                for(uint i = 0; i < orders.length - 1; i++){
                    if(orders[i].price < orders[i+1].price){
                        max = orders[i].price;
                        orders[i] = orders[i+1];
                        orders[i+1].price = max;
                    }
                }
            }
        }
        else if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "You haven't enough amount");
            orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0));
            uint max = 0;
            for(uint j = 0; j < orders.length - 1; j++){
                for(uint i = 0; i < orders.length - 1; i++){
                    if(orders[i].price > orders[i+1].price){
                        max = orders[i].price;
                        orders[i] = orders[i+1];
                        orders[i+1].price = max;
                    }
                }
            }
        }
        nextOrderId++;
    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
        } 
        //создаем новую переменную покупка-продажа
        uint orderBookSide;
        if(side == Side.BUY){
            //если в маркете покупаем, то маркет продает, поэтому 1
            orderBookSide = 1;
        }
        else{
            //если продаем в маркет, то маркет покупает, поэтому 0
            orderBookSide = 0;
        }
        Order[] storage orders = orderBook[ticker][orderBookSide];

        uint totalFilled = 0; //максимальное количество MarketOrders

        for(uint i = 0; i < orders.length && totalFilled < amount; i++){
            uint leftToFill = amount.sub(totalFilled); //10
            //How mach we can fill from orders[i]
            uint availableToFill = orders[i].amount.sub(orders[i].filled);//200 //order.amount - order.filled
            //update totalFilled
            uint filled = 0;
            if(availableToFill > leftToFill){
                filled = leftToFill;//fill the entire market order
            }
            else{
                filled = availableToFill; //fill as mush as is available in order[i]
            }
            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);
            //Execute the trade - совершить сделку
            //shift balances between buyer/seller
            if(side == Side.BUY){
                //Verify that the buyer has enough ETH to cover the purchase (require)
                require(balances[msg.sender][ticker] >= cost, "This is a error");
                //msg.sender is a buyer

                //transfer ETH from Buyer to Seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                //transfer Tokens from Seller to Buyer
                balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);

            }

            else if(side == Side.SELL){
                //msg.sender is the seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }
        }

        //Loop through the orderbook and remove 100% filled orders
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            //Remove the top el tin the array by overwriting every el
            //with the next el in order list

            for(uint i = 0; i < orders.length - 1; i++){
                orders[i] = orders[i+1];
            }
            orders.pop();
        }


    }
}