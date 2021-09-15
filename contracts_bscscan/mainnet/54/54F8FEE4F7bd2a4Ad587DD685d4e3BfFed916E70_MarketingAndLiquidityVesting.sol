/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// Sources flattened with hardhat v2.6.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/PercentageBasedVestingContract.sol

pragma solidity ^0.8.0;



contract PercentageBasedVestingContract is Ownable, Initializable{
    address public immutable token;
    IERC20 private tokenContract;

    uint256 public constant interval = 1 * 30 days;  // Delays between each unlock
    uint256 public cliff;

    uint256 [] public distributionPerMonthPercentage;
    uint256 public cycles;
    mapping (address => VestingTerms) public vestingData;

    uint256 public nextUnlock = block.timestamp;
    uint256 public immutable unlockEnd;

    event Distribute(address to, uint256 amount);

    struct InitialVestingData {
        address beneficiary;
        uint256 totalVestedTokens;

    }

    struct VestingTerms {
        uint256 totalVestedTokens;
        uint256 totalReleased;
        uint256 nextUnlock;
        uint256 countUnlock;
    }

    constructor(address token_, uint8 [] memory distributionPerMonthPercentage_, uint256 cliff_) {
        token = token_;
        cycles = distributionPerMonthPercentage_.length; // Numbers of months the distribution needs to run for
        distributionPerMonthPercentage = distributionPerMonthPercentage_;
        tokenContract = IERC20(token_);
        cliff = cliff_;
        unlockEnd = block.timestamp + cliff + (cycles - 1) * interval;
    }

    /* This function can only be called once */
    /* cliff needs to be in seconds */
    function addVestingPolicy(InitialVestingData [] memory initialVestingData_) public onlyOwner initializer {
        for (uint i = 0; i < initialVestingData_.length; i++){
            vestingData[initialVestingData_[i].beneficiary] = VestingTerms(initialVestingData_[i].totalVestedTokens, 0, block.timestamp + cliff, 0);
        }
    }

    function distribute() public {
        require(vestingData[msg.sender].totalVestedTokens > 0, "The account does not have any vested tokens.");
        require(vestingData[msg.sender].totalVestedTokens > vestingData[msg.sender].totalReleased, "Already claimed all tokens");
        require(block.timestamp > vestingData[msg.sender].nextUnlock, "No tokens to distribute yet");
        vestingData[msg.sender].nextUnlock = vestingData[msg.sender].nextUnlock + interval;

        uint256 countUnlock = vestingData[msg.sender].countUnlock;
        uint256 amountOfTokensToSend = vestingData[msg.sender].totalVestedTokens * distributionPerMonthPercentage[countUnlock] / 100;

        if (amountOfTokensToSend > 0) {
            uint256 initialTokenBalance = tokenContract.balanceOf(msg.sender);
            tokenContract.transfer(msg.sender, amountOfTokensToSend);
            uint256 afterTokenBalance = tokenContract.balanceOf(msg.sender);
            require(afterTokenBalance - initialTokenBalance > 0, "Failed sending tokens");
        }

        vestingData[msg.sender].countUnlock += 1;
        vestingData[msg.sender].totalReleased += amountOfTokensToSend;

        require(vestingData[msg.sender].totalVestedTokens >= vestingData[msg.sender].totalReleased, "Sanity check failed");
        emit Distribute(msg.sender, amountOfTokensToSend);
    }

    function recoverLeftover() public {
        require(vestingData[msg.sender].totalVestedTokens > 0, "The account does not have any vested tokens.");
        require(unlockEnd <= block.timestamp, "Distribution not completed");
        require(vestingData[msg.sender].totalVestedTokens > vestingData[msg.sender].totalReleased, "No leftovers to recover");
        uint256 leftOverBalance = vestingData[msg.sender].totalVestedTokens - vestingData[msg.sender].totalReleased;

        uint256 initialTokenBalance = tokenContract.balanceOf(msg.sender);
        tokenContract.transfer(msg.sender, leftOverBalance);
        uint256 afterTokenBalance = tokenContract.balanceOf(msg.sender);
        require(afterTokenBalance - initialTokenBalance > 0, "Failed sending tokens");

        vestingData[msg.sender].totalReleased += leftOverBalance;

        emit Distribute(msg.sender, leftOverBalance);
    }


}


// File contracts/For Client/MarketingAndLiquidityVesting.sol

pragma solidity ^0.8.0;


contract MarketingAndLiquidityVesting is PercentageBasedVestingContract {
    /* This array is the amount of % of the total allocation to be released in the month */
    uint8 [] distributionPercentage = [10, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
    uint256 cliff_ = 0;
    address tokenAddress = 0x0055448eEefD5c4bAc80d260fa63FF0D8402685f;
    InitialVestingData [] initialVestingData_;
    constructor() PercentageBasedVestingContract(tokenAddress,  distributionPercentage, cliff_ ){
        InitialVestingData [1] memory tmp = [
        InitialVestingData(0x45C40E472770686d6f30fCa1724cCFd56A43E740, 20_000_000 ether)
        ];

        for (uint i = 0; i < tmp.length; i++) {
            initialVestingData_.push(tmp[i]);
        }

        /* Vesting Policy 20,00,000 in total */
        addVestingPolicy(initialVestingData_);
    }



}