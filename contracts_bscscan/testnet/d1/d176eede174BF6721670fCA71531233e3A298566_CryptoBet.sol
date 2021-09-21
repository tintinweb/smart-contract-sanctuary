/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity ^0.5.10;


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

    constructor() internal {
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
        
    struct Info {
        uint256 amount;
        uint256 id;
        uint256 Card_No;
        uint256 time;
        uint256 _card_Price;
    }
        constructor(IBEP20 _Token) public 
    {
        Token = _Token;
    }
    
    uint256[21] public card_probability= [1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,5,5,6];
    uint256 minimumBet = 100E18;
    uint256 meximumBet = 1000E18;

    mapping (address =>mapping(uint256 => Info)) public user;
    mapping (address => uint256) public number_of_deposit;
    
    event Withdraw(address  user, uint256 amount,uint256 time,uint256 card);    
    event BetAmount(address indexed user, uint256 amount, uint256 card,uint256 time);
     
     
     
     
    function Bet_Amount(uint256 amount) public {
        
        require(amount >= minimumBet, "minimumBet 100 ");
        require(amount <= meximumBet, "meximumBet 1000");
        
        number_of_deposit[msg.sender] += 1; 
        Info storage User = user[msg.sender][number_of_deposit[msg.sender]];
        uint256 card_No = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, card_probability.length))))%card_probability.length;
        Token.transferFrom(msg.sender,address(this), amount);
        User.id = card_No;
        User.amount = amount;
        User.time = uint(block.timestamp);        
        User.Card_No = card_probability[user[msg.sender][number_of_deposit[msg.sender]].id];

        
        if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 1){
            
            User._card_Price = amount*1/2;
        }
        else if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 2){
            
            User._card_Price = amount*1;
        }
        else if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 3){
            
            User._card_Price = amount*3/2;
        }
        else if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 4){
            
            User._card_Price = amount*2;
        }
        else if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 5){
            
            User._card_Price = amount*3;
        }
        else if(card_probability[user[msg.sender][number_of_deposit[msg.sender]].id] == 6){
            
            User._card_Price = amount*10;
        }
        
        emit BetAmount(msg.sender,amount,User.Card_No,uint40(block.timestamp));
    }

     function withdraw(uint256 deposit_id) public {
         
        require(user[msg.sender][deposit_id].amount != 0 , "not found"); 
        require(user[msg.sender][deposit_id].Card_No != 0 , "card not found");         
         
        Info storage User = user[msg.sender][deposit_id];
        Token.transfer(msg.sender,User._card_Price);
        
        emit Withdraw (msg.sender,User._card_Price,uint40(block.timestamp),User.Card_No);
        User.id = 0;
        User.amount = 0;
        User.time = 0;
        User.Card_No = 0;
        User._card_Price=0;

     }
     
         function emergencyWithdraw(uint256 SMSAmount) public onlyOwner {
         Token.transfer(msg.sender, SMSAmount);
    }
         function emergencyWithdrawBNB(uint256 Amount) public onlyOwner {
         msg.sender.transfer(Amount);
    }

    
}