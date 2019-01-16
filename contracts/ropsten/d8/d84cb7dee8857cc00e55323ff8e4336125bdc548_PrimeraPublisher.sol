pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract PrimeraBasic {
    address public owner;
    event Published(address indexed PrimeraAddress, address indexed PrimeraOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier granted() {
        require(msg.sender == owner);
        _;
    }
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
    function setOwner(address newOwner) public granted returns(bool) {
        require(isAccepted(newOwner));
        owner = newOwner;
        return true;
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function send(address dest, uint256 value, uint gaslimit, bytes memory data) public granted returns(bool) {
        require(isAccepted(dest) && isContract(dest));
        require(value <= address(0).balance);
        if (gaslimit < 50000) gaslimit = 50000;
        (bool success,) = address(uint160(dest)).call.gas(gaslimit).value(value)(data);
        if (!success) revert();
        return true;
    }
    function transfer(address token, address dest, uint256 value) public granted returns(bool) {
        require(isAccepted(dest));
        require(value > 0 && value <= balanceOf(token, address(this)));
        if (address(0) == token) {
            require(!isContract(dest));
            address(uint160(dest)).transfer(value);
        } else {
            require(isContract(token));
            if (!ERC20(token).transfer(dest, value)) revert();
        }
        return true;
    }
}
contract PrimeraLight is PrimeraBasic {
    constructor(address _owner) public {
        owner = _owner;
        emit Published(address(this), _owner);
    }
    function () external payable {}
}
contract PrimeraPublisher is PrimeraBasic {
    address[] public Addresses;
    mapping(address => address) public Owners;
    uint public PublishCounts;
    constructor(address _owner) public {
        owner = _owner;
        emit Published(address(this), _owner);
    }
    function () external payable {}
    function publish(address ownerAddress) public returns(address) {
        require(isAccepted(ownerAddress));
        address newPrimera = address(new PrimeraLight(ownerAddress));
        Addresses.push(newPrimera);
        Owners[newPrimera] = ownerAddress;
        PublishCounts += 1;
        emit Published(newPrimera, ownerAddress);
        return newPrimera;
    }
}