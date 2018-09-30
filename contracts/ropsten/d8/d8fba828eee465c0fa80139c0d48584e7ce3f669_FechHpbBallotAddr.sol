pragma solidity ^0.4.24;

contract FechHpbBallotAddr {
    
    address public contractAddr;
    
    string public funStr="0xc90189e4";
    
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
  
    mapping (address => address) public adminMap;
   
   
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
   
   
    function addAdmin(address addr) onlyOwner public{
        adminMap[addr] = addr;
    }
   
   
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
   
    event SetContractAddr(address indexed from,address indexed _contractAddr);
    
    event SetFunStr(address indexed from,string indexed _funStr);
    
    event SetRound(uint indexed _round);
    
    constructor() public{
       owner = msg.sender;
       //设置默认管理员
	   adminMap[owner]=owner;
    }
    
    function setContractAddr(
        address _contractAddr
    ) onlyAdmin public{
        contractAddr=_contractAddr;
        emit SetContractAddr(msg.sender,_contractAddr);
    }
    
    //设置计算选举结果的截止轮数
    function setRound(
        uint _round
    ) onlyAdmin public{
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
    ) onlyAdmin public{
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