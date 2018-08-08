pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Token {

    using SafeMath for uint256;

    string public constant name = "Zombie Token";
    string public constant symbol = "ZOB";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, uint256 value, address indexed to, bytes extraData);

    function ERC20Token() public {
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address from, address to, uint256 value) internal {
        // Check if the sender has enough balance
        require(balanceOf[from] >= value);

        // Check for overflow
        require(balanceOf[to] + value > balanceOf[to]);

        // Save this for an amount double check assertion
        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        Transfer(from, to, value);

        // Asserts for duplicate check. Should never fail.
        assert(balanceOf[from].add(balanceOf[to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `value` tokens to `to` from your account
     *
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transfer(address to, uint256 value) public returns (bool success)  {
        _transfer(msg.sender, to, value);
        return true;
    }
    

    /**
     * Transfer tokens from other address
     *
     * Send `value` tokens to `to` in behalf of `from`
     *
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param value the amount to send
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `spender` to spend no more than `value` tokens in your behalf
     *
     * @param spender The address authorized to spend
     * @param value the max amount they can spend
     * @param extraData some extra information to send to the approved contract
     */
    function approve(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, value, spender, extraData);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);

        Transfer(0x0, to, value);
    }
}

contract zombieToken is Ownable, ERC20Token {

    address public invadeAddress;
    address public creatorAddress;
    uint public preMining = 1000000 * 10 ** 18; //for test purpose

    function zombieToken() public {
        balanceOf[msg.sender] = preMining;
        totalSupply = preMining;
    }

    function setInvadeAddr(address addr)public onlyOwner {
        invadeAddress = addr;
    }
    
    function setcreatorAddr(address addr)public onlyOwner {
        creatorAddress = addr;
    }
    
    function mint(address to, uint256 value) public returns (bool success) {
        require(msg.sender==invadeAddress);
        _mint(to, value);
        return true;
    }

    function buyCard(address from, uint256 value) public returns (bool success) {
        require(msg.sender==creatorAddress);
        _transfer(from, creatorAddress, value);
        return true;
    }
}