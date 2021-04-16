/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

/**
 * 1. Store stop limit order
 * 2. triger stop limit order 
*/

// File: veeStopLimitOrder.sol

pragma solidity ^0.5.16;

contract veeStopLimitOrder {
    enum DexInfo {
            NO_None,        
            UNISWAP, //CURRENT uniswap only
            SUSHISWAP
    }

    enum TokenInfo {
            ETH,        
            DAI, //CURRENT uniswap only
            USDC,
            USDT,
            ZRX
    }

    struct stopLimitOrder{
        uint orderID;
        address owner;
        uint amount;
        uint maxPrice;
        uint minPrice;
        uint expireTime;//hours
        DexInfo dex;
        TokenInfo tokenFrom; //sale token
        TokenInfo tokenTo;   //buy token, exchange token from  tokenFrom->tokenTo
        bool isAutoRepay;
        uint maxAcceptGasFee;
    }

        //1. 创建挂单成功后的EVENT,3个参数为indexed用于过滤和检索
     event OnCreateOroder(     bytes32 indexed orderID, 
                                address indexed orderOwner, 
                                string  indexed tokenFrom, 
                                string tokenTo, 
                                uint amount,
                                uint maxPrice, 
                                uint minPrice, 
                                uint expiryDate,
                                bool isAutoRepay);

     //2. 挂单触发执行成功后的EVENT,3个参数为indexed用于过滤和检索
     // uniswapExchangeNum： 是UNISWAP函数TokenA->TokenB的真实交易数量
     event OnCompleteOroder(    bytes32 indexed orderID, 
                                address indexed orderOwner, 
                                string indexed tokenPair, 
                                uint uniswapExchangeNum);

     //3. 挂单过期后的EVENT,3个参数为indexed用于过滤和检索
     event OnCancelOroder(bytes32 indexed orderID);

     //all of stop limit ordrs by accout address
     mapping (bytes32 => bool) public successOrderQueue;

     
    function random() private view returns (uint) {

        uint randomHash = uint(keccak256(abi.encode(block.difficulty,now)));        
        return randomHash % 1000;
    } 

    function concate(string memory str1,string memory sperator,string memory str2) internal view returns(string memory)
    {
        return string(abi.encodePacked(str1,sperator,str2));
    }

    function CreateOrder(address orderOwner,string calldata  tokenFrom,string calldata  tokenTo,uint amount,uint maxPrice,uint minPrice, uint expiryDate,bool isAutoRepay) external returns (bytes32) {

        bytes32 orderid = keccak256(abi.encode(orderOwner,
                                                maxPrice,
                                                minPrice,
                                                amount, 
                                                expiryDate,
                                                random()
                                                )
                                            );

        emit OnCreateOroder(   orderid,
                               orderOwner,
                               tokenFrom,
                               tokenTo, 
                               amount,
                               maxPrice, 
                               minPrice, 
                               expiryDate,
                               isAutoRepay);
                               
                               return orderid;

     }

    function CancelOroder(bytes32 orderid)external returns(bool){
        emit OnCancelOroder(orderid);
        return true;
    }


    function CheckOrder(bytes32 orderid,bool isRun)external view returns(bool){

            if(isRun && !successOrderQueue[orderid]){
                    return true;
            }

            return false;
    }

    function ExecuteOrder(
                                bytes32 orderid,
                                address orderOwner, 
                                string calldata  tokenFrom,
                                string calldata  tokenTo,
                                uint amount,
                                bool isRun,
                                uint uniswapExchnum) external returns(bool){
            

            //call uniswap exchangeToken(tokenA->TokenB)//save to contract address instead of user wallet
            uint uniswapExchangeNum = uniswapExchnum;
            
            successOrderQueue[orderid] = true;

             emit OnCompleteOroder(
                                        orderid,
                                        orderOwner,
                                        concate(tokenFrom , "/", tokenTo), 
                                        uniswapExchangeNum
                               );
                               return true;
    }
}