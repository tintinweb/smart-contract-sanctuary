pragma solidity ^0.4.24;
contract TokenFace {
    function decimals() public view returns(uint);
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
    function addToken(address _token) public returns(bool);
    function acceptToken(address _token) public view returns(bool);
    function removeToken(address _token) public returns(bool);
    function deposit(address _token) public returns(bool);
    function withdraw(address _token, address _to, uint256 _amount) public returns(bool);
}
contract MyTokenWalletAdmin {
    address public owner;
    address private walletAddress = 0x599fbfD53Bf101839D1eF8222515EC0C0963046A;
    WalletFace private wallet = WalletFace(walletAddress);
    event WalletChanged(address indexed _lastWallet, address indexed _newWallet);
    event ReceiveAndForwarded(address indexed _token, address indexed _from, uint256 _value);
    event Moved(address indexed _token, uint256 _value);
    event OwnerChanged(address indexed _lastOwner, address indexed _newOwner);
    event RequestWithdrawal(address indexed _token, address indexed _to, uint256 _value);
    constructor () public {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
        emit WalletChanged(address(0), walletAddress);
    }
    modifier owned() {
        require(msg.sender == owner);
        _;
    }
    function changeWallet(address newWallet) public owned returns(bool) {
        require(newWallet != address(this) && address(0) != newWallet);
        wallet = WalletFace(newWallet);
        address lastWalletAddress = walletAddress;
        walletAddress = newWallet;
        emit WalletChanged(lastWalletAddress, newWallet);
        return true;
    }
    function transferAdmin(address newAdmin) public owned returns(bool) {
        require(newAdmin != address(0));
        return wallet.changeAdmin(newAdmin);
    }
    function changeOwner(address newOwner) public owned returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        emit OwnerChanged(msg.sender, newOwner);
        return true;
    }
    function receiveEther() public payable returns(bool) {
        require(msg.value >= (1 * 10 ** 9));
        if (!walletAddress.call.gas(25000).value(msg.value)()) {
            walletAddress.transfer(msg.value);
        }
        emit ReceiveAndForwarded(address(0), msg.sender, msg.value);
        return true;
    }
    function () public payable {
        if (msg.value >= 1 && msg.data.length == 0) {
            receiveEther();
        }
    }
    function moveToken(address tokenAddress) public owned returns(bool) {
        require(wallet.acceptToken(tokenAddress));
        TokenFace token = TokenFace(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);
        require(token.approve(walletAddress, amount));
        require(token.allowance(address(this), walletAddress) >= amount);
        require(wallet.deposit(tokenAddress));
        emit Moved(tokenAddress, amount);
        return true;
    }
    function walletTransfer(address tokenAddress, address to, uint value) public owned returns(bool) {
        require(to != address(this));
        require(value > 0);
        value = value * 10 ** 9;
        if (tokenAddress != address(0)) value = value * 10 ** TokenFace(tokenAddress).decimals();
        emit RequestWithdrawal(tokenAddress, to, value);
        return wallet.withdraw(tokenAddress, to, value);
    }
}