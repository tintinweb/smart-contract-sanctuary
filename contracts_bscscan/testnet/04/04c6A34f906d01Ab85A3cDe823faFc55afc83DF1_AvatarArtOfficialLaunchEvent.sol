// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IAvatarArtNFT.sol";
import "./interfaces/IERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Runnable.sol";

contract AvatarArtOfficialLaunchEvent is ReentrancyGuard, Runnable {
    struct UserClaimedInfo{
        uint256 tokenId;
        uint256 nftType;
    }

     modifier onlyAdmin{
        require(_admins[_msgSender()], "Forbidden");
        _;
    }

    mapping(address => bool) public _admins;

    IAvatarArtNFT public _avatarArtNFT;

    //Store NFT type: Silver, Gold, ..., starts from 1
    uint256[] public _nftTypes;
    mapping(uint256 => uint256) public _nftTypePoints;
    mapping(uint256 => uint256) public _nftTypeLimitAmounts;
    mapping(uint256 => uint256) public _nftTypeMintedTotals;

    mapping(uint256 => uint256) public _nftTypeUserLimitAmounts;

    mapping(address => uint256) public _userPoints;
    mapping(address => uint256) public _userUsedPoints;

    mapping(address => UserClaimedInfo[]) public _userClaimedInfos;

    //Mapping: account => nftType => number of claimed NFT
    mapping(address => mapping(uint256 => uint256)) public _userClaimedNfts;

    constructor(
        IAvatarArtNFT avatarArtNFT) {
        require(
            address(avatarArtNFT) != address(0),
            "avatarArtNFT is zero address"
        );
        _avatarArtNFT = avatarArtNFT;
        _nftTypes = [1, 2];
        _nftTypePoints[1] = 150;
        _nftTypePoints[2] = 200;

        _nftTypeLimitAmounts[1] = 1500;
        _nftTypeLimitAmounts[2] = 500;

        _nftTypeUserLimitAmounts[1] = 3;
        _nftTypeUserLimitAmounts[2] = 2;
    }

    function updateUserPoint(address account, uint256 point)
        external
        nonReentrant
        onlyAdmin
    {
        require(account != address(0), "Zero address");
        require(point > 0, "Point is 0");
        _userPoints[account] = point;

        emit UserPointUpdated(account, point);
    }

    function updateUserPoints(address[] memory accounts, uint256[] memory points)
        external
        nonReentrant
        onlyAdmin
    {
        require(accounts.length > 0, "accounts is empty");
        require(accounts.length == points.length, "accounts and points mismatch");
        for (uint256 index = 0; index < accounts.length; index++) {
            address account = accounts[index];
            uint256 point = points[index];
            require(point > 0, "Point is 0");
            _userPoints[account] = point;

            emit UserPointUpdated(account, point);
        }
    }

    function claimNFT(uint256 nftType)
        external
        nonReentrant
        whenRunning
    {
        require(isNftTypeExisted(nftType), "nftType does not exist");
        require(_nftTypeMintedTotals[nftType] + 1 <= _nftTypeLimitAmounts[nftType], "Reach limitation of minting nft type amount");
        require(_userPoints[_msgSender()] - _userUsedPoints[_msgSender()] >=  _nftTypePoints[nftType], "Not enough point");
        require(_userClaimedNfts[_msgSender()][nftType] < _nftTypeUserLimitAmounts[nftType], "Reach limitation of minting user nft type amount");

        uint256 tokenId = _avatarArtNFT.mint(_msgSender());

        _userClaimedNfts[_msgSender()][nftType]++;
        _userUsedPoints[_msgSender()] += _nftTypePoints[nftType];
        _nftTypeMintedTotals[nftType]++;
        _userClaimedInfos[_msgSender()].push(UserClaimedInfo(tokenId, nftType));
        emit NFTClaimed(_msgSender(), tokenId, nftType);
    }

    function setNftTypes(uint256[] memory nftTypes)
        external
        nonReentrant
        onlyOwner
    {
        require(nftTypes.length > 0, "nftTypes is empty");
        _nftTypes = nftTypes;
    }

    function setNftTypePoint(uint256 nftType, uint256 point)
        external
        nonReentrant
        onlyOwner
    {
        require(isNftTypeExisted(nftType), "nftType does not exist");
        require(point > 0, "point is 0");
        _nftTypes[nftType] = point;
    }

    function setNftTypePoints(uint256[] memory nftTypes, uint256[] memory points)
        external
        nonReentrant
        onlyOwner
    {
        require(nftTypes.length > 0, "nftTypes is empty");
        require(
            nftTypes.length == points.length,
            "nftTypes and points mismatch"
        );

        for (uint256 index = 0; index < nftTypes.length; index++) {
            uint256 nftType = nftTypes[index];
            uint256 point = points[index];
            require(isNftTypeExisted(nftType), "nftType does not exist");
            require(point > 0, "point is 0");
            _nftTypes[nftType] = point;
        }
    }

    function setNftTypeUserLimitAmount(uint256 nftType, uint256 value)
        external
        nonReentrant
        onlyOwner
    {
        require(isNftTypeExisted(nftType), "nftType does not exist");
        require(value > 0, "value is 0");
        _nftTypeUserLimitAmounts[nftType] = value;
    }

    function setNftTypeUserLimitAmounts(uint256[] memory nftTypes, uint256[] memory values)
        external
        nonReentrant
        onlyOwner
    {
        require(nftTypes.length > 0, "nftTypes is empty");
        require(
            nftTypes.length == values.length,
            "nftTypes and values mismatch"
        );

        for (uint256 index = 0; index < nftTypes.length; index++) {
            uint256 nftType = nftTypes[index];
            uint256 value = values[index];
            require(isNftTypeExisted(nftType), "nftType does not exist");
            require(value > 0, "value is 0");
            _nftTypeUserLimitAmounts[nftType] = value;
        }
    }

        function setNftTypeLimitAmount(uint256 nftType, uint256 value)
        external
        nonReentrant
        onlyOwner
    {
        require(isNftTypeExisted(nftType), "nftType does not exist");
        require(value > 0, "value is 0");
        _nftTypeLimitAmounts[nftType] = value;
    }

    function setNftTypeLimitAmounts(uint256[] memory nftTypes, uint256[] memory values)
        external
        nonReentrant
        onlyOwner
    {
        require(nftTypes.length > 0, "nftTypes is empty");
        require(
            nftTypes.length == values.length,
            "nftTypes and values mismatch"
        );

        for (uint256 index = 0; index < nftTypes.length; index++) {
            uint256 nftType = nftTypes[index];
            uint256 value = values[index];
            require(isNftTypeExisted(nftType), "nftType does not exist");
            require(value > 0, "value is 0");
            _nftTypeLimitAmounts[nftType] = value;
        }
    }

    function isNftTypeExisted(uint256 nftType) public view returns (bool) {
        for (uint256 index = 0; index < _nftTypes.length; index++) {
            if (_nftTypes[index] == nftType) return true;
        }
        return false;
    }

    function getUserClaimedInfos(address account) external view returns(UserClaimedInfo[] memory){
        return _userClaimedInfos[account];
    }

    function setAvatarArtNFT(IAvatarArtNFT avatarArtNFT) external onlyOwner {
         require(
            address(avatarArtNFT) != address(0),
            "avatarArtNFT is zero address"
        );
        _avatarArtNFT = avatarArtNFT;
    }

    function setAdmin(address adminAddress, bool value) public onlyOwner{
        _admins[adminAddress] = value;
    }

    function withdrawToken(
        address tokenAddress,
        address recepient,
        uint256 value
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(recepient, value);
    }

    event UserPointUpdated(address account, uint256 point);
    event NFTClaimed(address account, uint256 tokenId, uint256 nftType);
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

interface IAvatarArtNFT{
    function mint(address to) external returns(uint256);
    function setContractOwner(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}