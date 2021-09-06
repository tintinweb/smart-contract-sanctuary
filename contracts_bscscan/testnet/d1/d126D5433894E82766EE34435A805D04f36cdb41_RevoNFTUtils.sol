/**
 *Submitted for verification at BscScan.com on 2021-09-05
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract RevoNFTUtils is Ownable {
    address public revoAddress;
    IRevoTokenContract private revoToken;
    address public revoLibAddress;
    IRevoLib private revoLib;
    
    IRevoNFT private revoNFT;
    
    uint256 private nextRevoId;
    uint256 public revoFees;
    
    event CreateNFT(address sender, string dbId, string collection);
    
    mapping(address => mapping(string => mapping(string => uint256))) public triggerMintHistory;

    constructor(address _revoLibAddress, address _revoNFT) public{
        setRevoLib(_revoLibAddress);
        setRevo(revoLib.tokenRevoAddress());
        setRevoNFT(_revoNFT);
        
        revoFees = 1;
    }
    
    function triggerCreateNFT(string memory _dbId, string memory _collection) public {
        revoToken.transferFrom(msg.sender, address(this), revoFees);
        
        triggerMintHistory[msg.sender][_collection][_dbId] = revoFees;
        
        emit CreateNFT(msg.sender, _dbId, _collection);
    }
    
    function setRevoFees(uint256 _fees) public onlyOwner {
        revoFees = _fees;
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
    
    function withdrawRevo(uint256 _amount) public onlyOwner {
        revoToken.transferFrom(address(this), owner(), _amount);
    }
}