/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

pragma solidity ^0.5.1;

contract charity{
    address payable owner; 
    address payable getter;
    uint date;
    uint amount;
    address payable wallet;
    constructor(uint _date, uint _amount, address payable _wallet) public { 
        owner = msg.sender;
        date = _date;
        amount = _amount;
        wallet = _wallet;
    }
    modifier onlyOwner(address _owner) {
        require(_owner==owner);
        _;
    }
   function changeOwner(address payable _newOwner) external onlyOwner(owner) {
      owner = _newOwner;
   }
   function setWalletAddress(address payable _wallet) external onlyOwner(owner){
        wallet=_wallet;
    }
    //������������� �����, �� ������� � ����� �������� ������
    function setGetter(address payable _getter) external onlyOwner(owner){
        getter=_getter;
    }
    //������������� ���� �� ������� �������������� ��� ���� � unix �������
    function setDate(uint _date) external onlyOwner(owner){
        date=_date;
    }
    //������������� �����, ������� �������� �����
    function setAmount(uint _amount)external onlyOwner(owner){
        amount=_amount;
    }
    //������� ��� ��������� ������ �� �������� �����
    function balanceView() public view returns (uint) {
       uint balance = address(wallet).balance;
       return balance;
    }
    function allInfo() public view returns (uint) {
       return amount;
    }
    modifier onlyAfter(uint time) {
      require( now > time);
      _;
   }
    modifier enoughSum(uint sum) {
      require( balanceView() >= sum);
      _;
   }
   modifier onlyBefore(uint _time) {
      require( now <= _time);
      _;
   }
    modifier notEnoughSum(uint summ) {
      require( balanceView() < summ);
      _;
   }
   
   // ������� ���������� � ������ ���������� �����.
    event Donation(address indexed from, uint value);
    //������� �������� ����� �� ���� ��������, ������� ����� ������� ����� ������������
    function donation(uint _sum) public payable notEnoughSum(balanceView()) onlyBefore(date) {
        wallet.transfer(_sum);
       emit Donation(msg.sender, msg.value);
    }
    
 //���� �����=����������, �� ������ ������������ �� ����� ��������
//���� ����� ��= ���������� � ���� ����������, �� ������ ����������� �� ����� ����������������� �����������
  function send() external payable onlyOwner(owner) enoughSum(amount){
      getter.transfer(amount);
      } 
 function sendIfFail() external payable onlyAfter(date) onlyOwner(owner) notEnoughSum(amount){
      owner.transfer(amount);
      } 



}