pragma solidity 0.4.24;

// Code Audited and Perfected by: GDO Infotech Pvt Ltd (www.GDO.co.in) 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
    * Protection against short address attack
    */
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    address public addressFundTeam = 0xB0A4E7aA8B8746323A0bbC3f307FEAE841b85f4a;
    uint256 public fundTeam = 75 * 10**6 * (10 ** 18);

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        if (msg.sender == addressFundTeam) {
            require(checkVesting(_value, now) > 0);
        }

        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
		require(_value <= balances[msg.sender]);
		require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        require(_spender != address(0));
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        require(_spender != address(0));
		uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function checkVesting(uint256 _value, uint256 _currentTime) public view returns(uint8 _period) {
        _period = 0;
        uint256 halfYear = 1551398400; //Fri, 01 Mar 2019 00:00:00 GMT
        uint256 wholeYear = 1567296000; // Sun, 01 Sep 2019 00:00:00 GMT
        if (halfYear <= _currentTime && _currentTime < wholeYear) {
            _period = 1;
            require(balances[addressFundTeam].sub(_value) >= fundTeam.div(2));
        }
        if (wholeYear <= _currentTime) {
            _period = 2;
            require(balances[addressFundTeam].sub(_value) >= 0);
        }
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "RegistryBlocks";
    string public constant symbol = "REG";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * Peterson&#39;s Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);

        emit Transfer(_token, owner, balance);
    }
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public tokenAllocated;

    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}

interface IGetPriceFromOraclize {
    function update() external payable;
    function getRate() external view returns (uint result);
}

