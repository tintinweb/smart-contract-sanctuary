/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT

//** Meliora Crowfunding Contract*/
//** Author Alex Hong : Meliora Finance 2021.5 */


// SPDX-License-Identifier: MIT

//** Meliora Crowfunding Contract*/
//** Author Alex Hong : Meliora Finance 2021.5 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity 0.6.6;




contract MelioraLaunchpad {
    using SafeMath for uint256;

    address payable internal melioraFactoryAddress;
    address payable public melioraDevAddress;

    IERC20 public token;
    address payable public launchpadCreatorAddress;
    address public unsoldTokensDumpAddress;

    mapping(address => uint256) public investments;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => bool) public claimed;

    uint256 private melioraDevFeePercentage;
    uint256 private melioraMinDevFeeInWei;
    uint256 public melioraId;

    uint256 public totalInvestorsCount;
    uint256 public launchpadCreatorClaimWei;
    uint256 public launchpadCreatorClaimTime;
    uint256 public totalCollectedWei;
    uint256 public totalTokens;
    uint256 public tokensLeft;
    uint256 public tokenPriceInWei;
    uint256 public hardCapInWei;
    uint256 public softCapInWei;
    uint256 public maxInvestInWei;
    uint256 public minInvestInWei;
    uint256 public openTime;
    uint256 public closeTime;
    bool public onlyWhitelistedAddressesAllowed = true;
    bool public melioraDevFeesExempted = false;
    bool public launchpadCancelled = false;

    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkDiscord;
    bytes32 public linkWebsite;

    constructor(address _melioraFactoryAddress, address _melioraDevAddress)
        public
    {
        require(_melioraFactoryAddress != address(0));
        require(_melioraDevAddress != address(0));

        melioraFactoryAddress = payable(_melioraFactoryAddress);
        melioraDevAddress = payable(_melioraDevAddress);
    }

    modifier onlyMelioraDev() {
        require(
            melioraFactoryAddress == msg.sender ||
                melioraDevAddress == msg.sender
        );
        _;
    }

    modifier onlyMelioraFactory() {
        require(melioraFactoryAddress == msg.sender, "Must be same address");
        _;
    }

    modifier onlyLaunchpadCreatorOrmelioraFactory() {
        require(
            launchpadCreatorAddress == msg.sender ||
                melioraFactoryAddress == msg.sender,
            "Not launchpad creator or factory"
        );
        _;
    }

    modifier onlyLaunchpadCreator() {
        require(launchpadCreatorAddress == msg.sender, "Not launchpad creator");
        _;
    }

    modifier whitelistedAddressOnly() {
        require(
            !onlyWhitelistedAddressesAllowed ||
                whitelistedAddresses[msg.sender],
            "Address not whitelisted"
        );
        _;
    }

    modifier launchpadIsNotCancelled() {
        require(!launchpadCancelled, "Cancelled");
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0, "Not an investor");
        _;
    }

    modifier notYetClaimedOrRefunded() {
        require(!claimed[msg.sender], "Already claimed or refunded");
        _;
    }

    function setAddressInfo(
        address _launchpadCreator,
        address _tokenAddress,
        address _unsoldTokensDumpAddress
    ) external onlyMelioraFactory {
        require(_launchpadCreator != address(0));
        require(_tokenAddress != address(0));
        require(_unsoldTokensDumpAddress != address(0));

        launchpadCreatorAddress = payable(_launchpadCreator);
        token = IERC20(_tokenAddress);
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime
    ) external onlyMelioraFactory {

        require(_totalTokens > 0,  "totalTokens < 0");
        require(_tokenPriceInWei > 0, "_tokenPriceInWei < 0");
        require(_openTime > 0, "_openTime < 0");
        require(_closeTime > 0, "_closeTime < 0");
        require(_hardCapInWei > 0, "_hardCapInWei < 0");
  
        
        require(_hardCapInWei <= _totalTokens.mul(_tokenPriceInWei), "_hardCapInWei over");
        require(_softCapInWei <= _hardCapInWei, "_softCapInWei> _hardCapInWei");
        require(_minInvestInWei <= _maxInvestInWei, "_minInvestInWei >  _maxInvestInWei");
        require(_openTime < _closeTime, "_openTime > _closeTime");
        
        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkDiscord,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite
    ) external onlyLaunchpadCreatorOrmelioraFactory {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkDiscord = _linkDiscord;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
    }
    function setMelioraInfo(
        uint256 _melioraDevFeePercentage,
        uint256 _melioraMinDevFeeInWei,
        uint256 _melioraId
    ) external onlyMelioraDev {
        melioraDevFeePercentage = _melioraDevFeePercentage;
        melioraMinDevFeeInWei = _melioraMinDevFeeInWei;
        melioraId = _melioraId;
    }

    function setmelioraDevFeesExempted(bool _melioraDevFeesExempted)
        external
        onlyMelioraDev
    {
        melioraDevFeesExempted = _melioraDevFeesExempted;
    }

    function setOnlyWhitelistedAddressesAllowed(
        bool _onlyWhitelistedAddressesAllowed
    ) external onlyLaunchpadCreatorOrmelioraFactory {
        onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
    }

    function addwhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyLaunchpadCreatorOrmelioraFactory
    {
        onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.mul(1e18).div(tokenPriceInWei);
    }

    function invest()
        public
        payable
        whitelistedAddressOnly
        launchpadIsNotCancelled
    {
        require(block.timestamp >= openTime, "Not yet opened");
        require(block.timestamp < closeTime, "Closed");
        require(totalCollectedWei < hardCapInWei, "Hard cap reached");
        require(tokensLeft > 0);
        require(msg.value <= tokensLeft.mul(tokenPriceInWei));
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);
        require(
            totalInvestmentInWei >= minInvestInWei ||
                totalCollectedWei >= hardCapInWei.sub(1 ether),
            "Min investment not reached"
        );
        require(
            maxInvestInWei == 0 || totalInvestmentInWei <= maxInvestInWei,
            "Max investment reached"
        );

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }

    receive() external payable {
        invest();
    }

    function addLiquidityAndLockLPTokens() external launchpadIsNotCancelled {
        require(totalCollectedWei > 0);
        require(
            !onlyWhitelistedAddressesAllowed ||
                whitelistedAddresses[msg.sender] ||
                msg.sender == launchpadCreatorAddress,
            "Not whitelisted or not launchpad creator"
        );

        if (totalCollectedWei >= hardCapInWei.sub(1 ether)) {
            require(
                msg.sender == launchpadCreatorAddress,
                "Not launchpad creator"
            );
        } else {
            revert("Liquidity cannot be added yet");
        }

        uint256 finalTotalCollectedWei = totalCollectedWei;
        uint256 melioraDevFeeInWei;
        if (!melioraDevFeesExempted) {
            uint256 pctDevFee =
                finalTotalCollectedWei.mul(melioraDevFeePercentage).div(100);
            melioraDevFeeInWei = pctDevFee > melioraMinDevFeeInWei ||
                melioraMinDevFeeInWei >= finalTotalCollectedWei
                ? pctDevFee
                : melioraMinDevFeeInWei;
        }
        if (melioraDevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(
                melioraDevFeeInWei
            );
            melioraDevAddress.transfer(melioraDevFeeInWei);
        }

        uint256 unsoldTokensAmount =
            token.balanceOf(address(this)).sub(
                getTokenAmount(totalCollectedWei)
            );
        if (unsoldTokensAmount > 0) {
            token.transfer(unsoldTokensDumpAddress, unsoldTokensAmount);
        }

        launchpadCreatorClaimWei = address(this).balance.mul(1e18).div(
            totalInvestorsCount.mul(1e18)
        );
        launchpadCreatorClaimTime = block.timestamp + 1 days;
    }

    function claimTokens()
        external
        whitelistedAddressOnly
        launchpadIsNotCancelled
        investorOnly
        notYetClaimedOrRefunded
    {
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        token.transfer(msg.sender, getTokenAmount(investments[msg.sender]));

        uint256 balance = address(this).balance;
        if (balance > 0) {
            uint256 funds =
                launchpadCreatorClaimWei > balance
                    ? balance
                    : launchpadCreatorClaimWei;
            launchpadCreatorAddress.transfer(funds);
        }
    }

    function getRefund()
        external
        whitelistedAddressOnly
        investorOnly
        notYetClaimedOrRefunded
    {
        if (!launchpadCancelled) {
            require(block.timestamp >= openTime, "Not yet opened");
            require(block.timestamp >= closeTime, "Not yet closed");
            require(softCapInWei > 0, "No soft cap");
            require(totalCollectedWei < softCapInWei, "Soft cap reached");
        }

        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        uint256 investment = investments[msg.sender];
        uint256 launchpadBalance = address(this).balance;
        require(launchpadBalance > 0);

        if (investment > launchpadBalance) {
            investment = launchpadBalance;
        }

        if (investment > 0) {
            msg.sender.transfer(investment);
        }
    }

    function cancelAndTransferTokensTolaunchpadCreator() external {
        if (
            launchpadCreatorAddress != msg.sender &&
            melioraDevAddress != msg.sender
        ) {
            revert();
        }

        require(!launchpadCancelled);
        launchpadCancelled = true;

        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(launchpadCreatorAddress, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

//** Meliora Crowfunding Contract*/
//** Author Alex Hong : Meliora Finance 2021.5 */


// SPDX-License-Identifier: MIT


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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity 0.6.6;



contract MelioraInfo is Ownable {
    uint256 private devFeePercentage = 1;
    uint256 private minDevFeeInWei = 1 ether;
    address[] private launchpadAddresses;

    /**
     *
     * @dev add launchpage adress to the pool
     *
     */
    function addLaunchpadAddress(address _launchapd)
        external
        returns (uint256)
    {
        launchpadAddresses.push(_launchapd);
        return launchpadAddresses.length - 1;
    }

    /**
     *
     * @dev get launchpad count
     *
     */
    function getLaunchpadCount() external view returns (uint256) {
        return launchpadAddresses.length;
    }

    /**
     *
     * @dev get launchpad address
     *
     */
    function getLaunchpadAddress(uint256 launchId)
        external
        view
        returns (address)
    {
        return launchpadAddresses[launchId];
    }

    /**
     *
     * @dev get allocated percentage
     *
     */
    function getDevFeePercentage() external view returns (uint256) {
        return devFeePercentage;
    }

    /**
     *
     * @dev set custom fee percent
     *
     */
    function setDevFeePercentage(uint256 _devFeePercentage) external onlyOwner {
        devFeePercentage = _devFeePercentage;
    }

    /**
     *
     * @dev get minimum dev fee
     *
     */
    function getMinDevFeeInWei() external view returns (uint256) {
        return minDevFeeInWei;
    }

    /**
     *
     * @dev set minimum dev fee
     *
     */
    function setMinDevFeeInWei(uint256 _minDevFeeInWei) external onlyOwner {
        minDevFeeInWei = _minDevFeeInWei;
    }
}

pragma solidity 0.6.6;



contract MelioraFactory {
    using SafeMath for uint256;

    event LaunchpadCreated(bytes32 title, uint256 launchId, address creator);

    uint256 public testHardCap = 99;
    uint256 public testSoftCap = 88;
    uint256 public testMaxInvest = 77;
    uint256 public testOpentime = 66;
    uint256 public testDEAPP = 55;
    uint256 public testMaxTokens = 44;
    address public testTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    bytes32 public testStringInfodata = "test";
    uint256 public debug = 1;


    address private constant wethAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    MelioraInfo public immutable MELIORA;

    constructor(address _melioraInfoAddress) public {
        MELIORA = MelioraInfo(_melioraInfoAddress);
        debug = 2;

    }

    struct LaunchpadInfo {
        address tokenAddress;
        address unsoldTokensDumpAddress;
        address[] whitelistedAddresses;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 maxInvestInWei;
        uint256 minInvestInWei;
        uint256 openTime;
        uint256 closeTime;
    }
    
    struct LaunchpadStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkDiscord;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
    }


    function initializeLaunchpad(
        MelioraLaunchpad _launchpad,
        uint256 _totalTokens,
        uint256 _finalTokenPriceInWei,
        
        
        LaunchpadInfo memory _info,
        LaunchpadStringInfo memory _stringInfo
    ) internal {
        _launchpad.setAddressInfo(
            msg.sender,
            
            _info.tokenAddress,
            _info.unsoldTokensDumpAddress
        );
        _launchpad.setGeneralInfo(
           
            _totalTokens,
            _finalTokenPriceInWei,
            _info.hardCapInWei,
            _info.softCapInWei,
            _info.maxInvestInWei,
            _info.minInvestInWei,
            _info.openTime,
            _info.closeTime
        );
        testHardCap = _info.hardCapInWei;
        testSoftCap = _info.softCapInWei;
        testMaxInvest = _info.maxInvestInWei;
        testOpentime = _info.minInvestInWei;

        _launchpad.setStringInfo(
       
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkDiscord,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite
        );
        testStringInfodata =  _stringInfo.linkTelegram;
        _launchpad.addwhitelistedAddresses(_info.whitelistedAddresses);
    }

    function createLaunchpad(
        LaunchpadInfo memory _info,
        LaunchpadStringInfo memory _stringInfo
    ) public {
        IERC20 token = IERC20(_info.tokenAddress);
        debug = 2;
        MelioraLaunchpad launchpad =
            new MelioraLaunchpad(address(this), MELIORA.owner());
        debug = 3;
        uint256 maxTokensToBeSold =
            _info.hardCapInWei.mul(1e18).div(_info.tokenPriceInWei);
            testMaxTokens = maxTokensToBeSold;
        // uint256 maxEthPoolTokenAmount =
        //     _info.hardCapInWei.mul(_uniInfo.liquidityPercentageAllocation).div(
        //         100
        //     );
        // uint256 maxLiqPoolTokenAmount =
        //     maxEthPoolTokenAmount.mul(1e18).div(_uniInfo.listingPriceInWei);
        // uint256 requiredTokenAmount =
        //     maxLiqPoolTokenAmount.add(maxTokensToBeSold);

        uint256 requiredTokenAmount = 1e18;
        token.transferFrom(msg.sender, address(launchpad), requiredTokenAmount);
        debug = 4;
        initializeLaunchpad(
            launchpad,
            maxTokensToBeSold,
            _info.tokenPriceInWei,
            _info,
            _stringInfo
        );
        testHardCap = _info.hardCapInWei+1;
  
        testSoftCap = _info.softCapInWei+1;


        uint256 melioraId = MELIORA.addLaunchpadAddress(address(launchpad));

        emit LaunchpadCreated(_stringInfo.saleTitle, melioraId, msg.sender);
    }
}