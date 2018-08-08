pragma solidity ^0.4.18;

contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}

contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);
    }
}

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
		uint256 c = a / b;
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

contract Ownable {
	address public owner;


	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

contract TriggmineToken is StandardToken, BurnableToken, Ownable {

	string public constant name = "Triggmine Coin";

	string public constant symbol = "TRG";

	uint256 public constant decimals = 18;

	bool public released = false;
	event Release();

	address public holder;

	mapping(address => uint) public lockedAddresses;

	modifier isReleased () {
		require(released || msg.sender == holder || msg.sender == owner);
		require(lockedAddresses[msg.sender] <= now);
		_;
	}

	function TriggmineToken() public {
		owner = 0x7E83f1F82Ab7dDE49F620D2546BfFB0539058414;

		totalSupply_ = 620000000 * (10 ** decimals);
		balances[owner] = totalSupply_;
		Transfer(0x0, owner, totalSupply_);

		holder = owner;
	}

	function lockAddress(address _lockedAddress, uint256 _time) public onlyOwner returns (bool) {
		require(balances[_lockedAddress] == 0 && lockedAddresses[_lockedAddress] == 0 && _time > now);
		lockedAddresses[_lockedAddress] = _time;
		return true;
	}

	function release() onlyOwner public returns (bool) {
		require(!released);
		released = true;
		Release();

		return true;
	}

	function getOwner() public view returns (address) {
		return owner;
	}

	function transfer(address _to, uint256 _value) public isReleased returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public isReleased returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}

	function transferOwnership(address newOwner) public onlyOwner {
		address oldOwner = owner;
		super.transferOwnership(newOwner);

		if (oldOwner != holder) {
			allowed[holder][oldOwner] = 0;
			Approval(holder, oldOwner, 0);
		}

		if (owner != holder) {
			allowed[holder][owner] = balances[holder];
			Approval(holder, owner, balances[holder]);
		}
	}

}

contract TriggminePresale is Ownable {
    uint public constant SALES_START = 1523890800;
    uint public constant SALES_END = 1525100400; 

    address public constant ASSET_MANAGER_WALLET = 0x7E83f1F82Ab7dDE49F620D2546BfFB0539058414;
    address public constant ESCROW_WALLET = 0x2e9F22E2D559d9a5ce234AB722bc6e818FA5D079;

    address public constant TOKEN_ADDRESS = 0x98F319D4dc58315796Ec8F06274fe2d4a5A69721; 
    uint public constant TOKEN_CENTS = 1000000000000000000;
    uint public constant TOKEN_PRICE = 0.0001 ether;

    uint public constant ETH_HARD_CAP = 3000 ether;
    uint public constant SALE_MAX_CAP = 36000000 * TOKEN_CENTS;

    uint public constant BONUS_WL = 20;
    uint public constant BONUS_2_DAYS = 20;
    uint public constant BONUS_3_DAYS = 19;
    uint public constant BONUS_4_DAYS = 18;
    uint public constant BONUS_5_DAYS = 17;
    uint public constant BONUS_6_DAYS = 16;
    uint public constant BONUS_15_DAYS = 15;

    uint public saleContributions;
    uint public tokensPurchased;

    address public whitelistSupplier;
    mapping(address => bool) public whitelistPrivate;
    mapping(address => bool) public whitelistPublic;

    event Contributed(address receiver, uint contribution, uint reward);
    event PrivateWhitelistUpdated(address participant, bool isWhitelisted);
    event PublicWhitelistUpdated(address participant, bool isWhitelisted);

    function TriggminePresale() public {
        whitelistSupplier = msg.sender;
        owner = ASSET_MANAGER_WALLET;
    }

    modifier onlyWhitelistSupplier() {
        require(msg.sender == whitelistSupplier || msg.sender == owner);
        _;
    }

    function contribute() public payable returns(bool) {
        return contributeFor(msg.sender);
    }

    function contributeFor(address _participant) public payable returns(bool) {
        require(now < SALES_END);
        require(saleContributions < ETH_HARD_CAP);

        uint bonusPercents = 0;
        if (now < SALES_START) { 
            require(whitelistPrivate[_participant]);
            bonusPercents = BONUS_WL;
        } else if (now < SALES_START + 1 days) { 
            require(whitelistPublic[_participant] || whitelistPrivate[_participant]);
            bonusPercents = BONUS_WL;
        } else if (now < SALES_START + 2 days) {
            bonusPercents = BONUS_2_DAYS;
        } else if (now < SALES_START + 3 days) {
            bonusPercents = BONUS_3_DAYS;
        } else if (now < SALES_START + 4 days) {
            bonusPercents = BONUS_4_DAYS;
        } else if (now < SALES_START + 5 days) {
            bonusPercents = BONUS_5_DAYS;
        } else if (now < SALES_START + 6 days) {
            bonusPercents = BONUS_6_DAYS;
        } else if (now < SALES_START + 15 days) {
            bonusPercents = BONUS_15_DAYS;
        }

        uint tokensAmount = (msg.value * TOKEN_CENTS) / TOKEN_PRICE;
        require(tokensAmount > 0);
        uint bonusTokens = (tokensAmount * bonusPercents) / 100;
        uint totalTokens = tokensAmount + bonusTokens;

        tokensPurchased += totalTokens;
        require(tokensPurchased <= SALE_MAX_CAP);
        require(TriggmineToken(TOKEN_ADDRESS).transferFrom(ASSET_MANAGER_WALLET, _participant, totalTokens));
        saleContributions += msg.value;
        ESCROW_WALLET.transfer(msg.value);

        Contributed(_participant, msg.value, totalTokens);
        return true;
    }

    function addToPrivateWhitelist(address _participant) onlyWhitelistSupplier() public returns(bool) {
        if (whitelistPrivate[_participant]) {
            return true;
        }
        whitelistPrivate[_participant] = true;
        PrivateWhitelistUpdated(_participant, true);
        return true;
    }

    function removeFromPrivateWhitelist(address _participant) onlyWhitelistSupplier() public returns(bool) {
        if (!whitelistPrivate[_participant]) {
            return true;
        }
        whitelistPrivate[_participant] = false;
        PrivateWhitelistUpdated(_participant, false);
        return true;
    }

    function addToPublicWhitelist(address _participant) onlyWhitelistSupplier() public returns(bool) {
        if (whitelistPublic[_participant]) {
            return true;
        }
        whitelistPublic[_participant] = true;
        PublicWhitelistUpdated(_participant, true);
        return true;
    }

    function removeFromPublicWhitelist(address _participant) onlyWhitelistSupplier() public returns(bool) {
        if (!whitelistPublic[_participant]) {
            return true;
        }
        whitelistPublic[_participant] = false;
        PublicWhitelistUpdated(_participant, false);
        return true;
    }

    function getTokenOwner() public view returns (address) {
        return TriggmineToken(TOKEN_ADDRESS).getOwner();
    }

    function restoreTokenOwnership() public onlyOwner {
        TriggmineToken(TOKEN_ADDRESS).transferOwnership(ASSET_MANAGER_WALLET);
    }

    function () public payable {
        contribute();
    }

}