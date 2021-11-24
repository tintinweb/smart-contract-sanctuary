/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


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
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}





interface IERC2612 is IERC20Permit {}





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





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}





// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }


    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}




interface TokenRecipient {
  // must return ture
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}




interface IDUSD {
  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;
}




interface IUSDOracle {
  function getPrice(address token) external view returns (uint256);
}










// Virtual Amm: x^2 = k
contract DuetUSDMinerPair is Ownable, TokenRecipient  {
  
  uint constant PERCENT_BASE = 10000;
  uint constant VALID_STABLE_PRICE = 98000000;  // 0.98 usd;

  uint public feePercent     =    20;  // 0.2%
  uint public redeemPercent  =  5000;  // 50%
  
  address public feeTo;
  address public immutable dusd;
  address public immutable stableToken;
  IUSDOracle public stableOracle;
  uint public reserve;

  event Mint(address indexed user, uint stableAmount, uint amount);
  event Burn(address indexed user, uint stableAmount, uint amount);

  uint private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, 'DuetUSDMinerPair: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(address _stableToken, IUSDOracle _stableOracle, address _dusd, address _feeTo) {
    require(IERC20Metadata(_stableToken).decimals() == 18, "not support stable token");
    stableToken = _stableToken;
    stableOracle = _stableOracle;
    dusd = _dusd;
    reserve = 50000000e18;
    feeTo = _feeTo;
  }

  function updateOracle(IUSDOracle _stableOracle) external onlyOwner {
    require(address(_stableOracle) != address(0), "invalid oracle");
    stableOracle = _stableOracle;
  }

  function setFeeTo(address _feeTo) external onlyOwner {
    feeTo = _feeTo;
  }

  function updateFeePercent(uint _feePercent) external onlyOwner {
    require(_feePercent <= 500, "fee too high");
    feePercent = _feePercent;
  }

  function updateRedeemPercent(uint _redeemPercent) external onlyOwner {
    require(_redeemPercent <= PERCENT_BASE, "invalid redeem percent");
    redeemPercent = _redeemPercent;
  }

  function updateVirtualReserve(uint _reserve) external onlyOwner {
    require(_reserve >= IERC20(stableToken).balanceOf(address(this)), "virtual reserve must >= real reserve");
    reserve = _reserve;
  }

  // for update, reuse stable etc.
  function approve(address to, uint value) external onlyOwner {
    TransferHelper.safeApprove(stableToken, to, value);
  }

  // function permitMineDuet(uint amount, uint minDusd, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
  //   IERC2612(stableToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
  //   mine(amount, minDusd, to);
  // }

  function mineDusd(uint amount, uint minDusd, address to) public lock returns(uint amountOut) {
    require(amount > 0, "invalid amount");
    require(stableOracle.getPrice(stableToken) > VALID_STABLE_PRICE, "stable token value too low");
    uint fee = 0;
    (amountOut, fee) = calcOutputFee(amount);

    require(amountOut >= minDusd, "insufficient output amount");
    reserve = reserve + amount;

    TransferHelper.safeTransferFrom(stableToken, msg.sender, address(this), amount);
    if (fee > 0) {
      TransferHelper.safeTransfer(stableToken, feeTo, fee);
    }
    
    IDUSD(dusd).mint(to, amountOut);
    emit Mint(to, amount, amountOut);
  }

  // test ok
  function calcOutputFee(uint amount) public view returns(uint amountOut, uint fee) {
    amountOut = amount * reserve / (reserve + amount);
    fee = feePercent > 0 ? amount * feePercent / PERCENT_BASE : 0;
    
    if (amount - amountOut < fee) {
      amountOut = amount - fee;
    } else {
      fee = amount - amountOut;
    }
  } 

  function calcInputFee(uint amountOut) public view returns (uint amountIn, uint fee) {
      amountIn = (reserve * amountOut / (reserve - amountOut)) + 1;
      fee = feePercent > 0 ? amountIn * feePercent / PERCENT_BASE : 0;
      if (amountIn - amountOut < fee) {
        amountIn = amountOut * PERCENT_BASE / (PERCENT_BASE - feePercent);
        if ((PERCENT_BASE - feePercent) * amountIn != amountOut * PERCENT_BASE) {
          amountIn += 1;
        }
        fee = amountIn - amountOut;
      } else {
        fee = amountIn - amountOut;
      }
    }

  function tokensReceived(address from, uint amount, bytes calldata exData) external override returns (bool) {
    require(msg.sender == dusd, "must call from dusd");
    if ( exData.length > 0) {
      doBurnDusd(amount, bytesToUint(exData), from);
    } else {
      doBurnDusd(amount, 0, from);
    }
    
    return true;
  }

  function permitBurnDusd(uint amount, uint minStable, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns(uint amountOut) {
    IERC2612(dusd).permit(msg.sender, address(this), amount, deadline, v, r, s);
    amountOut = burnDusd(amount, minStable, to);
  }

  function burnDusd(uint amount, uint minStable, address to) public returns(uint amountOut) {
    TransferHelper.safeTransferFrom(dusd, msg.sender, address(this), amount);
    amountOut = doBurnDusd(amount, minStable, to);
  }

  function doBurnDusd(uint amount, uint minStable, address to) internal lock returns(uint amountOut) {
    require(amount > 0, "invalid amount");
    uint fee = 0;
    (amountOut, fee) = calcOutputFee(amount);

    require(amountOut >= minStable, "insufficient output amount");
    require(checkUnderRedeemLimit(amountOut), "insufficient liquidity");

    reserve = reserve - amount;
    IDUSD(dusd).burn(amount);

    TransferHelper.safeTransfer(stableToken, to, amountOut);

    if (fee > 0 && feeTo != address(0)) {
      TransferHelper.safeTransfer(stableToken, feeTo, fee);
    }
    
    emit Burn(to, amountOut, amount);
  }

  function checkUnderRedeemLimit(uint amount) public view returns(bool) {
    uint redeemLimit = IERC20(stableToken).balanceOf(address(this)) * redeemPercent / PERCENT_BASE;
    return amount <= redeemLimit;
  }

  function bytesToUint(bytes calldata b) internal pure returns (uint256) {
    uint256 number;
    for(uint i=0; i < b.length; i++){
        number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
    }
    return number;
  }

}