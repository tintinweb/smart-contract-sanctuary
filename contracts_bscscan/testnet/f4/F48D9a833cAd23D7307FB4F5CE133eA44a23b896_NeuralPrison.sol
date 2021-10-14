pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBEP20.sol";


interface INeuralPepe {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract NeuralPrison is Ownable {
  uint256 public constant SECONDS_IN_A_DAY = 86400;

  address private _aiTreasuryAddress = 0x5F55507507c8754b80c08A9791C46FfC15482F99;
  address private _bnbTreasuryAddress = 0x5F55507507c8754b80c08A9791C46FfC15482F99;
  address private _aiAddress = 0x390A16E974bFE74625aD76704ad27A07bbbB5558;
  address private _pepeAddress = 0xBa64a2ac955d4456d859F926D51BBc7B6ED3758e;
  
  uint256 public pepeBnbPrice = 150000000000000000;
  uint256 public pepeAiPrice = 50000000000000000000;

  IBEP20 private AI;
  INeuralPepe private PEPE;
  
  mapping(uint256 => uint256) public _pepeRevealed;

  constructor () {
    PEPE = INeuralPepe(_pepeAddress);
    AI = IBEP20(_aiAddress);
  }

  event PepeToPepeSwap(uint256 incomingPepe, uint256 releasedPepe);
  event PepeReleased(uint256 releasedPepe);


  function _isPepeApproved(uint tokenId) private view returns (bool) {
    try PEPE.getApproved(tokenId) returns (address tokenOperator) {
        return tokenOperator == address(this);
    } catch {
        return false;
    }
  }

  function _isPepeApprovedForAll() private view returns (bool) {
    return PEPE.isApprovedForAll(msg.sender, address(this));
  }

  function _isAiApproved() private view returns (uint256) {
    return AI.allowance(msg.sender, address(this));
  }

  function getRandomIndex(uint256 maxIndex) public view returns(uint256){
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % maxIndex;
  }

  function getRandomPepe() private view returns (uint256) {
    uint256 totalPepesInPrison = PEPE.balanceOf(address(this));
    uint256 randomIndex = getRandomIndex(totalPepesInPrison);
    uint256 pepeToSend = PEPE.tokenOfOwnerByIndex(address(this), randomIndex);
    return pepeToSend;
  }

  function _pepeValidReveal(uint256 pepeId) internal view returns (bool) {
    return (block.timestamp - SECONDS_IN_A_DAY) > _pepeRevealed[pepeId];
  }

  function swapPepeForPepe(uint256 incomingTokenId) public {
    require(_pepeValidReveal(incomingTokenId), 'this pepe was in preson less than 24h ago');
    require(PEPE.balanceOf(address(this)) > 0, 'All pepes are free atm');
    require(PEPE.ownerOf(incomingTokenId) == _msgSender(), 'is not token owner');
    require(_isPepeApprovedForAll() || _isPepeApproved(incomingTokenId), 'contract is missing approvement for pepe transfer');
    require(AI.balanceOf(_msgSender()) >= pepeAiPrice && _isAiApproved() > pepeAiPrice, 'Not enough ai or allowance');


    uint256 tokenToSend = getRandomPepe();
    claimAI(tokenToSend);
    AI.transferFrom(_msgSender(), _aiTreasuryAddress, pepeAiPrice);
    PEPE.safeTransferFrom(_msgSender(), address(this), incomingTokenId);
    PEPE.safeTransferFrom(address(this), _msgSender(), tokenToSend);

    _pepeRevealed[tokenToSend] = block.timestamp;

    emit PepeToPepeSwap(incomingTokenId, tokenToSend);
  }

  function buyPepe() public payable {
    require(PEPE.balanceOf(address(this)) > 0, 'All pepes are free atm');
    require(pepeBnbPrice == msg.value, "BNB value sent is not correct");

    uint256 tokenToSend = getRandomPepe();
    claimAI(tokenToSend);
    PEPE.safeTransferFrom(address(this), msg.sender, tokenToSend);
    _pepeRevealed[tokenToSend] = block.timestamp;

    emit PepeReleased(tokenToSend);
  }

  function claimAI(uint256 tokenId) internal {
    uint256[] memory tokenToClaim = new uint256[](1);
    tokenToClaim[0] = tokenId;

    AI.claim(tokenToClaim);
    uint256 balance = AI.balanceOf(address(this));
    AI.transfer(_aiTreasuryAddress, balance);
  }

  /**
    * @dev Changes the AI treasury address
  */
  function changeAiTreasuryAddress(address newAddress) onlyOwner public {
      require(newAddress != address(0), 'cannot be zero address');
      _aiTreasuryAddress = newAddress;
  }

  /**
    * @dev Changes the BNB treasury address
  */
  function changeBnbTreasuryAddress(address newAddress) onlyOwner public {
      require(newAddress != address(0), 'cannot be zero address');
      _bnbTreasuryAddress = newAddress;
  }

  /**
    * @dev Changes the AI contract address
  */
  function changeAiAddress(address newAddress) onlyOwner public {
      require(newAddress != address(0), 'cannot be zero address');
      _aiAddress = newAddress;
      AI = IBEP20(_aiAddress);
  }

  /**
    * @dev Changes the Pepe contract address
  */
  function changePepeAddress(address newAddress) onlyOwner public {
      require(newAddress != address(0), 'cannot be zero address');
      _pepeAddress = newAddress;
      PEPE = INeuralPepe(_pepeAddress);
  }

  /**
    * @dev Changes the Pepe contract address
  */
  function changePepeBnbPrice(uint256 newPrice) onlyOwner public {
    require(newPrice >= 10000000000000000, 'value cannot be less then 0.01bnb');
    pepeBnbPrice = newPrice;
  }

  /**
    * @dev Changes the Pepe contract address
  */
  function changePepeAiPrice(uint256 newPrice) onlyOwner public {
    require(newPrice >= 1000000000000000000, 'value cannot be less then 1 ai');
    pepeAiPrice = newPrice;
  }

  /**
    * @dev returns 30 tokens
  */
  function releasePepes() onlyOwner public {
    uint256 pepeBalance = PEPE.balanceOf(address(this));
    uint256 txlimit = pepeBalance > 30 ? 30 : pepeBalance;

    for(uint256 i = 0; i < txlimit; i++) {
      uint256 tokenId = PEPE.tokenOfOwnerByIndex(address(this), i);
      PEPE.safeTransferFrom(address(this), owner(), tokenId);
    }
  }

    /**
    * @dev Return randox X tokens
  */
  function releaseRandomPepes(uint256 n) onlyOwner public {
    require(n > 0 && n < 30, 'wrong n');
    uint256 pepeBalance = PEPE.balanceOf(address(this));
    uint256 txlimit = pepeBalance < n ? pepeBalance : n;

    for(uint256 i = 0; i < txlimit; i++) {
      uint256 tokenToSend = getRandomPepe();
      PEPE.safeTransferFrom(address(this), owner(), tokenToSend);

    }
  }

  

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external pure returns(bytes4){
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  function basicTransfer(address recipient, uint256 amount) external returns (bool);
  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  function burn(uint256 burnQuantity) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function changeIsSwap(bool _inSwap) external;

  function claim(uint256[] memory tokenIndices) external returns (uint256);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}