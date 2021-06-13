/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity >=0.6.0 ;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface token{
    function transfer(address _to,uint256 _value) external;
}

contract ICOForERC20{
    uint256 public _goal;
    uint256 public _currentAmount;
    uint256 public _deadLine;
    uint256 public _ratio; 
    token public myToken;
    address payable beneficiary;
    bool public exchangeFlag = true;
    
    using SafeMath for uint256;
    
    
    //address=>Num of eth
    mapping(address=>uint256) public balances;
    address[] public funders;
    
    event Success(string);
    event ETHReceived(address,uint256);
    event TokenTransfer(uint256);
    
    constructor(uint256 goal,uint256 ratio,uint256 deadLine,
                address addressOfToken) public{
         _goal = goal * 10*18;
         _ratio = ratio;
         _deadLine = deadLine;
         beneficiary = msg.sender;
         myToken = token(addressOfToken);
    }
    
    receive() external payable{
        require(msg.value>0);
        require(now<_deadLine);
        if(exchangeFlag){
            if(_currentAmount<_goal){
                if(balances[msg.sender]==0){
                    funders.push(msg.sender);
                }
                uint256 eth = msg.value;
                balances[msg.sender] = balances[msg.sender].add(eth);
                _currentAmount = _currentAmount.add(eth);
                emit ETHReceived(msg.sender,msg.value);
                if(_currentAmount>=_goal){
                    exchangeFlag = false;
                    emit Success("Success");
                    successHandler();
                  
                    kill();
                }
            }
        }
    }
    
       function refund(uint256 value) public{
        require(exchangeFlag);
        require(value>0);
        uint256 balance = balances[msg.sender];
        require(value<=balance);
        msg.sender.transfer(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        _currentAmount.sub(value);
    }
    
    modifier onlyBeneficiary(){
        require(
            msg.sender == beneficiary
        );
        _;
    }
    
       function refundAll() public onlyBeneficiary{
        uint256 len = funders.length;
        for(uint256 i=0;i<len;i++){
            uint256 eth = balances[funders[i]];
            msg.sender.transfer(eth);
            balances[funders[i]] = 0;
        }
        kill();
    }
    
       function successHandler() private{
        uint256 len = funders.length;
        for(uint256 i=0;i<len;i++){
            uint256 tokenNum = balances[funders[i]].mul(_ratio);
            emit TokenTransfer(tokenNum);
            myToken.transfer(msg.sender,tokenNum);
            balances[funders[i]] = 0;
        }
    }
    
    function kill() private {
        selfdestruct(beneficiary);
    }
    
}