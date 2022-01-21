// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Contribution is Ownable {
    struct ContributionEvent {
        uint256 id;
        uint256 minETH;
        uint256 maxETH;
        bool isOpen;
        uint256 hardCap;
        uint256 availableETH;
    }

    uint256 public nextContributionEventId;
    uint256 public currentContributionEventId;

    mapping(uint256 => ContributionEvent) private events; // eventId => event
    mapping(uint256 => mapping(address => uint256)) private contributions; // eventId => (address => amount)

    event ContributionEventCreated(
        uint256 id,
        uint256 minETH,
        uint256 maxETH,
        bool isOpen,
        uint256 hardCap,
        uint256 availableETH
    );
    event Contributed(
        uint256 contributionEventId,
        address contributor,
        uint256 amount
    );
    event CurrentContributionEventSet(uint256 contributionEventId);
    event ContributionEventVisibilityChanged(
        uint256 contributionEventId,
        bool isOpen
    );

    function setCurrentContributionEvent(uint256 _id) public onlyOwner {
        require(_id > 0 && _id <= nextContributionEventId, "E005");
        currentContributionEventId = _id;
        emit CurrentContributionEventSet(currentContributionEventId);
    }

    function setContributionEventIsOpen(uint256 _id, bool _isOpen)
        public
        onlyOwner
    {
        require(_id > 0 && _id <= nextContributionEventId, "E005");
        events[_id].isOpen = _isOpen;
        emit ContributionEventVisibilityChanged(_id, _isOpen);
    }

    function getContributionEvent(uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        require(_id > 0 && _id <= nextContributionEventId, "E005");
        return (
            events[_id].minETH,
            events[_id].maxETH,
            events[_id].isOpen,
            events[_id].hardCap,
            events[_id].availableETH
        );
    }

    function getContribution(uint256 _eventId, address _contributor)
        public
        view
        returns (uint256)
    {
        require(_eventId > 0 && _eventId <= nextContributionEventId, "E005");
        return contributions[_eventId][_contributor];
    }

    function createContributionEvent(
        uint256 _minETH,
        uint256 _maxETH,
        uint256 _hardcap
    ) public onlyOwner {
        require(_minETH > 0, "E006");
        require(_maxETH > 0, "E007");
        require(_minETH <= _maxETH, "E008");
        require(_hardcap > 0, "E010");
        uint256 id = ++nextContributionEventId;
        events[id] = ContributionEvent({
            id: id,
            minETH: _minETH,
            maxETH: _maxETH,
            isOpen: false,
            hardCap: _hardcap,
            availableETH: _hardcap
        });

        emit ContributionEventCreated(
            id,
            _minETH,
            _maxETH,
            false,
            _hardcap,
            _hardcap
        );
    }

    function contribute(uint256 ethValue, address _contributor) private {
        require(events[currentContributionEventId].isOpen, "E009");
        require(
            contributions[currentContributionEventId][_contributor] == 0,
            "E003"
        );
        require(ethValue >= events[currentContributionEventId].minETH, "E001");
        require(ethValue <= events[currentContributionEventId].maxETH, "E002");
        require(
            events[currentContributionEventId].availableETH >= ethValue,
            "E004"
        );
        events[currentContributionEventId].availableETH -= ethValue;
        contributions[currentContributionEventId][_contributor] = ethValue;

        emit Contributed(currentContributionEventId, _contributor, ethValue);
    }

    receive() external payable {
        contribute(msg.value, msg.sender);
    }

    function withdrawAllETH() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _tokenAddress) public {
        IERC20 tokenContract = IERC20(_tokenAddress);
        tokenContract.transfer(
            msg.sender,
            tokenContract.balanceOf(address(this))
        );
    }
}

// Error Codes
// E001: Contribution is below minimum
// E002: Contribution is above maximum
// E003: Contribution already made
// E004: Contribution is above available ETH
// E005: Contribution event id must be between 1 and nextContributionEventId
// E006: minETH must be greater than 0
// E007: maxETH must be greater than 0
// E008: minETH must be less than or equal to maxETH
// E009: Contribution event is closed
// E010: hardCap must be greater than 0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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