/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

// Sources flattened with hardhat v2.0.10 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/interfaces/ITimelockManager.sol

pragma solidity 0.6.12;


interface ITimelockManager {
    event Api3PoolUpdated(address api3PoolAddress);

    event RevertedTimelock(
        address indexed recipient,
        address destination,
        uint256 amount
        );

    event PermittedTimelockToBeReverted(address recipient);

    event TransferredAndLocked(
        address source,
        address indexed recipient,
        uint256 amount,
        uint256 releaseStart,
        uint256 releaseEnd
        );

    event Withdrawn(
        address indexed recipient,
        uint256 amount
        );

    event WithdrawnToPool(
        address indexed recipient,
        address api3PoolAddress,
        address beneficiary
        );

    function updateApi3Pool(address api3PoolAddress)
        external;

    function revertTimelock(
        address recipient,
        address destination
        )
        external;

    function permitTimelockToBeReverted()
        external;

    function transferAndLock(
        address source,
        address recipient,
        uint256 amount,
        uint256 releaseStart,
        uint256 releaseEnd
        )
        external;

    function transferAndLockMultiple(
        address source,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata releaseStarts,
        uint256[] calldata releaseEnds
        )
        external;

    function withdraw()
        external;

    function withdrawToPool(
        address api3PoolAddress,
        address beneficiary
        )
        external;

    function getWithdrawable(address recipient)
        external
        view
        returns(uint256 withdrawable);

    function getTimelock(address recipient)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 remainingAmount,
            uint256 releaseStart,
            uint256 releaseEnd
            );

    function getRemainingAmount(address recipient)
        external
        view
        returns (uint256 remainingAmount);

    function getIfTimelockIsRevertible(address recipient)
        external
        view
        returns (bool revertStatus);
}


// File contracts/TimelockAgent.sol

pragma solidity 0.6.12;



contract TimelockAgent is Ownable {
    struct Timelock{
        address timelockContractAddress;
        address recipient;
        uint256 amount;
        uint256 releaseStart;
        uint256 releaseEnd;
        }

    IERC20 public api3Token;
    address public api3Dao;
    Timelock[] private timelocks;

    constructor (
        address _api3Token,
        address _api3Dao
        )
        public
    {
        api3Token = IERC20(_api3Token);
        api3Dao = _api3Dao;
    }

    function setTimelocks(
        address[] calldata timelockContractAddresses,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata releaseStarts,
        uint256[] calldata releaseEnds
        )
        external
        onlyOwner
    {
        require(
            timelockContractAddresses.length == recipients.length
                && timelockContractAddresses.length == amounts.length
                && timelockContractAddresses.length == releaseStarts.length
                && timelockContractAddresses.length == releaseEnds.length,
            "Parameters are of unequal length"
            );
        require(
            timelockContractAddresses.length <= 30,
            "Parameters are longer than 30"
            );
        require(
            timelocks.length == 0,
            "Timelocks already set"
            );
        for (uint256 ind = 0; ind < timelockContractAddresses.length; ind++)
        {
            timelocks.push(Timelock(
                timelockContractAddresses[ind],
                recipients[ind],
                amounts[ind],
                releaseStarts[ind],
                releaseEnds[ind]
                ));
        }
    }

    function getTimelocks()
        external
        view
        returns (
            address[] memory timelockContractAddresses,
            address[] memory recipients,
            uint256[] memory amounts,
            uint256[] memory releaseStarts,
            uint256[] memory releaseEnds
            )
    {
        timelockContractAddresses = new address[](timelocks.length);
        recipients = new address[](timelocks.length);
        amounts = new uint256[](timelocks.length);
        releaseStarts = new uint256[](timelocks.length);
        releaseEnds = new uint256[](timelocks.length);
        for (uint256 ind = 0; ind < timelocks.length; ind++)
        {
            Timelock storage timelock = timelocks[ind];
            timelockContractAddresses[ind] = timelock.timelockContractAddress;
            recipients[ind] = timelock.recipient;
            amounts[ind] = timelock.amount;
            releaseStarts[ind] = timelock.releaseStart;
            releaseEnds[ind] = timelock.releaseEnd;
        }
    }

    function executeTimelocks()
        external
    {
        require(
            timelocks.length != 0,
            "Timelocks not set"
            );
        for (uint256 ind = 0; ind < timelocks.length; ind++)
        {
            Timelock storage timelock = timelocks[ind];
            api3Token.approve(timelock.timelockContractAddress, timelock.amount);
            ITimelockManager timelockManager = ITimelockManager(timelock.timelockContractAddress);
            timelockManager.transferAndLock(
                address(this),
                timelock.recipient,
                timelock.amount,
                timelock.releaseStart,
                timelock.releaseEnd
                );
        }
        delete timelocks;
    }

    function refund()
        external
        onlyOwner
    {
        api3Token.transfer(api3Dao, api3Token.balanceOf(address(this)));
    }
}