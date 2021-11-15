// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IStaking.sol";
import "./interfaces/IERC20.sol";
import "./security/ReentrancyGuard.sol";
import "./utils/Ownable.sol";

/**
 * Implementation of {IStaking} interface.
 */

contract Staking is IStaking, Ownable, ReentrancyGuard {
    mapping(address => uint256) private _stake;
    mapping(address => uint256) private _stakeTime;

    bool public state;
    uint256 public dripRate;
    address public token;

    event Stake(address _user, uint256 _amount);
    event Harvest(address _user, uint256 _amount);
    event Withdraw(address _user, uint256 _amount, uint256 _interest);

    /**
     * Initalizes the owner abstract contract.
     */
    constructor(uint256 _dripRate, address _token) Ownable() {
        dripRate = _dripRate;
        token = _token;
    }

    function stake(uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 allowance =
            IERC20(token).allowance(_msgSender(), address(this));
        uint256 balance = IERC20(token).balanceOf(_msgSender());

        require(allowance >= _amount, "Stake Error: insufficient allowance");
        require(balance >= _amount, "Stake Error: insufficient balance");

        settle(_msgSender());
        _stake[_msgSender()] += _amount;
        _stakeTime[_msgSender()] = block.timestamp;

        emit Stake(_msgSender(), _amount);
        return IERC20(token).transferFrom(_msgSender(), address(this), _amount);
    }

    function settle(address _user) private {
        uint256 unclaimed = getUnclaimed(_user);
        if (unclaimed > 0) {
            IERC20(token).transfer(_user, unclaimed);
            _stakeTime[_user] = 0;
            emit Harvest(_msgSender(), unclaimed);
        }
    }

    function harvest() public virtual override nonReentrant returns (bool) {
        require(_stake[_msgSender()] > 0, "Stake Error: no stake found");
        settle(_msgSender());

        return true;
    }

    function withdraw() public virtual override nonReentrant returns (bool) {
        require(_stake[_msgSender()] > 0, "Stake Error: no stake found");
        uint256 unclaimed = getUnclaimed(_msgSender());
        uint256 staked = getStaked(_msgSender());

        _stake[_msgSender()] = 0;
        _stakeTime[_msgSender()] = 0;

        emit Withdraw(_msgSender(), unclaimed + staked, unclaimed);
        return IERC20(token).transfer(_msgSender(), unclaimed + staked);
    }

    function setDripRate(uint256 _newDripRate)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        dripRate = _newDripRate;
        return true;
    }

    function setState(bool _state)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        state = _state;
        return true;
    }

    function getStaked(address _user)
        public
        virtual
        override
        returns (uint256)
    {
        return _stake[_user];
    }

    function getUnclaimed(address _user)
        public
        virtual
        override
        returns (uint256)
    {
        uint256 time = block.timestamp - _stakeTime[_user];

        return ((getStaked(_user) * time * dripRate) / 10**18);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

interface IStaking {
    /**
     * @dev allow users to stake their tokens for staking.
     *
     * `_amount` representing the amount of tokens to stake.
     * @return a boolean value representing the state of the tx.
     */
    function stake(uint256 _amount) external returns (bool);

    /**
     * @dev allows users to harvest their earned tokens.
     *
     * @return a uint256 value representing the amount of tokens claimed.
     */
    function harvest() external returns (bool);

    /**
     * @dev allows users to withdraw all their staked tokens.
     *
     * @return a boolean value representing the status of the tx.
     */
    function withdraw() external returns (bool);

    /**
     * @dev allows the admin to change driprate per second.
     *
     * Requirements:
     * - Admin Only Function
     *
     * @return a boolean value representing the status of the tx.
     */
    function setDripRate(uint256 _rate) external returns (bool);

    /**
     * @dev pauses the user's ability to stake (or) withdraw stake.
     * It toggles the state. if stake is paused it enables it or it does the opposite.
     *
     * Requirements:
     * - Admin only Function
     *
     * @return a boolean representing the status of the tx.
     */
    function setState(bool _state) external returns (bool);

    /**
     * @dev returns the current staked amount of a user.
     *
     * @return an uint256 representing the user's current stake.
     */
    function getStaked(address _user) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of a user.
     *
     * @return an uint256 representing the unclaimed tokens of the user.
     */
    function getUnclaimed(address _user) external returns (uint256);
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Interface of ZNFT Shares ERC20 Token As in EIP
 */

interface IERC20 {
    /**
     * @dev returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev returns the symbol of the token
     */
    function symbol() external view returns (string memory);

    /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev returns the total tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev sets `amount` as the `allowance` of the `spender`.
     *
     * returns a boolean value indicating the operation status.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted from tokens are moved from one account('from') to another account ('to)
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when allowance of a `spender` is set by the `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev returns the current owner of the SC.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws error if the function is called by account other than owner
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "Ownable: caller not owner");
        _;
    }

    /**
     * @dev Leaves the contract without any owner.
     *
     * It will be impossible to call onlyOwner Functions.
     * NOTE: use with caution.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner(), address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner cannot be zero address"
        );
        address msgSender = _msgSender();

        emit OwnershipTransferred(msgSender, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

