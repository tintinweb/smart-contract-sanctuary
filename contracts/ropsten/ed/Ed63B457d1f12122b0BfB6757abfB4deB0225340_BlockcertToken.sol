/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.4.24;

/*Deployed at: 
https://rinkeby.etherscan.io/token/0xb18876e09953e60e5ab03d448b398601adcaacf0 */

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
	address public owner;
	address public newOwner;

	event OwnerUpdate(address _prevOwner, address _newOwner);

	/**
		@dev constructor
	*/
	constructor () public {
		owner = msg.sender;
	}

	// allows execution by the owner only
	modifier ownerOnly {
		assert(msg.sender == owner);
		_;
	}

	/**
		@dev allows transferring the contract ownership
		the new owner still needs to accept the transfer
		can only be called by the contract owner

		@param _newOwner    new contract owner
	*/
	function transferOwnership(address _newOwner) public ownerOnly {
		require(_newOwner != owner);
		newOwner = _newOwner;
	}

	/**
		@dev used by a new owner to accept an ownership transfer
	*/
	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnerUpdate(owner, newOwner);
		owner = newOwner;
		newOwner = 0x0;
	}
}

pragma solidity ^0.4.24;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    constructor () public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/**
    ERC20 Standard Token implementation
*/
contract BlockcertToken  is IERC20Token, Owned, Utils {
	string public standard = 'Token 0.1';

	string public name = 'BLOCKCERT';

	string public symbol = 'BCERT';

	uint8 public decimals = 0;

	uint256 public totalSupply = 2100000000;

	mapping (address => uint256) public balanceOf;

	mapping (address => mapping (address => uint256)) public allowance;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Convert(address indexed _from, address indexed _ownerAddress, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	/**
		@dev constructor

		@param _presalePool         Presale Pool address 27
		@param _Investors           CCT Pool address 3%
		@param _DeveloperPool       Developer pool address 7%
		@param _TreasuryPool        Treasury pool address 63%
	*/
    constructor (address _presalePool, address _Investors, address _DeveloperPool, address _TreasuryPool)
	public
	validAddress(_presalePool)
	validAddress(_Investors)
	validAddress(_DeveloperPool)
	validAddress(_TreasuryPool)
	{
		uint presalePoolBalance = 270000000;
		//uint publicSalePoolBalance = 430860000;
		uint InvestorsBalance = 30000000;
		uint DeveloperPoolBalance = 70000000;
		uint treasuryPoolBalance = 630000000;

		// balanceOf[msg.sender] = publicSalePoolBalance;
		// emit Transfer(this, msg.sender, publicSalePoolBalance);
		balanceOf[_presalePool] = presalePoolBalance;
        emit Transfer(this, _presalePool, presalePoolBalance);
		balanceOf[_Investors] = InvestorsBalance;
        emit Transfer(this, _Investors, InvestorsBalance);
		balanceOf[_DeveloperPool] = DeveloperPoolBalance;
        emit Transfer(this, _DeveloperPool, DeveloperPoolBalance);
		balanceOf[_TreasuryPool] = treasuryPoolBalance;
        emit Transfer(this, _TreasuryPool, treasuryPoolBalance);
	}

	/**
		@dev send coins
		throws on any error rather then return a false flag to minimize user errors

		@param _to      target address
		@param _value   transfer amount

		@return true if the transfer was successful, false if it wasn't
	*/
	function transfer(address _to, uint256 _value)
	public
	validAddress(_to)
	returns (bool success)
	{
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
		@dev an account/contract attempts to get the coins
		throws on any error rather then return a false flag to minimize user errors

		@param _from    source address
		@param _to      target address
		@param _value   transfer amount

		@return true if the transfer was successful, false if it wasn't
	*/
	function transferFrom(address _from, address _to, uint256 _value)
	public
	validAddress(_from)
	validAddress(_to)
	returns (bool success)
	{
		allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
		balanceOf[_from] = safeSub(balanceOf[_from], _value);
		balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
		return true;
	}

	/**
		@dev allow another account/contract to spend some tokens on your behalf
		throws on any error rather then return a false flag to minimize user errors

		also, to minimize the risk of the approve/transferFrom attack vector
		(see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
		in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

		@param _spender approved address
		@param _value   allowance amount

		@return true if the approval was successful, false if it wasn't
	*/
	function approve(address _spender, uint256 _value)
	public
	validAddress(_spender)
	returns (bool success)
	{
		// if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
		require(_value == 0 || allowance[msg.sender][_spender] == 0);

		allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
		@dev removes tokens from an account and decreases the token supply
		can be called by the contract owner to destroy tokens from any account or by any holder to destroy tokens from his/her own account

		@param _from       account to remove the amount from
		@param _amount     amount to decrease the supply by
	*/
	function destroy(address _from, uint256 _amount) public {
		require(msg.sender == _from || msg.sender == owner);
		// validate input

		balanceOf[_from] = safeSub(balanceOf[_from], _amount);
		totalSupply = safeSub(totalSupply, _amount);

        emit Transfer(_from, this, _amount);
	}

    /**
        @dev converting tokens from the ethereum network to the blockcerts network by token holder

        @param _ownerAddress       blockcerts network account to which funds must be transferred
        @param _amount                  convert amount
    */
    function convert(address _ownerAddress, uint256 _amount) public returns (bool success) {
        return _convert(msg.sender, _ownerAddress, _amount);
    }

    /**
        @dev converting tokens from the ethereum network any account to the blockcerts network by contract owner

        @param _from                    account to convert the amount from
        @param _ownerAddress       blockcerts network account to which funds must be transferred
        @param _amount                  convert amount
    */
    function convertFrom(address _from, address _ownerAddress, uint256 _amount) public returns (bool success) {
        require(msg.sender == owner || _from == msg.sender);
        return _convert(_from, _ownerAddress, _amount);
    }

    /**
        @dev converting tokens from the blockcert network any account to the ethereum network by contract owner

        @param _to                      token receiver
        @param _amount                  convert amount
    */
    function mint(address _to, uint256 _amount) public ownerOnly returns (bool success) {
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);
        balanceOf[this] = safeSub(balanceOf[this], _amount);
        emit Transfer(this, _to, _amount);
//        totalSupply = safeAdd(totalSupply, _amount);
        return true;
    }

    /**
        @dev converting tokens from the ethereum network to the blockcerts network by contract owner

        @param _from                    account to convert the amount from
        @param _ownerAddress       blockcerts network account to which funds must be transferred
        @param _amount                  convert amount
    */
    function _convert(address _from, address _ownerAddress, uint256 _amount)
    private
    validAddress(_from)
    validAddress(_ownerAddress)
    returns (bool success)
    {
        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        balanceOf[this] = safeAdd(balanceOf[this], _amount);
        emit Transfer(_from, this, _amount);
        emit Convert(_from, _ownerAddress, _amount);
//        totalSupply = safeSub(totalSupply, _amount);
        return true;
    }
}