/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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


contract sestraSwap {
    
    address public ownerAddress;
    IERC20 public sestrelToken; // 18 decimal
    IERC20 public usdtToken; // 6 decimal
    uint256 public sestraPrice;
    uint256 public sestrelDecimal = 1 ether;
    uint256 public usdtDecimal = 1000000;
    
    constructor(address _usdt, address _sestra, uint256 _sestraPrice) {
        
        ownerAddress = msg.sender;
        
        sestrelToken = IERC20(_sestra);
        usdtToken = IERC20(_usdt);
        sestraPrice = _sestraPrice;
    } 
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "only Owner");
        
        _;
    }
    
    function updateSestraPrice(uint256 _sestraPrice) external onlyOwner returns(bool) {
        sestraPrice = _sestraPrice;
        
        return true;
    }
    
    function updateSestrelToken(address _sestraToken) external onlyOwner returns(bool) {
        sestrelToken = IERC20(_sestraToken);
        
        return true;
    }
    
    function updateTetherToken(address _usdtToken) external onlyOwner returns(bool) {
        usdtToken = IERC20(_usdtToken);
        
        return true;
    }
    
    function adminDeposit(address _token, uint256 _amount) external onlyOwner returns(bool) {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        return true;
    }
    
    function failSafe(address _token, address _receiver, uint256 _amount) external onlyOwner returns(bool) {
        
        if(_token != address(0)) {
            
            IERC20(_token).transfer(_receiver, _amount);
            
            return true;
        }
        
        else {
            require(address(this).balance >= _amount, "Insufficient  Balance in Contract");
            
            bool  status = payable(_receiver).send(_amount);
            
            return status;
        }
    }
    
    function buySestrel(uint256 _usdt) external returns(bool) {
        
        usdtToken.transferFrom(msg.sender, address(this), _usdt);
        
        uint256 sestaToken = toSestrel(_usdt);
        sestrelToken.transfer(msg.sender, sestaToken);
        
        return true;
    }
    
    function sellSestrel(uint256 _sestrel) external returns(bool) {
        
        sestrelToken.transferFrom(msg.sender, address(this), _sestrel);
        uint256 usdt = toUSDT(_sestrel);
        
        usdtToken.transfer(msg.sender, usdt);
        
        return true;
    }
    
    function toUSDT(uint256 _sestrel) public view returns(uint256 _usdt) {
        
        uint256 usdt = ((_sestrel*sestraPrice)/sestrelDecimal);
        
        return (usdt);
    }
    
    function toSestrel(uint256 _usdt) public view returns(uint256 _sestrel) {
        
        uint256 sestrel = ((_usdt * sestrelDecimal)/sestraPrice);
        
        return sestrel;
    } 
    
}