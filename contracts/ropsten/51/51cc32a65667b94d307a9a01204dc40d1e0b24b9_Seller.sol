pragma solidity ^0.4.24;
contract TokenHandler {
    function name() public view returns(string);
    function symbol() public view returns(string);
    function decimals() public view returns(uint);
    function totalSupply() public view returns(uint256);
    function balanceOf(address _who) public view returns(uint256);
    function allowance(address _owner, address _spender) public view returns(uint256);
    function approve(address _spender, uint256 _value) public returns(bool);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _owner, address _spender, uint256 _value) public returns(bool);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}
contract WalletHandler {
    function admin() public view returns(address);
    function seller() public view returns(address);
    function acceptToken(address _token) public view returns(bool);
    function updateSeller(address _newSeller) public returns(bool);
    function removeToken(address _token) public returns(bool);
    function withdraw(address _token, address _to, uint256 _value) public returns(bool);
    event SellerChanged(address indexed _lastSeller, address indexed _newSeller);
    event TokenRemoved(address indexed _token, string _name);
    event Deposited(address indexed _token, address indexed _from, uint256 _value);
    event Sent(address indexed _token, address indexed _to, uint256 _value);
}
contract Seller {
    address public owner;
    address private walletAddress = msg.sender;
    address public instantTrade;
    WalletHandler wallet = WalletHandler(walletAddress);
    mapping(address => uint) prices;
    event OwnerChanged(address indexed _lastOwner, address indexed _newOwner);
    event WalletChanged(address indexed _lastWallet, address indexed _newWallet);
    event InstantTradeChanged(address indexed _lastToken, address indexed _newToken);
    event OrderSubmitted(address indexed _token, address indexed _buyer, uint256 _ether);
    event PaymentSent(address indexed _from, address indexed _to, uint256 _amount);
    event PaymentReturned(address indexed _from, address indexed _to, uint256 _amount);
    event RateUpdated(address indexed _token, string _name, uint _lastRate, uint _newRate);
    constructor () public {
        owner = msg.sender;
        instantTrade = address(0);
    }
    function author() internal view returns(bool) {
        if (msg.sender == owner) {
            return true;
        } else {
            return false;
        }
    }
    function updateOwner(address _newOwner) public returns(bool) {
        require(author());
        require(_newOwner != address(0) && address(this) != _newOwner);
        owner = _newOwner;
        emit OwnerChanged(msg.sender, _newOwner);
        return true;
    }
    function updateWallet(address _newWallet) public returns(bool) {
        require(author());
        require(_newWallet != address(0) && address(this) != _newWallet);
        address lastWallet = walletAddress;
        walletAddress = _newWallet;
        wallet = WalletHandler(_newWallet);
        emit WalletChanged(lastWallet, _newWallet);
        return true;
    }
    function updateRate(address _token, uint _newRate) public returns(bool) {
        require(author());
        require(wallet.acceptToken(_token));
        require(_newRate >= 1);
        TokenHandler token = TokenHandler(_token);
        string memory token_name = token.name();
        uint lastRate = prices[_token];
        prices[_token] = _newRate;
        emit RateUpdated(_token, token_name, lastRate, _newRate);
        return true;
    }
    function updateInstantTrade(address _token) public returns(bool) {
        require(author());
        require(wallet.acceptToken(_token));
        require(prices[_token] > 0);
        address lastToken = instantTrade;
        instantTrade = _token;
        emit InstantTradeChanged(lastToken, _token);
        return true;
    }
    function changeSeller(address _newSeller) public returns(bool) {
        return wallet.updateSeller(_newSeller);
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value >= 1 szabo);
        buy(instantTrade);
    }
    function buy(address _token) public payable returns(bool) {
        require(wallet.acceptToken(_token));
        require(prices[_token] > 0);
        uint256 amountETH = msg.value;
        uint256 amount = amountETH * prices[_token];
        TokenHandler token = TokenHandler(_token);
        uint256 value = token.balanceOf(walletAddress);
        uint256 valueETH = 0;
        uint256 payETH = msg.value;
        require(amount >= (1 * 10 ** token.decimals()));
        if (amount <= value) {
            require(wallet.withdraw(_token, msg.sender, amount));
        } else {
            payETH = value / prices[_token];
            valueETH = amountETH - payETH;
            if (valueETH >= (1 * 10 ** 9)) {
                if (!walletAddress.call.gas(50000).value(valueETH)()) walletAddress.transfer(valueETH);
                require(wallet.withdraw(address(0), msg.sender, valueETH));
                emit PaymentReturned(address(this), msg.sender, valueETH);
            }
            require(wallet.withdraw(_token, msg.sender, value));
        }
        if (!owner.call.gas(100000).value(payETH)()) owner.transfer(payETH);
        emit OrderSubmitted(_token, msg.sender, payETH);
        emit PaymentSent(msg.sender, owner, payETH);
        return true;
    }
}