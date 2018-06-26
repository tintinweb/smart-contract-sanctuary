pragma solidity ^0.4.24;
/// @title ERC20 Interface
/// @author info@yggdrash.io

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
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
    constructor()
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
        emit TransferToken(receiver, tokens);
    }

}