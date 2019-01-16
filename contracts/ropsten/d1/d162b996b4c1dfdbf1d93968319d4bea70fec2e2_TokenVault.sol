pragma solidity ^0.5.2;
contract ERC20 {
    function totalSupply() public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
}
contract ERC223 {
    function transfer(address to, uint amount, bytes memory extraData) public returns(bool);
}
contract TokenVault {
    address payable owner;
    address admin;
    event Deposit(address indexed _from, address indexed _token, uint256 _amount, bytes _data);
    event Withdraw(address indexed _recipient, address indexed _token, uint256 _amount, bytes _data);
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier isToken(address addr) {
        uint length;
        assembly { length := extcodesize(addr) }
        require(length > 0);
        require(ERC20(addr).totalSupply() > 0);
        _;
    }
    function setting(address newAdmin, address newOwner) public onlyAdmin {
        if (admin != newAdmin) {
            require(newAdmin != address(0) && address(this) != newAdmin);
            admin = newAdmin;
        }
        if (owner != newOwner) {
            require(newOwner != address(0) && address(this) != newOwner);
            owner = address(uint160(newOwner));
        }
    }
    function () external payable {
        if (msg.value > 0) owner.transfer(msg.value);
    }
    function deposit(address token, address from, uint amount) public isToken(token) {
        require(amount > 0);
        if (!ERC20(token).transferFrom(from, address(this), amount)) revert();
        emit Deposit(from, msg.sender, amount, bytes(""));
    }
    function tokenFallback(address from, uint amount, bytes memory extraData) public isToken(msg.sender) {
        emit Deposit(from, msg.sender, amount, extraData);
    }
    function withdraw(address token, uint amount) public onlyAdmin isToken(token) {
        require(amount > 0);
        if (!ERC20(token).transfer(owner, amount)) revert();
        emit Withdraw(owner, token, amount, bytes(""));
    }
}