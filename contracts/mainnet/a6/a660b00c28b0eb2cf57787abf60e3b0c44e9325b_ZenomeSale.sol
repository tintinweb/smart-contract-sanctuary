pragma solidity ^0.4.18;

/**
 * @title Read-only ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ReadOnlyToken {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token is ReadOnlyToken {
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableToken is Token {
    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) public returns (bool);
}

/**
 * @title Sale contract for Daonomic platform should implement this
 */
contract Sale {
    /**
     * @dev This event should be emitted when user buys something
     */
    event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus);
    /**
     * @dev Should be emitted if new payment method added
     */
    event RateAdd(address token);
    /**
     * @dev Should be emitted if payment method removed
     */
    event RateRemove(address token);

    /**
     * @dev Calculate rate for specified payment method
     */
    function getRate(address token) constant public returns (uint256);
    /**
     * @dev Calculate current bonus in tokens
     */
    function getBonus(uint256 sold) constant public returns (uint256);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev this version copied from zeppelin-solidity, constant changed to pure
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
 * @title Ownable
 * @dev Adds onlyOwner modifier. Subcontracts should implement checkOwner to check if caller is owner.
 */
contract Ownable {
    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal;
}

/**
 * @title Token represents some external value (for example, BTC)
 */
contract ExternalToken is Token {
    event Mint(address indexed to, uint256 value, bytes data);
    event Burn(address indexed burner, uint256 value, bytes data);

    function burn(uint256 _value, bytes _data) public;
}

/**
 * @dev This adapter helps to receive tokens. It has some subcontracts for different tokens:
 *   ERC20ReceiveAdapter - for receiving simple ERC20 tokens
 *   ERC223ReceiveAdapter - for receiving ERC223 tokens
 *   ReceiveApprovalAdapter - for receiving ERC20 tokens when token notifies receiver with receiveApproval
 *   EtherReceiveAdapter - for receiving ether (onReceive callback will be used). this is needed for handling ether like tokens
 *   CompatReceiveApproval - implements all these adapters
 */
contract ReceiveAdapter {

    /**
     * @dev Receive tokens from someone. Owner of the tokens should approve first
     */
    function onReceive(address _token, address _from, uint256 _value, bytes _data) internal;
}

/**
 * @dev Helps to receive ERC20-complaint tokens. Owner should call token.approve first
 */
contract ERC20ReceiveAdapter is ReceiveAdapter {
    function receive(address _token, uint256 _value, bytes _data) public {
        Token token = Token(_token);
        token.transferFrom(msg.sender, this, _value);
        onReceive(_token, msg.sender, _value, _data);
    }
}

/**
 * @title ERC223 TokenReceiver interface
 * @dev see https://github.com/ethereum/EIPs/issues/223
 */
contract TokenReceiver {
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public;
}

/**
 * @dev Helps to receive ERC223-complaint tokens. ERC223 Token contract should notify receiver.
 */
contract ERC223ReceiveAdapter is TokenReceiver, ReceiveAdapter {
    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        onReceive(msg.sender, _from, _value, _data);
    }

    function onTokenTransfer(address _from, uint256 _value, bytes _data) public {
        onReceive(msg.sender, _from, _value, _data);
    }
}

contract EtherReceiver {
	function receiveWithData(bytes _data) payable public;
}

contract EtherReceiveAdapter is EtherReceiver, ReceiveAdapter {
    function () payable public {
        receiveWithData("");
    }

    function receiveWithData(bytes _data) payable public {
        onReceive(address(0), msg.sender, msg.value, _data);
    }
}

/**
 * @dev This ReceiveAdapter supports all possible tokens
 */
contract CompatReceiveAdapter is ERC20ReceiveAdapter, ERC223ReceiveAdapter, EtherReceiveAdapter {

}

