/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity 0.4.24;

library SafeMath {
   function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
      if (a == 0) {
         return 0;
      }
      c = a * b;  
      assert(c / a == b);
      return c;
   }
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      // uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return a / b;
   }
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
   }
   function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
   }
}
contract Token {
   using SafeMath for uint256;
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
   mapping(address => uint256) balances;
   uint256 totalSupply_;
   function totalSupply() public view returns (uint256) {
      return totalSupply_;
   }
   function transfer(address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[msg.sender], "balance of msg.sender insufficient");
      require(_to != address(0));
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
   }
   function balanceOf(address _owner) public view returns (uint256) {
      return balances[_owner];
   }
   mapping (address => mapping (address => uint256)) internal allowed;
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      require(_value <= balances[_from]);
      require(_value <= allowed[_from][msg.sender]);
      require(_to != address(0));
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      emit Transfer(_from, _to, _value);
      return true;
   }
   function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
   }
   function allowance(address _owner,address _spender) public view returns (uint256) {
      return allowed[_owner][_spender];
   }
   function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
      allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);   
   }
   function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
      uint256 oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue >= oldValue) {
         allowed[msg.sender][_spender] = 0;
      } else {
         allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }
}

contract ChurroCoin is Token {
   string public name = 'Churro Coin';
   string public symbol = 'CHRR';
   uint256 public decimals = 10;
   uint256 public totalSupply = 1000e16;
   address public crowdsaleAddress;
   address public owner;
   
   modifier onlyCrowdsale {
      require(msg.sender == crowdsaleAddress);
      _;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
   constructor () public Token() {
      owner = msg.sender;
      balances[msg.sender] = 900e16;
   }
   function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
      require(_crowdsaleAddress != address(0));
      crowdsaleAddress = _crowdsaleAddress;
      balances[_crowdsaleAddress] = 100e16;
   }
   function buyTokens(address _receiver, uint256 _amount) public onlyCrowdsale {
      require(_receiver != address(0));
      require(_amount > 0);
      
      transfer(_receiver, _amount);
   }
}

contract Crowdsale1 {
   uint256 public tokenRate;
   ChurroCoin public token;   
   address public owner;
   uint256 public tokensSold;
   uint256 public limitCrowdsale = 100e16;

   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
   function () public payable {
      buy();
   }
   constructor(uint256 _tokenRate, address _tokenAddress) public {
      require(_tokenRate != 0 &&
      _tokenAddress != address(0));
      tokenRate = _tokenRate;
      token = ChurroCoin(_tokenAddress);
      owner = msg.sender;
   }
   function buy() public payable {
      uint256 tokensToBuy;
      tokensToBuy = msg.value * 1e10 / 1 ether * tokenRate;

      token.buyTokens(msg.sender, tokensToBuy);

      tokensSold += tokensToBuy;
   }
   function extractEther() public onlyOwner {
      owner.transfer(address(this).balance);
   }
}