// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";

/// @title SquidGame main Contract
/// @author SquidGame Team
/// @notice The play-to-earn Squid game
contract SquidMetaGame is Initializable {
    //Game Farming Income
    event WithdrawEvent(
        address indexed account,
        bytes32 indexed hash,
        uint256 nonce,
        uint256 amount
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //Destroy a transaction event
    event DropOrders(address operator, bytes32 hash);
    //Price Change Event
    event PriceChange(address operator, uint256 price_);

    event Extract(address operator, uint256 time_, uint256 nonce_,uint amount_);

    address public _owner;

    //Squid token
    IERC20 public SquidPieces;

    address public _recipientAddress;

    bool private _lock;

    //Referee
    address private _referees;

    //Transaction hash discard pool
    mapping(bytes32 => bool) orders;

    mapping(address => uint256) private _nonce;

    uint256 public price;

    uint256 public extractnum;

    function initialize(
        uint256 price_,
        address recipient_,
        address referees_,
        address token_
    ) public initializer {
        _recipientAddress = recipient_;
        _referees = referees_;
        price = price_;
        SquidPieces = IERC20(token_);
        _owner = msg.sender;
    }

    modifier Reentrant() {
        require(!_lock, "reentrant lock");
        _lock = true;
        _;
        _lock = false;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) public {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function extract(uint256 time) public {
        require(time > 0, "invlaid time");
        uint256 _extractnum = extractnum++;
        uint amount_ = price * time;
        SquidPieces.transferFrom(msg.sender, _recipientAddress, amount_);
        emit Extract(msg.sender, time, _extractnum,amount_);
    }

    //Game Farming Income
    function withdraw(
        uint256 amount,
        uint256 timeout,
        bytes memory signature
    ) public Reentrant returns (uint256) {
        uint256 nonce_ = ++_nonce[msg.sender];
        bytes32 hash = hashToVerify(
            keccak256(abi.encode(msg.sender, amount, nonce_, timeout))
        );
        require(!orders[hash], "hash expired");
        require(verify(_referees, hash, signature), "sign error");
        require(block.timestamp < timeout, "time out");
        require(
            SquidPieces.balanceOf(address(this)) >= amount,
            "stake insufficient"
        );
        SquidPieces.transfer(msg.sender, amount);
        emit WithdrawEvent(msg.sender, hash, nonce_, amount);
        return amount;
    }

    function dropOrders(bytes32[] memory hashArray) external onlyOwner {
        for (uint256 i = 0; i < hashArray.length; i++) {
            bool leap = orders[hashArray[i]];
            if (!leap) {
                orders[hashArray[i]] = true;
                emit DropOrders(msg.sender, hashArray[i]);
            }
        }
    }

    function nonce(address account) public view returns (uint256 nonce_) {
        return _nonce[account] + 1;
    }

    function setPrice(uint256 _price) public onlyOwner {
        require(_price != 0, "invalid price");
        price = _price;
        emit PriceChange(msg.sender, _price);
    }

    function hashToVerify(bytes32 data) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", data)
            );
    }

    function verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) private pure returns (bool) {
        require(signer != address(0), "invalid address");
        require(signature.length == 65, "invalid len of signature");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "invalid signature");
        return signer == ecrecover(hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.9.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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