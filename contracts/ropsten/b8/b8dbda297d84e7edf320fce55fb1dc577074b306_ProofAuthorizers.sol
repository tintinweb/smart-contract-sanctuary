pragma solidity >=0.5.0 <0.6.0;

import "./ECVerify.sol";

/**
 * @title The Proof Authorizers Contract
 * @author WalletSocket Inc. -- Tezan Sahu
 * @dev The contract to store information about the validators of IPFS proofs for different
 *      security tokens that would be used in WalletSocket & validate the proof signing authorities
 **/

 contract ProofAuthorizers{
    address public owner;
    ECVerify verifier;
    
    // Struct to store details about old addresses owned by a company
    struct companyAddrDetails{
        string docHash;                                  // IPFS hash of document stating that company owns the pubKey
        uint256 startDate;                               // Timestamp when the company&#39;s address was started to be used
        uint256 endDate;                                 // Timestamp when the company&#39;s address was discared
    }
    
    // Struct to store details about old addresses owned by an individual
    struct indivAddrDetails{
        string docHash;                                  // IPFS hash of document stating that individual owns the pubKey
        address companyPubAddr;                          // Old company address of company that the individual works for
        bytes companySign;                               // Signature of company on the docHash using pvtKey of above company address
        uint256 startDate;                               // Timestamp when the individual&#39;s address was started to be used
        uint256 endDate;                                 // Timestamp when the individual&#39;s address was discared
    }
    
    // Struct to store details about the current address owned by an individual
    struct Individual{
        string name;                                    // Name of the individual
        address pubAddr;                                // Current public address of individual
        string docHash;                                 // IPFS hash of document stating that individual owns the pubKey
        address companyPubAddr;                         // CompanyId of current company that the individual works for
        bytes companySign;                              // If an employee, company&#39;s sign on the docHash
        uint256 startDate;                              // Datefrom which the individual started using the current public key
    }
    
    // Struct to store details about the current address owned by a company
    struct Company{
        string name;                                    // Name of  the company
        address pubAddr;                                // Current public address of company
        string docHash;                                 // IPFS hash of document stating that individual owns the pubKey
        uint256 startDate;
    }
    
    mapping (bytes32 => Company) public companies;                                                   // Mapping from companyId to Company
    mapping (address => bytes32) public addressToCompany;                                            // Mapping from address to owner company
    mapping (bytes32 => mapping(address => companyAddrDetails)) public addressesOfCompany;           // Mapping from companyId to all old addresses details of company 

    mapping (bytes32 => Individual) public individuals;                                              // Mapping from individualId to Individual
    mapping (address => bytes32) public addressToIndiv;                                              // Mapping from address to owner individual
    mapping (bytes32 => mapping(address => indivAddrDetails)) public addressesOfIndiv;               // Mapping from individualId to all old addresses details of individual
                                                                    
    
    event CompanyAdded(string name, bytes32 indexed id, address indexed pubAddr, string docHash, uint256 timestamp);
    // event CompanyRemoved(string name, address indexed pubAddr, bytes docHash);
    // event CompanyPubKeyUpdated(string name, bytes32 indexed id, address indexed newPubAddr, uint256 timestamp);


    event IndividualAdded(string name, bytes32 indexed id, address indexed pubAddr, string docHash, bytes32 companyId, uint256 timestamp);
    // event IndividualRemoved(string name, bytes32 indexed id, address indexed pubAddr, string docHash);
    // event IndividualPubKeyUpdated(string name, bytes32 indexed id, address indexed newPubAddr, uint256 timestamp);

    
    // event EmployeeAdded(string name, bytes32 indexed id, address indexed pubAddr, string docHash, bytes32 companyId, uint256 timestamp);
    // event EmployeePubKeyUpdated(string name, bytes32 indexed id, address indexed newPubAddr, uint256 timestamp);
    // event EmployeeRemoved(string name, bytes32 indexed id, address indexed pubAddr, string docHash, bytes32 companyId);
    
    constructor(address verifierAddr) public {
        require(verifierAddr != address(0));
        owner = msg.sender;
        verifier = ECVerify(verifierAddr);
    }
    
    modifier onlyContractOwner() {
        require(msg.sender == owner, "Caller is not the owner of contract");
        _;
    }
    
    /**
     * @dev Function that adds a new company as a valid authorizer
     * @param _name Name of the company
     * @param _pubAddr Ethereum address of the company
     * @param _docHash IPFS hash of the document serving as a proof that the company owns &#39;_pubAddr&#39;
     * @return Unique companyID for the company
     */
    function addCompany(string calldata _name, address _pubAddr, string calldata _docHash) external onlyContractOwner returns (bytes32) {
        require(addressToCompany[_pubAddr] == bytes32(0) && addressToIndiv[_pubAddr] == bytes32(0), "Address is already in use");
        uint256 currentTime = uint256(now);
        bytes32 id = keccak256(abi.encodePacked(_name, _pubAddr, currentTime));
        companies[id] = Company({name: _name, pubAddr: _pubAddr, docHash: _docHash, startDate: currentTime});
        addressToCompany[_pubAddr] = id;
        
        emit CompanyAdded(_name, id, _pubAddr, _docHash, currentTime);
        return id;
    }
    
    /**
     * @dev Function that updates the public key of an existing company
     * @param companyId Unique ID of the company
     * @param pubAddr New Ethereum address of the company
     * @param docHash IPFS hash of the new document serving as a proof that the company owns &#39;pubAddr&#39;
     */
    function updateCompanyAddress(bytes32 companyId, address pubAddr, string memory docHash) public {
        require(msg.sender == owner || msg.sender == companies[companyId].pubAddr, "Only contract owner or company can call this function");
        require(companies[companyId].pubAddr != address(0), "Company does not exist");
        require(pubAddr != companies[companyId].pubAddr, "New address cannot be same as old one");
        // require(pubAddr != address(0), "Address cannot be null");
        
        require(addressToCompany[pubAddr] == bytes32(0) && addressToIndiv[pubAddr] == bytes32(0), "Address is already in use");
        if(pubAddr == address(0)){
            require(keccak256(bytes(docHash)) == keccak256(bytes("")), "If address is null, docHash must be null");
        }
        uint256 currentTime = uint256(now);
        
        addressesOfCompany[companyId][companies[companyId].pubAddr] = companyAddrDetails({
            docHash: companies[companyId].docHash,
            startDate: companies[companyId].startDate,
            endDate: currentTime
        });
    
        addressToCompany[pubAddr] = companyId;                // Store that the new public key corresponds to the companyId
        companies[companyId].docHash = docHash;               // Replace the old document hash with the new one
        companies[companyId].pubAddr = pubAddr;               // Replace the old public key with the new one
        companies[companyId].startDate = currentTime;
    }
    
    /**
     * @dev Function that adds a new employee of a company as a valid authorizer
     * @param _name Name of the employee
     * @param _pubAddr Ethereum address of the employee
     * @param _docHash IPFS hash of the document serving as a proof that the employee owns &#39;_pubAddr&#39;
     * @param _companyId Company for which the individual works for
     * @param _companySign Signature obtained when the company signs the above &#39;_docHash&#39; claiming that
     * it attests that fact that the employee is a valid employee of that company
     * @return Unique ID for the employee
     */
    function addEmployee(string calldata _name, address _pubAddr, string calldata _docHash, bytes32 _companyId, bytes calldata _companySign) external returns (bytes32){
        require(msg.sender == owner || msg.sender == companies[_companyId].pubAddr, "Only contract owner or company can call this function");
        require(companies[_companyId].pubAddr != address(0), "Company does not exist");
        require(addressToCompany[_pubAddr] == bytes32(0) && addressToIndiv[_pubAddr] == bytes32(0), "Address is already in use");
        require(_verifySign(_docHash, companies[_companyId].pubAddr, _companySign), "Invalid Signature");
        uint256 currentTime = uint256(now);
        bytes32 indivId = keccak256(abi.encodePacked(_name, _pubAddr, _companyId, currentTime));
        
        individuals[indivId] = Individual({name:_name,
            pubAddr:_pubAddr, 
            docHash:_docHash, 
            companyPubAddr:companies[_companyId].pubAddr, 
            companySign:_companySign, 
            startDate: currentTime
        });
        addressToIndiv[_pubAddr] = indivId;
        
        emit IndividualAdded(_name, indivId, _pubAddr, _docHash, _companyId, currentTime);
        
        return indivId;
    }
    
    /**
     * @dev Function that updates address of an existing employee
     * @param indivId Unique ID of the employee
     * @param pubAddr New Ethereum address of the employee
     * @param docHash IPFS hash of the new document serving as a proof that the employee owns &#39;pubAddr&#39;
     * @param companySign Signature obtained when the company signs the above &#39;_docHash&#39; claiming that
     * it attests that fact that the employee is a valid employee of that company
     */
    function updateEmployeeAddress(bytes32 indivId, address pubAddr, string memory docHash, bytes memory companySign) public {
        require(msg.sender == owner || msg.sender == companies[addressToCompany[individuals[indivId].companyPubAddr]].pubAddr || msg.sender == individuals[indivId].pubAddr, "Only owner, company or individual can update public key");
        require(individuals[indivId].pubAddr != address(0), "Individual does not exist");
        require(addressToCompany[pubAddr] == bytes32(0) && addressToIndiv[pubAddr] == bytes32(0), "Address is already in use");
        
        if(pubAddr == address(0)){
            require(keccak256(bytes(docHash)) == keccak256(bytes("")), "If address is null, docHash must be null");
            require(keccak256(companySign) == keccak256(bytes("")), "If address is null, companySign must be null");
        }
        
        
        uint256 currentTime = uint256(now);
        
        addressesOfIndiv[indivId][individuals[indivId].pubAddr] = indivAddrDetails({
            docHash: individuals[indivId].docHash,
            companyPubAddr: individuals[indivId].companyPubAddr,
            companySign: individuals[indivId].companySign,
            startDate: individuals[indivId].startDate,
            endDate: currentTime
        });
        if(pubAddr != address(0)){
            addressToIndiv[pubAddr] = indivId;    
        }
        
        individuals[indivId].pubAddr = pubAddr;
        individuals[indivId].docHash = docHash;
        individuals[indivId].companySign = companySign;
        individuals[indivId].startDate = currentTime;
    }
    
    
    /**
     * @dev Function that adds a new individual as a valid authorizer
     * @param _name Name of the individual
     * @param _pubAddr Ethereum address of the individual
     * @param _docHash IPFS hash of the document serving as a proof that the individual owns &#39;_pubAddr&#39;
     * @return Unique ID for the individual authorizer
     */
    function addIndividual(string calldata _name, address _pubAddr, string calldata _docHash) external onlyContractOwner returns(bytes32){
        require(addressToCompany[_pubAddr] == bytes32(0) && addressToIndiv[_pubAddr] == bytes32(0), "Address is already in use");
        
        uint256 currentTime = uint256(now);
        bytes32 indivId = keccak256(abi.encodePacked(_name, _pubAddr, currentTime));
        
        individuals[indivId] = Individual({
            name:_name,
            pubAddr:_pubAddr,
            docHash:_docHash,
            companyPubAddr:address(0),
            companySign: "0x",
            startDate: currentTime
        });
        addressToIndiv[_pubAddr] = indivId;
        
        emit IndividualAdded(_name, indivId, _pubAddr, _docHash, bytes32(0), currentTime);
        
        return indivId;
    }
    
    /**
     * @dev Function that updates address of an existing individual
     * @param indivId Unique ID of the individual
     * @param pubAddr New Ethereum address of the individual
     * @param docHash IPFS hash of the new document serving as a proof that the individual owns &#39;pubAddr&#39;
     */
    function updateIndividualAddress(bytes32 indivId, address pubAddr, string memory docHash) public  {
        require(msg.sender == owner || msg.sender == individuals[indivId].pubAddr, "Only owner or individual can update public address");
        require(individuals[indivId].pubAddr != address(0), "Individual does not exist");
        require(addressToCompany[pubAddr] == bytes32(0) && addressToIndiv[pubAddr] == bytes32(0), "Address is already in use");
        
        if(pubAddr == address(0)){
            require(keccak256(bytes(docHash)) == keccak256(bytes("")), "If address is null, docHash must be null");
        }
        
        uint256 currentTime = uint256(now);
        
        addressesOfIndiv[indivId][individuals[indivId].pubAddr] = indivAddrDetails({
            docHash: individuals[indivId].docHash,
            companyPubAddr: individuals[indivId].companyPubAddr,
            companySign: individuals[indivId].companySign,
            startDate: individuals[indivId].startDate,
            endDate: currentTime
        });
        
        if(pubAddr != address(0)){
            addressToIndiv[pubAddr] = indivId;    
        }
        
        individuals[indivId].pubAddr = pubAddr;
        individuals[indivId].docHash = docHash;
        individuals[indivId].companySign = bytes("0x");
        individuals[indivId].startDate = currentTime;
    }

    /**
     * @dev Function to validate IPFS proofs of security tokens authorized by different entities (comes from SecurityToken contract)
     * @param proofHash IPFS proof hash stating that an entity owns a security token
     * @param pubAddr Ethereum address of the authorizer who authorized the above &#39;proofHash&#39;
     * @param proofSign Signature obtained when the authorizer signs the above &#39;proofHash&#39; claiming that
     * it attests that fact that the entity is the rightful owner of the security token
     * @param proofTimestamp Timestamp at which the proofHash was signed and uploaded to the SecurityToken contract
     * @return Boolean indicating whether or not the proof of ownership is valid
     */
    function validateProof(string memory proofHash, address pubAddr, bytes memory proofSign, uint256 proofTimestamp) public view returns (bool) {
        require(_verifySign(proofHash, pubAddr, proofSign), "Invalid Signature");
        if(addressToCompany[pubAddr] != bytes32(0)){
            return _checkValidCompany(proofTimestamp, pubAddr);
        }
        else if (addressToIndiv[pubAddr] != bytes32(0)){
            return _checkValidIndiv(proofTimestamp, pubAddr);
        }
        else{
            return false;
        }
    }
    
    /**
     * @dev Internal function to check if the company that the ownership/employee proof points to is valid or not
     * @param proofTimestamp UNIX timestamp at the time of uploading the signed proof
     * @param companyAddress Ethereum address of the company pointed to by the ownership/employee proof
     * @return Boolean whether or not the company being pointed to is a valid authorizer
     */
    function _checkValidCompany(uint256 proofTimestamp, address companyAddress) internal view returns(bool){
        require(addressToCompany[companyAddress] != bytes32(0), "Invalid Authorizer Company Address");
        
        bytes32 companyId = addressToCompany[companyAddress];
        // If the company&#39;s current address is same as that while signing the proof, verify the proof timestamp
        if(companies[companyId].pubAddr == companyAddress){
            require(companies[companyId].startDate <= proofTimestamp, "Invalid proof timestamp for current company address");
                return true;
        }
        else{
            // Check whether or not the timestamp lies in the range that the company owned the old address
            require(addressesOfCompany[companyId][companyAddress].startDate <= proofTimestamp &&
             addressesOfCompany[companyId][companyAddress].endDate >= proofTimestamp, "Invalid proof timestamp for old company address");
            return true;
        }
    }
    
    /**
     * @dev Internal function to check if the individual that the ownership proof points to is valid or not
     * @param proofTimestamp UNIX timestamp at the time of uploading the signed proof
     * @param indivAddress Ethereum address of the individual pointed to by the ownership proof
     * @return Boolean whether or not the individual being pointed to is a valid authorizer
     */
    function _checkValidIndiv(uint256 proofTimestamp, address indivAddress) internal view returns (bool) {
        require(addressToIndiv[indivAddress] != bytes32(0), "Invalid Authorizer Address");
        bytes32 indivId = addressToIndiv[indivAddress];
        // If the individual&#39;s current address is same as that while signing the proof, verify the proof timestamp
        if(individuals[indivId].pubAddr == indivAddress){
            require(individuals[indivId].startDate <= proofTimestamp, "Invalid proof timestamp for current individual address");
            // If the individual is an employee of a company, check that the proof of his employment is valid or not
            if(individuals[indivId].companyPubAddr != address(0)){
                require(_verifySign(individuals[indivId].docHash, individuals[indivId].companyPubAddr, individuals[indivId].companySign), "Invalid company authorization of individual");
                return _checkValidCompany(individuals[indivId].startDate, individuals[indivId].companyPubAddr);
            }
            return true;
        }
        else{
            // Check whether or not the timestamp lies in the range that the individual owned the old address
            require(addressesOfIndiv[indivId][indivAddress].startDate <= proofTimestamp &&
             addressesOfIndiv[indivId][indivAddress].endDate >= proofTimestamp, "Invalid proof timestamp for new address");
            if(addressesOfIndiv[indivId][indivAddress].companyPubAddr != address(0)){
                require(_verifySign(addressesOfIndiv[indivId][indivAddress].docHash, addressesOfIndiv[indivId][indivAddress].companyPubAddr, addressesOfIndiv[indivId][indivAddress].companySign), 
                 "Invalid company authorization of individual");
                // If the individual is an employee of a company, check that the proof of his employment is valid or not
                return _checkValidCompany(addressesOfIndiv[indivId][indivAddress].startDate, addressesOfIndiv[indivId][indivAddress].companyPubAddr);
            }
            return true;
        }
    }
    
    /**
     * @dev Internal function for validating signatures on proofHashes
     * @param proofHash IPFS proof hash stating that an entity owns a security token
     * @param pubAddr Ethereum address of the authorizer who authorized the above &#39;proofHash&#39;
     * @param proofSign Signature obtained when the authorizer signs the above &#39;proofHash&#39; claiming that
     * it attests that fact that the entity is the rightful owner of the security token
     * @return Boolean indicating whether or not the signature is valid
     */
    function _verifySign(string memory proofHash, address pubAddr, bytes memory proofSign) internal view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly{
            r := mload(add(proofSign, 32))
            s := mload(add(proofSign, 64))
            v := and(mload(add(proofSign, 65)), 255)
        }
        
        return verifier.ecrecovery(_getMsgHash(proofHash), v, r, s) == pubAddr;
        // return verifier.ecrecovery(msgHash, v, r, s) == pubAddr;
    }

    function _getMsgHash(string memory message) internal pure returns (bytes32){
        bytes memory messageBytes = bytes(message);
        bytes memory prefix = bytes("\x19Ethereum Signed Message:\n46");
        string memory _tmpValue = new string(74);
        bytes memory _newValue = bytes(_tmpValue);
        for(uint256 i = 0; i < 46; i++){
            _newValue[i + 28] = messageBytes[i];
            if(i < 28){
                _newValue[i] = prefix[i];
            }
        }
        return keccak256(_newValue);
    }
    
}

// -------------------------------------------------------------------------------
// SOME NOTES:
// -------------------------------------------------------------------------------
// 1. Everytime an employee changes his company, he gets a new individualId
// 2. When employee changes his company, he has to be first removed by his old
//    company & then added as an employee to a new company
// -------------------------------------------------------------------------------