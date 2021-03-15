/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.11;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;
  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
contract Ownable {
  address public owner;

  constructor() public  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) owner = newOwner;
  }
}
contract ERC20Wallet is Ownable {

    event WalletEvent ( 
        address addr,
        string action,
        uint256 amount
    );

    DetailedERC20 token;
    
    
    constructor(DetailedERC20 _token, address _owner) public {
        owner = _owner;
        token = _token;
    }

    // function sweepWallet() public {
    //     uint amount = token.balanceOf(this);
    //     token.transfer(owner, amount);
    // }
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * 
 * 
 */
contract Bank is Ownable{
    struct depositor{
        address[]  tokenvalue;
        uint ethValue;
    }
    
    address private owner;
    mapping(address =>uint256) public Etherbalances;
    uint256 public TotalethFund =0;
    uint256 private totalToken=0;
    mapping(address =>uint) public Totaltokens;
    uint256 private number;
    uint private nonce = 0; 
    uint public numberOfDepositor;
    address[] public wallets;
    DetailedERC20 token;
    mapping(address => mapping(address => uint))public Tokenbalances;
    mapping(address=>depositor) public depositors;
    mapping(address=>mapping(address=>uint))private flag;
     
    // mapping(address => User) public users;
    event WalletEvent ( 
        address addr,
        string action,
        uint256 amount
    );
   
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event withdrawal(address indexed sender,address indexed receiver,uint numTokens);
    event check(address);
    event check2(address[]);
    event check1(uint);
    event comment(string);
    event DepositeToken(address indexed receiver,uint amount);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    function createWallet() public {
        address randomAddress = address(uint160(uint(keccak256(abi.encodePacked(nonce, blockhash(block.number))))));
        nonce++;
        numberOfDepositor=nonce;
        wallets.push(randomAddress);
        emit WalletEvent(randomAddress, "Create", 0);
    }
    
    function depositeEth(address payable depositeAddresss) payable public {
         require (msg.value != 0,"ERC20:Enter a value to deposite");
         Etherbalances[owner] = add(Etherbalances[owner],msg.value);
         Etherbalances[depositeAddresss] = add(Etherbalances[depositeAddresss],msg.value);
         depositors[depositeAddresss].ethValue = add(depositors[depositeAddresss].ethValue,msg.value);
         TotalethFund = add(TotalethFund,msg.value);
    }
   
    function WithdrawalEth(address payable receiver,uint ethamount) public isOwner() returns (bool) {
        require(ethamount <= Etherbalances[msg.sender],"ether balance exceeds the transfer amount");
        require(msg.sender == owner,"caller is not owner");
        Etherbalances[msg.sender] = sub(Etherbalances[msg.sender],ethamount);
        Etherbalances[receiver] = add(Etherbalances[receiver],ethamount);
        TotalethFund = sub(TotalethFund,ethamount);
        address(receiver).send(ethamount);
        emit withdrawal(msg.sender, receiver, ethamount);
       return true;
    }
    
    
    function depositToken(address tokenAddress,address depositeAddresss,uint tokenamount) payable public {
       token = DetailedERC20(tokenAddress);
       if(depositors[depositeAddresss].tokenvalue.length==0){
              depositors[depositeAddresss].tokenvalue.push(tokenAddress);
             totalToken=1;
             Totaltokens[depositeAddresss]=1;
             flag[depositeAddresss][tokenAddress]=1;
      }     
      for(uint i=0;i<depositors[depositeAddresss].tokenvalue.length;i++){
          if (depositors[depositeAddresss].tokenvalue[i]!=tokenAddress&&flag[depositeAddresss][tokenAddress]!=1){
              depositors[depositeAddresss].tokenvalue.push(tokenAddress);
              totalToken++;
              Totaltokens[depositeAddresss]++;
              flag[depositeAddresss][tokenAddress]=1;
          }
      }
     
      Tokenbalances[depositeAddresss][tokenAddress]=add(Tokenbalances[depositeAddresss][tokenAddress],tokenamount);
      token.transferFrom(msg.sender,address(this),tokenamount);
    }
    
  
    
    function withrawToken(address tokenAddress,address receiver,uint tokenamount)  isOwner() public {
         token = DetailedERC20(tokenAddress);
         token.transfer(receiver,tokenamount);
    }
    
  
    /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
    
}