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
    string public constant name = "WebSpaceX";
    string public constant symbol = "WSPX";
    uint8 public constant decimals = 18;
    mapping(uint8 => uint8) public approveOwner;

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
    uint256 public hardWeiCap = 15830 ether;

    // amount of raised money in wei
    uint256 public weiRaised;
    uint256 public tokenAllocated;

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract WSPXCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    uint256 public rate  = 312500;

    mapping (address => uint256) public deposited;
    mapping (address => bool) internal isRefferer;

    uint256 public weiMinSale = 0.1 ether;

    uint256 public constant INITIAL_SUPPLY = 9 * 10**9 * (10 ** uint256(decimals));

    uint256 public fundForSale   = 6 * 10**9 * (10 ** uint256(decimals));
    uint256 public    fundTeam   = 1 * 10**9 * (10 ** uint256(decimals));
    uint256 public    fundBounty = 2 * 10**9 * (10 ** uint256(decimals));

    address public addressFundTeam   = 0xA2434A8F6457fe7CF29AEa841cf3D0B0FE3217c8;
    address public addressFundBounty = 0x8828c48DEc2764868aD3bBf7fE9e8aBE773E3064;

    // 1 Jan - 15 Jan
    uint256 startTimeIcoStage1 = 1546300800; // Tue, 01 Jan 2019 00:00:00 GMT
    uint256 endTimeIcoStage1 =   1547596799; // Tue, 15 Jan 2019 23:59:59 GMT

    // 16 Jan - 31 Jan
    uint256 startTimeIcoStage2 = 1547596800; // Wed, 16 Jan 2019 00:00:00 GMT
    uint256 endTimeIcoStage2   = 1548979199; // Thu, 31 Jan 2019 23:59:59 GMT

    // 1 Feb - 15 Feb
    uint256 startTimeIcoStage3 = 1548979200; // Fri, 01 Feb 2019 00:00:00 GMT
    uint256 endTimeIcoStage3   = 1554076799; // Fri, 15 Feb 2019 23:59:59 GMT

    uint256 limitStage1 =  2 * 10**9 * (10 ** uint256(decimals));
    uint256 limitStage2 =  4 * 10**9 * (10 ** uint256(decimals));
    uint256 limitStage3 =  6 * 10**9 * (10 ** uint256(decimals));

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event CurrentPeriod(uint period);
    event ChangeTime(address indexed owner, uint256 newValue, uint256 oldValue);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event ChangeRate(address indexed owner, uint256 newValue, uint256 oldValue);
    event Burn(address indexed burner, uint256 value);
    event HardCapReached();


    constructor(address _owner, address _wallet) public
    Crowdsale(_wallet)
    {
        require(_owner != address(0));
        owner = _owner;
        //owner = msg.sender; // for test&#39;s
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
        //currentDate = 1547114400; // Thu, 10 Jan 2019 10:00:00 GMT // for test&#39;s
        uint currentPeriod = 0;
        currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod > 0){
            if(currentPeriod == 1){
                amountOfTokens = _weiAmount.mul(rate).mul(130).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage1) {
                    currentPeriod = currentPeriod.add(1);
                    amountOfTokens = 0;
                }
            }
            if(currentPeriod == 2){
                amountOfTokens = _weiAmount.mul(rate).mul(120).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage2) {
                    currentPeriod = currentPeriod.add(1);
                    amountOfTokens = 0;
                }
            }
            if(currentPeriod == 3){
                amountOfTokens = _weiAmount.mul(rate).mul(110).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage3) {
                    currentPeriod = 0;
                    amountOfTokens = 0;
                }
            }
        }
        emit CurrentPeriod(currentPeriod);
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        if(_currentDate < startTimeIcoStage1){
            return 0;
        }
        if( startTimeIcoStage1 <= _currentDate && _currentDate <= endTimeIcoStage1){
            return 1;
        }
        if( startTimeIcoStage2 <= _currentDate && _currentDate <= endTimeIcoStage2){
            return 2;
        }
        if( startTimeIcoStage3 <= _currentDate && _currentDate <= endTimeIcoStage3){
            return 3;
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
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        result = true;
    }

    function getDeposited(address _investor) external view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > balances[owner]) {
            emit TokenLimitReached(msg.sender, tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardWeiCap) {
            emit HardCapReached();
            return 0;
        }
        if (_weiAmount < weiMinSale) {
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

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }

    /**
     * @dev owner change time for startTimeIcoStage1
     * @param _value new time value
     */
    function setStartTimeIcoStage1(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage1;
        startTimeIcoStage1 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

    /**
     * @dev owner change time for endTimeIcoStage1
     * @param _value new time value
     */
    function setEndTimeIcoStage1(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage1;
        endTimeIcoStage1 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

    /**
     * @dev owner change time for startTimeIcoStage2
     * @param _value new time value
     */
    function setStartTimeIcoStage2(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage2;
        startTimeIcoStage2 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }


    /**
     * @dev owner change time for endTimeIcoStage2
     * @param _value new time value
     */
    function setEndTimeIcoStage2(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage2;
        endTimeIcoStage2 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

    /**
 * @dev owner change time for startTimeIcoStage3
 * @param _value new time value
 */
    function setStartTimeIcoStage3(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage3;
        startTimeIcoStage3 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }


    /**
     * @dev owner change time for endTimeIcoStage3
     * @param _value new time value
     */
    function setEndTimeIcoStage3(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage3;
        endTimeIcoStage3 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

    /**
     * @dev owner change address of wallet for collecting ETH
     * @param _newWallet new address of wallet
     */
    function setWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = wallet;
        wallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    /**
     * @dev owner change price of tokens
     * @param _newRate new price
     */
    function setRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0);
        uint256 _oldRate = rate;
        rate = _newRate;
        emit ChangeRate(msg.sender, _newRate, _oldRate);
    }
}