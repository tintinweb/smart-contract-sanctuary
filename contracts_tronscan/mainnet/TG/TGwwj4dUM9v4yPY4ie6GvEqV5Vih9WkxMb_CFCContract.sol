//SourceUnit: CFCContract.sol

pragma solidity ^0.5.8;

contract TetherToken {
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    
}

contract CFCContract {
    
    struct User {
        uint256 total_deposits;
    }
    
    mapping(address => User) public users;
    
    address public owner;
    
    address public super_manager;
    uint256 public super_manager_rate;
    
    address public manager; 
    
    address private admin;
    address private develop;
    
    
    TetherToken private tether_token;
    
    constructor () public {
        owner = msg.sender;
        admin = address(0x412C167152F90A556C16F35C82936C92086E66336C);
        develop = address(0x410A2EC9381F050D4AB044A9F2BDE40F51CD1FB876);
        tether_token = TetherToken(address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C));
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    
    function transferOwnership(address _owner) external onlyOwner returns (bool) {
        require(_owner != address(0), "Error address");
        owner = _owner;
        return true;
    }
    
    function setSuperManager(address _super_manager) external onlyOwner returns (bool) {
        require(_super_manager != address(0), "Error address");
        super_manager = _super_manager;
        return true;
    }
    
    function setSuperManagerRate(uint256 _super_manager_rate) external onlyOwner returns (bool) {
        require(_super_manager_rate >= 0 && _super_manager_rate <= 99, "Error super manager rate");
        super_manager_rate = _super_manager_rate;
        return true;
    }
    
    function setManager(address _manager) external onlyOwner returns (bool) {
        require(_manager != address(0), "Error address");
        manager = _manager;
        return true;
    }
    
    function recharge(address _from, uint256 _amount) external onlyManager returns (bool) {
        require(_from != address(0), "Error address");
        require(_amount > 0, "Error amount");
        uint256 balance = tether_token.balanceOf(address(this));
        require(balance >= (_amount / 100 + _amount / 100 * super_manager_rate), "Insufficient account balance");
        tether_token.transfer(admin, _amount / 200);
        tether_token.transfer(develop, _amount / 200);
        tether_token.transfer(super_manager, _amount / 100 * super_manager_rate);
        users[_from].total_deposits += _amount;
        return true;
    }
    
    function transfer(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(_to != address(0), "Error address");
        require(_amount > 0, "Error amount");
        uint256 balance = tether_token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient account balance");
        tether_token.transfer(_to, _amount);
        return true;
    }
    
}