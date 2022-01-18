/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/AirdropGemify.sol

pragma solidity ^0.4.18;




contract Airdrop is Ownable {
    using SafeMath for uint256;
    uint256 public airdropTokens;
    uint256 public totalClaimed;
    uint256 public amountOfTokens;
    mapping (address => bool) public tokensReceived;
    mapping (address => bool) public airdropAgent;
    ERC20 public token;

    function Airdropper(uint256 _amount) public {
        totalClaimed = 0;
        amountOfTokens = _amount;
    }

    // Send a static number of tokens to each user in an array (e.g. each user receives 100 tokens)
    function airdrop(address[] _recipients) public onlyAirdropAgent {        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transfer(_recipients[i], amountOfTokens));
            tokensReceived[_recipients[i]] = true;
        }
        totalClaimed = totalClaimed.add(amountOfTokens * _recipients.length);
    }

    // Send a dynamic number of tokens to each user in an array (e.g. each user receives 10% of their original contribution) 
    function airdropDynamic(address[] _recipients, uint256[] _amount) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
                require(token.transfer(_recipients[i], _amount[i]));
                tokensReceived[_recipients[i]] = true; 
                totalClaimed = totalClaimed.add(_amount[i]);
        } 
    }

    // Allow this agent to call the airdrop functions
    function setAirdropAgent(address _agentAddress, bool state) public onlyOwner {
        airdropAgent[_agentAddress] = state;
    }
    
    // Return any unused tokens back to the contract owner
    function reset() public onlyAirdropAgent {
        require(token.transfer(owner, remainingTokens()));
    }

    // Specify the ERC20 token address
    function setTokenAddress(address _tokenAddress) public onlyAirdropAgent {
        token = ERC20(_tokenAddress);
    }

    // Set the amount of tokens to send each user for a static airdrop
    function setTokenAmount(uint256 _amount) public onlyAirdropAgent {
        amountOfTokens = _amount;
    }

    // Return the amount of tokens that the contract currently holds
    function remainingTokens() public view returns (uint256) {
        return token.balanceOf(this);
    }

    modifier onlyAirdropAgent() {
        require(airdropAgent[msg.sender]);
         _;
        
    }
}