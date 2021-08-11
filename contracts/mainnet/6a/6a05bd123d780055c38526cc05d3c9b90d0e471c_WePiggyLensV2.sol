/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface PriceOracleInterface {
    function getUnderlyingPrice(address _pToken) external view returns (uint);
}

interface ComptrollerLensInterface {

    function getAllMarkets() external view returns (PTokenLensInterface[] memory);

    function markets(address) external view returns (bool, uint);

    function oracle() external view returns (PriceOracleInterface);

    function getAccountLiquidity(address) external view returns (uint, uint, uint);

    function getAssetsIn(address) external view returns (PTokenLensInterface[] memory);

    function mintCaps(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

interface PTokenLensInterface {

    function interestRateModel() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function comptroller() external view returns (address);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getCash() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function underlying() external view returns (address);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account) external virtual view returns (uint256, uint256, uint256, uint256);
}

interface PiggyDistributionInterface {
    function wpcSpeeds(address) external view returns (uint256);
}

interface InterestRateModelInterface {
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

    function blocksPerYear() external view returns (uint);

    function multiplierPerBlock() external view returns (uint);

    function baseRatePerBlock() external view returns (uint);

    function jumpMultiplierPerBlock() external view returns (uint);

    function kink() external view returns (uint);
}

contract WePiggyLensV2 {

    using SafeMath for uint256;

    ComptrollerLensInterface public comptroller;
    PiggyDistributionInterface public distribution;
    string  public pNativeToken;
    string public nativeToken;
    string public nativeName;
    address public owner;

    constructor(ComptrollerLensInterface _comptroller, PiggyDistributionInterface _distribution,
        string  memory _pNativeToken, string  memory _nativeToken, string memory _nativeName) public {
        comptroller = _comptroller;
        distribution = _distribution;
        pNativeToken = _pNativeToken;
        nativeToken = _nativeToken;
        nativeName = _nativeName;

        owner = msg.sender;
    }

    function updateProperties(ComptrollerLensInterface _comptroller, PiggyDistributionInterface _distribution,
        string  memory _pNativeToken, string  memory _nativeToken, string memory _nativeName) public {

        require(msg.sender == owner, "sender is not owner");

        comptroller = _comptroller;
        distribution = _distribution;
        pNativeToken = _pNativeToken;
        nativeToken = _nativeToken;
        nativeName = _nativeName;
    }

    struct PTokenMetadata {
        address pTokenAddress;
        uint pTokenDecimals;
        address underlyingAddress;
        uint underlyingDecimals;
        string underlyingSymbol;
        string underlyingName;
        uint exchangeRateCurrent;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint collateralFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        uint price;
        uint mintCap;
        uint borrowCap;
        bool isListed;
        uint blockNumber;
        uint accrualBlockNumber;
        uint borrowIndex;
    }

    // 获得市场的属性
    function pTokenMetadata(PTokenLensInterface pToken) public view returns (PTokenMetadata memory){

        (bool isListed, uint collateralFactorMantissa) = comptroller.markets(address(pToken));

        uint mintCap = comptroller.mintCaps(address(pToken));
        uint borrowCap = comptroller.borrowCaps(address(pToken));

        address underlyingAddress;
        uint underlyingDecimals;
        string memory underlyingSymbol;
        string memory underlyingName;
        if (compareStrings(pToken.symbol(), pNativeToken)) {
            underlyingAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
            underlyingDecimals = 18;
            underlyingSymbol = nativeToken;
            underlyingName = nativeName;
        } else {
            PTokenLensInterface pErc20 = PTokenLensInterface(address(pToken));
            underlyingAddress = pErc20.underlying();
            underlyingDecimals = IEIP20(pErc20.underlying()).decimals();
            underlyingSymbol = IEIP20(pErc20.underlying()).symbol();
            underlyingName = IEIP20(pErc20.underlying()).name();
        }

        uint price = PriceOracleInterface(comptroller.oracle()).getUnderlyingPrice(address(pToken));

        return PTokenMetadata({
        pTokenAddress : address(pToken),
        pTokenDecimals : pToken.decimals(),
        underlyingAddress : underlyingAddress,
        underlyingDecimals : underlyingDecimals,
        underlyingSymbol : underlyingSymbol,
        underlyingName : underlyingName,
        exchangeRateCurrent : pToken.exchangeRateStored(),
        supplyRatePerBlock : pToken.supplyRatePerBlock(),
        borrowRatePerBlock : pToken.borrowRatePerBlock(),
        reserveFactorMantissa : pToken.reserveFactorMantissa(),
        collateralFactorMantissa : collateralFactorMantissa,
        totalBorrows : pToken.totalBorrows(),
        totalReserves : pToken.totalReserves(),
        totalSupply : pToken.totalSupply(),
        totalCash : pToken.getCash(),
        price : price,
        mintCap : mintCap,
        borrowCap : borrowCap,
        isListed : isListed,
        blockNumber : block.number,
        accrualBlockNumber : pToken.accrualBlockNumber(),
        borrowIndex : pToken.borrowIndex()
        });

    }

    function pTokenMetadataAll(PTokenLensInterface[] memory pTokens) public view returns (PTokenMetadata[] memory) {
        uint pTokenCount = pTokens.length;
        PTokenMetadata[] memory res = new PTokenMetadata[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = pTokenMetadata(pTokens[i]);
        }
        return res;
    }

    struct PTokenBalances {
        address pToken;
        uint balance;
        uint borrowBalance; //用户的借款
        uint exchangeRateMantissa;
    }

    // 获得用户的市场金额
    function pTokenBalances(PTokenLensInterface pToken, address payable account) public view returns (PTokenBalances memory) {

        (, uint tokenBalance, uint borrowBalance, uint exchangeRateMantissa) = pToken.getAccountSnapshot(account);

        return PTokenBalances({
        pToken : address(pToken),
        balance : tokenBalance,
        borrowBalance : borrowBalance,
        exchangeRateMantissa : exchangeRateMantissa
        });

    }

    // 获得用户有每个市场的金额(抵押、借贷)
    function pTokenBalancesAll(PTokenLensInterface[] memory pTokens, address payable account) public view returns (PTokenBalances[] memory) {
        uint pTokenCount = pTokens.length;
        PTokenBalances[] memory res = new PTokenBalances[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = pTokenBalances(pTokens[i], account);
        }
        return res;
    }

    struct AccountLimits {
        PTokenLensInterface[] markets;
        uint liquidity;
        uint shortfall;
    }


    // 获得用户有哪些市场、流动性
    function getAccountLimits(address payable account) public view returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({
        markets : comptroller.getAssetsIn(account),
        liquidity : liquidity,
        shortfall : shortfall
        });
    }

