/**
 *Submitted for verification at snowtrace.io on 2021-11-25
*/

//SPDX-License-Identifier: Financial Octopofication
pragma solidity 0.7.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IFundz {
    function transfer(address to, uint256 value) external returns (bool);
    
    function balanceOf(address who) external view returns (uint256);
}

contract FundzTokenSaleV3 is Ownable{
    using SafeMath for uint;

    address public fundzAddr;
    address public fundzTokenSaleTreasury;
    bool public treasuryIsLocked;
    bool public fundzAddrIsLocked;
    uint256 private avaxAmount;
    uint256 public fundzPriceAvax;
    uint256 public fundzDecimal = 18;
    uint256 public avaxDecimal = 18;
    uint256 public startedAt;
    uint256 public endAt;
    
    event TokenTransfer(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public fundzExchanged;

    constructor(address _fundzAddr, address _fundzTokenSaleTreasury, uint256 _startDate, uint256 _endDate, uint256 _fundzPriceAvax)  {
        startedAt = _startDate;
        endAt = _endDate;
        fundzAddr = _fundzAddr;
        fundzTokenSaleTreasury = _fundzTokenSaleTreasury;
        fundzPriceAvax = _fundzPriceAvax;
        treasuryIsLocked = false;
        fundzAddrIsLocked = false;
    }
        
    receive() payable external {
        ExchangeAVAXforFUNDZ(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
        
    function ExchangeAVAXforFUNDZ(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;
        require(block.timestamp >= startedAt, "Sale not yet started, come back later!");
        require(block.timestamp < endAt, "Sale Ended :(");
                
        avaxAmount = ((amount.mul(10 ** uint256(fundzDecimal)).div(fundzPriceAvax)).mul(10 ** uint256(fundzDecimal))).div(10 ** uint256(fundzDecimal));
        require(IFundz(fundzAddr).balanceOf(address(this)) >= avaxAmount, "Contract has low FUNDZ balance :(");
        
        require(IFundz(fundzAddr).transfer(userAdd, avaxAmount));
        emit TokenTransfer(userAdd, avaxAmount);
        fundzExchanged[msg.sender] = fundzExchanged[msg.sender].add(avaxAmount);
        payable(fundzTokenSaleTreasury).transfer(amount);
    }
    
    function ExchangeAVAXforFUNDZManual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        require(block.timestamp >= startedAt, "Sale not yet started");
        require(block.timestamp < endAt, "Sale Ended");
        
       
        avaxAmount = ((amount.mul(10 ** uint256(fundzDecimal)).div(fundzPriceAvax)).mul(10 ** uint256(fundzDecimal))).div(10 ** uint256(fundzDecimal));
        require(IFundz(fundzAddr).balanceOf(address(this)) >= avaxAmount, "Contract has low FUNDZ balance :(");
        
        require(IFundz(fundzAddr).transfer(userAdd, avaxAmount));
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, avaxAmount);
        fundzExchanged[msg.sender] = fundzExchanged[msg.sender].add(avaxAmount);
        payable(fundzTokenSaleTreasury).transfer(amount);
    }
    
    function setFundzDecimal(uint256 newDecimal) public onlyOwner {
        fundzDecimal = newDecimal;
    }
    
    function updateFundzPrice(uint256 _fundzPriceAvax) public onlyOwner {
        fundzPriceAvax = _fundzPriceAvax;
    }
    
    function setFundzAddress(address newFundzAddr) public onlyOwner {
        require (fundzAddrIsLocked == false, "Can't be updated, FUNDZ address is already locked!");
        fundzAddr = newFundzAddr;
    }

    function lockFundzAddress(bool) public onlyOwner {
        require (fundzAddrIsLocked == false, "FUNDZ address is already locked!");
        fundzAddrIsLocked = true;
    }

    function setTreasuryAddress(address _fundzTokenSaleTreasury) public onlyOwner {
        require (treasuryIsLocked == false, "Can't be updated, treasury address is already locked!");
        fundzTokenSaleTreasury = _fundzTokenSaleTreasury;
    }

    function lockTreasuryAddress(bool) public onlyOwner {
        require (treasuryIsLocked == false, "Treasury address is already locked!");
        treasuryIsLocked = true;
    }

    function withdrawFundz(address beneficiary) public onlyOwner {
        require(block.timestamp >= endAt, "Sale not yet ended.");
        require(IFundz(fundzAddr).transfer(beneficiary, IFundz(fundzAddr).balanceOf(address(this))));
    }
    
    function changeStartDate(uint256 _startedAt) public onlyOwner {
        startedAt = _startedAt;
    }
     
    function changeEndDate(uint256 _endAt) public onlyOwner {
        endAt = _endAt;
    }

    function withdrawAvax(address payable beneficiary) public onlyOwner {
        require(block.timestamp >= endAt, "Sale not yet ended.");
        beneficiary.transfer(address(this).balance);
    }

    function fundzBalance() public view returns (uint256){
        return IFundz(fundzAddr).balanceOf(address(this));
    }

    function avaxBalance() public view returns (uint256){
        return address(this).balance;
    }
}