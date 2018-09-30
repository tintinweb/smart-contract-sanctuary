pragma solidity ^0.4.20;

/*
    ToDo:
    1. WithdrawToken
    2. Fees
    3. ...
    

*/

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    //function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    //function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
//   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//     if (a == 0) {
//       return 0;
//     }
//     uint256 c = a * b;
//     assert(c / a == b);
//     return c;
//   }
  
//   function div(uint256 a, uint256 b) internal pure returns (uint256) {
//     uint256 c = a / b;
//     return c;
//   }
  
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
library ByteFunctions {
    function toAddress(bytes32 bys) internal pure returns (address addr) {
        assembly {
          addr := mload(add(bys,20))
        } 
    }
}
contract DepositableToken is Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public lastActiveTransaction;
    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    
    function depositToken(address token, uint256 amount) public {
       tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
       lastActiveTransaction[msg.sender] = block.number;
       require(Token(token).transferFrom(msg.sender, this, amount));
       Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
      }
    function deposit() external payable {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        lastActiveTransaction[msg.sender] = block.number;
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    
    function getBalance(address token, address user) constant public returns (uint256) {
        return tokens[token][user];
    }
    
}

contract WithdrawToken is DepositableToken {
    event TransferDeposit(address indexed from, address indexed to, uint256 value);
    function checkStorageProof(bytes32[] _proof, address _payer) public  pure returns (bool) {
        require(_proof.length > 0);
        require(_payer != address(0));
        return true;
    }
    
    function getWithdraw(address token, address payer, uint32 taskType, bytes32[] proof, uint256 amount) public  {
        // Storage 10 Type
        if (taskType == uint32(10)) {
            require(tokens[token][payer] >= amount);
            if (checkStorageProof(proof, payer)) {
                tokens[token][payer] = tokens[token][payer].sub(amount);
                tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
                TransferDeposit(payer, msg.sender, amount);
            }
            
            
        }
        
    }
    /* function withdraw(proof, amount)
    
        Simple:
            1. check proof and amout 
            2. transferToken 
        Full:
            1. check proof and amount
            2. lock tokens for Withdraw
            3. Waiting refuteProof
            4. Withdraw
        Extra: 
            1. Proof Checker for task type
            + FULL
    */
}
contract DeNetTask is WithdrawToken{
    
}