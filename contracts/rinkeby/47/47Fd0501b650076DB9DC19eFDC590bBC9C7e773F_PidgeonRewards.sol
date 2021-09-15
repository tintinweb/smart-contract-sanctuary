// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract PoopyPidgeon {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
}

contract PidgeonRewards is Ownable {
  uint256 private _share = 65 * 10**14; //0.0065 ETH;
  bool public _claimActive = false;
  uint256 public _totalClaimCount = 0;

  mapping(uint256 => bool) public _claimedIds;
  mapping(address => uint256) public _maxClaimablePerAddress;

  struct UnclaimedItems {
      uint unclaimedItemCount;
      uint256[] unclaimedItemIds;
  }

  PoopyPidgeon private pp = PoopyPidgeon(0x490edFB63850eC7387E6D326E27Eec19f246eaa1);

  function _claimableItemCount(address _inputAddress) public view returns(uint256) {
    return _maxClaimablePerAddress[_inputAddress];
  }

  function _unclaimedItemIds(address _inputAddress) public view returns(UnclaimedItems memory) {
    uint tokenCount = pp.balanceOf(_inputAddress);

    UnclaimedItems memory result = UnclaimedItems(0, new uint256[](tokenCount));
    for(uint256 i; i < tokenCount; i++){
        uint tokenId = pp.tokenOfOwnerByIndex(_inputAddress, i);
        if (_claimedIds[tokenId] == false) {
            result.unclaimedItemIds[result.unclaimedItemCount] = tokenId;
            result.unclaimedItemCount +=1;
        }
      }
    return result;
  }

  function claim() public {
    if(msg.sender != owner()) {
      require(_claimActive, "Claim is not Active, wait for your turn");
    }

    uint256 _maxClaimCount = _claimableItemCount(msg.sender);
    UnclaimedItems memory uc_items = _unclaimedItemIds(msg.sender);

    if (uc_items.unclaimedItemCount < _maxClaimCount){
      _maxClaimCount = uc_items.unclaimedItemCount;
    }

    require (_maxClaimCount > 0, "You have claimed rewards or were not eligible");

    for(uint256 i; i < _maxClaimCount; i++) {
      _claimedIds[uc_items.unclaimedItemIds[i]] = true;
    }

    _totalClaimCount += _maxClaimCount;
    _maxClaimablePerAddress[msg.sender] = 0;
    require(payable(msg.sender).send(_maxClaimCount * _share), "Claim payout failed");
  }

  function setclaimBool(bool val) public onlyOwner {
    _claimActive = val;
  }

  function setmaxClaimablePerAddress(address[] memory _addresses, uint256[] memory _nums, uint256 _val) public onlyOwner {
    for(uint256 i; i < _addresses.length ; i++){
      _maxClaimablePerAddress[_addresses[i]] = (_val == 0  ? _nums[i] : _val );
    }
  }

  function setShare(uint256 _newShare) public onlyOwner() {
      _share = _newShare;
  }

  function receiveTotalRewards() public payable {}

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}