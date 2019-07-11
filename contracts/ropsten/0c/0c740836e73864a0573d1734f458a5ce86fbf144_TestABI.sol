/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.25 ;

contract TestABI{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require (msg.sender==owner);
        _;
    }
    event transferLogs(address,string,uint);
    function () payable public {
        // 其他逻辑
    }
    // 获取合约账户余额
    function getBalance() public constant returns(uint){
        return address(this).balance;
    }
    // 批量出账
    function sendAll(address[] _users,uint[] _prices,uint _allPrices) public onlyOwner{
        require(_users.length>0);
        require(_prices.length>0);
        require(address(this).balance>=_allPrices);
        for(uint32 i =0;i<_users.length;i++){
            require(_users[i]!=address(0)&&_users[i]!=owner);
            require(_prices[i]>0);
          _users[i].transfer(_prices[i]);  
          emit transferLogs(_users[i],&#39;转账&#39;,_prices[i]);
        }
    }
    // 合约出账
    function sendTransfer(address _user,uint _price) public onlyOwner{
        require(_user!=owner);
        if(address(this).balance>=_price){
            _user.transfer(_price);
            emit transferLogs(_user,&#39;转账&#39;,_price);
        }
    }
    // 提币
    function getEth(uint _price) public onlyOwner{
        if(_price>0){
            if(address(this).balance>=_price){
                owner.transfer(_price);
            }
        }else{
           owner.transfer(address(this).balance); 
        }
    }
}