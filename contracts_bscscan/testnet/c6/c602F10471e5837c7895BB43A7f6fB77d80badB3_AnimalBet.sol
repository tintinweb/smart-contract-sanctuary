/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IBEP20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

}


contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract AnimalBet  is Ownable{
    
    using SafeMath for uint256;
    IBEP20 public Token;
        

        constructor(IBEP20 _Token)  
    {
        Token = _Token;
        cardPrice[1]=35;
        cardPrice[2]=35;
        cardPrice[3]=35;
        cardPrice[4]=35;
        cardPrice[5]=35;
        cardPrice[6]=35;
        cardPrice[7]=55;
        cardPrice[8]=125;
        cardPrice[9]=115;
        cardPrice[10]=165;
        cardPrice[11]=200;
        cardPrice[12]=75;
        cardPrice[13]=200;
        cardPrice[14]=200;
        cardPrice[15]=200;
        cardPrice[16]=145;
        cardPrice[17]=35;
        cardPrice[18]=100;
        cardPrice[19]=85;
        cardPrice[20]=300;
    }
    struct UserInfo {
        uint256 amount;
        uint256 Card_No;
        uint256 random_Card;
        uint256 Food_card;
        uint256 random_food_card;
        bool status;
        bool special ;
        uint256 notspecial ;
        string winingStatus;
        bool _stop;
    }
    
    struct userinfo{
        uint256 userfoodAmount;
        uint256 gamefoodAmount;
    }
    
    uint256 [6] Animal_card= [1,2,3,4,5,6];
    uint256 [100] food_card= [1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,14,15,15,15,15,16,16,16,16,17,17,17,17,18,18,18,18,19,19,19,19,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20];    
    

    uint256 minimumBet = 500E18;
    uint256 winingAmount = 1000E18;

    mapping (address => UserInfo ) public User;
    mapping (address => userinfo ) public userAmount;
    mapping (uint256 => uint256 ) public cardPrice;
    
    event Withdraw(address  user, uint256 amount,uint256 time);    
    event BetAmount(address indexed user, uint256 amount, uint256 card,uint256 time);
     
     
     function register() public {
         
         Token.transferFrom(msg.sender,address(this), 500E18);
         User[msg.sender].amount = 500E18 ;
     }
     
    function GetAnimal() public 
    {
        
        require(User[msg.sender].amount > 0, "minimumBet 500 ");
        require(User[msg.sender].status  == false, "you Got Animal");
        
        uint256 card_No1 = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, Animal_card.length))))%Animal_card.length;
        uint256 card_No2 = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.timestamp ,Animal_card.length))))%Animal_card.length;
        
        User[msg.sender].Card_No = card_No1;
        User[msg.sender].random_Card=card_No2;
        User[msg.sender].status = true;
        
        emit BetAmount(msg.sender,500E18,card_No1,uint40(block.timestamp));
    }
    
    function Get_food() public {
        
        require(User[msg.sender].status  == true, "please Get Animal");
        require( !User[msg.sender].special && User[msg.sender].notspecial < 3, "please use special card");
        if(userAmount[msg.sender].userfoodAmount  < 500 && userAmount[msg.sender].gamefoodAmount  < 500){
        
        uint256 card_No1 = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.timestamp, food_card.length))))%food_card.length;
        uint256 card_No2 = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp ,food_card.length))))%food_card.length;
        
        if(User[msg.sender].Card_No == 0 && food_card[card_No1] == 0)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 1 && food_card[card_No1] == 1)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 2 && food_card[card_No1] == 2)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 3 && food_card[card_No1] == 3)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 4 && food_card[card_No1] == 4)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 5 && food_card[card_No1] == 5)
        {
            User[msg.sender].special =true;
        }
        else if(User[msg.sender].Card_No == 6 && food_card[card_No1] == 6)
        {
            User[msg.sender].special =true;
        }
        else if( food_card[card_No1] == 20)
        {
            userAmount[msg.sender].userfoodAmount += cardPrice[20];
        }
        else if (food_card[card_No1] == 0 || food_card[card_No1] == 1 || food_card[card_No1] ==2 || food_card[card_No1] == 3|| food_card[card_No1] == 4|| food_card[card_No1] ==5){
              User[msg.sender].notspecial+=1; 
        }
        else{
            userAmount[msg.sender].userfoodAmount += cardPrice[food_card[card_No1]];
        }
        
        userAmount[msg.sender].gamefoodAmount += cardPrice[food_card[card_No2]];
        }
        
        
        
        else if(userAmount[msg.sender].userfoodAmount  < 500 && userAmount[msg.sender].gamefoodAmount  > 500) {
              User[msg.sender].winingStatus = " you win";
              Token.transfer(msg.sender, winingAmount);
            userAmount[msg.sender].userfoodAmount = 0;
            userAmount[msg.sender].gamefoodAmount = 0 ;
            User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;
        }
         else if(userAmount[msg.sender].userfoodAmount  == 500 && userAmount[msg.sender].gamefoodAmount  > 500 ) {
              User[msg.sender].winingStatus = "you win1";
              Token.transfer(msg.sender, winingAmount);
            userAmount[msg.sender].userfoodAmount = 0;
            userAmount[msg.sender].gamefoodAmount = 0 ;
            User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;            
        }
         else if(userAmount[msg.sender].userfoodAmount  > 500 && userAmount[msg.sender].gamefoodAmount  <= 500 ) {
              User[msg.sender].winingStatus = "lose loss";
             userAmount[msg.sender].userfoodAmount = 0;
             userAmount[msg.sender].gamefoodAmount = 0 ;
             User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;              
        }
        else if(userAmount[msg.sender].userfoodAmount  < 500 && userAmount[msg.sender].gamefoodAmount  == 500 ) {
              User[msg.sender].winingStatus = "you loss";
             userAmount[msg.sender].userfoodAmount = 0;
             userAmount[msg.sender].gamefoodAmount = 0 ;
             User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;              
        }
        else  if(userAmount[msg.sender].userfoodAmount  > 500 && userAmount[msg.sender].gamefoodAmount  > 500 ) {
            
             if(userAmount[msg.sender].userfoodAmount < userAmount[msg.sender].gamefoodAmount)
              {
              User[msg.sender].winingStatus = "you win";
              Token.transfer(msg.sender, winingAmount);
             userAmount[msg.sender].userfoodAmount = 0;
             userAmount[msg.sender].gamefoodAmount = 0 ;
             User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;            
              }
              else
              {
                  User[msg.sender].winingStatus = "you loss";
                userAmount[msg.sender].userfoodAmount = 0;
                userAmount[msg.sender].gamefoodAmount = 0 ;
                User[msg.sender].special=false;
                User[msg.sender].notspecial = 0;
                User[msg.sender].status = false;
                User[msg.sender].amount=0;              
              }
        }
         
    }
    
    
    
    function chooseCard(uint256 _card) public 
    {
        require(User[msg.sender].special || User[msg.sender].notspecial == 3, "you have not any special card");
        userAmount[msg.sender].userfoodAmount += cardPrice[_card];
        User[msg.sender].special=false;
        User[msg.sender].notspecial == 0;
    }
    
    
    
        function stop() public 
    {
        require(User[msg.sender].status  == true, "please Get Animal");
        User[msg.sender]._stop = true;
    
              if(userAmount[msg.sender].userfoodAmount > userAmount[msg.sender].gamefoodAmount)
              {
              User[msg.sender].winingStatus = "you win";
              Token.transfer(msg.sender, winingAmount);
            userAmount[msg.sender].userfoodAmount = 0;
            userAmount[msg.sender].gamefoodAmount = 0 ;
            User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;            
              }
              else
              {
                  User[msg.sender].winingStatus = "you loss";
            userAmount[msg.sender].userfoodAmount = 0;
            userAmount[msg.sender].gamefoodAmount = 0 ;
            User[msg.sender].special=false;
             User[msg.sender].notspecial = 0;
             User[msg.sender].status = false;
             User[msg.sender].amount=0;                  
              }
        
    }
        
    
    
         function emergencyWithdraw(uint256 SMSAmount) public onlyOwner 
    {
         Token.transfer(msg.sender, SMSAmount);
    }
         function emergencyWithdrawBNB(uint256 Amount) public onlyOwner 
    {
         payable(msg.sender).transfer(Amount);
    }
             function SetPercentage(uint256 _id,uint256 _percentage) public onlyOwner 
    {
        cardPrice[_id]=_percentage;
    }

    
}