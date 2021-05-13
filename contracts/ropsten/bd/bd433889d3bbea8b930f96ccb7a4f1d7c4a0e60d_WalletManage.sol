/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^ 0.4 .18;

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns(bool success);
    function balanceOf(address _owner) external constant returns(uint256 balance);
}

interface ERC721Interface {
    function transferFrom(address _from, address _to, uint256 _tokenId) external returns(bool success);
    function balanceOf(address _owner) external constant returns(uint256);
}

contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WalletOwned {
    address public owner;
    address public manager;
    address public operation;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    modifier onlyOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    modifier onlyOwnerOrManager {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    modifier onlyManagerOrOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setManager(address newManager) onlyOwnerOrManager public {
        manager = newManager;
    }

    function setOperation(address newOperation) onlyOwnerOrManager public {
        operation = newOperation;
    }

}

contract WalletManage is WalletOwned, SafeMath {
    address[] public listWallet;
    address public hotAddress;
    address public coldAddress;
    uint public coldPercent;
    uint public hotPercent;

    event CreateWallet(address wallet);
    event SetHotWalletAddress(address wallet);
    event SetColdWalletAddress(address wallet);
    event SetHotPercent(uint percent);
    event SetColdPercent(uint percent);

    function createWallet() public onlyOperation {
        address childAddress = new Wallet(address(this));
        listWallet.push(childAddress);
        emit CreateWallet(childAddress);
    }

    function setHotAddress(address _value) public onlyManager {
        hotAddress = _value;
        emit SetHotWalletAddress(hotAddress);
    }

    function setColdAddress(address _value) public onlyManager {
        coldAddress = _value;
        emit SetColdWalletAddress(coldAddress);
    }

    function setPercent(uint _hot_percent) public onlyManagerOrOperation {
        require(_hot_percent > 0 && _hot_percent < 100);
        hotPercent = _hot_percent;
        coldPercent = sub(100, _hot_percent);
        emit SetHotPercent(hotPercent);
        emit SetColdPercent(coldPercent);
    }

    function getHotAddress() public view returns(address) {
        return hotAddress;
    }

    function getColdAddress() public view returns(address) {
        return coldAddress;
    }

    function getHotPercent() public view returns(uint) {
        return hotPercent;
    }

    function getColdPercent() public view returns(uint) {
        return coldPercent;
    }
}


contract Wallet is SafeMath {
    WalletManage parentInstance;
    event Deposited(address from, uint value, bytes data);

    function() public payable {
        transferAction(msg.value);
        emit Deposited(msg.sender, msg.value, msg.data);
    }

    constructor(address _parent_address) public {
        parentInstance = WalletManage(_parent_address);
    }

    function transferAction(uint amount) private {
        address _hot_address;
        uint _hot_value;
        address _cold_address;
        uint _cold_value;
        (_hot_address, _hot_value) = getHot();
        (_cold_address, _cold_value) = getCold();

        uint _amount_cold = mul(div(amount, 100), _cold_value);
        uint _amount_hot = sub(amount, _amount_cold);

        _hot_address.transfer(sub(amount, _amount_hot));
        _cold_address.transfer(_amount_cold);
    }

    function getHot() public view returns(address, uint) {
        address _address = parentInstance.getHotAddress();
        uint _amount = parentInstance.getHotPercent();
        return (_address, _amount);
    }

    function getCold() public view returns(address, uint) {
        address _address = parentInstance.getColdAddress();
        uint _amount = parentInstance.getColdPercent();
        return (_address, _amount);
    }

    function flushETH() public {
        transferAction(address(this).balance);
    }

    function flushERC(address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint WalletBalance = instance.balanceOf(address(this));
        address _hot_address = parentInstance.getHotAddress();
        if (WalletBalance == 0) {
            return;
        }
        if (!instance.transfer(_hot_address, WalletBalance)) {
            revert();
        }
    }

    function flushNFT(address tokenContractAddress, uint256 tokenId) public {
        ERC721Interface instance = ERC721Interface(tokenContractAddress);
        address _hot_address = parentInstance.getHotAddress();
        if (!instance.transferFrom(address(this), _hot_address, tokenId)) {
            revert();
        }
    }

}