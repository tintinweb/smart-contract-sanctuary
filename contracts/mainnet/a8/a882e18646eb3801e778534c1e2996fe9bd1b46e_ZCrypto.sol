/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.5.17;

contract ZCrypto  {
    using SafeMath for uint256;

    
    string private _tokenName;
    string private _tokenSymbol;
    uint8 private _decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    address private _minterAddress;
    address private _owner;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	


    constructor () public {
        _owner =  msg.sender;
        _tokenName = "ZCrypto";
        _tokenSymbol = "ZCO";
        _decimals = 8;
		uint256 initialSupply=10000000000000000;
        _minterAddress = _owner;
		address masterAccount=  _owner;
        _totalSupply = _totalSupply.add(initialSupply);
        _balances[masterAccount] = _balances[masterAccount].add(initialSupply);
        emit Transfer(address(0), masterAccount, initialSupply);
    }

    //Returns the name of the token
    function name() public view returns (string memory) {
        return _tokenName;
    }

    //Returns the symbol of the token
    function symbol() public view returns (string memory) {
        return _tokenSymbol;
    }

	/**
         Returns the number of decimals the token uses - e.g. 8, 
	 means to divide the token amount by 100000000 to get its user representation.
        */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * returns total tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * returns the  account balance of the specified address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * Returns the amount which spender is still allowed to withdraw from owner
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     *Transfer token for a specified address
	 *Transfers tokens to address receiver, and MUST fire the Transfer event. 
	 *The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     */
    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        _transfer(msg.sender, receiver, numTokens);
        return true;
    }

    /**
     * Allows spender to withdraw from your account msg.sender multiple times, up to the numTokens amount. 
     * If this function is called again it overwrites the current allowance with numTokens.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * To prevent attack vectors like the one https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/ , 
     * clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender. 
     * THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
     */
    function approve(address spender, uint256 numTokens) public returns (bool) {
        _approve(msg.sender, spender, numTokens);
	emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    /**
     * Transfer tokens from one address to another.
     */
    function transferFrom(address from, address to, uint256 numTokens) public returns (bool) {
        _transfer(from, to, numTokens);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(numTokens));
        return true;
    }

    
    /**
     * Transfer token from to a specified addresses
     */
    function _transfer(address from, address to, uint256 numTokens) internal {
        require(to != address(0));
		require(numTokens <= _balances[from]);
        _balances[from] = _balances[from].sub(numTokens);
        _balances[to] = _balances[to].add(numTokens);
         emit Transfer(from, to, numTokens);
    }

    /**
     * Approve an address to spend another addresses' tokens.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowed[owner][spender] = value; 
		
    }

    /**
     * Function to print new tokens
     */
    function mint(address account, uint256 numTokens) public onlyMinter  {
        require(account != address(0));
        _totalSupply = _totalSupply.add(numTokens);
        _balances[account] = _balances[account].add(numTokens);
        emit Transfer(address(0), account, numTokens);
    }


    
    /**
     * @return the address that can mint tokens.
     */
    function currentMinter() external view returns (address) {
        return _minterAddress;
    }


    /**
     *  change minter address, newMinter The address that will be able to mint tokens from now on
     */
    function changeMinter(address newMinter) external onlyOwner {
        _minterAddress = newMinter;
    } 

    modifier onlyMinter() {
        require(msg.sender==_minterAddress);
        _;
    }
	
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    
     /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
	 /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
	function transferOwnership(address newOwner) external onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
    }
  }
	
	

}

library SafeMath {
    /**
     * Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 ans = a - b;

        return ans;
    }

    /**
     * Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 ans = a + b;
        require(ans >= a);
        return ans;
    }
}