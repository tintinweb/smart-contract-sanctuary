pragma solidity ^0.4.18;


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

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

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
    uint256 public endTimeLockedTokensTeam = 1601510399; // +2 years (Wed, 30 Sep 2020 23:59:59 GMT)
    uint256 public endTimeLockedTokensAdvisor = 1554076800; // + 6 months (Mon, 01 Apr 2019 00:00:00 GMT)
    address public walletTeam = 0xdEffB0629FD35AD1A462C13D65f003E9079C3bb1;
    address public walletAdvisor = 0xD437f2289B4d20988EcEAc5E050C6b4860FFF4Ac;

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

        // Block the sending of tokens from the fund Advisors
        if ((msg.sender == walletAdvisor) && (now < endTimeLockedTokensAdvisor)) {
            revert();
        }
        // Block the sending of tokens from the fund Team
        if((msg.sender == walletTeam) && (now < endTimeLockedTokensTeam)) {
            revert();
        }

        // SafeMath.sub will throw if there is not enough balance.
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

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
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
        Approval(msg.sender, _spender, _value);
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    struct PermissionFunction {
                bool approveOwner;
                bool approveOwnerTwo;
    }
    PermissionFunction[] public permissions;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        permissions.push(PermissionFunction(false, false));
/*
        for (uint8 i = 0; i < 5; i++) {
            permissions.push(PermissionFunction(false, false));
        }
*/
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == ownerTwo);
        _;
    }


    function setApproveOwner(uint8 _numberFunction, bool _permValue) onlyOwner public {
        if(msg.sender == owner){
            permissions[_numberFunction].approveOwner = _permValue;
        }
        if(msg.sender == ownerTwo){
            permissions[_numberFunction].approveOwnerTwo = _permValue;
        }
    }

/*
    function getApprove(uint8 _numberFunction) public view onlyOwner returns (bool) {
        if(msg.sender == owner){
            return permissions[_numberFunction].approveOwner;
        }
        if(msg.sender == ownerTwo){
            return permissions[_numberFunction].approveOwnerTwo;
        }
    }
*/

    function removePermission(uint8 _numberFunction) public onlyOwner {
        permissions[_numberFunction].approveOwner = false;
        permissions[_numberFunction].approveOwnerTwo = false;
    }
}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "Greencoin";
    string public constant symbol = "GNC";
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
        Mint(_to, _amount);
        Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * Peterson&#39;s Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public  onlyOwner {
    //function claimTokens(address _token) public {  //for test&#39;s
        //require(permissions[4].approveOwner == true && permissions[4].approveOwnerTwo == true);
        if (_token == 0x0) {
                owner.transfer(this.balance);
                return;
            }
        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        Transfer(_token, owner, balance);
        //removePermission(4);
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
    uint256 public hardWeiCap = 60000 * (10 ** 18); // 60,000 ETH

    function Crowdsale(
    address _wallet
    )
    public
    {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract GNCCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    /**
    * Price: 1 ETH = 500 token
    *
    * 1 Stage  1 ETH = 575  token -- discount 15%
    * 2 Stage  1 ETH = 550  token -- discount 10%
    * 3 Stage  1 ETH = 525  token -- discount 5%
    * 4 Stage  1 ETH = 500  token -- discount 0%
    *
    */
    uint256[] public rates  = [575, 550, 525, 500];
    uint256 public weiMinSale =  1 * 10**17;

    mapping (address => uint256) public deposited;
    mapping(address => bool) public whitelist;

    uint256 public constant INITIAL_SUPPLY = 50 * (10 ** 6) * (10 ** uint256(decimals));
    uint256 public fundForSale = 30 *   (10 ** 6) * (10 ** uint256(decimals));
    uint256 public fundTeam =    7500 * (10 ** 3) * (10 ** uint256(decimals));
    uint256 public fundAdvisor = 4500 * (10 ** 3) * (10 ** uint256(decimals));
    uint256 public fundBounty =  500 *  (10 ** 3) * (10 ** uint256(decimals));
    uint256 public fundPreIco =  6000 * (10 ** 3) * (10 ** uint256(decimals));

    address public addressBounty = 0xE3dd17FdFaCa8b190D2fd71f3a34cA95Cdb0f635;

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Burn(address indexed burner, uint256 value);
    event HardCapReached();
    event Finalized();

    function GNCCrowdsale(
    address _owner,
    address _wallet,
    address _ownerTwo
    )
    public
    Crowdsale(_wallet)
    {
        require(_wallet != address(0));
        require(_owner != address(0));
        require(_ownerTwo != address(0));
        owner = _owner;
        ownerTwo = _ownerTwo;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintForOwner = mintForFund(owner);
        require(resultMintForOwner);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal returns (uint256) {
        uint256 currentDate = now;
        //currentDate = 1529020800; //for test&#39;s (Jun, 15)
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod < 4){
            amountOfTokens = _weiAmount.mul(rates[currentPeriod]);
            if(whitelist[msg.sender]){
                amountOfTokens = amountOfTokens.mul(105).div(100);
            }
            if (currentPeriod == 0) {
                if (tokenAllocated.add(amountOfTokens) > fundPreIco) {
                    TokenLimitReached(tokenAllocated, amountOfTokens);
                    return 0;
                }
            }
        }
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public pure returns (uint) {
        /**
        * 1527811200 - Jun, 01, 2018 00:00:00 && 1530403199 - Jun, 30, 2018 23:59:59
        * 1533081600 - Aug, 01, 2018 00:00:00 && 1534377599 - Aug, 15, 2018 23:59:59
        * 1534377600 - Aug, 16, 2018 00:00:00 && 1535759999 - Aug, 31, 2018 23:59:59
        * 1535760000 - Sep, 01, 2018 00:00:00 && 1538351999 - Sep, 30, 2018 23:59:59
        */

        if( 1527811200 <= _currentDate && _currentDate <= 1530403199){
            return 0;
        }
        if( 1533081600 <= _currentDate && _currentDate <= 1534377599){
            return 1;
        }
        if( 1534377600 <= _currentDate && _currentDate <= 1535759999){
            return 2;
        }
        if( 1535760000 <= _currentDate && _currentDate <= 1538351999){
            return 3;
        }
        return 10;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForFund(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY.sub(fundTeam).sub(fundAdvisor).sub(fundBounty));
        balances[walletTeam] = balances[walletTeam].add(fundTeam);
        balances[walletAdvisor] = balances[walletAdvisor].add(fundAdvisor);
        balances[addressBounty] = balances[addressBounty].add(fundBounty);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if(_weiAmount < weiMinSale){
            return 0;
        }
        if (tokenAllocated.add(addTokens) > fundForSale) {
            TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardWeiCap) {
            HardCapReached();
            return 0;
        }
        return addTokens;
    }

    /**
     * @dev Function to burn tokens.
     * @return True if the operation was successful.
     */
    function ownerBurnToken(uint _value) public onlyOwner returns (bool) {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(permissions[0].approveOwner == true && permissions[0].approveOwnerTwo == true);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(owner, _value);
        removePermission(0);
        return true;
    }

    /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
    function addToWhitelist(address _beneficiary) external onlyOwner {
        //require(permissions[1].approveOwner == true && permissions[1].approveOwnerTwo == true);
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        //require(permissions[2].approveOwner == true && permissions[2].approveOwnerTwo == true);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        //require(permissions[3].approveOwner == true && permissions[3].approveOwnerTwo == true);
        whitelist[_beneficiary] = false;
    }
}