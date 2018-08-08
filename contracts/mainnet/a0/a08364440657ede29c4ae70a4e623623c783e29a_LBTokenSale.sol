pragma solidity 0.4.18;

contract Ownable {
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20 {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));

		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}

contract LBToken is StandardToken {
	string public constant name = "LB Token";
    string public constant symbol = "LB";
    uint8  public constant decimals = 18;

	address public minter; 
	uint    public tokenSaleEndTime; 

	modifier onlyMinter {
		require (msg.sender == minter);
		_;
	}

	modifier whenMintable {
		require (now <= tokenSaleEndTime);
		_;
	}

    modifier validDestination(address to) {
        require(to != address(this));
        _;
    }

	function LBToken(address _minter, uint _tokenSaleEndTime) public {
		minter = _minter;
		tokenSaleEndTime = _tokenSaleEndTime;
    }

	function transfer(address _to, uint _value)
        public
        validDestination(_to)
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

	function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

	function createToken(address _recipient, uint _value)
		whenMintable
		onlyMinter
		returns (bool)
	{
		balances[_recipient] += _value;
		totalSupply += _value;
		return true;
	}
}

contract LBTokenSale is Ownable {
    using SafeMath for uint256;

	// token allocation
	uint public constant TOTAL_LBTOKEN_SUPPLY   = 480000000;
	uint public constant ALLOC_TEAM             =  72000000e18;
	uint public constant ALLOC_RESERVED         =  96000000e18;
	uint public constant ALLOC_COMMUNITY        =  72000000e18;
	uint public constant ALLOC_ADVISOR          =  24000000e18;
	uint public constant ALLOC_SALE_CORNERSTONE =  32500000e18; 
	uint public constant ALLOC_SALE_PRIVATE     = 120000000e18; 
	uint public constant ALLOC_SALE_GENERAL_1   =  22500000e18; 
	uint public constant ALLOC_SALE_GENERAL_2   =  21000000e18; 
	uint public constant ALLOC_SALE_GENERAL_3   =  20000000e18; 

	// Token sale rate from ETH to LB
	uint public constant RATE_CORNERSTONE  = 3250;
	uint public constant RATE_PRIVATE      = 3000;
	uint public constant RATE_CROWDSALE_S1 = 2250;
	uint public constant RATE_CROWDSALE_S2 = 2100;
	uint public constant RATE_CROWDSALE_S3 = 2000;

	// For token transfer
	address public constant WALLET_LB_RESERVED  = 0x2cde024b3dcf68081F0aA03f33e4631D7293544f;
	address public constant WALLET_LB_COMMUNITY = 0x60e95CE9A740cF66bE5598B994Ed97D6c143aDE9;
	address public constant WALLET_LB_TEAM      = 0x90545665F7Be2DB1880eDA948EA55AE6De2726F3;
	address public constant WALLET_LB_ADMIN     = 0x4Db76c3F8d0169ABa7aD5795dA1253231a09a22C;

	// For ether transfer
	address private constant WALLET_ETH_LB    = 0xc6bc39A8038A9C1dfdFE73ce1df4e5094D30E6f4;
	address private constant WALLET_ETH_ADMIN = 0x782872fb9459FC0dbdf8c0EDb5fE3D5f214a6660;

    LBToken public lbToken; 

	uint256 public presaleStartTime;
    uint256 public publicStartTime;
    uint256 public publicEndTime;
	bool public halted;

	// stat
	uint256 public totalLBSold_CORNERSTONE;
	uint256 public totalLBSold_PRIVATE;
	uint256 public totalLBSold_GENERAL_1;
	uint256 public totalLBSold_GENERAL_2;
	uint256 public totalLBSold_GENERAL_3;
    uint256 public weiRaised;
	mapping(address=>uint256) public weiContributions;

	// whitelisting
	mapping(address=>bool) public whitelisted_Private;
	mapping(address=>bool) public whitelisted_Cornerstone;
	event WhitelistedPrivateStatusChanged(address target, bool isWhitelisted);
	event WhitelistedCornerstoneStatusChanged(address target, bool isWhitelisted);

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    function LBTokenSale(uint256 _presaleStartTime, uint256 _publicStartTime, uint256 _publicEndTime) {
        presaleStartTime = _presaleStartTime;
        publicStartTime = _publicStartTime;
		publicEndTime = _publicEndTime;

        lbToken = new LBToken(address(this), publicEndTime);
		lbToken.createToken(WALLET_LB_RESERVED, ALLOC_RESERVED);
		lbToken.createToken(WALLET_LB_COMMUNITY, ALLOC_COMMUNITY);
		lbToken.createToken(WALLET_LB_TEAM, ALLOC_TEAM);
		lbToken.createToken(WALLET_LB_ADMIN, ALLOC_ADVISOR);
    }


    function changeWhitelistPrivateStatus(address _target, bool _isWhitelisted)
        public
        onlyOwner
    {
        whitelisted_Private[_target] = _isWhitelisted;
        WhitelistedPrivateStatusChanged(_target, _isWhitelisted);
    }

    function changeWhitelistPrivateStatuses(address[] _targets, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint i = 0; i < _targets.length; i++) {
            changeWhitelistPrivateStatus(_targets[i], _isWhitelisted);
        }
    }

	function changeWhitelistCornerstoneStatus(address _target, bool _isWhitelisted)
        public
        onlyOwner
    {
        whitelisted_Cornerstone[_target] = _isWhitelisted;
        WhitelistedCornerstoneStatusChanged(_target, _isWhitelisted);
    }

    function changeWhitelistCornerstoneStatuses(address[] _targets, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint i = 0; i < _targets.length; i++) {
            changeWhitelistCornerstoneStatus(_targets[i], _isWhitelisted);
        }
    }

    function validPurchase() 
        internal 
        returns(bool) 
    {
		bool nonZeroPurchase = msg.value != 0;
		bool withinSalePeriod = now >= presaleStartTime && now <= publicEndTime;
        bool withinPublicPeriod = now >= publicStartTime && now <= publicEndTime;

		bool whitelisted = whitelisted_Cornerstone[msg.sender] || whitelisted_Private[msg.sender];
		bool whitelistedCanBuy = whitelisted && withinSalePeriod;
        
        return nonZeroPurchase && (whitelistedCanBuy || withinPublicPeriod);
    }

    function () 
       payable 
    {
        buyTokens();
    }

    function buyTokens() 
       payable 
    {
		require(!halted);
        require(validPurchase());

		address investor = msg.sender;
        uint256 weiInvested = msg.value;
		uint256 purchaseTokens; 
		
		if (whitelisted_Cornerstone[investor]) {
			purchaseTokens = weiInvested.mul(RATE_CORNERSTONE); 
			require(ALLOC_SALE_CORNERSTONE - totalLBSold_CORNERSTONE >= purchaseTokens); // buy only if enough supply
			require(lbToken.createToken(investor, purchaseTokens));
			totalLBSold_CORNERSTONE = totalLBSold_CORNERSTONE.add(purchaseTokens); 
		} else if (whitelisted_Private[investor]) {
			purchaseTokens = weiInvested.mul(RATE_PRIVATE); 
			require(ALLOC_SALE_PRIVATE - totalLBSold_PRIVATE >= purchaseTokens); // buy only if enough supply
			require(lbToken.createToken(investor, purchaseTokens));
			totalLBSold_PRIVATE = totalLBSold_PRIVATE.add(purchaseTokens); 
		} else {
			purchaseTokens = _getPurchaseToken(investor, weiInvested);
			require(purchaseTokens > 0);
			require(lbToken.createToken(investor, purchaseTokens));
		}

		weiRaised = weiRaised.add(weiInvested);
		weiContributions[investor] = weiContributions[investor].add(weiInvested);

		TokenPurchase(investor, weiInvested, purchaseTokens);
		forwardFunds();
    }

	function _getPurchaseToken(address sender, uint256 weiInvested)
		internal
		returns(uint256) 
	{
		uint256 tokenRemain1 = ALLOC_SALE_GENERAL_1 - totalLBSold_GENERAL_1;
		uint256 tokenToPurchase1 = weiInvested.mul(RATE_CROWDSALE_S1);
		if (tokenRemain1 >= tokenToPurchase1) {
			totalLBSold_GENERAL_1 = totalLBSold_GENERAL_1.add(tokenToPurchase1);
			return tokenToPurchase1;
		} else if (tokenRemain1 > 0) {
			uint256 weiRemain = weiInvested - tokenRemain1.div(RATE_CROWDSALE_S1); 
			uint256 tokenToPurchase2 = weiRemain.mul(RATE_CROWDSALE_S2);
			totalLBSold_GENERAL_1 = totalLBSold_GENERAL_1.add(tokenRemain1);
			totalLBSold_GENERAL_2 = totalLBSold_GENERAL_2.add(tokenToPurchase2);
			return tokenRemain1 + tokenToPurchase2;
		}

		uint256 tokenRemain2 = ALLOC_SALE_GENERAL_2 - totalLBSold_GENERAL_2;
		tokenToPurchase2 = weiInvested.mul(RATE_CROWDSALE_S2);
		if (tokenRemain2 >= tokenToPurchase2) {
			totalLBSold_GENERAL_2 = totalLBSold_GENERAL_2.add(tokenToPurchase2);
			return tokenToPurchase2;
		} else if (tokenRemain2 > 0) {
			weiRemain = weiInvested - tokenRemain2.div(RATE_CROWDSALE_S2); 
			uint256 tokenToPurchase3 = weiRemain.mul(RATE_CROWDSALE_S3);
			totalLBSold_GENERAL_2 = totalLBSold_GENERAL_2.add(tokenRemain2);
			totalLBSold_GENERAL_3 = totalLBSold_GENERAL_3.add(tokenToPurchase3);
			return tokenRemain2 + tokenToPurchase3;
		}

		uint256 tokenRemain3 = ALLOC_SALE_GENERAL_3 - totalLBSold_GENERAL_3;
		tokenToPurchase3 = weiInvested.mul(RATE_CROWDSALE_S3);
		if (tokenRemain3 >= tokenToPurchase3) {
			totalLBSold_GENERAL_3 = totalLBSold_GENERAL_3.add(tokenToPurchase3);
			return tokenToPurchase3;
		}

		return 0;
	}

    function forwardFunds() 
       internal 
    {
        WALLET_ETH_LB.transfer((msg.value).mul(98).div(100));
		WALLET_ETH_ADMIN.transfer((msg.value).mul(2).div(100));
    }

    function hasEnded() 
        public 
        constant 
        returns(bool) 
    {
        return now > publicEndTime;
    }

	function toggleHalt(bool _halted)
		public
		onlyOwner
	{
		halted = _halted;
	}
}