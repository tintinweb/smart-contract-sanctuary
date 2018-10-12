pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function() public payable { }
}

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

contract ESCBAirdropper is Ownable {
    using SafeMath for uint256;
    uint256 public airdropTokens;
    uint256 public totalClaimed;
    uint256 public amountOfTokens;
    mapping (address => bool) public tokensReceived;
    mapping (address => bool) public craneList;
    mapping (address => bool) public airdropAgent;
    ERC20 public token;
    bool public craneEnabled = false;

    modifier onlyAirdropAgent() {
        require(airdropAgent[msg.sender]);
         _;
    }

    modifier whenCraneEnabled() {
        require(craneEnabled);
         _;
    }

    function ESCBAirdropper(uint256 _amount, address _tokenAddress) public {
        totalClaimed = 0;
        amountOfTokens = _amount;
        token = ERC20(_tokenAddress);
    }

    // Send a static number of tokens to each user in an array (e.g. each user receives 100 tokens)
    function airdrop(address[] _recipients) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]); // Probably a race condition between two transactions. Bail to avoid double allocations and to save the gas.
            require(token.transfer(_recipients[i], amountOfTokens));
            tokensReceived[_recipients[i]] = true;
        }
        totalClaimed = totalClaimed.add(amountOfTokens * _recipients.length);
    }

    // Send a dynamic number of tokens to each user in an array (e.g. each user receives 10% of their original contribution)
    function airdropDynamic(address[] _recipients, uint256[] _amount) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]); // Probably a race condition between two transactions. Bail to avoid double allocations and to save the gas.
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
    function reset() public onlyOwner {
        require(token.transfer(owner, remainingTokens()));
    }

    // Change the ERC20 token address
    function changeTokenAddress(address _tokenAddress) public onlyOwner {
        token = ERC20(_tokenAddress);
    }

    // Set the amount of tokens to send each user for a static airdrop
    function changeTokenAmount(uint256 _amount) public onlyOwner {
        amountOfTokens = _amount;
    }

    // Enable or disable crane
    function changeCraneStatus(bool _status) public onlyOwner {
        craneEnabled = _status;
    }

    // Return the amount of tokens that the contract currently holds
    function remainingTokens() public view returns (uint256) {
        return token.balanceOf(this);
    }

    // Add recipient in crane list
    function addAddressToCraneList(address[] _recipients) public onlyAirdropAgent {
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(!tokensReceived[_recipients[i]]); // If not received yet
            require(!craneList[_recipients[i]]);
            craneList[_recipients[i]] = true;
        }
    }

    // Get free tokens by crane
    function getFreeTokens() public
      whenCraneEnabled
    {
        require(craneList[msg.sender]);
        require(!tokensReceived[msg.sender]); // Probably a race condition between two transactions. Bail to avoid double allocations and to save the gas.
        require(token.transfer(msg.sender, amountOfTokens));
        tokensReceived[msg.sender] = true;
        totalClaimed = totalClaimed.add(amountOfTokens);
    }

}