//SourceUnit: FirePowerToken.sol

pragma solidity ^0.5.3;

contract ERC20 {
    using SafeMath for uint;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowances;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
	    
	function balanceOf(address _from) view external returns(uint) {
		return balances[_from];
	}
	   
    function _transfer(address sender, address recipient, uint amount) public {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint amount) public {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function approve(address owner, address spender, uint amount) public {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}
contract Ownable {
  address public owners;
  constructor() public {
    owners = msg.sender;
  }
  modifier onlyOwner() {
    require(owners == msg.sender,'Permission denied');
    _;
  }
}
interface FireFullGame {
    function startGame() external;
    function setNextPeriods() external;
}
contract FirePowerToken is ERC20,Ownable {
  using SafeMath for uint;
  FireFullGame private game;
  bool public gameState = false;
  address public owner;
  address public gameAddress;
  address[] internal _superNode;
  uint public periods = 1;
  uint public startPeople = 0;
  uint public surplus = 0;
  uint public burnTicket = 0;
  uint public nextBurn = 6000000 trx;
  uint public saleScale = 11000;
  uint public totalSale = 0;
  struct superNodeObj{
      bool state;
      uint withdrawProfit;
      uint profitFlag;
  }
  mapping(address=>superNodeObj) public nodeInfo;
  mapping(uint => mapping(uint => uint)) public periodsSupply;
  event Buyer(address indexed buyer, uint amount, uint tokens,uint timeStamp);
  event InvitBuy(address indexed buyer, address indexed inviter,uint amount,uint invit,uint timeStamp);
  
  constructor () public {
      owner = msg.sender;
      name = "FirePowerToken";
      symbol = "FPT";
      decimals = 6;
      totalSupply = 30000000 trx;
      balances[msg.sender] = 30000000 trx;
      periodsSupply[1][0] = 330000 trx;
      periodsSupply[1][1] = 15000000 trx;
      periodsSupply[1][2] = 0 trx;
      periodsSupply[2][0] = 420000 trx;
      periodsSupply[2][1] = 9000000 trx;
      periodsSupply[2][2] = 0 trx;
      periodsSupply[3][0] = 510000 trx;
      periodsSupply[3][1] = 6000000 trx;
      periodsSupply[3][2] = 0 trx;
      
  }
  
  function buy(address payable _invit) external payable{
      require(periods <= 3 ,"The Ended");
      require(msg.value == periodsSupply[periods][0],"Incorrect amount");
      uint supply = 300000 trx;
      surplus = surplus.add(supply);
      periodsSupply[periods][2] = periodsSupply[periods][2].add(supply);
      if(_invit != address(0x0) && _invit != address(this) && _invit != msg.sender){
          invitReward(_invit);
      }
      balances[owner] = balances[owner].sub(supply);
      _superNode.push(msg.sender);
      nodeInfo[msg.sender] = superNodeObj({
           state:true,
           withdrawProfit:0,
           profitFlag:0
      });
      startPeople = startPeople + 1;
      if(periodsSupply[periods][2] >= periodsSupply[periods][1]){
          periods = periods + 1;
      }
      emit Buyer(msg.sender, msg.value, supply, now);
  }
  
  function sale() external payable{
      uint ticket = msg.value.mul(1000).div(saleScale);
      require(surplus >= ticket,"surplus not enoug");
      surplus = surplus.sub(ticket);
      uint pre = balances[msg.sender];
      balances[msg.sender] = ticket.add(balances[msg.sender]);
      uint last = balances[msg.sender];
      if(pre < 100 && last >=100){
          startPeople = startPeople + 1;
          startGame();
      }
      totalSale = totalSale.add(msg.value);
	  emit Buyer(msg.sender, msg.value, ticket, now);
  }
  
  function nodeProfit() view external returns(uint){
      require(nodeInfo[msg.sender].state,"not supernode");
      return totalSale.sub(nodeInfo[msg.sender].profitFlag).div(100);
  }
  
  function withdrawProfit() external{
      require(nodeInfo[msg.sender].state,"not supernode");
      uint profit = totalSale.sub(nodeInfo[msg.sender].profitFlag).div(100);
      nodeInfo[msg.sender].profitFlag = totalSale;
      nodeInfo[msg.sender].withdrawProfit = profit;
      msg.sender.transfer(profit);
  }

  function invitReward(address payable _invit) internal{
      uint reward = msg.value.mul(15).div(100);
      _invit.transfer(reward);
      emit InvitBuy(msg.sender,_invit,msg.value,reward,now);
  }
  
  function currentNomalScale() external view returns (uint,uint) {
      return (periodsSupply[periods][0],300000 trx);
  }
  
  function startGame() internal{
      if(gameState == false && startPeople >= 4000 && periods > 3){
          gameState = true;
          game.startGame();
      }
  }
  
  function transfer(address recipient, uint amount) public returns (bool) {
    if(balances[recipient] > 100){
            super._transfer(msg.sender,recipient, amount);
        }else {
            super._transfer(msg.sender,recipient, amount);
            if(balances[recipient] >= 100){
                startPeople = startPeople + 1;
            }
        }
	if(balances[msg.sender] < 100){
		startPeople = startPeople - 1;
	}
    startGame();
  } 
  
  function setOwner(address _owner) external onlyOwner{
      owner = _owner;
  }
  
  function setGame(address _gameAddress) external onlyOwner{
      gameAddress = _gameAddress;
      game = FireFullGame(gameAddress);
  }
  
  function burn(address account, uint amount) external returns(bool){
      require(msg.sender == gameAddress, "not game address");
      burnTicket = burnTicket.add(amount);
      setNextScale();
      super._burn(account,amount);
      return true;
  }
  function superNode() external returns(address[] memory){
      return _superNode;
  }
  function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
  }
  function setNextScale() internal{
    if(burnTicket >= nextBurn){
        saleScale = saleScale.mul(140).div(100);
        uint newBurn = totalSupply.mul(20).div(100);
        nextBurn = nextBurn.add(newBurn);
        game.setNextPeriods();
    }
  }
 function getProgressScale() external view returns(uint){
	uint total = 1e9;
	return total.div(saleScale);
  }
}