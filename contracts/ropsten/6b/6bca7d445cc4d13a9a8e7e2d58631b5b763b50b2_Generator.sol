pragma solidity ^0.5.2;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
}
contract ERC223 {
    function transfer(address to, uint amount, bytes memory extraData) public returns(bool);
}
contract Face {
    function receive() public payable returns(bool);
}
contract Gateway is Face {
    address owner;
    constructor(address _owner) public {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
    }
    function () external payable {
        if (msg.value > 0) receive();
    }
    function tokenFallback(address from, uint amount, bytes memory extraData) public {
        bytes memory receiveData;
        address sender;
        ERC20(msg.sender).transfer(owner, amount);
        sender = from;
        receiveData = extraData;
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        address(uint160(owner)).transfer(msg.value);
        return true;
        
    }
    function receiveERC20(address token, uint amount) public {
        require(token != address(0) && amount > 0);
        ERC20(token).transferFrom(msg.sender, address(this), amount);
    }
    function claim(address token) public onlyOwner {
        require(address(0) != token);
        uint amount = ERC20(token).balanceOf(address(this));
        if (amount > 0) ERC20(token).transfer(owner, amount);
    }
}
contract Generator {
    function generate() public payable returns(address) {
        Face x = new Gateway(msg.sender);
        if (msg.value > 0) x.receive.value(msg.value)();
        return address(x);
    }
}