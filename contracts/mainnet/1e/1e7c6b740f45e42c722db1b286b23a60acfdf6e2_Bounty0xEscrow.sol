pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 /**
 * @title Contract that will work with ERC223 tokens.
 */

contract ERC223ReceivingContract {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data);
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract Bounty0xEscrow is Ownable, ERC223ReceivingContract {

    using SafeMath for uint256;

    address[] supportedTokens;

    mapping (address => bool) public tokenIsSupported;
    mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)

    event Deposit(address token, address user, uint amount, uint balance);
    event Distribution(address token, address host, address hunter, uint256 amount, uint64 timestamp);


    function Bounty0xEscrow() public {
        address Bounty0xToken = 0xd2d6158683aeE4Cc838067727209a0aAF4359de3;
        supportedTokens.push(Bounty0xToken);
        tokenIsSupported[Bounty0xToken] = true;
    }


    function addSupportedToken(address _token) public onlyOwner {
        require(!tokenIsSupported[_token]);

        supportedTokens.push(_token);
        tokenIsSupported[_token] = true;
    }

    function removeSupportedToken(address _token) public onlyOwner {
        require(tokenIsSupported[_token]);

        for (uint i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == _token) {
                var indexOfLastToken = supportedTokens.length - 1;
                supportedTokens[i] = supportedTokens[indexOfLastToken];
                supportedTokens.length--;
                tokenIsSupported[_token] = false;
                return;
            }
        }
    }

    function getListOfSupportedTokens() view public returns(address[]) {
        return supportedTokens;
    }


    function tokenFallback(address _from, uint _value, bytes _data) public {
        var _token = msg.sender;
        require(tokenIsSupported[_token]);

        tokens[_token][_from] = SafeMath.add(tokens[_token][_from], _value);
        Deposit(_token, _from, _value, tokens[_token][_from]);
    }


    function depositToken(address _token, uint _amount) public {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(_token != address(0));
        require(tokenIsSupported[_token]);

        require(ERC20(_token).transferFrom(msg.sender, this, _amount));
        tokens[_token][msg.sender] = SafeMath.add(tokens[_token][msg.sender], _amount);

        Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }


    function distributeTokenToAddress(address _token, address _host, address _hunter, uint256 _amount) external onlyOwner {
        require(_token != address(0));
        require(_hunter != address(0));
        require(tokenIsSupported[_token]);
        require(tokens[_token][_host] >= _amount);

        tokens[_token][_host] = SafeMath.sub(tokens[_token][_host], _amount);
        require(ERC20(_token).transfer(_hunter, _amount));

        Distribution(_token, _host, _hunter, _amount, uint64(now));
    }

    function distributeTokenToAddressesAndAmounts(address _token, address _host, address[] _hunters, uint256[] _amounts) external onlyOwner {
        require(_token != address(0));
        require(_host != address(0));
        require(_hunters.length == _amounts.length);
        require(tokenIsSupported[_token]);

        uint256 totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(tokens[_token][_host] >= totalAmount);
        tokens[_token][_host] = SafeMath.sub(tokens[_token][_host], totalAmount);

        for (uint i = 0; i < _hunters.length; i++) {
            require(ERC20(_token).transfer(_hunters[i], _amounts[i]));

            Distribution(_token, _host, _hunters[i], _amounts[i], uint64(now));
        }
    }

    function distributeTokenToAddressesAndAmountsWithoutHost(address _token, address[] _hunters, uint256[] _amounts) external onlyOwner {
        require(_token != address(0));
        require(_hunters.length == _amounts.length);
        require(tokenIsSupported[_token]);

        uint256 totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(ERC20(_token).balanceOf(this) >= totalAmount);

        for (uint i = 0; i < _hunters.length; i++) {
            require(ERC20(_token).transfer(_hunters[i], _amounts[i]));

            Distribution(_token, this, _hunters[i], _amounts[i], uint64(now));
        }
    }

}