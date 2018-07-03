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
    address public instantToken;
    uint256 public instantPrice;
    constructor () public {
        wallet = msg.sender;
        instantToken = address(0);
        instantPrice = 0;
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
            if (msg.value == 2) {
                unSell();
            }
            if (msg.value >= 10 finney) {
                etherLock();
            }
            if (msg.value > 100 && msg.value < 1 szabo) {
                trade();
            }
        } else {
            if (msg.value > 0) {
                trade();
            }
        }
    }
    function etherLock() public payable returns(bool success) {
        require(msg.value > 0);
        return true;
    }
    function deposit(address tokenAddr, uint256 value) public returns(bool success) {
        TokenFace token = TokenFace(tokenAddr);
        require(token.totalSupply() > 0 && value > 0);
        assert(token.approve(wallet, value));
        assert(token.transferFrom(msg.sender, wallet, value));
        return true;
    }
    function trade() public payable returns(bool success) {
        require(msg.value > 0 && instantPrice > 0);
        TokenFace token = TokenFace(instantToken);
        uint256 avail = token.balanceOf(wallet);
        uint256 reqValue = msg.value / instantPrice;
        require(msg.value * instantPrice == reqValue);
        require(reqValue <= avail);
        assert(token.transfer(msg.sender, reqValue));
        return true;
    }
    function sell(address tokenAddr, uint256 value) public admin returns(bool success) {
        require((address(0) != tokenAddr) && (value > 0));
        instantToken = tokenAddr;
        instantPrice = value;
        return true;
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
    function unSell() public admin returns(bool success) {
        instantToken = address(0);
        instantPrice = 0;
        return true;
    }
}