pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function allowance(address tokenOwner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract PrimeraToolkit {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }
    function isAccepted(address addr) internal view returns(bool) {
        if (addr != address(0) && addr != address(this)) return true;
        else return false;
    }
    function balanceOf(address token, address tokenOwner) internal view returns(uint256) {
        if (address(0) == token) return tokenOwner.balance;
        else return ERC20(token).balanceOf(tokenOwner);
    }
}
contract PrimeraStart {
    address owner;
    address admin;
    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }
}
contract PrimeraGranted is PrimeraStart, PrimeraToolkit {
    modifier granted() {
        if (msg.sender != owner && msg.sender != admin)
        revert();
        _;
    }
    function updateGranted(address newOwner, address newAdmin) public granted returns(bool) {
        require(isAccepted(newOwner) && isAccepted(newAdmin));
        owner = newOwner;
        admin = newAdmin;
        return true;
    }
    function transfer(address token, address to, uint256 value) public granted returns(bool) {
        require(isAccepted(to));
        require(value > 0 && value <= balanceOf(token, address(this)));
        address payable dest = address(uint160(to));
        if (address(0) == token) {
            if (isContract(dest)) {
                (bool success,) = dest.call.gas(100000).value(value)("");
                if (!success)
                dest.transfer(value);
            } else {
                dest.transfer(value);
            }
        } else {
            if (!isContract(token)) revert();
            if (!ERC20(token).transfer(dest, value))
            revert();
        }
        return true;
    }
    function send(address to, uint256 value, uint gaslimit, bytes memory data) public granted returns(bool) {
        require(isContract(to) && isAccepted(to) && value <= address(this).balance);
        if (gaslimit < 50000) gaslimit = 50000;
        (bool success,) = address(uint160(to)).call.gas(gaslimit).value(value)(data);
        if (!success) revert();
        return true;
    }
    function approve(address token, address spender, uint256 value) public granted returns(bool) {
        require(isContract(token) && isAccepted(spender));
        require(value > 0 && value <= balanceOf(token, address(this)));
        if (!ERC20(token).approve(spender, value))
        revert();
        return true;
    }
    function transferFrom(address token, address from, address to, uint256 value) public granted returns(bool) {
        require(isContract(token) && isAccepted(from) && address(0) != to);
        require(value > 0 && value <= ERC20(token).allowance(from, address(this)));
        if (!ERC20(token).transferFrom(from, to, value))
        revert();
        return true;
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
}
contract PrimeraFactory is PrimeraGranted {
    constructor(address _owner, address _admin) public {
        owner = _owner;
        admin = _admin;
    }
    function newPrimera(address ownerAddress, address adminAddress) public returns(address) {
        require(isAccepted(ownerAddress) && isAccepted(adminAddress));
        return address(new Primera(ownerAddress, adminAddress));
    }
    function() external payable {}
}
contract Primera is PrimeraGranted {
    constructor(address _owner, address _admin) public {
        owner = _owner;
        admin = _admin;
    }
    function() external payable {}
}