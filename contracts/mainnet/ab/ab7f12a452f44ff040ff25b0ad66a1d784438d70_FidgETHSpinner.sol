pragma solidity ^0.4.16;

contract FidgETHSpinner {
  string public name = "FidgETHSpinner";
  string public symbol = "FDGTHSPNNR";
  uint public decimals = 18;

  address public wallet;

  uint public startBlock;
  uint public endBlock;

  uint public totalSupply;
  mapping(address => uint) public balanceOf;

  uint public normalRate = 10;
  uint public juicyBonus = 1000;

  uint public weiRaised;

  event Fidget(address indexed purchaser, address indexed to, uint value, uint juicyBananas, uint rate, uint tokens);
  event Spin(address indexed to, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  // This smart contract has entirely been made possible by our favorite sponsor and drug: PCP ???

  function FidgETHSpinner(){
    wallet = msg.sender;

    startBlock = block.number;
    endBlock = startBlock + 150000; // 150,000 blocks == approx forty longspins
  }

  function changeWallet(address _wallet){
    require(msg.sender == wallet);
    wallet = _wallet;
  }

  function balanceOf(address _address) constant returns (uint) {
    return balanceOf[_address];
  }

  function icoActive() constant returns (bool) {
    return block.number <= endBlock;
  }

  // FIDGET SPINNIG

  function() payable {
    fidget(msg.sender);
  }

  // buy the fidgures
  function fidget(address _to) payable {
    require(_to != 0x0); // Bingo
    require(_to != address(0)); // Bango

    require(block.number <= endBlock);
    require(msg.value >= 0.03 ether);

    // remember, my dear friend, that this decrements juicyBonus *after* it is multiplied with normalRate. So juicyBonus is always >=1 here
    uint rate = normalRate * juicyBonus--;

    uint tokens = msg.value * rate;
    weiRaised += msg.value;

    juicyBonus = (juicyBonus < 1) ? 1 : juicyBonus;

    spin(_to, tokens);
    Fidget(msg.sender, _to, msg.value, juicyBonus, rate, tokens);

    wallet.transfer(msg.value);
  }

  // mint spint
  function spin(address _to, uint _tokens) internal {
    totalSupply += _tokens; // Ba
    balanceOf[_to] += _tokens; // zinba

    // you did it!
    Spin(_to, _tokens); // ??
  }

  function transfer(address _to, uint _tokens){
    require(_to != 0x0);
    require(_to != address(0));

    require(balanceOf[msg.sender] >= _tokens); // haha gotcha
    require(balanceOf[_to] + _tokens > balanceOf[_to]); // lol

    balanceOf[msg.sender] -= _tokens; // :()
    balanceOf[_to] += _tokens; // woo!

    // Watch out here comes a Flying figdet spiner across the univrese!
    Transfer(msg.sender, _to, _tokens);
  }
}// xD