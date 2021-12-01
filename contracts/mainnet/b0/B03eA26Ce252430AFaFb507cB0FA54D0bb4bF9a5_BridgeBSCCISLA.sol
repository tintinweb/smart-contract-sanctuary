// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BridgeBSCCISLA
 *
 */
contract BridgeBSCCISLA is Ownable {
    IERC20 private _token;

    address public tokenOwner;
    address public oracleAddress;
    uint256 public originalSupply;
    uint256 public maxSwapAmount;
    uint256 public minimumGasForOperation = 297 * 10**14; // (0.0297 ETH)
    bool public isActive = true;

    struct Swap {
        bytes32 id;
        uint256 origTimestamp;
        uint256 currentTimestamp;
        bool isOutbound;
        bool isComplete;
        bool isSendGasFunded;
        address swapAddress;
        uint256 amount;
    }

    mapping(bytes32 => Swap) public swaps;
    mapping(address => Swap) public lastUserSwap;

    event ReceiveTokensFromSource(
        bytes32 indexed id,
        uint256 origTimestamp,
        address sender,
        uint256 amount
    );

    event destinationGasFunded(bytes32 indexed id);

    event SendTokensToDestination(
        bytes32 indexed id,
        address receiver,
        uint256 amount
    );

    event TokenOwnerUpdated(address previousOwner, address newOwner);

    constructor(
        address _oracleAddress,
        address _tokenOwner,
        address _tokenAddy,
        uint256 _maxSwapAmount
    ) {
        oracleAddress = _oracleAddress;
        tokenOwner = _tokenOwner;
        _token = IERC20(_tokenAddy);
        maxSwapAmount = _maxSwapAmount;
    }

    function getSwapTokenAddress() external view returns (address) {
        return address(_token);
    }

    function changeActiveState(bool _isActive) external {
        require(
            msg.sender == owner() || msg.sender == tokenOwner,
            "changeActiveState user must be contract creator"
        );
        isActive = _isActive;
    }

    function updateSupply() external onlyOwner {
        originalSupply = _token.balanceOf(address(this));
    }

    function changeOracleAddress(address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
        transferOwnership(oracleAddress);
    }

    function updateTokenOwner(address newOwner) external {
        require(
            msg.sender == tokenOwner || msg.sender == owner(),
            "user must be current token owner to change it"
        );
        address previousOwner = tokenOwner;
        tokenOwner = newOwner;
        emit TokenOwnerUpdated(previousOwner, newOwner);
    }

    function depositTokens(uint256 _amount) external {
        require(
            msg.sender == tokenOwner,
            "depositTokens user must be token owner"
        );
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawTokens(uint256 _amount) external {
        require(
            msg.sender == tokenOwner,
            "withdrawTokens user must be token owner"
        );
        _token.transfer(msg.sender, _amount);
    }

    function updateSwapCompletionStatus(bytes32 _id, bool _isComplete)
        external
        onlyOwner
    {
        swaps[_id].isComplete = _isComplete;
    }

    function updateMinimumGasForOperation(uint256 _amountGas)
        external
        onlyOwner
    {
        minimumGasForOperation = _amountGas;
    }

    function receiveTokensFromSource(uint256 _amount)
        external
        payable
        returns (bytes32, uint256)
    {
        require(isActive, "this atomic swap instance is not active");
        require(
            msg.value >= minimumGasForOperation,
            "you must also send enough gas to cover the target transaction"
        );
        require(
            maxSwapAmount == 0 || _amount <= maxSwapAmount,
            "trying to send more than maxSwapAmount"
        );

        payable(oracleAddress).transfer(msg.value);
        _token.transferFrom(msg.sender, address(this), _amount);

        uint256 _ts = block.timestamp;
        bytes32 _id = sha256(abi.encodePacked(msg.sender, _ts, _amount));

        swaps[_id] = Swap({
            id: _id,
            origTimestamp: _ts,
            currentTimestamp: _ts,
            isOutbound: false,
            isComplete: false,
            isSendGasFunded: false,
            swapAddress: msg.sender,
            amount: _amount
        });
        lastUserSwap[msg.sender] = swaps[_id];

        emit ReceiveTokensFromSource(_id, _ts, msg.sender, _amount);
        return (_id, _ts);
    }

    function getLastUserSwap(address _addy)
        external
        view
        returns (Swap memory)
    {
        return lastUserSwap[_addy];
    }

    function unsetLastUserSwap(address _addy) external onlyOwner {
        delete lastUserSwap[_addy];
    }

    // msg.sender must be the user who originally created the swap.
    // Otherwise, the unique identifier will not match from the originally
    // sending txn.
    //
    // NOTE: This function can be spoofed by creating a sha256 hash of msg.sender's address
    // and _origTimestamp, but it's important to note sendTokensToDestination
    // can only be executed by the owner/oracle. Therefore validation should be done by the oracle before
    // executing those and the only possibility of a vulnerability is if someone has compromised the oracle account.
    function fundSendToDestinationGas(
        bytes32 _id,
        uint256 _origTimestamp,
        uint256 _amount
    ) external payable {
        require(
            msg.value >= minimumGasForOperation,
            "you must send enough gas to cover the send transaction"
        );
        require(
            _id ==
                sha256(abi.encodePacked(msg.sender, _origTimestamp, _amount)),
            "we don't recognize this swap"
        );
        payable(oracleAddress).transfer(msg.value);

        //check if swap already exists
        if (!(swaps[_id].amount > 0 && swaps[_id].origTimestamp > 0)) {
            swaps[_id] = Swap({
                id: _id,
                origTimestamp: _origTimestamp,
                currentTimestamp: block.timestamp,
                isOutbound: true,
                isComplete: false,
                isSendGasFunded: true,
                swapAddress: msg.sender,
                amount: _amount
            });
        }

        emit destinationGasFunded(_id);
    }

    // This must be called AFTER fundSendToDestinationGas has been executed
    // for this txn to fund this send operation
    function sendTokensToDestination(bytes32 _id) external returns (bytes32) {
        require(isActive, "this atomic swap instance is not active");

        Swap storage swap = swaps[_id];

        _confirmSwapExistsGasFundedAndSenderValid(swap);
        _token.transfer(swap.swapAddress, swap.amount);
        swap.currentTimestamp = block.timestamp;
        swap.isComplete = true;
        emit SendTokensToDestination(_id, swap.swapAddress, swap.amount);
        return _id;
    }

    function _confirmSwapExistsGasFundedAndSenderValid(Swap memory swap)
        private
        view
        onlyOwner
    {
        // functions that call this should only be called by the current owner
        // or oracle address as they will do the appropriate validation beforehand
        // to confirm the receiving swap is valid before sending tokens to the user.
        require(
            swap.origTimestamp > 0 && swap.amount > 0,
            "swap does not exist yet."
        );
        // We're just validating here that the swap has not been
        // completed and gas has been funded before moving forward.
        require(
            !swap.isComplete && swap.isSendGasFunded,
            "swap has already been completed or gas has not been funded"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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