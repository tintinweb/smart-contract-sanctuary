pragma solidity ^0.4.13;


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
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract CRCToken is StandardToken,Ownable{
	//the base info of the token 
	string public name;
	string public symbol;
	string public constant version = "1.0";
	uint256 public constant decimals = 18;

	uint256 public constant MAX_SUPPLY = 500000000 * 10**decimals;
	uint256 public constant quota = MAX_SUPPLY/100;

	//the percentage of all usages
	uint256 public constant allOfferingPercentage = 50;
	uint256 public constant teamKeepingPercentage = 15;
	uint256 public constant communityContributionPercentage = 35;

	//the quota of all usages
	uint256 public constant allOfferingQuota = quota*allOfferingPercentage;
	uint256 public constant teamKeepingQuota = quota*teamKeepingPercentage;
	uint256 public constant communityContributionQuota = quota*communityContributionPercentage;

	//the cap of diff offering channel
	//this percentage must less the the allOfferingPercentage
	uint256 public constant privateOfferingPercentage = 10;
	uint256 public constant privateOfferingCap = quota*privateOfferingPercentage;

	//diff rate of the diff offering channel
	uint256 public constant publicOfferingExchangeRate = 25000;
	uint256 public constant privateOfferingExchangeRate = 50000;

	//need to edit
	address public etherProceedsAccount;
	address public crcWithdrawAccount;

	//dependency on the start day
	uint256 public fundingStartBlock;
	uint256 public fundingEndBlock;
	uint256 public teamKeepingLockEndBlock ;

	uint256 public privateOfferingSupply;
	uint256 public allOfferingSupply;
	uint256 public teamWithdrawSupply;
	uint256 public communityContributionSupply;



	// bool public isFinalized;// switched to true in operational state

	event CreateCRC(address indexed _to, uint256 _value);

	// uint256 public

	function CRCToken(){
		name = "CRCToken";
		symbol ="CRC";

		etherProceedsAccount = 0x5390f9D18A7131aC9C532C1dcD1bEAb3e8A44cbF;
		crcWithdrawAccount = 0xb353425bA4FE2670DaC1230da934498252E692bD;

		fundingStartBlock=4263161;
		fundingEndBlock=4313561;
		teamKeepingLockEndBlock=5577161;

		totalSupply = 0 ;
		privateOfferingSupply=0;
		allOfferingSupply=0;
		teamWithdrawSupply=0;
		communityContributionSupply=0;
	}


	modifier beforeFundingStartBlock(){
		assert(getCurrentBlockNum() < fundingStartBlock);
		_;
	}

	modifier notBeforeFundingStartBlock(){
		assert(getCurrentBlockNum() >= fundingStartBlock);
		_;
	}
	modifier notAfterFundingEndBlock(){
		assert(getCurrentBlockNum() < fundingEndBlock);
		_;
	}
	modifier notBeforeTeamKeepingLockEndBlock(){
		assert(getCurrentBlockNum() >= teamKeepingLockEndBlock);
		_;
	}

	modifier totalSupplyNotReached(uint256 _ethContribution,uint rate){
		assert(totalSupply.add(_ethContribution.mul(rate)) <= MAX_SUPPLY);
		_;
	}
	modifier allOfferingNotReached(uint256 _ethContribution,uint rate){
		assert(allOfferingSupply.add(_ethContribution.mul(rate)) <= allOfferingQuota);
		_;
	}	 

	modifier privateOfferingCapNotReached(uint256 _ethContribution){
		assert(privateOfferingSupply.add(_ethContribution.mul(privateOfferingExchangeRate)) <= privateOfferingCap);
		_;
	}	 
	

	modifier etherProceedsAccountOnly(){
		assert(msg.sender == getEtherProceedsAccount());
		_;
	}
	modifier crcWithdrawAccountOnly(){
		assert(msg.sender == getCrcWithdrawAccount());
		_;
	}




	function processFunding(address receiver,uint256 _value,uint256 fundingRate) internal
		totalSupplyNotReached(_value,fundingRate)
		allOfferingNotReached(_value,fundingRate)

	{
		uint256 tokenAmount = _value.mul(fundingRate);
		totalSupply=totalSupply.add(tokenAmount);
		allOfferingSupply=allOfferingSupply.add(tokenAmount);
		balances[receiver] += tokenAmount;  // safeAdd not needed; bad semantics to use here
		CreateCRC(receiver, tokenAmount);	 // logs token creation
	}


	function () payable external{
		if(getCurrentBlockNum()<=fundingStartBlock){
			processPrivateFunding(msg.sender);
		}else{
			processEthPulicFunding(msg.sender);
		}


	}

	function processEthPulicFunding(address receiver) internal
	 notBeforeFundingStartBlock
	 notAfterFundingEndBlock
	{
		processFunding(receiver,msg.value,publicOfferingExchangeRate);
	}
	

	function processPrivateFunding(address receiver) internal
	 beforeFundingStartBlock
	 privateOfferingCapNotReached(msg.value)
	{
		uint256 tokenAmount = msg.value.mul(privateOfferingExchangeRate);
		privateOfferingSupply=privateOfferingSupply.add(tokenAmount);
		processFunding(receiver,msg.value,privateOfferingExchangeRate);
	}  

	function icoPlatformWithdraw(uint256 _value) external
		crcWithdrawAccountOnly
	{
		processFunding(msg.sender,_value,1);
	}

	function teamKeepingWithdraw(uint256 tokenAmount) external
	   crcWithdrawAccountOnly
	   notBeforeTeamKeepingLockEndBlock
	{
		assert(teamWithdrawSupply.add(tokenAmount)<=teamKeepingQuota);
		assert(totalSupply.add(tokenAmount)<=MAX_SUPPLY);
		teamWithdrawSupply=teamWithdrawSupply.add(tokenAmount);
		totalSupply=totalSupply.add(tokenAmount);
		balances[msg.sender]+=tokenAmount;
		CreateCRC(msg.sender, tokenAmount);
	}

	function communityContributionWithdraw(uint256 tokenAmount) external
	    crcWithdrawAccountOnly
	{
		assert(communityContributionSupply.add(tokenAmount)<=communityContributionQuota);
		assert(totalSupply.add(tokenAmount)<=MAX_SUPPLY);
		communityContributionSupply=communityContributionSupply.add(tokenAmount);
		totalSupply=totalSupply.add(tokenAmount);
		balances[msg.sender] += tokenAmount;
		CreateCRC(msg.sender, tokenAmount);
	}

	function etherProceeds() external
		etherProceedsAccountOnly
	{
		if(!msg.sender.send(this.balance)) revert();
	}
	



	function getCurrentBlockNum()  internal returns (uint256){
		return block.number;
	}

	function getEtherProceedsAccount() internal  returns (address){
		return etherProceedsAccount;
	}


	function getCrcWithdrawAccount() internal returns (address){
		return crcWithdrawAccount;
	}

	function setName(string _name) external
		onlyOwner
	{
		name=_name;
	}

	function setSymbol(string _symbol) external
		onlyOwner
	{
		symbol=_symbol;
	}


	function setEtherProceedsAccount(address _etherProceedsAccount) external
		onlyOwner
	{
		etherProceedsAccount=_etherProceedsAccount;
	}

	function setCrcWithdrawAccount(address _crcWithdrawAccount) external
		onlyOwner
	{
		crcWithdrawAccount=_crcWithdrawAccount;
	}

	function setFundingBlock(uint256 _fundingStartBlock,uint256 _fundingEndBlock,uint256 _teamKeepingLockEndBlock) external
		onlyOwner
	{

		fundingStartBlock=_fundingStartBlock;
		fundingEndBlock = _fundingEndBlock;
		teamKeepingLockEndBlock = _teamKeepingLockEndBlock;
	}


}