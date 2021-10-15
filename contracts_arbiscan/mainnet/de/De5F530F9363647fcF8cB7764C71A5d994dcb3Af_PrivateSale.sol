/**
 *Submitted for verification at arbiscan.io on 2021-10-14
*/

/*SPDX-License-Identifier: UNLICENSED*/
pragma solidity =0.7.6;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}
contract PrivateSale{
    address payable owner;
    address factory;
    address token;
    address weth;
    uint public immutable price;
    bool public locked;
    uint public timelock;
    mapping(address=>bool) whitlisted;
    mapping(address=>uint) paid;
    mapping(address=>uint) bought;
    mapping(address=>uint) remain;
    uint notSold;

    function buyPvt() external payable {
        require(whitlisted[msg.sender] || block.timestamp>=1634428800,"not whitlisted");
        require(notSold>=0,"can't buy that much");
        paid[msg.sender]+=msg.value;
        bought[msg.sender]+=msg.value*price;
        remain[msg.sender]+=msg.value*price;
        notSold-=msg.value*price;
    }
    
    function withdraw(uint amount) external {
        require(amount<=canWithdraw(msg.sender),"can't withdraw this amount");
        remain[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender,amount);
    }
    
    function canWithdraw(address sender) internal view returns (uint){
        if(locked && block.timestamp<=timelock+24 weeks){
            if(bought[sender]*75/100<=remain[sender]){
                return (remain[sender]-bought[sender]*75/100)+((bought[sender]*75/100)*(100*(timelock+block.timestamp)/(timelock+24 weeks))/100);
            } else {
                return ((bought[sender]*75/100)*(100*(timelock+block.timestamp)/(timelock+24 weeks))/100)-bought[sender]*75/100+remain[sender];
            }
        } else if (locked && block.timestamp>=timelock+24 weeks){
            return remain[sender];
        } else {
            return 0;
        }
    }
    
    function whitelist (address[] calldata user,bool access) external {
        require(msg.sender==owner);
        for (uint i; i < user.length; i++) {
            whitlisted[user[i]]=access;
        }
    }   
    
    function isWhitelisted() public view returns (bool){
        return whitlisted[msg.sender];
    }
    
    function getInfo(address who) public view returns (uint,uint,uint){
        return (bought[who], remain[who],canWithdraw(who));
    }

    function checkLiq() external{
        address pair = IUniswapV2Factory(factory).getPair(token,weth);
        require(pair!=address(0) && IERC20(token).balanceOf(pair)!=0,"liquidity not locked yet");
        locked=true;
        timelock=block.timestamp;
    }

    function withdrawETH(uint amount) external{
        require(msg.sender==owner && amount<=address(this).balance);
        owner.transfer(amount);
    }
    
    function withdrawNotSold(uint amount) external{
        require(msg.sender==owner && amount<=notSold);
        IERC20(token).transfer(owner,notSold);
    }
    
    constructor(uint _price,address _factory, address _token, address _weth){
        owner = msg.sender;
        price = _price;
        factory = _factory;
        token = _token;
        weth = _weth;
        notSold=200000000000000000000000000;
    }
    
    receive() external payable {
        
    }
}