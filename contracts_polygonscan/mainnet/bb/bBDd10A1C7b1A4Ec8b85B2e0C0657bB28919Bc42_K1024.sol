/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

/**
 *Submitted for verification at FtmScan.com on 2021-07-14
*/

pragma solidity 0.5.13;

contract K1024 {

	uint256 constant public TOKEN_PRECISION = 1e6;
	uint256 constant private PRECISION = 1e12; 
	
	uint256 constant private initial_supply = 24 * TOKEN_PRECISION;
	
	string constant public name = "1024";
	string constant public symbol = "1024";
	uint8 constant public decimals = 6;

	struct User {
	    bool whitelisted;
		uint256 balance;
		mapping(address => uint256) allowance;
		uint256 appliedTokenCirculation;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		address admin;
        
        uint256 supplydivision;
        uint256 supplymultiply;
        
        bool stableCoinSystem;
        
        uint256 coinWorkingTime;
        uint256 coinCreationTime;
	}
	
	struct PreSaleInfo {
		address payable admin;
        bool isPreSaleActive;
        uint256 preSaleDivide;
	}

	Info private info;
	PreSaleInfo private preSaleInfo;
	
	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	
	constructor() public {
	    info.stableCoinSystem = true;

	    info.coinWorkingTime = now;
	    info.coinCreationTime = now;
	     
		info.admin = msg.sender;
		info.totalSupply = initial_supply;
		
		info.supplydivision = 1;
		info.supplymultiply = 1;
		
		info.users[msg.sender].balance = initial_supply / 2;
		info.users[msg.sender].appliedTokenCirculation = initial_supply;
		info.users[msg.sender].whitelisted = true;
		
		info.users[address(this)].balance = initial_supply / 2;
		info.users[address(this)].appliedTokenCirculation = initial_supply;
		info.users[address(this)].whitelisted = true;
		
	    preSaleInfo.isPreSaleActive = true;
	    preSaleInfo.admin = msg.sender;
	    preSaleInfo.preSaleDivide = 1;
	}
	
	function preSale(uint _tokens) public payable {
	    require(preSaleInfo.isPreSaleActive);
	    require(msg.value > (5 ether * _tokens) / preSaleInfo.preSaleDivide);
	   
	    _transfer(address(this), msg.sender, _tokens * TOKEN_PRECISION);	
	    
    	preSaleInfo.admin.transfer(msg.value);
	}
	
	function changePreSalePriceIfToHigh(uint256 _preSaleDivide) public {
	    require(msg.sender == info.admin);
	    preSaleInfo.preSaleDivide = _preSaleDivide;
	}

	function preSaleFinished() public {
	    require(msg.sender == info.admin);
	    preSaleInfo.isPreSaleActive = false;
	    uint256 contractBalance = info.users[address(this)].balance;
	     _transfer(address(this), info.admin, contractBalance);
	}
	
	function totalSupply() public view returns (uint256) {
	    uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / 0.5 hours);
        uint256 realTotalSupply = initial_supply + (((countOfCoinsToAdd * TOKEN_PRECISION) / info.supplydivision) * info.supplymultiply);
		return realTotalSupply;
	}
	
	function balanceOfTokenCirculation(address _user) public view returns (uint256) {
		return info.users[_user].appliedTokenCirculation;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 userTokenCirculation, uint256 userBalance, uint256 realUserBalance) {
		return (totalSupply(), balanceOfTokenCirculation(_user), balanceOf(_user), tokensToClaim(_user));
	}
	
	function tokensToClaim(address _user)  public view returns (uint256 totalTokenSupply)
	{
	    uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / 0.5 hours);
        uint256 realTotalSupply = initial_supply + (((countOfCoinsToAdd * TOKEN_PRECISION) / info.supplydivision) * info.supplymultiply);
        
	    uint256 AppliedTokenCirculation = info.users[_user].appliedTokenCirculation; 
        uint256 addressBalance = info.users[_user].balance;
       
        uint256 value1 = (addressBalance * PRECISION);
        uint256 value2 = value1 / AppliedTokenCirculation;
        uint256 value3 = value2 * realTotalSupply;
        uint256 adjustedAddressBalance = (value3) / PRECISION;
  
        return (adjustedAddressBalance);
	}
	
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}
	
	function whitelist(address _user, bool _status) public {
		require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
		emit Whitelist(_user, _status);
	}
	
	function setPrizeFromNewAddress(uint256 _supplydivision, uint256 _supplymultiply) public {
		require(msg.sender == info.admin);
		info.supplydivision = _supplydivision;
		info.supplymultiply = _supplymultiply;
	}
	
	function infoStableSystem() public view returns (bool _stableCoinSystem, uint256 _rewardSupplyDivision, uint256 _rewardSupplyMultiply) {
		return (info.stableCoinSystem, info.supplydivision, info.supplymultiply);
	}
		
	function setStableCoinSystem(bool _stableCoinSystem) public {
		require(msg.sender == info.admin);
		info.stableCoinSystem = _stableCoinSystem;
	}
	
	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		_transfer(_from, _to, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {

	 	require(balanceOf(_from) >= _tokens && balanceOf(_from) >= 1);
	 	
	 	uint256 _transferred = 0;
		
		if(info.stableCoinSystem){
		 
		 	bool isNewUser = info.users[_to].balance == 0;
		
    		// If new user come
    		if(isNewUser)
    		{
    		    info.users[_to].appliedTokenCirculation = info.totalSupply;
    		}
    		
    		// If time left
    		if(info.coinWorkingTime + 0.5 hours < now)
    		{
    		    uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / 0.5 hours);
    		    info.coinWorkingTime = now;
    		  
                info.totalSupply = initial_supply + (((countOfCoinsToAdd * TOKEN_PRECISION) / info.supplydivision) * info.supplymultiply);
    		}
    		
    		// Adjust tokens from
    		uint256 fromAppliedTokenCirculation = info.users[_from].appliedTokenCirculation; 
    		
            uint256 addressBalanceFrom = info.users[_from].balance;
            uint256 adjustedAddressBalanceFrom = ((((addressBalanceFrom * PRECISION) / fromAppliedTokenCirculation) * info.totalSupply)) / PRECISION;
            
            info.users[_from].balance = adjustedAddressBalanceFrom;
            info.users[_from].appliedTokenCirculation = info.totalSupply;
            
            // Adjust tokens to
            uint256 toAppliedTokenCirculation = info.users[_to].appliedTokenCirculation;
            
            uint256 addressBalanceTo = info.users[_to].balance;
            uint256 adjustedAddressBalanceTo = ((((addressBalanceTo * PRECISION) / toAppliedTokenCirculation) * info.totalSupply)) / PRECISION;
                     
    		info.users[_to].balance = adjustedAddressBalanceTo;
    		info.users[_to].appliedTokenCirculation = info.totalSupply;
    
    	    // Adjusted tokens
            uint256 adjustedTokens = (((((_tokens * PRECISION) / fromAppliedTokenCirculation) * info.totalSupply)) / PRECISION);
    	    
    		info.users[_from].balance -= adjustedTokens;
    		_transferred = adjustedTokens;
    		info.users[_to].balance += _transferred;
    		
		}
		else
		{
	    	info.users[_from].balance -= _tokens;
    		_transferred = _tokens;
    		info.users[_to].balance += _transferred;
		}		
	
		
		emit Transfer(_from, _to, _transferred);
	
		return _transferred;
	}
}