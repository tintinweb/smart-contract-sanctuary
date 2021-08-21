/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-21
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

contract OnlyBy{
    error Unauthorized();
    
    modifier onlyBy(address _account){
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
}

contract HasOwnerOnlyEmergencyNativeTokenWithdraw is OnlyBy{
    address public owner;
    
    //only accessable by owner, in the event someone sends native tokens to the contract
    //   outside of public contracts, way to recover it.
    function emergencyWithdrawNativeToken(uint _amount,  address _sendTo) public onlyBy(owner){
        payable(_sendTo).transfer(_amount);
    }
    
    function changeOwner(address _newOwner) public onlyBy(owner){
        require(address(_newOwner) != address(0), "address cannot be 0x0"); 
        owner = _newOwner;
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


contract MochiRegiLite is SafeMath, HasOwnerOnlyEmergencyNativeTokenWithdraw{
    //company info:
    string public companyName;
    // this is just a sample test coin to be used for currency, can be whatever you want:
    IERC20 public usdc = IERC20(0xcb2f37b59104e8f697B5edE0B2276c97b20759b9);
    IERC20 public dai = IERC20(0x23FAE263500558D73F75043b9c2CD24777b1a38c);
    // poll read for the register to see if tx is complete (changes from isPending: true to isPending :false)
    mapping(uint => regiTxPending) public registers;
    mapping(address => bool) public employees;
    mapping(address => bool) public moneyManagers;
    mapping(IERC20 => uint) public balances;
    // cost of using the service:
    bool public costCoveredByMerchant; // whether or not the merchant passes this fee directly to customer at time of purchase
    uint public percentCharged;
    address public serviceFeePayTo1;
    address public serviceFeePayTo2;
    uint public percentTo1;
    //direct payout option
    address public directPayOutAddress;
    
    
    struct regiTxPending{
        bool isPending;
        uint amountDueInCents;
        uint additionalPaidByCustomer;
    }
    
    constructor(address _owner, string memory _companyName, bool _costCoveredByMerchant, uint _percentCharged, 
      address _serviceFeePayTo1, address _serviceFeePayTo2, uint _percentTo1, address _directPayOutAddress) {
        owner = _owner;
        companyName = _companyName;
        costCoveredByMerchant = _costCoveredByMerchant;
        percentCharged = _percentCharged;
        serviceFeePayTo1 = _serviceFeePayTo1;
        serviceFeePayTo2 = _serviceFeePayTo2;
        percentTo1 = _percentTo1;
        directPayOutAddress = _directPayOutAddress;
        // make owner all roles:
        employees[_owner] = true;
        moneyManagers[_owner] = true;
    }
    
    // contol who can change registers
    // consider renaming custodian to employee
    function addCustodianByOwner(address _employee) public onlyBy(owner){
        require(_employee != address(0), "address cannot be 0x0"); 
        employees[_employee] = true;
    }
    
    function removeCustodianByOwner(address _employee) public onlyBy(owner){
        require(_employee != address(0), "address cannot be 0x0"); 
        employees[_employee] = false;
    }
    
    // control who can move money
    function addMoneyManagerByOwner(address _employee) public onlyBy(owner){
        require(_employee != address(0), "address cannot be 0x0"); 
        moneyManagers[_employee] = true;
    }
    
    function removeMoneyManagerByOwner(address _employee) public onlyBy(owner){
        require(_employee != address(0), "address cannot be 0x0"); 
        moneyManagers[_employee] = false;
    }
    
    function changeCompanyName(string memory _newCompanyName) public onlyBy(owner){
        companyName = _newCompanyName;
    }
    
    function changeServiceFeePayTo1 (address _newServiceFeePayTo1) public onlyBy(serviceFeePayTo1){
        require(_newServiceFeePayTo1 != address(0), "address cannot be 0x0"); 
        serviceFeePayTo1 = _newServiceFeePayTo1;
    }
    
    function changeServiceFeePayTo2 (address _newServiceFeePayTo2) public onlyBy(serviceFeePayTo2){
        require(_newServiceFeePayTo2 != address(0), "address cannot be 0x0"); 
        serviceFeePayTo1 = _newServiceFeePayTo2;
    }
    
    // used to change state of register, if money is due, set _isPending to true and _amountDue to amount required to finish tx;
    // consider changing to use same decimal place as USDC
    function setRegisterState(uint _registerNumber, bool _isPending, uint _amountDueCents)public {
        if (_isPending){
            require(_amountDueCents > 1, "minimum amount requested for payment is 1 cent USD");
        }
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
        // dai is 18 decimal places, so cents equivalent is 10^16
        adjustForServiceFeeAndPay(_registerNumber, _amountToPayCents, dai, 10**16);
    }
    
    function cashOutTo(address _address) public{
         require(_address != address(0), "address cannot be 0x0"); 
         require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
         usdc.transfer(_address, balances[usdc]);
         balances[usdc] = 0;
         dai.transfer(_address, balances[dai]);
         balances[dai] =0;
    }
    
    // just in case someone sends tokens to this address, will not work for non standard erc20, but better 
    //   than nothing [Only accessable by contract owner to avoid abuse]
    function emergencyWithdrawErc20(address _addressOfCoin, uint _amount,  address _sendTo) public onlyBy(owner){
        IERC20 coin = IERC20(_addressOfCoin);
        bool result = coin.transfer(_sendTo, _amount);
        require (result, "transfer was not successful");
            // if you're emergency withdrawing DAI or USDC withdraw all of it so we can reset state:
            balances[coin] = 0;
    }
    
    // set this address to 0x0 to turn the feature off:
    function setDirectPayOutAddress(address _address)public{
        require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
        directPayOutAddress = _address;
    }
    
    //note: due to using cents as the sigfig nothing will be charged for less than $3.34 @ .3%
    function adjustForServiceFeeAndPay(uint _registerNumber, uint _amountToPayCents, IERC20 _erc20,
      uint _adjustForDecimal) internal{
        require(registers[_registerNumber].amountDueInCents == _amountToPayCents, "must pay exact ammount");
        uint256 balance = _erc20.balanceOf(msg.sender);
        uint256 allowance = _erc20.allowance(msg.sender, address(this));
        uint totalAmountInCoin = safeMul(_amountToPayCents, _adjustForDecimal);
        require(balance >= totalAmountInCoin, "Sender must have enough of the coin to make transaction");
        require(allowance >= totalAmountInCoin, "Check the token allowance");
        if(registers[_registerNumber].additionalPaidByCustomer >0){
            completePayment(registers[_registerNumber].additionalPaidByCustomer, _registerNumber, 
              _amountToPayCents, _erc20, _adjustForDecimal);
        } else{
            // merchant is absorbing service fee so it is caculated now:
            uint serviceFee = safeDiv(safeMul(percentCharged, _amountToPayCents),1000);
            // adjust for decimal place
            completePayment(serviceFee, _registerNumber, _amountToPayCents,  _erc20, _adjustForDecimal);
        }
    }
    
    function completePayment(uint _serviceFee, uint _registerNumber, uint _amountToPayCents, IERC20 _erc20,
      uint _adjustForDecimal) internal{
            // adjust for decimal place
            uint coinServiceFee = safeMul(_serviceFee, _adjustForDecimal);
            uint serviceFeeTo1 = safeDiv(safeMul(percentTo1, coinServiceFee),100);
            uint serviceFeeTo2 = safeSub(coinServiceFee, serviceFeeTo1);
            uint amountMinusServiceFee = safeSub(_amountToPayCents, _serviceFee);
            uint coinAmountMinusSerivceFee = safeMul(amountMinusServiceFee, _adjustForDecimal);
            //which is more performant, 3 transferFrom calls or 3 and sometimes 4 transfer calls?
            bool result1 = false;
            if(directPayOutAddress == address(0)){
                result1 = _erc20.transferFrom(msg.sender, address(this), coinAmountMinusSerivceFee);
            }else {
                result1 = _erc20.transferFrom(msg.sender, directPayOutAddress, coinAmountMinusSerivceFee);
            }
            bool result2 = true; 
            if (serviceFeeTo1 > 0){
                result2 = _erc20.transferFrom(msg.sender, serviceFeePayTo1, serviceFeeTo1);
            }
            bool result3 = true; 
            if (serviceFeeTo2 > 0){
                result3 = _erc20.transferFrom(msg.sender, serviceFeePayTo2, serviceFeeTo2);
            }
            require(result1 && result2 && result3, "transfer out was not successful");
            if (directPayOutAddress == address(0)){
                balances[_erc20] = safeAdd(balances[_erc20], coinAmountMinusSerivceFee);
            }
            registers[_registerNumber].isPending = false;
            registers[_registerNumber].amountDueInCents = 0;
            registers[_registerNumber].additionalPaidByCustomer = 0;
    }
    
}

contract MochiRegiLiteFactory is SafeMath, HasOwnerOnlyEmergencyNativeTokenWithdraw{
    // will be divided by 1000 so a value of 1 below is 0.1%
    uint public percentCharged = 3;
    address public serviceFeePayTo;
    uint public chargePerMint = 200; //5*10**18;
    // amount to split with commissioner
    uint public percentSplit = 50;
    mapping(address => address[]) public businesses;
    
    constructor(){
        serviceFeePayTo = msg.sender;
        owner = msg.sender;
    }
    
    function changePercentCharged(uint _percentCharged) public onlyBy(owner){
        // hard code a 5% service fee limit for all contracts forever.
        require (_percentCharged <= 50, "split percent cannot be more than 50");
        percentCharged = _percentCharged;
    }
    
    function changeServiceFeePayTo (address _newServiceFeePayTo) public onlyBy(owner){
        require(address(_newServiceFeePayTo) != address(0), "address cannot be 0x0"); 
        serviceFeePayTo = _newServiceFeePayTo;
    }
    
    function changeChargePerMint (uint _newCharge) public onlyBy(owner){
        chargePerMint = _newCharge;
    }
    
    function changeSplitPercent(uint _newSplit) public onlyBy(owner){
        require (_newSplit <= 100, "split percent cannot be more than 100");
        percentSplit = _newSplit;
    }
    
    
    function registerNewBusiness (string memory _name, bool _merchantPaysServiceFee, address _commissioner, 
      address _directPayOutAddress) public payable{
           require( _commissioner != address(0), "address cannot be 0x0"); 
        require(msg.value == chargePerMint, "must pay to mint new registers");
        MochiRegiLite newRegi = new MochiRegiLite(msg.sender, _name, _merchantPaysServiceFee, percentCharged, 
          owner, _commissioner, percentSplit, _directPayOutAddress);
        businesses[msg.sender].push(address(newRegi));
        uint payOutToOwner = safeDiv(safeMul(msg.value, percentSplit), 100);
        uint payOutToCommissioner = safeSub(msg.value, payOutToOwner);
        payable(serviceFeePayTo).transfer(payOutToOwner);
        payable(_commissioner).transfer(payOutToCommissioner);
    }
    
    function withdrawalPayment() public onlyBy(owner){
      
    }
    
    function getAddressesForBusinesses(address _ownerAddress)public view returns( address  [] memory){
        return businesses[_ownerAddress];
    }
    
    function removeRegisters(address _ownerAddress, uint _locationInArray) public onlyBy(owner){
        delete businesses[_ownerAddress][_locationInArray];
    }
    
    // would like to include with inheretence as well, however, this contract doesn't have any state with regard
    //    to any ERC20 tokens, again none should ever be sent here, but just in case:
    function emergencyWithdrawErc20(address _addressOfCoin, uint _amount,  address _sendTo) public onlyBy(owner){
        IERC20 coin = IERC20(_addressOfCoin);
        bool result = coin.transfer(_sendTo, _amount);
        require (result, "transfer was not successful");
    }
    
}