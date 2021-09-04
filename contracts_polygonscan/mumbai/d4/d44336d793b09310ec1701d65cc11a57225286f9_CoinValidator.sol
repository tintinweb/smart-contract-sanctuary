/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

//SPDX-License-Identifier: UNLICENSED

// This code is made public for the sake of transparency and security.
// This is due to the nature of "smart contracts"
// This does not constitute a forfieture of intellectual property rights
// This code (or any modification of it) is not to be redistributed by 
//    another party for commercial gain.
// This was made in good faith, however, cannot offer any guarantees
//    and the user is responsible for any damages that may occur as a
//    result of use.
// This is the property of MochiJump.com
pragma solidity ^0.8.4;

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

interface IRERC20 is IERC20{
    function mintFromRegi(address recipient, uint256 amount) external returns(bool);
}

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
        // remember "_;" required for modifier gotcha
        _;
    }
}

contract HasOwner is OnlyBy{
    address public owner;
    
    function changeOwner(address _newOwner) public onlyBy(owner){
        require(address(_newOwner) != address(0), "address cannot be 0x0"); 
        owner = _newOwner;
    }

}

contract CoinValidator is HasOwner{
    mapping(address=>bool) public approvedStableCoins;
    mapping(address=>bool) public approvedRewardsTokens;
    
    constructor(){
        owner = msg.sender;
        approvedStableCoins[0x23FAE263500558D73F75043b9c2CD24777b1a38c] = true;
        approvedStableCoins[0xcb2f37b59104e8f697B5edE0B2276c97b20759b9] = true;
        
    }
    
    function addApprovedStableCoins(address[] calldata _addresses)public onlyBy(owner){
        for (uint i = 0; i < _addresses.length; i++){
            approvedStableCoins[_addresses[i]] = true;
        }
    }
    
    function addApprovedRewardsTokens(address[] calldata _addresses)public onlyBy(owner){
        for (uint i = 0; i < _addresses.length; i++){
            approvedRewardsTokens[_addresses[i]] = true;
        }
    }
    
    function disapproveAddresses(address[] calldata _addresses)public onlyBy(owner){
        for (uint i = 0; i < _addresses.length; i++){
            approvedStableCoins[_addresses[i]] = false;
            approvedRewardsTokens[_addresses[i]] = false;
        }
    }
}

contract SafetyNet is HasOwner{
    
    //only accessable by owner, in the event someone sends native tokens to the contract
    //   outside of public contracts, way to recover it.
    function emergencyWithdrawNativeToken(uint _amount) public onlyBy(owner){
        // no concern about re-entry:
        msg.sender.call{value:_amount}("");
    }
    
    // the following two methods are borrowed from Sushi's:
    //   https://github.com/sushiswap/sushiswap/blob/canary/contracts/libraries/SafeERC20.sol
    //   and is being reused under the MIT licensing terms: (https://github.com/sushiswap/sushiswap/blob/canary/LICENSE.txt)
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }
    
    // this method is modified from the original to allow transfers to different addresses:
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

