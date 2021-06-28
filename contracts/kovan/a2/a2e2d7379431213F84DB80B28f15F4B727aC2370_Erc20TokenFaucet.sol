/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;



// Part: OpenZeppelin/[email protected]/Address

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// Part: OpenZeppelin/[email protected]/Context

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: Faucet.sol

contract Erc20TokenFaucet is Ownable {
    using Address for address;

    struct TokenConfig {
        address underlying;
        string  symbol;
        uint    numPerRequest;
    }

    // configs mapped by underlying address
    TokenConfig[] public configurations;

    uint public withdrawInterval = 10 minutes;

    mapping(address => uint) public antiAbuseTimeMap;

    modifier antiAbuse(){
        require(block.timestamp > (antiAbuseTimeMap[msg.sender] + withdrawInterval),
                "each address can only drip every 10 minutes");
        _;
        antiAbuseTimeMap[msg.sender] = block.timestamp;
    }

    function addConfig(address underlying_, string memory symbol_, uint numPerRequest_) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying_);
        require(index == uint(-1), "token config already exists");
        TokenConfig memory config = TokenConfig({underlying : underlying_, symbol : symbol_, numPerRequest : numPerRequest_});
        configurations.push(config);
    }

    function removeConfigByUnderlying(address underlying) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying);
        require(index != uint(-1), "token config not found");
        configurations[index] = configurations[configurations.length -1];
        configurations.pop();
    }

    // @notice withdraw all the tokens to owner
    function destroyFaucet() public onlyOwner {
        for (uint i = 0; i < configurations.length; i++) {
            emptyTokenByConfigIndex(i);
        }
        delete configurations;
    }

    // @notice withdraw all the tokens to owner
    function emptyTokenByUnderlying(address underlying) public onlyOwner {
        uint index = findTokenConfigIndexByUnderlying(underlying);
        require(index != uint(-1), "token config not found");
        IERC20 erc20 = IERC20(configurations[index].underlying);
        uint supply = erc20.balanceOf(address(this));
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, owner(), supply));
    }

    // @notice withdraw all the tokens to owner
    function emptyTokenByConfigIndex(uint index) internal onlyOwner {
        IERC20 erc20 = IERC20(configurations[index].underlying);
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, owner(), erc20.balanceOf(address(this))));

    }

    function findTokenConfigIndexByUnderlying(address underlying) public view returns (uint){
        for (uint i = 0; i < configurations.length; i++) {
            TokenConfig memory config = configurations[i];
            if (config.underlying == underlying) {
                return i;
            }
        }
        return uint(-1);
    }

    function compareString(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function findTokenConfigIndexBySymbol(string memory symbol) public view returns (uint){
        for (uint i = 0; i < configurations.length; i++) {
            TokenConfig memory config = configurations[i];
            if(compareString(config.symbol, symbol) == true) {
                return i;
            }

        }
        return uint(-1);
    }

    function requestWithdraw(string memory symbol) public antiAbuse {
        uint index = findTokenConfigIndexBySymbol(symbol);
        require(index != uint(-1), "token config not found");
        TokenConfig memory config = configurations[index];
        IERC20 erc20 = IERC20(config.underlying);
        uint supply = erc20.balanceOf(address(this));
        uint amount = supply > config.numPerRequest ? config.numPerRequest : supply;
        require(amount > 0, "not enough left");

        erc20.transfer(msg.sender, amount);
    }

    function requestAll() public antiAbuse {
        for (uint index = 0; index < configurations.length; index++) {
            TokenConfig memory config = configurations[index];
            IERC20 erc20 = IERC20(config.underlying);
            uint supply = erc20.balanceOf(address(this));
            uint amount = supply > config.numPerRequest ? config.numPerRequest : supply;
            if (amount > 0) {
                _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transfer.selector, msg.sender, amount));
            }
        }
    }

    function donate(string memory symbol, uint amount) public {
        require(amount > 0, "invalid donation");
        uint index = findTokenConfigIndexBySymbol(symbol);
        require(index != uint(-1), "token config not found");
        TokenConfig memory config = configurations[index];
        IERC20 erc20 = IERC20(config.underlying);
        _callOptionalReturn(erc20, abi.encodeWithSelector(erc20.transferFrom.selector, msg.sender, address(this), amount));
    }

    function setWithdrawInterval(uint256 _interval) external onlyOwner {
        withdrawInterval = _interval;
    }

    // handles non-standard token like USDT
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

       (bool success, bytes memory returndata) = address(token).call(data);
       _verifyCallResult(success, returndata, "");
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}