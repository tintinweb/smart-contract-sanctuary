// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract PreSale {

    using SafeMath for uint256;

    uint256 private constant decimal = 18;

    uint256 private _airdrop;
    uint256 private _preSale;

    mapping (address => uint256) _erc20Balance;
    mapping (address => bool) _isReceive;
    mapping (address => uint256) _balance;
    mapping (address => uint256) _buyBalance;

    address private _erc20;
    address private _preSaleAddress;    // 私募地址
    address private _airdropAddress;    // 空投地址
    address private _collectionAddress; // 收款地址

    event Buy(address indexed recomm, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);
    event Transfer(address indexed sender, uint256 amount);

    constructor(address erc20_, address preSaleAddress_, address collectionAddress_, address airdropAddress_){
        _erc20 = erc20_;
        _preSaleAddress = preSaleAddress_;
        _airdropAddress = airdropAddress_;
        _collectionAddress = collectionAddress_;
        _airdrop = 60000000*10**decimal;
        _preSale = 1200000000*10**decimal;
    }

    function getERC20Balance(address owner_) external view returns(uint256){
        return _erc20Balance[owner_];
    }

    function getIsReceive(address owner_) external view returns(bool){
        return _isReceive[owner_];
    }

    function getBalance(address owner_) external view returns(uint256){
        return _balance[owner_];
    }

    function getCanBuyBalance(address owner_) external view returns(uint256){
        uint256 buyBalance = _buyBalance[owner_];
        return (10*10**decimal).sub(buyBalance);
    }

    function airdrop(address recomm) external {
        address sender = msg.sender;
        require(_airdrop >= 300*10**decimal, "PreSale: Airdrop has been issued");
        require(!_isReceive[sender], "PreSale: The airdrop has been received and cannot be received again");
        _erc20Balance[sender] = _erc20Balance[sender].add(200*10**decimal);
        if (recomm != address(0)) {
            _erc20Balance[recomm] = _erc20Balance[recomm].add(100*10**decimal);
            _airdrop = _airdrop.sub(100*10**decimal);
        }
        _airdrop = _airdrop.sub(200*10**decimal);
        _isReceive[sender] = true;
    }

    function buy(address recomm) payable external {
        address sender_ = msg.sender;
        uint256 buyAmount = msg.value;
        uint256 amount = buyAmount.mul(400000);
        uint256 buyBalance = _buyBalance[sender_];
        require(buyAmount <= 10**19 && buyAmount >= 10**17, "PreSale: Minimum 0.1 BNB, maximum 10 BNB");
        require((10*10**decimal).sub(buyBalance) >= buyAmount, "Presale: The purchase quantity has been operated 10 BNB");
        require(_preSale >= amount, "PreSale: Sell out");
        uint256 recommFree;
        if (recomm != address(0)){
            recommFree = buyAmount.div(10);
            _balance[recomm] = _balance[recomm].add(recommFree);
        }
        _preSale = _preSale.sub(amount);
        _buyBalance[sender_] = buyBalance.add(buyAmount);
        IERC20(_erc20).transferFrom(_preSaleAddress, sender_, amount); // 预售地址授权给合约
        payable(_collectionAddress).transfer(buyAmount.sub(recommFree));
        emit Buy(recomm, buyAmount);
    }

    function withdraw() external {
        address sender_ = msg.sender;
        uint256 balance = _balance[sender_];
        require(balance > 0, "PreSale: The balance is unstable");
        require(balance >= 10**(decimal - 1), "PreSale: At least 0.1 BNB can be extracted");
        _balance[sender_] = 0;
        payable(sender_).transfer(balance);
        emit Withdraw(sender_, balance);
    }

    function transfer() external {
        address sender_ = msg.sender;
        uint256 balance = _erc20Balance[sender_];
        require(_airdrop <= 0 || balance >= 2000*10**18, "PreSale: Only when the balance reaches 2000 can it be withdrawn");
        require(balance > 0, "PreSale: The balance is unstable");
        _erc20Balance[sender_] = 0;
        IERC20(_erc20).transferFrom(_airdropAddress, sender_, balance);
        emit Transfer(sender_, balance);
    }

}