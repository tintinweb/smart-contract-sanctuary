pragma solidity ^0.4.24;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
}
contract SubWallet {
    address _mainWallet;
    constructor(address _mainAddress) public {
        _mainWallet = _mainAddress;
    }
    function () public payable {}
    function transferTo(address to, address token, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == _mainWallet);
        require(to != address(0) && address(this) != to);
        if (token == address(0)) {
            if (!to.call.gas(gasLimit).value(amount)()) to.transfer(amount);
        } else {
            bytes memory d = abi.encodePacked(bytes16(0xa9059cbb), to, amount);
            if (!token.call.gas(gasLimit).value(0)(d)) return false;
        }
        return true;
    }
    function setMain(address newMainAddress) public returns(bool) {
        require(msg.sender == _mainWallet);
        if (newMainAddress != address(0) && address(this) != newMainAddress) return false;
        _mainWallet = newMainAddress;
        return true;
    }
}
contract ETHMasker {
    address public beneficiary;
    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
    }
    function () public payable {
        require(msg.data.length == 0);
        beneficiary.transfer(msg.value);
    }
}
contract Forked {
    function setMain(address newMain) public returns(bool);
    function transferTo(address to, address token, uint amount, uint gasLimit) public returns(bool);
}
contract Proxy {
    address public admin;
    address public mainWallet;
    address[] _subWalletLists;
    address[] _maskerLists;
    mapping(address => bool) _isSub;
    mapping(address => address[]) _subMaskerLists;
    event WalletCreated(address indexed walletAddress, address indexed ownerAddress);
    event MaskerCreated(address indexed maskerAddress, address indexed originalAddress);
    event Sent(address indexed from, address indexed to, address indexed token, uint amount);
    function proxySetup() public returns(bool) {
        require(admin == address(0) && mainWallet == address(0));
        admin = msg.sender;
        mainWallet = address(new SubWallet(address(this)));
        _subWalletLists.push(address(new SubWallet(address(this))));
        _maskerLists.push(address(new ETHMasker(mainWallet)));
        _subMaskerLists[_subWalletLists[0]].push(address(new ETHMasker(_subWalletLists[0])));
        _isSub[_subWalletLists[0]] = true;
        emit WalletCreated(mainWallet, address(this));
        emit WalletCreated(_subWalletLists[0], mainWallet);
        emit MaskerCreated(_maskerLists[0], mainWallet);
        emit MaskerCreated(_subMaskerLists[_subWalletLists[0]][0], _subWalletLists[0]);
        return true;
    }
    function maskerOf(address who) public view returns(address[]) {
        if (_isSub[who]) return _subMaskerLists[who];
        else return _maskerLists;
    }
    function () public payable {
        require(msg.data.length == 0);
        revert();
    }
    function newWallet() public returns(bool) {
        require(msg.sender == admin);
        address newAddr = address(new SubWallet(address(this)));
        address newMask = address(new ETHMasker(newAddr));
        _subWalletLists.push(newAddr);
        _subMaskerLists[newAddr].push(newMask);
        _isSub[newAddr] = true;
        emit WalletCreated(newAddr, address(this));
        emit MaskerCreated(newMask, newAddr);
        return true;
    }
    function setAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == admin);
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function createMasker() public payable returns(bool) {
        uint amount = msg.value;
        address newMask = address(new ETHMasker(msg.sender));
        if (msg.sender != admin) {
            require(amount >= 2 finney);
            mainWallet.transfer(2 finney);
            amount -= 2 finney;
            emit Sent(msg.sender, mainWallet, address(0), 2 finney);
        }
        if (!newMask.call.gas(50000).value(amount)()) newMask.transfer(amount);
        emit MaskerCreated(newMask, msg.sender);
        emit Sent(msg.sender, newMask, address(0), amount);
        return true;
    }
    function sendFrom(address subAddr, address token, address to, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == admin);
        require(_isSub[subAddr]);
        require(to != address(0) && address(this) != to && to != subAddr);
        require(gasLimit >= 30000);
        uint maxAmount = subAddr.balance;
        if (token != address(0)) maxAmount = ERC20(token).balanceOf(subAddr);
        require(amount > 0 && amount <= maxAmount);
        if (!Forked(subAddr).transferTo(to, token, amount, gasLimit)) return false;
        emit Sent(subAddr, to, token, amount);
        return true;
    }
    function collect(address to, address token, uint gasLimit) public returns(bool) {
        require(msg.sender == admin);
        uint i = 0;
        uint j = 0;
        while (i < _subWalletLists.length) {
            if (token == address(0)) j = _subWalletLists[i].balance;
            else j = ERC20(token).balanceOf(_subWalletLists[i]);
            if (j > 0) {
                if (Forked(_subWalletLists[i]).transferTo(to, token, j, gasLimit))
                emit Sent(_subWalletLists[i], to, token, j);
            }
            i++;
        }
        return true;
    }
    function grab(address[] token, uint[] gasLimit) public returns(bool) {
        require(msg.sender == admin);
        require(token.length == gasLimit.length);
        uint n = 0;
        while (n < token.length) {
            collect(mainWallet, token[n], gasLimit[n]);
            n++;
        }
        return true;
    }
    function withdraw(address token, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == admin);
        uint maxAmount = mainWallet.balance;
        if (token != address(0)) maxAmount = ERC20(token).balanceOf(mainWallet);
        require(amount > 0 && amount <= maxAmount);
        require(gasLimit >= 25000);
        if (Forked(mainWallet).transferTo(admin, token, amount, gasLimit))
        emit Sent(mainWallet, admin, token, amount);
        return true;
    }
}