pragma solidity ^0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);

    function transferFrom(address from, address to, uint value) public returns (bool);

    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));

        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        require (_value <= _allowance);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint _value) public returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
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
 * @title ACToken
 */
contract GOENTEST is StandardToken {

    string public constant name = "goentesttoken";
    string public constant symbol = "GOENTEST";
    // string public constant name = "gttoken";
    // string public constant symbol = "GTT";
    uint public constant decimals = 18; // 18位小数

    uint public constant INITIAL_SUPPLY =  10000000000 * (10 ** decimals); // 100000000000000000000000000（100亿）

    /**
    * @dev Contructor that gives msg.sender all of existing tokens.
    */
    constructor() public { 
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}

//big lock storehouse
contract lockStorehouseToken is ERC20 {
    using SafeMath for uint;
    
    GOENTEST   tokenReward;
    
    address private beneficial;
    uint    private lockMonth;
    uint    private startTime;
    uint    private releaseSupply;
    bool    private released = false;
    uint    private per;
    uint    private releasedCount = 0;
    uint    public  limitMaxSupply; //限制从合约转出代币的最大金额
    uint    public  oldBalance;
    uint    private constant decimals = 18;
    
    constructor(
        address _tokenReward,
        address _beneficial,
        uint    _per,
        uint    _startTime,
        uint    _lockMonth,
        uint    _limitMaxSupply
    ) public {
        tokenReward     = GOENTEST(_tokenReward);
        beneficial      = _beneficial;
        per             = _per;
        startTime       = _startTime;
        lockMonth       = _lockMonth;
        limitMaxSupply  = _limitMaxSupply * (10 ** decimals);
        
        // 测试代码
        // tokenReward = GOENT(0xEfe106c517F3d23Ab126a0EBD77f6Ec0f9efc7c7);
        // beneficial = 0x1cDAf48c23F30F1e5bC7F4194E4a9CD8145aB651;
        // per = 125;
        // startTime = now;
        // lockMonth = 1;
        // limitMaxSupply = 3000000000 * (10 ** decimals);
    }
    
    mapping(address => uint) balances;
    
    function approve(address _spender, uint _value) public returns (bool){}
    
    function allowance(address _owner, address _spender) public view returns (uint){}
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require (_value > 0);
        require(_value <= balances[_from]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function getBeneficialAddress() public constant returns (address){
        return beneficial;
    }
    
    function getBalance() public constant returns(uint){
        return tokenReward.balanceOf(this);
    }
    
    modifier checkBalance {
        if(!released){
            oldBalance = getBalance();
            if(oldBalance > limitMaxSupply){
                oldBalance = limitMaxSupply;
            }
        }
        _;
    }
    
    function release() checkBalance public returns(bool) {
        // uint _lockMonth;
        // uint _baseDate;
        uint cliffTime;
        uint monthUnit;
        
        released = true;
        // 释放金额
        releaseSupply = SafeMath.mul(SafeMath.div(oldBalance, 1000), per);
        
        // 释放金额必须小于等于当前合同余额
        if(SafeMath.mul(releasedCount, releaseSupply) <= oldBalance){
            // if(per == 1000){
            //     _lockMonth = SafeMath.div(lockMonth, 12);
            //     _baseDate = 1 years;
                
            // }
            
            // if(per < 1000){
            //     _lockMonth = lockMonth;
            //     _baseDate = 30 days;
            //     // _baseDate = 1 minutes;
            // }

            // _lockMonth = lockMonth;
            // _baseDate = 30 days;
            // monthUnit = SafeMath.mul(5, 1 minutes);
            monthUnit = SafeMath.mul(lockMonth, 30 days);
            cliffTime = SafeMath.add(startTime, monthUnit);
        
            if(now > cliffTime){
                
                tokenReward.transfer(beneficial, releaseSupply);
                
                releasedCount++;

                startTime = now;
                
                return true;
            
            }
        } else {
            return false;
        }
        
    }
    
    function () private payable {
    }
}