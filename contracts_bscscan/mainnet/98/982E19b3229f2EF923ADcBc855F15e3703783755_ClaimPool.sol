/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface IIns3ProductToken{
    function totalSellQuantity() external view returns(uint256);
    function paid() external view returns(uint256);
    function expireTimestamp() external view returns(uint256);
    function closureTimestamp() external view returns(uint256);
    function totalPremiums() external view returns(uint256);
    function needPay() external view returns(bool);
    function isValid() external view returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(address account, uint256 amount) external;
    function calcDistributePremiums() external view returns(uint256,uint256);
    function approvePaid() external;
    function rejectPaid() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface IStakingPool 
{
    function putTokenHolder(uint256 tokenId,uint256 amount,uint256 timestamp) external;
    function calcPremiumsRewards(uint256 stakingAmount, uint256 timestamp) external view returns(uint256);
    function isClosed() external view returns(bool);
    function isNormalClosed() external view returns(bool);

    function totalStakingAmount() external view returns(uint256); 

    function totalNeedPayFromStaking() external view returns(uint256); 

    function totalRealPayFromStaking() external view returns(uint256) ; 

    function payAmount() external view returns(uint256); 

    function productTokenRemainingAmount() external view returns(uint256);
    function productTokenExpireTimestamp() external view returns(uint256);
    function calculateCapacity() external view returns(uint256);
    function takeTokenHolder(uint256 tokenId) external;
    function productToken() external view returns(IIns3ProductToken);
    function queryAndCheckClaimAmount(address userAccount) view external returns(uint256,uint256/*token balance*/);
}

interface IClaimPool is IStakingPool
{
    function tokenAddress() external view returns(address);
    function aTokenAddress() external view returns(address);
    function returnRemainingAToken(address account) external;
    function getAToken(uint256 userPayAmount, address account) external;
    function needPayFlag() external view returns(bool); 
    function totalClaimProductQuantity() external view returns(uint256);

    function stakingWeight() external view returns(uint256);
    function stakingLeverageWeight() external view returns(uint256);
}

interface IStakingPoolToken{
    function putTokenHolderInPool(uint256 tokenId,uint256 amount) external;
    function getTokenHolderAmount(uint256 tokenId,address poolAddr) view external returns(uint256);
    function getTokenHolder(uint256 tokenId) view external returns(uint256,uint256,uint256,uint256,address [] memory);
    function coinHolderRemainingPrincipal(uint256 tokenId) view external returns(uint256);
    function bookkeepingFromPool(uint256 amount) external;
    function isTokenExist(uint256 tokenId) view external returns(bool);
}

// File: contracts\@openzeppelin\GSN\Context.sol


pragma solidity ^0.6.0;

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

// File: contracts\@openzeppelin\access\Ownable.sol



pragma solidity ^0.6.0;

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

    function isOwner(address addr) public view returns(bool){
        return _owner == addr;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\ISponsorWhiteListControl.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity ^0.6.0;

interface ISponsorWhiteListControl {
    function getSponsorForGas(address contractAddr) external view returns (address);
    function getSponsoredBalanceForGas(address contractAddr) external view returns (uint) ;
    function getSponsoredGasFeeUpperBound(address contractAddr) external view returns (uint) ;
    function getSponsorForCollateral(address contractAddr) external view returns (address) ;
    function getSponsoredBalanceForCollateral(address contractAddr) external view returns (uint) ;
    function isWhitelisted(address contractAddr, address user) external view returns (bool) ;
    function isAllWhitelisted(address contractAddr) external view returns (bool) ;
    function addPrivilegeByAdmin(address contractAddr, address[] memory addresses) external ;
    function removePrivilegeByAdmin(address contractAddr, address[] memory addresses) external ;
    function setSponsorForGas(address contractAddr, uint upperBound) external payable ;
    function setSponsorForCollateral(address contractAddr) external payable ;
    function addPrivilege(address[] memory) external ;
    function removePrivilege(address[] memory) external ;
}

// File: contracts\@openzeppelin\math\SafeMath.sol



pragma solidity ^0.6.0;

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

// File: contracts\PriceMetaInfoDB.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;





contract PriceMetaInfoDB is Ownable 
{
    using SafeMath for uint256;    
    mapping(uint256=>address) _channels;
    
    uint256 public CHANNEL_PREMIUMS_PERCENT; 

    uint256 public FLASHLOAN_PREMIUMS_PERCENT; 

    uint256 public FLASHLOAN_PREMIUMS_DIVISOR; 

    address public PRICE_NODE_PUBLIC_KEY; 

    uint256 public TOTAL_ITF_AMOUNT ;

    uint256 public STAKING_MINT_PERCENT; 

    uint256 public PREMIUMS_SHARE_PERCENT; 

    uint256 public PRODUCT_WITHDRAW_PERCENT; 

    uint256 public ORACLE_PAYOUT_RATE; 

    uint256 public ORACLE_STAGE_NUM; 

    uint256 public ORACLE_NUM; 

    uint256 public ORACLE_SCHEDULE_MULTIPLIER; 

    uint256 public ORACLE_VALID_PERIOD; 

    uint256 public ITFAPY; 
    
    address[4] private _itfReleaseAccountArray;
    uint256[4] private _itfReleaseAccountMultiplierArray;
    uint256 private _itfReleaseDivisor;

    uint256 _lastBlockNumber;
    uint256 _lastBlockTimestamp;
    uint256 public blockTime  ; 

    function currentTimestamp() view public returns(uint256){
        return (block.number-_lastBlockNumber).mul(blockTime).div(1000).add(_lastBlockTimestamp);
    }

    uint256 public STAKING_TOKEN_MARGIN; 

    constructor(uint256 totalITFAmount, uint256 stakingMintPercent, 
                uint256 oraclePayoutRate,uint256 oracleStageNum,uint256 oracleNum,uint256 oracleScheduleMultiplier,
                uint256 premiumsSharePercent, 
                address[4] memory itfReleaseAccounts, 
                uint256[4] memory itfReleaseAccountMultipliers, 
                uint256 itfReleaseDivisor,
                uint256 channelPremiumsPercent,
                uint256 oracleValidPeriod,
                address priceNodePublicKey,
                uint256 flashLoanPremiumsPercent,
                uint256 flashLoanPremiumsDivisor,
                uint256 blockTime_
                ) public{
        require(blockTime_>0,"block time must be >0");

        TOTAL_ITF_AMOUNT=totalITFAmount;
        STAKING_MINT_PERCENT = stakingMintPercent;
        ORACLE_PAYOUT_RATE = oraclePayoutRate;
        ORACLE_STAGE_NUM = oracleStageNum;
        ORACLE_NUM = oracleNum;
        ORACLE_SCHEDULE_MULTIPLIER = oracleScheduleMultiplier;
        PREMIUMS_SHARE_PERCENT = premiumsSharePercent;
        ORACLE_VALID_PERIOD = oracleValidPeriod;
        setITFReleaseAccounts(itfReleaseAccounts,itfReleaseAccountMultipliers,itfReleaseDivisor);
        PRICE_NODE_PUBLIC_KEY = priceNodePublicKey;
        CHANNEL_PREMIUMS_PERCENT=channelPremiumsPercent;
        FLASHLOAN_PREMIUMS_PERCENT = flashLoanPremiumsPercent;
        FLASHLOAN_PREMIUMS_DIVISOR = flashLoanPremiumsDivisor;

        ITFAPY = 200;
        PRODUCT_WITHDRAW_PERCENT = 300;
        _lastBlockNumber=block.number;
        _lastBlockTimestamp=block.timestamp;
        blockTime = blockTime_;

        STAKING_TOKEN_MARGIN=10;
    }

    function refreshBlockTime() public {
        _lastBlockNumber=block.number;
        _lastBlockTimestamp=block.timestamp;
    }

    function setBlockTime(uint256 blockTime_) public onlyOwner {
        if (blockTime_!=blockTime){
            require(blockTime_>0,"block time must be >0");
            blockTime = blockTime_;
        }
        refreshBlockTime();
    }

    function seStakingTokenMargin(uint256 margin) public onlyOwner{
        STAKING_TOKEN_MARGIN=margin;
    }

    function hasCoverChannel(uint256 id) view public returns(bool){
        return _channels[id]!=address(0);
    } 

    function getCoverChannelAddress(uint256 id) view public returns(address){
        return _channels[id];
    }

    function registerCoverChannel(uint256 id,address receiverAccount) public onlyOwner{
        require(!hasCoverChannel(id),"The id exists");
        _channels[id]=receiverAccount;
    }

    function unregisterCoverChannel(uint256 id) public onlyOwner{
        require(hasCoverChannel(id),"The id does not exists");
        delete _channels[id];
    }

    function setChannelPremiumsPercent(uint256 channelPremiumsPercent) public onlyOwner {
        CHANNEL_PREMIUMS_PERCENT = channelPremiumsPercent;
    }

    function setFlashLoanPremiumsPercent(uint256 flashLoanPremiumsPercent) public onlyOwner {
        FLASHLOAN_PREMIUMS_PERCENT = flashLoanPremiumsPercent;
    }

    function setStakingMintPercent(uint256 stakingMintPercent) public onlyOwner {
        STAKING_MINT_PERCENT = stakingMintPercent;
    }

    function setOraclePayoutRate(uint256 oraclePayoutRate) public onlyOwner {
        ORACLE_PAYOUT_RATE = oraclePayoutRate;
    }

    function setOracleNum(uint256 oracleNum) public onlyOwner {
        ORACLE_NUM = oracleNum;
    }

    function setOracleStageNum(uint256 oracleStageNum) public onlyOwner {
        ORACLE_STAGE_NUM = oracleStageNum;
    }

    function setOracleScheduleMultiplier(uint256 oracleScheduleMultiplier) public onlyOwner {
        ORACLE_SCHEDULE_MULTIPLIER = oracleScheduleMultiplier;
    }



    function setOracleValidPeriod(uint256 oracleValidPeriod) public onlyOwner {
        ORACLE_VALID_PERIOD = oracleValidPeriod;
    }

    function setITFAPY(uint256 itfApy) public onlyOwner {
        require(itfApy < 1000,"invalid itf APY");
        ITFAPY = itfApy;
    }

    function setPremiumsSharePercent(uint256 premiumsSharePercent) public onlyOwner {
        require(premiumsSharePercent < 1000,"invalid premiums share percent");
        PREMIUMS_SHARE_PERCENT = premiumsSharePercent;
    }

    function setProductWithdrawPercent(uint256 productWithdrawPercent) public onlyOwner {
        require(productWithdrawPercent < 1000,"invalid product withdraw percent");
        PRODUCT_WITHDRAW_PERCENT = productWithdrawPercent;
    }

    function setITFReleaseAccounts(address[4] memory itfReleaseAccounts, uint256[4] memory itfReleaseAccountMultipliers, uint256 itfReleaseDivisor) public onlyOwner {
        _itfReleaseAccountArray = itfReleaseAccounts;
        _itfReleaseAccountMultiplierArray = itfReleaseAccountMultipliers;
        _itfReleaseDivisor = itfReleaseDivisor;
    }

    function getITFReleaseAccountArray() public view returns(address[4] memory) {
        return _itfReleaseAccountArray;
    }

    function getITFReleaseAccountMultiplierArray() public view returns(uint256[4] memory) {
        return _itfReleaseAccountMultiplierArray;
    }

    function getITFReleaseDivisor() public view returns(uint256) {
        return _itfReleaseDivisor;
    }

    function setPriceNodePublicKey(address priceNodePublicKey) public onlyOwner {
        PRICE_NODE_PUBLIC_KEY = priceNodePublicKey;
    }

    function verifySign(bytes32 messageHash, address publicKey, uint256 expiresAt, uint8 v, bytes32 r, bytes32 s) public view returns(bool){
		require(expiresAt > now, "time expired");
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address addr = ecrecover(prefixedHash, v, r, s);
        if(addr!=publicKey){
            prefixedHash = keccak256(abi.encodePacked("\x19Conflux Signed Message:\n32", messageHash));
            addr = ecrecover(prefixedHash, v, r, s);
        }
        return (addr==publicKey);
    }

    function initSponsor() external { 
        ISponsorWhiteListControl SPONSOR = ISponsorWhiteListControl(address(0x0888000000000000000000000000000000000001));
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }

}

// File: contracts\@openzeppelin\utils\Address.sol



pragma solidity ^0.6.2;

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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts\ProxyOwnable.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;




abstract contract ProxyOwnable is Context{
    using Address for address;

    Ownable _ownable;
    Ownable _adminable;

    constructor() public{
        
    }

    function setOwnable(address ownable) internal{ 
        require(ownable!=address(0),"setOwnable should not be 0");
        _ownable=Ownable(ownable);
        if (address(_adminable)==address(0)){
            require(!address(_adminable).isContract(),"admin should not be contract");
            _adminable=Ownable(ownable);
        }
    }

    function setAdminable(address adminable) internal{
        require(adminable!=address(0),"setOwnable should not be 0");
        _adminable=Ownable(adminable);
    }
    modifier onlyOwner {
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        require(_ownable.isOwner(_msgSender()),"Not owner");
        _;
    }

    modifier onlyAdmin {
        require(address(_adminable)!=address(0),"proxy adminable should not be 0");
        require(_adminable.isOwner(_msgSender()),"Not admin");
        _;
    }

    function admin() view public returns(address){
        require(address(_adminable)!=address(0),"proxy admin should not be 0");
        return _adminable.owner();
    }

    function owner() view external returns(address){
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        return _ownable.owner();
    }

    function getOwner() view external returns(address){
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        return _ownable.owner();
    }

    function isOwner(address addr) public view returns(bool){
        require(address(_ownable)!=address(0),"proxy ownable should not be 0");
        return _ownable.isOwner(addr);
    }

}

// File: contracts\Ins3Pausable.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity ^0.6.0;



contract Ins3Pausable is  ProxyOwnable{
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function initSponsor() public{ 
        ISponsorWhiteListControl SPONSOR = ISponsorWhiteListControl(address(0x0888000000000000000000000000000000000001));
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }
}

// File: contracts\Ins3Register.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;


contract Ins3Register is Ins3Pausable 
{
    mapping(bytes8=>address) _contracts;

    bytes8 [] _allContractNames;
    uint256 public count;
    constructor(address ownable) Ins3Pausable() public{
        setOwnable(ownable);
    }

    function contractNames() view public returns( bytes8[] memory){
        bytes8 [] memory names=new bytes8[](count);
        uint256 j=0;
        for (uint256 i=0;i<_allContractNames.length;++i){
            bytes8 name=_allContractNames[i];
            if (_contracts[name]!=address(0)){
                names[j]=name;
                j+=1;  
            }
        }
        return names;
    }

    function registerContract(bytes8 name, address contractAddr) onlyOwner public{
        require(_contracts[name]==address(0),"This name contract already exists"); 
        _contracts[name]=contractAddr;
        _allContractNames.push(name);
        count +=1;
    }

    function unregisterContract(bytes8 name) onlyOwner public {
        require(_contracts[name]!=address(0),"This name contract not exists"); 
        delete _contracts[name];
        count -=1;
    }

    function hasContract(bytes8 name) view public returns(bool){
        return _contracts[name]!=address(0);
    }

    function getContract(bytes8 name) view public returns(address){
        return _contracts[name];
    }


}

// File: contracts\IUpgradable.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;



abstract contract IUpgradable is Ins3Pausable{

    Ins3Register public register;
    address public registerAddress;


    function  updateDependentContractAddress() public virtual;  

    function updateRegisterAddress(address registerAddr) external {
        if (address(register) != address(0)) {
            require(register.isOwner(_msgSender()), "Just the register's owner can call the updateRegisterAddress()"); 
        }
        register = Ins3Register(registerAddr);
        setOwnable(registerAddr);
        registerAddress=registerAddr;
        updateDependentContractAddress();
    }

}

// File: contracts\@openzeppelin\math\Math.sol



pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    //rand() - added on 2020/09/07
    function rand(uint256 number) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        return random%number;
    }
}

