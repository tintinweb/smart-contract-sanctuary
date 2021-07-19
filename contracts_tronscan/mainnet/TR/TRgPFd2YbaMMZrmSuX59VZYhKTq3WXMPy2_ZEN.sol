//SourceUnit: ZEN.sol

pragma solidity ^0.4.25;

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
        uint256 c = a / b;
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

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract TRC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(uint256 value);
    event Burn(uint256 value);
}

contract ZEN is TRC20, Ownable, Pausable {

    struct sUserInfo {
        uint256 balance;
        bool lock;
        mapping(address => uint256) allowed;
    }
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    mapping(address => sUserInfo) user;

    constructor() public {
        name = "ZEN SOLUTIONS";
        symbol = "ZEN";
        decimals = 6;
        uint256 initialSupply = 20000000000;
        totalSupply_ = initialSupply * 10 ** uint(decimals);
        user[owner].balance = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
 
    }

    function() external payable  {
         revert();
    }
    
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return user[_owner].balance;
    }

    function lockState(address _owner) public view returns (bool) {
        return user[_owner].lock;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return user[_owner].allowed[_spender];
    }
    
    
    
    
    function lock(address _owner) public onlyOwner returns (bool) {
        require(user[_owner].lock == false);
        user[_owner].lock = true;
        return true;
    }

    function unlock(address _owner) public onlyOwner returns (bool) {
        require(user[_owner].lock == true);
        user[_owner].lock = false;
        return true;
    }

    function mint(uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        user[owner].balance = user[owner].balance.add(_amount);
        emit Mint(_amount);
        return true;
    }
    
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= user[owner].balance);
        user[owner].balance = user[owner].balance.sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_value > 0);
        user[msg.sender].allowed[_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal view {
        require(_from != address(0));
        require(_to != address(0));
        require(user[_from].balance >= _value);
        if(_lockCheck) {
            require(user[_from].lock == false);
        }
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(msg.sender, _to, _value, true);

        user[msg.sender].balance = user[msg.sender].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(_from, _to, _value, true);
        require(_value <=  user[_from].allowed[msg.sender]);

        user[_from].balance = user[_from].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        user[_from].allowed[msg.sender] = user[_from].allowed[msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferRestore(address _from, address _to, uint256 _value) public onlyOwner returns (bool) {
        validTransfer(_from, _to, _value, false);
    
        user[_from].balance = user[_from].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
        validTransfer(owner, _to, _value, false);
       
        user[owner].balance = user[owner].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);
       
        emit Transfer(owner, _to, _value);
        return true;
    }

}