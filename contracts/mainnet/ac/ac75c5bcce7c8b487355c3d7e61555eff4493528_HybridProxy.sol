pragma solidity ^0.4.23;

contract Contract {
  struct Contributor {
    uint256 balance;
    uint256 balance_bonus;
    uint256 fee;
    bool whitelisted;
  }
  mapping (address => Contributor) public contributors;
  uint256 public contract_eth_value;
  uint256 public contract_eth_value_fee;
}

contract ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract HybridProxy {

  struct Contributor {
    uint256 balance;
    uint256 balance_bonus;
    uint256 fee;
    bool whitelisted;
  }

  struct Snapshot {
    uint256 tokens_balance;
    uint256 eth_balance;
  }

  //FEES RELATED
  //============================
  address constant public DEVELOPER1 = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;
  address constant public DEVELOPER2 = 0x63F7547Ac277ea0B52A0B060Be6af8C5904953aa;
  uint256 constant public FEE_DEV = 500; //0.2% fee per dev -> so 0.4% fee in total
  //============================

  Contract contr;
  uint256 public eth_balance;
  uint256 public fee_balance;
  ERC20 public token;
  mapping (address => uint8) public contributor_rounds;
  Snapshot[] public snapshots;
  address owner;
  uint8 public rounds;

  constructor(address _contract) {
    owner = msg.sender;
    contr = Contract(_contract);
    eth_balance = contr.contract_eth_value();
    require(eth_balance != 0);
  }

  function dev_fee(uint256 tokens_this_round) returns (uint256) {
    uint256 tokens_individual;
    tokens_individual = tokens_this_round/FEE_DEV;
    require(token.transfer(DEVELOPER1, tokens_individual));
    require(token.transfer(DEVELOPER2, tokens_individual));
    tokens_this_round -= (2*tokens_individual);
    return tokens_this_round;
  }

  //public functions

  function withdraw()  {
    uint256 contract_token_balance = token.balanceOf(address(this));
		var (balance, balance_bonus, fee, whitelisted) = contr.contributors(msg.sender);
		if (contributor_rounds[msg.sender] < rounds) {
			Snapshot storage snapshot = snapshots[contributor_rounds[msg.sender]];
      uint256 tokens_to_withdraw = (balance * snapshot.tokens_balance) / snapshot.eth_balance;
			snapshot.tokens_balance -= tokens_to_withdraw;
			snapshot.eth_balance -= balance;
      contributor_rounds[msg.sender]++;
      require(token.transfer(msg.sender, tokens_to_withdraw));
    }
  }

  function emergency_withdraw(address _token) {
    require(msg.sender == owner);
    require(ERC20(_token).transfer(owner, ERC20(_token).balanceOf(this)));
  }

  function set_tokens_received() {
    require(msg.sender == owner);
    uint256 previous_balance;
    uint256 tokens_this_round;
    for (uint8 i = 0; i < snapshots.length; i++) {
      previous_balance += snapshots[i].tokens_balance;
    }
    tokens_this_round = token.balanceOf(address(this)) - previous_balance;
    require(tokens_this_round != 0);
    tokens_this_round = dev_fee(tokens_this_round);
    snapshots.push(Snapshot(tokens_this_round, eth_balance));
    rounds++;
  }

  function set_token_address(address _token) {
    require(msg.sender == owner && _token != 0x0);
    token = ERC20(_token);
  }
}