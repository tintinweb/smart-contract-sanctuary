pragma solidity ^0.4.19;

// LeeSungCoin Made By PinkCherry - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="82ebecf1e3ecebf6fbf1e9e3ecc2e5efe3ebeeace1edef">[email&#160;protected]</a>
// LeeSungCoin Request Question - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e2898d908783818d8b8c918d8e97968b8d8ca2858f838b8ecc818d8f">[email&#160;protected]</a>

library SafeMath
{
  	function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}


contract OwnerHelper
{
  	address public owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}

  	function OwnerHelper() public
	{
		owner = msg.sender;
  	}

  	function transferOwnership(address _to) onlyOwner public
	{
            require(_to != owner);
    		require(_to != address(0x0));
    		owner = _to;
    		OwnerTransferPropose(owner, _to);
  	}

}


contract ERC20Interface
{
  	event Transfer(address indexed _from, address indexed _to, uint _value);
  	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Burned(address indexed _burner, uint _value);

  	function totalSupply() public constant returns (uint);
  	function balanceOf(address _owner) public constant returns (uint balance);
  	function transfer(address _to, uint _value) public returns (bool success);
  	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  	function approve(address _spender, uint _value) public returns (bool success);
  	function allowance(address _owner, address _spender) public constant returns (uint remaining);
	function burn(uint _burnAmount) public returns (bool success);
}


contract ERC20Token is ERC20Interface, OwnerHelper
{
  	using SafeMath for uint;

  	uint public tokensIssuedTotal = 0;
  	address public constant burnAddress = 0;

  	mapping(address => uint) balances;
  	mapping(address => mapping (address => uint)) allowed;

  	function totalSupply() public constant returns (uint)
	{
		return tokensIssuedTotal;
  	}

  	function balanceOf(address _owner) public constant returns (uint balance)
	{
		return balances[_owner];
  	}

	function transfer(address _to, uint _amount) public returns (bool success)
	{
		require( balances[msg.sender] >= _amount );

	    balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to]        = balances[_to].add(_amount);

		Transfer(msg.sender, _to, _amount);
    
		return true;
  	}

  	function approve(address _spender, uint _amount) public returns (bool success)
	{
		require ( balances[msg.sender] >= _amount );

		allowed[msg.sender][_spender] = _amount;
    		
		Approval(msg.sender, _spender, _amount);

		return true;
	}

  	function transferFrom(address _from, address _to, uint _amount) public returns (bool success)
	{
		require( balances[_from] >= _amount );
		require( allowed[_from][msg.sender] >= _amount );
		balances[_from]            = balances[_from].sub(_amount);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
		balances[_to]              = balances[_to].add(_amount);

		Transfer(_from, _to, _amount);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint remaining)
	{
		return allowed[_owner][_spender];
  	}

	function burn(uint _burnAmount) public returns (bool success)
	{
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_burnAmount);
		tokensIssuedTotal = tokensIssuedTotal.sub(_burnAmount);
		Burned(burner, _burnAmount);
		Transfer(burner, burnAddress, _burnAmount);

		return true;
	}
}

