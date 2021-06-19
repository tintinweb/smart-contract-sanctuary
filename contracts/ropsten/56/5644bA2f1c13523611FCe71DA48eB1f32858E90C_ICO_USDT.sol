pragma solidity ^0.4.23;
import './owned.sol';
import './safemath.sol';


contract token{
    function transfer(address _to,uint256 amount) external;
    function transferFrom(address _from,address _to,uint256 _value) external;
}

contract ICO_USDT is owned{
    
    using SafeMath for uint;
    //众筹目标
    uint fundingGool;
    //众筹时间分钟为单位，截止日期
    uint deadline;
    //众筹的价格.
    uint price;
    //募集总额
    uint public fundAmount;
    token public tokenReward;
    token public usdtToken;
    
    //合约受益人
    address public beneficiary;
    //记录每一个人打入的usdt
    mapping(address => uint) public balanceOf;
    //发送一个事件保存每次的募捐
    event FundTransfer(address backer,uint amount);
    //发送一个事件判断是否完成募资
    event GoodReached(bool success);
    //0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99
    constructor (uint fundingGoolInUSDTDecimal,uint durationInMinutes, uint usdtDecimalCostofToken,address addressOfToken,address addressOfUSDT) {
        deadline = now + durationInMinutes * 1 minutes;
        price = usdtDecimalCostofToken ;
        //强制类型转换为合约类型
        tokenReward = token(addressOfToken);
        usdtToken = token(addressOfUSDT);
        fundingGool = fundingGoolInUSDTDecimal  ;
        beneficiary = msg.sender;
    }
    //指定阶梯价格 1个Token（）
    function setPrice(uint usdtDecimalCostofToken) public onlyowner{
        price = usdtDecimalCostofToken ;
    }
    
    function getPrice() public view returns (uint){
        return price ;
    }
    
    //回退函数（没有函数名）不接受ETH转账
    function() public {
    }
    
    //募集完成提款USDT
    function withdrawal() public{
        
        require(now >= deadline);
        
        if(fundAmount >= fundingGool){
            //受益人本人才能提款
            if(beneficiary == msg.sender){
                usdtToken.transfer(beneficiary,fundAmount) ;
            }
            
        }else{
            if(balanceOf[msg.sender] > 0){
                balanceOf[msg.sender] = 0;
                usdtToken.transfer(beneficiary,balanceOf[msg.sender]) ;
            }
        }
        
    }
    
    function usdtSwap(uint _usdtDecimalAmount) public{
        //判断众筹时间
        require(now < deadline);
        usdtToken.transferFrom(msg.sender,address(this),_usdtDecimalAmount);
        balanceOf[msg.sender] += _usdtDecimalAmount;
        fundAmount += _usdtDecimalAmount;
        //发送给用户的token数量 
        uint256 tokenAmount = _usdtDecimalAmount / price * (10 ** 18 )  ;
        tokenReward.transfer(msg.sender,tokenAmount);
        emit FundTransfer(msg.sender,_usdtDecimalAmount);
    }
    
    
    
    //定义一个募资是否完成的方法
    function checkGoodReached()  view returns(bool) {
        require(now >= deadline);
        if(fundAmount >= fundingGool){
            return true;
        }
        return false;
    }
}