pragma solidity ^0.4.24;
contract TokenFace {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract MyLocker {
    address public owner;
    address private microPay;
    bytes public descriptions;
    event OrderSubmitted(address indexed _from, string _contents);
    constructor() public {
        owner = msg.sender;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeAdmin(address addr) public admin returns(bool success) {
        require(addr != address(0) && address(this) != addr);
        owner = addr;
        return true;
    }
    function changeMicroPay(address addr) public admin returns(bool success) {
        require(addr != address(this) && address(0) != addr);
        microPay = addr;
        return true;
    }
    function () public payable {
    }
    function claim(address tokenAddress) public admin returns(bool success) {
        if (tokenAddress == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            TokenFace(tokenAddress).transfer(msg.sender, TokenFace(tokenAddress).balanceOf(address(this)));
        }
        return true;
    }
    function submitOrder(bytes contents) public payable returns(bool success) {
        require(contents.length > 0 && contents.length < 1000000001);
        require(contents.length <= msg.value);
        microPay.transfer(msg.value);
        emit OrderSubmitted(msg.sender, string(contents));
        return true;
    }
    function updateDescription(bytes hexed) public admin returns(bool success) {
        require(hexed.length > 0);
        descriptions = hexed;
        return true;
    }
    function getDescription() public view returns(string) {
        return string(descriptions);
    }
}