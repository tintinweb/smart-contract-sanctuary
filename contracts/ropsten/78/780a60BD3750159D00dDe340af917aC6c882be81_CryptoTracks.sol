/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


// 
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

// 
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

// 
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// 
contract CryptoTracks is Ownable, ReentrancyGuard {
  struct Tune {
    uint t1;
    uint t2;
    uint t3;
    uint t4;
    uint t5;
    uint t6;
    uint t7;
    uint t8;
  }

  mapping(address => uint[]) myFavorites;
  mapping(uint => uint) favoriteCount;
  uint favoriteFee = 0.001 ether;
  mapping(uint => address) tuneOwner;
  mapping(address => uint) artistTuneCount;
  Tune[] tunes;

  constructor() {
    uint _t1 = 1510101010000000005005005005000000000000165165165165000000;
    uint _t2 = 1510101010000020000000000000020000000180000000000000180000;
    uint _t3 = 1510101010000004000124000124004000000164000084000084164000;
    uint _t4 = 2101101010000009000000000000009000000169000000000000169000;
    uint _t5 = 15059004000000010000330330330010000000170000410410410170000;
    uint _t6 = 15059004000000020000000000000020000000180000000000000180000;
    uint _t7 = 1510101010000019000000019019000000000179000000179179000000;
    uint _t8 = 1510101010000019000000019000000000000179000000179000000000;
    tunes.push(Tune(_t1, _t2, _t3, _t4, _t5, _t6, _t7, _t8));
    uint tuneId = tunes.length - 1;
    tuneOwner[tuneId] = _msgSender();
    artistTuneCount[_msgSender()]++;
  }

  function getTune(uint _id) public view returns(
    uint, uint, uint, uint,
    uint, uint, uint, uint,
    address, uint) {
    Tune storage tune = tunes[_id];
    require(tune.t1 != 0);
    address thisTuneOwner = tuneOwner[_id];
    uint favCount = favoriteCount[_id];
    return (tune.t1, tune.t2, tune.t3, tune.t4,
    tune.t5, tune.t6, tune.t7, tune.t8,
    thisTuneOwner, favCount);
  }

  function getTunesLength() public view returns (uint) {
    return tunes.length;
  }

  function publishTune(uint _t1, uint _t2, uint _t3, uint _t4,
    uint _t5, uint _t6, uint _t7, uint _t8) nonReentrant external payable returns (uint) {
    require(_t1 != 0);
    tunes.push(Tune(_t1, _t2, _t3, _t4, _t5, _t6, _t7, _t8));
    uint tuneId = tunes.length - 1;
    tuneOwner[tuneId] = _msgSender();
    artistTuneCount[_msgSender()]++;
    return tuneId;
  }

  function getArtistTunes(address _artist) public view returns(uint[] memory) {
    uint[] memory theseTunes = new uint[](artistTuneCount[_artist]);
    uint inc = 0;
    for (uint i = 0; i < tunes.length; i++) {
      if (tuneOwner[i] == _artist) {
        theseTunes[inc] = i;
        inc++;
      }
    }
    return theseTunes;
  }

  function getMyFavorites() public view returns(uint[] memory) {
    return myFavorites[_msgSender()];
  }

  function favorite(uint _id) nonReentrant external payable {
    require(tuneOwner[_id] != address(0));
    Tune storage tune = tunes[_id];
    require(tune.t1 != 0);
    require(msg.value >= favoriteFee);
    for (uint i = 0; i < myFavorites[_msgSender()].length; i++) {
      require(_id != myFavorites[_msgSender()][i]);
    }
    favoriteCount[_id]++;
    payable(tuneOwner[_id]).transfer(msg.value);
    myFavorites[_msgSender()].push(_id);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setFavoriteFee(uint _fee) external onlyOwner {
    favoriteFee = _fee;
  }
}