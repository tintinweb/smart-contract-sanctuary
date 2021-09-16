/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

pragma solidity ^0.5.10;

interface IWYZTOKEN {
function totalSupply() external view returns(uint256);
function balanceOf(address owner) external view returns(uint256);
function transfer(address reciever, uint256 amount) external returns(bool);
function transferFrom(address from, address to,uint amount) external returns (bool);
function mint(uint256 _qty) external returns(uint256);
function burn(uint256 _quty) external returns(uint256);
function allowance(address _owner,address _spender) external view returns(uint256 remaining);
function approve(address _spender, uint256 amount) external returns(bool success);
}


contract stacking {
IWYZTOKEN public token;

constructor(IWYZTOKEN _token) public{
   token=_token;
}

    struct user { 
        uint depositeTime;
        uint amount;
        uint reward;
        
    }
    
    mapping (address => user ) public User ;
    

    function deposit (uint _amount ) public payable{
    token.transferFrom(msg.sender,address(this),_amount);
      User[msg.sender].amount = _amount; 
      User[msg.sender].depositeTime= block.timestamp; 
        }
        
    function ShowReward (address _tokenHolder) public view returns(uint){
    
    uint256 s = now - User[_tokenHolder].depositeTime;
      return s;
    }
    
    function withdraw() public{
    require(User[msg.sender].amount>0,"0 Deposite");
     uint256 a = ShowReward(msg.sender);
     uint256 b = a -User[msg.sender].reward;
        token.transfer(msg.sender, b);
        User[msg.sender].reward +=b;
    }
    
    function Unstakeing() public{
    require(User[msg.sender].amount>0,"0 Deposite");    
        
    token.transfer(msg.sender,User[msg.sender].amount);
     User[msg.sender].amount=0;
     User[msg.sender].depositeTime=0;
        
    }
    
}