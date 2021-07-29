pragma solidity ^0.6.7;

import "./AggregatorV3Interface.sol";


pragma experimental ABIEncoderV2;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.6.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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
        require(isOwner(), "Ownable: caller is not the owner");
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
    using SafeMath for uint256;

  struct FirstLevelUsers {
        uint64 transactionCount ;
        uint64 sluAllowanceCount ;
        int256 perTransactionFee ;
        address[] usersWhitelisted ;
        bool isEUR ;
    }
    struct SecondLevelUsers{
        mapping(address => bool) firtLevelOwners ;
    }
    struct DocData {
        uint256 time;
        string sha256Hash;
        string ipfsHash;
        string fileName;
        address creator;
    }
      AggregatorV3Interface internal priceFeed;
      AggregatorV3Interface internal priceEUR;
    mapping(address => DocData[]) public documents;
    mapping(address => FirstLevelUsers) public firstLevelUsers;
    mapping(address => mapping(address => bool)) public secondLevelUsers;
    mapping(address => bool ) public isFirstLevelUser;
    address[] public FLUAddress;
    string public name;
    
    constructor(
    string memory name_
    ) public Ownable() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceEUR = AggregatorV3Interface(0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F);
        name = name_;
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
    
     struct FLUBatch {
        address user  ;
        uint64 transactionCount ;
        uint64 sluAllowanceCount ;
        int256 perTransactionFee ;
        bool isEUR ;
    }
    
    function addFirstLevelUser(FLUBatch memory _FLU ) public onlyOwner {
        require(!isFirstLevelUser[_FLU.user],"user already exist");
        firstLevelUsers[_FLU.user] = FirstLevelUsers({
            transactionCount : _FLU.transactionCount,
            sluAllowanceCount : _FLU.sluAllowanceCount,
            perTransactionFee : _FLU.perTransactionFee,
            usersWhitelisted : new address[](0),
            isEUR : _FLU.isEUR
            });
            isFirstLevelUser[_FLU.user] = true;
            FLUAddress.push(_FLU.user);
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
    function changeFLUFee(address _user, int256 _fee) public onlyOwner{
        _changeFLUFee(_user,_fee );
    }
    function changeFLUscurr(address  _user, bool _curr) public onlyOwner{
        _changeFLUcurr(_user,_curr);
    }
    function changeFLUTransactionCount(address _user,  uint64 _tranCount) public onlyOwner{
        _changeFLUTransactionCount(_user,_tranCount);
    }
    function changeFLUsluCount(address  _user,  uint64 _sluCount) public onlyOwner{
        _changeFLUsluCount(_user,_sluCount);
    }
    function changeFLUBatchDetails(address[] memory _users, uint64 _tranCount , uint64 _sluCount ,int256 perTransactionFee) public onlyOwner{
              for(uint i=0;i<_users.length;i++){
                  _changeFLUFee(_users[i], perTransactionFee);
                  _changeFLUTransactionCount(_users[i], _tranCount);
                  _changeFLUsluCount(_users[i],  _sluCount);
              }
        }
    
    
    function changeFLUBatchFee(address[] memory _users, uint64  _fee) public onlyOwner{
        for(uint i=0;i<_users.length;i++){
        firstLevelUsers[_users[i]].perTransactionFee = _fee;
        }
    }
    

    
    function addFLUBatch(FLUBatch [] memory _FLUBatch ) public onlyOwner {
     for(uint i = 0; i<_FLUBatch.length;i++ ){
         address _user = _FLUBatch[i].user;
         if(!isFirstLevelUser[_user]){
             firstLevelUsers[_user] = FirstLevelUsers({
            transactionCount : _FLUBatch[i].transactionCount,
            sluAllowanceCount : _FLUBatch[i].sluAllowanceCount,
            perTransactionFee : _FLUBatch[i].perTransactionFee,
            usersWhitelisted : new address[](0),
            isEUR : _FLUBatch[i].isEUR
            });
            isFirstLevelUser[_user] = true;
            FLUAddress.push(_user);
         }
     }   
    }
    function whitelistSecondLevelUser(address slUser_) public {
        require(isFirstLevelUser[msg.sender], "not first level user");
        require(!secondLevelUsers[slUser_][msg.sender], "user already whitlisted under first level user");
        require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough secondLevelUserAllowanceCount left");
        secondLevelUsers[slUser_][msg.sender] = true; 
        firstLevelUsers[msg.sender].usersWhitelisted.push(slUser_);
        firstLevelUsers[msg.sender].sluAllowanceCount = firstLevelUsers[msg.sender].sluAllowanceCount - 1;
    }
    
    function createDocument(string memory sha256Hash , string memory ipfsHash , string memory fileName, address sharedAddress) public payable returns (bool) {
        require(isFirstLevelUser[msg.sender],"not first level user");
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
        DocData memory newDocData = DocData({
          time : block.timestamp,
          sha256Hash : sha256Hash,
          ipfsHash : ipfsHash,
          fileName : fileName,
          creator : msg.sender
        });
        documents[msg.sender].push(newDocData);
         if(sharedAddress!= address(0)){
            require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough secondLevelUserAllowanceCount left");
            documents[sharedAddress].push(newDocData);
            firstLevelUsers[msg.sender].sluAllowanceCount--;
        }
        firstLevelUsers[msg.sender].transactionCount -- ;
        owner().transfer(msg.value);
        
        return true;

    }
    struct BatchDoc {
        string sha256Hash;
        string ipfsHash;
        string fileName;
        address sharedAddress;
    }
    function createDocumentBatch(BatchDoc [] memory _batchDoc) public payable returns (bool) {
        require(isFirstLevelUser[msg.sender],"not first level user");
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");

        for(uint i =0 ;i < _batchDoc.length ;i++){
             DocData memory newDocData = DocData({
          time : block.timestamp,
          sha256Hash : _batchDoc[i].sha256Hash,
          ipfsHash : _batchDoc[i].ipfsHash,
          fileName : _batchDoc[i].fileName,
          creator : msg.sender
        });
        
         documents[msg.sender].push(newDocData);
        if(_batchDoc[i].sharedAddress!= address(0)){
            require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough secondLevelUserAllowanceCount left");
            documents[_batchDoc[i].sharedAddress].push(newDocData);
            firstLevelUsers[msg.sender].sluAllowanceCount--;
            
        }
            
        }
        
        owner().transfer(msg.value);
        return true;
    }
    function updateDocument(uint8 _id,string memory _ipfsHash) public payable returns (bool) {
        require(isFirstLevelUser[msg.sender],"not first level user");
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");

        documents[msg.sender][_id].ipfsHash = _ipfsHash;
        owner().transfer(msg.value);
        return true;
    }
     
     function shareDocument( uint8 _id , address sluAddress) public payable returns (bool) {
         require(isFirstLevelUser[msg.sender],"not first level user");
         require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
         require(firstLevelUsers[msg.sender].sluAllowanceCount > 0 , "not enough secondLevelUserAllowanceCount left");
         require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
         
         documents[sluAddress].push(documents[msg.sender][_id]);
         firstLevelUsers[msg.sender].sluAllowanceCount--;
         firstLevelUsers[msg.sender].transactionCount -- ;
         owner().transfer(msg.value);
         return true;
     }
     
    function getDocs() public view returns( DocData  [] memory){
        require(isFirstLevelUser[msg.sender],"not first level user");
        return documents[msg.sender];
    }
    function disableFLU(address _user) public onlyOwner{
        require(isFirstLevelUser[_user],"not first level user");
        isFirstLevelUser[_user] = false;
    }
    
    function calculateFeeETH(int256 _currfee, bool _curr) public view returns (int){
        return (_currfee * (10**26))/(getPrices(_curr));
    }
    function fluDetails(address _fluAddress) public view returns (FirstLevelUsers memory ){
        return firstLevelUsers[_fluAddress];
    }
    function getFLUAddress() public view returns (address [] memory ){
        return FLUAddress;
    }
}