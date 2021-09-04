/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

contract RentContract is ReentrancyGuard {

    struct rentInfo {
        bool isOccupied;
        address tenant;
        bool opPayed;
        uint256 opDaysLeft;
        uint256 opAmountLeft;
        uint256 paymentDate;
        uint256 area;
        uint256 monthlyPrice;
    }

    address public owner;
    address payable public landlord;
    
    // user balances
    mapping(address => uint256) public balances;
    
    // rent contracts inforamtion
    rentInfo[] public rentContracts; 

    modifier onlyOwner {
        require(msg.sender == owner, "Only for owner");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == owner || msg.sender == landlord, "Only for governance");
        _;
    }

    constructor(address payable _landlord) {
        owner = msg.sender;
        landlord = _landlord;
    }
    
    receive() external payable {}
    fallback() external payable {}
    
    function createRentContract (rentInfo memory _info) public onlyGovernance {
        rentContracts.push(_info);
    }

    function editRentContract (rentInfo memory _newInfo, uint256 _contractId) public onlyGovernance {
        rentContracts[_contractId] = _newInfo;
    }

    function deleteRentContract (uint256 _contractId) public onlyGovernance returns (rentInfo[] memory) {
        require(_contractId < rentContracts.length, "Wrong id");
        
        uint256 last = rentContracts.length-1;

        rentContracts[_contractId] = rentContracts[last];
        delete rentContracts[last];
        
        return rentContracts;
    }

    function signContract(uint256 _contractId, bool _payOpNow, uint8 _today) public onlyGovernance payable nonReentrant {
        rentInfo memory _rentInfo = rentContracts[_contractId];
        require(!_rentInfo.isOccupied, "This lot is already occupied");
        
        uint256 OP = _rentInfo.monthlyPrice * 3;
        
        if (_payOpNow) {
            // 100% предоплата
            require(msg.value >= OP, "Wrong rent payment value");
            
            payable(address(this)).transfer(OP);
            balances[msg.sender] += msg.value - OP;
        
            _rentInfo.paymentDate = _today;
            _rentInfo.opPayed = true;
            
        } else {
            _rentInfo.paymentDate = _today;
            _rentInfo.opDaysLeft = 10;
            _rentInfo.opAmountLeft = OP;
            
        }
        _rentInfo.isOccupied = true;
        _rentInfo.tenant = msg.sender;
        
        rentContracts[_contractId] = _rentInfo;
    }
    
    function payOffOp(uint256 _contractId) public nonReentrant {
        rentInfo memory _rentInfo = rentContracts[_contractId];
        
        require(_rentInfo.isOccupied, "Contract isnt signed");
        require(!_rentInfo.opPayed, "Op already payed off");
        require(_rentInfo.tenant == msg.sender, "Not your contract");
        require(balances[msg.sender] >= _rentInfo.opAmountLeft, "Insufficient balance");
        
        balances[msg.sender] -= _rentInfo.opAmountLeft;
        
        _rentInfo.opAmountLeft = 0;
        _rentInfo.opPayed = true;
        _rentInfo.opDaysLeft = 0;
        
        rentContracts[_contractId] = _rentInfo;
    }
    
    function terminateContract(uint256 _contractId) public {
        rentInfo memory _rentInfo = rentContracts[_contractId];
        require(_rentInfo.tenant == msg.sender && _rentInfo.isOccupied, "Not tenant or unsigned contract");
        
        _rentInfo.isOccupied = false;
        _rentInfo.tenant = address(0);
        _rentInfo.paymentDate = 0;
        
        rentContracts[_contractId] = _rentInfo;
    }
    
    function writeOffRent(uint256 _contractId) public onlyGovernance returns (uint256) {
        rentInfo memory _rentInfo = rentContracts[_contractId];
        address tenant = _rentInfo.tenant;  
        uint256 monthlyPayment = _rentInfo.monthlyPrice;
        
        require(balances[tenant] >= monthlyPayment, "Insufficient balance");

        balances[tenant] -= monthlyPayment;
        return balances[tenant];
    }
    
    function deposit(address _to) public payable nonReentrant {
        require(msg.value > 0, "Zero deposit");
        require(_to != address(0) && _to != address(this), "Wrong address");
        
        payable(address(this)).transfer(msg.value);
        
        balances[_to] += msg.value;
    }
    
    function setBalance(address _user, uint256 _value) public onlyGovernance {
        balances[_user] = _value;
    } 
    
    function withdraw(address _to, uint256 _amount) public payable onlyGovernance { 
        require(_amount > 0, "Zero withdrawal");
        require(_to != address(0) && _to != address(this), "Wrong address");
        
        payable(address(_to)).transfer(_amount);
    }
}