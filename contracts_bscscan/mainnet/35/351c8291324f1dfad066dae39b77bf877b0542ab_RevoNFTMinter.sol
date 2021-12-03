/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

interface IRevoTokenContract{
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IRevoLib{
  function getLiquidityValue(uint256 liquidityAmount) external view returns (uint256 tokenRevoAmount, uint256 tokenBnbAmount);
  function getLpTokens(address _wallet) external view returns (uint256);
  function tokenRevoAddress() external view returns (address);
  function calculatePercentage(uint256 _amount, uint256 _percentage, uint256 _precision, uint256 _percentPrecision) external view returns (uint256);
}

interface IRevoNFT{
  function nftsDbIds(string memory _collection, string memory _dbId) external view returns (uint256);
  function mintRevo(address _to, string memory _collection, string memory _dbId) external;
  function nextRevoId() external returns(uint256);
}

interface IRevoNFTUtils{
    struct PENDING_TX {
        uint256 itemIndex;
        string dbId;
        string collection;
        uint256 uniqueId;
        string itemType;
        address sender;
    }

    function dequeuePendingTx() external returns (PENDING_TX memory data);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() public view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function owner2() public view returns (address) {
        return _owner2;
    }

    function setOwner2(address _address) public onlyOwner{
        _owner2 = _address;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender() || _owner2 == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RevoNFTMinter is Ownable {
    address public revoAddress;
    IRevoTokenContract private revoToken;
    address public revoLibAddress;
    IRevoLib private revoLib;
    
    IRevoNFT private revoNFT;

    IRevoNFTUtils private revoNFTUtils;
    
    uint256[] public indexes;
    string[] public dbIds;
    
    constructor(address _revoLibAddress, address _revoNFT, address _revoNFTUtils) public{
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        setRevoNFTUtils(_revoNFTUtils);
    }
    
    /*
    Set revo Address & token
    */
    function setRevo(address _revo) public onlyOwner {
        revoAddress = _revo;
        revoToken = IRevoTokenContract(revoAddress);
    }
    
    /*
    Set revoLib Address & libInterface
    */
    function setRevoLib(address _revoLib) public onlyOwner {
        revoLibAddress = _revoLib;
        revoLib = IRevoLib(revoLibAddress);
    }
    
    function setRevoNFT(address _revoNFT) public onlyOwner {
        revoNFT = IRevoNFT(_revoNFT);
    }

    function setRevoNFTUtils(address _revoNFTUtils) public onlyOwner {
        revoNFTUtils = IRevoNFTUtils(_revoNFTUtils);
    }
    
    function mintRevoSimilarNFTBatch(address[] memory _receivers, string memory _collection, string[] memory _dbId) public onlyOwner {
        indexes = new uint256[](_receivers.length);
        dbIds = new string[](_receivers.length);
        
        for(uint256 i=0; i < _receivers.length; i++){
            revoNFT.mintRevo(_receivers[i], _collection, _dbId[i]);
            indexes[i] = revoNFT.nextRevoId();
            dbIds[i] = _dbId[i];
        }
    }

    function mintNFT(address _receiver, string memory _collection, string memory _dbId) public onlyOwner {
        revoNFT.mintRevo(_receiver, _collection, _dbId);
    }

    function mintNFTAndDequeue(address _receiver, string memory _collection, string memory _dbId) public onlyOwner {
        revoNFT.mintRevo(_receiver, _collection, _dbId);
        revoNFTUtils.dequeuePendingTx();
    }
    
    function getLastIndexes() public view returns(uint256[] memory){
        return indexes;
    }
    
    function getLastDbIds() public view returns(string[] memory){
        return dbIds;
    }
}