    struct PTokenWpcSpeed {
        PTokenLensInterface market;
        uint wpcSpeed;
    }

    function getWpcSpeed(PTokenLensInterface pToken) public view returns (PTokenWpcSpeed memory){
        uint wpcSpeed = distribution.wpcSpeeds(address(pToken));
        return PTokenWpcSpeed({
        market : pToken,
        wpcSpeed : wpcSpeed
        });
    }

    function getWpcSpeeds(PTokenLensInterface[] memory pTokens) public view returns (PTokenWpcSpeed[] memory){
        uint pTokenCount = pTokens.length;
        PTokenWpcSpeed[] memory res = new PTokenWpcSpeed[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = getWpcSpeed(pTokens[i]);
        }
        return res;
    }


    struct InterestRateModel {
        PTokenLensInterface market;
        uint blocksPerYear;
        uint multiplierPerBlock;
        uint baseRatePerBlock;
        uint jumpMultiplierPerBlock;
        uint kink;
    }

    function getInterestRateModel(PTokenLensInterface pToken) public view returns (InterestRateModel memory){
        InterestRateModelInterface interestRateModel = InterestRateModelInterface(pToken.interestRateModel());

        return InterestRateModel({
        market : pToken,
        blocksPerYear : interestRateModel.blocksPerYear(),
        multiplierPerBlock : interestRateModel.multiplierPerBlock(),
        baseRatePerBlock : interestRateModel.baseRatePerBlock(),
        jumpMultiplierPerBlock : interestRateModel.jumpMultiplierPerBlock(),
        kink : interestRateModel.kink()
        });
    }

    function getInterestRateModels(PTokenLensInterface[] memory pTokens) public view returns (InterestRateModel[] memory){
        uint pTokenCount = pTokens.length;
        InterestRateModel[] memory res = new InterestRateModel[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = getInterestRateModel(pTokens[i]);
        }
        return res;
    }


    function all() external view returns (PTokenMetadata[] memory, InterestRateModel[] memory, PTokenWpcSpeed[] memory){

        PTokenLensInterface[] memory pTokens = comptroller.getAllMarkets();
        PTokenMetadata[] memory metaData = pTokenMetadataAll(pTokens);
        InterestRateModel[] memory rateModels = getInterestRateModels(pTokens);
        PTokenWpcSpeed[] memory wpcSpeeds = getWpcSpeeds(pTokens);

        return (metaData, rateModels, wpcSpeeds);
    }


    function allForAccount(address payable account) external view returns (AccountLimits memory, PTokenBalances[] memory, PTokenMetadata[] memory, InterestRateModel[] memory){

        AccountLimits memory accountLimits = getAccountLimits(account);

        PTokenLensInterface[] memory pTokens = comptroller.getAllMarkets();
        PTokenBalances[] memory balances = pTokenBalancesAll(pTokens, account);
        PTokenMetadata[] memory metaData = pTokenMetadataAll(pTokens);
        InterestRateModel[] memory rateModels = getInterestRateModels(pTokens);

        return (accountLimits, balances, metaData, rateModels);
    }


    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}