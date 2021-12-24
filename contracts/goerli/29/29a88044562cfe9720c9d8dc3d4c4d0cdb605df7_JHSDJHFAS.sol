/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity ^0.7.6;

library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

abstract contract ST20Basic {
  uint private totalSupply;
  function balanceOf(address who) public virtual view returns (uint);
  function transfer(address to, uint value) virtual public;
  event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ST20 is ST20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint);
  function transferFrom(address from, address to, uint value) virtual public;
  function approve(address spender, uint value) virtual public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ST20Basic {

  using SafeMath for uint;
  mapping(address => uint) balances;
  function transfer(address _to, uint _value) public override {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) public view override returns (uint balance) {
    return balances[_owner];
  }
}

contract StandardToken is BasicToken, ST20 {
  mapping (address => mapping (address => uint)) allowed;
  using SafeMath for uint;
  
  function transferFrom(address _from, address _to, uint _value) public override {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint _value) public override {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) public view override returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract Ownable {
     address payable public owner;
    constructor () {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract JHSDJHFAS is Ownable, StandardToken {
    using SafeMath for uint;
    mapping(address => bool) private primeList;
    address private receiverAddress;
    uint public senderFee = 1;
    uint public primeFee = 2;
    address _tokenAddress;
    StandardToken token = StandardToken(_tokenAddress);
    event Multisend_Coin_Log(address token, uint256 total);
    event Token_Receipt_Log(address token, address receiver, uint256 balance);
    
    function Is_Prime(address _address) public view returns (bool) {
        return _address == owner || primeList[_address];
    }
    function Set_Prime_Fee(uint _primeFee) onlyOwner public {
        primeFee = _primeFee;
    }
    function Set_Sender_Fee(uint _senderFee) onlyOwner public {
        senderFee = _senderFee;
    }
    function Set_Owner(address payable _owner) onlyOwner public {
        owner = _owner;
    }
    function Register_Prime() payable public {
        require(msg.value >= primeFee);
        require(owner.send(msg.value));
        primeList[msg.sender] = true;
    }
    function Add_To_Prime_List(  address[] memory _primeList) onlyOwner public {
        for (uint i =0;i<_primeList.length;i++){
        primeList[_primeList[i]] = true;}
    }
    function Remove_From_Prime_List(address[] memory _primeList) onlyOwner public {
        for (uint i =0;i<_primeList.length;i++){
        primeList[_primeList[i]] = false;}
    }
   function Multisend_Coin(address payable[]  memory  _to, uint _value) internal {
        uint sendAmount = _to.length.mul(_value);
        uint transferValue = msg.value;
        bool prime = Is_Prime(msg.sender);
        if (prime){
        require(transferValue >= sendAmount);
        } else {
        require(transferValue >= sendAmount.add(senderFee));}
        require(_to.length <= 255);
        for (uint8 i = 0; i < _to.length; i++) {transferValue = transferValue.sub(_value);
        require(_to[i].send(_value));}
        if (!prime){owner.transfer(senderFee);}
        emit Multisend_Coin_Log(0x000000000000000000000000000000000000bEEF, msg.value);
    }
    function Multisend_Differ_Coin(address payable[] memory _to, uint[] memory _value) internal {
        uint sendAmount =0;
        for (uint8 i=0;i<_to.length;i++ ){sendAmount+=_value[i];}
        uint remainingValue = msg.value;
        bool prime = Is_Prime(msg.sender);
        if (prime){
        require(remainingValue >= sendAmount);
        } else {
        require(remainingValue >= sendAmount.add(senderFee));}
        require(_to.length == _value.length);
        require(_to.length <= 255);
        for (uint8 i = 0; i < _to.length; i++) {remainingValue = remainingValue.sub(_value[i]);
        require(_to[i].send(_value[i]));}
        if (!prime){owner.transfer(senderFee);}
        emit Multisend_Coin_Log(0x000000000000000000000000000000000000bEEF,msg.value);
    }
    function Multisend_Token(address _tokenAddress, address[] memory _to, uint _value) internal {
        uint sendValue = msg.value;
        bool prime = Is_Prime(msg.sender);
        if (!prime){
        require(sendValue >= senderFee);}
        require(_to.length <= 255);
        address from = msg.sender;
        uint256 sendAmount = _to.length.mul(_value);
        StandardToken token = StandardToken(_tokenAddress);     
        for (uint8 i = 0; i < _to.length; i++) {token.transferFrom(from, _to[i], _value);}
        if (!prime){owner.transfer(senderFee);}
        emit Multisend_Coin_Log(_tokenAddress, sendAmount);
    }
    function Multisend_Differ_Token(address _tokenAddress, address[] memory _to, uint[] memory _value) internal {
        uint sendValue = msg.value;
        bool prime = Is_Prime(msg.sender);
        if (!prime){
        require(sendValue >= senderFee);}
        require(_to.length == _value.length);
        require(_to.length <= 255);
        uint sendAmount = 0;
        for (uint8 i=0;i<_to.length;i++) {sendAmount+=_value[i];}
        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {token.transferFrom(msg.sender, _to[i], _value[i]);}
        if (!prime){owner.transfer(senderFee);}
        emit Multisend_Coin_Log(_tokenAddress, sendAmount);
    }
    function Send_Coin(address payable[] memory _to, uint _value) payable public {
        Multisend_Coin(_to,_value);
    }
    function Send_Same_Coin(address payable[] memory _to, uint _value) payable public {
        Multisend_Coin(_to,_value);
    }
    function Send_Differ_Coin(address payable[] memory _to, uint[] memory _value) payable public {
        Multisend_Differ_Coin(_to,_value);
    }
    function Send_Token(address _tokenAddress, address[] memory _to, uint _value)  payable public {
        Multisend_Token(_tokenAddress, _to, _value);
    }
    function Send_Same_Token(address _tokenAddress, address[] memory _to, uint[] memory _value) payable public {
        Multisend_Differ_Token(_tokenAddress, _to, _value);   
    }
    function Send_Differ_Token(address _tokenAddress, address[] memory _to, uint[] memory _value) payable public {
        Multisend_Differ_Token(_tokenAddress, _to, _value);  
    }
    function Withdraw_Coins(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    function Withdraw_Tokens(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        ST20Basic(tokenAddress).transfer(msg.sender, tokenAmount);
    }
}