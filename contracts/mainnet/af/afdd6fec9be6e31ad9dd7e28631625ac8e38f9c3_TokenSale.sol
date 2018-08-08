pragma solidity ^0.4.21;

contract EIP20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is
 * called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Owanble() public{
    owner = msg.sender;
  }

  // Modifier onlyOwner prevents function from running
  // if it is called by anyone other than the owner

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Function transferOwnership allows owner to change ownership.
  // Before the appying changes it checks if the owner
  // called this function and if the address is not 0x0.

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted = false;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract TokenSale is Haltable {
    using SafeMath for uint;

    string public name = "TokenSale Contract";

    // Constants
    EIP20Interface public token;
    address public beneficiary;
    address public reserve;
    uint public price = 0; // in wei

    // Counters
    uint public tokensSoldTotal = 0; // in wei
    uint public weiRaisedTotal = 0; // in wei
    uint public investorCount = 0;

    event NewContribution(
        address indexed holder,
        uint256 tokenAmount,
        uint256 etherAmount);

    function TokenSale(
        ) public {
            
        // Grant owner rights to deployer of a contract
        owner = msg.sender;
        
        // Set token address and initialize constructor
        token = EIP20Interface(address(0x2F7823AaF1ad1dF0D5716E8F18e1764579F4ABe6));
        
        // Set beneficiary address to receive ETH
        beneficiary = address(0xf2b9DA535e8B8eF8aab29956823df7237f1863A3);
        
        // Set reserve address to receive ETH
        reserve = address(0x966c0FD16a4f4292E6E0372e04fbB5c7013AD02e);
        
        // Set price of 1 token
        price = 0.00379 ether;
    }

    function changeBeneficiary(address _beneficiary) public onlyOwner stopInEmergency {
        beneficiary = _beneficiary;
    }
    
    function changeReserve(address _reserve) public onlyOwner stopInEmergency {
        reserve = _reserve;
    }
    
    function changePrice(uint _price) public onlyOwner stopInEmergency {
        price = _price;
    }

    function () public payable stopInEmergency {
        
        // require min limit of contribution
        require(msg.value >= price);
        
        // calculate token amount
        uint tokens = msg.value / price;
        
        // throw if you trying to buy over the token exists
        require(token.balanceOf(this) >= tokens);
        
        // recalculate counters
        tokensSoldTotal = tokensSoldTotal.add(tokens);
        if (token.balanceOf(msg.sender) == 0) investorCount++;
        weiRaisedTotal = weiRaisedTotal.add(msg.value);
        
        // transfer bought tokens to the contributor 
        token.transfer(msg.sender, tokens);

        // 100% / 10 = 10%
        uint reservePie = msg.value.div(10);
        
        // 100% - 10% = 90%
        uint beneficiaryPie = msg.value.sub(reservePie);

        // transfer funds to the reserve address
        reserve.transfer(reservePie);

        // transfer funds to the beneficiary address
        beneficiary.transfer(beneficiaryPie);

        emit NewContribution(msg.sender, tokens, msg.value);
    }
    
    
    // Withdraw any accidently sent to the contract ERC20 tokens.
    // Can be performed only by the owner.
    function withdrawERC20Token(address _token) public onlyOwner stopInEmergency {
        ERC20 foreignToken = ERC20(_token);
        foreignToken.transfer(msg.sender, foreignToken.balanceOf(this));
    }
    
    // Withdraw any accidently sent to the contract EIP20 tokens.
    // Can be performed only by the owner.
    function withdrawEIP20Token(address _token) public onlyOwner stopInEmergency {
        EIP20Interface foreignToken = EIP20Interface(_token);
        foreignToken.transfer(msg.sender, foreignToken.balanceOf(this));
    }
    
    // Withdraw all not sold tokens.
    // Can be performed only by the owner.
    function withdrawToken() public onlyOwner stopInEmergency {
        token.transfer(msg.sender, token.balanceOf(this));
    }
    
    // Get the contract token balance
    function tokensRemaining() public constant returns (uint256) {
        return token.balanceOf(this);
    }
    
}