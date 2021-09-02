/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// File: contracts\@openzeppelin\GSN\Context.sol

// SPDX-License-Identifier: MIT

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