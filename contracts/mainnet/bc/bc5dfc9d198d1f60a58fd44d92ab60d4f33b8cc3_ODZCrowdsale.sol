pragma solidity ^0.4.25;


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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

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
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
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
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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
    function changeOwner(address _newOwner) onlyOwner internal {
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
    string public constant name = "Oodlz Token";
    string public constant symbol = "ODZ";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
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

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract ODZCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    uint256 public ratePreIco  = 325;
    uint256 public rateIco  = 250;

    uint256 public weiMin = 0.005 ether;

    mapping (address => uint256) public deposited;

    uint256 public constant INITIAL_SUPPLY = 85 * 10**7 * (10 ** uint256(decimals));
    uint256 public    fundForSale = 17 * 10**7 * (10 ** uint256(decimals));

    uint256 public   fundTeam = 1275 * 10**5 * (10 ** uint256(decimals));
    uint256 public fundReserv = 5525 * 10**5 * (10 ** uint256(decimals));

    uint256 limitPreIco = 3 * 10**7 * (10 ** uint256(decimals));

    address public addressFundTeam   = 0x3939f99C5f8C9198c7D40E5880ee731F2F6395AC;
    address public addressFundReserv = 0xE6a4A7bd59989dA07417cDba8f6a4c29fd4732a3;

    uint256 startTimePreIco = 1539561600; // Mon, 15 Oct 2018 00:00:00 GMT
    uint256 endTimePreIco =   1546300799; // Mon, 31 Dec 2018 23:59:59 GMT
    uint256 startTimeIco =    1546300800; // Tue, 01 Jan 2019 00:00:00 GMT

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event MinWeiLimitReached(address indexed sender, uint256 weiAmount);
    event CurrentPeriod(uint period);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event ChangeRate(address indexed owner, uint256 newValue, uint256 oldValue);

    constructor(address _owner, address _wallet) public
    Crowdsale(_wallet)
    {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // $$$ for test&#39;s
        transfersEnabled = true;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintForOwner = mintForFund(owner);
        require(resultMintForOwner);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal returns (uint256) {
        uint256 currentDate = now;
        //currentDate = 1539993600; // (20 Oct 2018) // $$$ for test&#39;s
        uint currentPeriod = 0;
        currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod > 0){
            if(currentPeriod == 1){
                amountOfTokens = _weiAmount.mul(ratePreIco);
                if (tokenAllocated.add(amountOfTokens) > limitPreIco) {
                    currentPeriod = currentPeriod.add(1);
                }
            }
            if(currentPeriod == 2){
                amountOfTokens = _weiAmount.mul(rateIco);
            }
        }
        emit CurrentPeriod(currentPeriod);
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        if(_currentDate < startTimePreIco){
            return 0;
        }
        if( startTimePreIco <= _currentDate && _currentDate <= endTimePreIco){
            return 1;
        }
        if( endTimePreIco < _currentDate && _currentDate < startTimeIco){
            return 0;
        }
        if( startTimeIco <= _currentDate){
            return 2;
        }
        return 0;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForFund(address _walletOwner) internal returns (bool result) {
        result = false;
        require(_walletOwner != address(0));
        balances[_walletOwner] = balances[_walletOwner].add(fundForSale);

        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);
        balances[addressFundReserv] = balances[addressFundReserv].add(fundReserv);

        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function setWallet(address _newWallet) public onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = wallet;
        wallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (_weiAmount < weiMin) {
            emit MinWeiLimitReached(msg.sender, _weiAmount);
            return 0;
        }
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(msg.sender, tokenAllocated, addTokens);
            return 0;
        }
        return addTokens;
    }

    /**
     * @dev owner change rate for pre ICO
     * @param _value new rate value
     */
    function setRatePreIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = ratePreIco;
        ratePreIco = _value;
        emit ChangeRate(msg.sender, _value, _oldValue);
    }

    /**
     * @dev owner change rate for ICO
     * @param _value new rate value
     */
    function setRateIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = rateIco;
        rateIco = _value;
        emit ChangeRate(msg.sender, _value, _oldValue);
    }

    function setWeiMin(uint256 _value) public onlyOwner {
        require(_value > 0);
        weiMin = _value;
    }
}