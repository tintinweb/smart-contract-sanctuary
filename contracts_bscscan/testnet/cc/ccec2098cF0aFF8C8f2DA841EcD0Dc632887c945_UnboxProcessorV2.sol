// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IElemonInfo.sol";
import "./interfaces/IElemonNFT.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract UnboxProcessorV2 is ReentrancyGuard, Runnable
{
    enum EBoxType{
        Box1And2,
        Box3
    }

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IElemonNFT public _box1And2NFT;
    IElemonNFT public _box3NFT;

    IElemonNFT public _elemonNFT;

    constructor(
        IElemonNFT box1And2NFT,
        IElemonNFT box3NFT,
        IElemonNFT elemonNFT
    ) {
        _elemonNFT = elemonNFT;
        _box1And2NFT = box1And2NFT;
        _box3NFT = box3NFT;
    }

    function submitBox(EBoxType boxType, uint256 boxTokenId) external nonReentrant whenRunning {
        require(boxTokenId > 0, "boxTokenId should be greater than 0");

        if(boxType == EBoxType.Box1And2){
            _box1And2NFT.safeTransferFrom(_msgSender(), BURN_ADDRESS, boxTokenId);
        }else{
            _box3NFT.safeTransferFrom(_msgSender(), BURN_ADDRESS, boxTokenId);
        }

        uint256 elemonTokenId1 = _elemonNFT.mint(_msgSender());
        uint256 elemonTokenId2 = _elemonNFT.mint(_msgSender());
        uint256 elemonTokenId3 = _elemonNFT.mint(_msgSender());
        
        emit BoxSubmited(_msgSender(), boxType, boxTokenId, elemonTokenId1, elemonTokenId2, elemonTokenId3);
    }

    function setElemonNFT(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address 0");
        _elemonNFT = IElemonNFT(newAddress);
    }

    function withdrawToken(
        address tokenAddress,
        address recepient,
        uint256 value
    ) public onlyOwner {
        IERC20(tokenAddress).transfer(recepient, value);
    }

    function batchWithdrawNft(address nftAddress, uint256[] memory tokenIds, address recipient) external onlyOwner{
        require(recipient != address(0), "recipient is zero address");
        require(tokenIds.length > 0, "tokenIds is empty");
        for (uint256 index = 0; index < tokenIds.length; index++) {
            IERC721(nftAddress).safeTransferFrom(address(this), recipient, tokenIds[index]);
        }
    }

    event BoxSubmited(address account, EBoxType boxType, uint256 boxTokenId, uint256 elemonTokenId1, uint256 elemonTokenId2, uint256 elemonTokenId3);
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

interface IElemonNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
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