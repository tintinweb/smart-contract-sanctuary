/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.8.4;

contract Collateralized_Service_Tourism
{
    //------------------------------------------------------------------------
    
    // Variables at Launch
    string companyName;
    address contractAdmin;
    address contractOracle;
    uint idCounter = 0;
    uint collateralPercentage = 120;
    uint complaintNumber = 0;
    uint[] complaints;
    uint salary = 0.01 ether;
    
    //------------------------------------------------------------------------   
    
    // Constructor
    constructor(address _contractOracle, string memory _companyName){
        contractAdmin = msg.sender;
        contractOracle = _contractOracle;
        companyName = _companyName;
    }
    
    //------------------------------------------------------------------------
    
    // Structures
    struct tripDataFull{
        string companyName;
        uint tripId;
        address clientAddress;
        uint employeeId;
        uint price;
        uint amountRemaining;
        bool payed;
        bool taken;
        uint collPercentage;
        bytes32 contractHash;
        uint complaint;
        uint Deadline; // Deadline to complain (as seconds since unix epoch)
    }
    
    tripDataFull[] public data;
   
    //------------------------------------------------------------------------
    
    // Modifiers
    modifier onlyAdmin{
        require (msg.sender==contractAdmin);
        _;
    }
    
    modifier onlyPersonnel (uint _employeeId){
        require (msg.sender==employeeIdToEmployeeAddress[_employeeId] || msg.sender==contractAdmin);
        _;
    }
    
    modifier onlyOracle{
        require (msg.sender==contractOracle);
        _;
    }
    
    //------------------------------------------------------------------------
    
    // Mapppings
    mapping (uint => address) public employeeIdToEmployeeAddress;
    mapping (uint => address) public tripIdToPersonnelAddress;

    //------------------------------------------------------------------------
    
    // Functions for Admin
    function Change_Admin (address _newAdmin) private onlyAdmin{
       contractAdmin = _newAdmin;
    }

    // Functions for Personnel
    function Create_Personnel (address _newPersonnelAddress, uint _employeeId) private onlyAdmin{
       employeeIdToEmployeeAddress[_employeeId] = _newPersonnelAddress;
    }
    
    function Remove_Personnel (uint _employeeId) private onlyAdmin{
       delete employeeIdToEmployeeAddress[_employeeId];
    }
    
    //------------------------------------------------------------------------
    
    // Functions for Oracle
    
    function Change_Oracle (address _newOracle) private onlyOracle{
        contractOracle = _newOracle;
    }
    
    function Change_Percentage (uint _newPercentage) private onlyOracle{
        collateralPercentage = _newPercentage;
    }

    function Get_Complaints () private onlyOracle view returns(uint[] memory){
        return(complaints);
    }
    
    function Get_Case_Data (uint _tripId) private onlyOracle view returns(uint _price, uint _collPercentage, bytes32 _contractHash){
        return(data[_tripId].price, data[_tripId].collPercentage, data[_tripId].contractHash);
    }
    
    function Judgement (uint _tripId, uint _compensation, bool _accepted) public payable onlyOracle{
        require(_compensation >= 0);
        
        // if the Complaint is Accepted ,the client receives _compensation >0 (includes extra for GAS), and doesn't pay salary
        // if the Complaint is Denied, the client receives _compensation = 0, and the Client pays salary
        if (_accepted == true){
            payable(data[_tripId].clientAddress).transfer(_compensation+salary); 
        }

        complaints[complaintNumber] = 0;
        data[_tripId].complaint = 0;
        payable(msg.sender).transfer(salary);
    }

    //------------------------------------------------------------------------
    
    // Functions for Trips
    function Create_Trip (address _clientAddress, uint _price, bytes32 _contractHash, uint _employeeId, uint _deadline) public onlyPersonnel(_employeeId){
        address _personnelAddress = msg.sender;
        idCounter += 1;
        tripIdToPersonnelAddress[idCounter] = _personnelAddress;
        data.push(tripDataFull(companyName,idCounter,_clientAddress,_employeeId,_price,_price,false,false,collateralPercentage,_contractHash,0,_deadline));
    }
    
    function Check_Amount_Remaining (uint _tripId) public view returns(uint _result){
        require(msg.sender == data[_tripId].clientAddress);
        _result = data[_tripId].amountRemaining;
    }
    
    function Pay_Trip (uint _tripId) public payable{
        require(msg.sender == data[_tripId].clientAddress);
        require(msg.value <= data[_tripId].amountRemaining);
        if(data[_tripId].amountRemaining==0){
            data[_tripId].payed = true;
        }
    }
    
    function Take_Capital(uint _tripId, uint _employeeId) public payable onlyPersonnel(_employeeId){
        require(msg.value == data[_tripId].price*data[_tripId].collPercentage/100);
        // Interact with AAVE or Yearn (or other options) to invest Collateral
        payable(msg.sender).transfer(data[_tripId].price);
        data[_tripId].taken = true;
    }
    
    function Complain (uint _tripId) public payable{
        require(msg.sender == data[_tripId].clientAddress);
        require(msg.value == salary);
        data[_tripId].complaint = 1;
        complaints[complaintNumber] = _tripId;
        complaintNumber += 1;
    }
    
    function Take_Collateral(uint _tripId, uint _employeeId) public payable onlyPersonnel(_employeeId){
        require(data[_tripId].complaint == 0);
        require(block.timestamp >= block.timestamp);
        payable(msg.sender).transfer(data[_tripId].price*data[_tripId].collPercentage/100);
    }

    //------------------------------------------------------------------------
    
}