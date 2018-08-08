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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
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

/**
 * @title TMTGOwnable
 *
 * @dev zeppelin의 ownable의 변형으로 TMTGOwnable에서 권한은 hiddenOwner, superOwner, owner, centralBanker, operator가 있습니다.
 * 각 권한마다 역할이 다릅니다.
 */
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

    /**
    * @dev 해당 주소를 operator로 설정한다.
    * @param _operator has the ability to pause transaction, has the ability to blacklisting & unblacklisting. 
    */
    function setOperator(address _operator) external onlySuperOwner {
        operators[_operator] = true;
        emit TMTG_SetOperator(_operator);
    }

    /**
    * @dev 해당 주소를 operator에서 해제한다.
    * @param _operator has the ability to pause transaction, has the ability to blacklisting & unblacklisting. 
    */
    function delOperator(address _operator) external onlySuperOwner {
        operators[_operator] = false;
        emit TMTG_DeletedOperator(_operator);
    }

    /**
    * @dev owner의 권한을 넘겨 줄 수 있다. 단, superowner만 실행할 수 있다.
    * @param newOwner  
    */
    function transferOwnership(address newOwner) public onlySuperOwner {
        emit TMTG_RoleTransferred(Role.owner, owner, newOwner);
        owner = newOwner;
    }

    /**
    * @dev centralBanker의 권한을 넘겨 줄 수 있다. 단, superOwner만 실행할 수 있다.
    * @param newBanker centralBanker는 일종의 중앙은행으로 거래가 불가능하다. 
    * 지급 준비율과 통화량에 따라 묶여있는 금액이 결정되어진다.
    * 돈을 꺼내기 위해서는 감사를 거쳐서 owner쪽으로 인출이 가능하다. 
    */
    function transferBankOwnership(address newBanker) public onlySuperOwner {
        emit TMTG_RoleTransferred(Role.centralBanker, centralBanker, newBanker);
        centralBanker = newBanker;
    }

    /**
    * @dev superOwner의 권한을 넘겨 줄 수 있다. 단, hiddenOwner만 실행 할 수 있다.
    * @param newSuperOwner  superOwner는 hiddenOwner와 superOwner를 제외한 모든 권한 여부를 관리한다.
    */
    function transferSuperOwnership(address newSuperOwner) public onlyhiddenOwner {
        emit TMTG_RoleTransferred(Role.superOwner, superOwner, newSuperOwner);
        superOwner = newSuperOwner;
    }
    
    /**
    * @dev hiddenOwner의 권한 을 넘겨 줄 수 있다. 단, hiddenOwner만 실행 할 수 있다.
    * @param newhiddenOwner hiddenOwner는 별 다른 기능은 없지만 
    * superOwner와 hiddenOwner의 권한에 대해 설정 및 해제가 가능하다.   
    */
    function changeHiddenOwner(address newhiddenOwner) public onlyhiddenOwner {
        emit TMTG_RoleTransferred(Role.hiddenOwner, hiddenOwner, newhiddenOwner);
        hiddenOwner = newhiddenOwner;
    }
}

/**
 * @title TMTGPausable
 *
 * @dev 긴급한 상황에서 거래를 중지시킬때 사용한다.
 */
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
    /**
    * @dev 거래를 할 수 없게 막는다. 단, owner 또는 operator만 실행 할 수 있다.
    */
    function pause() onlyOwnerOrOperator whenNotPaused public {
        paused = true;
        emit TMTG_Pause();
    }
  
    /**
    * @dev 거래를 할 수 있게 풀어준다. 단, owner 또는 operator만 실행 할 수 있으며 paused 상태일 때만 이용이 가능하다.
    */
    function unpause() onlyOwnerOrOperator whenPaused public {
        paused = false;
        emit TMTG_Unpause();
    }
}

/**
 * @title TMTGBlacklist
 *
 * @dev 이상 징후가 있는 계정의 주소에 대해 거래를 할 수 없게 막는다.
 */
contract TMTGBlacklist is TMTGOwnable {
    mapping(address => bool) blacklisted;
    
    event TMTG_Blacklisted(address indexed blacklist);
    event TMTG_Whitelisted(address indexed whitelist);

    modifier whenPermitted(address node) {
        require(!blacklisted[node]);
        _;
    }
    
    /**
    * @dev 블랙리스팅 여부를 확인한다.
    * @param node  해당 사용자가 블랙리스트에 등록되었는가에 대한 유무를  확인한다.   
    */
    function isPermitted(address node) public view returns (bool) {
        return !blacklisted[node];
    }

    /**
    * @dev 블랙리스팅 처리한다.
    * @param node  해당 사용자를 블랙리스트에 등록한다.   
    */
    function blacklist(address node) public onlyOwnerOrOperator {
        blacklisted[node] = true;
        emit TMTG_Blacklisted(node);
    }

    /**
    * @dev 블랙리스트에서 해제한다.
    * @param node  해당 사용자를 블랙리스트에서 제거한다.   
    */
    function unblacklist(address node) public onlyOwnerOrOperator {
        blacklisted[node] = false;
        emit TMTG_Whitelisted(node);
    }
}

