/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./Ownable.sol";

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

interface IELX {
    function createStakeDelegated(address _from, uint256 _stake) external ; 
}
contract SupplyChain is Ownable
{

    /* User Related */
    struct user {
        string name;
        string email;
        string extraData;
        string contactNo;
        bool isActive;
        string profileHash;
        bool isCreated;
    } 

    /* Process Related */
    struct basicDetails {
        string registrationNo;
        string extractorName;
        string extractorAddress;
        address auditorAddress;
        address operatorAddress;
        address exporterAddress;
        address importerAddress;   
        address processorAddress;
    }

    struct auditor {
        string extractionMethod;
        string oilClass;
        string extraData;
        uint256 timeStamp;
    }

    struct operator {
        string hydrocarbonVariety;
        string operatorAbi;
        string gravity;
        string extraData;
        uint256 timeStamp;
    }
    struct exporter {
        string quantity;
        string destinationAddress;
        string shipNo;
        string shipName;
        string estimateDateTime;
        string exporterId;
        string extraData;
        uint256 timeStamp;

    }
    struct importer {
        string quantity;
        string shipNo;
        string shipName;
        string transportInfo;
        string terminalName;
        string terminalCoordinates;
        string importerId;
        string extraData;
        uint256 timeStamp;
    }
    struct processor {
        string quantity;
        string temperature;
        string fuelGrade;
        string internalBatchNo;
        string packagingDateTime;
        string processorName;
        string processorAddress;
        string extraData;
        uint256 timeStamp;

    }

    user userDetail;
    basicDetails basicDetailsData;
    auditor auditorData;
    operator operatorData;
    exporter exporterData;
    importer importerData;
    processor processorData; 

    address public lastAccess;
    address public admin;
    address tokenAddress;
    address stakingAddress;
    string[] public getUserRole = ['auditor', 'operator', 'exporter', 'importer', 'processor'];
    
    uint256 userAddFee;
    uint256 userEditFee;
    uint256 batchAddFee;
    uint256 auditorBatchUpdateFee;
    uint256 operatorBatchUpdateFee;
    uint256 exporterBatchUpdateFee;
    uint256 importerBatchUpdateFee;
    uint256 processorBatchUpdateFee;


    mapping(address => user) userDetails;
    mapping(address => string) userRole;

    mapping(address => string) nextAction;
    mapping(address => uint8) public authorizedCaller;
    mapping(address => basicDetails) batchBasicDetails;
    mapping(address => auditor) batchAuditor;
    mapping(address => operator) batchOperator;
    mapping(address => exporter) batchExporter;
    mapping(address => importer) batchImporter;
    mapping(address => processor) batchProcessor;

    /* Users Events */
    event UserCreated(address indexed user, string name, string email, string extraData, string contactNo, string role, bool isActive, string profileHash);
    event UserUpdated(address indexed user, string name, string email, string extraData, string contactNo, string role, bool isActive, string profileHash);
    event UserRoleUpdated(address indexed user, string role); 

    /* Batch Events */
    event performBatchAudit(address indexed user, address indexed batchNo);
    event DoneBatchAudit(address indexed user, address indexed batchNo);
    event DoneBatchOperation(address indexed user, address indexed batchNo);
    event DoneBatchExporting(address indexed user, address indexed batchNo);
    event DoneBatchImporting(address indexed user, address indexed batchNo);
    event DoneBatchProcessing(address indexed user, address indexed batchNo);

    event AuthorityUpdated(address indexed _operator, bool _isActive);

    

    constructor(address _tokenAddress) {
        admin = msg.sender;
        setUser(msg.sender, 'William Pete', '[email protected]', 'eyJjb21wYW55TmFtZSI6IkVuZXJneSBMZWRnZXIiLCJjb250YWN0QWRkcmVzcyI6IlVTQSJ9', '9999999999', 'admin', true, true, '11');
        authorizedCaller[msg.sender] = 1;
        emit AuthorityUpdated(msg.sender,true);

        setTokenAddress(_tokenAddress);
        
    }


    /*Modifier*/
    modifier isValidPerformer(address batchNo, string memory role) {
    
        // require(keccak256(SupplyChainUser.getUserRole(msg.sender)) == keccak256(role));
        require(keccak256(abi.encodePacked(getUserAddressRole(msg.sender))) == keccak256(abi.encodePacked(role)),'Invalid user');
        require(keccak256(abi.encodePacked(getNextAction(batchNo))) == keccak256(abi.encodePacked(role)),'Invalid step to proceed');
        _;
    }

    modifier onlyAuthCaller(){
        lastAccess = msg.sender;
        require(authorizedCaller[msg.sender] == 1 || msg.sender == owner,"Only Authorized and Owner can perform this action");
        _;
    }


     /*authorize caller*/
    function authorizeCaller(address _caller) public onlyOwner returns(bool)
    {
        authorizedCaller[_caller] = 1;
        emit AuthorityUpdated(_caller,true);
        return true;
    }
    
    /*Deauthorize caller*/
    function deAuthorizeCaller(address _caller) public onlyOwner returns(bool)
    {
        authorizedCaller[_caller] = 0;
        emit AuthorityUpdated(_caller,false);
        return true;
    }


    function getNextAction(address _batchNo) public view returns(string memory action)
    {
       (action) = getBatchNextAction(_batchNo);
       return (action);
    }

     /* Get Next Action  */    
    function getBatchNextAction(address _batchNo) public view returns(string memory)
    {
        return nextAction[_batchNo];
    }

    /*set batch basicDetails*/
    function setBatchDetails(string memory _registrationNo,
                             string memory _extractorName,
                             string memory _extractorAddress,
                             address _auditorAddress,
                             address _operatorAddress,
                             address _exporterAddress,
                             address _importerAddress,
                             address _processorAddress
                             
                            ) public onlyAuthCaller returns(address) {
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,batchAddFee);
        
        // uint tmpData = uint(keccak256(msg.sender, now));
        address tmpData = address(uint160(uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)))));
        address batchNo = address(tmpData);
        
        basicDetailsData.registrationNo = _registrationNo;
        basicDetailsData.extractorName = _extractorName;
        basicDetailsData.extractorAddress = _extractorAddress;
        basicDetailsData.auditorAddress = _auditorAddress;
        basicDetailsData.operatorAddress = _operatorAddress;
        basicDetailsData.exporterAddress = _exporterAddress;
        basicDetailsData.importerAddress = _importerAddress;
        basicDetailsData.processorAddress = _processorAddress;
        
        batchBasicDetails[batchNo] = basicDetailsData;
        
        nextAction[batchNo] = '0';   
        
        emit performBatchAudit(msg.sender, batchNo); 
        return batchNo;
    }

    /*get batch basicDetails*/
    function getBatchDetails(address _batchNo) public view returns(string memory registrationNo,
                             string memory extractorName,
                             string memory extractorAddress,
                             address auditorAddress,
                             address operatorAddress,
                             address exporterAddress,
                             address importerAddress,
                             address processorAddress) {
        
        basicDetails memory tmpData = batchBasicDetails[_batchNo];
        
        return (tmpData.registrationNo,tmpData.extractorName,tmpData.extractorAddress,tmpData.auditorAddress,tmpData.operatorAddress,tmpData.exporterAddress,tmpData.importerAddress,tmpData.processorAddress);
    }

    /* perform Audit */
    function updateAuditData(address _batchNo,
                                string memory _extractionMethod,
                                string memory _oilClass,
                                string memory _extraData
                                ) 
                                public isValidPerformer(_batchNo,'0') returns(bool) {
                            
        require(msg.sender == batchBasicDetails[_batchNo].auditorAddress,'Invalid Auditor');
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,auditorBatchUpdateFee);
        
        auditorData.extractionMethod = _extractionMethod;
        auditorData.oilClass         = _oilClass;
        auditorData.extraData = _extraData;
        auditorData.timeStamp = block.timestamp;
        
        batchAuditor[_batchNo] = auditorData;
        nextAction[_batchNo] = '1'; 

        emit DoneBatchAudit(msg.sender, _batchNo);
        return true;
    }

    /* get Audit data */
    function getAuditorData(address _batchNo) public view returns (string memory extractionMethod,string memory oilClass,string memory extraData, uint256 timeStamp) {        
        auditor memory tmpData = batchAuditor[_batchNo];
        return (tmpData.extractionMethod, tmpData.oilClass, tmpData.extraData, tmpData.timeStamp);
    }

    /* perform operator */
    function updateOperatorData(address _batchNo,
                                string memory _hydrocarbonVariety,
                                string memory _operatorAbi,
                                string memory _gravity,
                                string memory _extraData) 
                                public isValidPerformer(_batchNo,'1') returns(bool) {
                                    
        require(msg.sender == batchBasicDetails[_batchNo].operatorAddress,'Invalid Operator');
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,operatorBatchUpdateFee);

        operatorData.hydrocarbonVariety = _hydrocarbonVariety;
        operatorData.operatorAbi = _operatorAbi;
        operatorData.gravity = _gravity;
        operatorData.extraData = _extraData;
        operatorData.timeStamp = block.timestamp;
        
        batchOperator[_batchNo] = operatorData;
        nextAction[_batchNo] = '2'; 

        emit DoneBatchOperation(msg.sender, _batchNo);
        return true;
    }

    /* get operator data */
    function getOperatorData(address _batchNo) public view returns (string memory hydrocarbonVariety,string memory operatorAbi,string memory gravity,string memory extraData, uint256 timeStamp) {        
        operator memory tmpData = batchOperator[_batchNo];
        return (tmpData.hydrocarbonVariety, tmpData.operatorAbi, tmpData.gravity, tmpData.extraData, tmpData.timeStamp);
    }

    /* perform exporter */
    function updateExporterData(address _batchNo,
                                string memory _quantity,
                                string memory _destinationAddress,
                                string memory _shipNo,
                                string memory _shipName,
                                string memory _estimateDateTime,
                                string memory _exporterId,
                                string memory _extraData
                                ) 
                                public isValidPerformer(_batchNo,'2') returns(bool) {
                                    
        require(msg.sender == batchBasicDetails[_batchNo].exporterAddress,'Invalid exporter');
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,exporterBatchUpdateFee);

        exporterData.quantity = _quantity;
        exporterData.destinationAddress = _destinationAddress;
        exporterData.shipNo = _shipNo;
        exporterData.shipName = _shipName;
        exporterData.estimateDateTime = _estimateDateTime;
        exporterData.exporterId = _exporterId;
        exporterData.extraData = _extraData;
        exporterData.timeStamp = block.timestamp;
        
        
        batchExporter[_batchNo] = exporterData;
        nextAction[_batchNo] = '3'; 

        emit DoneBatchExporting(msg.sender, _batchNo);
        return true;
    }

    /* get exporter data */
    function getExporterData(address _batchNo) public view returns (string memory quantity,
                                                                    string memory destinationAddress,
                                                                    string memory shipNo,
                                                                    string memory shipName,
                                                                    string memory estimateDateTime,
                                                                    string memory exporterId,
                                                                    string memory extraData,
                                                                    uint256 timeStamp                                                                    

                                                                    ) {        
        exporter memory tmpData = batchExporter[_batchNo];
        return (tmpData.quantity, tmpData.destinationAddress, tmpData.shipNo, tmpData.shipName, tmpData.estimateDateTime, tmpData.exporterId, tmpData.extraData, tmpData.timeStamp);
    }

     /* perform import */
    function updateImporterData(address _batchNo,
                                string memory _quantity,
                                string memory _shipNo,
                                string memory _shipName,
                                string memory _transportInfo,
                                string memory _terminalName,
                                string memory _terminalCoordinates,
                                string memory _importerId,
                                string memory _extraData
                                ) 
                                public isValidPerformer(_batchNo,'3') returns(bool) {
                                    
        require(msg.sender == batchBasicDetails[_batchNo].importerAddress,'Invalid importer');
        
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,importerBatchUpdateFee);

        importerData.quantity = _quantity;
        importerData.shipNo = _shipNo;
        importerData.shipName = _shipName;
        importerData.transportInfo = _transportInfo;
        importerData.terminalName = _terminalName;
        importerData.terminalCoordinates = _terminalCoordinates;
        importerData.importerId = _importerId;
        importerData.extraData = _extraData;
        importerData.timeStamp = block.timestamp;
        
        batchImporter[_batchNo] = importerData;
        nextAction[_batchNo] = '4'; 

        emit DoneBatchImporting(msg.sender, _batchNo);
        return true;
    }

    /* get importer data */
    function getImporterData(address _batchNo) public view returns (string memory quantity,
                                                                    string memory shipNo,
                                                                    string memory shipName,
                                                                    string memory transportInfo,
                                                                    string memory terminalName,
                                                                    string memory terminalCoordinates,
                                                                    string memory importerId,
                                                                    string memory extraData,
                                                                    uint256 timeStamp

                                                                    ) {        
        importer memory tmpData = batchImporter[_batchNo];
        return (tmpData.quantity, tmpData.shipNo, tmpData.shipName, tmpData.transportInfo, tmpData.terminalName, tmpData.terminalCoordinates, tmpData.importerId, tmpData.extraData, tmpData.timeStamp);
    }

    /* perform processor */
    function updateProcessorData(address _batchNo,
                                string memory _quantity,
                                string memory _temperature,
                                string memory _fuelGrade,
                                string memory _internalBatchNo,
                                string memory _packagingDateTime,
                                string memory _processorName,
                                string memory _processorAddress,
                                string memory _extraData
                                ) 
                                public isValidPerformer(_batchNo,'4') returns(bool) {
                                    
        require(msg.sender == batchBasicDetails[_batchNo].processorAddress,'Invalid processor');
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,processorBatchUpdateFee);

        processorData.quantity = _quantity;
        processorData.temperature = _temperature;
        processorData.fuelGrade = _fuelGrade;
        processorData.internalBatchNo = _internalBatchNo;
        processorData.packagingDateTime = _packagingDateTime;
        processorData.processorName = _processorName;
        processorData.processorAddress = _processorAddress;
        processorData.extraData = _extraData;
        processorData.timeStamp = block.timestamp;
        
        
        batchProcessor[_batchNo] = processorData;
        nextAction[_batchNo] = 'DONE'; 

        emit DoneBatchProcessing(msg.sender, _batchNo);
        return true;
    }

    /* get processor data */
    function getProcessorData(address _batchNo) public view returns (string memory quantity,
                                                                    string memory temperature,
                                                                    string memory fuelGrade,
                                                                    string memory internalBatchNo,
                                                                    string memory packagingDateTime,
                                                                    string memory processorName,
                                                                    string memory processorAddress,
                                                                    string memory extraData,
                                                                    uint256 timeStamp
                                                                    ) {        
        processor memory tmpData = batchProcessor[_batchNo];
        return (tmpData.quantity, tmpData.temperature, tmpData.fuelGrade, tmpData.internalBatchNo, tmpData.packagingDateTime, tmpData.processorName, tmpData.processorAddress, tmpData.extraData, tmpData.timeStamp);
    }

     /*set user details*/
    function setUser(address _userAddress,
                     string memory _name, 
                     string memory _email, 
                     string memory _extraData, 
                     string memory _contactNo, 
                     string memory _role, 
                     bool _isActive,
                     bool _isCreated,
                     string memory _profileHash) internal returns(bool){
        
        /*store data into struct*/
        userDetail.name = _name;
        userDetail.email = _email;
        userDetail.extraData = _extraData;
        userDetail.contactNo = _contactNo;
        userDetail.isActive = _isActive;
        userDetail.profileHash = _profileHash;

        if(_isCreated == true)
        {
            userDetail.isCreated = _isCreated;
        }
        
        
        /*store data into mapping*/
        userDetails[_userAddress] = userDetail;
        userRole[_userAddress] = _role;
        
        return true;
    }  
    
    
    
     /* Update User */
    function updateUser(string memory _name, 
                        string memory _email,
                        string memory _extraData, 
                        string memory _contactNo, 
                        string memory _role, 
                        bool _isActive,
                        string memory _profileHash) public returns(bool)
    {
        require(msg.sender != address(0));
        require(isAlreadyUser(msg.sender) == true,"User does not exists");
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,userEditFee);

        /* Call Storage Contract */
        bool status = setUser(msg.sender, _name, _email, _extraData, _contactNo, _role, _isActive,false,_profileHash);
        
         /*call event*/
        emit UserUpdated(msg.sender,_name,_email,_extraData,_contactNo,_role,_isActive,_profileHash);
        emit UserRoleUpdated(msg.sender,_role);
        
        return status;
    }

    /* Create User For Admin  */
    function createUserForAdmin(address _userAddress, 
                                string memory _name, 
                                string memory _email,
                                string memory _extraData, 
                                string memory _contactNo, 
                                string memory _role, 
                                bool _isActive,
                                string memory _profileHash) public onlyAuthCaller returns(bool)
    {
        require(_userAddress != address(0));
        require(isAlreadyUser(_userAddress) == false,"User already exists");
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,userAddFee);
        
        /* Call Storage Contract */
        bool status = setUser(_userAddress, _name, _email, _extraData, _contactNo, _role, _isActive,true,_profileHash);
        
         /*call event*/
        emit UserCreated(_userAddress,_name, _email, _extraData,_contactNo,_role,_isActive,_profileHash);
        emit UserRoleUpdated(_userAddress,_role);
        
        return status;
    }
    
    /* Update User For Admin  */
    function updateUserForAdmin(address _userAddress,
                                string memory _name, 
                                string memory _email,
                                string memory _extraData,                                 
                                string memory _contactNo, 
                                string memory _role, 
                                bool _isActive,
                                string memory _profileHash) public onlyAuthCaller returns(bool)
    {
        require(_userAddress != address(0));
        
        IELX(tokenAddress).createStakeDelegated(msg.sender,userEditFee);
        
        /* Call Storage Contract */
        bool status = setUser(_userAddress, _name, _email, _extraData, _contactNo, _role, _isActive, false,_profileHash);
        
         /*call event*/
        emit UserUpdated(_userAddress,_name, _email, _extraData,_contactNo,_role,_isActive,_profileHash);
        emit UserRoleUpdated(_userAddress,_role);
        
        return status;
    }
     
    /*get user details*/
    function getUser(address _userAddress) public view returns(string memory name, 
                                                                string memory email,
                                                                string memory extraData,                                                                
                                                                string memory contactNo, 
                                                                string memory role,
                                                                bool isActive, 
                                                                string memory profileHash
                                                                ){

        require(_userAddress != address(0), "Invalid User");                                                          

        /*Getting value from struct*/
        user memory tmpData = userDetails[_userAddress];
        
        return (tmpData.name, tmpData.email, tmpData.extraData, tmpData.contactNo, userRole[_userAddress], tmpData.isActive, tmpData.profileHash);
    }

    /*get roles*/ 
    function getRoles() public view returns( string[] memory){
        return getUserRole;
    }

    /* check user already exist or Not */ 
    function isAlreadyUser(address _userAddress) public view returns(bool){
        
        return userDetails[_userAddress].isCreated;
    }

    /* Get User Role */
    function getUserAddressRole(address _userAddress) public view returns(string memory)
    {
        return userRole[_userAddress];
    }

    /* get action fee */
    function getActionFee() public view returns (uint256 _userAddFee,
                                                 uint256 _userEditFee,
                                                 uint256 _batchAddFee,
                                                 uint256 _auditorBatchUpdateFee,
                                                 uint256 _operatorBatchUpdateFee,
                                                 uint256 _exporterBatchUpdateFee,
                                                 uint256 _importerBatchUpdateFee,
                                                 uint256 _processorBatchUpdateFee) {        
        return (userAddFee, userEditFee, batchAddFee, auditorBatchUpdateFee, operatorBatchUpdateFee, exporterBatchUpdateFee, importerBatchUpdateFee, processorBatchUpdateFee);
    }

    function setActionFee(
                    uint256 _userAddFee,
                    uint256 _userEditFee,
                    uint256 _batchAddFee,
                    uint256 _auditorBatchUpdateFee,
                    uint256 _operatorBatchUpdateFee,
                    uint256 _exporterBatchUpdateFee,
                    uint256 _importerBatchUpdateFee,
                    uint256 _processorBatchUpdateFee) public onlyAuthCaller {   
        
        userAddFee = _userAddFee;
        userEditFee = _userEditFee; 
        batchAddFee = _batchAddFee; 
        auditorBatchUpdateFee = _auditorBatchUpdateFee;
        operatorBatchUpdateFee =  _operatorBatchUpdateFee;
        exporterBatchUpdateFee = _exporterBatchUpdateFee;
        importerBatchUpdateFee = _importerBatchUpdateFee;
        processorBatchUpdateFee = _processorBatchUpdateFee;
    }

    /* get token address */
    function getTokenAddress() public view returns (address _tokenAddress) {        
        return (tokenAddress);
    }

    /* set token address */
    function setTokenAddress(address _tokenAddress) public onlyAuthCaller {           
        tokenAddress = _tokenAddress;
    }

}

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner,"Caller is Not owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}