// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
contract Trade{
    IERC20 token;
    OrderDetail[] public buyOrderBook;
    OrderDetail[] public sellOrderBook;
    address payable owner;
    uint256 public price = 500;
    uint256 public fee = 100;
    struct OrderDetail {
        uint price;
        uint amount;
        address user;
    }
    IUniswapV2Router02 public uniswapV2Router;
        
    constructor(address _token){
    token = IERC20(_token);

    owner = payable(msg.sender);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
    }
    
    
    function buyToken(uint amount) public payable{
        uint256 totalPrice = (amount*price)+fee;
        require(msg.value==totalPrice, "pay ether price and fee to buy tokens");
        owner.transfer(totalPrice);
        token.transferFrom(owner, msg.sender, amount);
    }
    
    receive() external payable {}
    
    function sellOrder(uint256 amount, uint256 _price)public payable {

        bool found = false;
        for(uint i=0; i<buyOrderBook.length; i++){
            if (buyOrderBook[i].price==_price && amount==buyOrderBook[i].amount) {
                uint256 allowance = token.allowance(msg.sender, address(this));
                require(allowance>=amount, "give approval before deposit");
                token.transferFrom(msg.sender, buyOrderBook[i].user,amount);
                uint256 totalPrice = amount*_price;
                payable(msg.sender).transfer(totalPrice);
                delete buyOrderBook[i];
                found = true;
                break;
            }
        }
        if(found==false){
            uint256 allowance = token.allowance(msg.sender, address(this));
            require(allowance>=amount, "give approval before deposit");
            token.transferFrom(msg.sender, address(this) ,amount);
            sellOrderBook.push(OrderDetail(_price,amount, msg.sender));        
        }
    }
        
    function buyOrder(uint256 amount, uint _price) public payable {
        uint256 totalPrice = (amount* _price)+fee;
        require(msg.value==totalPrice, "pay price and fee in ether");
        bool found = false;
        for(uint i=0; i<sellOrderBook.length; i++){
            if (sellOrderBook[i].price==_price && amount==sellOrderBook[i].amount) {
                token.transfer(msg.sender,amount);
                uint256 priceWithOutFee = amount * _price;
                payable(sellOrderBook[i].user).transfer(priceWithOutFee);
                owner.transfer(fee);
                delete sellOrderBook[i];
                found = true;
                break;
            }
        }
        if(found==false){
            buyOrderBook.push(OrderDetail(_price, amount, msg.sender));       
        }
    }
    
    function buyOtherToken(address _token) public payable {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = _token;

        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }
}