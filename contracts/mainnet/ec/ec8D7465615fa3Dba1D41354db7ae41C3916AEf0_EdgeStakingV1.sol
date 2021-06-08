// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./utils/Context.sol";
import "./security/ReentrancyGuard.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IERC20.sol";

/**
 * An implementation of the {IStaking} interface.
 *
 * It allows users to stake their tokens for `x` days predetermined
 * during the time of stake and earn interest over time.
 *
 * The ROI can be changed but it's not influential on previous stakers
 * to maintain the integrity of the application.
 */

contract EdgeStakingV1 is ReentrancyGuard, Context, IStaking {
    mapping(address => uint256) public totalStakingContracts;
    mapping(address => mapping(uint256 => Stake)) public stakeContract;

    uint256 public currentROI;

    address public edgexContract;
    address public admin;

    /**
     * @dev represents the staking instance.
     *
     * Every user's stake is mapped to a staking instance
     * represented by `stakeId`
     */
    struct Stake {
        uint256 amount;
        uint256 maturesAt;
        uint256 createdAt;
        uint256 roiAtStake;
        bool isClaimed;
        uint256 interest;
    }

    /**
     * @dev Emitted when the `caller` the old admin
     * transfers the governance of the staking contract to a
     * `newOwner`
     */
    event RevokeOwnership(address indexed newOwner);

    /**
     * @dev Emitted when the `admin` who is the governor
     * of the contract changes the ROI for staking
     *
     * Effective for new stakers.
     */
    event ChangeROI(uint256 newROI);

    /**
     * @dev sanity checks the caller.
     * If the caller is not admin, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyAdmin() {
        require(_msgSender() == admin, "Error: caller not admin");
        _;
    }

    /**
     * @dev checks whether the address is a valid one.
     *
     * If it's a zero address returns an error.
     */
    modifier isZero(address _address) {
        require(_address != address(0), "Error: zero address");
        _;
    }

    /**
     * @dev sets the starting parameters of the SC.
     *
     * {_edgexContract} - address of the EDGEX token contract.
     * {_newROI} - the ROI in % represented in 13 decimals.
     * {_admin} - the controller of the contract.
     */
    constructor(
        address _edgexContract,
        uint256 _newROI,
        address _admin
    ) {
        edgexContract = _edgexContract;
        currentROI = _newROI;
        admin = _admin;
    }

    /**
     * @dev stakes the `amount` of tokens for `tenure`
     *
     * Requirements:
     * `amount` should be approved by the `caller`
     * to the staking contract.
     *
     * `tenure` shoulde be mentioned in days.
     */
    function stake(uint256 _amount, uint256 _tenureInDays)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 currentAllowance =
            IERC20(edgexContract).allowance(_msgSender(), address(this));
        uint256 currentBalance = IERC20(edgexContract).balanceOf(_msgSender());

        require(
            currentAllowance >= _amount,
            "Error: stake amount exceeds allowance"
        );
        require(
            currentBalance >= _amount,
            "Error: stake amount exceeds balance"
        );

        updateStakeData(_amount, _tenureInDays, _msgSender());
        totalStakingContracts[_msgSender()] += 1;

        return IERC20(edgexContract).transferFrom(
            _msgSender(),
            address(this),
            _amount
        );
    }

    /**
     * @dev creates the staking data in a new {Stake} strucutre.
     *
     * It records the current snapshots of ROI and other staking information available.
     */
    function updateStakeData(
        uint256 _amount,
        uint256 _tenureInDays,
        address _user
    ) internal {
        uint256 totalContracts = totalStakingContracts[_user] + 1;

        Stake storage sc = stakeContract[_user][totalContracts];
        sc.amount = _amount;
        sc.createdAt = block.timestamp;
        uint256 maturityInSeconds = _tenureInDays * 1 days;
        sc.maturesAt = block.timestamp + maturityInSeconds;
        sc.roiAtStake = currentROI;
    }

    /**
     * @dev claims the {amount} of tokens plus {earned} tokens
     * after the end of {tenure}
     *
     * Requirements:
     * `_stakingContractId` of the staking instance.
     *
     * returns a boolean to show the current state of the transaction.
     */
    function claim(uint256 _stakingContractId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Stake storage sc = stakeContract[_msgSender()][_stakingContractId];

        require(sc.maturesAt <= block.timestamp, "Not Yet Matured");
        require(!sc.isClaimed, "Already Claimed");

        uint256 total;
        uint256 interest;
        (total, interest) = calculateClaimAmount(
            _msgSender(),
            _stakingContractId
        );
        sc.isClaimed = true;
        sc.interest = interest;

        return IERC20(edgexContract).transfer(_msgSender(), total);
    }

    /**
     * @dev returns the amount of unclaimed tokens.
     *
     * Requirements:
     * `user` is the ethereum address of the wallet.
     * `contractId` is the id of the staking instance.
     *
     * returns the `total amount` and the `interest earned` respectively.
     */
    function calculateClaimAmount(address _user, uint256 _contractId)
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        Stake storage sc = stakeContract[_user][_contractId];

        uint256 a = sc.amount * sc.roiAtStake;
        uint256 time = sc.maturesAt - sc.createdAt;
        uint256 b = a * time;
        uint256 interest = b / (31536 * 10**18);
        uint256 total = sc.amount + interest;

        return (total, interest);
    }

    /**
     * @dev transfers the governance from one account(`caller`) to another account(`_newOwner`).
     *
     * Note: Governors can only set / change the ROI.
     */

    function revokeOwnership(address _newOwner)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOwner)
        returns (bool)
    {
        admin = payable(_newOwner);
        emit RevokeOwnership(_newOwner);
        return true;
    }

    /**
     * @dev will change the ROI on the staking yield.
     *
     * `_newROI` is the ROI calculated per second considering 365 days in a year.
     * It should be in 13 precision.
     *
     * The change will be effective for new users who staked tokens after the change.
     */
    function changeROI(uint256 _newROI)
        public
        virtual
        override
        onlyAdmin
        returns (bool)
    {
        currentROI = _newROI;
        emit ChangeROI(_newROI);
        return true;
    }

    /**
     * #@dev will change the token contract (EDGEX)
     *
     * If we're migrating / moving the token contract.
     * This prevents the need for migration of the staking contract.
     */
    function updateEdgexContract(address _contractAddress)
        public
        virtual
        override
        onlyAdmin
        isZero(_contractAddress)
        returns (bool)
    {
        edgexContract = _contractAddress;
        return true;
    }

    /**
     * @dev enables the governor to withdraw funds from the SC.
     *
     * this prevents tokens from getting locked in the SC.
     */
    function withdrawLiquidity(uint256 _edgexAmount, address _to)
        public
        virtual
        onlyAdmin
        isZero(_to)
        returns (bool)
    {
        return IERC20(edgexContract).transfer(_to, _edgexAmount);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IStaking {
    /**
     * @dev stakes the `amount` of tokens for `tenure`
     *
     * Requirements:
     * `amount` should be approved by the `caller`
     * to the staking contract.
     *
     * `tenure` shoulde be mentioned in days.
     */
    function stake(uint256 amount, uint256 tenure) external returns (bool);

    /**
     * @dev claims the {amount} of tokens plus {earned} tokens
     * after the end of {tenure}
     *
     * Requirements:
     * `stakeId` of the staking instance.
     *
     * returns a boolean to show the current state of the transaction.
     */
    function claim(uint256 stakeId) external returns (bool);

    /**
     * @dev returns the amount of unclaimed tokens.
     *
     * Requirements:
     * `user` is the ethereum address of the wallet.
     * `stakeId` is the id of the staking instance.
     *
     * returns the `total amount` and the `interest earned` respectively.
     */
    function calculateClaimAmount(address user, uint256 stakeId)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev transfers the governance from one account(`caller`) to another account(`_newOwner`).
     */
    function revokeOwnership(address _newOwner) external returns (bool);

    /**
     * @dev will change the ROI on the staking yield.
     *
     * `_newROI` is the ROI calculated per second considering 365 days in a year.
     * It should be in 13 precision.
     *
     * The change will be effective for new users who staked tokens after the change.
     */
    function changeROI(uint256 _newROI) external returns (bool);

    /**
     * #@dev will change the token contract (EDGEX)
     *
     * If we're migrating / moving the token contract.
     * This prevents the need for migration of the staking contract.
     */
    function updateEdgexContract(address _contractAddress)
        external
        returns (bool);
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

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