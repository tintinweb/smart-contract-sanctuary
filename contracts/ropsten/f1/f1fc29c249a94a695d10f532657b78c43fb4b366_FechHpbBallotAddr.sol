pragma solidity ^0.4.24;

contract FechHpbBallotAddr {
    
    address public contractAddr;
    
    string public funStr;
    
    address public owner;
    
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
    
    event Constructor(address indexed from,address indexed _contractAddr,string indexed _funStr);
    
    constructor(address _contractAddr,string _funStr) public{
        contractAddr=_contractAddr;
        funStr=_funStr;
        owner = msg.sender;
        emit Constructor(msg.sender,_contractAddr,_funStr);
    }
    
    function setContractAddr(
        address _contractAddr
    ) onlyOwner public{
        contractAddr=_contractAddr;
        emit SetContractAddr(msg.sender,_contractAddr);
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