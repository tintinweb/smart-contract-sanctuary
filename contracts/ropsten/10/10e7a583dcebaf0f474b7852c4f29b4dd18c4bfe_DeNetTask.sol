pragma solidity ^0.4.20;

/*
    ToDo:
    1. WithdrawToken
    2. Fees
    3. ...
    
    Deposit Example:
    "0x20708856000F2757B9bAd30c1851872f3998362C", "1000000"
    
    "0x20708856000F2757B9bAd30c1851872f3998362C", "0x3d71e8a1a1038623a2def831abdf390897eb1d77"
    
    checkStorageProof
    ["0x1262","0x12","0x12"], "0x3d71e8a1a1038623a2def831abdf390897eb1d77"
    
    getWithdraw
        "0x20708856000F2757B9bAd30c1851872f3998362C",
        "0x3d71e8a1a1038623a2def831abdf390897eb1d77",
        10, 
        ["0x1262","0x12","0x12"], 15000
        
    getLightingWithdraw 
        "0x20708856000F2757B9bAd30c1851872f3998362C",
        "0x3d71e8a1a1038623a2def831abdf390897eb1d77",
        "0x1",
        "0x01",
        15000,
        1
    checkHold
        "0x20708856000F2757B9bAd30c1851872f3998362C",
        "0x3d71e8a1a1038623a2def831abdf390897eb1d77",
        "0x1",
        "0x3", // 0x0 - Sum, 0x1 - Time, 0x2 - nonce, 0x3 - payed
        15000,
        1
        

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
    
    // function verify(address _checkAddr, bytes32 hash, uint8 v, bytes32 r, bytes32 s) constant returns(bool) {
    //     return ecrecover(hash, v, r, s) == _checkAddr;
    // }
}
contract MegaToken {
    using SafeMath for uint256;
    
    mapping (address => mapping (address => uint256)) public tokens; //mapping of token addresses to mapping of account balances 
    
    /*
        holdedSum = hold[token][address][taskHash][0];
        holdedBlock/Time = hold[token][address][taskHash][1];
        lastNonce = hold[token][address][taskHash][2]
        Payed = hold[token][address][taskHash][3]
        
    */
    mapping (address => mapping (address => mapping (bytes32 => mapping (bytes1 => uint256)))) public hold; 
    
    event TransferDeposit(address indexed token, address indexed from, address indexed to, uint256 value);
    event TransferLighting(address indexed token, address indexed from,
                           address indexed to, uint256 total, uint256 value,
                           bytes32 channel, uint32 nonce);
    
    function transferToken(address _token, address _from, address _to, uint256 _value) internal {
        require(tokens[_token][_from] >= _value);
        tokens[_token][_from] = tokens[_token][_from].sub(_value);
        tokens[_token][_to] = tokens[_token][_to].add(_value);
        TransferDeposit(_token, _from, _to, _value);
    }
    
    /*
        lightingTransfer is tranfer with hold in 2 hours
        holdedSum = hold[token][address][taskHash][0];
        holdedBlock/Time = hold[token][address][taskHash][1];
        lastNonce = hold[token][address][taskHash][2]
        Payed = hold[token][address][taskHash][3]
    */
    function lightingTransfer(address _token, address _from, address _to, uint256 _total, uint32 _nonce, bytes32 _channel) internal {
        uint256 sendVal;
        sendVal = _total.sub(hold[_token][_to][_channel][0x3]);
        
        require(hold[_token][_to][_channel][0x2] < _nonce); // checkNonce
        require(_total - hold[_token][_to][_channel][0x3] > 0); // check Total - Payed > 0
        require(sendVal >= tokens[_token][_from]); // check Available balance
        
        hold[_token][_to][_channel][0x2] = _nonce;
        hold[_token][_to][_channel][0x1] = block.number + 360;
        tokens[_token][_from] = tokens[_token][_from].sub(sendVal);
        hold[_token][_to][_channel][0x0] = hold[_token][_to][_channel][0x0].add(sendVal); 
        hold[_token][_to][_channel][0x3] = _total;
        TransferLighting(_token, _from, _to, _total, sendVal, _channel, _nonce);
        delete sendVal;
    }
    
}
contract DepositableToken is Ownable, MegaToken {
    using SafeMath for uint256;
    
    mapping (address => uint256) public lastActiveTransaction;
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
    
    function checkStorageProof(bytes32[] _proof, address _payer) public  pure returns (bool) {
        require(_proof.length > 0);
        require(_payer != address(0));
        return true;
    }
    
    function getWithdraw(
            address token,
            address payer,
            uint32 taskType,
            bytes32[] proof,
            uint256 amount
        ) public {
        
        // Storage 10 Type
        if (taskType == uint32(10)) {
            if (checkStorageProof(proof, payer)) {
                transferToken(token, payer, msg.sender, amount);
            }
        }
    }
    
    function getLightingWithdraw(address token,
                                address payer,
                                bytes32 channelId,
                                bytes32 digSig,
                                uint256 total,
                                uint32 mNonce
                                ) external
    {
        require(digSig != 0x0); // need to real checker
       
        lightingTransfer(token, payer, msg.sender, total, mNonce, channelId);
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