/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

contract CryptoBet  is Ownable{
    
    using SafeMath for uint256;
    IBEP20 public Token;
        

        constructor(IBEP20 _Token)  
    {
        Token = _Token;
        cardPrice[1]=500000000000000000;
        cardPrice[2]=1000000000000000000;
        cardPrice[3]=1500000000000000000;
        cardPrice[4]=2000000000000000000;
        cardPrice[5]=5000000000000000000;
    }

        struct User 
    {
        address payable upline;
        uint256 referrals;
        uint256 deposit_time;
        uint256 total_deposits;
    }
    
    uint256 [100] card_probability= [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,5,5];
    

    uint256 minimumBet = 100000E18;
    uint256 total_users;
    uint256 BNB_Amount = 1900000000000000;

    mapping (address => uint256 []) public amount;
    mapping (address => uint256 []) public Card_No;
    mapping (address => uint256 []) public _card_Price;
    mapping (uint256 => uint256 ) public cardPrice;
    mapping(address => User) public users;
    event Withdraw(address  user, uint256 amount,uint256 time);    
    event BetAmount(address indexed user, uint256 amount, uint256 card,uint256 time);
     


         function _setUpline(address _addr, address payable _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != _owner && (users[_upline].deposit_time > 0 || _upline == _owner))
        {
            users[_addr].upline = _upline;
            users[_upline].referrals+
            total_users++;
        }
    }



      function _chakUpline( address _upline , address add) public view returns(bool result){
        if(users[add].upline == address(0) && _upline != add && add != _owner && (users[_upline].deposit_time > 0 || _upline == _owner)) {
            return true;  

        }
    }



     
     
     
    function Bet_Amount(uint256 _amount,address payable _upline) external payable
    {
        
        require(_amount >= minimumBet, "minimumBet 1");
        require(BNB_Amount == msg.value, "enter bnb amount");

        _setUpline(msg.sender,_upline);
        uint256 cardprice; 
        uint256 card_No = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, card_probability.length))))%card_probability.length;
        
        Token.transferFrom(msg.sender,address(this), _amount);
        Token.transfer(_upline, minimumBet);
        
        if(card_probability[card_No] == 1){
            
            cardprice = (_amount*cardPrice[1])/1E18;
        }
        else if(card_probability[card_No] == 2){
            
            cardprice= (_amount*cardPrice[2])/1E18;
        }
        else if(card_probability[card_No] == 3){
            
            cardprice = (_amount*cardPrice[3])/1E18;
        }
        else if(card_probability[card_No] == 4){
            
            cardprice = (_amount*cardPrice[4])/1E18;
        }
        else if(card_probability[card_No] == 5){
            
            cardprice = (_amount*cardPrice[5])/1E18;
        }
        

        amount[msg.sender].push(_amount);
        Card_No[msg.sender].push(card_probability[card_No]);
        _card_Price[msg.sender].push(cardprice);
        users[msg.sender].deposit_time = block.timestamp;
        
        emit BetAmount(msg.sender,_amount,card_probability[card_No],uint40(block.timestamp));
    }

    
    function withdraw(uint256[] memory _index) public {
        
        uint256 TotalAmount;
   for (uint256 z; z < _index.length; z++) {   
       
    TotalAmount +=_card_Price[msg.sender][_index[z]];
   }
   
      for (uint256 z; z < _index.length; z++) { 
    for(uint i = _index[z]; i <  amount[msg.sender].length - 1; i++) {
      amount[msg.sender][i] = amount[msg.sender][i + 1];
      Card_No[msg.sender][i] = Card_No[msg.sender][i + 1];
      _card_Price[msg.sender][i] = _card_Price[msg.sender][i + 1];
    }
     
    amount[msg.sender].pop();
    Card_No[msg.sender].pop();
    _card_Price[msg.sender].pop();
  }
  
    Token.transfer(msg.sender,TotalAmount);  
  emit Withdraw(msg.sender,TotalAmount,block.timestamp);
    }
  
    
         function UserInfo (address _add) public view returns (uint256[] memory usersAmount,uint256[] memory usersCardNo,uint256[] memory usersCardPrice)
    {
        uint lengthAmount = amount[_add].length;
        uint lengthCardNo = Card_No[_add].length;   
        uint lengthCardPrice = _card_Price[_add].length;
        
        usersAmount = new uint256[](lengthAmount);
        usersCardNo = new uint256[](lengthCardNo);
        usersCardPrice = new uint256[](lengthCardPrice);        
        
        for(uint i = 0; i < lengthAmount; i++)
        {
            usersAmount[i] = amount[_add][i];
            usersCardNo[i] = Card_No[_add][i];
            usersCardPrice[i] = _card_Price[_add][i];
        }   
    }
    
    


         function emergencyWithdraw(uint256 Amount) public onlyOwner 
    {
           Token.transfer(msg.sender, Amount);
    }
         function emergencyWithdrawBNB(uint256 Amount) public onlyOwner 
    {
            payable(msg.sender).transfer(Amount);
    }
         function SetPercentage(uint256 _percentage) public onlyOwner 
    {
            BNB_Amount=_percentage;
    }
    

             function Set_Minimum_Percentage(uint256 _percentage) public onlyOwner 
    {
            minimumBet=_percentage;
    }


             function Set_Reward_Percentage(uint256 id,uint256 _percentage) public onlyOwner 
    {
            cardPrice[id]=_percentage;
    }
    

    

    
}