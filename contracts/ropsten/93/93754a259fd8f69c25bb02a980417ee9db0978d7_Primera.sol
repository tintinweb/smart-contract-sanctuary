pragma solidity ^0.5.0;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function allowance(address tokenOwner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
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
contract Primera is Ownable {
    constructor(address _owner) public {
        owner = _owner;
    }
    function () external payable {}
    function approve(address token, address spender, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && spender != address(0) && address(this) != spender);
        require(value > 0 && value <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(spender, value)) revert();
        return true;
    }
    function call(address contractAddress, uint256 value, uint256 gaslimit, bytes memory data) public onlyOwner returns(bool) {
        require(contractAddress != address(0) && address(this) != contractAddress);
        require(value >= 0 && value <= address(this).balance);
        if (gaslimit < 25000) gaslimit = 250000;
        address payable dest = address(uint160(contractAddress));
        (bool success,) = dest.call.gas(gaslimit).value(value)(data);
        if (!success) revert();
        return true;
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function send(address to, uint256 value) public onlyOwner returns(bool) {
        require(to != address(0) && address(this) != to);
        require(value > 0 && value <= address(this).balance);
        address payable dest = address(uint160(to));
        (bool success,) = dest.call.gas(250000).value(value)("");
        if (!success) dest.transfer(value);
        return true;
    }
    function transfer(address token, address to, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && to != address(0) && address(this) != to);
        require(value > 0 && value <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).transfer(to, value)) revert();
        return true;
    }
    function transferFrom(address token, address from, address to, uint256 value) public onlyOwner returns(bool) {
        require(token != address(0) && to != address(0));
        require(from != address(0) && address(this) != from);
        require(value > 0 && from != to);
        ERC20 tokenLoad = ERC20(token);
        (uint256 remain, uint256 available) = (tokenLoad.allowance(from, address(this)), tokenLoad.balanceOf(from));
        if (remain < available) remain = available;
        require(value <= remain);
        if (!tokenLoad.transferFrom(from, to, value)) revert();
        return true;
    }
}