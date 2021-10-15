/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity ^0.5.10;


interface IERC20 {
    
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






    contract stake  is Ownable{
    
        using SafeMath for uint256;
         IERC20 public Token;
        

        constructor(IERC20 _Token) public 
    {
    
        Token = _Token;
    }
        
        
        mapping(address => uint256) public id; 
        mapping(address=>uint256[]) public amount;
        mapping(address =>uint256[]) public depositeTime;
        mapping(address=>uint256) public reward;
        mapping(address=>uint256) public User;

        address[] public user;
        bool ApprovalByAdmin;
        uint256 Time = 1 minutes;
        uint256 public percentage=5E18;
        uint256 public totalDepositeToken;
        
    function setPercentage(uint256 _percentage) public onlyOwner{
    percentage=_percentage;    
        
    }
   
    function deposite(uint256 _amount) public
        {
            if(0==User[msg.sender]){
                User[msg.sender]=1;
                user.push(msg.sender);
                
            }
        require(!ApprovalByAdmin);
       Token.transferFrom(msg.sender, address(this), _amount);
       amount[msg.sender].push(_amount);
       depositeTime[msg.sender].push(uint40(block.timestamp));
       totalDepositeToken+=_amount;
        }
    
   
    function withdraw() public
        {
         require(!ApprovalByAdmin);
         uint256 amountReward;     
         for (uint256 z; z < depositeTime[msg.sender].length; z++) {
         if((now-depositeTime[msg.sender][z])>Time){    
         amountReward=((amount[msg.sender][z]*percentage/100))/1E18;
         reward[msg.sender]+= amountReward+amount[msg.sender][z];
         
    
        for(uint i = z; i <  amount[msg.sender].length - 1; i++)
         {
          amount[msg.sender][i] = amount[msg.sender][i + 1];
          depositeTime[msg.sender][i] = depositeTime[msg.sender][i + 1];
         }
         amount[msg.sender].pop();
         depositeTime[msg.sender].pop();
        }
         }
         
         
         }
    
        function Check_Reward(address _address) public view returns(uint256)
        {
         require(!ApprovalByAdmin);
         uint256 amountReward;     
         for (uint256 z; z < depositeTime[_address].length; z++) {
         if((now-depositeTime[_address][z])>Time){    
         amountReward+=((amount[_address][z]*percentage/100))/1E18;
        }
         }
         return amountReward;
         }
         
         
         function sendMultiToken() public {
     
        uint256 i = 0;
        
        for (i; i < user.length; i++) {
            uint256 Tokenpercentage=totalDepositeToken/user.length;
            Token.transfer(user[i],Tokenpercentage);
          
        }
     
    }


 function UserInfo (address _add) public view returns (uint256[] memory usersAmount,uint256 usersReward)
    {
  
        return (  amount[_add], reward[_add]);
    }
    
    function lock() public onlyOwner {
        ApprovalByAdmin = true;
    } 
    
    function unlock() public onlyOwner {
        ApprovalByAdmin = false;
    }
    


}