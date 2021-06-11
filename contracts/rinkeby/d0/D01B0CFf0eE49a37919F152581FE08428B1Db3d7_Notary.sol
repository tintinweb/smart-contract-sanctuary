pragma solidity ^0.6.7;

import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceEUR;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() internal {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceEUR = AggregatorV3Interface(0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F);
    }

    /**
     * Returns the latest price
     */
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
}


pragma solidity ^0.6.7;

pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.6.7;

contract Notary is Ownable ,PriceConsumerV3 {
    using SafeMath for uint256;

  struct FirstLevelUsers {
        uint64 transactionCount ;
        uint64 secondLevelUserAllowanceCount ;
        int256 perTransactionFee ;
        address[] usersWhitelisted ;
        bool isEUR ;
    }
    struct SecondLevelUsers{
        mapping(address => bool) firtLevelOwners ;
    }
    struct HashData {
        uint256 time;
        string sha256Hash;
        string ipfsHash;
        string fileName;
    }
    mapping(address => HashData[]) public hashes;
    mapping(address => FirstLevelUsers) public firstLevelUsers;
    mapping(address => mapping(address => bool)) public secondLevelUsers;
    mapping(address => bool ) public isFirstLevelUser;
    string public name;
    
    constructor(
    string memory name_
    ) public Ownable() {
        // priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        name = name_;
    }
        function getPrices(bool _curr ) public view returns (int) {
            if(_curr){
                return (getPriceUSDETH()*(10**8))/getPriceUSDEUR();
            }else{
                return getPriceUSDETH();
            }
    }
    
    function addFirstLevelUser(address user_) public onlyOwner {
        require(!isFirstLevelUser[user_],"user already exist");
        // string storage _hashes;
        firstLevelUsers[user_] = FirstLevelUsers({
            transactionCount : 3,
            secondLevelUserAllowanceCount : 1,
            perTransactionFee : 0,
            usersWhitelisted : new address[](0),
            isEUR : false
            });
            isFirstLevelUser[user_] = true;
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
        firstLevelUsers[_user].secondLevelUserAllowanceCount = _sluCount;
    }
    function changeFLUFee(address _user, int256 _fee) public onlyOwner{
        _changeFLUFee(_user,_fee );
    }
    function changeFLUcurr(address  _user, bool _curr) public onlyOwner{
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
    
    function addFLUBatch(address[] memory users) public onlyOwner {
     for(uint i = 0; i<users.length;i++ ){
         address _user = users[i];
         if(!isFirstLevelUser[_user]){
             firstLevelUsers[_user] = FirstLevelUsers({
            transactionCount : 3,
            secondLevelUserAllowanceCount : 1,
            perTransactionFee : 0,
            usersWhitelisted : new address[](0),
            isEUR : false
            });
            isFirstLevelUser[_user] = true;
             
         }
     }   
    }
    function whitelistSecondLevelUser(address slUser_) public {
        require(isFirstLevelUser[msg.sender], "not first level user");
        require(!secondLevelUsers[slUser_][msg.sender], "user already whitlisted under first level user");
        require(firstLevelUsers[msg.sender].secondLevelUserAllowanceCount > 0 , "not enough secondLevelUserAllowanceCount left");
        secondLevelUsers[slUser_][msg.sender] = true; 
        firstLevelUsers[msg.sender].secondLevelUserAllowanceCount = firstLevelUsers[msg.sender].secondLevelUserAllowanceCount - 1;
        
    }
    
    function createDocument(string memory sha256Hash , string memory ipfsHash , string memory fileName) public payable {
        require(isFirstLevelUser[msg.sender]);
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");
        HashData memory newHashData = HashData({
          time : block.timestamp,
          sha256Hash : sha256Hash,
          ipfsHash : ipfsHash,
          fileName : fileName
        });
        hashes[msg.sender].push(newHashData);
        firstLevelUsers[msg.sender].transactionCount -- ;
        
    }
    struct BatchDoc {
        string sha256Hash;
        string ipfsHash;
        string fileName;
    }
    function createDocumentBatch(BatchDoc [] memory _batchDoc) public payable {
        require(isFirstLevelUser[msg.sender]);
        require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
        require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");

        for(uint i =0 ;i < _batchDoc.length ;i++){
             HashData memory newHashData = HashData({
          time : block.timestamp,
          sha256Hash : _batchDoc[i].sha256Hash,
          ipfsHash : _batchDoc[i].ipfsHash,
          fileName : _batchDoc[i].fileName
        });
        hashes[msg.sender].push(newHashData);
        }
    }
     
     function shareDocument( uint8 _id , address sluAddress) public payable {
         require(isFirstLevelUser[msg.sender]);
         require(firstLevelUsers[msg.sender].transactionCount > 0, "not enough transactions left");
         require(int(msg.value)>=calculateFeeETH(firstLevelUsers[msg.sender].perTransactionFee,firstLevelUsers[msg.sender].isEUR),"pay assigned transaction fee");

         hashes[sluAddress].push(hashes[msg.sender][_id]);
         firstLevelUsers[msg.sender].transactionCount -- ;
         
     }
     
    function getHashes() public view returns( HashData  [] memory){
        require(isFirstLevelUser[msg.sender],"not first level user");
        return hashes[msg.sender];
    }
    function disableFLU(address _user) public onlyOwner{
        require(isFirstLevelUser[_user],"not first level user");
        isFirstLevelUser[_user] = false;
    }
    
    function calculateFeeETH(int256 _currfee, bool _curr) public view returns (int){
        return (_currfee * (10**18))/(getPrices(_curr));
    }
}