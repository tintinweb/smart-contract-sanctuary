/**
 *Submitted for verification at Etherscan.io on 2021-10-03
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








/**
 *  Gate -- by jacob robbins
 *
 *  Synopsis:      Allow gated actions on an associated contract via Requests which may be Granted by Gatekeepers
 *
 *                 Each Ethereum account can create one Request. Gatekeepers can grant Requests.
 *
 *                 Sending funds is optional but is encouraged at least to the amount of gas cost required for the Gatekeepers to approve the Request.
 *                 Anyone can contribute funds to support a Request, not just the requestor.
 *
 *                 Granted Requests can be used to gate actions in other contracts. For example, to allow the requestor to mint an NFT.
 *
*/

// Interface used by other contracts to gate access to minting
interface GateCheck {
  function gateRequestIsGranted(address) external view returns(bool);
}

contract Gate is Ownable, ReentrancyGuard, GateCheck {

  uint32 private constant noRequest = 0;
  uint32 private constant pendingRequest = 100;
  uint32 private constant grantedRequest = 222;

  struct GateRequest {
    uint32 status;
    uint32 funded;
  }

  event RequestCreated(
    address _requestor,
    uint _funded
  );

  event RequestSupported(
    address indexed _supportedRequestor,
    address indexed _supporter,
    uint _funded,
    string _shout
  );

  event RequestGranted(
    address indexed _grantedRequestor
  );

  mapping(address => GateRequest) private _gateRequests;

  mapping(address => uint256) private _gatekeeperMapping;

  address[] public _gatekeepers;

  bool public isOpen = true;

  // METHODS FOR THE PUBLIC

  function createRequest() external payable returns(uint32 funded) {
    require(isOpen, 'gate is closed');
    address a = _msgSender();
    if (_gateRequests[a].status == noRequest) {
      _gateRequests[a].status = pendingRequest;
    }
    if (msg.value > 0) {
      funded = uint32(msg.value);
      _gateRequests[a].funded += funded;
    }
    emit RequestCreated(_msgSender(), funded);
  }

  function viewRequest(address requestor) public view returns(uint32 status, uint32 funded) {
    if (requestor ==  address(0)) {
      requestor = _msgSender();
    }
    return(
      _gateRequests[requestor].status,
      _gateRequests[requestor].funded
    );
  }

  function fundRequest(address fundedRequestor, string calldata shout) external payable returns(uint32 funded) {
    if (fundedRequestor ==  address(0)) {
      fundedRequestor = _msgSender();
    }
    funded = uint32(msg.value);
    _gateRequests[fundedRequestor].funded += funded;
    emit RequestSupported(fundedRequestor, _msgSender(), uint(msg.value), shout);
  }

  receive() external payable {
    _gateRequests[_msgSender()].funded += uint32(msg.value);
  }

  // EXTERNAL CONTRACT CHECK API

  function gateRequestIsGranted(address requestor) public view override returns(bool) {
    require(requestor !=  address(0), 'invalid requestor');
    return(grantedRequest == _gateRequests[requestor].status);
  }


  // METHODS FOR GATEKEEPERS

  modifier onlyGatekeeper() {
      require(
        _gatekeeperMapping[_msgSender()] == grantedRequest,
        "For Gatekeepers Only"
      );
      _;
  }

  function grantRequests(address[] calldata grantAddresses) public nonReentrant onlyGatekeeper {
    address curr;
    for (uint256 i=0; i < grantAddresses.length; i++) {
      curr = grantAddresses[i];
      require(curr !=  address(0), 'invalid grantee');
      _gateRequests[curr].status = grantedRequest;
      emit RequestGranted(curr);
    }
  }

  // Requests can only be created when the gate is open. It is initially open.
  function updateIsOpen(bool newVal) public nonReentrant onlyGatekeeper {
    isOpen = newVal;
  }

  // gatekeepers are able to withdraw funds to pay the gas required for grants
  function withdrawFunds(uint256 amount) public nonReentrant onlyGatekeeper {
    payable(_msgSender()).transfer(amount);
  }


  // METHODS FOR CONTRACT OWNER

  function addGatekeeper(address a) public nonReentrant onlyOwner {
    _gatekeeperMapping[a] = grantedRequest;
    _gatekeepers.push(a);
  }

  function removeGatekeeper(address a) public nonReentrant onlyOwner {
    _gatekeeperMapping[a] = noRequest;
    for (uint i=0; i < _gatekeepers.length; i++) {
      if (_gatekeepers[i] == a) {
        delete _gatekeepers[i];
      }
    }
  }

  constructor() Ownable() {
    // add the deployer as first gatekeepers for convenience
    addGatekeeper(_msgSender());
  }

}