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
contract Wallet {
    address public admin;
    constructor () public {
        admin = msg.sender;
    }
    function changeAdmin(address newAdmin) public returns(bool success) {
        require(msg.sender == admin);
        require(newAdmin != address(this) && address(0) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function () public payable {
        revert();
    }
    function depositEther() public payable returns(bool) {
        require(msg.value >= 1);
        return true;
    }
    function depositToken(address tokenAddress, uint256 amount) public returns(bool) {
        require(tokenAddress != address(0));
        require(amount > 0);
        TokenFace token = TokenFace(tokenAddress);
        uint256 approvedValue = token.allowance(msg.sender, address(this));
        require(amount <= approvedValue);
        require(amount <= token.balanceOf(msg.sender));
        require(token.transferFrom(msg.sender, address(this), amount));
        return true;
    }
    function sendEther(address to, uint256 amount) public returns(bool) {
        require(msg.sender == admin);
        require(to != address(0) && address(this) != to);
        require(amount >= 1 && amount <= address(this).balance);
        to.transfer(amount);
        return true;
    }
    function sendToken(address to, uint256 amount, address tokenAddress) public returns(bool) {
        require(msg.sender == admin && tokenAddress != address(0) && to != address(0) && address(this) != to);
        TokenFace token = TokenFace(tokenAddress);
        require(amount >= 1 && amount <= token.balanceOf(address(this)));
        require(token.transfer(to, amount));
        return true;
    }
}