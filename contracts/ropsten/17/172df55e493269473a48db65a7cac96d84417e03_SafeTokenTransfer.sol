pragma solidity ^0.4.11;


contract ERC20 {
    function totalSupply() public constant returns (uint supply);
    function balanceOf( address who ) public constant returns (uint value);
    function allowance( address owner, address spender ) public constant returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}


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

}

contract SafeTokenTransfer {
    using SafeMath for uint;
    ERC20 public yeedToken;
    address public tokenOwner;
    address public owner;
    event TransferToken(address sender, uint amount);


    modifier isOwner() {
        // Only owner is allowed to proceed
        require (msg.sender == owner);
        _;
    }

    // init Contract
    function SafeTokenTransfer()
    public
    {
        owner = msg.sender;
    }

    // setupToken
    function setupToken(address _token, address _tokenOwner)
    public
    isOwner
    {
        require(_token != 0);
        yeedToken = ERC20(_token);
        tokenOwner = _tokenOwner;
    }

    function transferToken(address receiver, uint tokens)
    public
    isOwner
    {
        // check token balance
        require(yeedToken.balanceOf(receiver) < tokens);
        tokens = tokens.sub(yeedToken.balanceOf(receiver));
        // Send token
        require(yeedToken.transferFrom(tokenOwner, receiver, tokens));
        TransferToken(receiver, tokens);
    }

}