// File: contracts\@openzeppelin\utils\ReentrancyGuard.sol



pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts\@openzeppelin\token\ERC20\IERC20.sol



pragma solidity ^0.6.0;

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

// File: contracts\@openzeppelin\token\ERC20\SafeERC20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\IUSDT.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Interface of the USDT standard as defined in the EIP.
 */
interface IUSDT {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external ;


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
    function approve(address spender, uint256 amount) external ;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external ;

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

// File: contracts\CompatibleERC20.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;





interface IERC20Full is IERC20
{
    function decimals() external view returns (uint8);
}

library CompatibleERC20  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function decimalsERC20(address token) internal view returns (uint256){
        if (token==USDT_ADDRESS){
            return IUSDT(token).decimals();
        }else{
            return uint256(IERC20Full(token).decimals());
        }
    }

    function getDiffDecimals(address token) internal view returns(uint256){
        uint256 dec=decimalsERC20(token);
        require(dec<=18,"token's decimals must <=18");
        return 10**(18-dec);
    }

    function getCleanAmount(address token,uint256 amount) internal view returns (uint256){
        uint256 dec=getDiffDecimals(token);
        return amount.div(dec).mul(dec);
    }

    function balanceOfERC20(address token,address addr) internal view returns(uint256){
        uint256 dec=getDiffDecimals(token);
        if (token==USDT_ADDRESS){
            return IUSDT(token).balanceOf(addr).mul(dec);
        }else{
            return IERC20(token).balanceOf(addr).mul(dec);
        }
    }

