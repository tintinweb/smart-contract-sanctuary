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

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

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

    mapping(address => mapping(address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
        } else {
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
    address public advisor;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        advisor = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == advisor);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function changeAdvisor(address newAdvisor) onlyOwner public {
        advisor = newAdvisor;
        OwnerChanged(advisor, newAdvisor);
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "MCFit Token";
    string public constant symbol = "MCF";
    uint8 public constant decimals = 18;

    uint256 public totalAllocated = 0;

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
    function mint(address _to, uint256 _amount) canMint internal returns (bool) {

        require(!mintingFinished);
        totalAllocated = totalAllocated.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function withDraw(address _investor) internal returns (bool) {

        require(mintingFinished);
        uint256 amount = balanceOf(_investor);
        require(amount <= totalAllocated);
        totalAllocated = totalAllocated.sub(amount);
        balances[_investor] = balances[_investor].sub(amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;
    bool public checkDate;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;
    uint256 public tokenRaised;
    bool public isFinalized = false;

    event Finalized();


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {

        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        //token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        checkDate = false;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    /**
 * @dev Must be called after crowdsale ends, to do some extra finalization
 * work. Calls the contract&#39;s finalization function.
 */
    function finalize() onlyOwner public {
        require(!isFinalized);
        //require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal pure {
    }
}


contract MCFitCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    mapping(address => uint256) public deposited;
    uint256 public constant INITIAL_SUPPLY = 1 * (10**9) * (10 ** uint256(decimals));
    uint256 public fundReservCompany = 350 * (10**6) * (10 ** uint256(decimals));
    uint256 public fundTeamCompany = 300 * (10**6) * (10 ** uint256(decimals));
    uint256 public countInvestor;

    uint256 limit40Percent = 30*10**6*10**18;
    uint256 limit20Percent = 60*10**6*10**18;
    uint256 limit10Percent = 100*10**6*10**18;

    event Closed();
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);


    function MCFitCrowdsale(uint256 _startTime, uint256 _endTime,uint256 _rate, address _wallet) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        owner = _wallet;
        //advisor = msg.sender;
        transfersEnabled = true;
        mintingFinished = false;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintFunds = mintToSpecialFund(owner);
        require(resultMintFunds);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public payable returns (uint256){
        require(state == State.Active);
        require(_investor != address(0));
        if(checkDate){
            assert(now >= startTime && now < endTime);
        }
        uint256 weiAmount = msg.value;
        // calculate token amount to be created
        uint256 tokens = getTotalAmountOfTokens(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        mint(_investor, tokens);
        TokenPurchase(_investor, weiAmount, tokens);
        if(deposited[_investor] == 0){
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal constant returns (uint256 amountOfTokens) {
        uint256 currentTokenRate = 0;
        uint256 currentDate = now;
        //uint256 currentDate = 1516492800; // 21 Jan 2018
        require(currentDate >= startTime);

        if (totalAllocated < limit40Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*140);
        } else if (totalAllocated < limit20Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*120);
        } else if (totalAllocated < limit10Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*110);
        } else {
            return currentTokenRate = _weiAmount.mul(rate*100);
        }
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        if(checkDate){
            require(hasEnded());
        }
        state = State.Closed;
        transfersEnabled = false;
        finishMinting();
        Closed();
        finalize();
        wallet.transfer(this.balance);
    }

    function mintToSpecialFund(address _wallet) public onlyOwner returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(fundReservCompany);
        balances[_wallet] = balances[_wallet].add(fundTeamCompany);
        result = true;
    }

    function changeRateUSD(uint256 _rate) onlyOwner public {
        require(state == State.Active);
        require(_rate > 0);
        rate = _rate;
    }

    function changeCheckDate(bool _state, uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(state == State.Active);
        require(_startTime >= now);
        require(_endTime >= _startTime);

        checkDate = _state;
        startTime = _startTime;
        endTime = _endTime;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function removeContract() public onlyOwner {
        selfdestruct(owner);
    }

}