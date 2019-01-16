pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function allowance(address tokenOwner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Core {
    address payable owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address payable newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function balanceOf(address token, address who) internal view returns(uint256) {
        if (address(0) == token) return who.balance;
        else return ERC20(token).balanceOf(who);
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function approve(address token, address spender, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && token != spender);
        require(spender != address(0) && address(this) != spender);
        require(value > 0 && value <= balanceOf(token, address(this)));
        if (!ERC20(token).approve(spender, value)) revert();
        return true;
    }
    function transfer(address token, address payable to, uint256 value) public onlyOwner returns(bool) {
        require(to != address(0) && to != address(this) && to != token);
        require(value > 0 && value <= balanceOf(token, address(this)));
        if (address(0) == token) {
            (bool success,) = to.call.gas(250000).value(value)("");
            if (!success) to.transfer(value);
        } else {
            if (!ERC20(token).transfer(to, value))
            revert();
        }
        return true;
    }
    function transferFrom(address token, address from, address to, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && from != address(this) && address(0) != from);
        require(token != from && to != address(0) && address(this) != to);
        require(to != from && to != token);
        require(value > 0 && value <= ERC20(token).allowance(from, address(this)));
        require(value <= balanceOf(token, address(this)));
        if (!ERC20(token).transferFrom(from, to, value))
        revert();
        return true;
    }
}
contract Fork is Core {
    constructor(address _owner) public {
        owner = address(uint160(_owner));
    }
    function () external payable {}
}
contract Forkable is Core {
    address[] public Addresses;
    mapping(address => Status) public Info;
    struct Status {
        uint Id;
        bool active;
    }
    constructor(address _owner) public {
        owner = address(uint160(_owner));
        Addresses.push(address(this));
        Info[address(this)].Id = 0;
        Info[address(this)].active = true;
    }
    function () external payable {}
    function fork() public onlyOwner returns(address) {
        address n = address(new Fork(address(this)));
        Info[n].active = true;
        Info[n].Id = Addresses.length;
        Addresses.push(n);
        return n;
    }
    function setMain(address payable newMain, address forkAddress) public onlyOwner returns(bool) {
        require(newMain != address(0));
        require(Info[newMain].Id < 1 && Info[forkAddress].active);
        if (!Core(forkAddress).setOwner(newMain)) revert();
        Info[forkAddress].active = false;
        return true;
    }
    function send(address forkAddress, address token, address payable to, uint256 value) public onlyOwner returns(bool) {
        require(Info[forkAddress].active);
        if (!Core(forkAddress).transfer(token, to, value)) revert();
        return true;
    }
    function authorize(address forkAddress, address token, address spender, uint256 value) public onlyOwner returns(bool) {
        require(Info[forkAddress].active);
        if (!Core(forkAddress).approve(token, spender, value)) revert();
        return true;
    }
    function grab(address forkAddress, address token, address from, address to, uint256 value) public onlyOwner returns(bool) {
        require(Info[forkAddress].active);
        if (!Core(forkAddress).transferFrom(token, from, to, value)) revert();
        return true;
    }
}