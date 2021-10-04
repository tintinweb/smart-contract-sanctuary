pragma solidity ^0.6.7;

 import "./AggregatorV3Interface.sol";

pragma experimental ABIEncoderV2;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.6.7;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.6.7;

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address payable) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.6.7;

contract Notary is Ownable {

    struct FirstLevelUsers {
        uint64 transactionCount ;
        uint64 sluAllowanceCount ;
        int256 perTransactionFee ;
        address[] usersWhitelisted ;
        bool isEUR ;
        uint256 accessLevel ;
    }
    struct DocData {
        uint256 time;
        string sha256Hash;
        string ipfsHash;
        string fileName;
        string sessionKey;
        address creator;
    }
    struct FLUBatch {
        address user  ;
        uint64 transactionCount ;
        uint64 sluAllowanceCount ;
        int256 perTransactionFee ;
        bool isEUR ;
        uint256 accessLevel;
    }
    struct AdminWhitelistCount {
        uint256 subAdminCount;
        uint256 fluCount;
    }
      AggregatorV3Interface internal priceFeed;
      AggregatorV3Interface internal priceEUR;
    mapping(address => DocData[]) public documents;
    mapping(address => FirstLevelUsers) public firstLevelUsers;
    mapping(address => mapping(address => bool)) public secondLevelUsers;
    mapping(address => bool ) public isFirstLevelUser;
    mapping(address => uint256 ) public adminLevel;
    mapping(address=>  address[]) private adminFLUAddress;
    mapping(address => AdminWhitelistCount ) public adminWhitelistCount;
    address[] public FLUAddress;
    string public name;
    uint256 batchLimit = 10;
    
    constructor(
    string memory name_
    
    ) public Ownable() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceEUR = AggregatorV3Interface(0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F);
        name = name_;
        adminLevel[msg.sender] = 1 ;
    }
        function getPriceUSDETH() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
        function getPriceUSDEUR() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceEUR.latestRoundData();
        return price;
    }
            function getAllPriceUSDEUR() public view returns (uint80,int256,uint256,uint256,uint80) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceEUR.latestRoundData();
        return (roundID, price, startedAt, timeStamp, answeredInRound);
    }
        function getPrices(bool _curr ) public view returns (int) {
            if(_curr){
                return (getPriceUSDETH()*(10**8))/getPriceUSDEUR();
            }else{
                return getPriceUSDETH();
            }
    }
      
      function _addFLU(FLUBatch  memory _FLUBatch) private returns (bool) {
         firstLevelUsers[_FLUBatch.user] = FirstLevelUsers({
            transactionCount : _FLUBatch.transactionCount,
            sluAllowanceCount : _FLUBatch.sluAllowanceCount,
            perTransactionFee : _FLUBatch.perTransactionFee,
            usersWhitelisted : new address[](0),
            isEUR : _FLUBatch.isEUR,
            accessLevel : _FLUBatch.accessLevel
            });
            return true;
       }

        function checkAdmins (uint256 l) private pure{
          require(l==1 || l ==2, "na");
          }
    function addFirstLevelUser(FLUBatch  memory _FLUBatch ) public  {
        require(adminLevel[msg.sender]==1 || adminLevel[msg.sender]==2 || adminLevel[msg.sender]==3,"na");
        require(!isFirstLevelUser[_FLUBatch.user],"uae");
            _addFLU( _FLUBatch );
            isFirstLevelUser[_FLUBatch.user] = true;
            FLUAddress.push(_FLUBatch.user);
            adminFLUAddress[msg.sender].push(_FLUBatch.user);
            if(adminLevel[msg.sender] == 2 || adminLevel[msg.sender] == 3) adminWhitelistCount[msg.sender].fluCount -- ;
    }
    function _changeFLUFee(address _user, int256 _fee) private {
        firstLevelUsers[_user].perTransactionFee = _fee;
    }
    function _changeFLUcurr(address  _user,  bool curr) private {
        firstLevelUsers[_user].isEUR = curr;
    }
    function _changeFLUTransactionCount(address _user,  uint64 _tranCount) private {
        firstLevelUsers[_user].transactionCount = _tranCount;
    }
    function _changeFLUsluCount(address  _user,  uint64 _sluCount) private {
        firstLevelUsers[_user].sluAllowanceCount = _sluCount;
    }
    function changeFLUFee(address _user, int256 _fee) public {
        checkAdmins(adminLevel[msg.sender]);
        _changeFLUFee(_user,_fee );
    }
    function changeFLUscurr(address  _user, bool _curr) public {
        checkAdmins(adminLevel[msg.sender]);
        _changeFLUcurr(_user,_curr);
    }
    function changeFLUTransactionCount(address _user,  uint64 _tranCount) public {
      checkAdmins(adminLevel[msg.sender]);
        _changeFLUTransactionCount(_user,_tranCount);
    }
    function changeFLUsluCount(address  _user,  uint64 _sluCount) public {
      checkAdmins(adminLevel[msg.sender]);
        _changeFLUsluCount(_user,_sluCount);
    }
    function _changeFLUAccessLevel(address _user, uint256 _accessLevel) private {
        firstLevelUsers[_user].accessLevel = _accessLevel;
    } 
    function changeFLUAccessLevel(address _user, uint256 _accessLevel)public {
       checkAdmins(adminLevel[msg.sender]);
        _changeFLUAccessLevel(_user,_accessLevel);
    }
    struct FLUBatchUp {
        address[] user ;
        uint64 transactionCount ;
        uint64 sluAllowanceCount ;
        int256 perTransactionFee ;
        uint256 accessLevel;
    }
    function changeFLUBatchDetails(FLUBatchUp memory _FLUBatchUp) public {
         require(_FLUBatchUp.user.length<batchLimit,"na");
         checkAdmins(adminLevel[msg.sender]);
            
        for(uint i=0;i<_FLUBatchUp.user.length;i++){
          address _FLUuser = _FLUBatchUp.user[i];
          firstLevelUsers[_FLUuser].transactionCount = _FLUBatchUp.transactionCount;
          firstLevelUsers[_FLUuser].sluAllowanceCount = _FLUBatchUp.sluAllowanceCount;
          firstLevelUsers[_FLUuser].perTransactionFee = _FLUBatchUp.perTransactionFee;
          firstLevelUsers[_FLUuser].accessLevel = _FLUBatchUp.accessLevel;
          }
        }
    
    function addFLUBatch(FLUBatch [] memory _FLUBatch ) public {
    require(adminLevel[msg.sender]==1 && adminLevel[msg.sender]==2 && adminLevel[msg.sender]==3,"na");
     require(_FLUBatch.length<batchLimit, "LE");
     for(uint i = 0; i<_FLUBatch.length;i++ ){
         address _user = _FLUBatch[i].user;
         if(!isFirstLevelUser[_user]){
            _addFLU(_FLUBatch[i]);
            isFirstLevelUser[_user] = true;
            FLUAddress.push(_user);
            adminFLUAddress[msg.sender].push(_user);
         }
         if(adminLevel[msg.sender]== 2 || adminLevel[msg.sender]== 3) adminWhitelistCount[msg.sender].fluCount -- ;
     }   
    }
    
    function whitelistSecondLevelUser(address slUser_) public {
        require(isFirstLevelUser[msg.sender], "not first level user");
        require(!secondLevelUsers[slUser_][msg.sender], "user already exist");
        require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough slu left");
        secondLevelUsers[slUser_][msg.sender] = true; 
        firstLevelUsers[msg.sender].usersWhitelisted.push(slUser_);
        firstLevelUsers[msg.sender].sluAllowanceCount = firstLevelUsers[msg.sender].sluAllowanceCount - 1;
    }
    
    struct Doc {
        string sha256Hash ;
        string ipfsHash ;
        string fileName ;
        address _sharedAddress ;
        string _sessionKey ;
    }
    function _createDoc ( Doc memory _doc) private view returns (DocData memory ){
       return DocData({
          time : block.timestamp,
          sha256Hash : _doc.sha256Hash,
          ipfsHash : _doc.ipfsHash,
          fileName : _doc.fileName,
          sessionKey : _doc._sessionKey, 
          creator : msg.sender
        });
    }
    function createDocument(Doc memory _doc) public payable returns (bool) {
        require(isFirstLevelUser[msg.sender],"not FLU");
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not etl");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
       if(firstLevelUsers[msg.sender].accessLevel == 1){
           bytes memory bIPFSHash = bytes(_doc.ipfsHash);
           require(bIPFSHash.length == 0  , "FNA" );
           require(_doc._sharedAddress == address(0),"FNA");
       } else if (firstLevelUsers[msg.sender].accessLevel == 2){
           require(_doc._sharedAddress == address(0) , "FNA" );
       }
        // DocData memory newDocData = _createDoc(_doc);
        if(_doc._sharedAddress!= address(0)){
            require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "na slucount left");
            documents[_doc._sharedAddress].push(_createDoc(_doc));
            firstLevelUsers[msg.sender].usersWhitelisted.push(_doc._sharedAddress);
            firstLevelUsers[msg.sender].sluAllowanceCount --;
        }
        documents[msg.sender].push(_createDoc(_doc));
        firstLevelUsers[msg.sender].transactionCount -- ;
        owner().transfer(msg.value);
        return true;

    }
    // struct BatchDoc {
    //     string sha256Hash;
    //     string ipfsHash;
    //     string fileName;
    //     string sessionKey;
    //     address sharedAddress;
    // }
    function createDocumentBatch(Doc [] memory _batchDoc) public payable returns (bool) {
        require(_batchDoc.length<batchLimit, "LE");
        require(firstLevelUsers[msg.sender].accessLevel == 4, "FNA");
        require(isFirstLevelUser[msg.sender],"not flu");
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
     for(uint i =0 ;i < _batchDoc.length ;i++){
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
         documents[msg.sender].push(_createDoc(_batchDoc[i]));
        if(_batchDoc[i]._sharedAddress!= address(0)){
            require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough slua left");
            documents[_batchDoc[i]._sharedAddress].push(_createDoc(_batchDoc[i]));
            firstLevelUsers[msg.sender].usersWhitelisted.push(_batchDoc[i]._sharedAddress);
            firstLevelUsers[msg.sender].sluAllowanceCount --;
        }
        }
        firstLevelUsers[msg.sender].transactionCount -- ;
        owner().transfer(msg.value);
        return true;
    }
     
     function shareDocument( uint256 _id , address sluAddress , string memory _sessionKey) public payable returns (bool) {
         require(isFirstLevelUser[msg.sender],"not first level user");
         require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
         require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
         require(firstLevelUsers[msg.sender].accessLevel == 2, "FNA");
         documents[msg.sender][_id].sessionKey = _sessionKey;
         documents[sluAddress].push(documents[msg.sender][_id]);
         firstLevelUsers[msg.sender].usersWhitelisted.push(sluAddress);
         firstLevelUsers[msg.sender].transactionCount -- ;
         owner().transfer(msg.value);
         return true;
     }
     
    function getDocs() public view returns( DocData  [] memory){
        return documents[msg.sender];
    }
    function disableFLU(address _user) public {
        require(adminLevel[msg.sender]==1 || adminLevel[msg.sender]==2 || adminLevel[msg.sender]==3);
        require(isFirstLevelUser[_user],"not flu");
        isFirstLevelUser[_user] = false;
    }
    
    function calculateFeeETH(int256 _currfee, bool _curr) public view returns (int){
        return (_currfee * (10**26))/(getPrices(_curr));
    }
    function fluDetails(address _fluAddress) public view returns (FirstLevelUsers memory ){
        return firstLevelUsers[_fluAddress];
    }
    function getFLUAddress() public view returns (address [] memory ){
        require (adminLevel[msg.sender] == 1);
        return FLUAddress;
    }
    function addAdminLevel (address _newAddress , uint256 level , FLUBatch  memory _FLUBatch) public {
        checkAdmins(adminLevel[msg.sender]);
      if(adminLevel[msg.sender] == 2 && (level == 1 || level == 2)) revert ();
        adminLevel[_newAddress] = level;
        addFirstLevelUser(_FLUBatch);
        if(adminLevel[msg.sender]== 2) adminWhitelistCount[msg.sender].subAdminCount --;
    }
    function removeAdminLevel (address _newAddress ) public {
    require(adminLevel[msg.sender]==1 || adminLevel[msg.sender]==2);
      if(adminLevel[msg.sender] == 2 && (adminLevel[_newAddress] == 1 || adminLevel[_newAddress] == 2)) revert ();
        adminLevel[_newAddress] = 0;
    }
    function changeAdminWhitelistCount(address _adminAdress , AdminWhitelistCount memory _adminWhitelistCount ) public {
        checkAdmins(adminLevel[msg.sender]);
        if(adminLevel[_adminAdress]==2 && (adminLevel[_adminAdress] == 1 || adminLevel[_adminAdress] == 2)) revert();
        adminWhitelistCount[_adminAdress] = AdminWhitelistCount({
          subAdminCount :  adminLevel[msg.sender] == 2?0:_adminWhitelistCount.subAdminCount,
          fluCount : _adminWhitelistCount.fluCount
        });
    }
    function changeBatchLimit (uint256 _limit) public {
        require(adminLevel[msg.sender]==1);
        batchLimit = _limit;
    }
    function getFLUAddress2()public view returns (address [] memory ){
         if(adminLevel[msg.sender] != 1 && adminLevel[msg.sender] != 2 && adminLevel[msg.sender] != 3)  revert();
         return adminFLUAddress[msg.sender];
    }
}