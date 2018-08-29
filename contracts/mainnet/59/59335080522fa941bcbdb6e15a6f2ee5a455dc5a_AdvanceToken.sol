pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

contract owned {

    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract saleOwned is owned{
    mapping (address => bool) public saleContract;

    modifier onlySaleOwner {        
        require(msg.sender == owner || true == saleContract[msg.sender]);
        _;
    }

    function isSaleOwner() public view returns (bool success) {     
        if(msg.sender == owner || true == saleContract[msg.sender])
            return true;
        return false;
    }

    function addSaleOwner(address saleOwner) onlyOwner public {
        saleContract[saleOwner] = true;
    }

    function delSaleOwner(address saleOwner) onlyOwner public {
        saleContract[saleOwner] = false;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is saleOwned {
    event Pause();
    event Unpause();

    bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
    modifier whenNotPaused() {
        require(false == paused);
        _;
    }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
    modifier whenPaused {
        require(true == paused);
        _;
    }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

/******************************************/
/*       BASE TOKEN STARTS HERE       */
/******************************************/
contract BaseToken is Pausable{
    using SafeMath for uint256;    
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256))  approvals;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed approval, address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint value);

    function BaseToken(
        string tokenName,
        string tokenSymbol
    ) public {
        decimals = 18;
        name = tokenName;
        symbol = tokenSymbol;
    }    
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) whenNotPaused public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused public returns (bool) {
        assert(balanceOf[_from] >= _value);
        assert(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        
        emit TransferFrom(msg.sender, _from, _to, _value);
        
        return true;
    }

    function allowance(address src, address guy) public view returns (uint256) {
        return approvals[src][guy];
    }

    function approve(address guy, uint256 _value) public returns (bool) {
        approvals[msg.sender][guy] = _value;
        
        emit Approval(msg.sender, guy, _value);
        
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/
contract AdvanceToken is BaseToken {
    string tokenName        = "8ENCORE";       // Set the name for display purposes
    string tokenSymbol      = "8EN";           // Set the symbol for display purposes

    struct frozenStruct {        
        uint startTime;
        uint endTime;
    }
    
    mapping (address => bool) public frozenAccount;
    mapping (address => frozenStruct) public frozenTime;   
    
    frozenStruct public allFrozenTime;          // all frozenTime

    event AllFrozenFunds(uint startTime, uint endTime);
    event FrozenFunds(address target, bool frozen, uint startTime, uint endTime);    
    event Burn(address indexed from, uint256 value);
    
    function AdvanceToken() BaseToken(tokenName, tokenSymbol) public {
        allFrozenTime.startTime = 0;
        allFrozenTime.endTime = 0;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        
        if(false == isSaleOwner())                          // for refund
            require(false == isAllFrozen());                // Check is Allfrozen

        require(false == isFrozen(_from));                  // Check if sender is frozen        

        if(false == isSaleOwner())                          // for refund
            require(false == isFrozen(_to));                // Check if recipient is frozen

        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient

        emit Transfer(_from, _to, _value);
    }

    function mintToken(uint256 mintedAmount) onlyOwner public {
        uint256 mintSupply = mintedAmount.mul(10 ** uint256(decimals));
        balanceOf[msg.sender] = balanceOf[msg.sender].add(mintSupply);
        totalSupply = totalSupply.add(mintSupply);
        emit Transfer(0, this, mintSupply);
        emit Transfer(this, msg.sender, mintSupply);
    }

    function isAllFrozen() public view returns (bool success) {
        if(0 == allFrozenTime.startTime && 0 == allFrozenTime.endTime)
            return true;

        if(allFrozenTime.startTime <= now && now <= allFrozenTime.endTime)
            return true;
        
        return false;
    }

    function isFrozen(address target) public view returns (bool success) {        
        if(false == frozenAccount[target])
            return false;

        if(frozenTime[target].startTime <= now && now <= frozenTime[target].endTime)
            return true;
        
        return false;
    }

    function setAllFreeze(uint startTime, uint endTime) onlyOwner public {           
        allFrozenTime.startTime = startTime;
        allFrozenTime.endTime = endTime;
        emit AllFrozenFunds(startTime, endTime);
    }

    function freezeAccount(address target, bool freeze, uint startTime, uint endTime) onlySaleOwner public {
        frozenAccount[target] = freeze;
        frozenTime[target].startTime = startTime;
        frozenTime[target].endTime = endTime;
        emit FrozenFunds(target, freeze, startTime, endTime);
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}