pragma solidity ^0.4.0;

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

contract CappedSale is AbstractSale {
    uint256 public cap;
    uint256 public initialCap;

    function CappedSale(uint256 _cap) public {
        cap = _cap;
        initialCap = _cap;
    }

    function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
        super.checkPurchaseValid(buyer, sold, bonus);
        require(cap >= sold);
    }

    function onPurchase(address buyer, address token, uint256 value, uint256 sold, uint256 bonus) internal {
        super.onPurchase(buyer, token, value, sold, bonus);
        cap = cap.sub(sold);
    }
}

contract PeriodSale is AbstractSale {
	uint256 public start;
	uint256 public end;

	function PeriodSale(uint256 _start, uint256 _end) public {
		start = _start;
		end = _end;
	}

	function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
		super.checkPurchaseValid(buyer, sold, bonus);
		require(now > start && now < end);
	}
}

contract Eticket4Sale is MintingSale, PeriodSale, OwnableImpl, CappedSale {
    address public btcToken;

    uint256 public btcEthRate = 10 * 10**10;
    uint256 public constant ethEt4Rate = 1000 * 10**18;

    function Eticket4Sale(
        address _mintableToken,
        address _btcToken,
        uint256 _start,
        uint256 _end,
        uint256 _cap)
    MintingSale(_mintableToken)
    PeriodSale(_start, _end)
    CappedSale(_cap) {
        btcToken = _btcToken;
        RateAdd(address(0));
        RateAdd(_btcToken);
    }

    function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
        super.checkPurchaseValid(buyer, sold, bonus);
        require(now > start && now < end);
    }

    function getRate(address _token) constant public returns (uint256) {
        if (_token == btcToken) {
            return btcEthRate * ethEt4Rate;
        } else if (_token == address(0)) {
            return ethEt4Rate;
        } else {
            return 0;
        }
    }

    event BtcEthRateChange(uint256 btcEthRate);

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

    function transferWithBonus(address beneficiary, uint256 amount) onlyOwner public {
        uint256 bonus = getBonus(amount);
        doPurchase(beneficiary, amount, bonus);
        Purchase(beneficiary, address(1), 0, amount, bonus);
        onPurchase(beneficiary, address(1), 0, amount, bonus);
    }

    function transfer(address beneficiary, uint256 amount) onlyOwner public {
        doPurchase(beneficiary, amount, 0);
        Purchase(beneficiary, address(1), 0, amount, 0);
        onPurchase(beneficiary, address(1), 0, amount, 0);
    }
}

contract DaoxCommissionSale is AbstractSale {
	function getSold(address _token, uint256 _value) constant public returns (uint256) {
		return super.getSold(_token, _value).div(99).mul(100);
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

contract PublicSale is SecuredImpl, Whitelist, Eticket4Sale, DaoxCommissionSale {
	function PublicSale(
		address _mintableToken,
		address _btcToken,
		uint256 _start,
		uint256 _end,
		uint256 _cap)
	Eticket4Sale(_mintableToken, _btcToken, _start, _end, _cap) {

	}

	function getBonus(uint256 sold) constant public returns (uint256) {
		return getTimeBonus(sold) + getAmountBonus(sold);
	}

	function getTimeBonus(uint256 sold) internal returns (uint256) {
		uint256 interval = (now - start) / (86400 * 5);
		if (interval == 0) {
			return sold.mul(6).div(100);
		} else if (interval == 1) {
			return sold.mul(4).div(100);
		} else if (interval == 2 || interval == 3) {
			return sold.mul(3).div(100);
		} else {
			return sold.mul(1).div(100);
		}
	}

	function getAmountBonus(uint256 sold) internal returns (uint256) {
		if (sold > 20000 * 10 ** 18) {
			return sold.mul(25).div(100);
		} else if (sold > 15000 * 10 ** 18) {
			return sold.mul(20).div(100);
		} else if (sold > 10000 * 10 ** 18) {
			return sold.mul(15).div(100);
		} else if (sold > 5000 * 10 ** 18) {
			return sold.mul(10).div(100);
		} else if (sold > 1000 * 10 ** 18) {
			return sold.mul(5).div(100);
		} else {
			return 0;
		}
	}

	function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
		super.checkPurchaseValid(buyer, sold, bonus);
		if (sold >= 10000 * 10 ** 18) {
			require(isInWhitelist(buyer));
		}
	}
}