pragma solidity ^0.5.2;
contract ERC20 {
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
}
contract ERC223 {
    function transfer(address to, uint amount, bytes memory extraData) public returns(bool);
}
contract Vault {
    address payable owner;
    address admin;
    event AdminshipTransferred(address indexed _newAdmin, address indexed _prevAdmin);
    event OwnershipTransferred(address indexed _newOwner, address indexed _prevOwner);
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
    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        emit AdminshipTransferred(newAdmin, msg.sender);
    }
    function changeOwner(address newOwner) public onlyAdmin {
        require(newOwner != address(0) && address(this) != newOwner);
        address oldOwner = owner;
        owner = address(uint160(newOwner));
        emit OwnershipTransferred(newOwner, oldOwner);
    }
    function () external payable {
        if (msg.value > 0) deposit();
    }
    function depositERC20(address token, address from, uint amount) public {
        uint length;
        assembly { length := extcodesize(token) }
        require(length > 0 && amount > 0);
        if (!ERC20(token).transferFrom(from, address(this), amount))
        revert();
        emit Deposit(from, msg.sender, amount, bytes(""));
    }
    function tokenFallback(address from, uint amount, bytes memory extraData) public {
        emit Deposit(from, msg.sender, amount, extraData);
    }
    function deposit() public payable {
        require(msg.value > 1);
        emit Deposit(msg.sender, address(0), msg.value, bytes(""));
    }
    function withdraw(address token, uint amount) public onlyAdmin {
        require(amount > 0);
        if (address(0) == token) {
            owner.transfer(amount);
        } else {
            uint length;
            assembly { length := extcodesize(token) }
            require(length > 0);
            if (!ERC20(token).transfer(owner, amount))
            revert();
        }
        emit Withdraw(owner, token, amount, bytes(""));
    }
}