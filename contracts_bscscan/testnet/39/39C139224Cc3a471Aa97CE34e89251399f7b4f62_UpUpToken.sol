//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import 'BEP20.sol';


contract UpUpToken is BEP20('UpUp Token', 'UPUP', 18) {
    
    using SafeMath for uint256;
    using Address for address;
    
    uint256 private immutable _tokensPerDay;
    uint private _lastDate;
    uint256 private _rate;
    
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    constructor(uint256 total, uint256 perday) {
        _mint(_msgSender(), total * (10 ** uint256(decimals())));
        _lastDate = block.timestamp;
        _tokensPerDay = perday * (10 ** uint256(decimals()));
    }
    
    receive() external payable {
        buyTokens(_msgSender());
    }
    
    function setRate(uint256 rate) public {
        _rate = rate;
    }
    
    function buyTokens(address beneficiary) public payable {
        uint256 weiAmount = msg.value;
        
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        
        uint256 tokens = weiAmount.mul(_rate);
        
        transfer(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        
        _forwardFunds();
    }

    function createTokens() public onlyOwner {
        require(block.timestamp > _lastDate && block.timestamp - _lastDate > 10 seconds, "Once per minute");
        uint256 tokens = (block.timestamp - _lastDate) * (_tokensPerDay / 1 days);
        require(tokens > 0, 'Empty earn');
        
        _mint(_msgSender(), tokens);
        _lastDate = block.timestamp;
    }
    
    function _forwardFunds() internal {
        //_wallet.transfer(msg.value);
    }
}