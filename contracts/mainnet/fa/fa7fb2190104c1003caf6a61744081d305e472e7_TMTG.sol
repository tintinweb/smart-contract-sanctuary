pragma solidity ^0.4.24;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

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
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract TMTGOwnable {
    address public owner;
    address public centralBanker;
    address public superOwner;
    address public hiddenOwner;
    
    enum Role { owner, centralBanker, superOwner, hiddenOwner }

    mapping(address => bool) public operators;
    
    
    event TMTG_RoleTransferred(
        Role indexed ownerType,
        address indexed previousOwner,
        address indexed newOwner
    );
    
    event TMTG_SetOperator(address indexed operator); 
    event TMTG_DeletedOperator(address indexed operator);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner || operators[msg.sender]);
        _;
    }
    
    modifier onlyNotBankOwner(){
        require(msg.sender != centralBanker);
        _;
    }
    
    modifier onlyBankOwner(){
        require(msg.sender == centralBanker);
        _;
    }
    
    modifier onlySuperOwner() {
        require(msg.sender == superOwner);
        _;
    }
    
    modifier onlyhiddenOwner(){
        require(msg.sender == hiddenOwner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;     
        centralBanker = msg.sender;
        superOwner = msg.sender; 
        hiddenOwner = msg.sender;
    }

    function setOperator(address _operator) external onlySuperOwner {
        operators[_operator] = true;
        emit TMTG_SetOperator(_operator);
    }

    function delOperator(address _operator) external onlySuperOwner {
        operators[_operator] = false;
        emit TMTG_DeletedOperator(_operator);
    }

    function transferOwnership(address newOwner) public onlySuperOwner {
        emit TMTG_RoleTransferred(Role.owner, owner, newOwner);
        owner = newOwner;
    }

    function transferBankOwnership(address newBanker) public onlySuperOwner {
        emit TMTG_RoleTransferred(Role.centralBanker, centralBanker, newBanker);
        centralBanker = newBanker;
    }
 
    function transferSuperOwnership(address newSuperOwner) public onlyhiddenOwner {
        emit TMTG_RoleTransferred(Role.superOwner, superOwner, newSuperOwner);
        superOwner = newSuperOwner;
    }
  
    function changehiddenOwner(address newhiddenOwner) public onlyhiddenOwner {
        emit TMTG_RoleTransferred(Role.hiddenOwner, hiddenOwner, newhiddenOwner);
        hiddenOwner = newhiddenOwner;
    }
}

contract TMTGPausable is TMTGOwnable {
    event TMTG_Pause();
    event TMTG_Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }
  
    function pause() onlyOwnerOrOperator whenNotPaused public {
        paused = true;
        emit TMTG_Pause();
    }
  
    function unpause() onlyOwnerOrOperator whenPaused public {
        paused = false;
        emit TMTG_Unpause();
    }
}

contract TMTGBlacklist is TMTGOwnable {
    mapping(address => bool) blacklisted;
    
    event TMTG_Blacklisted(address indexed blacklist);
    event TMTG_Whitelisted(address indexed whitelist);

    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }

    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }

    function blacklist(address node) public onlyOwnerOrOperator {
        blacklisted[node] = true;
        emit TMTG_Blacklisted(node);
    }

    function unblacklist(address node) public onlyOwnerOrOperator {
        blacklisted[node] = false;
        emit TMTG_Whitelisted(node);
    }
}

contract HasNoEther is TMTGOwnable {
    constructor() public payable {
        require(msg.value == 0);
    }

    function() external {
    }

    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

contract TMTGBaseToken is StandardToken, TMTGPausable, TMTGBlacklist, HasNoEther {
    
    event TMTG_TransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value);
    event TMTG_Burn(address indexed burner, uint256 value);
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool ret) {
        ret = super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool ret) {
        ret = super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool ret) {
        ret = super.decreaseApproval(_spender, _subtractedValue);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Transfer(_who, address(0), _value);
        emit TMTG_Burn(_who, _value);
    }

    function burn(uint256 _value) onlyOwner public returns (bool) {
        _burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
        
        return true;
    }
    
    function reclaimToken() external onlyOwner {
        transfer(owner, balanceOf(this));
    }
    
    
    function destroy() onlyhiddenOwner public {
        selfdestruct(superOwner);
    }    
}

