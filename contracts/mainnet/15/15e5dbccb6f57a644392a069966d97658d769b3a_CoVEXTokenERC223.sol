pragma solidity ^0.4.15;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract ERC223Token is ERC223Interface {
    using SafeMath for uint;

    mapping(address => uint) balances; // List of user balances.
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes _data) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, empty);
    }

    
    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}

contract CoVEXTokenERC223 is ERC223Token{
    using SafeMath for uint256;

    string public name = "CoVEX Coin";
    string public symbol = "CoVEX";
    uint256 public decimals = 18;

    // 250M
    uint256 public totalSupply = 250*1000000 * (uint256(10) ** decimals);
    uint256 public totalRaised; // total ether raised (in wei)

    uint256 public startTimestamp; // timestamp after which ICO will start
    uint256 public durationSeconds; // 1 month= 1 * 30 * 24 * 60 * 60

    uint256 public maxCap;

    uint256 coinsPerETH;

    mapping(address => uint) etherBalance;

    mapping(uint => uint) public weeklyRewards;

    uint256 minPerUser = 0.1 ether;
    uint256 maxPerUser = 100 ether;

    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet;

    function CoVEXTokenERC223() {
        fundsWallet = msg.sender;
        
        startTimestamp = now;
        durationSeconds = 0; //admin can set it later

        //initially assign all tokens to the fundsWallet
        balances[fundsWallet] = totalSupply;

        bytes memory empty;
        Transfer(0x0, fundsWallet, totalSupply, empty);

        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    function() isIcoOpen checkMinMax payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        etherBalance[msg.sender] = etherBalance[msg.sender].add(msg.value);

        bytes memory empty;
        Transfer(fundsWallet, msg.sender, tokenAmount, empty);
    }

    function transfer(address _to, uint _value){
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint _value, bytes _data){
        return super.transfer(_to, _value, _data);   
    }

    function calculateTokenAmount(uint256 weiAmount) constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
        // setting rewards is possible only for 4 weeks
        for (uint i = 1; i <= 4; i++) {
            if (now <= startTimestamp + 7 days) {
                return tokenAmount.mul(100+weeklyRewards[i]).div(100);    
            }
        }
        return tokenAmount;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function adminBurn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
      // no need to require value <= totalSupply, since that would imply the
      // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      bytes memory empty;
      Transfer(burner, address(0), _value, empty);
    }

    function adminAddICO(uint256 _startTimestamp, uint256 _durationSeconds, 
        uint256 _coinsPerETH, uint256 _maxCap, uint _week1Rewards,
        uint _week2Rewards, uint _week3Rewards, uint _week4Rewards) isOwner{

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap * 1 ether;

        weeklyRewards[1] = _week1Rewards;
        weeklyRewards[2] = _week2Rewards;
        weeklyRewards[3] = _week3Rewards;
        weeklyRewards[4] = _week4Rewards;

        // reset totalRaised
        totalRaised = 0;
    }

    modifier isIcoOpen() {
        require(now >= startTimestamp);
        require(now <= (startTimestamp + durationSeconds));
        require(totalRaised <= maxCap);
        _;
    }

    modifier checkMinMax(){
      require(msg.value >= minPerUser);
      require(msg.value <= maxPerUser);
      _;
    }

    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }
}