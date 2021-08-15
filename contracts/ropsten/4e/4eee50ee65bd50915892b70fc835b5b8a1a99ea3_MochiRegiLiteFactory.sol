/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MochiRegiLite is SafeMath {
    address public owner;
    //company info:
    string public companyName;
    // this is just a sample test coin to be used for currency, can be whatever you want:
    IERC20 public usdc = IERC20(0xCE658c66B9DbCE86050C5C4Ccda2b967110B7E1C);
    IERC20 public dai = IERC20(0x20BC04560F4C84846a920b06F3782ffC6BA7785D);
    // poll read for the register to see if tx is complete (changes from isPending: true to isPending :false)
    mapping(uint => regiTxPending) public registers;
    mapping(address => bool) public employees;
    mapping(address => bool) public moneyManagers;
    mapping(IERC20 => uint) public balances;
    // cost of using the service:
    bool public costCoveredByMerchant; // whether or not the merchant passes this fee directly to customer at time of purchase
    uint public percentCharged;
    address public serviceFeePayTo;
    
    
    struct regiTxPending{
        bool isPending;
        uint amountDueInCents;
        uint additionalPaidByCustomer;
    }
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner, string memory _companyName, bool _costCoveredByMerchant, uint _percentCharged, address _serviceFeePayTo) {
        owner = _owner;
        companyName = _companyName;
        costCoveredByMerchant = _costCoveredByMerchant;
        percentCharged = _percentCharged;
        serviceFeePayTo = _serviceFeePayTo;
        // make owner all roles:
        employees[_owner] = true;
        moneyManagers[_owner] = true;
    }
    
    
    error Unauthorized();
    
     modifier onlyBy(address _account){
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    
    // contol who can change registers (owner will likely want to add themself)
    function addCustodianByOwner(address _employee) public onlyBy(owner){
        employees[_employee] = true;
    }
    
    function removeCustodianByOwner(address _employee) public onlyBy(owner){
        employees[_employee] = false;
    }
    
    // control who can move money (owner will likely want to add themself)
    function addMoneyManagerByOwner(address _employee) public onlyBy(owner){
        moneyManagers[_employee] = true;
    }
    
    function removeMoneyManagerByOwner(address _employee) public onlyBy(owner){
        moneyManagers[_employee] = false;
    }
    
    // change owner
    function changeOwner(address _newOwner) public onlyBy(owner){
        owner = _newOwner;
    }
    
    function changeCompanyName(string memory _newCompanyName) public onlyBy(owner){
        companyName = _newCompanyName;
    }
    
    function changeServiceFeePayTo (address _newServiceFeePayTo) public onlyBy(serviceFeePayTo){
        serviceFeePayTo = _newServiceFeePayTo;
    }
    
    // used to change state of register, if money is due, set _isPending to true and _amountDue to amount required to finish tx;
    // consider changing to use same decimal place as USDC
    function setRegisterState(uint _registerNumber, bool _isPending, uint _amountDueCents)public {
        require(_amountDueCents > 1, "minimum amount requested for payment is 1 cent USD");
        require(employees[address(msg.sender)] == true, "Can only be called by an employee address");
        if (!costCoveredByMerchant){
            // tack on service charge if merchant does not want to include in pricing:
            uint serviceFee = safeDiv(safeMul(percentCharged, _amountDueCents), 1000);
            uint totalPaidByCustomer = safeAdd(serviceFee, _amountDueCents);
            registers[_registerNumber].isPending = _isPending;
            registers[_registerNumber].amountDueInCents = totalPaidByCustomer;
            registers[_registerNumber].additionalPaidByCustomer = safeSub(totalPaidByCustomer, _amountDueCents);
        } else{
        registers[_registerNumber].isPending = _isPending;
        registers[_registerNumber].amountDueInCents = _amountDueCents;
        }
    }
    
    function payAtRegisterWithUsdc(uint _registerNumber, uint _amountToPayCents) public{
        //usdc is 6 decimal places, so cents equivalent is 10^4
        adjustForServiceFeeAndPay(_registerNumber, _amountToPayCents, usdc, 10**4);
        
    }
    
    function payAtRegisterWithDai(uint _registerNumber, uint _amountToPayCents) public{
        // dai is 6 decimal places, so cents equivalent is 10^16
        adjustForServiceFeeAndPay(_registerNumber, _amountToPayCents, dai, 10**16);
    }
    
    function cashOutTo(address _address) public{
         require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
         usdc.transfer(_address, balances[usdc]);
         balances[usdc] = 0;
         dai.transfer(_address, balances[dai]);
         balances[dai] =0;
    }
    
    function adjustForServiceFeeAndPay(uint _registerNumber, uint _amountToPayCents, IERC20 _erc20, uint _adjustForDecimal) internal{
        require(registers[_registerNumber].amountDueInCents == _amountToPayCents, "must pay exact ammount");
        uint256 allowance = _erc20.allowance(msg.sender, address(this));
        uint totalAmountInCoin = safeMul(_amountToPayCents, _adjustForDecimal);
        require(allowance >= totalAmountInCoin, "Check the token allowance");
        if(registers[_registerNumber].additionalPaidByCustomer >0){
            // adjust for decimal place
            uint coinServiceFee = safeMul(registers[_registerNumber].additionalPaidByCustomer, _adjustForDecimal);
            uint amountMinusServiceFee = safeSub(_amountToPayCents, registers[_registerNumber].additionalPaidByCustomer);
            uint coinAmountMinusSerivceFee = safeMul(amountMinusServiceFee, _adjustForDecimal);
            bool result1 = _erc20.transferFrom(msg.sender, serviceFeePayTo, coinServiceFee);
            bool result2 = _erc20.transferFrom(msg.sender, address(this), coinAmountMinusSerivceFee);
            require(result1 && result2, "transfer was not successful");
            balances[_erc20] = safeAdd(balances[_erc20], coinAmountMinusSerivceFee);
            registers[_registerNumber].isPending = false;
            registers[_registerNumber].amountDueInCents = 0;
            registers[_registerNumber].additionalPaidByCustomer = 0;
        } else{
            // merchant is absorbing service fee so it is caculated now:
            uint serviceFee = safeDiv(safeMul(percentCharged, _amountToPayCents),1000);
            // adjust for decimal place
            uint coinServiceFee = safeMul(serviceFee, _adjustForDecimal);
            uint amountMinusServiceFee = safeSub(_amountToPayCents, serviceFee);
            uint coinAmountMinusSerivceFee = safeMul(amountMinusServiceFee, _adjustForDecimal);
            bool result1 = _erc20.transferFrom(msg.sender, serviceFeePayTo, coinServiceFee);
            bool result2 = _erc20.transferFrom(msg.sender, address(this), coinAmountMinusSerivceFee);
            require(result1 && result2, "transfer was not successful");
            balances[_erc20] = safeAdd(balances[_erc20], coinAmountMinusSerivceFee);
            registers[_registerNumber].isPending = false;
            registers[_registerNumber].amountDueInCents = 0;
            registers[_registerNumber].additionalPaidByCustomer = 0;
        }
    }
    
}

contract MochiRegiLiteFactory{
    address public owner = msg.sender;
    // will be devided by 1000 so a value of 1 below is 0.1%
    uint public percentCharged = 3;
    address public serviceFeePayTo = msg.sender;
    
    
    address[] public businesses;
    
    error Unauthorized();
    modifier onlyBy(address _account){
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    
    function changePercentCharged(uint _percentCharged) public onlyBy(owner){
       percentCharged = _percentCharged;
    }
    
    function changeOwner(address _newOwner) public onlyBy(owner){
        owner = _newOwner;
    }
    
    function changeServiceFeePayTo (address _newServiceFeePayTo) public onlyBy(owner){
        serviceFeePayTo = _newServiceFeePayTo;
    }
    
    function registerNewBusiness (string memory _name, bool _merchantPaysServiceFee) public payable{
        require(msg.value == 5*10**18, "must pay to mint new registers");
        MochiRegiLite newRegi = new MochiRegiLite(msg.sender, _name, _merchantPaysServiceFee, percentCharged, serviceFeePayTo);
        businesses.push(address(newRegi));
    }
    
    function withdrawalPayment() public onlyBy(owner){
      payable(serviceFeePayTo).transfer(address(this).balance);
    }
    
    
}