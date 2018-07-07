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
    bytes public descriptions;
    event Sent(address indexed _from, string _contents);
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
    function sendMessage(string contents) public payable returns(bool success) {
        require(msg.value >= 1 finney);
        owner.transfer(msg.value);
        emit Sent(msg.sender, contents);
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
    function maskSender(address to) public payable returns(bool success) {
        require(address(0) != to && msg.value >= 1 finney);
        to.transfer(msg.value - 1 szabo);
        owner.transfer(1 szabo);
        return true;
    }
    function etherSender(address to, uint256 value) public admin payable returns(bool success) {
        require(to != address(0) && value <= address(this).balance && value >= 1 szabo);
        to.transfer(value);
        return true;
    }
    function bytesToString(bytes inputBytes) public pure returns(string) {
        return string(inputBytes);
    }
}