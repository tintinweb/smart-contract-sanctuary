pragma solidity ^0.4.16;
//创建一个基础合约，有些操作只能是当前合约的创建者才能操作
contract owned{
    //声明一个用来接收合约创建者的状态变量
    address public owner;
    //构造函数，把当前交易的发送者（合约的创建者）赋予owner变量
    function owned(){
        owner=msg.sender;
    }
    //声明一个修改器，用于有些方法只有合约的创建者才能操作
    modifier onlyOwner{
        if(msg.sender != owner){
            revert();
        }else{
            _;
        }
    }
    //把该合约的拥有者转移给其他人
    function transferOwner(address newOwner) onlyOwner {
        owner=newOwner;
    }
}


contract tokenDemo is owned{
    string public name;//代币名字
    string public symbol;//代币符号
    uint8 public decimals=18;//代币小数位
    uint public totalSupply;//代币总量
    
    uint public sellPrice=0.01 ether;//卖价，持有的人卖给智能合约持有者
    uint public buyPrice=0.01 ether;//买价，向持有人买代币
    
    //用一个映射类型的变量，来记录所有帐户的代币的余额
    mapping(address => uint) public balanceOf;
    //用一个映射类型的变量，来记录被冻结的帐户
    mapping(address => bool) public frozenAccount;
    
    
    //构造函数，初始化代币的变量和初始化总量
    function tokenDemo(
        uint initialSupply,
        string _name,
        string _symbol,
        address centralMinter
        ) payable {
        //手动指定代币的的拥有者，如果不填，则默认为合约的部署者
        if(centralMinter !=0){
            owner=centralMinter;
        }
        
        totalSupply=initialSupply * 10 ** uint256(decimals);
        balanceOf[owner]=totalSupply;
        name=_name;
        symbol=_symbol;
    }
    
    function rename(string newTokenName,string newSymbolName) public onlyOwner
    {
        name = newTokenName;
        symbol = newSymbolName;
    }
    
    //发行代币，向指定的目标帐户添加代币
    function mintToken(address target,uint mintedAmount) onlyOwner{
        //判断目标帐户是否存在
        if(target !=0){
            //目标帐户增加相应的的代币
            balanceOf[target] += mintedAmount;
            //增加总量
            totalSupply +=mintedAmount;
        }else{
            revert();
        }
    }
    
    //实现帐户的冻结和解冻
    function freezeAccount(address target,bool _bool) onlyOwner{
        if(target != 0){
            frozenAccount[target]=_bool;
        }
    }
        
    function transfer(address _to,uint _value){
        //检测交易的发起者的帐户是不是被冻结了
        if(frozenAccount[msg.sender]){
            revert();
        }
        //检测交易发起者的帐户代币余额是否足够
        if(balanceOf[msg.sender]<_value){
            revert();
        }
        //检测溢出
        if((balanceOf[_to]+_value)<balanceOf[_to]){
            revert();
        }
        //实现代币转移
        balanceOf[msg.sender] -=_value;
        balanceOf[_to] +=_value;
    }
    
    
    //设置代币的买卖价格    
    function setPrice(uint newSellPrice,uint newBuyPrice)onlyOwner{
        sellPrice=newSellPrice;
        buyPrice=newBuyPrice;
    }   
    
    
    //持有代币的用户卖代币给合约的拥有者，以获得以太币
    function sell(uint amount) returns(uint revenue){
        //检测交易的发起者的帐户是不是被冻结
        if(frozenAccount[msg.sender]){
            revert();
        }
        //检测交易发起者的帐户的代币余额是否够用
        if(balanceOf[msg.sender]<amount){
            revert();
        }
        //把相应数量的代币给合约的拥有者
        balanceOf[owner] +=amount;
        //卖家的帐户减去相应的余额
        balanceOf[msg.sender] -=amount;
        //计算对应的以太币的价值 
        revenue=amount*sellPrice;
        //向卖家的的帐户发送对应数量的以太币
        if(msg.sender.send(revenue)){
            return revenue;
            
        }else{
            //如果以太币发送失败，则终止程序，并且恢复状态变量
            revert();
        }
    }
    
    
    //向合约的拥有者购买代币
    function buy() payable returns(uint amount){
        //检测买价是不是大于0
        if(buyPrice<=0){
            //如果不是，则终止
            revert();
        }
        //根据用户发送的以太币的数量和代币的买价，计算出代币的数量
        amount=msg.value/buyPrice;
        //检测合约拥有者是否有足够多的代币
        if(balanceOf[owner]<amount){
            revert();
        }
        //向合约的拥有者转移以太币
        if(!owner.send(msg.value)){
            //如果失败，则终止
            revert();
        }
        //合约拥有者的帐户减去相应的代币
        balanceOf[owner] -=amount;
        //买家的帐户增加相应的代币
        balanceOf[msg.sender] +=amount;
        
        return amount;
    }
    
    
}