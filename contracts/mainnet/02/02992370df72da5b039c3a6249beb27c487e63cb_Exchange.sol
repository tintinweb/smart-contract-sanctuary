pragma solidity ^0.4.23;

contract Admin {

	address public	admin;
	address public	feeAccount; // address feeAccount, which will receive fee.
	address public 	nextVersionAddress; // this is next address exchange
	bool 	public	orderEnd; // this is var use when Admin want close exchange
	string  public 	version; // number version example 1.0, test_1.0
	uint 	public	feeTake; //percentage times (1 ether)
	bool	public	pause;

	modifier assertAdmin() {
		if ( msg.sender != admin ) {
			revert();
		}
		_;
	}

	/*
	*	This is function, is needed to change address admin.
	*/
	function setAdmin( address _admin ) assertAdmin public {
		admin = _admin;
	}
	function setPause (bool state) assertAdmin public {
		pause = state;
	}
	/*
	* 	This is function, is needed to change version smart-contract.
	*/
	function setVersion(string _version) assertAdmin public {
		version = _version;	
	}

	/*
	* 	This is function, is needed to set address, next smart-contracts.
	*/
	function setNextVersionAddress(address _nextVersionAddress) assertAdmin public{
		nextVersionAddress = _nextVersionAddress;	
	}

	/*
	* 	This is function, is needed to stop, news orders.
	*	Can not turn off it.
	*/
	function setOrderEnd() assertAdmin public {
		orderEnd = true;
	}

	/*
	*	This is function, is needed to change address feeAccount.
	*/
	function setFeeAccount( address _feeAccount ) assertAdmin public {
		feeAccount = _feeAccount;
	}

	/*
	* 	This is function, is needed to set new fee.
	*	Can only be changed down.
	*/
	
	function setFeeTake( uint _feeTake ) assertAdmin public {
		feeTake = _feeTake;
	}
}

contract SafeMath {

	function safeMul( uint a, uint b ) pure internal returns ( uint ) {
		
		uint 	c;
		
		c = a * b;
		assert( a == 0 || c / a == b );
		return c;
	}

	function safeSub( uint a, uint b ) pure internal returns ( uint ) {
		
		assert( b <= a );
		return a - b;
	}

	function safeAdd( uint a, uint b ) pure internal returns ( uint ) {
		
		uint 	c;
	
		c = a + b;
		assert( c >= a && c >= b );
		return c;
	}
}

/*
* Interface ERC20
*/

contract Token {

	function transfer( address _to, uint256 _value ) public returns ( bool success );
	
	function transferFrom( address _from, address _to, uint256 _value ) public returns ( bool success );
	
	event Transfer( address indexed _from, address indexed _to, uint256 _value );

}

