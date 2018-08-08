pragma solidity ^0.4.16;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract LBN is SafeMath {
    string public constant name = "Leber Network";
    string public constant symbol = "LBN";
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 100000000 * (10 ** uint256(decimals));
    uint256 public airdropSupply = 9000000 * (10 ** uint256(decimals));

    uint256 public airdropCount;
    mapping(address => bool) airdropTouched;

    uint256 public constant airdropCountLimit1 = 20000;
    uint256 public constant airdropCountLimit2 = 20000;

    uint256 public constant airdropNum1 = 300 * (10 ** uint256(decimals));
    uint256 public constant airdropNum2 = 150 * (10 ** uint256(decimals));

    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LBN() public {
        owner = msg.sender;

        airdropCount = 0;
        balanceOf[address(this)] = airdropSupply;
        balanceOf[msg.sender] = totalSupply - airdropSupply;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply, _value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
        require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    function () external payable {
        require(balanceOf[address(this)] > 0);
        require(!airdropTouched[msg.sender]);
        require(airdropCount < airdropCountLimit1 + airdropCountLimit2);

        airdropTouched[msg.sender] = true;
        airdropCount = SafeMath.safeAdd(airdropCount, 1);

        if (airdropCount <= airdropCountLimit1) {
            _transfer(address(this), msg.sender, airdropNum1);
        } else if (airdropCount <= airdropCountLimit1 + airdropCountLimit2) {
            _transfer(address(this), msg.sender, airdropNum2); 
        }
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require(balanceOf[_from] >= _value);               // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
   
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                         // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
         
        Transfer(_from, _to, _value);
    }
}