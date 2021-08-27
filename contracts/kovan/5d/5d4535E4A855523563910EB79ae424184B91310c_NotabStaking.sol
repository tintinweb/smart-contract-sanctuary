// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IStaking.sol";
import "./interfaces/INotabToken.sol";
import "./security/ReentrancyGuard.sol";
import "./utils/Ownable.sol";

/**
 * Implementation of {IStaking} interface.
 */

contract NotabStaking is IStaking, Ownable, ReentrancyGuard {
    mapping(address => uint256) private _stake;
    mapping(address => uint256) private _stakeTime;

    bool public isPaused;
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
        require(!isPaused, "Stake Error: paused");
        uint256 allowance = INotabToken(token).allowance(
            _msgSender(),
            address(this)
        );
        uint256 balance = INotabToken(token).balanceOf(_msgSender());

        require(balance >= _amount, "Stake Error: insufficient balance");
        require(allowance >= _amount, "Stake Error: insufficient allowance");

        settle(_msgSender());
        _stake[_msgSender()] += _amount;
        _stakeTime[_msgSender()] = block.timestamp;

        emit Stake(_msgSender(), _amount);
        return
            INotabToken(token).transferFrom(
                _msgSender(),
                address(this),
                _amount
            );
    }

    function settle(address _user) private {
        uint256 unclaimed = getUnclaimed(_user);
        if (unclaimed > 0) {
            INotabToken(token).transfer(_user, unclaimed);
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
        require(!isPaused, "Stake Error: paused");
        require(_stake[_msgSender()] > 0, "Stake Error: no stake found");
        uint256 unclaimed = getUnclaimed(_msgSender());
        uint256 staked = getStaked(_msgSender());

        _stake[_msgSender()] = 0;
        _stakeTime[_msgSender()] = 0;

        emit Withdraw(_msgSender(), unclaimed + staked, unclaimed);
        return INotabToken(token).transfer(_msgSender(), unclaimed + staked);
    }

    function setDripRate(uint256 _newDripRate)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        require(_newDripRate > 0, "Stake error: invalid drip rate");
        dripRate = _newDripRate;
        return true;
    }

    function pause(bool _state)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        isPaused = _state;
        return true;
    }

    function getStaked(address _user)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _stake[_user];
    }

    function getUnclaimed(address _user)
        public
        virtual
        override
        view
        returns (uint256)
    {
        uint256 time = block.timestamp - _stakeTime[_user];

        return ((getStaked(_user) * time * ((dripRate/10**2)/31536000)) / 10**18);
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
     *
     * Requirements:
     * - Admin only Function
     *
     * @return a boolean representing the status of the tx.
     */
    function pause(bool _state) external returns (bool);

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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INotabToken {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
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

// SPDX-License-Identifier: ISC

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}