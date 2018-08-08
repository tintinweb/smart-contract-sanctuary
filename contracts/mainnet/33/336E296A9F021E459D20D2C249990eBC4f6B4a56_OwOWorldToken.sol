pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract OwOWorldToken {

    using SafeMath for uint256;

    string public constant symbol = "OWO";
    string public constant name = "OwO.World Token";
    uint public constant decimals = 18;

    uint public _owoAmount;
    uint public _totalSupply = 0;

    uint public _oneTokenInWei = 108931000000000; // starts at $0.02
    bool public _CROWDSALE_PAUSED = false;

    address public _ownerWallet;   // owner wallet
    address public _multiSigWallet;  // The address to hold the funds donated
    uint public _totalEthCollected = 0;            // In wei
    bool public _saleFinalized = false;         // Has OwO Dev finalized the sale?

    uint constant public dust = 1 finney;    // Minimum investment
    uint public _cap = 50000 ether;       // Hard cap to protect the ETH network from a really high raise
    uint public _capOwO = 100000000 * 10 ** decimals;   // total supply of owo for the crowdsale

    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 25;

    /* How many distinct addresses have invested */
    uint public _investorCount = 0;

    /* the UNIX timestamp end date of the crowdsale */
    uint public _endsAt;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Crowdsale end time has been changed
    event EndsAtChanged(uint endsAt);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => uint256) public investedAmountOf;
    mapping (address => uint256) public tokenAmountOf;


    function () payable{
        createTokens();
    }

    function OwOWorldToken()
    {

        _ownerWallet = msg.sender;

        uint tokenAmount = 500000 * 10 ** decimals;
        balances[_ownerWallet] = balances[_ownerWallet].add(tokenAmount);
        _totalSupply = _totalSupply.add(tokenAmount);
        _multiSigWallet = 0x6c5140f605a9Add003B3626Aae4f08F41E6c6FfF;
        _endsAt = 1514332800;

    }

    modifier onlyOwner(){
        require(msg.sender == _ownerWallet);
        _;
    }

    function setOneTokenInWei(uint w) onlyOwner {
        _oneTokenInWei = w;
        changed(msg.sender);
    }

    function setMultiSigWallet(address w) onlyOwner {
        require(w != 0
          && _investorCount < MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE
          );

          _multiSigWallet = w;

        changed(msg.sender);
    }

    function setEndsAt(uint time) onlyOwner {

      require(now < time);

      _endsAt = time;
      EndsAtChanged(_endsAt);
    }

    function setPause(bool w) onlyOwner{
        _CROWDSALE_PAUSED = w;
        changed(msg.sender);
    }

   function setFinalized(bool w) onlyOwner{
        _saleFinalized = w;
        changed(msg.sender);
        if(_saleFinalized == true){
            withdraw();
        }
    }

    function getMultiSigWallet() constant returns (address){

        return _multiSigWallet;

    }
    function getMultiSigBalance() constant returns (uint){

        return balances[_multiSigWallet];

    }
    function getTotalSupply() constant returns (uint){

        return _totalSupply;

    }


    function getTotalEth() constant returns (uint){

        return _totalEthCollected;

    }

    function getTotalPlayers() constant returns (uint){

        return _investorCount;

    }
    function createTokens() payable{

        require(
            msg.value > 0
            && _totalSupply < _capOwO
            && _CROWDSALE_PAUSED ==false
            && _saleFinalized == false
            && now < _endsAt
            );

               //priced at $0.03
            if(_totalSupply >500001 && _totalSupply<1000000 && _oneTokenInWei<135714800000000){
                _oneTokenInWei = 135714800000000;
            }
            //priced at $0.04
            if(_totalSupply >1000001 && _totalSupply<2000000 && _oneTokenInWei<180953100000000){
                _oneTokenInWei = 180953100000000;
            }
            //priced at $0.05
            if(_totalSupply>2000001 && _totalSupply<4000000 && _oneTokenInWei<226191400000000){
                _oneTokenInWei = 226191400000000;
            }
            //priced at $0.06
            if(_totalSupply>4000001 && _totalSupply<6000000 && _oneTokenInWei<271429700000000){
              _oneTokenInWei = 271429700000000;
            }
            //priced at $0.07
            if(_totalSupply>6000001 && _totalSupply<8000000 && _oneTokenInWei<316667900000000){
              _oneTokenInWei = 316667900000000;
            }
            //priced at $0.08
            if(_totalSupply>8000001 && _totalSupply<10000001 && _oneTokenInWei<361906200000000){
              _oneTokenInWei = 361906200000000;
            }


            if(investedAmountOf[msg.sender] == 0) {
                   // A new investor
                   _investorCount = _investorCount.add(1);
            }

            _owoAmount = msg.value.div(_oneTokenInWei);

            balances[msg.sender] = balances[msg.sender].add(_owoAmount);
            _totalSupply = _totalSupply.add(_owoAmount);
            _totalEthCollected = _totalEthCollected.add(msg.value);
            investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(msg.value);

            transfer(_ownerWallet,msg.value);



    }

    function balanceOf(address _owner) constant returns(uint256 balance){

        return balances[_owner];

    }

    event changed(address a);

    function transfer(address _to, uint256 _value) returns(bool success){
        require(
            balances[msg.sender] >= _value
            && _value > 0
            );
            balances[msg.sender].sub(_value);
            balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyOwner returns (bool success){
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value >0

            );

            balances[_from].sub(_value);
            balances[_to].add(_value);
            allowed[_from][msg.sender].sub(_value);
            Transfer(_from,_to,_value);
            return true;
    }

    function getBlockNumber() constant internal returns (uint) {
        return block.number;
    }

    function withdraw() onlyOwner payable{

         assert(_multiSigWallet.send(this.balance));

     }


}