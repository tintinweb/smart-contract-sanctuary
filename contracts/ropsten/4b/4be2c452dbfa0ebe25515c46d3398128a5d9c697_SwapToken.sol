pragma solidity ^0.4.24;


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

contract  SwapToken{
    using SafeMath for uint;
    ERC20 public oldToken;
    ERC20 public newToken;
    address public tokenOwner;

    address public owner;
    bool public swap_able;
    event Swap(address sender, uint amount);
    event SwapAble(bool swapable);

    modifier isOwner() {
        // Only owner is allowed to proceed
        require (msg.sender == owner);
        _;
    }

    // Check SwapAble
    modifier isSwap() {
        require (swap_able);
        _;
    }

    // init Contract
    constructor()
    public
    {
        owner = msg.sender;
        swap_able = false;
    }

    // Setup Token Setup
    function tokenSetup(address _oldToken, address _newToken, address _tokenOwner)
    public
    isOwner
    {
        require(_oldToken != 0 && _newToken != 0 && _tokenOwner != 0);
        oldToken = ERC20(_oldToken);
        newToken = ERC20(_newToken);
        tokenOwner = _tokenOwner;
    }

    // swap start, stop
    function swapAble(bool _swap_able)
    public
    isOwner
    {
        swap_able = _swap_able;
        emit SwapAble(_swap_able);
    }

    // withdraw old token
    function withdrawOldToken(address to, uint amount)
    public
    isOwner
    returns (bool success)
    {
        require(oldToken.transfer(to, amount));
        return true;
    }

    function swapAbleToken()
    public
    constant
    returns (uint256)
    {
        return newToken.allowance(tokenOwner, this);
    }

    function swapToken(uint amount)
    public
    isSwap
    returns (bool success)
    {
        // check allowance newToken
        require(newToken.allowance(tokenOwner, this) >= amount);
        // getBack Token
        require(oldToken.transferFrom(msg.sender, this, amount));
        // swap new Token
        require(newToken.transferFrom(tokenOwner, msg.sender, amount));
        emit Swap(msg.sender, amount);
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public payable {
        revert();
    }
}