contract LeeSungCoin is ERC20Token
{
	uint constant E18 = 10**18;

  	string public constant name 	= "LeeSungCoin";
  	string public constant symbol 	= "LSC";
  	uint public constant decimals 	= 18;

	address public wallet;
	address public adminWallet;
	address public IcoContract;

	uint public constant totalCoinCap   = 2000000000 * E18;
	uint public constant icoCoinCap     = 1400000000 * E18;
	uint public constant mktCoinCap     =  600000000 * E18;
	uint public constant preSaleCoinCap =  480000000 * E18;

	uint public coinPerEth = 20000 * E18;

	uint public constant privateSaleBonus	 = 30;
	uint public constant preSaleFirstBonus	 = 20;
	uint public constant preSaleSecondBonus  = 15;
	uint public constant mainSaleFirstBonus	 = 5;
	uint public constant mainSaleSecondBonus = 0;

  	uint public constant preSaleFirstStartDate = 1517788800; // 2018-02-05 00:00 UTC
  	uint public constant preSaleFirstEndDate   = 1518307200; // 2018-02-11 00:00 UTC

  	uint public constant preSaleSecondStartDate = 1518393600; // 2018-02-12 00:00 UTC
  	uint public constant preSaleSecondEndDate   = 1518912000; // 2018-02-18 00:00 UTC


  	uint public constant mainSaleFirstStartDate = 1519603200; // 2018-02-26 00:00 UTC
  	uint public constant mainSaleFirstEndDate   = 1520121600; // 2018-03-04 00:00 UTC

  	uint public constant mainSaleSecondStartDate = 1520208000; // 2018-03-05 00:00 UTC
  	uint public constant mainSaleSecondEndDate   = 1520726400; // 2018-03-11 00:00 UTC

	uint public constant transferCooldown = 2 days;

	uint public constant preSaleMinEth  = 1 ether;
	uint public constant mainSaleMinEth =  1 ether / 2; // 0.5 Ether

  	uint public priEtherReceived = 0; // Ether actually received by the contract
  	uint public icoEtherReceived = 0; // Ether actually received by the contract

    uint public coinIssuedTotal     = 0;
  	uint public coinIssuedIco       = 0;
  	uint public coinIssuedMkt       = 0;
	
	uint public coinBurnIco = 0;
	uint public coinBurnMkt = 0;

  	mapping(address => uint) public icoEtherContributed;
  	mapping(address => uint) public icoCoinReceived;
  	mapping(address => bool) public refundClaimed;
  	mapping(address => bool) public coinLocked;
  	
 	event WalletChange(address _newWallet);
  	event AdminWalletChange(address _newAdminWallet);
  	event CoinMinted(address indexed _owner, uint _tokens, uint _balance);
  	event CoinIssued(address indexed _owner, uint _tokens, uint _balance, uint _etherContributed);
  	event Refund(address indexed _owner, uint _amount, uint _tokens);
  	event LockRemove(address indexed _participant);
	event WithDraw(address indexed _to, uint _amount);
	event OwnerReclaim(address indexed _from, address indexed _owner, uint _amount);

  	function LeeSungCoin() public
	{
		require( icoCoinCap + mktCoinCap == totalCoinCap );
		wallet = owner;
		adminWallet = owner;
		
		IcoContract = 0x6E5B3dBFB6a85D11e5d0d4A5618C53838Da63900;
		priEtherReceived = 517 ether;
		icoEtherReceived = 112260255293000000000;
  	}

  	function () payable public
	{
    	buyCoin();
  	}
  	
  	function atNow() public constant returns (uint)
	{
		return now;
  	}

  	function buyCoin() private
	{
		uint nowTime = atNow();

		uint saleTime = 0; // 1 : preSaleFirst, 2 : preSaleSecond, 3 : mainSaleFirst, 4 : mainSaleSecond

		uint minEth = 0;
		uint maxEth = 300 ether;

		uint coins = 0;
		uint coinBonus = 0;
		uint coinCap = 0;

		if (nowTime > preSaleFirstStartDate && nowTime < preSaleFirstEndDate)
		{
			saleTime = 1;
			minEth = preSaleMinEth;
			coinBonus = preSaleFirstBonus;
			coinCap = preSaleCoinCap;
		}

		if (nowTime > preSaleSecondStartDate && nowTime < preSaleSecondEndDate)
		{
			saleTime = 2;
			minEth = preSaleMinEth;
			coinBonus = preSaleSecondBonus;
			coinCap = preSaleCoinCap;
		}

		if (nowTime > mainSaleFirstStartDate && nowTime < mainSaleFirstEndDate)
		{
			saleTime = 3;
			minEth = mainSaleMinEth;
			coinBonus = mainSaleFirstBonus;
			coinCap = icoCoinCap;
		}

		if (nowTime > mainSaleSecondStartDate && nowTime < mainSaleSecondEndDate)
		{
			saleTime = 4;
			minEth = mainSaleMinEth;
			coinBonus = mainSaleSecondBonus;
			coinCap = icoCoinCap;
		}
		
		require( saleTime >= 1 && saleTime <= 4 );
		require( msg.value >= minEth );
		require( icoEtherContributed[msg.sender].add(msg.value) <= maxEth );

		coins = coinPerEth.mul(msg.value) / 1 ether;
      	coins = coins.mul(100 + coinBonus) / 100;

		require( coinIssuedIco.add(coins) <= coinCap );

		balances[msg.sender]        = balances[msg.sender].add(coins);
	    icoCoinReceived[msg.sender] = icoCoinReceived[msg.sender].add(coins);
		coinIssuedIco               = coinIssuedIco.add(coins);
		tokensIssuedTotal           = tokensIssuedTotal.add(coins);
    
		icoEtherReceived                = icoEtherReceived.add(msg.value);
		icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value);
    
		coinLocked[msg.sender] = true;
    
		Transfer(0x0, msg.sender, coins);
		CoinIssued(msg.sender, coins, balances[msg.sender], msg.value);

		wallet.transfer(this.balance);
  	}

 	function isTransferable() public constant returns (bool transferable)
	{
		if ( atNow() < mainSaleSecondEndDate + transferCooldown )
		{
			return false;
		}

		return true;
  	}

	function coinLockRemove(address _participant) public
	{
		require( msg.sender == adminWallet || msg.sender == owner );
		coinLocked[_participant] = false;
		LockRemove(_participant);
  	}

	function coinLockRmoveMultiple(address[] _participants) public
	{
		require( msg.sender == adminWallet || msg.sender == owner );
    		
		for (uint i = 0; i < _participants.length; i++)
		{
  			coinLocked[_participants[i]] = false;
  			LockRemove(_participants[i]);
		}
  	}

  	function changeWallet(address _wallet) onlyOwner public
	{
    		require( _wallet != address(0x0) );
    		wallet = _wallet;
    		WalletChange(wallet);
  	}

  	function changeAdminWallet(address _wallet) onlyOwner public
	{
    		require( _wallet != address(0x0) );
    		adminWallet = _wallet;
    		AdminWalletChange(adminWallet);
  	}

  	function mintMarketing(address _participant, uint _amount) onlyOwner public
	{
		uint coins = _amount * E18;
		
		require( coins <= mktCoinCap.sub(coinIssuedMkt) );
		
		balances[_participant] = balances[_participant].add(coins);
		
		coinIssuedMkt   = coinIssuedMkt.add(coins);
		coinIssuedTotal = coinIssuedTotal.add(coins);
		tokensIssuedTotal = tokensIssuedTotal.add(coins);
		
		coinLocked[_participant] = true;
		
		Transfer(0x0, _participant, coins);
		CoinMinted(_participant, coins, balances[_participant]);
  	}
  	
  	function mintIcoTokenMultiple(address[] _addresses, uint[] _amounts) onlyOwner public
  	{
		uint coins = 0;
		
		for (uint i = 0; i < _addresses.length; i++)
		{
		    coins = _amounts[i] * E18;
		    
		    balances[_addresses[i]] = balances[_addresses[i]].add(coins);
    
		    coinIssuedIco       = coinIssuedIco.add(coins);
		    coinIssuedTotal     = coinIssuedTotal.add(coins);
		    tokensIssuedTotal   = tokensIssuedTotal.add(coins);
    
		    coinLocked[_addresses[i]] = true;
		    Transfer(0x0, _addresses[i], coins);
	        CoinMinted(_addresses[i], coins, balances[_addresses[i]]);
		}
  	}
  	
  	function ownerWithdraw() external onlyOwner
	{
		uint amount = this.balance;
		wallet.transfer(amount);
		WithDraw(msg.sender, amount);
  	}
  	
  	function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner public returns (bool success)
	{
  		return ERC20Interface(tokenAddress).transfer(owner, amount);
  	}
  	
  	function transfer(address _to, uint _amount) public returns (bool success)
	{
		require( isTransferable() );
		require( coinLocked[msg.sender] == false );
		require( coinLocked[_to] == false );
		return super.transfer(_to, _amount);
  	}
  	
  	function transferFrom(address _from, address _to, uint _amount) public returns (bool success)
	{
		require( isTransferable() );
		require( coinLocked[_from] == false );
		require( coinLocked[_to] == false );
		return super.transferFrom(_from, _to, _amount);
  	}

  	function transferMultiple(address[] _addresses, uint[] _amounts) external
  	{
		require( isTransferable() );
		require( coinLocked[msg.sender] == false );
		require( _addresses.length == _amounts.length );
		
		for (uint i = 0; i < _addresses.length; i++)
		{
  			if (coinLocked[_addresses[i]] == false) 
			{
				super.transfer(_addresses[i], _amounts[i]);
			}
		}
  	}

  	function reclaimFunds() external
	{
		uint coins;
		uint amount;

		require( atNow() > mainSaleSecondEndDate );
		require( !refundClaimed[msg.sender] );
		require( icoEtherContributed[msg.sender] > 0 );

		coins = icoCoinReceived[msg.sender];
		amount = icoEtherContributed[msg.sender];

		balances[msg.sender] = balances[msg.sender].sub(coins);
		tokensIssuedTotal    = tokensIssuedTotal.sub(coins);

		refundClaimed[msg.sender] = true;

		msg.sender.transfer(amount);

		Transfer(msg.sender, 0x0, coins);
		Refund(msg.sender, amount, coins);
  	}
  	
    function transferToOwner(address _from) onlyOwner public
    {
		require( coinLocked[_from] == false );
        uint amount = balanceOf(_from);
        
        balances[_from] = balances[_from].sub(amount);
        balances[owner] = balances[owner].add(amount);
        
        Transfer(_from, owner, amount);
        OwnerReclaim(_from, owner, amount);
    }

	function burnIcoCoins() onlyOwner public returns (bool success)
	{
	    uint coins = 1400000000 * E18;
	    coins = coins.sub(coinIssuedIco);
	    
	    address burner = msg.sender;
	    
		balances[burner] = balances[burner].add(coins);
		
		coinIssuedTotal = coinIssuedTotal.add(coins);
		coinIssuedIco   = coinIssuedIco.add(coins);
		tokensIssuedTotal = tokensIssuedTotal.add(coins);
		
		Transfer(0x0, burner, coins);
		
        coinIssuedTotal = coinIssuedTotal.sub(coins);
        coinIssuedIco = coinIssuedIco.sub(coins);
        coinBurnIco = coinBurnIco.add(coins);
		
		return super.burn(coins);
	}

	function burnMktCoins() onlyOwner public returns (bool success)
	{
	    uint coins = 600000000 * E18;
	    coins = coins.sub(coinIssuedMkt);
	    
	    address burner = msg.sender;
	    
		balances[burner] = balances[burner].add(coins);
		
		coinIssuedTotal = coinIssuedTotal.add(coins);
		coinIssuedIco   = coinIssuedIco.add(coins);
		tokensIssuedTotal = tokensIssuedTotal.add(coins);
		
		Transfer(0x0, burner, coins);
		
        coinIssuedTotal = coinIssuedTotal.sub(coins);
        coinIssuedMkt = coinIssuedMkt.sub(coins);
        coinBurnMkt = coinBurnMkt.add(coins);
		
		return super.burn(coins);
	}

}