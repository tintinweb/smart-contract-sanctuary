/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: contracts/IPoolRestrictions.sol

pragma solidity 0.6.12;


interface IPoolRestrictions {
    function getMaxTotalSupply(address _pool) external virtual view returns(uint256);
    function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external virtual view returns(bool);
    function isWithoutFee(address _addr) external virtual view returns(bool);
}

// File: contracts/PoolRestrictions.sol

pragma solidity 0.6.12;




contract PoolRestrictions is IPoolRestrictions, Ownable {

  event SetTotalRestrictions(address indexed token, uint256 maxTotalSupply);
  event SetSignatureAllowed(bytes4 indexed signature, bool allowed);
  event SetSignatureAllowedForAddress(address indexed voting, bytes4 indexed signature, bool allowed, bool overrideAllowed);
  event SetWithoutFee(address indexed addr, bool withoutFee);

  struct TotalRestrictions {
    uint256 maxTotalSupply;
  }
  // token => restrictions
  mapping(address => TotalRestrictions) public totalRestrictions;

  // signature => allowed
  mapping(bytes4 => bool) public signaturesAllowed;

  struct VotingSignature {
    bool allowed;
    bool overrideAllowed;
  }
  // votingAddress => signature => data
  mapping(address => mapping(bytes4 => VotingSignature)) public votingSignatures;

  mapping(address => bool) public withoutFeeAddresses;

  constructor() public Ownable() {}

  function setTotalRestrictions(address[] calldata _poolsList, uint256[] calldata _maxTotalSupplyList) external onlyOwner {
    _setTotalRestrictions(_poolsList, _maxTotalSupplyList);
  }

  function setVotingSignatures(bytes4[] calldata _signatures, bool[] calldata _allowed) external onlyOwner {
    _setVotingSignatures(_signatures, _allowed);
  }

  function setVotingSignaturesForAddress(address _votingAddress, bool _override, bytes4[] calldata _signatures, bool[] calldata _allowed) external onlyOwner {
    _setVotingSignaturesForAddress(_votingAddress, _override, _signatures, _allowed);
  }

  function setWithoutFee(address[] calldata _addresses, bool _withoutFee) external onlyOwner {
    uint len = _addresses.length;
    for (uint i = 0; i < len; i++) {
      withoutFeeAddresses[_addresses[i]] = _withoutFee;
      emit SetWithoutFee(_addresses[i], _withoutFee);
    }
  }

  function getMaxTotalSupply(address _poolAddress) external override view returns(uint256) {
    return totalRestrictions[_poolAddress].maxTotalSupply;
  }

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external override view returns(bool) {
    if(votingSignatures[_votingAddress][_signature].overrideAllowed) {
      return votingSignatures[_votingAddress][_signature].allowed;
    } else {
      return signaturesAllowed[_signature];
    }
  }

  function isWithoutFee(address _address) external override view returns(bool) {
    return withoutFeeAddresses[_address];
  }

  /*** Internal Functions ***/

  function _setTotalRestrictions(address[] memory _poolsList, uint256[] memory _maxTotalSupplyList) internal {
    uint256 len = _poolsList.length;
    require(len == _maxTotalSupplyList.length , "Arrays lengths are not equals");

    for(uint256 i = 0; i < len; i++) {
      totalRestrictions[_poolsList[i]] = TotalRestrictions(_maxTotalSupplyList[i]);
      emit SetTotalRestrictions(_poolsList[i], _maxTotalSupplyList[i]);
    }
  }

  function _setVotingSignatures(bytes4[] memory _signatures, bool[] memory _allowed) internal {
    uint256 len = _signatures.length;
    require(len == _allowed.length , "Arrays lengths are not equals");

    for(uint256 i = 0; i < len; i++) {
      signaturesAllowed[_signatures[i]] = _allowed[i];
      emit SetSignatureAllowed(_signatures[i], _allowed[i]);
    }
  }

  function _setVotingSignaturesForAddress(address _votingAddress, bool _override, bytes4[] memory _signatures, bool[] memory _allowed) internal {
    uint256 len = _signatures.length;
    require(len == _allowed.length , "Arrays lengths are not equals");

    for(uint256 i = 0; i < len; i++) {
      votingSignatures[_votingAddress][_signatures[i]] = VotingSignature(_allowed[i], _override);
      emit SetSignatureAllowedForAddress(_votingAddress, _signatures[i], _allowed[i], _override);
    }
  }
}