contract AbstractSale is Sale, CompatReceiveAdapter, Ownable {
    using SafeMath for uint256;

    event Withdraw(address token, address to, uint256 value);
    event Burn(address token, uint256 value, bytes data);

    function onReceive(address _token, address _from, uint256 _value, bytes _data) internal {
        uint256 sold = getSold(_token, _value);
        require(sold > 0);
        uint256 bonus = getBonus(sold);
        address buyer;
        if (_data.length == 20) {
            buyer = address(toBytes20(_data, 0));
        } else {
            require(_data.length == 0);
            buyer = _from;
        }
        checkPurchaseValid(buyer, sold, bonus);
        doPurchase(buyer, sold, bonus);
        Purchase(buyer, _token, _value, sold, bonus);
        onPurchase(buyer, _token, _value, sold, bonus);
    }

    function getSold(address _token, uint256 _value) constant public returns (uint256) {
        uint256 rate = getRate(_token);
        require(rate > 0);
        return _value.mul(rate).div(10**18);
    }

    function getBonus(uint256 sold) constant public returns (uint256);

    function getRate(address _token) constant public returns (uint256);

    function doPurchase(address buyer, uint256 sold, uint256 bonus) internal;

    function checkPurchaseValid(address /*buyer*/, uint256 /*sold*/, uint256 /*bonus*/) internal {

    }

    function onPurchase(address /*buyer*/, address /*token*/, uint256 /*value*/, uint256 /*sold*/, uint256 /*bonus*/) internal {

    }

    function toBytes20(bytes b, uint256 _start) pure internal returns (bytes20 result) {
        require(_start + 20 <= b.length);
        assembly {
            let from := add(_start, add(b, 0x20))
            result := mload(from)
        }
    }

    function withdrawEth(address _to, uint256 _value) onlyOwner public {
        withdraw(address(0), _to, _value);
    }

    function withdraw(address _token, address _to, uint256 _value) onlyOwner public {
        require(_to != address(0));
        verifyCanWithdraw(_token, _to, _value);
        if (_token == address(0)) {
            _to.transfer(_value);
        } else {
            Token(_token).transfer(_to, _value);
        }
        Withdraw(_token, _to, _value);
    }

    function verifyCanWithdraw(address token, address to, uint256 amount) internal;

    function burnWithData(address _token, uint256 _value, bytes _data) onlyOwner public {
        ExternalToken(_token).burn(_value, _data);
        Burn(_token, _value, _data);
    }
}

/**
 * @title This sale mints token when user sends accepted payments
 */
contract MintingSale is AbstractSale {
    MintableToken public token;

    function MintingSale(address _token) public {
        token = MintableToken(_token);
    }

    function doPurchase(address buyer, uint256 sold, uint256 bonus) internal {
        token.mint(buyer, sold.add(bonus));
    }

    function verifyCanWithdraw(address, address, uint256) internal {

    }
}

/**
 * @title OwnableImpl
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableImpl is Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function OwnableImpl() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function checkOwner() internal {
        require(msg.sender == owner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract CappedBonusSale is AbstractSale {
    uint256 public cap;
    uint256 public initialCap;

    function CappedBonusSale(uint256 _cap) public {
        cap = _cap;
        initialCap = _cap;
    }

    function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
        super.checkPurchaseValid(buyer, sold, bonus);
        require(cap >= sold.add(bonus));
    }

    function onPurchase(address buyer, address token, uint256 value, uint256 sold, uint256 bonus) internal {
        super.onPurchase(buyer, token, value, sold, bonus);
        cap = cap.sub(sold).sub(bonus);
    }
}

/**
 * @title Secured
 * @dev Adds only(role) modifier. Subcontracts should implement checkRole to check if caller is allowed to do action.
 */
contract Secured {
    modifier only(string role) {
        require(msg.sender == getRole(role));
        _;
    }

    function getRole(string role) constant public returns (address);
}

contract SecuredImpl is Ownable, Secured {
	mapping(string => address) users;
	event RoleTransferred(address indexed previousUser, address indexed newUser, string role);

	function getRole(string role) constant public returns (address) {
		return users[role];
	}

	function transferRole(string role, address to) onlyOwner public {
		require(to != address(0));
		RoleTransferred(users[role], to, role);
		users[role] = to;
	}
}

contract Whitelist is Secured {
	mapping(address => bool) whitelist;
	event WhitelistChange(address indexed addr, bool allow);

	function isInWhitelist(address addr) constant public returns (bool) {
		return whitelist[addr];
	}

	function setWhitelist(address addr, bool allow) only("operator") public {
		setWhitelistInternal(addr, allow);
	}

	function setWhitelistInternal(address addr, bool allow) internal {
		whitelist[addr] = allow;
		WhitelistChange(addr, allow);
	}
}

