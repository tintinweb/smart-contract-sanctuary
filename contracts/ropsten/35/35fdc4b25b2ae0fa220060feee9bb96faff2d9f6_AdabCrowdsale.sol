pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender],"Value is over than balance");
        require(_to != address(0),"Invalid address");

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
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from],"Value over than balance");
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}


/**
 * @title Simplified version of FreezableToken from OpenZeppelin
 * Use one date release tokens for all accounts
 */
contract FreezableToken is StandardToken {
    /**
     * @dev total freezing balance per address
    */
    mapping (address => uint) internal freezingBalance;
    
    /**
     * @dev date release frozen token is 31.05.2019 - UnixTimeStamp 1559260800
    */
    uint256 public dateRelease = 1559260800;

    event Freezed(address indexed to, uint amount);
    event Released(address indexed owner, uint amount);
     /**
     * @dev Gets the balance of the specified address include freezing tokens.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

    /**
     * @dev Gets the balance of the specified address without freezing tokens.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }
    
    /**
     * @dev freeze your tokens to the specified address.
     * @param _to Address to which token will be freeze.
     * @param _amount Amount of token to freeze.
     */
    function freezeTo(address _to, uint _amount) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);
        emit Freezed(_to, _amount);
    }

    /**
     * @dev function unfreeze your frozen tokens and transfer their to the balance.
     */
    function release() public {
        require(freezingBalance[msg.sender] > 0,"You don`t have freezed tokens.");
        require(now > dateRelease, "Date release tokens did not come yet.");
        uint256 amount = freezingBalance[msg.sender];
        freezingBalance[msg.sender] = 0;
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit Released(msg.sender, amount);
    }
    
}


