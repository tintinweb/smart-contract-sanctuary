pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract EOSToken{
    using SafeMath for uint256;
    string TokenName = "EOS";
    
    uint256 totalSupply = 100**18;
    address owner;
    mapping(address => uint256)  balances;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function mint(address _to,uint256 _amount) public onlyOwner {
        require(_amount < totalSupply);
        totalSupply = totalSupply.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    }
    
    function transfer(address _from, address _to, uint256 _amount) public onlyOwner {
        require(_amount < balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    }
    
    function eosOf(address _who) public constant returns(uint256){
        return balances[_who];
    }
}


contract EOSGame{
    
    using SafeMath for uint256;
    mapping(address => uint256) public bet_count;
    uint256 FUND = 100;
    uint256 MOD_NUM = 20;
    uint256 POWER = 100;
    uint256 SMALL_CHIP = 1;
    uint256 BIG_CHIP = 20;
    EOSToken public eos;
    
    event FLAG(string b64email, string slogan);
    
    constructor() public{
        eos=new EOSToken();
    }
    
    function initFund() public{
        if(bet_count[tx.origin] == 0){
            bet_count[tx.origin] = 1;
            eos.mint(tx.origin, FUND);
        }
    }
    
    function bet(uint256 chip) internal {
        bet_count[tx.origin] = bet_count[tx.origin].add(1);
        uint256 seed = uint256(keccak256(abi.encodePacked(block.number)))+uint256(keccak256(abi.encodePacked(block.timestamp)));
        uint256 seed_hash = uint256(keccak256(abi.encodePacked(seed)));
        uint256 shark = seed_hash % MOD_NUM;
        uint256 lucky_hash = uint256(keccak256(abi.encodePacked(bet_count[tx.origin])));
        uint256 lucky = lucky_hash % MOD_NUM;
        if (shark == lucky){
            eos.transfer(address(this), tx.origin, chip.mul(POWER));
        }
    }
    
    function smallBlind() public {
        eos.transfer(tx.origin, address(this), 1);
        bet(SMALL_CHIP);
    }
    
    function bigBlind() public {
        eos.transfer(tx.origin, address(this), 20);
        bet(BIG_CHIP);
    }
    
    function eosBlanceOf() public view returns(uint256) {
        return eos.eosOf(tx.origin);
    }

    function CaptureTheFlag(string b64email) public{
		require (eos.eosOf(tx.origin) > 18888);
		emit FLAG(b64email, "Congratulations to capture the flag!");
	}
}