pragma solidity ^0.4.23;

// File: contracts\Math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts\Owned.sol

// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned{

    address public owner;
    address public newOwner;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransfered(address indexed _from, address indexed _to);
    event AdminChange(address indexed _admin, bool _status);
    event OwnershipTransferCancelled();

    modifier onlyOwner{
        require(isOwner(msg.sender) == true);
        _;
    }

    modifier onlyAdmin{
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyOwnerOrAdmin{
        require(isOwner(msg.sender) == true || isAdmin[msg.sender] == true);
        _;
    }

    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner returns (bool){
        require(_newOwner != address(0));
        require(_newOwner != address(this));
        require(_newOwner != owner);
        owner = _newOwner;
        emit OwnershipTransferProposed(owner, _newOwner);
        
        return true;
    }

    function cancelOwnershipTransfer() public onlyOwner returns (bool){
        if(newOwner == address(0)){
            return true;
        }

        newOwner = address(0);
        emit OwnershipTransferCancelled();

        return true;
    }

    function isOwner(address _address) public view returns (bool){
        return (_address == owner);
    }

    function isOwnerOrAdmin (address _address) public view returns (bool){
        return (isOwner(_address) || isAdmin[_address]);
    }
    
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnershipTransfered(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _a) public onlyOwner{
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner{
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }
}

// File: contracts\Finalizable.sol

contract Finalizable is Owned{ 
	bool public finalized;

	event Finalized();

	constructor () public Owned(){
		finalized = false;
	}

	function finalize() public onlyOwner returns (bool){
		require(!finalized);

		finalized = true;
		emit Finalized();

		return true;
	}
}

// File: contracts\Token.sol

contract Token is Owned, Finalizable {
    using SafeMath for uint256;

    string  public constant name = &quot;We Inc Token&quot;;
    string  public constant symbol = &quot;WINC&quot;;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public tokensOutInMarket;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Burn(address indexed _burner, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor () public Finalizable(){
        totalSupply = 120000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        tokensOutInMarket = 0;

        //Constructor fire a Transfer event if tokens are assigned to an account.
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function decimals() public view returns (uint8){
        return decimals;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply;
    }

    //@dev Gets the balance of the specified address
    //@param _owner The address to query the balance of.
    //@return An uint256 representing the amount owned by the passed address
    function balanceOf(address _owner) public view returns(uint256){
        return balanceOf[_owner];
    }

    function burn(uint256 _value) public{
        _burn(msg.sender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance[_owner][_spender];
    }

    function tokensOutInMarket() public view returns (uint256){
        return tokensOutInMarket;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        require(balanceOf[_to] + _value > _value);

        validateTransfer(msg.sender, _to);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);

        return true;
    }

    function validateTransfer(address _from, address _to) private view{
        require(_to != address(0));

        //Once the token is finalized, everybody can transfer tokens
        if(finalized){
            return;
        }

        if(isOwner(_to)){
            return;
        }

        //Before the token is finalized, only owner and admin are allowed to initiate transfer
        //this allows moving token while the sale is still ongoing
        require(isOwnerOrAdmin(_from));
    }

    function _burn(address _who, uint256 _value) internal{
        require(_value <= balanceOf[_who]);

        balanceOf[_who] = balanceOf[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    //@dev Burns a specific amount of tokens from the target address and decrements allowance
    //@param _from address The address which you want to send tokens from
    //@param _value uint256 The amount of tokens to be burned
    function burnFrom(address _from, uint256 _value) public{
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}

// File: contracts\tokenSale.sol

contract TokenSale is Token{
    using SafeMath for uint256;

    //Token
    Token public token;

    //Pricing
    uint256 public tokensPerEth;
    uint256 public bonus;
    uint256 public maxContribution;
    uint256 public minContribution;
    uint256 public tokenConversionFactor;
    uint256 public totalEthCap;

    //Sales status
    uint256 public tokenSold;
    uint256 public totalEthCollected;
    mapping(address => uint256) public ethContributed;
    mapping(address => uint256) public accountTokensPurchased;
    bool public saleSuspended;
    bool crowdsaleClosed;
    uint256 public startTime;
    uint256 public endTime;

    //Wallet
    address public walletAddress;

    //Admin
    address public admin;

    //whitelisting
    mapping(address => bool) whitelist;
    uint256 public numberWhitelisted = 0;
    //only whitelisted person can contribute in the current stage
    uint256 public currentStage;
    mapping(uint256 => uint256) public stageBonus;

    //Events
    event Initialized();
    event TokenPerEthUpdated(uint256 _newValue);
    event MaxContributionUpdated(uint256 _newMax);
    event BonusUpdate(uint256 _newValue);
    event SaleWindowUpdated(uint256 _startTime, uint256 _endTime);
    event SaleSuspended();
    event SaleResumed();
    event TokenPuchased(address indexed _benificiary, uint256 _cost, uint256 _token);
    event ToeknReclaimed(uint256 _amount);
    event Whitelisted(address indexed _account, uint256 _countWhitelisted);
    event CurrentStageUpdated(uint256 _newStage);
    event StageBonusUpdated(uint256 _stage, uint256 _bonus);
    event SaleClosed();
    event walletAddressUpdated(address indexed _walletAddress);

    constructor (uint256 _startTime, uint256 _endTime, address _walletAddress, Token _token) public{
        require (_walletAddress != address(0));
        require (_walletAddress != address(this));
        require (_startTime < _endTime);
        require(address(token) == address(0));
        require(address(_token) != address(0));
        require(address(_token) != address(this));
        require(address(_token) != address(walletAddress));
        require(isOwnerOrAdmin(address(_token)) == false);
        
        admin = msg.sender;
        tokenSold = 0;
        totalEthCollected = 0;
        maxContribution = 100 ether;
        minContribution = 5 ether;

        //Pre sale parameters
        //Opening Eth rate = USD $460.00, WINC rate = USD $0.026
        //Therefore, 1 ETH = 17690WINC
        tokensPerEth = 17690;

        //96,000,000 / 17,690 = 5,426 ether
        totalEthCap = 5426 ether;

        walletAddress = _walletAddress;

        finalized = false;
        saleSuspended = false;
        crowdsaleClosed = false;
        startTime = _startTime;
        endTime = _endTime;
        bonus = 2000;

        //initialize stage bonus
        currentStage = 0;
        stageBonus[1] = 2000;
        stageBonus[2] = 1500;
        stageBonus[3] = 1000;
        stageBonus[4] = 500;

        token = _token;

        //This factor is used when converting cost <-> tokens 
        // 18 is te ETH -> wei Conversion
        //4 is the bonuses expressed as 0-1000 for 0.00% - 100.00%
        tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(4));
        require(tokenConversionFactor >0);
        emit Initialized();
    }

    function currentTime() public constant returns (uint256){
        return now;
    }

    //Initialie should be called by owner as part of the deployment setup phase 
    //It will associate the sale contract with the token contract and perform basic checker.
    function initialize(Token _token) external onlyOwner returns (bool){
        require(address(token) == address(0));
        require(address(_token) != address(0));
        require(address(_token) != address(this));
        require(address(_token) != address(walletAddress));
        require(isOwnerOrAdmin(address(_token)) == false);

        token = _token;

        //This factor is used when converting cost <-> tokens 
        // 18 is te ETH -> wei Conversion
        //4 is the bonuses expressed as 0-1000 for 0.00% - 100.00%
        tokenConversionFactor = 10**(uint256(18).sub(_token.decimals()).add(4));
        require(tokenConversionFactor >0);
        emit Initialized();

        return true;
    }

    //Allows owner to change the wallet address which is used for collecting ether 
    //received during the token sale.

    function setWalletAddress(address _walletAddress) external onlyOwner returns (bool){
        require(_walletAddress != address(0));
        require(_walletAddress != address(this));
        require(_walletAddress != address(token));
        require(isOwnerOrAdmin(_walletAddress) == false);

        walletAddress = _walletAddress;
        emit walletAddressUpdated(_walletAddress);

        return true;
    }

    //Allows the owner to set a bonus to apply to each stage 
    //For example, setting it to 2000 means 20% bonus
    function setBonus(uint256 _stage, uint256 _bonus) external onlyOwner returns (bool){
        require(_bonus <= 10000);
        require(currentStage < _stage);
        stageBonus[_stage] = _bonus;

        emit StageBonusUpdated(_stage, _bonus); 
        return true;
    }

    //Allows the owner to set a sale window which will allow the sale to receive contributions
    //between _startTime and _endTime. 
    //Once _endTime is reached, the sale contract will automatically stop accepting incoming contrbutions.
    function setSaleWindow(uint256 _startTime, uint256 _endTime) external onlyOwner returns(bool){
        require(_startTime > 0);
        require(_startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;

        emit SaleWindowUpdated(_startTime, _endTime);

        return true;
    }

    //Allows the owner to suspend sale until it is manually resumed at a later time
    function suspendSale() external onlyOwner returns (bool){
        if(saleSuspended == true){
            return false;
        }

        saleSuspended = true;

        emit SaleSuspended();
        return true;
    }

    //Allows the owner to resume sale
    function resume() external onlyOwner returns (bool){
        if(saleSuspended == false){
            return false;
        }

        saleSuspended = false;

        emit SaleResumed();
        return true;
    }


    //Returns the number of tokens that the user has purchased 
    //will check against max allowed
    function getUserTokenBalance(address _benificiary) internal view returns(uint256){
        return token.balanceOf(_benificiary);
    }

    //Allows the admin to determine what is the current stage of the sale 
    //It can only move forward
    //----------------------Need to automate------------
    function setCurrentStage(uint256 _stage) public onlyOwner returns (bool){
        require(_stage > 0);
        require(currentStage < _stage);

        currentStage = _stage;

        emit CurrentStageUpdated(_stage);
        return true;
    }

    //Allows the owner of admin to add people from the whitelist 
    function setWhitelisted(address _address) internal onlyOwnerOrAdmin returns (bool){
        require(_address != address(0));
        require(_address != address(this));
        require(_address != walletAddress);

        if(whitelist[_address]){
            return false;
        }
        whitelist[_address] = true;
        numberWhitelisted = numberWhitelisted.add(1);

        emit Whitelisted(_address, numberWhitelisted);
        return true;
    }

    //Allows owner to add people to whitelist 
    function addWhitelisted(address _address) public onlyOwnerOrAdmin returns (bool){
        return setWhitelisted(_address);
    }

    //Allow the owner to add, people from the whitelist in batches
    //Do not exceed the tx gas limit or block gas limit
    function addwhitelistedBatch(address[] _address) public onlyOwnerOrAdmin{
        require(_address.length > 0);

        for(uint256 i = 0; i < _address.length; i++){
            setWhitelisted(_address[i]);
        }
    }

    function updatedTokensPerEth(uint256 _tokensPerEth) public onlyOwner{
        tokensPerEth = _tokensPerEth;
        emit TokenPerEthUpdated(tokensPerEth);
    }

    //information
    function tokensToEth(uint256 _tokens) public view returns (uint256){
        return _tokens.div(tokensPerEth);
    }

    function ethToTokens(uint256 _eth) public view returns(uint256){
        return _eth.mul(tokensPerEth);
    }

    //Contribution 
    function () public payable {
        require(!crowdsaleClosed);
        buyTokensInternal(stageBonus[currentStage]);
    }

    function buyTokensInternal(uint256 _currentBonus) internal{
        address _benificiary = msg.sender;
        require(whitelist[_benificiary] == true);
        require(!finalized);
        require(!saleSuspended);
        require(currentTime() >= startTime);
        require(currentTime() <= endTime);
        require(msg.value >= minContribution);
        require(_benificiary != address(0));
        require(_benificiary != address(this));
        require(_benificiary != address(token));

        //The wallet collecting ETH cannot directly purchase tokens.
        require(_benificiary != address(walletAddress));

        //check how many tokens are still available for sale 
        uint256 saleBalance = token.balanceOf(address(this));
        require(saleBalance > 0);

        //Calculate how many tokens the contributor could purchase based on ETH recieved
        uint256 tokens = msg.value.mul(tokensPerEth).mul(_currentBonus.add(1000)).div(tokenConversionFactor);
        require(tokens > 0);
        uint256 ethContribution = msg.value;
        uint256 refund = 0;
        uint256 ethToContribute = totalEthCap.sub(totalEthCollected);

        //calculate what is the max amount of ETH that the contributor should be allowed to purchase 
        uint256 ethQuotaBalance = maxContribution.sub(ethContributed[_benificiary]);



        //contributor send more ETH than allowed
        if(ethContribution > ethQuotaBalance){
            //ETH allowed is more than balance left
            if(ethQuotaBalance > ethToContribute){
                refund = ethContribution.sub(ethToContribute);
                ethContribution = ethToContribute;              
            } else {
            refund = ethContribution.sub(ethQuotaBalance);
            ethContribution = ethQuotaBalance;
            }            
        }
///---------------need further update wrong logic---------------------
        tokens = ethContribution.mul(tokensPerEth).mul(_currentBonus.add(1000)).div(tokenConversionFactor);

        //This is the actual amount of ETH that can be sent to the wallet
        walletAddress.transfer(ethContribution);

        //update ICO status 
        tokenSold = tokenSold.add(tokens);
        totalEthCollected = totalEthCollected.add(ethContribution);

        //Transfer token to benificiary 
        require(token.transfer(_benificiary, tokens));

        //refund excess ETH if needed
        if(refund > 0){
            msg.sender.transfer(refund);
        }

        emit TokenPuchased(_benificiary, ethContribution, tokens);

        accountTokensPurchased[_benificiary] = accountTokensPurchased[_benificiary].add(tokens);

    }

}