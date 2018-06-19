pragma solidity ^0.4.19;

contract EthermiumTokenList {
	function safeMul(uint a, uint b) returns (uint) {
	    uint c = a * b;
	    assert(a == 0 || c / a == b);
	    return c;
	}

	function safeSub(uint a, uint b) returns (uint) {
	    assert(b <= a);
	    return a - b;
	}

	function safeAdd(uint a, uint b) returns (uint) {
	    uint c = a + b;
	    assert(c>=a && c>=b);
	    return c;
	}
	
	struct Token {
		address tokenAddress; // token ethereum address
		uint256 decimals; // number of token decimals
		string url; // token website url
		string symbol; // token symbol
		string name; // token name
		string logoUrl; // link to logo
		bool verified; // true if the url was verified
		address owner; // address from which the token was added
		bool enabled; // owner of the token can disable it
	}

	address public owner;
	mapping (address => bool) public admins;
	address public feeAccount;
	address[] public tokenList;
	mapping(address => Token) public tokens; 
	uint256 public listTokenFee; // in wei per block
	uint256 public modifyTokenFee; // in wei

	event TokenAdded(address tokenAddress, uint256 decimals, string url, string symbol, string name, address owner, string logoUrl);
	event TokenModified(address tokenAddress, uint256 decimals, string url, string symbol, string name, bool enabled, string logoUrl);
	event FeeChange(uint256 listTokenFee, uint256 modifyTokenFee);
	event TokenVerify(address tokenAddress, bool verified);
	event TokenOwnerChanged(address tokenAddress, address newOwner);

	modifier onlyOwner {
		assert(msg.sender == owner);
		_;
	}

	modifier onlyAdmin {
	    if (msg.sender != owner && !admins[msg.sender]) throw;
	    _;
	}

	function setAdmin(address admin, bool isAdmin) public onlyOwner {
    	admins[admin] = isAdmin;
  	}

  	function setOwner(address newOwner) public onlyOwner {
	    owner = newOwner;
	}

	function setFeeAccount(address feeAccount_) public onlyOwner {
	    feeAccount = feeAccount_;
	}

	function setFees(uint256 listTokenFee_, uint256 modifyTokenFee_) public onlyOwner
	{
		listTokenFee = listTokenFee_;
		modifyTokenFee = modifyTokenFee_;
		FeeChange(listTokenFee, modifyTokenFee);
	}

	

	function EthermiumTokenList (address owner_, address feeAccount_, uint256 listTokenFee_, uint256 modifyTokenFee_)
	{
		owner = owner_;
		feeAccount = feeAccount_;
		listTokenFee = listTokenFee_;
		modifyTokenFee = modifyTokenFee_;
	}


	function addToken(address tokenAddress, uint256 decimals, string url, string symbol, string name, string logoUrl) public payable
	{
		require(tokens[tokenAddress].tokenAddress == address(0x0));
		if (msg.sender != owner && !admins[msg.sender])
		{
			require(msg.value >= listTokenFee);
		}

		tokens[tokenAddress] = Token({
			tokenAddress: tokenAddress, 
			decimals: decimals,
			url: url,
			symbol: symbol,
			name: name,
			verified: false,
			owner: msg.sender,
			enabled: true,
			logoUrl: logoUrl
		});
		
		if (!feeAccount.send(msg.value)) throw;
		tokenList.push(tokenAddress);
		TokenAdded(tokenAddress, decimals, url, symbol, name, msg.sender, logoUrl);
	}

	function modifyToken(address tokenAddress, uint256 decimals, string url, string symbol, string name,  string logoUrl, bool enabled) public payable
	{
		require(tokens[tokenAddress].tokenAddress != address(0x0));
		require(msg.sender == tokens[tokenAddress].owner);

		if (keccak256(url) != keccak256(tokens[tokenAddress].url))
			tokens[tokenAddress].verified = false;

		tokens[tokenAddress].decimals = decimals;
		tokens[tokenAddress].url = url;
		tokens[tokenAddress].symbol = symbol;
		tokens[tokenAddress].name = name;
		tokens[tokenAddress].enabled = enabled;
		tokens[tokenAddress].logoUrl = logoUrl;

		TokenModified(tokenAddress, decimals, url, symbol, name, enabled, logoUrl);
	}

	function changeOwner(address tokenAddress, address newOwner) public
	{
		require(tokens[tokenAddress].tokenAddress != address(0x0));
		require(msg.sender == tokens[tokenAddress].owner || msg.sender == owner);

		tokens[tokenAddress].owner = newOwner;

		TokenOwnerChanged(tokenAddress, newOwner);
	}

	function setVerified(address tokenAddress, bool verified_) onlyAdmin public
	{
		require(tokens[tokenAddress].tokenAddress != address(0x0));

		tokens[tokenAddress].verified = verified_;

		TokenVerify(tokenAddress, verified_);
	}

	function isTokenInList(address tokenAddress) public constant returns (bool)
	{
		if (tokens[tokenAddress].tokenAddress != address(0x0))
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	function getToken(address tokenAddress) public constant returns ( uint256, string, string, string, bool, string)
	{
		require(tokens[tokenAddress].tokenAddress != address(0x0));
		
		return ( 
			tokens[tokenAddress].decimals, 
			tokens[tokenAddress].url,
			tokens[tokenAddress].symbol,
			tokens[tokenAddress].name,
			tokens[tokenAddress].enabled,
			tokens[tokenAddress].logoUrl
		);
	}

	function getTokenCount() public constant returns(uint count)
	{
		return tokenList.length;
	}

	function isTokenVerified(address tokenAddress) public constant returns (bool)
	{
		if (tokens[tokenAddress].tokenAddress != address(0x0) && tokens[tokenAddress].verified)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

}