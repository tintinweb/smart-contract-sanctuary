/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Insurance {
    // Owner of the system
    address public owner;
    
    // Hospital in system
    mapping(address => address) _nextHospital;
    uint256 private hospitalListSize;
    address constant GUARD = address(1);
    
    // Customers in system
    mapping(address => address) _nextCustomer;
    uint256 private customerListSize;
    address constant CUSTOMERGUARD = address(1);
    
    // Customer claimed in system
    mapping(address => address) _nextCustomerClaimed;
    uint256 private customerClaimedListSize;
    address constant CUSTOMERCLAIMEDGUARD = address(1);
    
    // Events - publicize actions to external listeners
    event BuyInsuranceMade(address indexed customerAddress, uint amount);
    event ClaimInsuranceMade(address indexed hospitalAddress, address indexed customerAddress, uint amount);
    
    event SystemDepositMade(address indexed admin, uint amount);
    event SystemWithdrawMade(address indexed admin, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor() {
        // msg provides details about the message that's sent to the contract
        // msg.sender is contract caller (address of contract creator)
        owner = msg.sender;
        _nextHospital[GUARD] = GUARD;
        _nextCustomer[CUSTOMERGUARD] = CUSTOMERGUARD;
        _nextCustomerClaimed[CUSTOMERCLAIMEDGUARD] = CUSTOMERCLAIMEDGUARD;
    }
    
    // **************************************************************************************
    
    // Hospital
    
    /// @notice Is Hospital
    /// @param hospital address of hospital
    function isHospital(address hospital) private view returns (bool) {
        return _nextHospital[hospital] != address(0);
    }
    
    /// @notice Get previous hospital
    /// @param hospital address of hospital
    function _getPrevHospital(address hospital) internal view returns (address) {
        address currentAddress = GUARD;
        while(_nextHospital[currentAddress] != GUARD) {
            if (_nextHospital[currentAddress] == hospital) {
                return currentAddress;
            }
            currentAddress = _nextHospital[currentAddress];
        }
        return address(0);
    }
    
    /// @notice Get hospital length in hospitalListSize
    function getHospitalListCount() public view returns (uint256) {
        return hospitalListSize;
    }
    
    /// @notice Get hospital in hospitalListSize
    /// @param indexAt index of hospitalListSize
    function getHospital(uint256 indexAt) public view returns (address) {
        require(owner == msg.sender, "You are not authorized.");
        address[] memory hospital = new address[](hospitalListSize);
        address currentAddress = _nextHospital[GUARD];
        for(uint256 i = 0; currentAddress != GUARD; ++i) {
            hospital[i] = currentAddress;
            currentAddress = _nextHospital[currentAddress];
        }
        return hospital[indexAt];
    }
    
    /// @notice Add hospital
    /// @param hospital address of hospital
    function addHospital(address hospital) public {
        require(owner == msg.sender, "You are not authorized.");
        require(!isCustomer(hospital), "System found this address is customer in system.");
        require(!isHospital(hospital), "Hospital is exist.");
        _nextHospital[hospital] = _nextHospital[GUARD];
        _nextHospital[GUARD] = hospital;
        hospitalListSize++;
    }
    
    /// @notice Add hospital using array of hospital
    /// @param hospitalList array of hospital address
    function addHospitalList(address[] memory hospitalList) public {
        require(owner == msg.sender, "You are not authorized.");
        for (uint256 i=0; i < hospitalList.length; i++) {
            if (!isHospital(hospitalList[i])) {
                addHospital(hospitalList[i]);
            }
        }
    }
    
    /// @notice Remove hospital
    /// @param hospital address of hospital
    function removeHospital(address hospital) public {
        require(isHospital(hospital), "Hospital not found.");
        address prevHospital = _getPrevHospital(hospital);
        _nextHospital[prevHospital] = _nextHospital[hospital];
        _nextHospital[hospital] = address(0);
        hospitalListSize--;
    }
    
    // **************************************************************************************
    
    // Customer 

    /// @notice Is customer
    /// @param customer address of customer
    function isCustomer(address customer) private view returns (bool) {
        return _nextCustomer[customer] != address(0);
    }
    
    /// @notice Get customer
    /// @param customer address of customer
    function getCustomer(address customer) public view returns (bool) {
        require(owner == msg.sender || isHospital(msg.sender), "This function for only admin or hospital.");
        return _nextCustomer[customer] != address(0);
    }
    
    /// @notice Add customer
    /// @param customer address of customer
    function addCustomer(address customer) private {
        _nextCustomer[customer] = _nextCustomer[CUSTOMERGUARD];
        _nextCustomer[CUSTOMERGUARD] = customer;
        customerListSize++;
    }
    
    /// @notice Buy Insurance
    function buyInsurance() public payable {
        require(!isHospital(msg.sender), "Hospital can't buy insurance.");
        
        require(!isCustomerClaimed(msg.sender), "Customer already claimed insurance before.");

        uint priceOfInsturance = 10000000000000;
        require(msg.value >= priceOfInsturance, "Price require 0.00001 ETH or more.");
        require(!isCustomer(msg.sender), "Customer already exist.");
        
        // return money when receive more priceOfInsturance
        uint moneyToReturn = msg.value - priceOfInsturance;
        
        // add customer in system 
        addCustomer(msg.sender);
        
        // Broadcast deposit event
        emit BuyInsuranceMade(msg.sender, msg.value); // fire event
        
        if (moneyToReturn > 0) {
            payable(msg.sender).transfer(moneyToReturn);
        }
    }
    
    // **************************************************************************************

    // Claim Insurance
    
    /// @notice Is customer
    /// @param customer address of customer
    function isCustomerClaimed(address customer) private view returns (bool) {
        return _nextCustomerClaimed[customer] != address(0);
    }
    
    /// @notice Get customer
    /// @param customer address of customer
    function getCustomerClaimed(address customer) public view returns (bool) {
        require(owner == msg.sender || isHospital(msg.sender), "This function for only admin or hospital.");
        return _nextCustomerClaimed[customer] != address(0);
    }
    
    /// @notice Add customer
    /// @param customer address of customer
    function addCustomerClaimed(address customer) private {
        _nextCustomerClaimed[customer] = _nextCustomerClaimed[CUSTOMERGUARD];
        _nextCustomerClaimed[CUSTOMERGUARD] = customer;
        customerListSize++;
    }
    
    /// @notice Claim Insurance
    /// @param customer address of customer
    function claimInsurance(address customer) public {
        require(isHospital(msg.sender), "This function for only hospital or Hospital not found.");
        
        require(!isCustomerClaimed(customer), "Customer already claimed insurance before.");
        require(isCustomer(customer), "Customer not found.");
        
        uint moneyForClaim = 100000000000000;
        require(systemBalance() >= moneyForClaim, "System balance is not enough.");
        
        // add customer claimed in system
        addCustomerClaimed(customer);
        
        // send money to customer
        payable(customer).transfer(moneyForClaim);
        
        // Broadcast withdraw event
        emit ClaimInsuranceMade(msg.sender, customer, moneyForClaim);
    }
    
    // **************************************************************************************
    
    /// @notice Insurance system balance
    /// @return Balances of all users combined
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    /// @notice Deposit ether into system
    /// @return The balance of the user after the deposit is made
    function systemDeposit() public payable returns (uint256) {
        require(owner == msg.sender, "You are not authorized.");

        // Broadcast deposit event
        emit SystemDepositMade(msg.sender, msg.value); // fire event

        return systemBalance();
    }
    
    /// @notice Withdraw ether from the system
    /// @param withdrawAmount amount you want to withdraw
    /// @return remainingBalance The balance remaining for the system
    function systemWithdraw(uint withdrawAmount) public returns (uint256 remainingBalance) {
        require(owner == msg.sender, "You are not authorized.");
        require(systemBalance() >= withdrawAmount, "System balance is not enough.");

        // Revert on failed
        payable(msg.sender).transfer(withdrawAmount);
        
        // Broadcast system withdraw event
        emit SystemWithdrawMade(msg.sender, withdrawAmount);
        
        return systemBalance();
    }
}