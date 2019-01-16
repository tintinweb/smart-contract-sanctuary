pragma solidity ^0.5.0;
contract Primera {
    function setOwner(address _owner) public returns(bool);
    function call(address contractAddress, uint256 value, uint256 gaslimit, bytes memory data) public returns(bool);
    function approve(address token, address spender, uint256 value) public returns(bool);
    function receive() public payable returns(bool);
    function send(address to, uint256 value) public returns(bool);
    function transfer(address token, address to, uint256 value) public returns(bool);
    function transferFrom(address token, address from, address to, uint256 value) public returns(bool);
}
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract PrimeraProxy {
    address owner;
    Primera account;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address _owner) public onlyOwner {
        require(_owner != address(0) && address(this) != _owner);
        owner = _owner;
    }
    function changeAccount(address _account) public onlyOwner {
        require(_account != address(0) && address(this) != _account);
        account = Primera(_account);
    }
    function () external payable {
        if (msg.value > 0) receive();
    }
    function move(address token) public onlyOwner {
        require(token != address(0));
        ERC20 a = ERC20(token);
        uint256 b = a.balanceOf(address(this));
        require(b > 0);
        if (!a.transfer(address(account), b))
        revert();
    }
    function setOwner(address _owner) public onlyOwner {
        if (!account.setOwner(_owner)) revert();
    }
    function approve(address token, address spender, uint256 value) public onlyOwner {
        if (!account.approve(token, spender, value)) revert();
    }
    function call(address contractAddress, uint256 value, uint256 gaslimit, bytes memory data) public onlyOwner {
        if (!account.call(contractAddress, value, gaslimit, data)) revert();
    }
    function receive() public payable {
        if (!account.receive.value(msg.value)()) revert();
    }
    function send(address to, uint256 value) public onlyOwner {
        if (!account.send(to, value)) revert();
    }
    function transfer(address token, address to, uint256 value) public onlyOwner {
        if (!account.transfer(token, to, value)) revert();
    }
    function transferFrom(address token, address from, address to, uint256 value) public onlyOwner {
        if (!account.transferFrom(token, from, to, value)) revert();
    }
}