contract MochiRegiLite is SafeMath, SafetyNet{
    // set and hard coded into the lifetime of the contract, safer in my opinion than allowing 
    //  a backdoor to change it. This is here to ensure no one can set a stable coin or rewards 
    //  token to something malicous
    CoinValidator public validator = CoinValidator(0xd44336d793B09310EC1701d65cc11a57225286F9);
    address public parentFactory;
    //company info:
    string public companyName;
    // uint is the cents value for that stablecoin:
    address[] public approvedStableCoins;
    // cent values
    mapping (address => uint) public centValues;
    // poll read for the register to see if tx is complete (changes from isPending: true to isPending :false)
    mapping(uint => regiTxPending) public registers;
    mapping(address => bool) public employees;
    mapping(address => bool) public moneyManagers;
    mapping(address => uint) public balances;
    mapping(address => uint) public tipJar;
    // cost of using the service:
    bool public costCoveredByMerchant; // whether or not the merchant passes this fee directly to customer at time of purchase
    uint public percentCharged;
    address public serviceFeePayTo1;
    address public serviceFeePayTo2;
    uint public percentTo1;
    //direct payout option
    address public directPayOutAddress;
    //rewards token
    IRERC20 public rewardsToken;
    
    
    
    struct regiTxPending{
        bool isPending;
        uint amountDueInCents;
        uint additionalPaidByCustomer;
    }
    
    //would like to have 2 more options in constructor, however, cannot optimize if done. Must be configured after
    //  creation to use rewardsToken and directPayOut option.
    constructor(address _owner, string memory _companyName, bool _costCoveredByMerchant, uint _percentCharged, 
      address _serviceFeePayTo1, address _serviceFeePayTo2, uint _percentTo1, address _parentFactory) {
        owner = _owner;
        companyName = _companyName;
        costCoveredByMerchant = _costCoveredByMerchant;
        percentCharged = _percentCharged;
        serviceFeePayTo1 = _serviceFeePayTo1;
        serviceFeePayTo2 = _serviceFeePayTo2;
        percentTo1 = _percentTo1;
        parentFactory = _parentFactory;
        // make owner all roles:
        employees[_owner] = true;
        moneyManagers[_owner] = true;
        //setup approved stablecoins dai/usdc by default
        approvedStableCoins.push(0x1C60a866552A7a00e3614f7C8609F6b11C72Dfa2);
        approvedStableCoins.push(0x2eb07888b9e0B9bcc5f67D922Fe6260F520eaE22);
        // dai is 18 decimal places, so cents equivalent is 10^16
        centValues[0x23FAE263500558D73F75043b9c2CD24777b1a38c] = 10**16;
        // usdc is 6 decimal places, so cents equivalent is 10^4
        centValues[0xcb2f37b59104e8f697B5edE0B2276c97b20759b9] = 10**4;
    }
    
    function getApprovedStableCoins() public view returns (address[] memory){
        return approvedStableCoins;
    }
    
    function addStableCoin(address _tokenAddress, uint _centsPosition) public{
        require(moneyManagers[address(msg.sender)], "Must be called by a money manager address");
        // this is done to protect customers from maliciously coded "Stable Coins"
        require(validator.approvedStableCoins(_tokenAddress), "stable coin must be verified to be useable");
        approvedStableCoins.push(address(_tokenAddress));
        centValues[_tokenAddress] = _centsPosition;
    }
    
    function removeStableCoin(uint _index) public {
        require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
        address addressAtLoc = approvedStableCoins[_index];
        delete approvedStableCoins[_index];
        centValues[addressAtLoc] = 0;
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
    
    function payAtRegister(uint _registerNumber, uint _amountToPayCents, address _coin) public{
        require(centValues[_coin] >0, "must be an approved coin");
        adjustForServiceFeeAndPay(_registerNumber, _amountToPayCents, IERC20(_coin), centValues[_coin]);
    }
    
    
    //additional amount for tips will not be subject to service fees and shall be provided in native decimal amounts
    function payAtRegisterWithTip(uint _registerNumber, uint _amountToPayCents, address _erc20, uint _additionalTip) public{
        payAtRegister(_registerNumber, _amountToPayCents, _erc20);
        safeTransferFrom(IERC20(_erc20), msg.sender, address(this), _additionalTip);
        tipJar[_erc20] = safeAdd(tipJar[_erc20], _additionalTip);
    }
    
    function cashOut(address _address) public{
         require(_address != address(0), "address cannot be 0x0"); 
         require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
         for (uint i = 0; i < approvedStableCoins.length; i++){
             IERC20 coin = IERC20(approvedStableCoins[i]);
             uint amount = safeAdd(balances[approvedStableCoins[i]], tipJar[approvedStableCoins[i]]);
             balances[approvedStableCoins[i]] = 0;
             safeTransfer(coin, _address, amount);
         }
    }
    
    function transferFromTill(address _erc20, address _to, uint _amount) public{
         require(_to != address(0), "address cannot be 0x0"); 
         require(_erc20 != address(0), "address cannot be 0x0"); 
         require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
         require(balances[_erc20]>= _amount, "cannot withdraw more than is available");
         require(centValues[_erc20] >0, "must be an approved coin");
         IERC20 coin = IERC20(_erc20);
         balances[_erc20] = safeSub(balances[_erc20], _amount);
         safeTransfer(coin,_to, _amount);
    }
    
    function transferFromTips(address _erc20, address _to, uint _amount) public{
         require(_to != address(0), "address cannot be 0x0"); 
         require(_erc20 != address(0), "address cannot be 0x0"); 
         require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
         require(balances[_erc20]>= _amount, "cannot withdraw more than is available");
         require(centValues[_erc20] >0, "must be an approved coin");
         IERC20 coin = IERC20(_erc20);
         balances[_erc20] = safeSub(tipJar[_erc20], _amount);
         safeTransfer(coin,_to, _amount);
    }

    // just in case someone sends tokens to this address, will not work for non standard erc20, but better 
    //   than nothing [Only accessable by contract owner to avoid abuse]
    function emergencyWithdrawErc20(address _addressOfCoin, uint _amount,  address _sendTo) public onlyBy(owner){
        IERC20 coin = IERC20(_addressOfCoin);
        safeTransfer(coin,_sendTo, _amount);
        if (centValues[_addressOfCoin] >0)
            // if you're emergency withdrawing an approved coin all of it so we can reset state:
            balances[_addressOfCoin] = 0;
    }
    
    // set this address to 0x0 to turn the feature off:
    function setDirectPayOutAddress(address _address)public{
        require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
        directPayOutAddress = _address;
    }
    
    // set this address to 0x0 to turn the feature off:
    function changeRewardsToken (address _tokenAddress) public{
        require(moneyManagers[address(msg.sender)] == true, "Must be called by a money manager address");
        // this is done to protect customers from maliciously coded "Rewards Tokens"
        require(validator.approvedRewardsTokens(_tokenAddress), "rewards coin must be verified to be useable");
        rewardsToken = IRERC20(_tokenAddress);
    }
    
    //note: due to using cents as the sigfig nothing will be for any surcharge less than 1 complete cent
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
            if(directPayOutAddress == address(0)){
                safeTransferFrom(_erc20,msg.sender, address(this), coinAmountMinusSerivceFee);
            }else {
                safeTransferFrom(_erc20,msg.sender, directPayOutAddress, coinAmountMinusSerivceFee);
            }
            if (serviceFeeTo1 > 0){
                safeTransferFrom(_erc20,msg.sender, serviceFeePayTo1, serviceFeeTo1);
            }
            if (serviceFeeTo2 > 0){
                safeTransferFrom(_erc20,msg.sender, serviceFeePayTo2, serviceFeeTo2);
            }
            //recognize, if this were a withdrawal, this would be vunerable to re-entry
            //  however, in this case a re-entry attack would just mean customer 
            //  is paying more.
            if (directPayOutAddress == address(0)){
                balances[address(_erc20)] = safeAdd(balances[address(_erc20)], coinAmountMinusSerivceFee);
            }
            if (address(rewardsToken) != address(0)){
                rewardsToken.mintFromRegi(msg.sender, coinAmountMinusSerivceFee);
            }
            registers[_registerNumber].isPending = false;
            registers[_registerNumber].amountDueInCents = 0;
            registers[_registerNumber].additionalPaidByCustomer = 0;
    }
    
}

