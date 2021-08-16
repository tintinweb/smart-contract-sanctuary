/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity 0.5.14;


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

contract GlobalConfig is Ownable {
    using SafeMath for uint256;

    uint256 public communityFundRatio = 10;
    uint256 public minReserveRatio = 10;
    uint256 public maxReserveRatio = 20;
    uint256 public liquidationThreshold = 85;
    uint256 public liquidationDiscountRatio = 95;
    uint256 public compoundSupplyRateWeights = 4;
    uint256 public compoundBorrowRateWeights = 6;
    uint256 public rateCurveSlope = 15 * 10 ** 16;
    uint256 public rateCurveConstant = 3 * 10 ** 16;
    uint256 public deFinerRate = 10;
    address payable public deFinerCommunityFund = msg.sender;

    address public bank;                               // the Bank contract
    address public savingAccount;             // the SavingAccount contract
    address public tokenInfoRegistry;     // the TokenRegistry contract
    address public accounts;                       // the Accounts contract
    address public constants;                      // the constants contract
    address public chainLink;

    event CommunityFundRatioUpdated(uint256 indexed communityFundRatio);
    event MinReserveRatioUpdated(uint256 indexed minReserveRatio);
    event MaxReserveRatioUpdated(uint256 indexed maxReserveRatio);
    event LiquidationThresholdUpdated(uint256 indexed liquidationThreshold);
    event LiquidationDiscountRatioUpdated(uint256 indexed liquidationDiscountRatio);
    event CompoundSupplyRateWeightsUpdated(uint256 indexed compoundSupplyRateWeights);
    event CompoundBorrowRateWeightsUpdated(uint256 indexed compoundBorrowRateWeights);
    event rateCurveSlopeUpdated(uint256 indexed rateCurveSlope);
    event rateCurveConstantUpdated(uint256 indexed rateCurveConstant);
    event ConstantUpdated(address indexed constants);
    event BankUpdated(address indexed bank);
    event SavingAccountUpdated(address indexed savingAccount);
    event TokenInfoRegistryUpdated(address indexed tokenInfoRegistry);
    event AccountsUpdated(address indexed accounts);
    event DeFinerCommunityFundUpdated(address indexed deFinerCommunityFund);
    event DeFinerRateUpdated(uint256 indexed deFinerRate);
    event ChainLinkUpdated(address indexed chainLink);


    function initialize(
        address _bank,
        address _savingAccount,
        address _tokenInfoRegistry,
        address _accounts,
        address _constants,
        address _chainLink
    ) public onlyOwner {
        bank = _bank;
        savingAccount = _savingAccount;
        tokenInfoRegistry = _tokenInfoRegistry;
        accounts = _accounts;
        constants = _constants;
        chainLink = _chainLink;
    }

    /**
     * Update the community fund (commision fee) ratio.
     * @param _communityFundRatio the new ratio
     */
    function updateCommunityFundRatio(uint256 _communityFundRatio) external onlyOwner {
        if (_communityFundRatio == communityFundRatio)
            return;

        require(_communityFundRatio > 0 && _communityFundRatio < 100,
            "Invalid community fund ratio.");
        communityFundRatio = _communityFundRatio;

        emit CommunityFundRatioUpdated(_communityFundRatio);
    }

    /**
     * Update the minimum reservation reatio
     * @param _minReserveRatio the new value of the minimum reservation ratio
     */
    function updateMinReserveRatio(uint256 _minReserveRatio) external onlyOwner {
        if (_minReserveRatio == minReserveRatio)
            return;

        require(_minReserveRatio > 0 && _minReserveRatio < maxReserveRatio,
            "Invalid min reserve ratio.");
        minReserveRatio = _minReserveRatio;

        emit MinReserveRatioUpdated(_minReserveRatio);
    }

    /**
     * Update the maximum reservation reatio
     * @param _maxReserveRatio the new value of the maximum reservation ratio
     */
    function updateMaxReserveRatio(uint256 _maxReserveRatio) external onlyOwner {
        if (_maxReserveRatio == maxReserveRatio)
            return;

        require(_maxReserveRatio > minReserveRatio && _maxReserveRatio < 100,
            "Invalid max reserve ratio.");
        maxReserveRatio = _maxReserveRatio;

        emit MaxReserveRatioUpdated(_maxReserveRatio);
    }

    /**
     * Update the liquidation threshold, i.e. the LTV that will trigger the liquidation.
     * @param _liquidationThreshold the new threshhold value
     */
    function updateLiquidationThreshold(uint256 _liquidationThreshold) external onlyOwner {
        if (_liquidationThreshold == liquidationThreshold)
            return;

        require(_liquidationThreshold > 0 && _liquidationThreshold < liquidationDiscountRatio,
            "Invalid liquidation threshold.");
        liquidationThreshold = _liquidationThreshold;

        emit LiquidationThresholdUpdated(_liquidationThreshold);
    }

    /**
     * Update the liquidation discount
     * @param _liquidationDiscountRatio the new liquidation discount
     */
    function updateLiquidationDiscountRatio(uint256 _liquidationDiscountRatio) external onlyOwner {
        if (_liquidationDiscountRatio == liquidationDiscountRatio)
            return;

        require(_liquidationDiscountRatio > liquidationThreshold && _liquidationDiscountRatio < 100,
            "Invalid liquidation discount ratio.");
        liquidationDiscountRatio = _liquidationDiscountRatio;

        emit LiquidationDiscountRatioUpdated(_liquidationDiscountRatio);
    }

    /**
     * Medium value of the reservation ratio, which is the value that the pool try to maintain.
     */
    function midReserveRatio() public view returns(uint256){
        return minReserveRatio.add(maxReserveRatio).div(2);
    }

    function updateCompoundSupplyRateWeights(uint256 _compoundSupplyRateWeights) external onlyOwner{
        compoundSupplyRateWeights = _compoundSupplyRateWeights;

        emit CompoundSupplyRateWeightsUpdated(_compoundSupplyRateWeights);
    }

    function updateCompoundBorrowRateWeights(uint256 _compoundBorrowRateWeights) external onlyOwner{
        compoundBorrowRateWeights = _compoundBorrowRateWeights;

        emit CompoundBorrowRateWeightsUpdated(_compoundBorrowRateWeights);
    }

    function updaterateCurveSlope(uint256 _rateCurveSlope) external onlyOwner{
        rateCurveSlope = _rateCurveSlope;

        emit rateCurveSlopeUpdated(_rateCurveSlope);
    }

    function updaterateCurveConstant(uint256 _rateCurveConstant) external onlyOwner{
        rateCurveConstant = _rateCurveConstant;

        emit rateCurveConstantUpdated(_rateCurveConstant);
    }

    function updateBank(address _bank) external onlyOwner{
        bank = _bank;

        emit BankUpdated(_bank);
    }

    function updateSavingAccount(address _savingAccount) external onlyOwner{
        savingAccount = _savingAccount;

        emit SavingAccountUpdated(_savingAccount);
    }

    function updateTokenInfoRegistry(address _tokenInfoRegistry) external onlyOwner{
        tokenInfoRegistry = _tokenInfoRegistry;

        emit TokenInfoRegistryUpdated(_tokenInfoRegistry);
    }

    function updateAccounts(address _accounts) external onlyOwner{
        accounts = _accounts;

        emit AccountsUpdated(_accounts);
    }

    function updateConstant(address _constants) external onlyOwner{
        constants = _constants;

        emit ConstantUpdated(_constants);
    }

    function updatedeFinerCommunityFund(address payable _deFinerCommunityFund) external onlyOwner{
        deFinerCommunityFund = _deFinerCommunityFund;

        emit DeFinerCommunityFundUpdated(_deFinerCommunityFund);
    }

    function updatedeFinerRate(uint256 _deFinerRate) external onlyOwner{
        require(_deFinerRate <= 100,"_deFinerRate cannot exceed 100");
        deFinerRate = _deFinerRate;

        emit DeFinerRateUpdated(_deFinerRate);
    }

    function updateChainLink(address _chainLink) external onlyOwner{
        chainLink = _chainLink;

        emit ChainLinkUpdated(address(_chainLink));
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
        return uint256(IAggregator(tokenInfo[tokenAddress].chainLinkOracle).latestAnswer());
    }

    function priceFromAddress(address tokenAddress) public view returns(uint256) {
        if(Utils._isETH(address(globalConfig), tokenAddress)) {
            return 1e18;
        }
        return uint256(IAggregator(tokenInfo[tokenAddress].chainLinkOracle).latestAnswer());
    }

     function _priceFromAddress(address _token) internal view returns (uint) {
        return _token != ETH_ADDR ? uint256(IAggregator(tokenInfo[_token].chainLinkOracle).latestAnswer()) : INT_UNIT;
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




interface IAggregator {
    function latestAnswer() external view returns (int256);
}





/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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




/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}








library SavingLib {
    using SafeERC20 for IERC20;

    /**
     * Receive the amount of token from msg.sender
     * @param _amount amount of token
     * @param _token token address
     */
    function receive(GlobalConfig globalConfig, uint256 _amount, address _token) public {
        if (Utils._isETH(address(globalConfig), _token)) {
            require(msg.value == _amount, "The amount is not sent from address.");
        } else {
            //When only tokens received, msg.value must be 0
            require(msg.value == 0, "msg.value must be 0 when receiving tokens");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     * Send the amount of token to an address
     * @param _amount amount of token
     * @param _token token address
     */
    function send(GlobalConfig globalConfig, uint256 _amount, address _token) public {
        if (Utils._isETH(address(globalConfig), _token)) {
            msg.sender.transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

}



/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


/**
 * @notice Code copied from OpenZeppelin, to make it an upgradable contract
 */
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initialize() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}




/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract InitializablePausable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);
    
    address private globalConfigPausable;
    bool private _paused;

    function _initialize(address _globalConfig) internal {
        globalConfigPausable = _globalConfig;
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(GlobalConfig(globalConfigPausable).owner());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(GlobalConfig(globalConfigPausable).owner());
    }

    modifier onlyPauser() {
        require(msg.sender == GlobalConfig(globalConfigPausable).owner(), "PauserRole: caller does not have the Pauser role");
        _;
    }
}



interface ICToken {
    function supplyRatePerBlock() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function redeem(uint redeemAmount) external returns (uint);
    function exchangeRateStore() external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint);
}

interface ICETH{
    function mint() external payable;
}

interface IController {
    function fastForward(uint blocks) external returns (uint);
    function getBlockNumber() external view returns (uint);
}

contract SavingAccount is Initializable, InitializableReentrancyGuard, Constant, InitializablePausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    GlobalConfig public globalConfig;

    event Transfer(address indexed token, address from, address to, uint256 amount);
    event Borrow(address indexed token, address from, uint256 amount);
    event Repay(address indexed token, address from, uint256 amount);
    event Deposit(address indexed token, address from, uint256 amount);
    event Withdraw(address indexed token, address from, uint256 amount);
    event WithdrawAll(address indexed token, address from, uint256 amount);
    event Liquidate(address liquidator, address borrower, address borrowedToken, uint256 repayAmount, address collateralToken, uint256 payAmount);
    event Claim(address from, uint256 amount);

    modifier onlySupportedToken(address _token) {
        if(!Utils._isETH(address(globalConfig), _token)) {
            require(ITokenRegistry(globalConfig.tokenInfoRegistry()).isTokenExist(_token), "Unsupported token");
        }
        _;
    }

    modifier onlyEnabledToken(address _token) {
        require(ITokenRegistry(globalConfig.tokenInfoRegistry()).isTokenEnabled(_token), "The token is not enabled");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.bank()),
            "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    /**
     * Initialize function to be called by the Deployer for the first time
     * @param _tokenAddresses list of token addresses
     * @param _cTokenAddresses list of corresponding cToken addresses
     * @param _globalConfig global configuration contract
     */
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        GlobalConfig _globalConfig
    )
        public
        initializer
    {
        // Initialize InitializableReentrancyGuard
        super._initialize();
        super._initialize(address(_globalConfig));

        globalConfig = _globalConfig;

        require(_tokenAddresses.length == _cTokenAddresses.length, "Token and cToken length don't match.");
        uint tokenNum = _tokenAddresses.length;
        for(uint i = 0;i < tokenNum;i++) {
            if(_cTokenAddresses[i] != address(0x0) && _tokenAddresses[i] != ETH_ADDR) {
                approveAll(_tokenAddresses[i]);
            }
        }
    }

    /**
     * Approve transfer of all available tokens
     * @param _token token address
     */
    function approveAll(address _token) public {
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        require(cToken != address(0x0), "cToken address is zero");
        IERC20(_token).safeApprove(cToken, 0);
        IERC20(_token).safeApprove(cToken, uint256(-1));
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * Transfer the token between users inside DeFiner
     * @param _to the address that the token be transfered to
     * @param _token token address
     * @param _amount amout of tokens transfer
     */
    function transfer(address _to, address _token, uint _amount) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {

        IBank(globalConfig.bank()).newRateIndexCheckpoint(_token);
        uint256 amount = IAccounts(globalConfig.accounts()).withdraw(msg.sender, _token, _amount);
        IAccounts(globalConfig.accounts()).deposit(_to, _token, amount);

        emit Transfer(_token, msg.sender, _to, amount);
    }

    /**
     * Borrow the amount of token from the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     */
    function borrow(address _token, uint256 _amount) external onlySupportedToken(_token) onlyEnabledToken(_token) whenNotPaused nonReentrant {

        require(_amount != 0, "Borrow zero amount of token is not allowed.");

        IBank(globalConfig.bank()).borrow(msg.sender, _token, _amount);

        // Transfer the token on Ethereum
        SavingLib.send(globalConfig, _amount, _token);

        emit Borrow(_token, msg.sender, _amount);
    }

    /**
     * Repay the amount of token back to the saving pool.
     * @param _token token address
     * @param _amount amout of tokens to borrow
     * @dev If the repay amount is larger than the borrowed balance, the extra will be returned.
     */
    function repay(address _token, uint256 _amount) public payable onlySupportedToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.receive(globalConfig, _amount, _token);

        // Add a new checkpoint on the index curve.
        uint256 amount = IBank(globalConfig.bank()).repay(msg.sender, _token, _amount);

        // Send the remain money back
        if(amount < _amount) {
            SavingLib.send(globalConfig, _amount.sub(amount), _token);
        }

        emit Repay(_token, msg.sender, amount);
    }

    /**
     * Deposit the amount of token to the saving pool.
     * @param _token the address of the deposited token
     * @param _amount the mount of the deposited token
     */
    function deposit(address _token, uint256 _amount) public payable onlySupportedToken(_token) onlyEnabledToken(_token) nonReentrant {
        require(_amount != 0, "Amount is zero");
        SavingLib.receive(globalConfig, _amount, _token);
        IBank(globalConfig.bank()).deposit(msg.sender, _token, _amount);

        emit Deposit(_token, msg.sender, _amount);
    }

    /**
     * Withdraw a token from an address
     * @param _token token address
     * @param _amount amount to be withdrawn
     */
    function withdraw(address _token, uint256 _amount) external onlySupportedToken(_token) whenNotPaused nonReentrant {
        require(_amount != 0, "Amount is zero");
        uint256 amount = IBank(globalConfig.bank()).withdraw(msg.sender, _token, _amount);
        SavingLib.send(globalConfig, amount, _token);

        emit Withdraw(_token, msg.sender, amount);
    }

    /**
     * Withdraw all tokens from the saving pool.
     * @param _token the address of the withdrawn token
     */
    function withdrawAll(address _token) external onlySupportedToken(_token) whenNotPaused nonReentrant {

        // Sanity check
        require(IAccounts(globalConfig.accounts()).getDepositPrincipal(msg.sender, _token) > 0, "Token depositPrincipal must be greater than 0");

        // Add a new checkpoint on the index curve.
        IBank(globalConfig.bank()).newRateIndexCheckpoint(_token);

        // Get the total amount of token for the account
        uint amount = IAccounts(globalConfig.accounts()).getDepositBalanceCurrent(_token, msg.sender);

        uint256 actualAmount = IBank(globalConfig.bank()).withdraw(msg.sender, _token, amount);
        if(actualAmount != 0) {
            SavingLib.send(globalConfig, actualAmount, _token);
        }
        emit WithdrawAll(_token, msg.sender, actualAmount);
    }

    function liquidate(address _borrower, address _borrowedToken, address _collateralToken) public onlySupportedToken(_borrowedToken) onlySupportedToken(_collateralToken) whenNotPaused nonReentrant {
        (uint256 repayAmount, uint256 payAmount) = IAccounts(globalConfig.accounts()).liquidate(msg.sender, _borrower, _borrowedToken, _collateralToken);

        emit Liquidate(msg.sender, _borrower, _borrowedToken, repayAmount, _collateralToken, payAmount);
    }

    /**
     * Withdraw token from Compound
     * @param _token token address
     * @param _amount amount of token
     */
    function fromCompound(address _token, uint _amount) external onlyAuthorized {
        require(ICToken(ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token)).redeemUnderlying(_amount) == 0, "redeemUnderlying failed");
    }

    function toCompound(address _token, uint _amount) external onlyAuthorized {
        address cToken = ITokenRegistry(globalConfig.tokenInfoRegistry()).getCToken(_token);
        if (Utils._isETH(address(globalConfig), _token)) {
            ICETH(cToken).mint.value(_amount)();
        } else {
            // uint256 success = ICToken(cToken).mint(_amount);
            require(ICToken(cToken).mint(_amount) == 0, "mint failed");
        }
    }

    function() external payable{}

    /**
     * An account claim all mined FIN token
     */
    function claim() public nonReentrant {
        uint FINAmount = IAccounts(globalConfig.accounts()).claim(msg.sender);
        IERC20(ITokenRegistry(globalConfig.tokenInfoRegistry()).addressFromIndex(11)).safeTransfer(msg.sender, FINAmount);

        emit Claim(msg.sender, FINAmount);
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
    function isTokenExist(address) external view returns (bool);
    function isTokenEnabled(address) external view returns (bool);
    function getCToken(address) external view returns (address);
    function addressFromIndex(uint index) external view returns(address);
}

interface IBank {
    function newRateIndexCheckpoint(address) external;
    function deposit(address _to, address _token, uint256 _amount) external;
    function withdraw(address _from, address _token, uint256 _amount) external returns(uint);
    function borrow(address _from, address _token, uint256 _amount) external;
    function repay(address _to, address _token, uint256 _amount) external returns(uint);
}

interface IAccounts {
    function withdraw(address _accountAddr, address _token, uint256 _amount) external returns (uint256);
    function deposit(address _accountAddr, address _token, uint256 _amount) external;
    function getDepositPrincipal(address _accountAddr, address _token) external view returns(uint256);
    function getDepositBalanceCurrent(address _token, address _accountAddr) external view returns (uint256);
    function liquidate(address _liquidator, address _borrower, address _borrowedToken, address _collateralToken) external returns (uint256, uint256);
    function claim(address _account) external returns(uint256);
}