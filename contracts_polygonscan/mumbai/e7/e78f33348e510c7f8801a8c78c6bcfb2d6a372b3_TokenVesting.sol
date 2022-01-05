/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }
}

pragma solidity ^0.8.0;

contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;

    uint256 public totalVestings;
    IERC20 public ERC20Interface;

    struct VestingDetails {
        address receiver;
        uint256 amount;
        uint256 release;
        bool expired;
    }

    /**
     * @param _tokenAddress address of the token contract
     */
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Zero token address");
        ERC20Interface = IERC20(_tokenAddress);
    }

    mapping(uint256 => VestingDetails) public vestingID;
    mapping(address => uint256[]) receiverIDs;

    /**
     * @param _receiver Address of the receiver of the vesting
     * @param _amount Amount of tokens to be locked up for vesting
     * @param _release Timestamp of the release time
     * @return _success Boolean value true if flow is successful
     * Creates a new vesting
     */
    function createVesting(
        address _receiver,
        uint256 _amount,
        uint256 _release
    ) internal onlyOwner _hasAllowance(msg.sender, _amount) returns (bool) {
        require(_receiver != address(0), "Zero receiver address");
        require(_amount > 0, "Zero amount");
        require(_release > block.timestamp, "Incorrect release time");

        totalVestings++;
        vestingID[totalVestings] = VestingDetails(
            _receiver,
            _amount,
            _release,
            false
        );
        receiverIDs[_receiver].push(totalVestings);
        ERC20Interface.safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    /**
     * @param id Id of the vesting
     * @return _success Boolean value true if flow is successful
     * The receiver of the vesting can claim their vesting if the vesting ID corresponds to their address
     * and hasn't expired
     */
    function claim(uint256 id) external returns (bool) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(!vestingDetail.expired, "ID expired");
        require(
            block.timestamp >= vestingDetail.release,
            "Release time not reached"
        );
        vestingID[id].expired = true;
        ERC20Interface.safeTransfer(
            vestingDetail.receiver,
            vestingDetail.amount
        );
        return true;
    }

    /**
     * @param id Id of the vesting
     * @return _success Boolean value true if flow is successful
     * To suspend the lock before expiry and transfer the token amount to the receiver
     */
    function suspendLockTransferToReceiver(uint256 id)
        external
        onlyOwner
        returns (bool)
    {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(
            block.timestamp < vestingDetail.release,
            "Release time already reached"
        );
        require(!vestingDetail.expired, "ID expired");
        vestingID[id].expired = true;
        ERC20Interface.safeTransfer(
            vestingDetail.receiver,
            vestingDetail.amount
        );
        return true;
    }

    /**
     * @param _receivers Array of address of receiver of vesting amount
     * @param _amounts Array of amounts corresponding to each vesting
     * @param _releases Array of release timestamps corresponding to each vesting
     * @return _success Boolean value true if flow is successful
     * Creates multiple vesting, calls createVesting for each corresponding entry in {_receivers} {_amounts} {_releases}
     */
    function createMultipleVesting(
        address[] memory _receivers,
        uint256[] memory _amounts,
        uint256[] memory _releases
    ) external returns (bool) {
        require(
            _receivers.length == _amounts.length &&
                _amounts.length == _releases.length,
            "Invalid data"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = createVesting(
                _receivers[i],
                _amounts[i],
                _releases[i]
            );
            require(success, "Creation of vesting failed");
        }
        return true;
    }

    /**
     * @param user Address of receiver of vesting amount
     * @return Array of IDs corresponding to vesting assigned to the user
     * Returns the IDs of the vestings , the user corresponds to
     */
    function getReceiverIDs(address user)
        external
        view
        returns (uint256[] memory)
    {
        return receiverIDs[user];
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}