contract RegistryBlocksCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    mapping (address => uint256) public deposited;
    mapping(address => bool) public whitelist;
    // List of admins
    mapping (address => bool) public contractAdmins;
    // list of refund
    mapping (address => mapping (uint256 => bool)) public confirmations;


    uint256 public constant INITIAL_SUPPLY = 500 * 10**6 * (10 ** uint256(decimals));
    uint256 public fundForSale = 325 * 10**6 * (10 ** uint256(decimals));

    address public addressFundReserv = 0xeE5090f1C6920c347c1f2273A5F2b8AAc4c8b103;
    uint256 public fundReserv = 100 * 10**6 * (10 ** uint256(decimals));

    uint256 public weiMinSale = 0.1 ether;

    uint256 public countInvestor;
    uint256 softCap = 11250 * 10**3 * (10 ** uint256(decimals));
    uint256 startTime = 1535760000; //Sat, 01 Sep 2018 00:00:00 GMT
    uint256 endTime = 1541030400; //Thu, 01 Nov 2018 00:00:00 GMT


    IGetPriceFromOraclize oraclizeContact;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Burn(address indexed burner, uint256 value);
    event Refund(address indexed investor, uint256 value);

    constructor (address _owner) public
    Crowdsale(_owner)
    {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; //for test&#39;s
        transfersEnabled = true;
        totalSupply = INITIAL_SUPPLY;
        mintForOwner(owner);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public onlyWhitelist payable returns (uint256){
        require(_investor != address(0));
        uint256 tokens = 0;
        if(_investor != owner){
            uint256 weiAmount = msg.value;
            tokens = validPurchaseTokens(weiAmount);
            if (tokens == 0) {revert();}
            weiRaised = weiRaised.add(weiAmount);
            tokenAllocated = tokenAllocated.add(tokens);
            mint(_investor, tokens, owner);
            emit TokenPurchase(_investor, weiAmount, tokens);
            if(3750 * 10**3 * (10 ** uint256(decimals)) <= tokenAllocated && tokenAllocated <= softCap){
            //for test&#39;s
            //if(0 <= tokenAllocated ){
                prepareForRefund(_investor);
            }
            if (deposited[_investor] == 0) {
                countInvestor = countInvestor.add(1);
            }
            deposit(_investor);
            wallet.transfer(weiAmount);
        }
        return tokens;
    }

    function prepareForRefund(address _addressInvestor) internal {
        uint256 lastPaid = deposited[_addressInvestor];
        uint256 weiInvestor = lastPaid.add(msg.value);
        require(weiInvestor > 0);
        if(lastPaid > 0){
            confirmations[_addressInvestor][lastPaid] = false;
        }
        confirmations[_addressInvestor][weiInvestor] = true;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentDate = now;
        //currentDate = 1537444800; //for test&#39;s (Tue, 20 Sep 2018 12:00:00 GMT)
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        uint256 priceToken = getPriceToken();
        if(currentPeriod == 1 && _weiAmount >= weiMinSale){
            amountOfTokens = _weiAmount.mul(priceToken);
        }
        return amountOfTokens;
    }

    function getPriceToken() public view returns (uint256 _price) {
        uint priceExchange = oraclizeContact.getRate();
        if(0 <= tokenAllocated && tokenAllocated <= 3750 * 10**3 * (10 ** uint256(decimals))){
            _price = priceExchange.mul(100).div(5);
        }
        if(3750 * 10**3 * (10 ** uint256(decimals)) < tokenAllocated && tokenAllocated <= 40000 * 10**3 * (10 ** uint256(decimals))){
            _price = priceExchange.mul(1000).div(75);
        }
        if(40000 * 10**3 * (10 ** uint256(decimals)) < tokenAllocated && tokenAllocated <= 70000 * 10**3 * (10 ** uint256(decimals))){
            _price = priceExchange.mul(100).div(8);
        }
        if(70000 * 10**3 * (10 ** uint256(decimals)) < tokenAllocated && tokenAllocated <= 160000 * 10**3 * (10 ** uint256(decimals))){
            _price = priceExchange.mul(100).div(9);
        }
        if(160000 * 10**3 * (10 ** uint256(decimals)) < tokenAllocated && tokenAllocated <= 325000 * 10**3 * (10 ** uint256(decimals))){
            _price = priceExchange.mul(10);
        }
    }

    function getPeriod(uint256 _currentDate) public view returns (uint _period) {
        _period = 0;
        //1535760000 - Sep, 01, 2018 00:00:00 && 1541030400 - Nov, 01, 2018 00:00:00
        if( startTime < _currentDate && _currentDate < endTime){
            _period = 1;
        }
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function depositOf(address _owner) public view returns (uint256 balance) {
        return deposited[_owner];
    }

    function getConfirmRefund(address _addressInvestor, uint256 _weiAmount) public view returns (bool) {
        return confirmations[_addressInvestor][_weiAmount];
    }

    function setOraclizeContract(address _addressContract) public onlyOwner {
        require(_addressContract != address(0));
        oraclizeContact = IGetPriceFromOraclize(_addressContract);
    }

    function refundToInvestor() onlySoftCap public returns (uint256) {
    //function refundToInvestor() public returns (uint256) { //for test&#39;s
        address _addressInvestor = msg.sender;
        require(_addressInvestor != address(0));
        uint256 weiInvestor = depositOf(_addressInvestor);
        require(weiInvestor > 0);
        require(address(this).balance >= weiInvestor);
        uint256 tokenInvestor = balanceOf(_addressInvestor);
        require(tokenInvestor > 0);
        if(confirmations[_addressInvestor][weiInvestor] == true){
            balances[_addressInvestor] = 0;
            confirmations[_addressInvestor][weiInvestor] == false;
            deposited[_addressInvestor] = 0;
            balances[owner] = balances[owner].add(tokenInvestor);
            tokenAllocated = tokenAllocated.sub(tokenInvestor);
            fundForSale = fundForSale.add(tokenInvestor);
            _addressInvestor.transfer(weiInvestor);
            emit Refund(_addressInvestor, weiInvestor);
        }
        return weiInvestor;
    }

    function updatePrice() public payable onlyOwner {
        oraclizeContact.update();
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[addressFundReserv] = balances[addressFundReserv].add(fundReserv);
        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);
        balances[_wallet] = balances[_wallet].add(fundForSale);
        result = true;
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        return addTokens;
    }

    /**
    * @dev owner burn Token.
    * @param _value amount of burnt tokens
    */
    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value <= totalSupply);
        require(_value <= fundForSale);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        fundForSale = fundForSale.sub(_value);
        emit Burn(msg.sender, _value);
    }

    /**
    * @dev Add an contract admin
    */
    function setContractAdmin(address _admin, bool _isAdmin) external onlyOwner {
        require(_admin != address(0));
        contractAdmins[_admin] = _isAdmin;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external onlyOwnerOrAnyAdmin {
        require(_beneficiary != address(0));
		whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrAnyAdmin {
        require(_beneficiaries.length < 101);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwnerOrAnyAdmin {
        require(_beneficiary!= address(0));
		whitelist[_beneficiary] = false;
    }

    modifier onlyOwnerOrAnyAdmin() {
        require(msg.sender == owner || contractAdmins[msg.sender]);
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender]);
        _;
    }

    modifier onlySoftCap() {
        require(endTime <= now && tokenAllocated <= softCap);
        _;
    }

    function balanceContract() public view returns (uint256){
        return address(this).balance;
    }

}