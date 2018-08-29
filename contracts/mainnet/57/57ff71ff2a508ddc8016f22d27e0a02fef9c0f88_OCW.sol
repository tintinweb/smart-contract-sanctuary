pragma solidity 0.4.24;

contract OCW {
  mapping (uint256 => Mark) public marks;
  string public constant name = "One Crypto World";
  string public constant symbol = "OCW";
  uint8 public constant decimals = 0;
  string public constant memo = "Introducing One Crypto World (OCW)\n A blockchain is a ledger showing the quantity of something controlled by a user. It enables one to transfer control of that digital representation to someone else.\nOne Crypto World (OCW) is created and designed by Taiwanese Crypto Congressman Jason Hsu, who is driving for innovative policies in crypto and blockchain. It will be designed as a utility token without the nature of securities. OCW will not go on exchange; users will not be able to make any direct profit through OCW.\nOne Crypto World is a Proof of Support(POS). The OCW coin will only be distributed to global Key Opinion Leaders (KOLs), which makes it exclusive.\nBy using OCW coins, each KOL can contribute their valuable opinion to the Crypto Congressman’s policies.";
  
  mapping (address => uint256) private balances;
  mapping (address => uint256) private marked;
  uint256 private totalSupply_ = 1000;
  uint256 private markId = 0;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  
  struct Mark {
    address author;
    bytes content;
  }

  constructor() public {
    balances[msg.sender] = totalSupply_;
  } 
  
  function () public {
      mark();
  }

  function mark() internal {
    require(1 + marked[msg.sender] <= balances[msg.sender]);
    markId ++;
    marked[msg.sender] ++;
    Mark memory temp;
    temp.author = msg.sender;
    temp.content = msg.data;
    marks[markId] = temp;
  }

  function totalMarks() public view returns (uint256) {
    return markId;
  }
  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value + marked[msg.sender] <= balances[msg.sender]);
    require(_value <= balances[msg.sender]);
    require(_value != 0);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}