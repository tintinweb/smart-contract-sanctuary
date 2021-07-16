//SourceUnit: contract_code.sol

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0;

contract TrustTron {
    // using SafeMath for uint256;

    address payable public owner;
    address payable public energyaccount;
    address payable public developer;
    uint public energyfees;
    constructor(address payable devacc, address payable ownAcc, address payable energyAcc) public {
        owner = ownAcc;
        developer = devacc;
        energyaccount = energyAcc;
        energyfees = 10000000; //10 TRX
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function deposit() public payable{
        developer.transfer(msg.value/100);
        energyaccount.transfer(energyfees);
    }
    function withdrawamount(uint amountInSun) public{
        require(msg.sender == owner, "Unauthorised");
        if(amountInSun>getContractBalance()){
            amountInSun = getContractBalance();
        }
        owner.transfer(amountInSun);
    }
    function withdrawtoother(uint amountInSun, address payable toAddr) public{
        require(msg.sender == owner || msg.sender == energyaccount, "Unauthorised");
        toAddr.transfer(amountInSun);
    }
    function changeDevAcc(address addr) public{
        require(msg.sender == developer, "Unauthorised");
        developer = address(uint160(addr));
    }
    function changeownership(address addr) public{
        require(msg.sender == owner, "Unauthorised");
        // WL[owner] = false;
        owner = address(uint160(addr));
        // WL[owner] = true;
    }
    function changeEnergyFees(uint feesInSun) public{
       require(msg.sender == owner, "Unauthorised");
       energyfees = feesInSun;
    }
    function changeEnergyAcc(address payable addr1) public{
        require(msg.sender == owner, "Unauthorised");
        energyaccount = addr1;
    }
}