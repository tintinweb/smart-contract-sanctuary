pragma solidity ^0.4.21;

contract Erc20Token {
	uint256 public totalSupply; //Total amount of Erc20Token
	
	//Check balances
    function balanceOf(address _owner) public constant returns (uint256 balance);
    
	/**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success);
	
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//Contract manager
contract ownerYHT {
    address public owner;

    function ownerYHT() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
	
    function transferOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

//knifeOption
contract KEO is ownerYHT,Erc20Token {
    string public name= &#39;KEO&#39;; 
    string public symbol = &#39;KEO&#39;; 
    uint8 public decimals = 0;
	
	uint256 public moneyTotal = 60000000;//Total amount of Erc20Token
	uint256 public moneyFreeze = 20000000; 
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
	/**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function KEO() public {
        totalSupply = (moneyTotal - moneyFreeze) * 10 ** uint256(decimals);

        balances[msg.sender] = totalSupply;
    }
	
	
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
		return true;
    }
	
	/**
	 * Send tokens to another account from a specified account
     * The calling process will check the set maximum allowable transaction amount
	 * 
	 */
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success){
        
        require(_value <= allowed[_from][msg.sender]);   // Check allowed
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
	
	function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
	
	//Set the maximum amount allowed for the account
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
	
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //private
    function _transfer(address _from, address _to, uint256 _value) internal {

		require(_to != 0x0);

		require(balances[_from] >= _value);

		require(balances[_to] + _value > balances[_to]);

		uint previousBalances = balances[_from] + balances[_to];

		balances[_from] -= _value;

		balances[_to] += _value;

		emit Transfer(_from, _to, _value);

		assert(balances[_from] + balances[_to] == previousBalances);

    }
    
	/**
	 *Thawing frozen money
	 *Note: The value unit here is the unit before the 18th power 
	 *that hasn&#39;t been multiplied by 10, that is, the same unit as 
	 * the money whose initial definition was frozen.
	 */
	event EventUnLockFreeze(address indexed from,uint256 value);
    function unLockFreeze(uint256 _value) onlyOwner public {
        require(_value <= moneyFreeze);
        
		moneyFreeze -= _value;
		
		balances[msg.sender] += _value * 10 ** uint256(decimals);
		
		emit EventUnLockFreeze(msg.sender,_value);
    }
}