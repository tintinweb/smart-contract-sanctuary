pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Developed {
    using SafeMath for uint256;
    
    struct Developer {
        address account;
        uint256 comission;
        bool isCollab;
    }
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint64 public totalSupply;


    // State variables for the payout
    uint public payoutBalance = 0;
    uint public payoutIndex = 0;
    bool public paused = false;
    uint public lastPayout;


    constructor() public payable {        
        Developer memory dev = Developer(msg.sender, 1 szabo, true);
        developers[msg.sender] = dev;
        developerAccounts.push(msg.sender);
        name = "MyHealthData Divident Token";
        symbol = "MHDDEV";
        totalSupply = 1 szabo;
    }
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    mapping(address => Developer) internal developers;
    address[] public developerAccounts;
    
    mapping (address => mapping (address => uint256)) private _allowed;
    
    modifier comissionLimit (uint256 value) {
        require(value < 1 szabo, "Invalid value");
        _;
    }

    modifier whenNotPaused () {
        require(paused == false, "Transfers paused, to re-enable transfers finish the payout round.");
        _;
    }

    function () external payable {}

    function newDeveloper(address _devAccount, uint64 _comission, bool _isCollab) public comissionLimit(_comission) returns(address) {
        require(_devAccount != address(0), "Invalid developer account");
        
        bool isCollab = _isCollab;
        Developer storage devRequester = developers[msg.sender];
        //"Developer have to be a collaborator in order to invite others to be a Developer
        if (!devRequester.isCollab) {
            isCollab = false;
        }
        
        require(devRequester.comission>=_comission, "The developer requester must have comission balance in order to sell her commission");
        devRequester.comission = devRequester.comission.sub(_comission);
        
        Developer memory dev = Developer(_devAccount, _comission, isCollab);
        developers[_devAccount] = dev;

        developerAccounts.push(_devAccount);
        return _devAccount;
    }

    function totalDevelopers() public view returns (uint256) {
        return developerAccounts.length;
    }

    function getSingleDeveloper(address _devID) public view returns (address devAccount, uint256 comission, bool isCollaborator) {
        require(_devID != address(0), "Dev ID must be greater than zero");
        //require(devID <= numDevelopers, "Dev ID must be valid. It is greather than total developers available");
        Developer memory dev = developers[_devID];
        devAccount = dev.account;
        comission = dev.comission;
        isCollaborator = dev.isCollab;
        return;
    }
    
    function payComission() public returns (bool success) {
        require (lastPayout < now - 14 days, "Only one payout every two weeks allowed");
        paused = true;
        if (payoutIndex == 0)
            payoutBalance = address(this).balance;
        for (uint i = payoutIndex; i < developerAccounts.length; i++) {
            Developer memory dev = developers[developerAccounts[i]];
            if (dev.comission > 0) {
                uint valueToSendToDev = (payoutBalance.mul(dev.comission)).div(1 szabo);

                // Developers should ensure these TXs will not revert
                // otherwise they&#39;ll lose the payout (payout remains in 
                // balance and will split with everyone in the next round)
                dev.account.send(valueToSendToDev);

                if (gasleft() < 100000) {
                    payoutIndex = i + 1;
                    return;
                }
            }            
        }
        success = true;
        payoutIndex = 0;
        payoutBalance = 0;
        paused = false;
        lastPayout = now;
        return;
    }   
    
    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint64 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        Developer memory dev = developers[owner];
        return dev.comission;
    }
    
    
    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint64 value) public comissionLimit(value) whenNotPaused returns (bool)    {
                
        Developer storage devRequester = developers[from];
        require(devRequester.comission > 0, "The developer receiver must exist");
        
        require(value <= balanceOf(from), "There is no enough balance to perform this operation");
        require(value <= _allowed[from][msg.sender], "Trader is not allowed to transact to this limit");

        Developer storage devReciever = developers[to];
        if (devReciever.account == address(0)) {
            Developer memory dev = Developer(to, 0, false);
            developers[to] = dev;
            developerAccounts.push(to);
        }
        
        devRequester.comission = devRequester.comission.sub(value);
        devReciever.comission = devReciever.comission.add(value);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        
        emit Transfer(from, to, value);
        return true;
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint64 value) public comissionLimit(value) whenNotPaused returns (bool) {
        require(value <= balanceOf(msg.sender), "Spender does not have enough balance");
        require(to != address(0), "Invalid new owner address");
             
        Developer storage devRequester = developers[msg.sender];
        
        require(devRequester.comission >= value, "The developer requester must have comission balance in order to sell her commission");
        
        Developer storage devReciever = developers[to];
        if (devReciever.account == address(0)) {
            Developer memory dev = Developer(to, 0, false);
            developers[to] = dev;
            developerAccounts.push(to);
        }
        
        devRequester.comission = devRequester.comission.sub(value);
        devReciever.comission = devReciever.comission.add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint64 value) public comissionLimit(value) returns (bool) {
        require(spender != address(0), "Invalid spender");
    
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint64 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256)    {
        return _allowed[owner][spender];
    }


    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(address spender, uint64 addedValue) public comissionLimit(addedValue) returns (bool)    {
        require(spender != address(0), "Invalid spender");
        
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public comissionLimit(subtractedValue) returns (bool)    {
        require(spender != address(0), "Invalid spender");
        
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

}