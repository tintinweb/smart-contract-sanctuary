pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

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
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title ERC20 interface
 */
contract AbstractERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool _success);
    function allowance(address owner, address spender) public constant returns (uint256 _value);
    function transferFrom(address from, address to, uint256 value) public returns (bool _success);
    function approve(address spender, uint256 value) public returns (bool _success);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract TradCoin is Ownable, AbstractERC20 {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    //address of distributor
    address public distributor;
    // The time after which Trad tokens become transferable.
    // Current value is July 30, 2018 23:59:59 Eastern Time.
    uint256 becomesTransferable = 1533009599;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    // balances allowed to transfer during locking
    mapping (address => uint256) internal balancesAllowedToTransfer;
    //mapping to show person is investor or team/project, true=>investor, false=>team/project
    mapping (address => bool) public isInvestor;

    event DistributorTransferred(address indexed _from, address indexed _to);
    event Allocated(address _owner, address _investor, uint256 _tokenAmount);

    constructor(address _distributor) public {
        require (_distributor != address(0x0));
        name = "TradCoin";
        symbol = "TRADCoin";
        decimals = 18 ;
        totalSupply = 300e6 * 10**18;    // 300 million tokens
        owner = msg.sender;
        distributor = _distributor;
        balances[distributor] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

    /// manually send tokens to investor
    function allocateTokensToInvestors(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_to != address(0x0));
        require(_value > 0);
        uint256 unlockValue = (_value.mul(30)).div(100);
        // SafeMath.sub will throw if there is not enough balance.
        balances[distributor] = balances[distributor].sub(_value);
        balances[_to] = balances[_to].add(_value);
        balancesAllowedToTransfer[_to] = unlockValue;
        isInvestor[_to] = true;
        emit Allocated(msg.sender, _to, _value);
        return true;
    }

    /// manually send tokens to investor
    function allocateTokensToTeamAndProjects(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_to != address(0x0));
        require(_value > 0);
        // SafeMath.sub will throw if there is not enough balance.
        balances[distributor] = balances[distributor].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Allocated(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Check balance of given account address
    * @param owner The address account whose balance you want to know
    * @return balance of the account
    */
    function balanceOf(address owner) public view returns (uint256){
        return balances[owner];
    }

    /**
    * @dev transfer token for a specified address (written due to backward compatibility)
    * @param to address to which token is transferred
    * @param value amount of tokens to transfer
    * return bool true=> transfer is succesful
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0x0));
        require(value <= balances[msg.sender]);
        uint256 valueAllowedToTransfer;
        if(isInvestor[msg.sender]){
            if (now >= becomesTransferable){
                valueAllowedToTransfer = balances[msg.sender];
                assert(value <= valueAllowedToTransfer);
            }else{
                valueAllowedToTransfer = balancesAllowedToTransfer[msg.sender];
                assert(value <= valueAllowedToTransfer);
                balancesAllowedToTransfer[msg.sender] = balancesAllowedToTransfer[msg.sender].sub(value);
            }
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address from which token is transferred 
    * @param to address to which token is transferred
    * @param value amount of tokens to transfer
    * @return bool true=> transfer is succesful
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0x0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        uint256 valueAllowedToTransfer;
        if(isInvestor[from]){
            if (now >= becomesTransferable){
                valueAllowedToTransfer = balances[from];
                assert(value <= valueAllowedToTransfer);
            }else{
                valueAllowedToTransfer = balancesAllowedToTransfer[from];
                assert(value <= valueAllowedToTransfer);
                balancesAllowedToTransfer[from] = balancesAllowedToTransfer[from].sub(value);
            }
        }
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    //function to check available balance to transfer tokens during locking perios for investors
    function availableBalanceInLockingPeriodForInvestor(address owner) public view returns(uint256){
        return balancesAllowedToTransfer[owner];
    }

    /**
    * @dev Approve function will delegate spender to spent tokens on msg.sender behalf
    * @param spender ddress which is delegated
    * @param value tokens amount which are delegated
    * @return bool true=> approve is succesful
    */
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev it will check amount of token delegated to spender by owner
    * @param owner the address which allows someone to spend fund on his behalf
    * @param spender address which is delegated
    * @return return uint256 amount of tokens left with delegator
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
    * @dev increment the spender delegated tokens
    * @param spender address which is delegated
    * @param valueToAdd tokens amount to increment
    * @return bool true=> operation is succesful
    */
    function increaseApproval(address spender, uint valueToAdd) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(valueToAdd);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev deccrement the spender delegated tokens
    * @param spender address which is delegated
    * @param valueToSubstract tokens amount to decrement
    * @return bool true=> operation is succesful
    */
    function decreaseApproval(address spender, uint valueToSubstract) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (valueToSubstract > oldValue) {
          allowed[msg.sender][spender] = 0;
        } else {
          allowed[msg.sender][spender] = oldValue.sub(valueToSubstract);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

}