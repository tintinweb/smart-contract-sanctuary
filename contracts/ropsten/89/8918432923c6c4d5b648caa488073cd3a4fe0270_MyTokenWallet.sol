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
    address public creator;
    address private wallet = address(this);
    address public instantToken;
    uint256 public instantPrice;
    constructor () public {
        creator = msg.sender;
        instantToken = address(0);
        instantPrice = 0;
    }
    function prepair(address walletAddr) public {
        require(msg.sender == creator && walletAddr != address(this) && address(0) != walletAddr);
        creator = address(this);
        wallet = walletAddr;
    }
    modifier admin() {
        require (msg.sender == wallet);
        _;
    }
    function () public payable {
        if (msg.sender != wallet && address(0) != instantToken && instantPrice >= 1 && msg.value >= 1 szabo) {
            trade();
        }
    }
    function deposit(address tokenAddr, uint256 value) public returns(bool success) {
        TokenFace token = TokenFace(tokenAddr);
        require(token.totalSupply() > 0 && value > 0 && token.balanceOf(msg.sender) >= value);
        token.transferFrom(msg.sender, creator, value);
        return true;
    }
    function trade() public payable returns(bool success) {
        TokenFace token = TokenFace(instantToken);
        uint256 avail = token.balanceOf(creator);
        uint256 reqValue = msg.value / instantPrice;
        require(msg.value * instantPrice == reqValue);
        require(reqValue <= avail);
        token.transfer(msg.sender, reqValue);
        return true;
    }
    function sell(address tokenAddr, uint256 value) public admin returns(bool success) {
        instantToken = tokenAddr;
        instantPrice = value;
        return true;
    }
    function claim() public admin returns(bool success) {
        require(address(this).balance > 0);
        wallet.transfer(address(this).balance);
        return true;
    }
    function withdraw(address tokenAddr) public admin returns(bool success) {
        TokenFace token = TokenFace(tokenAddr);
        uint256 value = token.balanceOf(address(this));
        require(value > 0);
        token.transfer(wallet, value);
        return true;
    }
}