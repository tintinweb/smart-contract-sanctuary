/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity 0.5.16;

library SafeMath {

    function add(uint a, uint b) internal pure returns(uint) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface ERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function balanceOf(address account) external view returns(uint256);
  function allowance(address _owner, address _spender)external view returns(uint256);
}

contract Stacking{
    using SafeMath for uint256;
    
    
    address[] public tokenAddress;
    address public owner;
    ERC20 private rewardToken;
    ERC20 private token;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can access");
        _;
    }
    
    constructor(address _rewardToken) public{
        owner = msg.sender;
        rewardToken = ERC20(_rewardToken);
        
    }  
    uint public currentId =1;
    
    struct Person{
        address user;
        uint id;
        uint depositAmount;
        bool activeStatus;
        uint depositTime;
        uint typeId;
        uint tokenId;
    }
    
    
    
    mapping(address => bool)public tokenDetails;
    mapping(address => Person) public userDetails;
    
    
    
    event Deposit(address indexed user, uint _type, uint _tokenId, uint amount, uint _time);
    

      function addToken(address _addtoken) public onlyOwner{
      require(!tokenDetails[_addtoken], "Token address is not valid");
      
         tokenAddress.push(_addtoken);
      
        tokenDetails[_addtoken] =  true;
     }
    
    function deposit(uint _amount, uint _type, uint _tokenId) public payable{
        
       require(_type == 1 || _type == 2, "user has only two deposit types");
       require(userDetails[msg.sender].typeId == 0 || userDetails[msg.sender].typeId == _type, "User can deposit same type of deposit types");

       if(_type == 1){
           require(_tokenId == 0, " token index should be zero initially");
           require(msg.value > 0,"Invalid Amount");
           require(_amount == 0, "user can deposit either token or ether at a time");
           
           userDetails[msg.sender].user = msg.sender;
           userDetails[msg.sender].id = currentId;

           userDetails[msg.sender].depositAmount= userDetails[msg.sender].depositAmount.add(msg.value);
           userDetails[msg.sender].activeStatus = true;
           userDetails[msg.sender].depositTime = block.timestamp;
           userDetails[msg.sender].typeId = _type;
           userDetails[msg.sender].tokenId= _tokenId;
           currentId++;
           
         
           
           emit Deposit(msg.sender, _type , _tokenId, msg.value,block.timestamp);
           
       }
     
     else{
        
          require(msg.value == 0, "User can deposit either token or ether at a time");
          require(_tokenId< tokenAddress.length, "Token Id should be less than token address length");
          
          address tokenAddress = tokenAddress[_tokenId];
          require(tokenDetails[tokenAddress], "Active status is false");
          token = ERC20(tokenAddress);
          require(token.balanceOf(msg.sender) >= _amount, "Insufficient Amount");
     
          require(token.allowance(msg.sender,address(this)) >= _amount, "Amount is not approved yet");
          require(token.transferFrom(msg.sender,address(this),_amount),"Transferfrom failed");
 
          userDetails[msg.sender].user = msg.sender;
          userDetails[msg.sender].id = currentId;
          userDetails[msg.sender].activeStatus = true;
          userDetails[msg.sender].depositTime = block.timestamp;
          userDetails[msg.sender].typeId = _type;
          userDetails[msg.sender].depositAmount = userDetails[msg.sender].depositAmount.add(_amount);
          userDetails[msg.sender].tokenId = _tokenId;
          currentId++;
          
          
          emit Deposit(msg.sender, _type, _tokenId, msg.value, block.timestamp);
        
      }
    }

     function withdraw() public{
         
         require(userDetails[msg.sender].activeStatus, "User is not active");
         require(msg.sender != address(0), "Address is invalid");
         
          uint _type;
          uint reward;
          _type = userDetails[msg.sender].typeId;
          
          if(_type == 1){
            address(uint160(msg.sender)).send(userDetails[msg.sender].depositAmount);
            uint nod = block.timestamp.sub(userDetails[msg.sender].depositTime).div(1 days);
            if(nod >0  && nod <= 10){
                reward = userDetails[msg.sender].depositAmount.mul(50e18).div(100e18);
            }
            else if(nod > 10 && nod <= 20){
                reward = userDetails[msg.sender].depositAmount.mul(75e18).div(100e18);
                
            }
            else{
                reward = userDetails[msg.sender].depositAmount.mul(100e18).div(100e18);

            }
                      require(rewardToken.transfer(msg.sender, reward), "Transfer failed");

                 userDetails[msg.sender].depositAmount = 0;
                 userDetails[msg.sender].activeStatus = false;

         }
         
         else{
             uint _tokenId;
          _tokenId =  userDetails[msg.sender].tokenId;
          
          address tokenAddress = tokenAddress[_tokenId];
          require(tokenDetails[tokenAddress], "Active status is false");
          token = ERC20(tokenAddress);
          require(token.transfer(msg.sender, userDetails[msg.sender].depositAmount), "Transfer failed");
           uint _nod = block.timestamp.sub(userDetails[msg.sender].depositTime).div(1 days);
           if(_nod > 0 && _nod <= 10){
               reward = userDetails[msg.sender].depositAmount.mul(50e18).div(100e18);
           }
           else if(_nod > 10 && _nod <= 20){
               reward = userDetails[msg.sender].depositTime.mul(75e18).div(100e18);
           }
           else{
               reward = userDetails[msg.sender].depositAmount.mul(100e18).div(100e18);
           }
           
           require(rewardToken.transfer(msg.sender, reward), "Transfer failed");
          
          
               userDetails[msg.sender].depositAmount = 0;
               userDetails[msg.sender].activeStatus = false;
             
          
          
          
         }
         
        
         
     }



}