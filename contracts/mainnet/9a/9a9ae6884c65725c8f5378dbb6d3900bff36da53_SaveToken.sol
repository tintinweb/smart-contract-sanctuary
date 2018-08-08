pragma solidity ^0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
	function mul(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) pure internal returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) pure internal returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) pure internal returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;


	/**
	 * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	 * account.
	 */
	function Ownable() public {
		owner = msg.sender;
	}


	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert();
		}
		_;
	}


	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
	 * @param newOwner The address to transfer ownership to.
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
		}
	}

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
	uint256 public tokenTotalSupply;

	function balanceOf(address who) public view returns(uint256);

	function allowance(address owner, address spender) public view returns(uint256);

	function transfer(address to, uint256 value) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function transferFrom(address from, address to, uint256 value) public returns (bool success);

	function approve(address spender, uint256 value) public returns (bool success);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() public view returns (uint256 availableSupply);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract SaveToken is ERC20, Ownable {
	using SafeMath for uint;

	string public name = "SaveToken";
	string public symbol = "SAVE";
	uint public decimals = 18;

	mapping(address => uint256) affiliate;
	function getAffiliate(address who) public view returns(uint256) {
		return affiliate[who];
	}

    struct AffSender {
        bytes32 aff_code;
        uint256 amount;
    }
    uint public no_aff = 0;
	mapping(uint => AffSender) affiliate_senders;
	function getAffiliateSender(bytes32 who) public view returns(uint256) {
	    
	    for (uint i = 0; i < no_aff; i++) {
            if(affiliate_senders[i].aff_code == who)
            {
                return affiliate_senders[i].amount;
            }
        }
        
		return 1;
	}
	function getAffiliateSenderPosCode(uint pos) public view returns(bytes32) {
	    if(pos >= no_aff)
	    {
	        return 1;
	    }
	    return affiliate_senders[pos].aff_code;
	}
	function getAffiliateSenderPosAmount(uint pos) public view returns(uint256) {
	    if(pos >= no_aff)
	    {
	        return 2;
	    }
	    return affiliate_senders[pos].amount;
	}

	uint256 public tokenTotalSupply = 0;
	uint256 public trashedTokens = 0;
	uint256 public hardcap = 350 * 1000000 * (10 ** decimals); // 350 million tokens

	uint public ethToToken = 6000; // 1 eth buys 6 thousands tokens
	uint public noContributors = 0;


	//-----------------------------bonus periods
	uint public tokenBonusForFirst = 10; // multiplyer in %
	uint256 public soldForFirst = 0;
	uint256 public maximumTokensForFirst = 55 * 1000000 * (10 ** decimals); // 55 million

	uint public tokenBonusForSecond = 5; // multiplyer in %
	uint256 public soldForSecond = 0;
	uint256 public maximumTokensForSecond = 52.5 * 1000000 * (10 ** decimals); // 52 million 500 thousands

	uint public tokenBonusForThird = 4; // multiplyer in %
	uint256 public soldForThird = 0;
	uint256 public maximumTokensForThird = 52 * 1000000 * (10 ** decimals); // 52 million

	uint public tokenBonusForForth = 3; // multiplyer in %
	uint256 public soldForForth = 0;
	uint256 public maximumTokensForForth = 51.5 * 1000000 * (10 ** decimals); // 51 million 500 thousands

	uint public tokenBonusForFifth = 0; // multiplyer in %
	uint256 public soldForFifth = 0;
	uint256 public maximumTokensForFifth = 50 * 1000000 * (10 ** decimals); // 50 million

	uint public presaleStart = 1519344000; //2018-02-23T00:00:00+00:00
	uint public presaleEnd = 1521849600; //2018-03-24T00:00:00+00:00
    uint public weekOneStart = 1524355200; //2018-04-22T00:00:00+00:00
    uint public weekTwoStart = 1525132800; //2018-05-01T00:00:00+00:00
    uint public weekThreeStart = 1525824000; //2018-05-09T00:00:00+00:00
    uint public weekFourStart = 1526601600; //2018-05-18T00:00:00+00:00
    uint public tokenSaleEnd = 1527292800; //2018-05-26T00:00:00+00:00
    
    uint public saleOn = 1;
    uint public disown = 0;

	//uint256 public maximumTokensForReserve = 89 * 1000000 * (10 ** decimals); // 89 million
	address public ownerVault;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	/**
	 * @dev Fix for the ERC20 short address attack.
	 */
	modifier onlyPayloadSize(uint size) {
		if (msg.data.length < size + 4) {
			revert();
		}
		_;
	}

	/**
	 * @dev modifier to allow token creation only when the hardcap has not been reached
	 */
	modifier isUnderHardCap() {
		require(tokenTotalSupply <= hardcap);
		_;
	}

	/**
	 * @dev Constructor
	 */
	function SaveToken() public {
		ownerVault = msg.sender;
	}

	/**
	 * @dev transfer token for a specified address
	 * @param _to The address to transfer to.
	 * @param _value The amount to be transferred.
	 */
	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);

		return true;
	}

	/**
	 * @dev Transfer tokens from one address to another
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amout of tokens to be transfered
	 */
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
		uint256 _allowance = allowed[_from][msg.sender];
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);

		return true;
	}

	/**
	 * @dev Transfer tokens from one address to another according to off exchange agreements
	 * @param _from address The address which you want to send tokens from
	 * @param _to address The address which you want to transfer to
	 * @param _value uint256 the amount of tokens to be transferred
	 */
	function masterTransferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public onlyOwner returns (bool success) {
	    if(disown == 1) revert();
	    
		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		Transfer(_from, _to, _value);

		return true;
	}

	function totalSupply() public view returns (uint256 availableSupply) {
		return tokenTotalSupply;
	}

	/**
	 * @dev Gets the balance of the specified address.
	 * @param _owner The address to query the the balance of.
	 * @return An uint256 representing the amount owned by the passed address.
	 */
	function balanceOf(address _owner) public view returns(uint256 balance) {
		return balances[_owner];
	}

	/**
	 * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	 * @param _spender The address which will spend the funds.
	 * @param _value The amount of tokens to be spent.
	 */
	function approve(address _spender, uint256 _value) public returns (bool success) {

		// To change the approve amount you first have to reduce the addresses`
		//  allowance to zero by calling `approve(_spender, 0)` if it is not
		//  already 0 to mitigate the race condition described here:
		//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
			revert();
		}

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);

		return true;
	}

	/**
	 * @dev Function to check the amount of tokens than an owner allowed to a spender.
	 * @param _owner address The address which owns the funds.
	 * @param _spender address The address which will spend the funds.
	 * @return A uint256 specifying the amount of tokens still available for the spender.
	 */
	function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	/**
	 * @dev Allows the owner to change the token exchange rate.
	 * @param _ratio the new eth to token ration
	 */
	function changeEthToTokenRation(uint8 _ratio) public onlyOwner {
		if (_ratio != 0) {
			ethToToken = _ratio;
		}
	}

	/**
	 * @dev convenience show balance
	 */
	function showEthBalance() view public returns(uint256 remaining) {
		return this.balance;
	}

	/**
	 * @dev burn tokens if need to
	 * @param value token with decimals
	 * @param from burn address
	 */
	function decreaseSupply(uint256 value, address from) public onlyOwner returns (bool) {
	    if(disown == 1) revert();
	    
		balances[from] = balances[from].sub(value);
		trashedTokens = trashedTokens.add(value);
		tokenTotalSupply = tokenTotalSupply.sub(value);
		Transfer(from, 0, value);
		return true;
	}

	/**
	 *  Send ETH with affilate code.
	 */
	function BuyTokensWithAffiliate(address _affiliate) public isUnderHardCap payable
	{
		affiliate[_affiliate] += msg.value;
		if (_affiliate == msg.sender){  revert(); }
		BuyTokens();
	}

	/**
	 *  Allows owner to create tokens without ETH
	 */
	function mintTokens(address _address, uint256 amount) public onlyOwner isUnderHardCap
	{
	    if(disown == 1) revert();
	    
		if (amount + tokenTotalSupply > hardcap) revert();
		if (amount < 1) revert();

		//add tokens to balance
		balances[_address] = balances[_address] + amount;

		//increase total tokens
		tokenTotalSupply = tokenTotalSupply.add(amount);
		Transfer(this, _address, amount);
		noContributors++;
	}

	/**
	 *  @dev Change owner vault.
	 */
	function changeOwnerVault(address new_vault) public onlyOwner
	{
	    ownerVault = new_vault;
    }
    
	/**
	 *  @dev Change periods.
	 */
	function changePeriod(uint period_no, uint new_value) public onlyOwner
	{
		if(period_no == 1)
		{
		    presaleStart = new_value;
		}
		else if(period_no == 2)
		{
		    presaleEnd = new_value;
		}
		else if(period_no == 3)
		{
		    weekOneStart = new_value;
		}
		else if(period_no == 4)
		{
		    weekTwoStart = new_value;
		}
		else if(period_no == 5)
		{
		    weekThreeStart = new_value;
		}
		else if(period_no == 6)
		{
		    weekFourStart = new_value;
		}
		else if(period_no == 7)
		{
		    tokenSaleEnd = new_value;
		}
	}

	/**
	 *  @dev Change saleOn.
	 */
	function changeSaleOn(uint new_value) public onlyOwner
	{
	    if(disown == 1) revert();
	    
		saleOn = new_value;
	}

	/**
	 *  @dev No more god like.
	 */
	function changeDisown(uint new_value) public onlyOwner
	{
	    if(new_value == 1)
	    {
	        disown = 1;
	    }
	}

	/**
	 * @dev Allows anyone to create tokens by depositing ether.
	 */
	function BuyTokens() public isUnderHardCap payable {
		uint256 tokens;
		uint256 bonus;

        if(saleOn == 0) revert();
        
		if (now < presaleStart) revert();

		//this is pause period
		if (now >= presaleEnd && now <= weekOneStart) revert();

		//sale has ended
		if (now >= tokenSaleEnd) revert();

		//pre-sale
		if (now >= presaleStart && now <= presaleEnd)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForFirst).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForFirst = soldForFirst.add(tokens);
			if (soldForFirst > maximumTokensForFirst) revert();
		}

		//public first week
		if (now >= weekOneStart && now <= weekTwoStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForSecond).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForSecond = soldForSecond.add(tokens);
			if (soldForSecond > maximumTokensForSecond.add(maximumTokensForFirst).sub(soldForFirst)) revert();
		}

		//public second week
		if (now >= weekTwoStart && now <= weekThreeStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForThird).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForThird = soldForThird.add(tokens);
			if (soldForThird > maximumTokensForThird.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond)) revert();
		}

		//public third week
		if (now >= weekThreeStart && now <= weekFourStart)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForForth).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForForth = soldForForth.add(tokens);
			if (soldForForth > maximumTokensForForth.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond).add(maximumTokensForThird).sub(soldForThird)) revert();
		}

		//public forth week
		if (now >= weekFourStart && now <= tokenSaleEnd)
		{
			bonus = ethToToken.mul(msg.value).mul(tokenBonusForFifth).div(100);
			tokens = ethToToken.mul(msg.value).add(bonus);
			soldForFifth = soldForFifth.add(tokens);
			if (soldForFifth > maximumTokensForFifth.add(maximumTokensForFirst).sub(soldForFirst).add(maximumTokensForSecond).sub(soldForSecond).add(maximumTokensForThird).sub(soldForThird).add(maximumTokensForForth).sub(soldForForth)) revert();
		}

		if (tokens == 0)
		{
			revert();
		}

        if (tokens + tokenTotalSupply > hardcap) revert();
		
		//add tokens to balance
		balances[msg.sender] = balances[msg.sender] + tokens;

		//increase total tokens
		tokenTotalSupply = tokenTotalSupply.add(tokens);
		Transfer(this, msg.sender, tokens);
		noContributors++;
	}

	/**
    * @dev Allows the owner to send the funds to the vault.
    * @param _amount the amount in wei to send
    */
	function withdrawEthereum(uint256 _amount) public onlyOwner {
		require(_amount <= this.balance); // wei

		if (!ownerVault.send(_amount)) {
			revert();
		}
		Transfer(this, ownerVault, _amount);
	}


	// 	function getReservedTokens() public view returns (uint256)
	// 	{
	// 		if (checkIsPublicTime() == false) return 0;
	// 		return hardcap - maximumTokensForPublic + maximumTokensForPrivate - tokenTotalSupply;
	// 	}

	function transferReservedTokens(uint256 _amount) public onlyOwner
	{
	    if(disown == 1) revert();
	    
		if (now <= tokenSaleEnd) revert();

		assert(_amount <= (hardcap - tokenTotalSupply) );

		balances[ownerVault] = balances[ownerVault] + _amount;
		tokenTotalSupply = tokenTotalSupply + _amount;
		Transfer(this, ownerVault, _amount);
	}

	function() external payable {
		BuyTokens();

	}
}