/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}



contract Exchange{
    
    address public oldtoken = 0x74faaB6986560fD1140508e4266D8a7b87274Ffd;
    address public newtoken = 0x3A41Eca14EcC96dc9dA6E98Ba2BF19ACc5A84e51;
    address public owner;
    uint[] public rate  = [1e18,1e18];//old / new
    uint public poudage;
    event Swap(address _user, uint _amount);
    
    modifier onlyOwner{
        require(msg.sender == owner, "only owner");
        _;
    }
    
    function transferOwnership(address _newowner)public onlyOwner{
        owner = _newowner;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function setTokens(address _old, address _new)public onlyOwner{
        oldtoken = _old;
        newtoken = _new;
    }
    
    function setRate(uint[] memory rate_) public onlyOwner{
        require(rate_.length == 2,'wrong length');
        rate = rate_;
    }
    
    function setPoudage(uint poudage_) public onlyOwner{
        poudage = poudage_;
    }
    
    
    function newToOld(uint amount_) public{
        require(IERC20(newtoken).balanceOf(msg.sender) >= amount_,"insufficient new tokens");
        require(IERC20(oldtoken).balanceOf(address(this))>=amount_,"insufficient old tokens");
        uint outAmount = amount_ * 1e18  / rate[1]  *  rate[0] / 1e18;
        uint afterAmount = outAmount *(10000 - poudage) / 10000;
        IERC20(newtoken).transferFrom(msg.sender, address(this), amount_);
        IERC20(oldtoken).transfer(msg.sender, afterAmount);
        
        emit Swap(msg.sender, amount_);
    }
    
    function oldToNew(uint amount_) public{
        require(IERC20(oldtoken).balanceOf(msg.sender) >= amount_,"insufficient old tokens");
        require(IERC20(newtoken).balanceOf(address(this))>=amount_,"insufficient new tokens");
        uint outAmount = amount_ * 1e18  / rate[0]  *  rate[1] / 1e18;
        uint afterAmount = outAmount *(10000 - poudage) / 10000;
        IERC20(oldtoken).transferFrom(msg.sender, address(this), amount_);
        IERC20(newtoken).transfer(msg.sender, afterAmount);
        
        emit Swap(msg.sender, amount_);
    }
    
    
    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }
    
    
    
}