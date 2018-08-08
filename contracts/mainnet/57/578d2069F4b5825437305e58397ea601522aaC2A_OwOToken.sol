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

contract OwOToken {

    using SafeMath for uint256;

    string public constant symbol = "OWO";
    string public constant name = "OwO.World Token";
    uint public constant decimals = 18;
    address public _multiSigWallet;  // The address to hold the funds donated
    address public owner;
    uint public totalSupply;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // Crowdsale end time has been changed
    event EndsAtChanged(uint endsAt);
    event changed(address a);
    
    function () payable{
        //
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function OwOToken() {
        
        owner = msg.sender;
        totalSupply = 100000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
        _multiSigWallet = 0x6c5140f605a9Add003B3626Aae4f08F41E6c6FfF;

    }

    /* Send coins */
    function transfer(address _to, uint256 _value) returns(bool success){
      require((balanceOf[msg.sender] >= _value) && (balanceOf[_to].add(_value)>balanceOf[_to]));
        balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to].add(_value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
        return true;

    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function setMultiSigWallet(address w) onlyOwner {
        require(w != 0 );

          _multiSigWallet = w;

        changed(msg.sender);
    }
    function getMultiSigWallet() constant returns (address){

        return _multiSigWallet;

    }
    function getMultiSigBalance() constant returns (uint){

        return balanceOf[_multiSigWallet];

    }
    function getTotalSupply() constant returns (uint){

        return totalSupply;

    }
    
    function withdraw() onlyOwner payable{

         assert(_multiSigWallet.send(this.balance));

     }


}