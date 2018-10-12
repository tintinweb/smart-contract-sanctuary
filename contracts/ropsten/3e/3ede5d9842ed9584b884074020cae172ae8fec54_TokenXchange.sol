pragma solidity ^0.4.25;
contract Factory {
    function create(address walletAddress, address tokenAddress) public returns(address);
}
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract TokenXchange {
    address public owner;
    address creatorAddress;
    mapping(address => addressInfo) public tokenInfo;
    struct addressInfo {
        address seller;
        uint rate;
    }
    event Sent(address indexed _from, address indexed _to, address indexed _token, uint _value);
    event SellerActived(address indexed _token, address indexed _seller);
    constructor(address _factory) public {
        owner = msg.sender;
        creatorAddress = _factory;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function sellToken(address tokenAddress, uint tokenRate) public admin returns(bool) {
        require(tokenAddress != address(0));
        address a = Factory(creatorAddress).create(address(this), tokenAddress);
        tokenInfo[tokenAddress].seller = a;
        tokenInfo[tokenAddress].rate = tokenRate;
        emit SellerActived(tokenAddress, a);
        return true;
    }
    function updateTokenRate(address tokenAddress, uint newRate) public admin returns(bool) {
        require(tokenInfo[tokenAddress].seller != address(0));
        require(newRate > 0);
        tokenInfo[tokenAddress].rate = newRate;
        return true;
    }
    function updateOwner(address newOwner) public admin returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function() public payable {
        if (msg.data.length == 0 && msg.value > 0) {
            owner.transfer(msg.value);
            emit Sent(msg.sender, owner, address(0), msg.value);
        }
    }
    function buyToken(address buyer, address token) public payable returns(bool) {
        require(msg.sender == tokenInfo[token].seller);
        require(tokenInfo[token].rate > 0 && msg.value > 0);
        ERC20 a = ERC20(token);
        uint b = a.balanceOf(address(this));
        uint c = msg.value * tokenInfo[token].rate;
        require(c <= b);
        if (!a.transfer(buyer, c)) revert();
        owner.transfer(msg.value);
        emit Sent(address(this), buyer, token, c);
        emit Sent(buyer, owner, address(0), msg.value);
        return true;
    }
    function getBalance(address token) internal view returns(uint) {
        if (token == address(0)) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function withdraw(address token) public admin returns(bool) {
        require(token != address(0));
        uint value = getBalance(token);
        require(value > 0);
        if (!ERC20(token).transfer(owner, value)) revert();
        emit Sent(address(this), owner, token, value);
        return true;
    }
}