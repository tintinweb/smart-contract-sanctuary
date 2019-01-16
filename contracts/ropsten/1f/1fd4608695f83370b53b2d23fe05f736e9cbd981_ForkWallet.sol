pragma solidity ^0.5.0;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function allowance(address tokenOwner, address tokenSpender) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function approve(address tokenSpender, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Wallet {
    function setOwner(address _owner) public returns(bool);
    function receive() public payable returns(bool);
    function send(address to, uint256 value, uint256 gaslimit, bytes memory data) public returns(bool);
    function transfer(address token, address to, uint256 value) public returns(bool);
    function approve(address token, address spender, uint256 value) public returns(bool);
    function transferFrom(address token, address from, address to, uint256 value) public returns(bool);
}
contract Ownable {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _owner) public onlyOwner returns(bool) {
        require(_owner != address(0) && address(this) != _owner);
        owner = _owner;
        return true;
    }
}
contract Forkable is Wallet, Ownable {
    function approve(address token, address spender, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && spender != address(0) && address(this) != spender);
        require(value > 0 && value <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(spender, value)) revert();
        return true;
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function send(address to, uint256 value, uint256 gaslimit, bytes memory data) public onlyOwner returns(bool) {
        require(to != address(0) && address(this) != to);
        require(value >= 0 && value <= address(this).balance);
        address payable dest = address(uint160(to));
        if (gaslimit > 4700000 && gaslimit < 25000) gaslimit = 250000;
        if (!Wallet(dest).receive.value(value)()) {
            (bool success,) = dest.call.gas(gaslimit).value(value)(data);
            if (!success) dest.transfer(value);
        }
        return true;
    }
    function transfer(address token, address to, uint256 value) public onlyOwner returns(bool) {
        require(address(0) != token && to != address(0) && address(this) != to);
        require(value > 0 && value <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).transfer(to, value)) revert();
        return true;
    }
    function transferFrom(address token, address from, address to, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && address(0) != to);
        require(from != address(0) && address(this) != from);
        require(value > 0 && value <= ERC20(token).allowance(from, address(this)));
        if (!ERC20(token).transferFrom(from, to, value)) revert();
        return true;
    }
}
contract Mainable is Forkable {
    mapping(address => bool) isFork;
    address[] public Forks;
    function fork() public onlyOwner returns(bool) {
        address newFork = address(new ForkWallet(address(this)));
        isFork[newFork] = true;
        Forks.push(newFork);
        return true;
    }
    function forkApprove(address forkAddress, address token, address spender, uint256 value) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        if (!Wallet(forkAddress).approve(token, spender, value)) revert();
        return true;
    }
    function forkReceive(address forkAddress, uint256 value) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        require(value > 0 && value <= address(this).balance);
        if (!Wallet(forkAddress).receive.value(value)()) revert();
        return true;
    }
    function forkSend(address forkAddress, address to, uint256 value, uint256 gaslimit, bytes memory data) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        if (!Wallet(forkAddress).send(to, value, gaslimit, data)) revert();
        return true;
    }
    function forkTransfer(address forkAddress, address token, address to, uint256 value) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        if (!Wallet(forkAddress).transfer(token, to, value)) revert();
        return true;
    }
    function forkTransferFrom(address forkAddress, address token, address from, address to, uint256 value) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        if (!Wallet(forkAddress).transferFrom(token, from, to, value)) revert();
        return true;
    }
    function forkUpgrade(address forkAddress, address admin) public onlyOwner returns(bool) {
        require(isFork[forkAddress]);
        if (!Wallet(forkAddress).setOwner(admin)) revert();
        return true;
    }
}
contract ForkWallet is Forkable {
    constructor(address _owner) public {
        owner = _owner;
    }
    function() external payable {}
}
contract MainWallet is Mainable {
    constructor(address _owner) public {
        owner = _owner;
    }
    function() external payable {}
}