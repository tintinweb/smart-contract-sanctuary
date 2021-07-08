/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IJGNNFT {
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function burn(address _owner, uint256 _id, uint256 _value) external;
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

interface IDuckLootBox {
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}


contract DuckLootBox is Ownable {

  IJGNNFT public JGNNFT;
  mapping(uint => uint) public lootboxTokens;
  uint lastId = 1;

  uint public lootboxTokenId;
  uint public tokensPerLootBox;

  uint seed = 0;
  
  // _proxyRegistryAddress - 0xa5409ec958c83c3f309868babaca7c86dcb077c1
  constructor(address _JGNNFT, uint _lootboxTokenId, uint _tokensPerLootBox) {
    JGNNFT = IJGNNFT(_JGNNFT);
    lootboxTokenId = _lootboxTokenId;
    tokensPerLootBox = _tokensPerLootBox;
  }

  function addTokensToLootbox(uint[] calldata _tokenIds) public onlyOwner {
    for(uint i = 0; i < _tokenIds.length; i++) {
      lootboxTokens[lastId] = _tokenIds[i];
      lastId++;
    }
  }

  function replaceTokenFromLootbox(uint _id, uint _tokenId) public onlyOwner {
    require(_id < lastId, "function only for replacement");
    lootboxTokens[_id] = _tokenId;
  }
  
  function unpack(uint amount) public {
    require(msg.sender == tx.origin, "can be used only by address");
    require(amount > 0, "amount should be more than 0");
    require(JGNNFT.balanceOf(msg.sender, lootboxTokenId) >= amount, "exceed user amount");

    JGNNFT.burn(msg.sender, lootboxTokenId, amount);
            
    uint tokenId;

    for(uint k = 0; k < amount; k++) {
      uint[] memory tokens = new uint[](tokensPerLootBox);
      uint[] memory amounts = new uint[](tokensPerLootBox);
      
      bool done;
      for(uint i = 0; i < tokensPerLootBox; i++) {
        for(uint j = 0; j < 20; j++) {
          done = false;
          uint randomNumber = uint(blockhash(block.number)) / 1e18 + seed;
          seed += block.number;

          tokenId = lootboxTokens[(randomNumber % (lastId - 1)) + 1];
          if(JGNNFT.balanceOf(address(this), tokenId) > 0) {
            done = true;
            break;
          }
        }

        require(done, "lootbox is almost empty");
        tokens[i] = tokenId;
        amounts[i] = 1;
      }

      JGNNFT.safeBatchTransferFrom(address(this), msg.sender, tokens, amounts, "0x");
      seed = 0;
    }
    
  }

  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4) {
    return IDuckLootBox.onERC1155BatchReceived.selector; 
  }
  
}