contract MochiRegiLiteFactory is SafeMath, SafetyNet{
    string public version = "0.1.0";
    // will be divided by 1000 so a value of 1 below is 0.1%
    uint public percentCharged = 3;
    address public serviceFeePayTo;
    uint public chargePerMint = 200; //5*10**18;
    // amount to split with commissioner
    uint public percentSplit = 50;
    mapping(address => address[]) public businesses;
    //for contract verification
    mapping(address => bool) public verified;
    bool public isRetired = false;
    
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
    
    
    // removing directPayOutAddress and rewardsToken as solidity requires smaller function params to do optimization:
    function registerNewBusiness (string memory _name, bool _merchantPaysServiceFee, address _commissioner) public payable{
        require( _commissioner != address(0), "address cannot be 0x0"); 
        require(msg.value == chargePerMint, "must pay to mint new registers");
        require(!isRetired, "factory must be active");
        MochiRegiLite newRegi = new MochiRegiLite(msg.sender, _name, _merchantPaysServiceFee, percentCharged, 
          owner, _commissioner, percentSplit, address(this));
        businesses[msg.sender].push(address(newRegi));
        verified[address(newRegi)] = true;
        uint payOutToOwner = safeDiv(safeMul(msg.value, percentSplit), 100);
        uint payOutToCommissioner = safeSub(msg.value, payOutToOwner);
        // no concern about re-entry:
        (bool success1, ) = payable(serviceFeePayTo).call{value:payOutToOwner}("");
        (bool success2, ) = payable(_commissioner).call{value:payOutToCommissioner}("");
        require(success1 && success2, "Transfer failed.");
    }
    
    //retire in case of upgrades, setting to true stops all future register production from this factory
    function retireFactory(bool _isRetired) public onlyBy(owner){
      isRetired = _isRetired;
    }
    
    function getAddressesForBusinesses(address _ownerAddress)public view returns( address  [] memory){
        return businesses[_ownerAddress];
    }
    
    //callable by register set owner, if anyone else calls nothing will be found
    function removeRegisters(uint _locationInArray) public{
        address addressToDelete = businesses[msg.sender][_locationInArray];
        delete businesses[msg.sender][_locationInArray];
        // remove from verified, the registers at that address should no longer be used
        verified[addressToDelete];
    }
    
    //callable by register set owner, if anyone else calls nothing will be found
    function changeRegisterSetOwner(address _newOwner, uint _locationInArray) public{
        address addressToMove = businesses[msg.sender][_locationInArray];
        delete businesses[msg.sender][_locationInArray];
        businesses[_newOwner].push(addressToMove);
    }
    
    // would like to include with inheretence as well, however, this contract doesn't have any state with regard
    //    to any ERC20 tokens, again none should ever be sent here, but just in case:
    function emergencyWithdrawErc20(address _addressOfCoin, uint _amount,  address _sendTo) public onlyBy(owner){
        IERC20 coin = IERC20(_addressOfCoin);
        safeTransfer(coin,_sendTo, _amount);
    }
}