contract WhitelistSale is AbstractSale, Whitelist {
	function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
		super.checkPurchaseValid(buyer, sold, bonus);
		require(isInWhitelist(buyer));
	}
}

contract DaoxCommissionSale is AbstractSale {
	function getSold(address _token, uint256 _value) constant public returns (uint256) {
		return super.getSold(_token, _value).div(99).mul(100);
	}
}

contract ReadOnlyTokenImpl is ReadOnlyToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TokenImpl is Token, ReadOnlyTokenImpl {
  using SafeMath for uint256;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emitTransfer(msg.sender, _to, _value);
    return true;
  }

  function emitTransfer(address _from, address _to, uint256 _value) internal {
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emitTransfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is Token {
	event Burn(address indexed burner, uint256 value);
	function burn(uint256 _value) public;
}

contract BurnableTokenImpl is TokenImpl, BurnableToken {
	/**
	 * @dev Burns a specific amount of tokens.
	 * @param _value The amount of token to be burned.
	 */
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		// no need to require value <= totalSupply, since that would imply the
		// sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
	}
}

contract MintableTokenImpl is Ownable, TokenImpl, MintableToken {
    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emitMint(_to, _amount);
        emitTransfer(address(0), _to, _amount);
        return true;
    }

    function emitMint(address _to, uint256 _value) internal {
        Mint(_to, _value);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract PausableToken is Pausable, TokenImpl {

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}

contract ZenomeToken is OwnableImpl, PausableToken, MintableTokenImpl, BurnableTokenImpl {
	string public constant name = "Zenome";
	string public constant symbol = "sZNA";
	uint8 public constant decimals = 18;

	function burn(uint256 _value) public whenNotPaused {
		super.burn(_value);
	}
}

contract ZenomeSale is OwnableImpl, SecuredImpl, DaoxCommissionSale, MintingSale, CappedBonusSale, WhitelistSale {
	address public btcToken;
	uint256 public ethRate = 1350 * 10**18;
	uint256 public btcEthRate = 10 * 10**10;

	function ZenomeSale(
		address _mintableToken,
		address _btcToken,
		uint256 _cap)
	MintingSale(_mintableToken)
	CappedBonusSale(_cap) {
		btcToken = _btcToken;
		RateAdd(address(0));
		RateAdd(_btcToken);
	}

	function getRate(address _token) constant public returns (uint256) {
		if (_token == btcToken) {
			return btcEthRate * ethRate;
		} else if (_token == address(0)) {
			return ethRate;
		} else {
			return 0;
		}
	}

	function getBonus(uint256 sold) constant public returns (uint256) {
		if (sold > 850000 * 10**18) {
			return sold.mul(50).div(100);
		} else if (sold > 340000 * 10**18) {
			return sold.mul(33).div(100);
		} else if (sold > 85000 * 10**18) {
			return sold.mul(20).div(100);
		} else {
			return 0;
		}
	}

	event EthRateChange(uint256 rate);

	function setEthRate(uint256 _ethRate) onlyOwner public {
		ethRate = _ethRate;
		EthRateChange(_ethRate);
	}

	event BtcEthRateChange(uint256 rate);

	function setBtcEthRate(uint256 _btcEthRate) onlyOwner public {
		btcEthRate = _btcEthRate;
		BtcEthRateChange(_btcEthRate);
	}

	function withdrawBtc(bytes _to, uint256 _value) onlyOwner public {
		burnWithData(btcToken, _value, _to);
	}

	function transferTokenOwnership(address newOwner) onlyOwner public {
		OwnableImpl(token).transferOwnership(newOwner);
	}

	function pauseToken() onlyOwner public {
		Pausable(token).pause();
	}

	function unpauseToken() onlyOwner public {
		Pausable(token).unpause();
	}

	function transfer(address beneficiary, uint256 amount) onlyOwner public {
		emulatePurchase(beneficiary, address(1), 0, amount, 0);
	}

	function emulatePurchase(address beneficiary, address paymentMethod, uint256 value, uint256 amount, uint256 bonus) onlyOwner public {
		setWhitelistInternal(beneficiary, true);
		doPurchase(beneficiary, amount, bonus);
		Purchase(beneficiary, paymentMethod, value, amount, bonus);
		onPurchase(beneficiary, paymentMethod, value, amount, bonus);
	}
}