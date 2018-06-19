pragma solidity ^0.4.21;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Lockable is Ownable {
    bool public contractLocked = false;

    modifier notLocked() {
        require(!contractLocked);
        _;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;
    }

    function unlockContract() public onlyOwner {
        contractLocked = false;
    }
}

contract FeeCalculator is Ownable, SafeMath {

    uint public feeNumerator = 0;

    uint public feeDenominator = 0;

    uint public minFee = 0;

    uint public maxFee = 0;

    function setFee(uint _feeNumerator, uint _feeDenominator, uint _minFee, uint _maxFee) public onlyOwner {
        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;
        minFee = _minFee;
        maxFee = _maxFee;
    }

    function calculateFee(uint value) public view returns (uint requiredFee) {
        if (feeNumerator == 0 || feeDenominator == 0) return 0;

        uint fee = safeDiv(safeMul(value, feeNumerator), feeDenominator);

        if (fee < minFee) return minFee;

        if (fee > maxFee) return maxFee;

        return fee;
    }

    function subtractFee(uint value) internal returns (uint newValue);
}

contract EIP20Interface {
    uint256 public totalSupply;

    function balanceOf(address owner) public view returns (uint256 balance);

    function transfer(address to, uint256 value) public returns (bool success);

    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value) public returns (bool success);

    function allowance(address owner, address spender) public view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Mintable is Ownable {
    mapping(address => bool) public minters;

    modifier onlyMinter {
        require(minters[msg.sender] == true);
        _;
    }

    function Mintable() public {
        adjustMinter(msg.sender, true);
    }

    function adjustMinter(address minter, bool canMint) public onlyOwner {
        minters[minter] = canMint;
    }

    function mint(address to, uint256 value) public;

}

contract Token is EIP20Interface, Ownable, SafeMath, Mintable, Lockable, FeeCalculator {

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowed;

    mapping(address => bool) frozenAddresses;

    string public name;

    uint8 public decimals;

    string public symbol;

    bool public isBurnable;

    bool public canAnyoneBurn;

    modifier notFrozen(address target) {
        require(!frozenAddresses[target]);
        _;
    }

    event AddressFroze(address target, bool isFrozen);

    function Token(string _name, uint8 _decimals, string _symbol) public {
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
    }

    function transfer(address to, uint256 value) notLocked notFrozen(msg.sender) public returns (bool success) {
        return transfer(msg.sender, to, value);
    }

    function transfer(address from, address to, uint256 value) internal returns (bool success) {
        balances[from] = safeSub(balances[from], value);
        value = subtractFee(value);
        balances[to] = safeAdd(balances[to], value);

        emit Transfer(from, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) notLocked notFrozen(from) public returns (bool success) {
        uint256 allowance = allowed[from][msg.sender];
        balances[from] = safeSub(balances[from], value);
        allowed[from][msg.sender] = safeSub(allowance, value);
        value = subtractFee(value);
        balances[to] = safeAdd(balances[to], value);

        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) notLocked public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256 remaining) {
        return allowed[owner][spender];
    }

    function freezeAddress(address target, bool freeze) onlyOwner public {
        if (freeze) {
            frozenAddresses[target] = true;
        } else {
            delete frozenAddresses[target];
        }
        emit AddressFroze(target, freeze);
    }

    function isAddressFrozen(address target) public view returns (bool frozen){
        return frozenAddresses[target];
    }

    function mint(address to, uint256 value) public onlyMinter {
        totalSupply = safeAdd(totalSupply, value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(0x0, to, value);
    }

    function subtractFee(uint value) internal returns (uint newValue) {
        uint feeToTake = calculateFee(value);

        if (feeToTake == 0) return value;

        balances[this] = safeAdd(balances[this], feeToTake);

        return value - feeToTake;
    }

    function withdrawFees(address to) onlyOwner public returns (bool success) {
        return transfer(this, to, balances[this]);
    }

    function burn(uint256 value) public returns (bool success) {
        require(isBurnable);

        if (!canAnyoneBurn && msg.sender != owner) {
            return false;
        }

        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = totalSupply - value;
        return true;
    }
}