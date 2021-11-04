//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./utils/Ownable.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract ElemonMarketplace is Runnable, ReentrancyGuard, IERC721Receiver{
    struct MarketHistory{
        address buyer;
        address seller;
        uint256 price;
        uint256 time;
    }
    
    address public _elemonTokenAddress;
    address public _elemonNftAddress;
    address public _feeRecepientAddress;
    
    uint256 private _burningFeePercent;       //Multipled by 1000
    uint256 private _ecoFeePercent;       //Multipled by 1000
    uint256 constant public MULTIPLIER = 1000;
    
    //Mapping between tokenId and token price
    mapping(uint256 => uint256) internal _tokenPrices;
    
    //Mapping between tokenId and owner of tokenId
    mapping(uint256 => address) internal _tokenOwners;
    
    constructor(address tokenAddress, address nftAddress){
        require(tokenAddress != address(0), "Address 0");
        require(nftAddress != address(0), "Address 0");
        _elemonTokenAddress = tokenAddress;
        _elemonNftAddress = nftAddress;
        _feeRecepientAddress = _msgSender();
        _burningFeePercent = 2000;        //2%
        _ecoFeePercent = 2000;        //2%
    }
    
    /**
     * @dev Create a sell order to sell ELEMON
     * User transfer his NFT to contract to create selling order
     * Event is used to retreive logs and histories
     */
    function createSellOrder(uint256 tokenId, uint256 price) external whenRunning nonReentrant returns(bool){
        //Validate
        require(_tokenOwners[tokenId] == address(0), "Can not create sell order for this token");
        IERC721 elemonContract = IERC721(_elemonNftAddress);
        require(elemonContract.ownerOf(tokenId) == _msgSender(), "You have no permission to create sell order for this token");
        
        //Transfer Elemon NFT to contract
        elemonContract.safeTransferFrom(_msgSender(), address(this), tokenId);
        
        _tokenOwners[tokenId] = _msgSender();
        _tokenPrices[tokenId] = price;
        
        emit NewSellOrderCreated(_msgSender(), tokenId, price, _now());
        
        return true;
    }
    
    /**
     * @dev User that created selling order cancels that order
     * Event is used to retreive logs and histories
     */ 
    function cancelSellOrder(uint256 tokenId) external nonReentrant returns(bool){
        require(_tokenOwners[tokenId] == _msgSender(), "Forbidden to cancel sell order");

        IERC721 elemonContract = IERC721(_elemonNftAddress);

        //Transfer Elemon NFT from contract to sender
        elemonContract.safeTransferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        
        emit SellingOrderCanceled(tokenId, _now());
        
        return true;
    }
    
    /**
     * @dev Get token info about price and owner
     */ 
    function getTokenInfo(uint256 tokenId) external view returns(address, uint){
        return (_tokenOwners[tokenId], _tokenPrices[tokenId]);
    }
    
    /**
     * @dev Get purchase fee percent, this fee is for seller
     */ 
    function getFeePercent() external view returns(uint256 burningFeePercent, uint256 ecoFeePercent){
        burningFeePercent = _burningFeePercent;
        ecoFeePercent = _ecoFeePercent;
    }
    
    /**
     * @dev Get token price
     */ 
    function getTokenPrice(uint256 tokenId) external view returns(uint256){
        return _tokenPrices[tokenId];
    }
    
    /**
     * @dev Get token's owner
     */ 
    function getTokenOwner(uint256 tokenId) external view returns(address){
        return _tokenOwners[tokenId];
    }
    
    function purchase(uint256 tokenId) external whenRunning nonReentrant returns(uint256){
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0),"Token has not been added");
        
        uint256 tokenPrice = _tokenPrices[tokenId];
        uint256 ownerReceived = tokenPrice;
        if(tokenPrice > 0){
            IERC20 elemonTokenContract = IERC20(_elemonTokenAddress);    
            require(elemonTokenContract.transferFrom(_msgSender(), address(this), tokenPrice));
            uint256 feeAmount = 0;
            if(_burningFeePercent > 0){
                feeAmount = tokenPrice * _burningFeePercent / 100 / MULTIPLIER;
                if(feeAmount > 0){
                    require(elemonTokenContract.transfer(address(0), feeAmount), "Fail to transfer fee to address(0)");
                    ownerReceived -= feeAmount;
                }
            }
            if(_ecoFeePercent > 0){
                feeAmount = tokenPrice * _ecoFeePercent / 100 / MULTIPLIER;
                if(feeAmount > 0){
                    require(elemonTokenContract.transfer(_feeRecepientAddress, feeAmount), "Fail to transfer fee to eco address");
                    ownerReceived -= feeAmount;
                }
            }
            require(elemonTokenContract.transfer(tokenOwner, ownerReceived), "Fail to transfer token to owner");
        }
        
        //Transfer Elemon NFT from contract to sender
        IERC721(_elemonNftAddress).transferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        
        emit Purchased(_msgSender(), tokenOwner, tokenId, tokenPrice, _now());
        
        return tokenPrice;
    }

    function setFeeRecepientAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _feeRecepientAddress = newAddress;
    }
    
    /**
     * @dev Set ELEMON contract address 
     */
    function setElemonNftAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _elemonNftAddress = newAddress;
    }
    
    /**
     * @dev Set ELEMON token address 
     */
    function setElemonTokenAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _elemonTokenAddress = newAddress;
    }
    
    /**
     * @dev Get ELEMON token address 
     */
    function setFeePercent(uint256 burningFeePercent, uint256 ecoFeePercent) external onlyOwner{
        require(burningFeePercent < 100 * MULTIPLIER, "Invalid burning fee percent");
        require(ecoFeePercent < 100 * MULTIPLIER, "Invalid ecosystem fee percent");
        _burningFeePercent = burningFeePercent;
        _ecoFeePercent = ecoFeePercent;
    }

    /**
     * @dev Owner withdraws ERC20 token from contract by `tokenAddress`
     */
    function withdrawToken(address tokenAddress, address recepient) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recepient, token.balanceOf(address(this)));
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
    
    event NewSellOrderCreated(address seller, uint256 tokenId, uint256 price, uint256 time);
    event Purchased(address buyer, address seller, uint256 tokenId, uint256 price, uint256 time);
    event SellingOrderCanceled(uint256 tokenId, uint256 time);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Runnable is Ownable{
    modifier whenRunning{
        require(_isRunning, "Paused");
        _;
    }
    
    modifier whenNotRunning{
        require(!_isRunning, "Running");
        _;
    }
    
    bool public _isRunning;
    
    constructor(){
        _isRunning = true;
    }
    
    function toggleRunning() public onlyOwner{
        _isRunning = !_isRunning;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function isExisted(uint256 tokenId) external view returns(bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}