contract TMTG is TMTGBaseToken {
    string public constant name = "The Midas Touch Gold";
    string public constant symbol = "TMTG";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals));
    uint256 public openingTime;
    
    struct investor {
        uint256 _sentAmount;
        uint256 _initialAmount;
        uint256 _limit;
    }

    mapping(address => investor) public searchInvestor;
    mapping(address => bool) public superInvestor;
    mapping(address => bool) public CEx;
    mapping(address => bool) public investorList;

    event TMTG_SetInvestor(address indexed investor); 
    event TMTG_DeleteInvestor(address indexed investor);
    event TMTG_Stash(uint256 _value);
    event TMTG_Unstash(uint256 _value);
    event TMTG_SetCEx(address indexed CEx); 
    event TMTG_DeleteCEx(address indexed CEx);
    event TMTG_SetSuperInvestor(address indexed SuperInvestor); 
    event TMTG_DeleteSuperInvestor(address indexed SuperInvestor);
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        openingTime = block.timestamp;

        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function setCEx(address _CEx) external onlySuperOwner {   
        CEx[_CEx] = true;
        
        emit TMTG_SetCEx(_CEx);
    }

    function delCEx(address _CEx) external onlySuperOwner {   
        CEx[_CEx] = false;
        
        emit TMTG_DeleteCEx(_CEx);
    }

    function setSuperInvestor(address _super) external onlySuperOwner {
        superInvestor[_super] = true;
        
        emit TMTG_SetSuperInvestor(_super);
    }
    
    function delSuperInvestor(address _super) external onlySuperOwner {
        superInvestor[_super] = false;
        
        emit TMTG_DeleteSuperInvestor(_super);
    }
    
    function setOpeningTime() onlyOwner public {
        openingTime = block.timestamp;
    }

    function delInvestor(address _addr) onlySuperOwner public {
        investorList[_addr] = false;
        searchInvestor[_addr] = investor(0,0,0);
        emit TMTG_DeleteInvestor(_addr);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused onlyNotBankOwner returns (bool) {
        require(!superInvestor[msg.sender]);
        return super.approve(_spender,_value);     
    }

    function _timelimitCal(address who) internal view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 _result = timeValue.div(30 days);

        return _result.mul(searchInvestor[who]._limit);
    }

    function _transferInvestor(address _to, uint256 _value) internal returns (bool ret) {
        uint256 addedValue = searchInvestor[msg.sender]._sentAmount.add(_value);
        
        require(_timelimitCal(msg.sender) >= addedValue);
        
        searchInvestor[msg.sender]._sentAmount = searchInvestor[msg.sender]._sentAmount.sub(_value);
        ret = super.transfer(_to, _value);
        if (!ret) {
            searchInvestor[msg.sender]._sentAmount = searchInvestor[msg.sender]._sentAmount.add(_value);
        }
    }

    function transfer(address _to, uint256 _value) public
    whenPermitted(msg.sender) whenPermitted(_to) whenNotPaused onlyNotBankOwner
    returns (bool) {   
        
        if(investorList[msg.sender]) {
            return _transferInvestor(_to, _value);
        
        } else {
            if (superInvestor[msg.sender]) {
                require(_to != owner);
                require(!superInvestor[_to]);
                require(!CEx[_to]);

                if(!investorList[_to]){
                    investorList[_to] = true;
                    searchInvestor[_to] = investor(0, _value, _value.div(10));
                    emit TMTG_SetInvestor(_to); 
                }
            }
            return super.transfer(_to, _value);
        }
    }

    function _transferFromInvestor(address _from, address _to, uint256 _value)
    public returns(bool ret) {
        uint256 addedValue = searchInvestor[_from]._sentAmount.add(_value);
        require(_timelimitCal(_from) >= addedValue);
        searchInvestor[_from]._sentAmount = searchInvestor[_from]._sentAmount.sub(_value);
        ret = super.transferFrom(_from, _to, _value);

        if (!ret) {
            searchInvestor[_from]._sentAmount = searchInvestor[_from]._sentAmount.add(_value);
        }else {
            emit TMTG_TransferFrom(_from, msg.sender, _to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public whenNotPaused whenPermitted(msg.sender) whenPermitted(_to) returns (bool ret)
    {   
        if(investorList[_from]) {
            return _transferFromInvestor(_from,_to, _value);
        } else {
            ret = super.transferFrom(_from, _to, _value);
            emit TMTG_TransferFrom(_from, msg.sender, _to, _value);
        }
    }

    function getLimitPeriod() public view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 result = timeValue.div(30 days);
        return result;
    }
    
    function stash(uint256 _value) public onlyOwner {
        require(balances[owner] >= _value);
        
        balances[owner] = balances[owner].sub(_value);
        
        balances[centralBanker] = balances[centralBanker].add(_value);
        
        emit TMTG_Stash(_value);        
    }

    function unstash(uint256 _value) public onlyBankOwner {
        require(balances[centralBanker] >= _value);
        
        balances[centralBanker] = balances[centralBanker].sub(_value);
        
        balances[owner] = balances[owner].add(_value);
        
        emit TMTG_Unstash(_value);
    }
}