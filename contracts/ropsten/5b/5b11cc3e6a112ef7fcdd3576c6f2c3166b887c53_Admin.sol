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
contract WalletFace {
    function admin() public view returns(address);
    function changeAdmin(address _newAdmin) public returns(bool);
    function depositToken(address _token, uint256 _value) public returns(bool);
    function sendEther(address _to, uint256 _uint256) public returns(bool);
    function sendToken(address _to, uint256 _value, address _token) public returns(bool);
}
contract Admin {
    address public owner;
    address private walletAddress;
    WalletFace private wallet;
    bytes4 dEther = 0x98ea5fca;
    constructor () public {
        owner = msg.sender;
    }
    modifier owned() {
        require(msg.sender == owner);
        _;
    }
    function changeWallet(address newWallet) public owned returns(bool) {
        require(newWallet != address(this) && address(0) != newWallet);
        wallet = WalletFace(newWallet);
        walletAddress = newWallet;
        return true;
    }
    function transferAdmin(address newAdmin) public owned returns(bool) {
        require(newAdmin != address(0));
        return wallet.changeAdmin(newAdmin);
    }
    function changeOwner(address newOwner) public owned returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function receiveEther() public payable returns(bool) {
        require(msg.value > 0);
        if (!walletAddress.call.gas(25000).value(msg.value)(dEther)) {
            walletAddress.transfer(msg.value);
        }
        return true;
    }
    function () public payable {
        if (msg.value >= 1 && msg.data.length == 0) {
            receiveEther();
        }
    }
    function moveToken(address tokenAddress) public owned returns(bool) {
        require(tokenAddress != address(0));
        TokenFace token = TokenFace(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);
        require(token.approve(walletAddress, amount));
        require(token.allowance(address(this), walletAddress) >= amount);
        return wallet.depositToken(tokenAddress, amount);
    }
    function transferEther(address to, uint256 value) public owned returns(bool) {
        require(to != address(this));
        require(value > 0);
        return wallet.sendEther(to, value);
    }
    function transferToken(address to, uint256 value, address tokenAddress) public owned returns(bool) {
        require(value > 0);
        return wallet.sendToken(to, value, tokenAddress);
    }
}