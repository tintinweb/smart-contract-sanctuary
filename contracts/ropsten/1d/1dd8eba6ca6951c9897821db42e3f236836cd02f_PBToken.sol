/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

/**
 *Submitted for verification at Etherscan.io 
*/

pragma solidity ^0.5.0;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;

    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");

    return a % b;
  }
}

contract Ownable {
    address public _owner;

    /* The Ownable constructor sets the original `owner` of the contract to the sender account. */
    constructor () public {
        _owner = msg.sender;
    }

    /* Throws if called by any account other than the owner. */
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Error: sender is not same owner");
        }
        _;
    }

    /**
    * Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            _owner = newOwner;
        }
    }

    /* Returns the address of the current owner. */
    function owner() public view returns (address) {
        return _owner;
    }
}


contract StandardToken is SafeMath, Ownable{
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) private deactivatedList;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    /* This notifies clients about the another contract to spend some tokens */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyActivatedList() {
        require(deactivatedList[msg.sender] != true, "Error: sender is in deactivatedList.");
        _;
    }

    function addDeactivatedList(address _deactivatedAccount) public onlyOwner {
        deactivatedList[_deactivatedAccount] = true;
    }

    function getDeactivatedList(address _deactivatedAccount) public onlyOwner view returns(bool) {
        return deactivatedList[_deactivatedAccount];
    }

    function removeDeactivatedList(address _deactivatedAccount) public onlyOwner {
        deactivatedList[_deactivatedAccount] = false;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public onlyActivatedList returns (bool) {
        require(_to != address(0x0), "");   // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[msg.sender] >= _value, "");
        require(balanceOf[_to] + _value >= balanceOf[_to], ""); 

        if (balanceOf[msg.sender] >= _value && balanceOf[_to] + _value > balanceOf[_to]) {
            balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
            balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
            emit Transfer(msg.sender, _to, _value);

            return true;
        } else {
            return false;
        }
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* This is an alternative to `approve` that can be used as a mitigation for problems*/
    function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
        approve(_spender, SafeMath.safeAdd(allowance[msg.sender][_spender], _value));
        return true;
    }

    /* This is an alternative to `approve` that can be used as a mitigation for problems*/
    function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
        approve(_spender, SafeMath.safeSub(allowance[msg.sender][_spender], _value));
        return true;
    }
       
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0x0), "");   // Prevent transfer to 0x0 address. Use burn() instead
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender], "TokenTransferFromError");

        require(msg.sender == _owner || deactivatedList[_from] != true, "From is in deactivatedList");

        if (balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value && balanceOf[_to] + _value > balanceOf[_to]) {
            balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           
            // Subtract from the sender
            balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
            // Add the same to the recipient
            allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function burn() public pure {
        require(false, "This function is not supported");
    }

    function withdrawEther() public pure {
        require(false, "This function is not supported");
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /* Modifier to make a function callable only when the contract is not paused. */
    modifier whenNotPaused() {
        if (paused) revert("Error: paused");
        _;
    }

    /* Modifier to make a function callable only when the contract is paused. */
    modifier whenPaused() {
        if (!paused) revert("Error: not paused");
        _;
    }

    /* Called by the owner to pause, triggers stopped state. */
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /* Called by the owner to unpause, returns to normal state */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}


/* Pausable token. Simple ERC20 Token example, with pausable token creation*/
contract PausableToken is Pausable, StandardToken {
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract PBToken is PausableToken{
    string public name;
    string public symbol;
    uint8 public decimals;
    //address public _owner;
    string public version = "1.1.1";

    mapping (address => uint256) public freezeOf;

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
    
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimalUnits);                        // Update total supply
        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        _owner = msg.sender;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "");   // Check if the sender has enough
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);     // Check if the sender has enough
        require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    // can accept ether
    function () external payable { revert("error"); }
}