// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./AggregatorV3Interface.sol";

interface Oracle{
    function getPrice() external view returns(uint256);
}


contract buying is Context{
    using SafeMath for uint256;
    
    AggregatorV3Interface internal _priceETH;
    AggregatorV3Interface internal _priceLINK;
    
    address public _USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public _USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public _LINK=0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address public _ROTS;
    address payable public _admin;
    uint256 _balance=105e23;
    bool public _started;
    uint256 public _startTime;
    address public oracle;
    
    constructor(address _rotsAddress) public {
        _ROTS=_rotsAddress;
        _admin=msg.sender;
        _priceETH = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        _priceLINK = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }
    
    
    
    function remainingROTS() public view returns (uint256) {
        return _balance;
    }
    
    function getUSDPrice(uint256 _amount) public view returns(uint256){
        return _amount.mul(_price()).div(10e18);
    }
    
    function getLINKPrice(uint256 _amount) public view returns(uint256){
        return _amount.mul(_price()).mul(getLatestPrice(_priceLINK)).div(10e11);
    }
    
    function getETHPrice(uint256 _amount) public view returns(uint256){
        return _amount.mul(_price()).mul(getLatestPrice(_priceETH)).div(10e11);
    }
    
    
    function setOracle(address _oracle) public virtual returns (bool){
        require(_msgSender()==_admin,"You don't have permissions to perfrom the selected task.");
        oracle=_oracle;
    }
    
    function start() public virtual returns (bool){
        require(_msgSender()==_admin,"You don't have permissions to perfrom the selected task.");
        require(_started==false,"Already started.");
        _started=true;
        _startTime=now;
    }
     
    function buyUSDT(uint256 _amount) public virtual returns(bool){
        require(_started==true,"Buying not yet started.");
        uint256 _rotsAmount=_amount.mul(_price()).div(10e18);
        _buy(_USDT,_amount,_rotsAmount);
        return true;
    }
    
    function buyUSDC(uint256 _amount) public virtual returns(bool){
        require(_started==true,"Buying not yet started.");
        uint256 _rotsAmount=_amount.mul(_price()).div(10e18);
        _buy(_USDC,_amount,_rotsAmount);
        return true;
    }
    
    function buyLINK(uint256 _amount) public virtual returns(bool){
        require(_started==true,"Buying not yet started.");
        uint256 _rotsAmount=_amount.mul(_price()).mul(getLatestPrice(_priceLINK)).div(10e11);
        _buy(_LINK,_amount,_rotsAmount);
        return true;
    }
    
    function buyETH() public payable returns(bool){
        require(_started==true,"Buying not yet started.");
        uint256 _amount=msg.value;
        _admin.transfer(_amount);
        uint256 _rotsAmount=_amount.mul(_price()).mul(getLatestPrice(_priceETH)).div(10e11);
        require(_rotsAmount<=_balance,"Not enough ROTS in contract.");
        IERC20(_ROTS).transfer(_msgSender(),_rotsAmount);
        _balance=_balance.sub(_rotsAmount);
        return true;
        
    }
    
    function _buy(address _tokenAddress,uint256 _amount,uint256 _rotsAmount) internal virtual{
        IERC20(_tokenAddress).transferFrom(_msgSender(),_admin,_amount);
        require(_rotsAmount<=_balance,"Not enough ROTS in contract.");
        IERC20(_ROTS).transfer(_msgSender(),_rotsAmount);
        _balance=_balance.sub(_rotsAmount);
    }
    
    function _price() public view returns(uint256){
        uint256 price_;
        if (oracle!=address(0)){
            price_=Oracle(oracle).getPrice();
        }
        else {
            price_=1e19;
        }
        
        
        return price_;
    }
    
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }
}