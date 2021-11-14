// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

//import "./babyADA.sol";

contract NBH {
  //assign Token contract to variable
  NBH public token;

  //add mappings
  mapping(address => uint) public etherBalanceOf;
  mapping(address => uint) public depositStart;
  mapping(address => bool) public isDeposited;
  mapping(address => uint) public balances;
  mapping(address => mapping(address => uint)) public allowance;
  uint public totalSupply = 1000000000000000 * 10 ** 18;
  string public name = "New Born of Hope";
  string public symbol = "NBH";
  uint public decimals = 18;

  //add events
  event Deposit(address indexed user, uint etherAmount, uint timeStart);
  event Withdraw(address indexed user, uint etherAmount, uint depositTime, uint interest);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  constructor() public payable {
    balances[msg.sender] = totalSupply;
  }

  function deposit() payable public {
    require(isDeposited[msg.sender]==false, 'Error, deposit already active');
    require(msg.value==1e16, 'Error, deposit must be >= 0.01 ETH');
 
    etherBalanceOf[msg.sender] = etherBalanceOf[msg.sender] + msg.value;
    depositStart[msg.sender] = depositStart[msg.sender] + block.timestamp;

    isDeposited[msg.sender] = true; //Activate deposit status
    emit Deposit(msg.sender, msg.value, block.timestamp);


    //increase msg.sender ether deposit balance
    //start msg.sender hodling time

    //set msg.sender deposit status to true
    //emit Deposit event
  }

  function withdraw() public {
    require(isDeposited[msg.sender]==true, 'Error, no privious deposit');
    uint userBalance = etherBalanceOf[msg.sender]; //for event

    //check user's hodl time
    uint depositTime = block.timestamp - depositStart[msg.sender];

    //calc interest per second
    //calc accrued interest
    uint interestPerSecond = 31668017 * (etherBalanceOf[msg.sender] / 1e16);
    uint interest = interestPerSecond * depositTime;

    //send eth to user
    msg.sender.transfer(userBalance);
    //token.mint(msg.sender, interest);  //interest to user

    //send interest in tokens to user

    //reset depositer data
    depositStart[msg.sender] = 0;
    etherBalanceOf[msg.sender] = 0;
    isDeposited[msg.sender] = false;

    //emit event
    emit Withdraw(msg.sender, userBalance, depositTime, interest);

  }

   function balanceOf(address owner) public view returns(uint) {
    return balances[owner];
  }

  function transfer(address to, uint value) public returns(bool) {
    require(balanceOf(msg.sender) >= value, 'balance too low');
    balances[to] += value;
    balances[msg.sender] -= value;
    emit Transfer(msg.sender, to, value);
    return true;
  }
  
  function transferFrom(address from, address to, uint value) public returns(bool) {
    require(balanceOf(from) >= value, 'balance too low');
    require(allowance[from][msg.sender] >= value, 'allowance too low');
    balances[to] += value;
    balances[from] -= value;
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint value) public returns(bool) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
}