contract ADABToken is FreezableToken, BurnableToken {
    string public constant name = "ADAB Token";
    string public constant symbol = "ADAB";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 480000000 * 1 ether; //480 000 000
    address public CrowdsaleAddress;
    uint256 public dateStartTransfer;

    constructor(address _CrowdsaleAddress) public {
        CrowdsaleAddress = _CrowdsaleAddress;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY; 
        dateStartTransfer = 1538352000; // 01.10.2018
    }
    
    modifier onlyOwner() {
        // only Crowdsale contract
        require(msg.sender == CrowdsaleAddress);
        _;
    }
    
    modifier allowTransfer() {
        if (msg.sender != CrowdsaleAddress){
            require(now > dateStartTransfer,"All transfers are locked now.");
        }
        _;
    }

    /**
     * function can be run only from crowdsale contract
     */
    function setDateRelease (uint256 _newDate) public onlyOwner {
        dateRelease = _newDate;
    }    
    
    /**
     * function can be run only from crowdsale contract
     */
    function setDateStartTransfer(uint256 _newDate) public onlyOwner {
        dateStartTransfer = _newDate;
    }
    
    /**
     *@dev Override and add lock time
    */
    function transfer(address _to, uint256 _value) public allowTransfer returns(bool){
        return super.transfer(_to,_value);
    }

    /**
     *@dev Override and add lock time
    */
    function transferFrom(address _from, address _to, uint256 _value) public allowTransfer returns(bool){
        return super.transferFrom(_from,_to,_value);
    }
 
    /**
     * @dev function transfer tokens from special address to users
     * @dev can run only from crowdsale contract
    */
    function transferTokensFromSpecialAddress(address _from, address _to, uint256 _value) public onlyOwner returns (bool){
        require (balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

}

contract Ownable {
    address public owner;
    address public manager;
    address candidate;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier restricted() {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        candidate = newOwner;
    }

    function confirmOwnership() public {
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }

    function setManager(address _newManager) public onlyOwner {
        manager = _newManager;
    }
}

contract BountyAddress {
    //Address where stored marketing and bounty tokens- 1%
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

contract ReserveFundAddress {
    //Address where stored project fund tokens- 15%
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

contract TeamAddress1 {
    //Address where stored command tokens- 2% - hold = dateRelease + 1 year
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

contract TeamAddress2 {
    //Address where stored command tokens- 6% - hold = dateRelease + 2 year
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

contract AdvisorsAddress1 {
    //Address where stored advisors tokens- 1% - hold = dateStartTransfer 
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

contract AdvisorsAddress2 {
    //Address where stored advisors tokens- 3% - hold = dateRelease 
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}

/**
 * @title Crowdsale contract
 */
contract AdabCrowdsale is Ownable {
    using SafeMath for uint; 
    address myAddress = this;
    uint256 public dateDeployContract;
    
    ADABToken public token = new ADABToken(myAddress);
    /**
    * @dev New address for hold tokens
    */
    ReserveFundAddress public holdAddress1 = new ReserveFundAddress();
    TeamAddress1 public holdAddress2 = new TeamAddress1();
    TeamAddress2 public holdAddress3 = new TeamAddress2();
    BountyAddress public holdAddress4 = new BountyAddress();
    AdvisorsAddress1 public holdAddress5 = new AdvisorsAddress1();
    AdvisorsAddress2 public holdAddress6 = new AdvisorsAddress2();

    constructor() public {
        uint256 TotalTokens = token.INITIAL_SUPPLY();
        // distribute tokens
        //Transer tokens to reserve fund address.  (15%)
        _transferTokens(address(holdAddress1), TotalTokens.mul(15).div(100));
        //Transer tokens to TeamAddress1  (2%)
        _transferTokens(address(holdAddress2), TotalTokens.div(50));
        //Transer tokens to TeamAddress2  (6%)
        _transferTokens(address(holdAddress3), TotalTokens.mul(6).div(100));
        // Transer tokens to bounty address. (1%)
        _transferTokens(address(holdAddress4), TotalTokens.div(100));
        // Transer tokens to AdvisorsAddress1 (1%)
        _transferTokens(address(holdAddress5), TotalTokens.div(100));
        // Transer tokens to AdvisorsAddress2 (3%)
        _transferTokens(address(holdAddress6), TotalTokens.mul(3).div(100));

        dateDeployContract = now;
    }
    
    modifier checkDate(uint256 _date) {
        require(_date > dateDeployContract, "The date can not be earlier than date of deploy contract");
        _;
    }


    function _transferTokens(address _newInvestor, uint256 _value) internal {
        require (_newInvestor != address(0),"Invalid address");
        require(_value > 0, "Value must be over zero.");
        token.transfer(_newInvestor, _value);
    } 
    
    /**
     * @dev the function transfer tokens from ReservedFund to new investor
     */
    function transferReserveFundTokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        return token.transferTokensFromSpecialAddress(holdAddress1, _newInvestor, _value);
    }

    /**
     * @dev the function transfer tokens from bounty fund to new investor
     */
    function transferBountyTokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        return token.transferTokensFromSpecialAddress(holdAddress4, _newInvestor, _value);
    }

    /**
     * @dev the function transfer tokens from TeamAddress1 to new investor
     */
    function transferTeam1Tokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        require(now > token.dateRelease() + 365 days, "Hold one year from dateRelease");
        return token.transferTokensFromSpecialAddress(holdAddress2, _newInvestor, _value);
    }

    /**
     * @dev the function transfer tokens from TeamAddress2 to new investor
     */
    function transferTeam2Tokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        require(now > token.dateRelease() + 730 days, "Hold two years from dateRelease");
        return token.transferTokensFromSpecialAddress(holdAddress3, _newInvestor, _value);
    }
 
    /**
     * @dev the function transfer tokens from AdvisorAddress1 to new investor
     */
    function transferAdvisor1Tokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        require(now > token.dateStartTransfer(), "Hold is dateStartTransfer");
        return token.transferTokensFromSpecialAddress(holdAddress5, _newInvestor, _value);
    }
 
    /**
     * @dev the function transfer tokens from AdvisorAddress2 to new investor
     */
    function transferAdvisor2Tokens(address _newInvestor, uint256 _value) public onlyOwner returns(bool) {
        require(now > token.dateRelease(), "Hold is dateRelease");
        return token.transferTokensFromSpecialAddress(holdAddress6, _newInvestor, _value);
    }
 
    /**
     * @dev the function transfer tokens to new investor
     */
    function transferTokens(address _newInvestor, uint256 _value) public restricted {
        _transferTokens(_newInvestor, _value);
    }
    
    /**
     * @dev the function transfer frozen tokens to new investor
     */
    function transferFrozenTokens(address _newInvestor, uint256 _value) public restricted {
        token.freezeTo(_newInvestor, _value);
    }
   
    /**
     * @dev the function transfer simple tokens and frozen tokens to new investor in one transaction
     */
    function transferComplex(address _newInvestor, uint256 _tokens, uint256 _frozenTokens) public restricted {
        if (_tokens > 0) {
            transferTokens(_newInvestor, _tokens);
        }
        if (_frozenTokens > 0) {
            transferFrozenTokens(_newInvestor, _frozenTokens);
        }
    }
    
    /**
     * @dev the function burning tokens in contract balance not over than 50% of INITIAL_SUPPLY
     */ 
    function burnMyTokens (uint256 _value) public onlyOwner {
        uint256 limitBurn = token.totalSupply().sub(_value);
        require(limitBurn >= token.INITIAL_SUPPLY().div(2), "The limit of burning tokens is reached");
        token.burn(_value);        
    }
    
    function setDateRelease (uint256 _newDate) public onlyOwner checkDate(_newDate) {
        token.setDateRelease(_newDate);
    }
    
    function setDateStartTransfer(uint256 _newDate) public onlyOwner checkDate(_newDate) {
        token.setDateStartTransfer(_newDate);
    }

    function() external payable {
        revert("The contract doesn`t receive ether");
    } 
}