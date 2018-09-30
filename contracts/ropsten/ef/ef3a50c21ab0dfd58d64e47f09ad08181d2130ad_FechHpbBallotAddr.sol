pragma solidity ^0.4.24;

contract FechHpbBallotAddr {
    
    address public contractAddr;
    
    string public funStr;
    
    address public owner;
    
    //选择总共几轮的数据作为选举结果，默认值为6，就是7轮数据的累计得票数为选举结果
    uint public round = 6;
    
   /**
    * 只有管理员可以调用
   */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }
	
    function transferOwnership(address newOwner) onlyOwner  public{
        owner = newOwner;
    }
    
    event SetContractAddr(address indexed from,address indexed _contractAddr);
    
    event SetFunStr(address indexed from,string indexed _funStr);
    
    event SetRound(uint indexed _round);
    
    constructor() public{
       
    }
    
    function setContractAddr(
        address _contractAddr
    ) onlyOwner public{
        contractAddr=_contractAddr;
        emit SetContractAddr(msg.sender,_contractAddr);
    }
    
    //设置计算选举结果的截止轮数
   function setRound(uint _round) onlyOwner public{
        round=_round;
        emit SetRound(_round);
   }
   
   /**
     * 得到选举结果的截止轮数
      */
    function getRound(
    ) public constant returns(
        uint _round
    ){
        return round;
    }
    /**
     * 得到最获取智能合约地址
      */
    function getContractAddr(
    ) public constant returns(
        address _contractAddr
    ){
        return contractAddr;
    }
    
    function setFunStr(
        string _funStr
    ) onlyOwner public{
        funStr=_funStr;
        emit SetFunStr(msg.sender,_funStr);
    }
    
    /**
     * 得到最获取智能合约调用方法
      */
    function getFunStr(
    ) public constant returns(
        string _funStr
    ){
        return funStr;
    }
}