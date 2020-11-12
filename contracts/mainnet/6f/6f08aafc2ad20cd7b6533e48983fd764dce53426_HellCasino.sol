pragma solidity ^0.5.0;

import "./ERC20.sol";

contract HellCasino is ERC20Detailed {

   using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _adminBalances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    string constant tokenName = "HellCasino";
    string constant tokenSymbol = "HCAS";
    uint8  constant tokenDecimals = 8;
    
    uint256 _totalSupply = 30000000000000000; // 300 million total supply
    uint256 _OwnerSupply = 30000000000000000; // All supply is going to the contractOwner
    
    uint256 public jackpotfeePercent = 200; //2% going to jackpot address
    uint256 public burnPercent = 100; // 1% deflation each Tx
    //2 months in seconds 5259492
    uint256 private _releaseTime = 5259492;
    uint256 private _released;

    address public contractOwner;
    
    address public jackpot;


    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
        _released = block.timestamp+_releaseTime;
		    contractOwner = msg.sender;
        _mint(msg.sender, _OwnerSupply);
    }

    modifier isOwner(){
       require(msg.sender == contractOwner, "Unauthorised Sender");
        _;
    }
   /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  /**
  * @dev Returns when the Admin Funds will be released in seconds
  */
  function released() public view returns (uint256) {
    return _released;
  }
    
  /**
  * @dev Gets the Admin balance of the specified address.
  * @param adminAddress The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function adminBalance(address adminAddress) public view returns(uint256) {
      return _adminBalances[adminAddress];
  }
  
  /**
  * @dev Gets the balance of the specified address.
  * @param user The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address user) public view returns (uint256) {
    return _balances[user];
  }

 //Finding the percent of the burnfee
  function findBurnPercent(uint256 value) internal view returns (uint256)  {
	//Burn 1% of the sellers tokens
	uint256 burnValue = value.ceil(1);
	uint256 onePercent = burnValue.mul(burnPercent).div(10000);

	return onePercent;
  }
  
  //Finding the percent of the jackpotfee
    function findJackpotPercent(uint256 value) internal view returns (uint256)  {
	//Jackpot 2% of the sellers tokens
	uint256 jackpotValue = value.ceil(1);
	uint256 twoPercent = jackpotValue.mul(jackpotfeePercent).div(10000);

	return twoPercent;
  }
  
  function setJackpot(address _jackpot) public isOwner {
        jackpot = _jackpot;
  }
  
  //Simple transfer Does not burn tokens when transfering only allowed by Owner
  function simpleTransfer(address to, uint256 value) public isOwner returns (bool) {
	require(value <= _balances[msg.sender]);
	require(to != address(0));

	_balances[msg.sender] = _balances[msg.sender].sub(value);
	_balances[to] = _balances[to].add(value);

	emit Transfer(msg.sender, to, value);
	return true;
  }
 
    //Send Locked token to contract only Owner Can do so its pointless for anyone else
    function sendLockedToken(address beneficiary, uint256 value) public isOwner{
        require(_released > block.timestamp, "TokenTimelock: release time is before current time");
		require(value <= _balances[msg.sender]);
		_balances[msg.sender] = _balances[msg.sender].sub(value);
		_adminBalances[beneficiary] = value;
    }
    
    //Anyone Can Release The Funds after 2 months
    function release() public returns(bool){
        require(block.timestamp >= _released, "TokenTimelock: current time is before release time");
        uint256 value = _adminBalances[msg.sender];
        require(value > 0, "TokenTimelock: no tokens to release");
        _balances[msg.sender] = _balances[msg.sender].add(value);
         emit Transfer(contractOwner , msg.sender, value);
		 return true;
    }
  
  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  //To be Used by users to trasnfer tokens and burn while doing so
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender],"Not Enough Tokens in Account");
    require(to != address(0));
	require(value >= 2, "Minimum tokens to be sent is 2");
	uint256 burn;
	uint256 jackpotfee;
	uint256 totalfee;
	
	if(value < 10){
	    burn = 1;
	}else{
	    burn = findBurnPercent(value);
	    jackpotfee = findJackpotPercent(value);
	    totalfee = burn + jackpotfee;
	}
	
    uint256 tokensToTransfer = value.sub(totalfee);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[jackpot] = _balances[jackpot].add(jackpotfee);

    _totalSupply = _totalSupply.sub(burn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), burn);
    emit Transfer(msg.sender, address(jackpot), jackpotfee);
    return true;
  }
  
  //Transfer tokens to multiple addresses at once
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
   /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
     require(amount <= _balances[msg.sender],"Not Enough Tokens in Account");
    _burn(msg.sender, amount);
  }
 /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be Deflationary.
   * @param amount The amount that will be Deflationary.
   */
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be Deflationary.
   * @param amount The amount that will be Deflationary.
   */	
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
  
    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
 
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
   /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    
    //Delete balance of this account
    _balances[from] = _balances[from].sub(value);
    
	uint256 burn;
	uint256 jackpotfee;
	uint256 totalfee;
	if(value < 10){
	    burn = 1;
	}else{
	    burn = findBurnPercent(value);
	    jackpotfee = findJackpotPercent(value);
	    totalfee = burn + jackpotfee;
	}	
    uint256 tokensToTransfer = value.sub(totalfee);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(burn);
    _balances[jackpot] = _balances[jackpot].add(jackpotfee);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), burn);
    emit Transfer(msg.sender, address(jackpot), jackpotfee);
    return true;
  }
   /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

}