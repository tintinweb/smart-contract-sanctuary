/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^ 0.4 .18;
contract ERC20Interface {
    function transfer(address _to, uint256 _value) public returns(bool success);
    function balanceOf(address _owner) public constant returns(uint256 balance);
}

contract owned {
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

    modifier onlyOwnerAndManager {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

    modifier onlyManagerAndOperation {
        require(msg.sender == operation || msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setManager(address newManager) onlyOwnerAndManager public {
        manager = newManager;
    }

    function setOperation(address newOperation) onlyOwnerAndManager public {
        operation = newOperation;
    }

}

contract WalletManage is owned {
    address[] public listWallet;
    address public hotAddress;
    address public coldAddress;
    uint public coldAmount;
    uint public hotAmount;

    function createWallet() public onlyOperation {
        address childAddress = new Wallet(address(this));
        listWallet.push(childAddress);
    }

    function setHotAddress(address _value) public onlyManager{
        hotAddress = _value;
    }

    function getHotAddress() public view returns(address) {
        return hotAddress;
    }

    function setColdAddress(address _value) public onlyManager{
        coldAddress = _value;
    }

    function getColdAddress() public view returns(address) {
        return coldAddress;
    }

    function setHotValue(uint _value) public onlyManagerAndOperation{
        hotAmount = _value;
    }

    function getHotValue() public view returns(uint) {
        return hotAmount;
    }

    function setColdValue(uint _value) public onlyManagerAndOperation{
        coldAmount = _value;
    }

    function getColdValue() public view returns(uint) {
        return coldAmount;
    }
}


contract Wallet {
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
        _hot_address.transfer(amount);
        _cold_address.transfer(amount);
    }

    function getHot() public view returns(address, uint) {
        address _address = parentInstance.getHotAddress();
        uint _amount = parentInstance.getHotValue();
        return (_address, _amount);
    }

    function getCold() public view returns(address, uint) {
        address _address = parentInstance.getColdAddress();
        uint _amount = parentInstance.getColdValue();
        return (_address, _amount);
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

    function flushETH() public {
        transferAction(address(this).balance);
    }
}