contract Exchange is SafeMath, Admin {

	mapping( address => mapping( address => uint )) public tokens;
	mapping( address => mapping( bytes32 => bool )) public orders;
	mapping( bytes32 => mapping( address => uint )) public ordersBalance;

	event Deposit( address token, address user, uint amount, uint balance );
	event Withdraw( address token, address user, uint amount, uint balance );
	event Order( address user, address tokenTake, uint amountTake, address tokenMake, uint amountMake, uint nonce );
	event OrderCancel( address user, address tokenTake, uint amountTake, address tokenMake, uint amountMake, uint nonce );
	event Trade( address makeAddress, address tokenMake, uint amountGiveMake, address takeAddress, address tokenTake, uint quantityTake, uint feeTakeXfer, uint balanceOrder );
	event HashOutput(bytes32 hash);

	constructor( address _admin, address _feeAccount, uint _feeTake, string _version) public {
		admin = _admin;
		feeAccount = _feeAccount;
		feeTake = _feeTake;
		orderEnd = false;
		version = _version;
		pause = false;
	}

 	function 	depositEth() payable public {
 		assertQuantity( msg.value );
		tokens[0][msg.sender] = safeAdd( tokens[0][msg.sender], msg.value );
		emit Deposit( 0, msg.sender, msg.value, tokens[0][msg.sender] );
 	}

	function 	withdrawEth( uint amount ) public {
		assertQuantity( amount );
		tokens[0][msg.sender] = safeSub( tokens[0][msg.sender], amount );
		msg.sender.transfer( amount );
		emit Withdraw( 0, msg.sender, amount, tokens[0][msg.sender] );
	}

	function 	depositToken( address token, uint amount ) public {
		assertToken( token );
		assertQuantity( amount );
		tokens[token][msg.sender] = safeAdd( tokens[token][msg.sender], amount );
		if ( Token( token ).transferFrom( msg.sender, this, amount ) == false ) {
			revert();
		}
	    emit	Deposit( token, msg.sender, amount , tokens[token][msg.sender] );
	}

	function 	withdrawToken( address token, uint amount ) public {
		assertToken( token );
		assertQuantity( amount );
		if ( Token( token ).transfer( msg.sender, amount ) == false ) {
			revert();
		}
		tokens[token][msg.sender] = safeSub( tokens[token][msg.sender], amount ); // уязвимость двойного входа?
	    emit Withdraw( token, msg.sender, amount, tokens[token][msg.sender] );
	}
	
	function 	order( address tokenTake, uint amountTake, address tokenMake, uint amountMake, uint nonce ) public {
		bytes32 	hash;

		assertQuantity( amountTake );
		assertQuantity( amountMake );
		assertCompareBalance( amountMake, tokens[tokenMake][msg.sender] );
		if ( orderEnd == true )
			revert();
		
		hash = keccak256( this, tokenTake, tokenMake, amountTake, amountMake, nonce );
		
		orders[msg.sender][hash] = true;
		tokens[tokenMake][msg.sender] = safeSub( tokens[tokenMake][msg.sender], amountMake );
		ordersBalance[hash][msg.sender] = amountMake;

		emit HashOutput(hash);
		emit Order( msg.sender, tokenTake, amountTake, tokenMake, amountMake, nonce );
	}

	function 	orderCancel( address tokenTake, uint amountTake, address tokenMake, uint amountMake, uint nonce ) public {
		bytes32 	hash;

		assertQuantity( amountTake );
		assertQuantity( amountMake );

		hash = keccak256( this, tokenTake, tokenMake, amountTake, amountMake, nonce );
		orders[msg.sender][hash] = false;

		tokens[tokenMake][msg.sender] = safeAdd( tokens[tokenMake][msg.sender], ordersBalance[hash][msg.sender]);
		ordersBalance[hash][msg.sender] = 0;
		emit OrderCancel( msg.sender, tokenTake, amountTake, tokenMake, amountMake, nonce );
	}

	function 	trade( address tokenTake, address tokenMake, uint amountTake, uint amountMake, uint nonce, address makeAddress, uint quantityTake ) public { 

		bytes32 	hash;
		uint 		amountGiveMake;

		assertPause();
		assertQuantity( quantityTake );

		hash = keccak256( this, tokenTake, tokenMake, amountTake, amountMake, nonce );
		assertOrders( makeAddress, hash );
		
		amountGiveMake = safeMul( amountMake, quantityTake ) / amountTake;
		assertCompareBalance ( amountGiveMake, ordersBalance[hash][makeAddress] );
	
		tradeBalances( tokenTake, tokenMake, amountTake, amountMake, makeAddress, quantityTake, hash);
		emit HashOutput(hash);
	}

	function 	tradeBalances( address tokenGet, address tokenGive, uint amountGet, uint amountGive, address user, uint amount, bytes32 hash) private {
		uint 		feeTakeXfer;
		uint 		amountGiveMake;

		feeTakeXfer = safeMul( amount, feeTake ) / ( 1 ether );
		amountGiveMake = safeMul( amountGive, amount ) / amountGet; 

		tokens[tokenGet][msg.sender] = safeSub( tokens[tokenGet][msg.sender], safeAdd( amount, feeTakeXfer ) );
		tokens[tokenGet][user] = safeAdd( tokens[tokenGet][user], amount );
		tokens[tokenGet][feeAccount] = safeAdd( tokens[tokenGet][feeAccount], feeTakeXfer );
		ordersBalance[hash][user] = safeSub( ordersBalance[hash][user], safeMul( amountGive, amount ) / amountGet );
		tokens[tokenGive][msg.sender] = safeAdd( tokens[tokenGive][msg.sender], safeMul( amountGive, amount ) / amountGet );

		emit Trade( user, tokenGive, amountGiveMake, msg.sender, tokenGet, amount, feeTakeXfer, ordersBalance[hash][user] );
		emit HashOutput(hash);
	}

	function 	assertQuantity( uint amount ) pure private {
		if ( amount == 0 ) {
			revert();
		}
	}

	function	assertPause() view private {
		if ( pause == true ) {
			revert();
		}	
	}

	function 	assertToken( address token ) pure private { 
		if ( token == 0 ) {
			revert();
		}
	}


	function 	assertOrders( address makeAddress, bytes32 hash ) view private {
		if ( orders[makeAddress][hash] == false ) {
			revert();
		}
	}

	function 	assertCompareBalance( uint a, uint b ) pure private {
		if ( a > b ) {
			revert();
		}
	}
}