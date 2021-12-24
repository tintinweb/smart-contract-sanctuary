/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Token {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




abstract contract IERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function  detectTransferRestriction (address from, address to, uint256 value) public virtual view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function  messageForTransferRestriction  (uint8 restrictionCode) public virtual view returns (string memory);
}



contract ERC1404TokenMinKYC is IERC20Token, IERC1404 {
	
	// Set buy and sell restrictions on investors.  
	// date is Linux Epoch datetime
	// Both date must be less than current date time to allow the respective operation. Like to get tokens from others, receiver's buy restriction
	// must be less than current date time. 
	// 0 means investor is not allowed to buy or sell his token.  0 indicates buyer or seller is not whitelisted. 
	// this condition is checked in detectTransferRestriction
    mapping (address => uint256) private _buyRestriction;  
	mapping (address => uint256) private _sellRestriction;	
	
	mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
	address private _owner;
	
	// These addresses can control addresses that can manage whitelisting of investor or in otherwords can call modifyKYCData
    mapping (address => bool) private _whitelistControlAuthority;  	
	

    //event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    //event Transfer(address indexed from, address indexed to, uint256 tokens);

	
	// ERC20 related functions
	uint256 public decimals = 18;
    uint256 private _totalSupply;
    string public name;
    string public symbol;
	
	// Custom functions
	string public ShareCertificate;
	string public CompanyHomepage;
	string public CompanyLegalDocs;

	
	// These variables control how many investors can have tokens
	// if allowedInvestors = 0 then there is no limit of investors 
	uint256 public currentTotalInvestors = 0;		
	uint256 public allowedInvestors = 0;

	// Transfer Allowed = true
	// Transfer not allowed = false
	bool public isTradingAllowed = true;
	
	
	constructor(uint256 _initialSupply, string memory _name,  string memory _symbol, uint256 _allowedInvestors, uint256 _decimals, string memory _ShareCertificate, string memory _CompanyHomepage, string memory _CompanyLegalDocs ) {

			name = _name;
			symbol = _symbol;

			decimals = _decimals;

			_owner = msg.sender;
			_buyRestriction[_owner] = 1;
			_sellRestriction[_owner] = 1;

			allowedInvestors = _allowedInvestors;

			// Minting tokens for initial supply
			_totalSupply = _initialSupply;
			_balances[_owner] = _totalSupply;

			// add message sender to whitelist authority list
			_whitelistControlAuthority[_owner] = true;

			ShareCertificate = _ShareCertificate;
			CompanyHomepage = _CompanyHomepage;
			CompanyLegalDocs = _CompanyLegalDocs;

			emit Transfer(address(0), _owner, _totalSupply);

	}



    function resetShareCertificate(string memory _ShareCertificate) 
	external 
	onlyOwner {
		 ShareCertificate = _ShareCertificate;
    }

    function resetCompanyHomepage(string memory _CompanyHomepage) 
	external 
	onlyOwner {
		 CompanyHomepage = _CompanyHomepage;
    }
	
    function resetCompanyLegalDocs(string memory _CompanyLegalDocs) 
	external 
	onlyOwner {
		 CompanyLegalDocs = _CompanyLegalDocs;
    }




	// _allowedInvestors = 0    No limit on number of investors        
	// _allowedInvestors > 0 only X number of investors can have positive balance 
    function resetAllowedInvestors(uint256 _allowedInvestors) 
	external 
	onlyOwner {
		if( _allowedInvestors != 0 )
			require(_allowedInvestors >= currentTotalInvestors, "Allowed Investors cannot be less than Current holders");

		 allowedInvestors = _allowedInvestors;
    }


    function flipTradingStatus() 
	external 
	onlyOwner {
		 isTradingAllowed = !isTradingAllowed;
    }


	//-----------------------------------------------------------------------
	// Get or set current owner of this smart contract
    function owner() 
	external 
	view 
	returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can call function");
        _;
    }
    function transferOwnership(address newOwner) 
	external 
	onlyOwner {
        require(newOwner != address(0), "Zero address not allowed");
		_owner = newOwner;
    }
	//-----------------------------------------------------------------------
	
  
  

	  


	  
 
	//-----------------------------------------------------------------------
    // Manage whitelist autority and KYC status
	
	function setWhitelistAuthorityStatus(address user)
	external 
	onlyOwner {
		_whitelistControlAuthority[user] = true;
	}
	function removeWhitelistAuthorityStatus(address user)
	external 
	onlyOwner {
		delete _whitelistControlAuthority[user];
	}	
	function getWhitelistAuthorityStatus(address user)
	external 
	view
	returns (bool) {
		 return _whitelistControlAuthority[user];
	}	
	

  	// Set buy and sell restrictions on investors 
	function modifyKYCData (address user, uint256 buyRestriction, uint256 sellRestriction) 
	external 
	{ 
	  	    require(_whitelistControlAuthority[msg.sender] == true, "Not Whitelist Authority");
			
		   _buyRestriction[user] = buyRestriction;
		   _sellRestriction[user] = sellRestriction;
	}
	  	  
	function getKYCData(address user) 
	external 
	view
	returns (uint256, uint256 ) {
		   return (_buyRestriction[user] , _sellRestriction[user] );
	}
	//-----------------------------------------------------------------------





	//-----------------------------------------------------------------------
	// These are ERC1404 interface implementations 
	
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == 1, messageForTransferRestriction(restrictionCode));
        _;
    }
	
    function detectTransferRestriction (address _from, address _to, uint256 value) 
	override
	public 
	view 
	returns (uint8 status)
    {	
	      // check if trading is allowed 
		  require(isTradingAllowed == true, "Transfer not allowed"); 	

		  require( value > 0, "Value bring transferred cannot be 0");
		  
		  require( _sellRestriction[_from] != 0  && _buyRestriction[_to] != 0, "Not Whitelisted" );
		  require( _sellRestriction[_from] <= block.timestamp && _buyRestriction[_to] <= block.timestamp, "KYC Time Restriction" );
		  
			// Following conditions make sure if number of token holders are within limit if enabled 
			// allowedInvestors = 0 means no restriction on token holders
			if(allowedInvestors == 0)
				return 1;
			else {
				if( _balances[_to] > 0 || _to == _owner) 
					// token can be transferred if the reciver is alreay holding tokens and already counted in currentTotalInvestors
					// or receiver is the company account. Company account do not count in currentTotalInvestors
					return 1;
				else {
					if(  currentTotalInvestors < allowedInvestors  )
						// currentTotalInvestors is within limits of allowedInvestors
						return 1;
					else {
						// In this section currentTotalInvestors = allowedInvestors and no more transaction are allowed,  
						// except following conditions 
						// if whole balance is being transferred from sender to another whitelisted investor with 0 balance  and sender is no owner
						// in this situation any sender cannot send partial balance to new receiver as it will exceed allowedInvestors limt 
						// sending the whole balance will exclude current holder from allowedInvestors and new receiver will be added in allowedInvestors 
						// owner is excluded in this situation because if he send partial or full balance to new investor then it will exceed allowedInvestors
						if( _balances[_from] == value && _balances[_to] == 0 && _from != _owner)    
							return 1;
						else
							return 0;
					}
				}
			}

    }

    function messageForTransferRestriction (uint8 restrictionCode)
	override
    public	
    pure 
	returns (string memory message)
    {
        if (restrictionCode == 1) 
            message = "Whitelisted";
         else 
            message = "Not Whitelisted";
    }
	//-----------------------------------------------------------------------




 	function totalSupply() 
	override
	external 
	view 
	returns (uint256) {
		return _totalSupply;
	}


    function balanceOf(address account) 
	override
    external 
    view 
    returns (uint256) {
        return _balances[account];
    }
	


    function approve(
        address spender,
        uint256 amount
    )  
	override
	external 
	returns (bool)
	{
        require(spender != address(0), "Zero address not allowed");
		require(amount > 0, "Amount cannot be 0");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
		return true;
    }


 
    function allowance(address ownby, address spender) 
	override
	external 
	view 
	returns (uint256) {
        return _allowances[ownby][spender];
    }



    function transfer(
        address recipient,
        uint256 amount
    ) 	
	override
	external 
	notRestricted (msg.sender, recipient, amount)
	returns (bool)
	{
		transferSharesBetweenInvestors ( msg.sender, recipient, amount );
		return true;
    }




    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) 
	override
	external 
	notRestricted (sender, recipient, amount)
	returns (bool)	
	{	
        require(_allowances[sender][msg.sender] >= amount, "Amount cannot be greater than Allowance" );
		transferSharesBetweenInvestors ( sender, recipient, amount );
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

		return true;
    }


	// Transfer tokens from one account to other
	// Also manage current number of account holders
	function transferSharesBetweenInvestors (
        address sender,
        address recipient,
        uint256 amount	
	)
	internal
	{
        	require(_balances[sender] >= amount, " Amount greater than sender balance");
			
			// owner account is not counted in currentTotalInvestors in below conditions
			
			_balances[sender] = _balances[sender] - amount;
			if( _balances[sender] == 0 && sender != _owner )
				currentTotalInvestors = currentTotalInvestors - 1;		

			if( _balances[recipient] == 0 && recipient != _owner )
				currentTotalInvestors = currentTotalInvestors + 1;
			_balances[recipient] = _balances[recipient] + amount;

			emit Transfer(sender, recipient, amount);
	}



    function mint(address account, uint256 amount) 
	onlyOwner 
	external 
	returns (bool)	{
        require(account != address(0), "Zero address not allowed");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
		return true;
    }


    function burn(address account, uint256 amount) 
	onlyOwner
	external 
	returns (bool)	{
        require(account != address(0), "Zero address not allowed");
        require(_balances[account] >= amount, "Amount greater than balance");

        _totalSupply = _totalSupply - amount;
        _balances[account] = _balances[account] - amount;
        emit Transfer(account, address(0), amount);
		return true;
    }

}