    function transferERC20(address token,address recipient, uint256 amount) internal{
        uint256 dec=getDiffDecimals(token);
        if (token==USDT_ADDRESS){
            IUSDT(token).transfer(recipient,amount.div(dec));  
        }else{
            IERC20(token).safeTransfer(recipient,amount.div(dec));
        }
    }

    function allowanceERC20(address token,address account,address spender) view internal returns(uint256){
        uint256 dec=getDiffDecimals(token);
        if (token==USDT_ADDRESS){
            return IUSDT(token).allowance(account,spender).mul(dec);
        }else{
            return IERC20(token).allowance(account,spender).mul(dec);
        }
    }
    
    function approveERC20(address token,address spender, uint256 amount) internal {
        uint256 dec=getDiffDecimals(token);
        if (token==USDT_ADDRESS){
            IUSDT(token).approve(spender,amount.div(dec));
        }else{
            IERC20(token).safeApprove(spender,amount.div(dec));
        }
    }

    function transferFromERC20(address token,address sender, address recipient, uint256 amount) internal {
        uint256 dec=getDiffDecimals(token);
        if (token==USDT_ADDRESS){
            IUSDT(token).transferFrom(sender,recipient,amount.div(dec));
        }else{
            IERC20(token).safeTransferFrom(sender,recipient,amount.div(dec));
        }
    }
}

