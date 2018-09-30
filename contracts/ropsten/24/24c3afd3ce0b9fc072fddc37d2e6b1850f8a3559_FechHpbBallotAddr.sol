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
    
    constructor() public{
        owner = msg.sender;
    }
    
    function setContractAddr(
        address _contractAddr
    ) onlyOwner public{
        contractAddr=_contractAddr;
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