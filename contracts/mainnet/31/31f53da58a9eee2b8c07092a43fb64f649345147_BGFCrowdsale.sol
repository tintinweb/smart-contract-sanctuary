pragma solidity ^0.4.23;


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
    address public walletTeam = 0x35cCaeD05CE27739579502B3424364774f18980e;
    uint256 public fundForTeam =  5*10**6 * (10 ** 18);

    uint256 public startTime = 1533081600; // 01 Aug 2018 00:00:00 GMT
    uint256 endTime = startTime + 35 days;
    uint256 firstRelease = endTime + 26 weeks;
    uint256 secondRelease = firstRelease + 26 weeks;
    uint256 thirdRelease = secondRelease + 26 weeks;
    uint256 fourthRelease = thirdRelease + 26 weeks;

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
        if (msg.sender == walletTeam) {
            checkVesting(_value, now);
        }
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

    function checkVesting(uint256 _value, uint256 _currentTime) public view returns(uint8 period) {
        require(firstRelease <= _currentTime);
        if (firstRelease <= _currentTime && _currentTime < secondRelease) {
            period = 1;
            require(balances[walletTeam].sub(_value) > fundForTeam.mul(3).div(4));
        }
        if (secondRelease <= _currentTime && _currentTime < thirdRelease) {
            period = 2;
            require(balances[walletTeam].sub(_value) > fundForTeam.mul(2).div(4));
        }
        if (thirdRelease <= _currentTime && _currentTime < fourthRelease) {
            period = 3;
            require(balances[walletTeam].sub(_value) > fundForTeam.mul(1).div(4));
        }
        if (fourthRelease <= _currentTime) {
            period = 4;
            require(balances[walletTeam].sub(_value) >= 0);
        }
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
    string public constant name = "BlockGain Fund Token";
    string public constant symbol = "BGF";
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


contract BGFCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    // https://www.coingecko.com/en/coins/ethereum
    //$0.09 = 1 token => $ 1,000 = 1.332019074513147 ETH =>
    //11,111.11 token = 1.5863699097355521 ETH => 1 ETH = 11,111.1/1.332019074513147 = 8342
    uint256 public rate  = 8342;

    mapping (address => uint256) public deposited;
    mapping(address => bool) public whitelist;

    uint256 public constant INITIAL_SUPPLY = 166666667 * (10 ** uint256(decimals));
    uint256 public fundForSale = 161666667 * (10 ** uint256(decimals));

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event MinWeiLimitReached(address indexed sender, uint256 weiAmount);
    event Finalized();
    event Burn(address indexed burner, uint256 value);

    constructor(address _owner) public
    Crowdsale(_owner)
    {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // for test&#39;s
        transfersEnabled = true;
        mintingFinished = false;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

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
        //currentDate = 1533513600; // (06 Aug 2018 00:00:00 GMT) for test&#39;s
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod < 5){
            if(whitelist[msg.sender]){
                if(currentPeriod == 0){
                    amountOfTokens = _weiAmount.mul(rate);
                }
                if(currentPeriod == 1){
                    amountOfTokens = _weiAmount.mul(rate).mul(90).div(95);
                }
                if(currentPeriod == 2){
                    amountOfTokens = _weiAmount.mul(rate).mul(90).div(100);
                }
                if(currentPeriod == 3){
                    amountOfTokens = _weiAmount.mul(rate).mul(90).div(105);
                }
                if(currentPeriod == 4){
                    amountOfTokens = _weiAmount.mul(rate).mul(90).div(110);
                }
            }
        }
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        if( startTime <= _currentDate && _currentDate <= startTime + 7 days){
            return 0;
        }
        if( startTime + 7 days <= _currentDate && _currentDate <= startTime + 14 days){
            return 1;
        }
        if( startTime + 14 days <= _currentDate && _currentDate <= startTime + 21 days){
            return 2;
        }
        if( startTime + 21 days <= _currentDate && _currentDate <= startTime + 28 days){
            return 3;
        }
        if( startTime + 28 days <= _currentDate && _currentDate <= startTime + 35 days){
            return 4;
        }
        return 10;
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _walletOwner) internal returns (bool result) {
        result = false;
        require(_walletOwner != address(0));
        balances[_walletOwner] = balances[_walletOwner].add(fundForSale);
        balances[walletTeam] = balances[walletTeam].add(fundForTeam);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public inState(State.Active) returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (_weiAmount < 0.05 ether) {
            emit MinWeiLimitReached(msg.sender, _weiAmount);
            return 0;
        }
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(tokenAllocated, addTokens);
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

    function setRate(uint256 _newRate) external onlyOwner returns (bool){
        require(_newRate > 0);
        rate = _newRate;
        return true;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        require(_beneficiaries.length < 101);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
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

}