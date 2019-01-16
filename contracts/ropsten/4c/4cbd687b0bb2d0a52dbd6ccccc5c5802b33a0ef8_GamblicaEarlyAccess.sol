pragma solidity ^0.4.23;

contract GMBCToken {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract GamblicaEarlyAccess {

    enum State { CREATED, DEPOSIT, PROCESSING, CLAIM }

    uint constant PRIZE_FUND_GMBC = 100000000 * (10 ** 18); // 100 000 000 GMBC

    event DepositRegistered(address _player, uint _amount);    

    GMBCToken public gmbcToken;
    
    address public owner;

    State public state;    
    uint public gmbcTotal;
    mapping (address => uint) deposit;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Method can be called only by owner");
        _;
    }

    constructor(address gmbcTokenAddress) public {
      owner = msg.sender;
      state = State.CREATED;
      gmbcToken = GMBCToken(gmbcTokenAddress);
    }

    function () public payable {
      require(msg.value == 0, "This contract does not accept ether");

      claim();
    }

    function start() public onlyOwner {
      require(gmbcToken.balanceOf(address(this)) >= PRIZE_FUND_GMBC, "Contract can only be activated with a prize fund");
      require(state == State.CREATED, "Invalid contract state");

      gmbcTotal = PRIZE_FUND_GMBC;
      state = State.DEPOSIT;
    }

    function registerDeposit(address player, uint amount) public onlyOwner {
      require(state == State.DEPOSIT, "Invalid contract state");
      require(gmbcTotal + amount == gmbcToken.balanceOf(address(this)), "Cant register that deposit");

      gmbcTotal += amount;      
      deposit[player] += amount;

      emit DepositRegistered(player, amount);
    }


    function addWinnigs(address[] winners, uint[] amounts) public onlyOwner {
      require(winners.length == amounts.length, "Invalid arguments");
      require(state == State.PROCESSING, "Invalid contract state");
      
      uint length = winners.length;
      for (uint i = 0; i < length; i++) {
        deposit[winners[i]] += amounts[i];
      }
    }
    
    function end() public onlyOwner {      
      require(state == State.PROCESSING, "Invalid contract state");

      state = State.CLAIM;
    }

     function claim() public {
      require(state == State.CLAIM, "Contract should be deactivated first");
      
      uint amount = deposit[msg.sender];
      deposit[msg.sender] = amount;
      gmbcToken.transfer(msg.sender, amount);      
    }
}