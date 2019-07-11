/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.4.25;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Bet {
    address public owner;
    struct ContractEntry{
        address _address;
        bool _enabled;
        ERC20Interface _contractInterface;
    }
    mapping (address => ContractEntry) public contractMap;

    event SendBalance(address _from, uint256 _value);
    event SendBalanceERC20(address _from, uint256 _value, address _contractAddress);
    event WithdrawBalance(address _to, uint256 _value);
    event WithdrawBalanceERC20(address _to, uint256 _value, address _contractAddress);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //set contract
    function addContractERC20(address _contractAddress) public onlyOwner returns (bool){
        ContractEntry memory cEntry = contractMap[_contractAddress];
        require(_contractAddress != cEntry._address);
        ERC20Interface _contractInterface = ERC20Interface(_contractAddress);
        contractMap[_contractAddress] = ContractEntry(_contractAddress, true, _contractInterface);
        return true;
    }
    function changeContractStatus(address _contractAddress, bool enabled) public onlyOwner returns (bool){
        ContractEntry memory cEntry = contractMap[_contractAddress];
        require(_contractAddress == cEntry._address);
        cEntry._enabled = enabled;
        contractMap[_contractAddress] = cEntry;
        return true;
    }
    function getContractStatus(address _contractAddress) public view returns (int8){
        ContractEntry memory cEntry = contractMap[_contractAddress];
        if(_contractAddress == cEntry._address){
            if(cEntry._enabled){
               return 1;
            }else{
               return 0;
            }
        }else{
            return -1;
        }
    }

    //get balance
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getBalanceERC20(address _contractAddress) public view returns (uint256){
        ContractEntry memory cEntry = contractMap[_contractAddress];
        require(_contractAddress == cEntry._address);
        return cEntry._contractInterface.balanceOf(this);
    }

    //transfer balance
    function sendBalance() public payable returns(uint) {
        emit SendBalance(msg.sender, msg.value);
        return msg.value;
    }

    function sendBalanceERC20(address _contractAddress, uint _value) public returns (bool) {
        require(_value > 0);
        ContractEntry memory cEntry = contractMap[_contractAddress];
        require(_contractAddress == cEntry._address);
        require(cEntry._enabled);
        require(cEntry._contractInterface.transferFrom(msg.sender, this, _value));
        emit SendBalanceERC20(msg.sender, _value, _contractAddress);
        return true;
    }

    //withdraw balance
    function withdrawBalance(address _to, uint256 _value)  public onlyOwner returns (bool) {
        require(_value > 0);
        _to.transfer(_value);
        emit WithdrawBalance(_to, _value);
        return true;
    }
    function withdrawBalanceERC20(address _to, uint256 _value, address _contractAddress)  public onlyOwner returns (bool) {
        require(_value > 0);
        ContractEntry memory cEntry = contractMap[_contractAddress];
        require(_contractAddress == cEntry._address);
        cEntry._contractInterface.transfer(_to, _value);
        emit WithdrawBalanceERC20(_to, _value, _contractAddress);
        return true;
    }
}