/**
 * @title HasNoEther
 *
 * @dev 이상 징후가 있는 계정의 주소에 대해 거래를 할 수 없게 막는다.
 */
contract HasNoEther is TMTGOwnable {
    
    /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
    constructor() public payable {
        require(msg.value == 0);
    }
    
    /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
    function() external {
    }
    
    /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

/**
 * @title TMTGBaseToken 토큰락과 권한 설정 등 주요함수가 등록되어 있다.
 */
contract TMTGBaseToken is StandardToken, TMTGPausable, TMTGBlacklist, HasNoEther {
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
    
    event TMTG_SetCEx(address indexed CEx); 
    event TMTG_DeleteCEx(address indexed CEx);
    
    event TMTG_SetSuperInvestor(address indexed SuperInvestor); 
    event TMTG_DeleteSuperInvestor(address indexed SuperInvestor);
    
    event TMTG_SetInvestor(address indexed investor); 
    event TMTG_DeleteInvestor(address indexed investor);
    
    event TMTG_Stash(uint256 _value);
    event TMTG_Unstash(uint256 _value);

    event TMTG_TransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value);
    event TMTG_Burn(address indexed burner, uint256 value);
    
    /**
    * @dev 거래소 주소를 등록한다.
    * @param _CEx  해당 주소를 거래소 주소로 등록한다.   
    */
    function setCEx(address _CEx) external onlySuperOwner {   
        CEx[_CEx] = true;
        
        emit TMTG_SetCEx(_CEx);
    }

    /**
    * @dev 거래소 주소를 해제한다.
    * @param _CEx  해당 주소의 거래소 권한을 해제한다.   
    */
    function delCEx(address _CEx) external onlySuperOwner {   
        CEx[_CEx] = false;
        
        emit TMTG_DeleteCEx(_CEx);
    }

    /**
    * @dev 수퍼투자자 주소를 등록한다.
    * @param _super  해당 주소를 수퍼투자자 주소로 등록한다.   
    */
    function setSuperInvestor(address _super) external onlySuperOwner {
        superInvestor[_super] = true;
        
        emit TMTG_SetSuperInvestor(_super);
    }

    /**
    * @dev 수퍼투자자 주소를 해제한다.
    * @param _super  해당 주소의 수퍼투자자 권한을 해제한다.   
    */
    function delSuperInvestor(address _super) external onlySuperOwner {
        superInvestor[_super] = false;
        
        emit TMTG_DeleteSuperInvestor(_super);
    }

    /**
    * @dev 투자자 주소를 해제한다.
    * @param _addr  해당 주소를 투자자 주소로 해제한다.   
    */
    function delInvestor(address _addr) onlySuperOwner public {
        investorList[_addr] = false;
        searchInvestor[_addr] = investor(0,0,0);
        emit TMTG_DeleteInvestor(_addr);
    }

    /**
    * @dev 투자자의 토큰락 시작 시점을 지정한다.   
    */
    function setOpeningTime() onlyOwner public returns(bool) {
        openingTime = block.timestamp;

    }

    /**
    * @dev 현재 투자자의 토큰락에 대해 초기 수퍼투자자로부터 받은 양의 몇 %를 받을 수 있는가를 확인 할 수 있다.
    * 1달이 되었을때 1이 되며 10%를 사용이 가능하고, 7일 경우 70%의 값에 해당하는 코인을 자유롭게 사용이 가능하다.   
    */
    function getLimitPeriod() public view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 result = timeValue.div(31 days);
        return result;
    }

    /**
    * @dev 최신 리밋을 확인한다.
    * @param who 해당 사용자의 현 시점에서의 리밋 값을 리턴한다. 3달이 지났을 경우, 
    * _result 의 값은 수퍼투자자로부터 최초에 받은 30%가 사용이 가능하다. 
    */
    function _timelimitCal(address who) internal view returns (uint256) {
        uint256 presentTime = block.timestamp;
        uint256 timeValue = presentTime.sub(openingTime);
        uint256 _result = timeValue.div(31 days);

        return _result.mul(searchInvestor[who]._limit);
    }

    /**
    * @dev 인베스터가 transfer하는 경우, 타임락에 따라 값을 제한한다.
    * @param _to address to send
    * @param _value tmtg&#39;s amount
    */
    function _transferInvestor(address _to, uint256 _value) internal returns (bool ret) {
        uint256 addedValue = searchInvestor[msg.sender]._sentAmount.add(_value);

        require(_timelimitCal(msg.sender) >= addedValue);
        
        searchInvestor[msg.sender]._sentAmount = addedValue;        
        ret = super.transfer(_to, _value);
        if (!ret) {
        searchInvestor[msg.sender]._sentAmount = searchInvestor[msg.sender]._sentAmount.sub(_value);
        }
    }

    /**
    * @dev transfer 함수를 실행할 때, 수퍼인베스터가 인베스터에게 보내는 경우와 인베스터가 아닌 사람에게 보내는 경우로 나뉘어지며,
    * 인베스터가 아닌 사람에게 보내는 경우, 해당 사용자를 인베스터로 만들며, 최초 보낸 금액의 10%가 limit으로 할당된다.
    * 또한 인베스터가 transfer 함수를 실행하는 경우, 타임락에 따라 보내는 값이 제한된다.
    * @param _to address to send
    * @param _value tmtg&#39;s amount
    */
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
    /**
    * @dev 인베스터가 transferFrom에서 from 인 경우, 타임락에 따라 값을 제한한다.
    * @param _from send amount from this address 
    * @param _to address to send
    * @param _value tmtg&#39;s amount
    */
    function _transferFromInvestor(address _from, address _to, uint256 _value)
    public returns(bool ret) {
        uint256 addedValue = searchInvestor[_from]._sentAmount.add(_value);
        require(_timelimitCal(_from) >= addedValue);
        searchInvestor[_from]._sentAmount = addedValue;
        ret = super.transferFrom(_from, _to, _value);

        if (!ret) {
            searchInvestor[_from]._sentAmount = searchInvestor[_from]._sentAmount.sub(_value);
        }else {
            emit TMTG_TransferFrom(_from, msg.sender, _to, _value);
        }
    }

    /**
    * @dev transferFrom에서 superInvestor인 경우 approve에서 제한되므로 해당 함수를 사용하지 못한다. 또한 인베스터인 경우,
    * 타임락에 따라 양이 제한된다.
    * @param _from send amount from this address 
    * @param _to address to send
    * @param _value tmtg&#39;s amount
    */
    function transferFrom(address _from, address _to, uint256 _value)
    public whenNotPaused whenPermitted(msg.sender) whenPermitted(_to) returns (bool ret)
    {   
        if(investorList[_from]) {
            return _transferFromInvestor(_from, _to, _value);
        } else {
            ret = super.transferFrom(_from, _to, _value);
            emit TMTG_TransferFrom(_from, msg.sender, _to, _value);
        }
    }

    function approve(address _spender, uint256 _value) public
    whenPermitted(msg.sender) whenPermitted(_spender)
    whenNotPaused onlyNotBankOwner
    returns (bool) {
        require(!superInvestor[msg.sender]);
        return super.approve(_spender,_value);     
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public 
    whenNotPaused onlyNotBankOwner
    whenPermitted(msg.sender) whenPermitted(_spender)
    returns (bool) {
        require(!superInvestor[msg.sender]);
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) public
    whenNotPaused onlyNotBankOwner
    whenPermitted(msg.sender) whenPermitted(_spender)
    returns (bool) {
        require(!superInvestor[msg.sender]);
        return super.decreaseApproval(_spender, _subtractedValue);
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
    
    /**
    * @dev owner만 실행이 가능하고, 해당 코인의 양만큼 centralBanker에 입금이 가능하다.
    * @param _value tmtg&#39;s amount
    */
    function stash(uint256 _value) public onlyOwner {
        require(balances[owner] >= _value);
        
        balances[owner] = balances[owner].sub(_value);
        
        balances[centralBanker] = balances[centralBanker].add(_value);
        
        emit TMTG_Stash(_value);        
    }
    /**
    * @dev centralBanker만 실행이 가능하고, 해당 코인의 양만큼 owner에게 출금이 가능하다.
    * 단, 검수를 거쳐서 실행된다.
    * @param _value tmtg&#39;s amount
    */
    function unstash(uint256 _value) public onlyBankOwner {
        require(balances[centralBanker] >= _value);
        
        balances[centralBanker] = balances[centralBanker].sub(_value);
        
        balances[owner] = balances[owner].add(_value);
        
        emit TMTG_Unstash(_value);
    }
    
    function reclaimToken() external onlyOwner {
        transfer(owner, balanceOf(this));
    }
    
    function destory() onlyhiddenOwner public {
        selfdestruct(superOwner);
    } 

    /**
    * @dev 투자자가 거래소에서 추가 금액을 샀을 경우, 추가여분은 10개월간 토큰락이 걸린다. 이 때, 관리자의 입회 하에 해당 금액을 옮기게 해줌
    * @param _investor 
    * @param _to 
    * @param _amount 
    */
    function refreshInvestor(address _investor, address _to, uint _amount) onlyOwner public  {
       require(investorList[_investor]);
       require(_to != address(0));
       require(_amount <= balances[_investor]);
       balances[_investor] = balances[_investor].sub(_amount);
       balances[_to] = balances[_to].add(_amount); 
    }
}

contract TMTG is TMTGBaseToken {
    string public constant name = "The Midas Touch Gold";
    string public constant symbol = "TMTG";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1e10 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        openingTime = block.timestamp;

        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}