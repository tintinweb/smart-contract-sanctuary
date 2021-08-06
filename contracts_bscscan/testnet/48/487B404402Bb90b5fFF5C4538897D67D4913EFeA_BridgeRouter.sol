/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


pragma solidity ^0.8.0;

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

    constructor () {
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

// File: contracts/SafeToken.sol

pragma solidity ^0.8.0;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// File: contracts/IBridge.sol

pragma solidity ^0.8.0;

interface IBridge {
  function departure(
    uint fromChainId,
    uint toChainId,
    address to,
    uint amount,
    uint nonce,
    bytes calldata signature
  ) external;

  function arrival(
    uint fromChainId,
    uint toChainId,
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external;
}

// File: contracts/BridgeRouter.sol

pragma solidity ^0.8.0;





contract BridgeRouter is Ownable, ReentrancyGuard {
  uint public chainId;
  mapping(address => bool) public Admins;
  mapping(address => mapping(uint => Token)) public Tokens;

  struct Token {
    address bridge;
    bool status;
  }

  event Departure(
    address token,
    uint fromChainId,
    uint toChainId,
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature
  );

  event Arrival(
    uint fromChainId,
    uint toChainId,
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature
  );

  constructor(uint _chainId) {
    chainId = _chainId;
    Admins[msg.sender] = true;
  }

  modifier onlyAdmin() {
    require(Admins[msg.sender], "only admin");
    _;
  }

  function updateAdmin(address _admin, bool _status) external onlyOwner {
    Admins[_admin] = _status;
  }

  function updateToken(address token, address _bridge, uint destChainId, bool _status) external onlyOwner {
    Tokens[token][destChainId].bridge = _bridge;
    Tokens[token][destChainId].status = _status;
  }

  function departure(
    address token,
    uint toChainId,
    address to,
    uint amount,
    uint nonce,
    bytes calldata signature
  ) external {
    // test on transfer if required amount is needed
    SafeToken.safeTransferFrom(token, msg.sender, address(this), amount);
    Token storage t = Tokens[token][toChainId];
    require(t.status, "unsupport token");
    SafeToken.safeApprove(token, t.bridge, type(uint256).max);
    IBridge(t.bridge).departure(chainId, toChainId, to, amount, nonce, signature);
    emit Departure(
      token,
      chainId,
      toChainId,
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature
    );
  }

  function arrival(
    address token,
    uint fromChainId,
    uint toChainId,
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external onlyAdmin nonReentrant {
    // TODO connect to bridge interface.
    Token storage t = Tokens[token][fromChainId];
    require(t.status, "unsupport token");
    require(toChainId == chainId, "wrong chain id");
    IBridge(t.bridge).arrival(fromChainId, toChainId, from, to, amount, nonce, signature);
    emit Arrival(
      fromChainId,
      toChainId,
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      signature
    );
  }
}