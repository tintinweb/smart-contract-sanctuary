pragma solidity ^0.4.24;

contract BTTSTokenFactory {
	address[] public deployedTokens;
	function numberOfDeployedTokens() public view returns (uint);
	function deployBTTSTokenContract(
        string symbol,
        string name,
        uint8 decimals,
        uint initialSupply,
        bool mintable,
        bool transferable
    ) public returns (address);
}

contract BTTSToken {
	function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool);
	function disableMinting() public;
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint tokens) public returns (bool);
}

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
    require(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }

}

contract Campaign is Ownable {
    using SafeMath for uint256;

    event Topup(address indexed from, address indexed token, uint256 amount);
    event Payment(address indexed from, address indexed to, address indexed token, uint256 amount);
    event Reallocation(address indexed from, address indexed to, address indexed token, uint256 amount);

    //user address => token address => balance
    mapping(address => mapping(address => uint256)) private balances;

    function balance(address _user, address _token) public view returns (uint256) {
        return balances[_user][_token];
    }

    //requires approve on the tokens to be present
    function topup(address _for, address _token, uint256 _amount) public {
        require(ERC20(_token).transferFrom(msg.sender, address(this), _amount));
        updateBalance(_for, _token, _amount);
    }

    //topup account with any tokens supporting ApproveAndCallFallBack
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) public {
        require(ERC20(_token).transferFrom(_from, address(this), _amount));
        updateBalance(_from, _token, _amount);
    }

    function updateBalance(address _for, address _token, uint256 _amount) internal {
        balances[_for][_token] = balances[_for][_token].add(_amount);
        emit Topup(_for, _token, _amount);
    }

    function pay(address _from, address _to, address _token, uint256 _amount) public onlyOwner returns (bool transferred) {
        require(balances[_from][_token] >= _amount);
        balances[_from][_token] = balances[_from][_token].sub(_amount);
        transferred = ERC20(_token).transfer(_to, _amount);
        emit Payment(_from, _to, _token, _amount);
    }
        
    //method to transfer tokens internally between reserve addresses
    function reallocate(address _from, address _to, address _token, uint256 _amount) public onlyOwner returns (bool) {
        require(balances[_from][_token] >= _amount);
        balances[_from][_token] = balances[_from][_token].sub(_amount);
        balances[_to][_token] = balances[_to][_token].add(_amount);
        emit Reallocation(_from, _to, _token, _amount);
        return true;
    }

}


contract CustomCoinMinter is Ownable {
    using SafeMath for uint256;

	//ropsten: &quot;0x29280a0ef3e3df985c6b9dac0cf4108318d98d3b&quot;
	BTTSTokenFactory public bttsFactory;
	ERC20 public gzeCoin;
  	//target wallet for received GZE
  	address public gzeWallet;
  	address public campaign;

	address[] public createdTokens;
	uint256 public numOfCreatedTokens;
	mapping(address => uint256) public tokenRates;
	mapping(address => address) public tokenCreators;
	uint8 public constant decimals = 18;

    event CampaignAddressUpdated(address newAddress);

	constructor(BTTSTokenFactory _bttsFactory, ERC20 _gzeCoin, address _gzeWallet, address _campaign) public {
		owner = msg.sender;
		bttsFactory = _bttsFactory;
		gzeCoin = _gzeCoin;
		gzeWallet = _gzeWallet;
		campaign = _campaign;
	}

	function newToken (
        string _symbol,
        string _name,
        uint _initialSupply,
        address _topupFor,
        uint256 _rate) public onlyOwner returns (address token) {

		require(_rate > 0);

		token = bttsFactory.deployBTTSTokenContract(
			_symbol, _name, decimals, _initialSupply, true, true);

		numOfCreatedTokens = createdTokens.push(token);
		tokenRates[token] = _rate;
		tokenCreators[token] = msg.sender;

		//approve and topup
		ERC20(token).approve(campaign, _initialSupply);
		Campaign(campaign).topup(_topupFor, token, _initialSupply);
	}

	function listCreatedTokens() public view returns (address[]) {
		return createdTokens;
	}

  	//public mint function requires approval for gzeCoins
  	//_gzeValue - amount of gaze tokens to use for minting
  	//will result in (_gzeValue * rate) tokens minted

  	//tokens can be minted by creators by paying with gze (approve)
  	function mintWithGze(BTTSToken _token, uint256 _gzeValue) public returns (bool) {
  		require(tokenCreators[_token] == msg.sender);
  		require(tokenRates[_token] > 0);
  	  	gzeCoin.transferFrom(msg.sender, gzeWallet, _gzeValue);
  	  	_token.mint(msg.sender, _gzeValue.mul(tokenRates[_token]), false);
	
  	  	return true;
  	}

  	function mint(BTTSToken _token, address _for, uint256 _value) public onlyOwner returns (bool) {
  		require(tokenRates[_token] > 0);
  	  	_token.mint(_for, _value, false);
	
  	  	return true;
  	}
	
  	function disableMinting(BTTSToken token) public onlyOwner {
  		token.disableMinting();
  	}
  	
  	function updateCampaign(address _campaign) public onlyOwner {
  		campaign = _campaign;
  		emit CampaignAddressUpdated(campaign);
  	}

}