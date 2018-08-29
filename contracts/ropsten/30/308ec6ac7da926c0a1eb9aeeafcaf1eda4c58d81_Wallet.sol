pragma solidity ^0.4.24;
contract Token {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
}
contract WalletForkFactory {
    function forkThis() public returns(address);
}
contract WalletForkFace {
    function sendToken(address tokenAddress, address to, uint amount, uint gasLimit) public returns(bool);
    function sendEther(address to, uint amount, uint gasLimit) public returns(bool);
    function changeUnforked(address newUnforked) public returns(bool);
}
contract Wallet {
    address admin;
    address[] forkLists;
    address forkFactory;
    mapping(address => uint) _tokenGas;
    mapping(address => mapping(address => uint)) _balances;
    uint public defaultGas;
    event WalletForked(address indexed forkAddress, address indexed mainAddress);
    event Collected(address indexed from, address indexed tokenAddress, uint amount, uint gasUsed);
    event Sent(address indexed to, address indexed tokenAddress, uint amount, uint gasUsed);
    event MainWalletMoved(address indexed previousWallet, address indexed newWallet);
    constructor(address _admin, address _forkFactory, uint _defaultGas) public {
        admin = _admin;
        forkFactory = _forkFactory;
        defaultGas = _defaultGas;
    }
    function () public payable {}
    function subWallets() public view returns(address[]) {
        return forkLists;
    }
    function updateBalances(address tokenAddress) public returns(bool) {
        require(msg.sender == admin && tokenAddress != address(0));
        uint a = 0;
        while (a <= forkLists.length) {
            _balances[forkLists[a]][tokenAddress] = Token(tokenAddress).balanceOf(forkLists[a]);
            a++;
        }
        return true;
    }
    function updateToken(address tokenAddress, uint setGasTo) public returns(bool) {
        require(msg.sender == admin && tokenAddress != address(0));
        require(setGasTo >= defaultGas);
        _tokenGas[tokenAddress] = setGasTo;
        updateBalances(tokenAddress);
        return true;
    }
    function updateWallet(address newWallet) public returns(bool) {
        require(msg.sender == admin);
        uint b = 0;
        while (b < forkLists.length) {
            if (!WalletForkFace(forkLists[b]).changeUnforked(newWallet)) {
                break;
            } else {
                emit MainWalletMoved(address(this), newWallet);
            }
            b++;
        }
        return true;
    }
    function updateFactory(address newFactory) public returns(bool) {
        require(msg.sender == admin);
        forkFactory = newFactory;
        return true;
    }
    function updateAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == admin);
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function collectToken(address tokenAddress) public returns(bool) {
        require(msg.sender == admin && address(0) != tokenAddress);
        uint c = 0;
        uint d = 0;
        if (_tokenGas[tokenAddress] == 0) _tokenGas[tokenAddress] = defaultGas;
        while (c < forkLists.length) {
            if (_balances[forkLists[c]][tokenAddress] > 0) {
                d = _balances[forkLists[c]][tokenAddress];
                if (!WalletForkFace(forkLists[c]).sendToken(tokenAddress, address(this), d, _tokenGas[tokenAddress])) {
                    break;
                } else {
                    _balances[forkLists[c]][tokenAddress] = 0;
                    emit Collected(forkLists[c], tokenAddress, d, _tokenGas[tokenAddress]);
                }
                c++;
            }
        }
        return true;
    }
    function collectEther() public returns(bool) {
        require(msg.sender == admin);
        uint e = 0;
        uint f = 0;
        while (e < forkLists.length) {
            if (forkLists[e].balance > 0) {
                f = forkLists[e].balance;
                if (!WalletForkFace(forkLists[e]).sendEther(address(this), f, defaultGas)) {
                    break;
                } else {
                    emit Collected(forkLists[e], address(0), f, defaultGas);
                }
            }
            e++;
        }
        return true;
    }
    function sendTo(address dest, address tokenAddress, uint amount, bytes msgData) public returns(bool) {
        require(msg.sender == admin);
        require(dest != address(0) && address(this) != dest);
        uint maxAmount = address(this).balance;
        require(amount > 0);
        uint g = defaultGas;
        if (tokenAddress == address(0)) {
            require(amount <= maxAmount);
            if (!dest.call.gas(g).value(amount)(msgData)) dest.transfer(amount);
        } else {
            Token x = Token(tokenAddress);
            maxAmount = x.balanceOf(address(this));
            require(amount <= maxAmount);
            g = gasleft();
            if (!x.transfer(dest, amount)) revert();
            g -= gasleft();
        }
        emit Sent(dest, tokenAddress, amount, g);
        return true;
    }
    function forkMe() public returns(address) {
        require(msg.sender == admin);
        address n = WalletForkFactory(forkFactory).forkThis();
        forkLists.push(n);
        emit WalletForked(n, address(this));
        return n;
    }
}