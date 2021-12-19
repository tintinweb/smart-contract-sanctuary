// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IElemonInfo.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract ElemonStarOperator is ReentrancyGuard, Runnable{
    address public _recipientAddress;

    IERC20 public _elmonToken;
    IERC721 public _elemonNft;
    IElemonInfo public _elemonInfo;

    uint256[] public _stars;
    mapping(uint256 => uint256) public _starPrices;

    constructor(IERC721 elemonNft, IERC20 elmonToken, IElemonInfo elemonInfo, address recipientAddress){
        _elemonNft = elemonNft;
        _elemonInfo = elemonInfo;
        _recipientAddress = recipientAddress;        
        _elmonToken = elmonToken;

        _stars = [1,2,3,4,5,6,7,8,9];
        _starPrices[1] = 100000000000000000000;
        _starPrices[2] = 150000000000000000000;
        _starPrices[3] = 200000000000000000000;
        _starPrices[4] = 250000000000000000000;
        _starPrices[5] = 300000000000000000000;
        _starPrices[6] = 350000000000000000000;
        _starPrices[7] = 400000000000000000000;
        _starPrices[8] = 450000000000000000000;
        _starPrices[9] = 500000000000000000000;
    }

    function upgradeStar(uint256 tokenId, uint256 star) external nonReentrant whenRunning{
        require(_stars.length > 0, "_stars is empty");
        require(isExisted(star), "Star does not exist");
        require(_elemonNft.ownerOf(tokenId) == _msgSender(), "Not owner");
        require(_elemonInfo.getBaseCardId(tokenId) != 0, "Invalid tokenId");
        require(_elemonInfo.getStar(tokenId) + 1 == star, "Invalid star");

        require(_elmonToken.transferFrom(_msgSender(), _recipientAddress, _starPrices[star]), "Can not transfer token");

        _elemonInfo.setStar(tokenId, star);
        emit ElemonStarUpgraded(tokenId, star);
    }

    function adminUpgradeStar(uint256 tokenId, uint256 star) external nonReentrant onlyOwner{
        require(_stars.length > 0, "_stars is empty");
        require(isExisted(star), "Star does not exist");

        _elemonInfo.setStar(tokenId, star);
        emit ElemonStarUpgraded(tokenId, star);
    }

    function configureRecipientTokenAddress(address recipientAddress) external onlyOwner{
        require(recipientAddress != address(0), "Address 0");
        _recipientAddress = recipientAddress;
    }

    function configureStar(uint256[] memory stars) external onlyOwner{
        require(stars.length > 0, "stars is empty");
        _stars = stars;
    }

    function configureStarPrice(uint256 star, uint256 price) external onlyOwner{
        require(isExisted(star), "Star does not exist");
        _starPrices[star] = price;
        emit StarPriceUpdated(star, price);
    }

    function configureElemonNft(IERC721 elemonNft) external onlyOwner{
        require(address(elemonNft) != address(0), "Address 0");
        _elemonNft = elemonNft;
    }

    function configureElmonToken(IERC20 elmonToken) external onlyOwner{
        require(address(elmonToken) != address(0), "Address 0");
        _elmonToken = elmonToken;
    }

    function configureElemonInfo(IElemonInfo  newAddress) external onlyOwner{
        require(address(newAddress) != address(0), "Address 0");
        _elemonInfo = IElemonInfo(newAddress);
    }

    function isExisted(uint256 star) public view returns(bool){
        for (uint256 index = 0; index < _stars.length; index++) {
            if(_stars[index] == star) return true;
        }
        return false;
    }

    event StarPriceUpdated(uint256 star, uint256 price);
    event ElemonStarUpgraded(uint256 tokenId, uint256 star);
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
    uint256 public constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

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
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
     _owner = _msgSender();
     emit OwnershipTransferred(address(0), _msgSender());
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

interface IElemonInfo {
    struct Info {
        uint256 rarity;
        uint256 baseCardId;
        uint256[6] bodyParts;
        uint256 quality;
        uint256 class;
        uint256 star;
    }

    function getTokenInfo(uint256 tokenId) external returns(Info memory);
    function getTokenInfoValues(uint256 tokenId) external view 
        returns (uint256 rarity, uint256 baseCardId, uint256[] memory bodyParts, uint256 quality, uint256 class, uint256 star);
    function getRarity(uint256 tokenId) external view returns(uint256);
    function getBaseCardId(uint256 tokenId) external view returns (uint256);
    function getBodyPart(uint256 tokenId) external view returns (uint256[] memory);
    function getQuality(uint256 tokenId) external view returns (uint256);
    function getClass(uint256 tokenId) external view returns (uint256);
    function getStar(uint256 tokenId) external view returns (uint256);

    function setRarity(uint256 tokenId, uint256 rarity) external;
    function setBodyParts(uint256 tokenId, uint256[6] memory bodyParts) external;
    function setQuality(uint256 tokenId, uint256 quality) external;
    function setClass(uint256 tokenId, uint256 class) external;
    function setStar(uint256 tokenId, uint256 star) external;
    function setInfo(
        uint256 tokenId,
        uint256 baseCardId,
        uint256[6] memory bodyParts,
        uint256 quality,
        uint256 class,
        uint256 rarity,
        uint256 star
    ) external;
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