// File: contracts\ClaimPool.sol

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;








contract StakingPoolV2 is IClaimPool, IUpgradable, ReentrancyGuard
{
    using SafeMath for uint256;
    using CompatibleERC20 for address;
    address public override tokenAddress;

    address public override aTokenAddress;

    uint256 [] public tokenHolderIds;  


    mapping(uint256/*tokenId*/=>uint256) _timestamps; 
    IStakingPoolToken public stakingPoolToken;
    IIns3ProductToken public override productToken;

    uint256 public stakingAmountLimit; 

    uint256 public minStakingAmount; 

	uint256 public capacityLimitPercent; 

    uint256 private _totalStakingAmount; 

    uint256 public _totalStakingTimeAmount; 


    uint256 private _totalNeedPayFromStaking; 

    uint256 private _totalRealPayFromStaking; 

    uint256 private _payAmount; 
    bool public _isClosed;

    bool public override needPayFlag;
    bool public claimEnable; 

    uint256 _totalPremiumsAfterClose;

    uint256 public override stakingWeight;

    uint256 public override stakingLeverageWeight;

    constructor(uint256 stakingAmountLimit_, uint256 minStakingAmount_, uint256 capacityLimitPercent_, address tokenAddress_) public{
        stakingAmountLimit = stakingAmountLimit_;
        minStakingAmount = minStakingAmount_;
        capacityLimitPercent = capacityLimitPercent_;

        tokenAddress = tokenAddress_;

        stakingWeight=10000;
        stakingLeverageWeight=10000;
    }

    function setStakingAmountLimit(uint256 stakingAmountLimit_) onlyOwner public{
        require(stakingAmountLimit_ > _totalStakingAmount);
        stakingAmountLimit=stakingAmountLimit_;
    }

    function setStakingWeight(uint256 stakingWeight_) onlyOwner public{
        stakingWeight=stakingWeight_;
    }

    function setStakingLeverageWeight(uint256 stakingLeverageWeight_) onlyOwner public {
        stakingLeverageWeight=stakingLeverageWeight_;
    }

    function setNeedPayFlag(bool needPay) onlyOwner public{
        require(!_isClosed,"can not set flag");
        needPayFlag =  needPay;
    }

    function startTime() view public returns(uint256){
        return productToken.closureTimestamp();
    }

    function executeTime() view public returns(uint256){
        return productToken.expireTimestamp();
    }

    function totalClaimProductQuantity() view public virtual override returns(uint256){
        return productToken.totalSellQuantity();
    }

    function calculateCapacity() view public override returns(uint256) {
        uint256 activeCovers = productToken.totalSellQuantity().mul(productToken.paid());
        uint256 maxMCRCapacity = _totalStakingAmount.mul(capacityLimitPercent).div(1000);
        uint256 maxCapacity = maxMCRCapacity < stakingAmountLimit ? maxMCRCapacity : stakingAmountLimit;
        uint256 availableCapacity = activeCovers >= maxCapacity ? 0 : maxCapacity.sub(activeCovers);
        return availableCapacity;
    }

    function productTokenRemainingAmount() view public override returns(uint256){ 
        require(address(productToken)!=address(0),"The productToken should not be 0");
        return calculateCapacity();
    }

    function tokenHolderIdLength() view public returns(uint256){
        return tokenHolderIds.length;
    }

    function productTokenExpireTimestamp() view public override returns(uint256){
        require(address(productToken)!=address(0),"The productToken should not be 0");
        return productToken.expireTimestamp();
    }

    function setProductToken(address productTokenAddress) onlyOwner public returns(bool){
		require(address(productToken) == address(0),"The setProductToken() can only be called once");
		productToken = IIns3ProductToken(productTokenAddress);
		return true;
	}

    modifier onlyPoolToken(){
        require(address(stakingPoolToken)==address(_msgSender()));
        _;
    }

    function putTokenHolder(uint256 tokenId,uint256 amount,uint256 timestamp) onlyPoolToken public override {
        require(amount>=minStakingAmount,"amount should > minStakingAmount");
        require(remainingStakingAmount()>=amount,"putTokenHolder - remainingStakingAmount not enough");
        require(_timestamps[tokenId]==0,"putTokenHolder - The tokenId already exists");
        require(timestamp<productToken.closureTimestamp(),"Clouser period, can not staking");
        _totalStakingAmount = _totalStakingAmount.add(amount);
        uint256 period = productToken.expireTimestamp().sub(timestamp);
        _totalStakingTimeAmount = _totalStakingTimeAmount.add(amount.mul(period).mul(period));
        tokenHolderIds.push(tokenId);
        _timestamps[tokenId]=timestamp;

    }

    function takeTokenHolder(uint256 tokenId) onlyPoolToken public override{ 
        require(!_isClosed,"pool has colsed");
        require(_timestamps[tokenId]!=0,"The tokenId does not exist");
        uint256 amount=stakingPoolToken.getTokenHolderAmount(tokenId,address(this));
        uint256 period = productToken.expireTimestamp().sub(_timestamps[tokenId]);
        delete _timestamps[tokenId];
        _totalStakingAmount = _totalStakingAmount.sub(amount);
        _totalStakingTimeAmount = _totalStakingTimeAmount.sub(amount.mul(period).mul(period));
    }

    function remainingStakingAmount() view public returns(uint256){
        return stakingAmountLimit.sub(_totalStakingAmount);
    }

    function updateDependentContractAddress() public override{
        stakingPoolToken=IStakingPoolToken(register.getContract("SKPT"));
        require(address(stakingPoolToken)!=address(0),"updateDependentContractAddress - staking pool token does not init");
    }

    function calcPremiumsRewards(uint256 stakingAmount, uint256 beginTimestamp) view public override returns(uint256){
        (, uint256 toPoolTokenPremiums) = productToken.calcDistributePremiums();
        uint256 timePeriod = productToken.expireTimestamp().sub(beginTimestamp);
        if (_totalStakingTimeAmount == 0) {
            return 0;
        }
        return toPoolTokenPremiums.mul(stakingAmount).mul(timePeriod).mul(timePeriod).div(_totalStakingTimeAmount); 
    }

    function isClosed() view public override returns(bool){
        return _isClosed;
    }

    function isNormalClosed() view public override returns(bool){
        return _isClosed && !productToken.needPay();
    }

    function totalStakingAmount() view public override returns(uint256){
        return _totalStakingAmount;
    }

    function totalNeedPayFromStaking() view public override returns(uint256){
        return _totalNeedPayFromStaking;
    }

    function totalRealPayFromStaking() view public override returns(uint256){
        return _totalRealPayFromStaking;
    }

    function payAmount() view public override returns(uint256){
        return _payAmount;
    }

    function canStake() view public returns(bool){
        return now<productToken.closureTimestamp(); 
    }


    function close(bool needPay, uint256 totalRealPayFromStakingToken) public onlyOwner {
        require(!_isClosed,"Staking pool has been closed");
        _isClosed = true;
        if(needPay){
            require(needPayFlag,"flag error");
            productToken.approvePaid();
        }else{
            require(!needPayFlag,"flag error");
            productToken.rejectPaid();
        }
        uint256 totalSellQuantity = totalClaimProductQuantity();

        if(needPay && totalSellQuantity>0) { 
            uint256 totalPaidAmount = totalSellQuantity.mul(productToken.paid());

            uint256 totalPremiums = tokenAddress.balanceOfERC20(address(this));

            uint256 totalNeedPayAmount = totalPaidAmount.sub(totalPremiums);
            require(totalRealPayFromStakingToken <= totalNeedPayAmount,"please check pay amount");

            _totalNeedPayFromStaking = totalNeedPayAmount;
            _totalRealPayFromStaking = totalRealPayFromStakingToken;
            
            if(_totalRealPayFromStaking>0){
                tokenAddress.transferERC20(address(stakingPoolToken),totalPremiums);
                
                _totalPremiumsAfterClose=totalPremiums;
                stakingPoolToken.bookkeepingFromPool(_totalRealPayFromStaking.add(_totalPremiumsAfterClose));
            }

            updatePayAmount();

        }
    }


    function calcPayAmount(uint256 tokenId, address poolAddr) view public returns(uint256) {
        (,,,,address [] memory poolAddrs) = stakingPoolToken.getTokenHolder(tokenId);
        uint256 totalPayAmount = 0;
        uint256 poolPayAmount = 0;
        for (uint256 i=0;i<poolAddrs.length;++i) {
            IClaimPool pool=IClaimPool(poolAddrs[i]);
            if(pool.needPayFlag()) {
                uint256 totalPaidAmount = pool.totalClaimProductQuantity().mul(pool.productToken().paid());
                uint256 totalNeedPayAmount = totalPaidAmount.sub(pool.productToken().totalPremiums());
                uint256 stakingAmount = stakingPoolToken.getTokenHolderAmount(tokenId, poolAddrs[i]);
                uint256 userPayAmount = stakingAmount.mul(totalNeedPayAmount).div(pool.totalStakingAmount());
                totalPayAmount = totalPayAmount.add(userPayAmount);
                if(poolAddrs[i]==poolAddr){
                    poolPayAmount = userPayAmount;
                }
            }
        }
        if(totalPayAmount==0){
            return 0;
        } else{
            uint256 stakingAmount = stakingPoolToken.getTokenHolderAmount(tokenId, poolAddr);
            uint256 poolPayAmount2 = poolPayAmount.mul(stakingAmount).div(totalPayAmount);
            return Math.min(poolPayAmount2, poolPayAmount);
        }
    }

    function calcPayAmountFromStaking(uint256 beginIndex, uint256 endIndex) public view returns(uint256){
        require(needPayFlag,"pay flag error");
        require(beginIndex <= endIndex,"index error");
        require(endIndex < tokenHolderIds.length,"end index out of range");
        uint256 totalRealPayAmount = 0;

        for(uint256 i=beginIndex; i <= endIndex; ++i) {
            uint256 tokenId=tokenHolderIds[i];
            if (!stakingPoolToken.isTokenExist(tokenId)){
                continue;
            }
            uint256 userRealPayAmount = calcPayAmount(tokenId, address(this));
            if(userRealPayAmount>0){
                totalRealPayAmount = totalRealPayAmount.add(userRealPayAmount);
            }
        }
        return totalRealPayAmount;
    }

    function updatePayAmount() public onlyOwner {
        require(_isClosed,"Pool must be closed");
        require(!claimEnable,"claim already enable");
        uint256 totalAmount = tokenAddress.balanceOfERC20(address(this));
        uint256 totalSellQuantity = totalClaimProductQuantity();
        if(totalSellQuantity>0) {
            _payAmount = totalAmount.add(_totalRealPayFromStaking).add(_totalPremiumsAfterClose).div(totalSellQuantity);
        }else {
            _payAmount = 0;
        }

        if (totalAmount>0){
            _totalPremiumsAfterClose=_totalPremiumsAfterClose.add(totalAmount);
            tokenAddress.transferERC20(address(stakingPoolToken),totalAmount);
            stakingPoolToken.bookkeepingFromPool(totalAmount);
        }
    }

    function setClaimEnable() public onlyOwner{
        require(_isClosed,"Pool must be closed");
        claimEnable = true;
    }

    function queryAndCheckClaimAmount(address userAccount) view external virtual override returns(uint256,uint256/*token balance*/){
        require(claimEnable,"claim not enable");
        require(payAmount()>0,"no money for claim");
        uint256 productTokenQuantity = productToken.balanceOf(userAccount);
        return (productTokenQuantity.mul(payAmount()),productTokenQuantity);
    }

    function returnRemainingAToken(address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        
    }

    function getAToken(uint256 userPayAmount, address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        
    }
}

