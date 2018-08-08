pragma solidity ^0.4.10;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Gmt is SafeMath, StandardToken {

    string public constant name = "Gold Mine Token";
    string public constant symbol = "GMT";
    uint256 public constant decimals = 18;

    uint256 private constant tokenBountyCap = 60000*10**decimals;
    uint256 private constant tokenCreationCapPreICO =  460000*10**decimals;
    uint256 public constant tokenCreationCap = 1200000*10**decimals;

    address public constant owner = 0x3705FC0600D7173E3d451740B3f304747B447ECe;

    // 1 ETH = 250 USD
    uint private oneTokenInWeiSale = 5000000000000000; // 0,005 ETH
    uint private oneTokenInWei = 10000000000000000; // 0,01 ETH

    Phase public currentPhase = Phase.PreICO;

    enum Phase {
        PreICO,
        ICO
    }

    modifier onlyOwner {
        if(owner != msg.sender) revert();
        _;
    }

    event CreateGMT(address indexed _to, uint256 _value);
    event Mint(address indexed to, uint256 amount);

    function Gmt() {}

    function () payable {
        createTokens();
    }

    function createTokens() internal {
        if (msg.value <= 0) revert();

        if (currentPhase == Phase.PreICO) {
            if (totalSupply <= tokenCreationCapPreICO) {
                generateTokens(oneTokenInWeiSale);
            }
        }
        else if (currentPhase == Phase.PreICO) {
            if (totalSupply > tokenCreationCapPreICO && totalSupply <= tokenCreationCap) {
                generateTokens(oneTokenInWei);
            }
        }
        else if (currentPhase == Phase.ICO) {
            if (totalSupply > tokenCreationCapPreICO && totalSupply <= tokenCreationCap) {
                generateTokens(oneTokenInWei);
            }
        } else {
            revert();
        }
    }

    function generateTokens(uint _oneTokenInWei) internal {
        uint multiplier = 10 ** decimals;
        uint256 tokens = safeDiv(msg.value, _oneTokenInWei)*multiplier;
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        if (tokenCreationCap <= checkedSupply) revert();
        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        CreateGMT(msg.sender,tokens);
        owner.transfer(msg.value);
    }


    function changePhaseToICO() external onlyOwner returns (bool){
        currentPhase = Phase.ICO;
        return true;
    }

    function createBountyTokens() external onlyOwner returns (bool){
        uint256 tokens = tokenBountyCap;
        balances[owner] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        CreateGMT(owner, tokens);
    }


    function changeTokenPrice(uint tpico1, uint tpico) external onlyOwner returns (bool){
        oneTokenInWeiSale = tpico1;
        oneTokenInWei = tpico;
        return true;
    }


}