/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Wallet is Ownable{
    using SafeMath for uint256;

    struct Token {
        bytes32 ticker;  
        address tokenAddress;
    }

    //mapping which stores token structs with ticker as key, let's us access for examples tokenMapping[ticker].ticker for getting symbol and tokenMapping[ticker].tokenAddress for getting address
    mapping(bytes32 => Token) public tokenMapping; 

    //store all tickers 
    bytes32[] public TokenList; 

    //points to balances of different tokens, first key address of tokenHolder, second key token ticker
    mapping(address => mapping(bytes32 => uint256)) public balances;

    modifier tokenExists(bytes32 ticker) {
        require(tokenMapping[ticker].tokenAddress != address(0), "Token does not exist");
        _;
    }

    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external {
        //save the ticker to our mapping, be equal to new token with a ticker and address
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        //just want a list of all the ID's
        TokenList.push(ticker);
    }

    

    function deposit(uint amount, bytes32 ticker) tokenExists(ticker) external{
        //transfer from msg.sender to us
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(amount);
    }

    function withdraw(uint amount, bytes32 ticker) tokenExists(ticker) external{
        //make sure the token exists
        require(balances[msg.sender][ticker] >= amount, "Balance not sufficient");
        //adjust the balances before
        balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(amount);
        //input the address (token address for the ticker) and transfer from us to the msg.sender 
        //msg.sender is the rightfull owner of the tokens
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    function depositEth() payable external {
        require(msg.value > 0, "depositEth: msg.value should be higher than zero");
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].add(msg.value);
    }
    
    function withdrawEth(uint amount) external {
        require(balances[msg.sender][bytes32("ETH")] >= amount,'Insufficient balance'); 
        balances[msg.sender][bytes32("ETH")] = balances[msg.sender][bytes32("ETH")].sub(amount);
        msg.sender.call{value:amount}("");
        
    }

}

contract Dex is Wallet {
using SafeMath for uint256;
    
    enum Side {
        Buy, 
        Sell 
    }

    //order.side = Side.Buy

    struct Order {
        uint256 id;
        address trader;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 price; //limit orders
        uint256 filled;
    }

    uint256 public nextOrderID = 0;

    mapping(bytes32 => mapping(uint256 => Order[])) orderBook;

    function getTokenList() public view returns(uint256){
        uint256 token = TokenList.length;
        return token;
    }

    function getTokenBalance(bytes32 _ticker) view public returns(uint256 balance){
        balance = balances[msg.sender][_ticker];
        return balance;
    }

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint256(side)];
    }

    function createLimitOrder( Side side, bytes32 ticker, uint256 amount, uint256 price) public {

        if(side == Side.Buy){
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
        }
        else if(side == Side.Sell){
            require(balances[msg.sender][ticker] >= amount);
        }
        Order[] storage orders = orderBook[ticker][uint256(side)];
        orders.push( Order(nextOrderID, msg.sender, side, ticker, amount, price, 0) );

        //Bubble Loop Algorithm to sort Buy and Sell orders
        uint256 i = orders.length > 0 ? orders.length -1 : 0;

        if(side == Side.Buy){
           while(i > 0){
               if(orders[i-1].price > orders[i].price){
                   break;
               }
               Order memory orderToMove = orders[i-1];
               orders[i - 1] = orders[i];
               orders[i] = orderToMove;
               i--;
           }
        }

        else if(side == Side.Sell){
            while(i > 0){
               if(orders[i - 1].price < orders[i].price){
                   break;
               }
               Order memory orderToMove = orders[i-1];
               orders[i - 1] = orders[i];
               orders[i] = orderToMove;
               i--;
           }
        }
        nextOrderID++;
}

     function createMarketOrder( Side side, bytes32 ticker, uint256 amount)public {
         if(side == Side.Sell){
            require(balances[msg.sender][ticker] >= amount, "insufficient balance");
         }
        
        uint256 orderBookSide;
        if(side == Side.Buy){
            orderBookSide = 1;
        }else{
            orderBookSide = 0;
        }

        Order[] storage orders = orderBook[ticker][orderBookSide];

        uint256 totalFilled = 0;

        //this loop will take us into the orderbook
        for(uint256 i = 0; i < orders.length && totalFilled < amount; i++){
            //how many existing orders can we fill with our new market order
            uint256 leftToFill = amount.sub(totalFilled);//amount minus totalFilled
            uint256 availableToFill = orders[i].amount.sub(orders[i].filled); // how much is available in this current order
            uint256 filled = 0;
            if( availableToFill > leftToFill  ){
                filled = leftToFill; // fill the entire market order
            }else{
                filled = availableToFill; // fill whats available in order[i]
            }
            totalFilled = totalFilled.add(filled);//update totalFilled
            orders[i].filled = orders[i].filled.add(filled);
            uint256 cost = filled.mul(orders[i].price);

            if(side == Side.Buy){
                //verfiy the buyer has enough eth to cover trade
                require(balances[msg.sender]["ETH"] >= cost, "You do not have enough ETH to cover trade");
                //transfer Eth from buyer to seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
                //transfer tokens from seller to buyer
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);

            }else if(side == Side.Sell){
                //execute the trade
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
    
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }            

        }

            //Loop through order book and remove 100% filled orders
            while( orders.length > 0 && orders[0].filled == orders[0].amount ){
                //removing the top element by overwriting every element with the next element in the list
                for(uint256 i = 0; i < orders.length -1; i++){
                    orders[i] = orders[i +1];
                }
                orders.pop();
        }
     }

}