pragma solidity ^0.4.24;


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
    address public ownerTwo;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == ownerTwo);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function changeOwnerTwo(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        ownerTwo = _newOwner;
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "FOOOZ";
    string public constant symbol = "FOOOZ";
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

    uint256 public hardWeiCap = 119000 * (10 ** 18);

    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract FooozCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    mapping (address => uint256) public deposited;

    uint256 public constant INITIAL_SUPPLY = 613333328 * (10 ** uint256(decimals));
    uint256 public fundForSale = 466133330 * (10 ** uint256(decimals));

    address public addressFundDevelopers = 0x326B7740e5E806fc731200A3ea92f588a86568A3;
    address public addressFundBounty = 0xE585b723bDc6324dD55cf614fa83f61A88D5b3D8;
    address public addressFundBonus = 0x1f318fE745bEE511a72A8AB2b704a5F285587335;
    address public addressFundInvestment = 0x80A0BE0Ab330E48dE8E37277b838b9eB0Bb3bb6f;
    address public addressFundAdministration = 0xFe3905B9Bd7C0c4164873180dfE0ee85FbFe9F19;


    uint256[] public discount  = [50, 25, 20, 15, 10];



    uint256 public weiMinSalePreIco = 1190 * 10 ** 15;
    uint256 public weiMinSaleIco = 29 * 10 ** 15;
    uint256 priceToken = 3362;
    // $0.25 = 1 token => $1,000 = 1.19 ETH =>
    //4,000 token = 1.19 ETH => 1 ETH = 4,000/1.19 = 3362 token

    uint256 public countInvestor;
    uint256 public currentAfterIcoPeriod;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event HardCapReached();
    event Finalized();

    constructor (address _owner, address _ownerTwo) public
    Crowdsale(_owner)
    {
        require(_owner != address(0));
        require(_ownerTwo != address(0));
        owner = _owner;
        ownerTwo = _ownerTwo;
        //owner = msg.sender; //for test&#39;s
        transfersEnabled = true;
        mintingFinished = false;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        mintForOwner(owner);
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    function setPriceToken(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        priceToken = _newPrice;
    }

    // low level token purchase function
    function buyTokens(address _investor) public inState(State.Active) payable returns (uint256){
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

    function getTotalAmountOfTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentDate = now;
        //currentDate = 1534204800; //for test&#39;s (Tue, 14 Aug 2018 00:00:00 GMT)
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod < 5){
            amountOfTokens = _weiAmount.mul(priceToken).mul(discount[currentPeriod] + 100).div(100);
        }
        if(currentPeriod == 0 && _weiAmount < weiMinSalePreIco){
            amountOfTokens = 0;
        }
        if(0 < currentPeriod && currentPeriod < 5 && _weiAmount < weiMinSaleIco){
            amountOfTokens = 0;
        }
        return amountOfTokens;
    }

    /**
    * Pre-ICO sale starts on 01 of Jul, ends on 05 Jul 2018
    * 1st. Stage starts 06 of Jul, ends on 15 of Jul , 2018
    * 2nd. Stage starts 16 of Jul, ends on 25 of Jul , 2018
    * 3rd. Stage starts 26 of Jul, ends on 05 of Aug , 2018
    * 4th. Stage starts 06 of Aug, ends on 15  of Aug , 2018
    */
    function getPeriod(uint256 _currentDate) public pure returns (uint) {
        //1530403200 - July, 01, 2018 00:00:00 && 1530835199 - July, 05, 2018 23:59:59
        if( 1530403200 <= _currentDate && _currentDate <= 1530835199){
            return 0;
        }
        //1530835200 - July, 06, 2018 00:00:00 && 1531699199 - July, 15, 2018 23:59:59
        if( 1530835200 <= _currentDate && _currentDate <= 1531699199){
            return 1;
        }
        //1531699200 - July, 16, 2018 00:00:00 && 1532563199 - July, 25, 2018 23:59:59
        if( 1531699200 <= _currentDate && _currentDate <= 1532563199){
            return 2;
        }
        //1532563200 - July, 26, 2018 00:00:00 && 1533513599 - August,   05, 2018 23:59:59
        if( 1532563200 <= _currentDate && _currentDate <= 1533513599){
            return 3;
        }
        //1533513600 - August,   06, 2018 00:00:00 && 1534377599 - August,   15, 2018 23:59:59
        if( 1533513600 <= _currentDate && _currentDate <= 1534377599){
            return 4;
        }
        return 10;
    }

    function getAfterIcoPeriod(uint256 _currentDate) public pure returns (uint) {
        uint256 endIco = 1534377600; // August,   16, 2018 00:00:00
        if( endIco < _currentDate && _currentDate <= endIco + 2*365 days){
            return 100;
        }
        if( endIco + 2*365 days < _currentDate && _currentDate <= endIco + 4*365 days){
            return 200;
        }
        if( endIco + 4*365 days < _currentDate && _currentDate <= endIco + 6*365 days){
            return 300;
        }
        if( endIco + 6*365 days < _currentDate && _currentDate <= endIco + 8*365 days){
            return 400;
        }
        return 0;
    }

    function mintAfterIcoPeriod() public returns (bool result) {
        uint256 totalCost = tokenAllocated.div(priceToken);
        uint256 fivePercent = 0;
        uint256 currentDate = now;
        //currentDate = 1571101199; //for test Oct, 15, 2019
        bool changePeriod = false;
        uint256 nonSoldToken = totalSupply.sub(tokenAllocated);
        uint256 mintTokens = 0;
        result = false;
        if (currentAfterIcoPeriod < getAfterIcoPeriod(currentDate)){
            currentAfterIcoPeriod = currentAfterIcoPeriod.add(getAfterIcoPeriod(currentDate));
            changePeriod = true;
        }
        if(totalCost.mul(100).div(weiRaised) < 200 || changePeriod){
            mintTokens = nonSoldToken.div(4); // 25%
            fivePercent = mintTokens.div(20); // 5%

            balances[addressFundBonus] = balances[addressFundBonus].add(fivePercent.mul(2));
            balances[addressFundBounty] = balances[addressFundBounty].add(fivePercent);
            balances[addressFundInvestment] = balances[addressFundInvestment].add(fivePercent.mul(10));
            balances[addressFundAdministration] = balances[addressFundAdministration].add(fivePercent);
            //balances[ownerTwo] = balances[ownerTwo].add(fivePercent.mul(6));

            balances[owner] = balances[owner].sub(fivePercent.mul(14)); // - 70%
            tokenAllocated = tokenAllocated.add(fivePercent.mul(14));
            result = true;
        }
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        uint256 fundBounty = 24533333 * (10 ** uint256(decimals));
        uint256 fundDevelopers = 122666665 * (10 ** uint256(decimals));
        require(_wallet != address(0));
        balances[addressFundDevelopers] = balances[addressFundDevelopers].add(fundDevelopers);
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        tokenAllocated = tokenAllocated.add(fundDevelopers).add(fundBounty);
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY).sub(tokenAllocated);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public inState(State.Active) returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardWeiCap) {
            emit HardCapReached();
            return 0;
        }
        return addTokens;
    }

    function finalize() public onlyOwner inState(State.Active) returns (bool result) {
        result = false;
        state = State.Closed;
        wallet.transfer(address(this).balance);
        finishMinting();
        emit Finalized();
        result = true;
    }

}