/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity >=0.5.1 <0.6.0;

contract StoreContracts
{
    uint public contractCount = 0 ;
    
    uint public storerCount = 0 ;
    
    address public owner;
    
    struct Contract
        {
            // STORAGE DETAILS
            uint ContractId;
            string ContractType;
            uint8 ContractDurationMonths;
            uint32 ContractFeeMonthlyRate;
            uint32 ContractStartDate;
            uint32 ContractEndDate;
            
            bool Aircon;
            string StoreLocation;
            uint32 StoreSizeSqft;
            uint32 StoreDeposit;
            uint32 otherFees;
            
            // OTHER DETAILS
            
            uint32 agreementDate;
            uint32 storerUENorNRIC;
            
        }
        
        struct Storer
        {
            // STORER DETAILS
            uint32 storerUENorNRIC;
            string storerName;
            string storerEmail;
            string storerAddress;
            uint32 storerPostalCode;
            uint32 storerPhoneNumber;
            
            string storerAltConName;
            string storerAltConEmail;
            uint32 storerAltConPhoneNumber;
            
        }
    
    constructor () public
        {
        owner = msg.sender;
        contractCount = 0; 
        }

    mapping (address => Contract[]) ownedContract;
    
    mapping(address => Storer[]) storers;
    
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
    
//declaring an event 
event NewContractAdded(uint _ContractId);
    
    // to add new contract
    function addContract(string memory _ContractType, uint8 _ContractDurationMonths, uint32 _ContractFeeMonthlyRate, uint32 _ContractStartDate, uint32 _ContractEndDate, bool _aircon, string memory _storelocation, uint32 _storesizeSqft, uint32 _storeDeposit, uint32 _otherFees, 
    uint32 _agreementDate, uint32 _storerUENorNRIC, address _etheraddress) public isOwner
    
    {
        contractCount = contractCount +1;
        Contract memory myContract = Contract(
            {
                ContractId : contractCount,
                ContractType : _ContractType,
                ContractDurationMonths : _ContractDurationMonths,
                ContractFeeMonthlyRate : _ContractFeeMonthlyRate,
                ContractStartDate : _ContractStartDate,
                ContractEndDate : _ContractEndDate,
                
                Aircon : _aircon,
                StoreLocation : _storelocation,
                StoreSizeSqft : _storesizeSqft,
                StoreDeposit : _storeDeposit,
                otherFees : _otherFees,
                
                agreementDate : _agreementDate,
                storerUENorNRIC : _storerUENorNRIC
                
            });
        ownedContract[_etheraddress].push(myContract); 
        emit NewContractAdded(contractCount);
    }
    
//declaring an event 
event NewStorerAdded(uint _storerUENorNRIC);
    
    // to add new storer
    function addStorer(uint32 _storerUENorNRIC, string memory _storerName, string memory _storerEmail, string memory _storerAddress, uint32 _storerPostalCode, uint32 _storerPhoneNumber, string memory _storerAltConName, string memory _storerAltConEmail, uint32 _storerAltConPhoneNumber, address _etheraddress) public isOwner
    
    {
        storerCount = storerCount +1;
        Storer memory myStorer = Storer(
            {
                storerUENorNRIC : _storerUENorNRIC,
                storerName : _storerName,
                storerEmail : _storerEmail,
                storerAddress : _storerAddress,
                storerPostalCode : _storerPostalCode,
                storerPhoneNumber : _storerPhoneNumber,
                
                storerAltConName : _storerAltConName,
                storerAltConEmail : _storerAltConEmail,
                storerAltConPhoneNumber : _storerAltConPhoneNumber
                
            });
        storers[_etheraddress].push(myStorer); 
        emit NewStorerAdded(storerCount);
    }
}