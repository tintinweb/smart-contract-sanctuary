/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;


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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Constant {
    enum ActionType { DepositAction, WithdrawAction, BorrowAction, RepayAction }
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10 ** uint256(18);
    uint256 public constant ACCURACY = 10 ** 18;
    uint256 public constant BLOCKS_PER_YEAR = 2102400;
}


library Utils{

    function _isETH(address globalConfig, address _token) public view returns (bool) {
        return IConstant(IGlobalConfig(globalConfig).constants()).ETH_ADDR() == _token;
    }

    function getDivisor(address globalConfig, address _token) public view returns (uint256) {
        if(_isETH(globalConfig, _token)) return IConstant(IGlobalConfig(globalConfig).constants()).INT_UNIT();
        return 10 ** uint256(ITokenRegistry(IGlobalConfig(globalConfig).tokenInfoRegistry()).getTokenDecimals(_token));
    }

}

/**
 * @dev Token Info Registry to manage Token information
 *      The Owner of the contract allowed to update the information
 */
contract TokenRegistry is Ownable, Constant {

    using SafeMath for uint256;

    /**
     * @dev TokenInfo struct stores Token Information, this includes:
     *      ERC20 Token address, Compound Token address, ChainLink Aggregator address etc.
     * @notice This struct will consume 5 storage locations
     */
    struct TokenInfo {
        // Token index, can store upto 255
        uint8 index;
        // ERC20 Token decimal
        uint8 decimals;
        // If token is enabled / disabled
        bool enabled;
        // Is ERC20 token charge transfer fee?
        bool isTransferFeeEnabled;
        // Is Token supported on Compound
        bool isSupportedOnCompound;
        // cToken address on Compound
        address cToken;
        // Chain Link Aggregator address for TOKEN/ETH pair
        address chainLinkOracle;
        // Borrow LTV, by default 60%
        uint256 borrowLTV;
    }

    event TokenAdded(address indexed token);
    event TokenUpdated(address indexed token);

    uint256 public constant MAX_TOKENS = 128;
    uint256 public constant SCALE = 100;

    // TokenAddress to TokenInfo mapping
    mapping (address => TokenInfo) public tokenInfo;

    // TokenAddress array
    address[] public tokens;
    IGlobalConfig public globalConfig;

    /**
     */
    modifier whenTokenExists(address _token) {
        require(isTokenExist(_token), "Token not exists");
        _;
    }

    /**
     *  initializes the symbols structure
     */
    function initialize(IGlobalConfig _globalConfig) public onlyOwner{
        globalConfig = _globalConfig;
    }

    /**
     * @dev Add a new token to registry
     * @param _token ERC20 Token address
     * @param _decimals Token's decimals
     * @param _isTransferFeeEnabled Is token changes transfer fee
     * @param _isSupportedOnCompound Is token supported on Compound
     * @param _cToken cToken contract address
     * @param _chainLinkOracle Chain Link Aggregator address to get TOKEN/ETH rate
     */
    function addToken(
        address _token,
        uint8 _decimals,
        bool _isTransferFeeEnabled,
        bool _isSupportedOnCompound,
        address _cToken,
        address _chainLinkOracle
    )
        public
        onlyOwner
    {
        require(_token != address(0), "Token address is zero");
        require(!isTokenExist(_token), "Token already exist");
        require(_chainLinkOracle != address(0), "ChainLinkAggregator address is zero");
        require(tokens.length < MAX_TOKENS, "Max token limit reached");

        TokenInfo storage storageTokenInfo = tokenInfo[_token];
        storageTokenInfo.index = uint8(tokens.length);
        storageTokenInfo.decimals = _decimals;
        storageTokenInfo.enabled = true;
        storageTokenInfo.isTransferFeeEnabled = _isTransferFeeEnabled;
        storageTokenInfo.isSupportedOnCompound = _isSupportedOnCompound;
        storageTokenInfo.cToken = _cToken;
        storageTokenInfo.chainLinkOracle = _chainLinkOracle;
        // Default values
        storageTokenInfo.borrowLTV = 60; //6e7; // 60%

        tokens.push(_token);
        emit TokenAdded(_token);
    }

    function updateBorrowLTV(
        address _token,
        uint256 _borrowLTV
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].borrowLTV == _borrowLTV)
            return;

        // require(_borrowLTV != 0, "Borrow LTV is zero");
        require(_borrowLTV < SCALE, "Borrow LTV must be less than Scale");
        // require(liquidationThreshold > _borrowLTV, "Liquidation threshold must be greater than Borrow LTV");

        tokenInfo[_token].borrowLTV = _borrowLTV;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateTokenTransferFeeFlag(
        address _token,
        bool _isTransfeFeeEnabled
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].isTransferFeeEnabled == _isTransfeFeeEnabled)
            return;

        tokenInfo[_token].isTransferFeeEnabled = _isTransfeFeeEnabled;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateTokenSupportedOnCompoundFlag(
        address _token,
        bool _isSupportedOnCompound
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].isSupportedOnCompound == _isSupportedOnCompound)
            return;

        tokenInfo[_token].isSupportedOnCompound = _isSupportedOnCompound;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateCToken(
        address _token,
        address _cToken
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].cToken == _cToken)
            return;

        tokenInfo[_token].cToken = _cToken;
        emit TokenUpdated(_token);
    }

    /**
     */
    function updateChainLinkAggregator(
        address _token,
        address _chainLinkOracle
    )
        external
        onlyOwner
        whenTokenExists(_token)
    {
        if (tokenInfo[_token].chainLinkOracle == _chainLinkOracle)
            return;

        tokenInfo[_token].chainLinkOracle = _chainLinkOracle;
        emit TokenUpdated(_token);
    }


    function enableToken(address _token) external onlyOwner whenTokenExists(_token) {
        require(!tokenInfo[_token].enabled, "Token already enabled");

        tokenInfo[_token].enabled = true;

        emit TokenUpdated(_token);
    }

    function disableToken(address _token) external onlyOwner whenTokenExists(_token) {
        require(tokenInfo[_token].enabled, "Token already disabled");

        tokenInfo[_token].enabled = false;

        emit TokenUpdated(_token);
    }

    // =====================
    //      GETTERS
    // =====================

    /**
     * @dev Is token address is registered
     * @param _token token address
     * @return Returns `true` when token registered, otherwise `false`
     */
    function isTokenExist(address _token) public view returns (bool isExist) {
        isExist = tokenInfo[_token].chainLinkOracle != address(0);
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getTokenIndex(address _token) external view returns (uint8) {
        return tokenInfo[_token].index;
    }

    function isTokenEnabled(address _token) external view returns (bool) {
        return tokenInfo[_token].enabled;
    }

    /**
     */
    function getCTokens() external view returns (address[] memory cTokens) {
        uint256 len = tokens.length;
        cTokens = new address[](len);
        for(uint256 i = 0; i < len; i++) {
            cTokens[i] = tokenInfo[tokens[i]].cToken;
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8) {
        return tokenInfo[_token].decimals;
    }

    function isTransferFeeEnabled(address _token) external view returns (bool) {
        return tokenInfo[_token].isTransferFeeEnabled;
    }

    function isSupportedOnCompound(address _token) external view returns (bool) {
        return tokenInfo[_token].isSupportedOnCompound;
    }

    /**
     */
    function getCToken(address _token) external view returns (address) {
        return tokenInfo[_token].cToken;
    }

    function getChainLinkAggregator(address _token) external view returns (address) {
        return tokenInfo[_token].chainLinkOracle;
    }

    function getBorrowLTV(address _token) external view returns (uint256) {
        return tokenInfo[_token].borrowLTV;
    }

    function getCoinLength() public view returns (uint256 length) {
        return tokens.length;
    }

    function addressFromIndex(uint index) public view returns(address) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        return tokens[index];
    }

    function priceFromIndex(uint index) public view returns(uint256) {
        require(index < tokens.length, "coinIndex must be smaller than the coins length.");
        address tokenAddress = tokens[index];
        // Temp fix
        if(Utils._isETH(address(globalConfig), tokenAddress)) {
            return 1e18;
        }
        return uint256(IAggregator(globalConfig.chainLink()).getLatestAnswer(tokenAddress));
    }

    function priceFromAddress(address tokenAddress) public view returns(uint256) {
        if(Utils._isETH(address(globalConfig), tokenAddress)) {
            return 1e18;
        }
        return uint256(IAggregator(globalConfig.chainLink()).getLatestAnswer(tokenAddress));
    }

     function _priceFromAddress(address _token) internal view returns (uint) {
        return _token != ETH_ADDR ? uint256(IAggregator(globalConfig.chainLink()).getLatestAnswer(_token)) : INT_UNIT;
    }

    function _tokenDivisor(address _token) internal view returns (uint) {
        return _token != ETH_ADDR ? 10**uint256(tokenInfo[_token].decimals) : INT_UNIT;
    }

    function getTokenInfoFromIndex(uint index)
        external
        view
        whenTokenExists(addressFromIndex(index))
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        address token = tokens[index];
        return (
            token,
            _tokenDivisor(token),
            _priceFromAddress(token),
            tokenInfo[token].borrowLTV
        );
    }

    function getTokenInfoFromAddress(address _token)
        external
        view
        whenTokenExists(_token)
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            tokenInfo[_token].index,
            _tokenDivisor(_token),
            _priceFromAddress(_token),
            tokenInfo[_token].borrowLTV
        );
    }

    // function _isETH(address _token) public view returns (bool) {
    //     return globalConfig.constants().ETH_ADDR() == _token;
    // }

    // function getDivisor(address _token) public view returns (uint256) {
    //     if(_isETH(_token)) return INT_UNIT;
    //     return 10 ** uint256(getTokenDecimals(_token));
    // }

    mapping(address => uint) public depositeMiningSpeeds;
    mapping(address => uint) public borrowMiningSpeeds;

    function updateMiningSpeed(address _token, uint _depositeMiningSpeed, uint _borrowMiningSpeed) public onlyOwner{
        if(_depositeMiningSpeed != depositeMiningSpeeds[_token]) {
            depositeMiningSpeeds[_token] = _depositeMiningSpeed;
        }
        
        if(_borrowMiningSpeed != borrowMiningSpeeds[_token]) {
            borrowMiningSpeeds[_token] = _borrowMiningSpeed;
        }

        emit TokenUpdated(_token);
    }
}

interface IGlobalConfig {
    function constants() external view returns (address);
    function tokenInfoRegistry() external view returns (address);
    function chainLink() external view returns (address);
}

interface IConstant {
    function ETH_ADDR() external view returns (address);
    function INT_UNIT() external view returns (uint256);
}

interface ITokenRegistry {
    function getTokenDecimals(address) external view returns (uint8);
}

interface IAggregator {
    function getLatestAnswer(address) external view returns (int256);
}