// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IETHStaking.sol";

// import "hardhat/console.sol";

contract ETHStaking is IETHStaking, Ownable, ReentrancyGuard {
    /*********** VARIABLES ***********/
    uint256 public override totalValueLocked;

    uint256 public override apy;

    uint256 public override correctionFactor;

    /*********** MAPPING ***********/
    // User info
    // user address -> stakeNum -> UserInfo struct
    mapping(address => mapping(uint256 => UserInfo)) public override userInfo;

    // Stake Nums - How many stakes a user has
    mapping(address => uint256) public override stakeNums;
    mapping(address => uint256) private __stakeNums;

    /*********** CONSTRUCTOR ***********/
    constructor(uint256 _apy, uint256 _correctionFactor) {
        apy = _apy; // 0.6% apy -> 0.6 * 1e18
        correctionFactor = _correctionFactor; // 0.6% apy -> 1e21
    }

    /*********** FALLBACK FUNCTIONS ***********/
    receive() external payable {}

    /*********** GETTERS ***********/
    function balanceOf(address _account, uint256 _stakeNum)
        public
        view
        override
        returns (uint256)
    {
        return userInfo[_account][_stakeNum].amount;
    }

    function stakeExists(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (bool)
    {
        return balanceOf(_beneficiary, _stakeNum) != 0 ? true : false;
    }

    function calculateReward(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (uint256 _reward)
    {
        UserInfo memory _user = userInfo[_beneficiary][_stakeNum];
        _stakeExists(_beneficiary, _stakeNum);

        if (totalValueLocked == 0) return 0;

        uint256 _secs = _calculateSecs(block.timestamp, _user.lastUpdated);
        _reward = (_secs * _user.amount * apy) / (3153600 * correctionFactor);
    }

    function contractBalance() public view override returns (uint256) {
        return address(this).balance;
    }

    /*********** ACTIONS ***********/

    function changeAPY(uint256 _apy, uint256 _correctionFactor)
        public
        override
        onlyOwner
    {
        require(_apy != 0, "apy cannot be zero");
        apy = _apy; // 0.6% apy -> 0.6 * 1e18
        correctionFactor = _correctionFactor; // 0.6% apy -> 1e21
        emit APYChanged(_apy, _correctionFactor);
    }

    function withdrawContractFunds(uint256 _amount) public override onlyOwner {
        require(
            _amount <= address(this).balance,
            "amount exceeds contract balance"
        );
        _handleETHTransfer(owner(), _amount);
        emit OwnerWithdrawFunds(owner(), _amount);
    }

    function destructContract() public override onlyOwner {
        selfdestruct(payable(owner()));
    }

    function stake() public payable override {
        uint256 _amount = msg.value;
        require(_amount > 0, "stake amount not valid");

        uint256 _stakeNums = __stakeNums[_msgSender()];
        uint256 _stakeNum;

        if (_stakeNums == 0) {
            // user is coming for first time
            _stakeNum = 1;
        } else {
            // add 1 in his previous stake
            _stakeNum = _stakeNums + 1;
        }

        require(!stakeExists(_msgSender(), _stakeNum), "stake already exists");

        _updateUserInfo(ActionType.Stake, _msgSender(), _stakeNum, _amount, 0);

        emit Staked(_msgSender(), _amount, _stakeNum);
    }

    function unstake(uint256 _stakeNum) public override {
        _stakeExists(_msgSender(), _stakeNum);

        uint256 _amount = balanceOf(_msgSender(), _stakeNum);
        uint256 _reward = calculateReward(_msgSender(), _stakeNum);

        _updateUserInfo(
            ActionType.Unstake,
            _msgSender(),
            _stakeNum,
            _amount,
            _reward
        );

        _handleETHTransfer(_msgSender(), (_amount + _reward));

        emit Unstaked(_msgSender(), _amount, _reward, _stakeNum);
    }

    /*********** INTERNAL FUNCTIONS ***********/
    function _calculateSecs(uint256 _to, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    function _stakeExists(address _beneficiary, uint256 _stakeNum)
        internal
        view
    {
        UserInfo memory _user = userInfo[_beneficiary][_stakeNum];
        require(_stakeNum != 0, "StakeNum does not exist");
        require(stakeNums[_beneficiary] != 0, "User does not have any stake");
        require(_user.amount > 0, "User staked amount cannot be 0");
    }

    function _handleETHTransfer(address _beneficiary, uint256 _amount)
        internal
    {
        payable(_beneficiary).transfer(_amount);
        emit ETHTransferred(_beneficiary, _amount);
    }

    function _updateUserInfo(
        ActionType _actionType,
        address _beneficiary,
        uint256 _stakeNum,
        uint256 _amount,
        uint256 _reward
    ) internal nonReentrant {
        UserInfo storage user = userInfo[_beneficiary][_stakeNum];

        user.lastUpdated = block.timestamp;

        if (_actionType == ActionType.Stake) {
            stakeNums[_beneficiary] = _stakeNum;
            __stakeNums[_beneficiary] = _stakeNum;
            totalValueLocked = totalValueLocked + _amount;
            user.amount = _amount;
            user.rewardPaid = 0;
        }

        if (_actionType == ActionType.Unstake) {
            stakeNums[_beneficiary] = stakeNums[_beneficiary] - 1;
            totalValueLocked = totalValueLocked - _amount;
            user.amount = 0;
            user.rewardPaid = _reward;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETHStaking {
    /*********** STRUCT ***********/
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 lastUpdated;
    }

    /*********** ENUM ***********/
    enum ActionType {
        Stake,
        Unstake
    }

    /*********** EVENTS ***********/
    event Staked(address indexed user, uint256 amount, uint256 stakeNum);
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 stakeNum
    );
    event OwnerWithdrawFunds(address indexed beneficiary, uint256 amount);
    event ETHTransferred(address indexed beneficiary, uint256 amount);
    event APYChanged(uint256 apy, uint256 correctionFactor);

    /*********** GETTERS ***********/
    function totalValueLocked() external view returns (uint256);

    function apy() external view returns (uint256);

    function correctionFactor() external view returns (uint256);

    function userInfo(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function stakeNums(address) external view returns (uint256);

    function balanceOf(address _account, uint256 _stakeNum)
        external
        view
        returns (uint256);

    function stakeExists(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (bool);

    function calculateReward(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (uint256);

    function contractBalance() external view returns (uint256);

    /*********** ACTIONS ***********/
    function stake() external payable;

    function unstake(uint256 _stakeNum) external;

    function changeAPY(uint256 _apy, uint256 _correctionFactor) external;

    function withdrawContractFunds(uint256 _amount) external;

    function destructContract() external;
}

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