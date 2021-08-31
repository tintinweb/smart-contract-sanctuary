// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Token.sol";

contract CtnPledge {

    ContinuumFinanceToken private token;

    mapping(address => uint) public ctnBalanceOf;

    mapping(address => bool) public isDeposited;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);


    constructor(ContinuumFinanceToken _token) public {
     token = _token;
    }

    function deposit(uint256 amount)  public {
        require(isDeposited[msg.sender] == false, 'Error, deposit already active');
        require(token.balanceOf(msg.sender) >= amount, 'Error balance not enough');
        token.approve(msg.sender, amount);
        token.transferFrom(msg.sender, address(this), amount);
        ctnBalanceOf[msg.sender] = ctnBalanceOf[msg.sender] + amount;
        isDeposited[msg.sender] = true; //activate deposit status
        emit Deposit(msg.sender, amount);
    }


    function ctnBalance() public view returns(uint256){
      require(isDeposited[msg.sender] == true, 'Error, deposit not active');
      return ctnBalanceOf[msg.sender];
    }

    function withdraw() public {
    require(isDeposited[msg.sender]==true, 'Error, no previous deposit');
    uint userBalance = ctnBalanceOf[msg.sender]; //for event

    token.transferFrom(address(this), msg.sender, userBalance);

    isDeposited[msg.sender] = false;

    emit Withdraw(msg.sender, userBalance);
  }

}