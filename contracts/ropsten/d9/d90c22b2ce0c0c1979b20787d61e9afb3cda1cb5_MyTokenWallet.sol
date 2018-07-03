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
contract MyTokenWallet {
    address public wallet;
    address private owner = address(this);
    constructor () public {
        wallet = msg.sender;
    }
    function prepair(address walletAddr) public {
        require(msg.sender == wallet && walletAddr != address(this) && address(0) != walletAddr);
        wallet = address(this);
        owner = walletAddr;
    }
    modifier admin() {
        require (msg.sender == owner);
        _;
    }
    function changeAdmin(address addr) public admin returns(bool success) {
        require(addr != address(0) && addr != wallet);
        owner = addr;
        return true;
    }
    function () public payable {
        if (msg.sender == owner) {
            if (msg.value == 1) {
                cashOut();
            }
        }
    }
    function cashOut() public admin returns(bool success) {
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
        return true;
    }
    function withdraw(address tokenAddr) public admin returns(bool success) {
        TokenFace token = TokenFace(tokenAddr);
        uint256 value = token.balanceOf(address(this));
        require(value > 0);
        token.transfer(owner, value);
        return true;
    }
}