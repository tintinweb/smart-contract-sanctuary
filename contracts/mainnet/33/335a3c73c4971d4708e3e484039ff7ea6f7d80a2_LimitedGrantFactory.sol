pragma solidity >=0.4.21 <0.6.0;

contract ERC20TokenBankInterface{
  function balance() public view returns(uint);
  function token() public view returns(address, string memory);
  function issue(address _to, uint _amount) public returns (bool success);
}

contract LimitedGrant{
  address public owner;
  ERC20TokenBankInterface public token_bank;
  uint256 public limit_period;
  uint256 public limit_amount;
  uint256 public last_grant_block_num;
  string public name;


  constructor(string memory _name, address _erc20bank,
              uint256 _limit_period, uint256 _limit_amount) public{
                owner = msg.sender;
                name = _name;
                token_bank = ERC20TokenBankInterface(_erc20bank);
                limit_period = _limit_period;
                limit_amount = _limit_amount;
                last_grant_block_num = 0;
  }

  function transferOwnership(address _new) public{
    require(msg.sender == owner, "only owner can call this");
    owner = _new;
  }

  event LGrantUser(address to, uint256 amount, string reason);
  function grant(address _to, uint256 _amount, string memory _reason) public{
    require(msg.sender == owner, "only owner can call this");
    require(block.number > last_grant_block_num + limit_period, "too close");
    require(_amount <= limit_amount, "too much");
    require(token_bank.balance() >= _amount, "not enough token");

    token_bank.issue(_to, _amount);
    emit LGrantUser(_to, _amount, _reason);
  }
}

contract LimitedGrantFactory{
  event NewLimitedGrant(address addr);

  function createLimitedGrant(string memory name, address erc20bank, uint256 limit_period, uint256 limit_amount)
  public returns(address){
    LimitedGrant lg = new LimitedGrant(name, erc20bank, limit_period, limit_amount);
    lg.transferOwnership(msg.sender);
    emit NewLimitedGrant(address(lg));
    return address(lg);
  }
}