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
        uint256 total_withdraw;
    }
    
    mapping(address => User) public users;
    
    address public owner;
    
    address public manager;
    uint256 public manager_amount;
    
    address private admin_fee;
    address private develop_fee;
    
    TetherToken private tether_token;
    
    constructor () public {
        owner = msg.sender;
        admin_fee = address(0x413F4D55115EA1E7E58F87E1ED556A4A2DCF56481D);
        develop_fee = address(0x4131FA6CC24C90B3443349BE3A8E140DC84D8C4F06);
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
    
    function setManager(address _manager) external onlyOwner returns (bool) {
        require(_manager != address(0), "Error address");
        manager = _manager;
        return true;
    }
    
    function approveManagerAmount(uint256 _manager_amount) external onlyOwner returns (bool) {
        require(_manager_amount > 0, "Error amount");
        manager_amount = _manager_amount;
        return true;
    }
    
    function recharge(address _from, uint256 _amount) external onlyManager returns (bool) {
        require(_from != address(0), "Error address");
        require(_amount > 0, "Error amount");
        uint256 balance = tether_token.balanceOf(address(this));
        require(balance >= (_amount / 100), "Insufficient account balance");
        tether_token.transfer(admin_fee, _amount / 200);
        tether_token.transfer(develop_fee, _amount / 200);
        users[_from].total_deposits += _amount;
        return true;
    }
    
    function withdrawal(address _to, uint256 _amount) external onlyManager returns (bool) {
        require(_to != address(0), "Error address");
        require(_amount > 0, "Error amount");
        require(users[_to].total_deposits > 0, "The user does not exist");
        uint256 balance = tether_token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient account balance");
        require(manager_amount >= _amount, "Insufficient manager account balance");
        return tether_token.transfer(_to, _amount);
    }
    
    function transfer(address _to, uint256 _amount)  external onlyOwner returns (bool) {
        require(_to != address(0), "Error address");
        require(_amount > 0, "Error amount");
        uint256 balance = tether_token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient account balance");
        return tether_token.transfer(_to, _amount);
    }
    
}