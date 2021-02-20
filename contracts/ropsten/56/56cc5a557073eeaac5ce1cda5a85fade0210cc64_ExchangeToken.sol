pragma solidity ^0.6.12;

import "./Rescue.sol";


contract ExchangeToken {
    
    using SafeMath for uint256;
    
    
    RESCUE public Rescue;
    uint256 Prise = 5000000000000000;

    address payable owner = msg.sender;
    
   
    constructor(
    RESCUE _token
  )
     public
  {
    Rescue = _token;

  }
    mapping (address => User) users;
    
    struct User 
    {
        uint256 deposit_amount;
        uint256 deposit_time;
    }
    
    modifier onlyOwner(){
    require(msg.sender==owner);
    _;
    }
    
    function SellToken(uint256 tokenamount) public 
    {
         uint256 ab =  EtherToToken(tokenamount);
        require(address(this).balance >= ab);
        require(Rescue.balanceOf(msg.sender) >= tokenamount);
        
         Rescue.transferFrom(msg.sender,address(this),tokenamount);
         msg.sender.transfer(ab);
    }
    
    
    function BayToken(uint256 numberoftoken) external payable
    {
       uint256 abc =  EtherToToken(numberoftoken);
       require(msg.value >= abc); 
     require(Rescue.balanceOf(address(this)) >= numberoftoken);   
        Rescue.transfer(msg.sender,numberoftoken);
        
    }
    

    function TokenTransfer(uint256 _amount) public
    {
        require(Rescue.balanceOf(address(this)) >= _amount);
            Rescue.transfer(owner,_amount);
    }
    
    
    function EtherTransfer(uint256 _value) public 
    {
        require(address(this).balance >= _value);
            owner.transfer(_value);
    }
    
    
    function EtherToToken(uint256 __amount) public view returns (uint256)
    {
        uint256 reward = Prise.mul(__amount);
                return reward;
    }

    
    function UserInfo() public view returns(uint256 tokenofuser)
    {
        return (Rescue.balanceOf(msg.sender));
    }
    
    function contractbalance() public view returns(uint256 tokenofuser)
    {
        return (address(this).balance);
    }
    
    
    function contractInfo() public view onlyOwner returns(uint256 tokenofcontract)
    {
        return (Rescue.balanceOf(address(this)));
    }
    
  
}




library _SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}