contract ClaimPool is StakingPoolV2
{
    mapping(address => uint256) public userClaimMap;

    uint256 private _totalClaimProductQuantity;

    uint256 public claimRate;


    uint256 public aTokenRate;

    constructor(uint256 stakingAmountLimit_, uint256 minStakingAmount_, uint256 capacityLimitPercent_, 
                uint256 claimRate_, uint256 aTokenRate_, address tokenAddress_, 
                address aTokenAddress_) StakingPoolV2(stakingAmountLimit_, minStakingAmount_, capacityLimitPercent_, tokenAddress_) public{
        claimRate = claimRate_;
        aTokenRate = aTokenRate_;
        aTokenAddress = aTokenAddress_;
    }

    function totalClaimProductQuantity() view public virtual override returns(uint256){
        return _totalClaimProductQuantity;
    }

    function queryAndCheckClaimAmount(address userAccount) view external virtual override returns(uint256,uint256/*token balance*/){
        require(claimEnable,"claim not enable");
        require(payAmount()>0,"no money for claim");
        uint256 productTokenQuantity = userClaimMap[userAccount];
        return (productTokenQuantity.mul(payAmount()),productTokenQuantity);
    }

    function setClaimRate(uint256 claimRate_) onlyOwner public{
        require(claimRate_>0 && claimRate_<=100,"claim rate error");
        require(now < startTime(),"can not set rate");
        claimRate = claimRate_;
	}

    function setATokenRate(uint256 aTokenRate_) onlyOwner public{
        require(now < startTime(),"can not set rate");
        aTokenRate =  aTokenRate_;
    }

    function claimStandardReached() view public returns(bool) {
        return _totalClaimProductQuantity.mul(100).div(productToken.totalSellQuantity())>=claimRate;
    }

    function redeemFromClaim() nonReentrant whenNotPaused external {
        require(!needPayFlag,"can not redeemFromClaim");
        require(!_isClosed || !productToken.needPay(),"can not redeemFromClaim");

        uint256 productQuantity = userClaimMap[_msgSender()];
        if(productQuantity > 0) {
            uint256 aTokenAmount = calcATokenAmount(productQuantity.mul(productToken.paid())); //TODO
            aTokenAddress.transferERC20(_msgSender(), aTokenAmount);
            productToken.transfer(_msgSender(), productQuantity);
            _totalClaimProductQuantity = _totalClaimProductQuantity.sub(productQuantity);
            userClaimMap[_msgSender()] = 0;
        }
    }

    function calcATokenAmount(uint256 totalPaidAmount) view public returns(uint256) {
        return totalPaidAmount.mul(aTokenRate).div(1e18);
    }

    function pledgeForClaim(uint256 productQuantity, uint256 aTokenAmount) nonReentrant whenNotPaused external {
        require(!_isClosed,"Staking pool has been closed");
        require(now >= startTime(),"It hasn't started");
        require(now < executeTime(),"can not pledge");

        uint256 checkAmount = calcATokenAmount(productQuantity.mul(productToken.paid()));
        require(checkAmount == aTokenAmount,"invalid cover amount");
        aTokenAddress.transferFromERC20(_msgSender(), address(this), aTokenAmount);
        productToken.transferFrom(_msgSender(), address(this), productQuantity);
        userClaimMap[_msgSender()] = userClaimMap[_msgSender()].add(productQuantity);
        _totalClaimProductQuantity = _totalClaimProductQuantity.add(productQuantity);
    }

    function returnRemainingAToken(address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        uint256 totalRealPayAmount = _totalClaimProductQuantity.mul(payAmount());
        uint256 totalNeedPayAmount = _totalClaimProductQuantity.mul(productToken.paid());
        if(totalRealPayAmount < totalNeedPayAmount) {
            uint256 totalLeftATokenAmount = calcATokenAmount(totalNeedPayAmount.sub(totalRealPayAmount));
            uint256 claimQuantity = userClaimMap[userAccount];
            uint256 aTokenAmount = totalLeftATokenAmount.mul(claimQuantity).div(_totalClaimProductQuantity);
            if(aTokenAmount>0){
                aTokenAddress.transferERC20(userAccount, aTokenAmount);
            }
        }
        userClaimMap[userAccount] = 0;
    }

    function getAToken(uint256 userPayAmount, address userAccount) onlyPoolToken nonReentrant whenNotPaused public virtual override {
        uint256 totalPayAmount = totalRealPayFromStaking();
        uint256 totalATokenAmount = calcATokenAmount(_totalClaimProductQuantity.mul(payAmount()));
        uint256 aTokenAmount = totalATokenAmount.mul(userPayAmount).div(totalPayAmount);
        if(aTokenAmount>0){
            aTokenAddress.transferERC20(userAccount, aTokenAmount);
        }
    }

}