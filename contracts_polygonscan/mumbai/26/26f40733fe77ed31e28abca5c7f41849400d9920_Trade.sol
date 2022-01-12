/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//API to expose the tokens functions to our exchange
interface ERC20API{
    //API function to check token allowances
    function allowance(address owner, address delegate) external view returns (uint);

    //API function to transfer to receiver with amount tokens
    function transfer(address receiver, uint numTokens) external returns (bool);

    //API function to transfer to receiver with amount tokens from sender
    function transferFrom(address owner, address buyer, uint numTokens) external returns(bool);
}

/**
* Mindmaps:
*
* Structs (Offer, OrderBook, TokenType, tokenList): https://drive.google.com/file/d/1oHJrva8hZ97GgtbQN-Lt3-f0xI_sLc2R/view?usp=sharing    
* StoreBuyOrder function: https://drive.google.com/file/d/1wewmW26YbGiJpeSpCrjl5QChDo8OzzhF/view?usp=sharing
*
*/
contract Trade{
    struct Offer{
        //amount of tokens to be traded
        uint amount;

        //transaction creator
        address maker;
    }

    struct OrderBook{
        //The next higher price
        uint higherPrice;

        //The previous higher price
        uint lowerPrice;
        
        //list of orders at this price
        mapping (uint => Offer) offers;

        //pointer to the first offer
        uint offerPointer;

        //how many orders in this price
        uint offerLength;
    }
    
    //The type of token that the user needs to trade
    struct TokenType{
        //Address of the token(contract) to be traded
        address tokenContract;

        ////////////////////////// buyBook /////////////////////////////////////////

        //a mapping of price to orders on that price
        mapping (uint => OrderBook) buyBook;

        //pointer to the highest price on this book
        uint maxBuyPrice;

        //pointer to the lowest price on this book
        uint minBuyPrice;

        //how many buy prices are there
        uint amountBuyPrices;
        
        //////////////////////////// sellBook ///////////////////////////////////////

        //a mapping of price to orders on that price
        mapping (uint => OrderBook) sellBook;

        //pointer to the lowest price on this book
        uint minSellPrice;

        //pointer to the highest price on this book
        uint maxSellPrice;

        //how many sell prices are there
        uint amountSellPrice;
    }
    
    //List of token types
    mapping (address => TokenType) tokenList;
    
    //mapping (Sender's address => Number of ETH)
    mapping (address => uint) public ethBalance;
    
    //mapping (Sender's address => mapping(TokenType's Address => Number of tokens))
    mapping (address => mapping(address => uint)) public tokenBalance;


    ///////////////////////////////////////// List of events /////////////////////////////////////////
    
    event DepositToken(address, uint);
    event WithdrawToken(address, uint);

    event ReceivedETH(address, uint);
    event WithdrawETH(address, uint);

    ///////////////////////////////////////// List of APIs /////////////////////////////////////////
    function getTokenBalance(address _token) public view returns(uint256) {
        return tokenBalance[msg.sender][_token];
    }

    /**
    * This function allows users deposit TOKEN from the user's wallet to the exchange
    * _token: the address of the token(contract) to be traded
    * _amount: the number of tokens the user wants to deposit to the exchange
    */
    function depositToken(address _token, uint256 _amount) public payable{
        //loads the API with the address given
        ERC20API tokenLoaded = ERC20API(_token);

        //requires that our contract has the permission to withdraw form the user on the Token
        require(tokenLoaded.allowance(msg.sender, address(this)) >= _amount, concatenate("Check the token allowance, ", toString(tokenLoaded.allowance(msg.sender, address(this)))) );

        //requires that the transfer to our account succeeds
        require(tokenLoaded.transferFrom(msg.sender, address(this), _amount), "You need to sell at least some tokens");

        //adds balance of the token on the user balance
        tokenBalance[msg.sender][_token] += _amount;

        //Broadcast event DepositToken(address, uint)
        emit DepositToken(_token, _amount);
    }
    

    /**
    * This function allows users withdraw TOKEN from the exchange to the user's wallet
    * _token: the address of the token(contract) to be traded
    * _amount: the number of tokens the user wants to withdraw from the exchange
    */
    function withdrawToken(address _token, uint _amount) public {
        //loads the API with the address given
        ERC20API tokenLoaded = ERC20API(_token);

        //requires that after the operation the users balance won't be negative
        require(tokenBalance[msg.sender][_token] - _amount >= 0);

        //requires that the users balance won't overflow after
        require(tokenBalance[msg.sender][_token] - _amount <= tokenBalance[msg.sender][_token]);

        //reduces the users balance first
        tokenBalance[msg.sender][_token] -= _amount;

        //calls the API function to transfer on the tokens contract form exchange to user
        require(tokenLoaded.transfer(msg.sender, _amount));

        //Broadcast event WithdrawToken(address, uint)
        emit WithdrawToken(_token, _amount);
    }

    //we make a function to allow users to send Ethereum to the exchange
    receive() external payable {
        //requires that this won't overflow
        require(ethBalance[msg.sender] + msg.value >= ethBalance[msg.sender]);

        //adds the balance to the user
        ethBalance[msg.sender] += msg.value;

        emit ReceivedETH(msg.sender, msg.value);
    }

    function sendEther(address payable _to) public payable {
        // This function is no longer recommended for sending Ether.
        _to.transfer(msg.value);
    }

    //This function allows users withdraw ETH from the exchange to the user's wallet
    function withdrawEth(uint _wei) public {
        //requires eth balance of user won't be negative
        require(ethBalance[msg.sender] - _wei >= 0);

        //requires that this won't overflow
        require(ethBalance[msg.sender] - _wei <= ethBalance[msg.sender]);

        //reduces the users eth balance first
        ethBalance[msg.sender] -= _wei;

        //Convert adddress to address payable
        address payable senderAddress = payable(msg.sender);

        //transfer ETH from the exchange to the user's wallet
        senderAddress.transfer(_wei);

        emit WithdrawETH(msg.sender, _wei);
    }

    /**
    * This function will be called when either one:
    * 1. No sell order matches our limit price, so the order will be placed on the market as a maker (stored to be filled with a future selling demand)
    * 2. There were sell orders that matched, but we have filled them and there is a "leftover", and the remaining of the order has to be stored.
    *
    * It should receive as arguments:
    * address _token: address of the contract of the token our user wants to trade. We are allowing the users to trade any token they want, without the need for us to "list" the token.
    * uint _price: the limit price (highest) the user wants to buy at (exchange does the "best effort" to match with the lowest price).
    * uint _amount amount of tokens the user wants to buy.
    * address _maker the address of the buyer
    */
    function storeBuyOrder(address _token, uint _price, uint _amount, address _maker) private{
        // increases the length of the queue by one
        tokenList[_token].buyBook[_price].offerLength++;

        // tokenList[_token].buyBook[_price] loads the buybook at that price, just like before.
        // offers[] is used because we will set the offer at this position of the queue, in the next line is what is inside this.
        // tokenList[_token].buyBook[_price].offerLength the length of the queue 
        // = Offer(_amount, _maker); sets the last (lines above) place of the queue as the current order.
        tokenList[_token].buyBook[_price].offers[tokenList[_token].buyBook[_price].offerLength] = Offer(_amount, _maker);
        
        // Are we the first in the queue?
        if(tokenList[_token].buyBook[_price].offerLength == 1){
            // sets the pointer to start here
            tokenList[_token].buyBook[_price].offerPointer = 1;
            tokenList[_token].amountBuyPrices++;
            
            uint highestBuyPrice = tokenList[_token].maxBuyPrice;
            uint lowestBuyPrice = tokenList[_token].minBuyPrice;
            
            //if the price list is empty or we are the lowest one
            if(highestBuyPrice == 0 || lowestBuyPrice > _price){
                //if the price list is empty
                if (highestBuyPrice == 0){
                    //we are the highest buy price of the token
                    tokenList[_token].maxBuyPrice = _price;

                    // the higher price of the new order is itself, as it is on the top of the book
                    tokenList[_token].buyBook[_price].higherPrice = _price;

                    //the lower price or our order is zero
                    tokenList[_token].buyBook[_price].lowerPrice = 0;
                }

                //we are the lowest one
                else{
                    //the lowest prices lower price is the new order
                    tokenList[_token].buyBook[lowestBuyPrice].lowerPrice = _price;

                    // the new orders higher price is the old lowest priced order
                    tokenList[_token].buyBook[_price].higherPrice = lowestBuyPrice;

                    //the lower price of our order is zero
                    tokenList[_token].buyBook[_price].lowerPrice = 0;
                }

                // Update min buy price of the token
                tokenList[_token].minBuyPrice = _price;
            }

            //checks if we are the biggest price
            else if(highestBuyPrice < _price){
                // current highest buy prices "higher price" points to the new order
                tokenList[_token].buyBook[highestBuyPrice].higherPrice = _price;

                // new orders higher price points to ourselves as there is no one higher than us yet
                tokenList[_token].buyBook[_price].higherPrice = _price;

                // new orders lower price points to previous highest price
                tokenList[_token].buyBook[_price].lowerPrice = highestBuyPrice;

                // updates tokens highest price to reflect the new order
                tokenList[_token].maxBuyPrice = _price;
            }
            
            // if we are in the middle
            else{
                // what is the max buy price at the moment
                uint buyPrice = tokenList[_token].maxBuyPrice;
                
                // stores if we found the spot
                bool finished = false;

                while(buyPrice > 0 && !finished){
                    // checks if this is the spot
                    // if it is, place the new order between the item and the item's higher value
                    // marks task as complete to break out of the loop
                    if(buyPrice < _price && tokenList[_token].buyBook[buyPrice].higherPrice > _price){
                        // the new orders lower price is the item we have found
                        tokenList[_token].buyBook[_price].lowerPrice = buyPrice;

                        // the new orders higher price is the items higher price
                        tokenList[_token].buyBook[_price].higherPrice = tokenList[_token].buyBook[buyPrice].higherPrice;

                        // the items higher prices lower price is the new order
                        tokenList[_token].buyBook[tokenList[_token].buyBook[buyPrice].higherPrice].lowerPrice = _price;

                        // the items higher price is the new order
                        tokenList[_token].buyBook[buyPrice].higherPrice = _price;

                        // task is finished, break out of the loop
                        finished = true;
                    }else{
                        // goes one item down on the linked list
                        buyPrice = tokenList[_token].buyBook[buyPrice].lowerPrice;
                    }
                }
            }
        }
    }

    function buyToken(address _token, uint _price, uint _amount) public{
        //loads the token with the given address from the structure mapping
        TokenType storage loadedToken = tokenList[_token];

        //the total amount of ETH this account will move
        uint ethRequired = _price * _amount;
        
        //checks for overflow
        require(ethRequired >= _amount, "ethRequired must >= amount");
        require(ethRequired >= _price, "ethRequired must >= _price");
        require(ethBalance[msg.sender] >= ethRequired, "ethBalance[msg.sender] must >= ethRequired");
        require(ethBalance[msg.sender] - ethRequired >= 0, "ethBalance[msg.sender] - ethRequired must >= 0");
        require(ethBalance[msg.sender] - ethRequired <= ethBalance[msg.sender], "ethBalance[msg.sender] - ethRequired must <= ethBalance[msg.sender]");

        //we first deduct from the caller balance before anything else
        ethBalance[msg.sender] -= ethRequired;
        
        //if no sell order gets filled
        if (loadedToken.amountSellPrice == 0 || loadedToken.minSellPrice >= _price){
            storeBuyOrder(_token, _price, _amount, msg.sender); //store the whole order
        }else{
            uint ethAmount = 0;
            uint remainingAmount = _amount;
            uint buyPrice = loadedToken.minSellPrice;
            uint offerPointer;

            while(buyPrice <= _price && remainingAmount > 0){
                offerPointer = loadedToken.sellBook[buyPrice].offerPointer;
                
                while(offerPointer <= loadedToken.sellBook[buyPrice].offerLength && remainingAmount > 0){
                    uint volumeAtPointer = loadedToken.sellBook[buyPrice].offers[offerPointer].amount;
                    if(volumeAtPointer <= remainingAmount) {
                        ethAmount = volumeAtPointer * buyPrice;
                        require(ethBalance[msg.sender] >= ethAmount, "ethBalance[msg.sender] must >= ethAmount");
                        require(ethBalance[msg.sender] - ethAmount <= ethBalance[msg.sender], "ethBalance[msg.sender] - ethAmount must <= ethBalance[msg.sender]");
                        ethBalance[msg.sender] -= ethAmount;
                        tokenBalance[msg.sender][_token] += volumeAtPointer;
                        loadedToken.sellBook[buyPrice].offers[offerPointer].amount = 0;
                        ethBalance[loadedToken.sellBook[buyPrice].offers[offerPointer].maker] += ethAmount;
                        loadedToken.sellBook[buyPrice].offerPointer++;
                        remainingAmount -= volumeAtPointer;
                    }else{
                        require(loadedToken.sellBook[buyPrice].offers[offerPointer].amount > remainingAmount, "amount must > remainingAmount");
                        ethAmount = remainingAmount * buyPrice;
                        require(ethBalance[msg.sender] - ethAmount <= ethBalance[msg.sender], "ethBalance[msg.sender] - ethAmount must <= ethBalance[msg.sender]");
                        ethBalance[msg.sender] -= ethAmount;
                        loadedToken.sellBook[buyPrice].offers[offerPointer].amount -= remainingAmount;
                        ethBalance[loadedToken.sellBook[buyPrice].offers[offerPointer].maker] += ethAmount;
                        tokenBalance[msg.sender][_token] += remainingAmount;
                        remainingAmount = 0;
                    }
                    
                    if(offerPointer == loadedToken.sellBook[buyPrice].offerLength && loadedToken.sellBook[buyPrice].offers[offerPointer].amount == 0){
                        loadedToken.amountSellPrice--;
                        if(buyPrice == loadedToken.sellBook[buyPrice].higherPrice || loadedToken.sellBook[buyPrice].higherPrice == 0){
                            loadedToken.minSellPrice = 0;
                        }else{
                            loadedToken.minSellPrice = loadedToken.sellBook[buyPrice].higherPrice;
                            loadedToken.sellBook[loadedToken.sellBook[buyPrice].higherPrice].lowerPrice = 0;
                        }
                    }

                    offerPointer++;
                }

                buyPrice = loadedToken.minSellPrice;
            }

            if (remainingAmount > 0){
                buyToken(_token, _price, remainingAmount);
            }
        }
    }

    function storeSellOrder(address _token, uint _price, uint _amount, address _maker) private{
        tokenList[_token].sellBook[_price].offerLength++;
        tokenList[_token].sellBook[_price].offers[tokenList[_token].sellBook[_price].offerLength] = Offer(_amount, _maker);
        
        if (tokenList[_token].sellBook[_price].offerLength == 1){
            tokenList[_token].sellBook[_price].offerPointer = 1;
            tokenList[_token].amountSellPrice++;
            
            uint currentSellPrice = tokenList[_token].minSellPrice;
            uint highestSellPrice = tokenList[_token].maxSellPrice;
            
            if (highestSellPrice == 0 || highestSellPrice < _price){
                if(currentSellPrice == 0){
                    tokenList[_token].minSellPrice =_price;
                    tokenList[_token].sellBook[_price].higherPrice = _price;
                    tokenList[_token].sellBook[_price].lowerPrice = 0;
                }else{
                    tokenList[_token].sellBook[highestSellPrice].higherPrice = _price;
                    tokenList[_token].sellBook[_price].lowerPrice = highestSellPrice;
                    tokenList[_token].sellBook[_price].higherPrice = _price;
                }
                tokenList[_token].maxSellPrice = _price;
            }else if(currentSellPrice > _price){
                tokenList[_token].sellBook[currentSellPrice].lowerPrice = _price;
                tokenList[_token].sellBook[_price].higherPrice = currentSellPrice;
                tokenList[_token].sellBook[_price].lowerPrice = 0;
                tokenList[_token].minSellPrice = _price;
            }else{
                uint sellPrice = tokenList[_token].minSellPrice;
                bool finished = false;
                while(sellPrice > 0 && !finished){
                    if(sellPrice < _price && tokenList[_token].sellBook[sellPrice].higherPrice > _price){
                        tokenList[_token].sellBook[_price].lowerPrice = sellPrice;
                        tokenList[_token].sellBook[_price].higherPrice = tokenList[_token].sellBook[sellPrice].higherPrice;
                        
                        tokenList[_token].sellBook[tokenList[_token].sellBook[sellPrice].higherPrice].lowerPrice = _price;
                        
                        tokenList[_token].sellBook[sellPrice].higherPrice = _price;
                    }
                    sellPrice = tokenList[_token].sellBook[sellPrice].higherPrice;
                }
            }
        }
    }

    function sellToken(address _token, uint _price, uint _amount) public{
        TokenType storage loadedToken = tokenList[_token];
        uint ethRequired = _price * _amount;
        
        require(ethRequired >= _amount, concatenate("ethRequired must >= ", toString(_amount)));
        require(ethRequired >= _price, concatenate("ethRequired must >= ", toString(_price)));
        require(tokenBalance[msg.sender][_token] >= _amount, concatenate("tokenBalance must >= ", toString(_amount)) );
        require(tokenBalance[msg.sender][_token] - _amount >= 0, "tokenBalance[msg.sender][_token] - _amount must >= 0");
        require(ethBalance[msg.sender] + ethRequired >= ethBalance[msg.sender]);
        
        tokenBalance[msg.sender][_token] -= _amount;
        
        if(loadedToken.amountBuyPrices == 0 || loadedToken.maxBuyPrice < _price){
            storeSellOrder(_token, _price, _amount, msg.sender);
        }else {
            uint sellPrice = loadedToken.maxBuyPrice;
            uint remainingAmount = _amount;
            uint offerPointer;
            while (sellPrice >= _price && remainingAmount > 0){
                offerPointer = loadedToken.buyBook[sellPrice].offerPointer;
                while(offerPointer <= loadedToken.buyBook[sellPrice].offerLength && remainingAmount>0){
                    uint volumeAtPointer = loadedToken.buyBook[sellPrice].offers[offerPointer].amount;
                    if (volumeAtPointer <= remainingAmount){
                        uint ethRequiredNow = volumeAtPointer * sellPrice;
                        require(tokenBalance[msg.sender][_token] >= volumeAtPointer);
                        require(tokenBalance[msg.sender][_token] - volumeAtPointer>=0);
                        tokenBalance[msg.sender][_token] -= volumeAtPointer;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token] += volumeAtPointer;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount = 0;
                        ethBalance[msg.sender] += ethRequiredNow;
                        loadedToken.buyBook[sellPrice].offerPointer++;
                        remainingAmount -= volumeAtPointer;
                    }else{
                        require(volumeAtPointer - remainingAmount>0);
                        ethRequired = remainingAmount * sellPrice;
                        require(tokenBalance[msg.sender][_token] >= remainingAmount);
                        tokenBalance[msg.sender][_token] -= remainingAmount;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount -= remainingAmount;
                        ethBalance[msg.sender] += ethRequired;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token] += remainingAmount;
                        remainingAmount = 0;
                    }
                    
                    if(offerPointer == loadedToken.buyBook[sellPrice].offerLength && loadedToken.buyBook[sellPrice].offers[offerPointer].amount == 0){
                        loadedToken.amountBuyPrices--;
                        if (sellPrice == loadedToken.buyBook[sellPrice].lowerPrice || loadedToken.buyBook[sellPrice].lowerPrice == 0){
                        loadedToken.maxBuyPrice = 0;
                        }else {
                            loadedToken.maxBuyPrice = loadedToken.buyBook[sellPrice].lowerPrice;
                            loadedToken.buyBook[loadedToken.buyBook[sellPrice].lowerPrice].higherPrice = loadedToken.maxBuyPrice;
                        }
                    }
                    offerPointer++;
                }
                sellPrice = loadedToken.maxBuyPrice;
            }
            if (remainingAmount > 0){
                sellToken(_token, _price, remainingAmount);
            }
        }
    }

    /**
    * The function will take 3 arguments, 
    * _token: the address of the ERC20 compatible token that has a struct of a TokenType stored in our exchange, 
    * isSellOrder: a boolean telling if the order is a sell order or not, 
    * _price: the price of the orders that the user wants to delete
    */
    function removeOrder(address _token, bool isSellOrder, uint _price) public{
        //loads the token with the given address from the structure mapping
        TokenType storage loadedToken = tokenList[_token];

        //Is it a sell or a buy order?
        if (isSellOrder){
            uint counter = loadedToken.sellBook[_price].offerPointer;
            while (counter <= loadedToken.sellBook[_price].offerLength){
                // if the maker of the order is the caller
                if (loadedToken.sellBook[_price].offers[counter].maker == msg.sender){
                    uint orderVolume = loadedToken.sellBook[_price].offers[counter].amount;
                    require(tokenBalance[msg.sender][_token] + orderVolume >= tokenBalance[msg.sender][_token]);
                    loadedToken.sellBook[_price].offers[counter].amount = 0;
                    tokenBalance[msg.sender][_token] += orderVolume;
                }

                counter++;
            }
        }else {
            uint counter = loadedToken.buyBook[_price].offerPointer;
            while (counter <= loadedToken.buyBook[_price].offerLength){
                if (loadedToken.buyBook[_price].offers[counter].maker == msg.sender){
                    uint orderVolume = loadedToken.buyBook[_price].offers[counter].amount * _price;
                    require(ethBalance[msg.sender] + orderVolume >= ethBalance[msg.sender]);
                    loadedToken.buyBook[_price].offers[counter].amount = 0;
                    
                }
                counter++;
            }
        }
    }

    function getSellOrders(address _token) public view returns(uint[] memory, uint[] memory){
        TokenType storage loadedToken = tokenList[_token];

        uint[] memory ordersPrices = new uint[](loadedToken.amountSellPrice);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountSellPrice);
        
        uint sellPrice = loadedToken.minSellPrice;
        uint counter = 0;
        
        if (loadedToken.minSellPrice > 0){
            while(sellPrice <= loadedToken.maxSellPrice){
                
                 ordersPrices[counter] = sellPrice;
                 uint priceVolume = 0;
                 uint offerPointer = loadedToken.sellBook[sellPrice].offerPointer;
                
                while(offerPointer <= loadedToken.sellBook[sellPrice].offerLength){
                    priceVolume += loadedToken.sellBook[sellPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                ordersvolumes[counter] = priceVolume;
                if (sellPrice == loadedToken.sellBook[sellPrice].higherPrice){
                    break;
                }else{
                    sellPrice = loadedToken.sellBook[sellPrice].higherPrice;
                }
                counter++;
            }
        }

        return(ordersPrices, ordersvolumes);
    }
    
    function getBuyOrders(address _token) public view returns(uint[] memory, uint[] memory){
        TokenType storage loadedToken = tokenList[_token];
        uint[] memory ordersPrices = new uint[](loadedToken.amountBuyPrices);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountBuyPrices);
        
        uint buyPrice = loadedToken.minBuyPrice;
        uint counter = 0;
        
        if (loadedToken.maxBuyPrice > 0){
            while(buyPrice <= loadedToken.maxBuyPrice){
                ordersPrices[counter] = buyPrice;
                uint priceVolume = 0;
                uint offerPointer = loadedToken.buyBook[buyPrice].offerPointer;
                
                while(offerPointer <= loadedToken.buyBook[buyPrice].offerLength){
                    priceVolume += loadedToken.buyBook[buyPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                
                ordersvolumes[counter] = priceVolume;
                
                if (buyPrice == loadedToken.buyBook[buyPrice].higherPrice){
                    break;
                }else{
                    buyPrice = loadedToken.buyBook[buyPrice].higherPrice;
                }
                counter++;
            }
        }
        
        return(ordersPrices, ordersvolumes);
    }

    function concatenate(string memory s1, string memory s2) internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
}