/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/LOTTGE.sol

contract LOTTGE is Ownable {
    event InvestorsAdded(
        address[] investors,
        uint256[] tokenAllocations,
        address caller
    );

    event InvestorAdded(
        address indexed investor,
        address indexed caller,
        uint256 allocation
    );

    event InvestorRemoved(
        address indexed investor,
        address indexed caller,
        uint256 allocation
    );

    event WithdrawnTokens(address indexed investor, uint256 value);

    event DepositInvestment(address indexed investor, uint256 value);

    event TransferInvestment(address indexed owner, uint256 value);

    event RecoverToken(address indexed token, uint256 indexed amount);

    uint256 private constant _remainingDistroPercentage = 67;
    uint256 private constant _noOfRemaingDays = 120;
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;

    IERC20 private _fmtToken;
    uint256 private _totalAllocatedAmount;
    uint256 private _initialTimestamp;
    address[] public investors;

    struct Investor {
        bool exists;
        uint256 withdrawnTokens;
        uint256 tokensAllotment;
    }

    mapping(address => Investor) public investorsInfo;

    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;
    /// @dev Boolean variable that indicates whether the investors set was finalized.
    bool public isFinalized = false;

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the contract is initialized.
    modifier notInitialized() {
        require(!isInitialized, "initialized");
        _;
    }

    modifier onlyInvestor() {
        require(investorsInfo[_msgSender()].exists, "Only investors allowed");
        _;
    }

    constructor(address _token) {
        _fmtToken = IERC20(_token);
    }

    function getInitialTimestamp() public view returns (uint256 timestamp) {
        return _initialTimestamp;
    }

    function _diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    /// @dev release tokens to all the investors
    function releaseTokens() external onlyOwner initialized {
        for (uint8 i = 0; i < investors.length; i++) {
            Investor storage investor = investorsInfo[investors[i]];
            uint256 tokensAvailable = withdrawableTokens(investors[i]);
            if (tokensAvailable > 0) {
                investor.withdrawnTokens =
                    investor.withdrawnTokens +
                    tokensAvailable;
                _fmtToken.transfer(investors[i], tokensAvailable);
            }
        }
    }

    /// @dev Adds investors. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investors The addresses of new investors.
    /// @param _tokenAllocations The amounts of the tokens that belong to each investor.
    function addInvestors(
        address[] calldata _investors,
        uint256[] calldata _tokenAllocations
    ) external onlyOwner {
        require(
            _investors.length == _tokenAllocations.length,
            "different arrays sizes"
        );
        for (uint256 i = 0; i < _investors.length; i++) {
            _addInvestor(_investors[i], _tokenAllocations[i]);
        }
        emit InvestorsAdded(_investors, _tokenAllocations, msg.sender);
    }

    // 25% at TGE, 75% released daily over 270 Days, no Cliff
    function withdrawTokens() external onlyInvestor initialized {
        Investor storage investor = investorsInfo[_msgSender()];

        uint256 tokensAvailable = withdrawableTokens(_msgSender());

        require(tokensAvailable > 0, "no tokens available to withdraw.");

        investor.withdrawnTokens = investor.withdrawnTokens + tokensAvailable;
        _fmtToken.transfer(_msgSender(), tokensAvailable);

        emit WithdrawnTokens(_msgSender(), tokensAvailable);
    }

    /// @dev The starting time of TGE
    /// @param _timestamp The initial timestamp, this timestap should be used for vesting
    function setInitialTimestamp(uint256 _timestamp)
        external
        onlyOwner
        notInitialized
    {
        isInitialized = true;
        _initialTimestamp = _timestamp;
    }

    /// @dev withdrawble tokens for an address
    /// @param _investor whitelisted investor address
    function withdrawableTokens(address _investor)
        public
        view
        returns (uint256 tokens)
    {
        if (!isInitialized) {
            return 0;
        }
        Investor storage investor = investorsInfo[_investor];
        uint256 availablePercentage = _calculateAvailablePercentage();
        uint256 noOfTokens = _calculatePercentage(
            investor.tokensAllotment,
            availablePercentage
        );
        uint256 tokensAvailable = noOfTokens - investor.withdrawnTokens;

        return tokensAvailable;
    }

    /// @dev Adds investor. This function doesn't limit max gas consumption,
    /// so adding too many investors can cause it to reach the out-of-gas error.
    /// @param _investor The addresses of new investors.
    /// @param _tokensAllotment The amounts of the tokens that belong to each investor.
    function _addInvestor(address _investor, uint256 _tokensAllotment)
        internal
        onlyOwner
    {
        require(_investor != address(0), "Invalid address");
        require(
            _tokensAllotment > 0,
            "the investor allocation must be more than 0"
        );
        Investor storage investor = investorsInfo[_investor];

        require(investor.tokensAllotment == 0, "investor already added");

        investor.tokensAllotment = _tokensAllotment;
        investor.exists = true;
        investors.push(_investor);
        _totalAllocatedAmount = _totalAllocatedAmount + _tokensAllotment;
        emit InvestorAdded(_investor, _msgSender(), _tokensAllotment);
    }

    /// @dev calculate percentage value from amount
    /// @param _amount amount input to find the percentage
    /// @param _percentage percentage for an amount
    function _calculatePercentage(uint256 _amount, uint256 _percentage)
        private
        pure
        returns (uint256 percentage)
    {
        return ((_amount * _percentage) / 100) / 1e18;
    }

    function _calculateAvailablePercentage()
        private
        view
        returns (uint256 availablePercentage)
    {
        // x Token assigned
        // 33% on TGE
        // x - .33x tokens distributed for 120 days - 67% remaining
        // .67 * x / 120 tokens per day
        uint256 oneDays = _initialTimestamp + 1 days;
        uint256 vestingDuration = _initialTimestamp + 120 days;

        uint256 everyDayReleasePercentage = (_remainingDistroPercentage *
            1e18) / _noOfRemaingDays;

        uint256 currentTimeStamp = block.timestamp;
        if (currentTimeStamp > _initialTimestamp) {
            if (currentTimeStamp <= oneDays) {
                return uint256(33) * 1e18;
            } else if (
                currentTimeStamp > oneDays && currentTimeStamp < vestingDuration
            ) {
                uint256 noOfDays = _diffDays(
                    _initialTimestamp,
                    currentTimeStamp
                );
                uint256 currentUnlockedPercentage = noOfDays *
                    everyDayReleasePercentage;

                return (uint256(33) * 1e18) + currentUnlockedPercentage;
            } else {
                return uint256(100) * 1e18;
            }
        }
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(_msgSender(), amount);
        emit RecoverToken(_token, amount);
    }
}