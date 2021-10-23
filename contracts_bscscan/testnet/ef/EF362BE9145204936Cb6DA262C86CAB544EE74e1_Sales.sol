//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import 'SafeMath.sol';
import 'Address.sol';
import 'Ownable.sol';
import 'IBEP20.sol';

contract Sales is Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    uint256 private _rate;
    uint256 private _buy_limit;
    uint256 private _bought_tokens;
    uint256 private _min_buy_amount;
    IBEP20 _token;
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    constructor(IBEP20 token) {
        _bought_tokens = 0;
        _token = token;
    }
    
    receive() external payable {
        buyTokens(_msgSender());
    }
    
    function setRate(uint256 rate) public onlyOwner {
        _rate = rate;
    }
    
    function setBuyLimit(uint256 buy_limit) public onlyOwner {
        _buy_limit = buy_limit;
    }
    
    function setMinBuyAmount(uint256 min_buy_amount) public onlyOwner {
        _min_buy_amount = min_buy_amount;
    }
    
    function setBoughtTokens(uint256 bought_tokens) public onlyOwner {
        _bought_tokens = bought_tokens;
    }
    
    function getRate() public view returns(uint256) {
        return _rate;
    }
    
    function getBuyLimit() public view returns(uint256) {
        return _buy_limit;
    }
    
    function getBoughtTokens() public view returns(uint256) {
        return _bought_tokens;
    }
    
    function getMinBuyAmount() public view returns(uint256){
        return _min_buy_amount;
    }
    
    function buyTokens(address beneficiary) public payable {
        uint256 weiAmount = msg.value;
        
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(weiAmount != 0, "WeiAmount is 0");

        uint256 tokens = weiAmount.mul(_rate.div(1 ether));
    
        require(tokens >= _min_buy_amount, "You are trying to buy less than the minimum amount of tokens");        
        require(_bought_tokens.add(tokens) <= _buy_limit, "Buy limit is over");
        
        _token.transfer(beneficiary, tokens);
        _bought_tokens = _bought_tokens.add(tokens);
        
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        
        _forwardFunds(weiAmount);
    }
    
    function _forwardFunds(uint256 weiAmount) internal {
        //_token.transfer(msg.value);
    }
}