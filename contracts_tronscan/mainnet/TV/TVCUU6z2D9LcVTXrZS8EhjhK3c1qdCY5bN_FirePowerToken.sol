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
  address payable public owners;
  constructor() public {
    owners = msg.sender;
  }
  function setOwner(address payable _owner) external onlyOwner{
      owners = _owner;
  }
  modifier onlyOwner() {
    require(owners == msg.sender,'Permission denied');
    _;
  }
}
interface FireFullContract {
    function startContract() external;
    function setNextPeriods() external;
}
contract FirePowerToken is ERC20,Ownable {
  using SafeMath for uint;
  FireFullContract private FFC;
  bool public contractState = false;
  address public contractAddress;
  address[] public superPlayerQueue;
  uint public periods = 1;
  uint public startPeople = 0;
  uint public surplus = 0;
  uint public burnTicket = 0;
  uint public nextBurn = 6000000 trx;
  uint public saleScale = 11000;
  struct saleStateObj{
      uint count;
      uint amount;
      uint token;
      uint withdraw;
  }
  struct superPlayerObj{
      bool state;
      uint withdrawProfit;
      uint profitFlag;
  }
  saleStateObj public nodeState;
  saleStateObj public nomalState;
  mapping(address=>superPlayerObj) public nodeInfoList;

  mapping(uint => mapping(uint => uint)) public periodsSupply;
  event Buyer(address indexed buyer, uint amount, uint tokens,uint timeStamp);
  event InvitBuy(address indexed buyer, address indexed inviter,uint amount,uint invit,uint timeStamp);
  
  constructor () public {
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
  
  function restore(address _nodeAddress,address _invitAddress,uint _amount,uint _timeStamp) external onlyOwner{
      uint supply = 300000 trx;
      surplus = surplus.add(supply);
      periodsSupply[periods][2] = periodsSupply[periods][2].add(supply);
      if(_invitAddress != _nodeAddress){
          emit InvitBuy(_nodeAddress,_invitAddress,_amount,_amount.mul(15).div(100),_timeStamp);
      }
      balances[owners] = balances[owners].sub(supply);
      superPlayerQueue.push(_nodeAddress);
      nodeInfoList[_nodeAddress] = superPlayerObj({
           state:true,
           withdrawProfit:0,
           profitFlag:0
      });
      nodeState.count = nodeState.count + 1;
      nodeState.amount = nodeState.amount.add(_amount);
      nodeState.token = nodeState.token.add(supply);
      emit Buyer(_nodeAddress, _amount, supply, _timeStamp);
  }
  
  function buy(address payable _invit) external payable{
      require(periods <= 3 ,"The Ended");
      require(msg.value == periodsSupply[periods][0],"Incorrect amount");
      uint supply = 300000 trx;
      surplus = surplus.add(supply);
      periodsSupply[periods][2] = periodsSupply[periods][2].add(supply);
      uint invitAmount = 0;
      if(_invit != address(0x0) && _invit != address(this) && _invit != msg.sender){
          invitAmount = msg.value.mul(15).div(100);
          _invit.transfer(invitAmount);
          emit InvitBuy(msg.sender,_invit,msg.value,invitAmount,now);
      }
      balances[owners] = balances[owners].sub(supply);
      superPlayerQueue.push(msg.sender);
      nodeInfoList[msg.sender] = superPlayerObj({
           state:true,
           withdrawProfit:0,
           profitFlag:0
      });

      if(periodsSupply[periods][2] >= periodsSupply[periods][1]){
          periods = periods + 1;
      }
      nodeState.count = nodeState.count + 1;
      nodeState.amount = nodeState.amount.add(msg.value);
      nodeState.token = nodeState.token.add(supply);
      owners.transfer(msg.value.sub(invitAmount));
      emit Buyer(msg.sender, msg.value, supply, now);
  }
  
  function sale() external payable{
      uint ticket = msg.value.mul(1000).div(saleScale);
      require(surplus >= ticket,"surplus not enoug");
      surplus = surplus.sub(ticket);
      uint pre = balances[msg.sender];
      balances[msg.sender] = ticket.add(balances[msg.sender]);
      uint last = balances[msg.sender];
      if(pre < 100 trx && last >=100 trx){
		  startPeople = startPeople + 1;
          startContract();
      }
      nomalState.count = nomalState.count + 1;
      nomalState.amount = nomalState.amount.add(msg.value);
      nomalState.token = nomalState.token.add(ticket);
	  emit Buyer(msg.sender, msg.value, ticket, now);
  }
  
  function getSP(address _account) view external returns(bool,uint,uint){
      uint profit = nodeInfoList[msg.sender].state?nomalState.amount.sub(nodeInfoList[msg.sender].profitFlag).div(100):0;
      return (nodeInfoList[_account].state,profit,nodeInfoList[_account].withdrawProfit);
  }
  
  function withdrawProfit() external{
      require(nodeInfoList[msg.sender].state,"not supernode");
      uint profit = nomalState.amount.sub(nodeInfoList[msg.sender].profitFlag).div(100);
      nodeInfoList[msg.sender].profitFlag = nomalState.amount;
      nodeInfoList[msg.sender].withdrawProfit = nodeInfoList[msg.sender].withdrawProfit.add(profit);
      nomalState.withdraw = nomalState.withdraw.add(profit);
      msg.sender.transfer(profit);
  }
  
  function currentNomalScale() external view returns (uint,uint,uint) {
      uint total = 1e9;
      return (periodsSupply[periods][0],300000 trx,total.div(saleScale));
  }
  
  function startContract() internal{
      if(contractState == false && startPeople >= 4000 && periods > 3){
          contractState = true;
          FFC.startContract();
      }
  }
  
  function transfer(address recipient, uint amount) public returns (bool) {
    uint sendOld = balances[msg.sender];
    uint recOld = balances[recipient];
    super._transfer(msg.sender,recipient, amount);
    if(sendOld >= 100 trx  && balances[msg.sender] < 100 trx){
        startPeople = startPeople - 1;
    }
    
    if(recOld < 100 trx && balances[recipient] >= 100 trx){
        startPeople = startPeople + 1;
    }
    startContract();
  }
  
  function setContract(address _contractAddress) external onlyOwner{
      contractAddress = _contractAddress;
      FFC = FireFullContract(contractAddress);
  }
  
  function burn(address account, uint amount) external returns(bool){
      require(msg.sender == contractAddress, "not contract address");
      burnTicket = burnTicket.add(amount);
      setNextScale();
      super._burn(account,amount);
      return true;
  }

  function setNextScale() internal{
    if(burnTicket >= nextBurn){
        saleScale = saleScale.mul(140).div(100);
        uint newBurn = totalSupply.mul(20).div(100);
        nextBurn = nextBurn.add(newBurn);
        FFC.setNextPeriods();
    }
  }
  function superPlayerInfo() external view returns(address[] memory){
      return superPlayerQueue;
  }
}