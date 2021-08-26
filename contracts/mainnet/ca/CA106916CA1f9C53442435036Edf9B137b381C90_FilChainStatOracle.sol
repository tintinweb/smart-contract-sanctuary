/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


library StringUtil {
    
    function equal(string memory a, string memory b) internal pure returns(bool){
        return equal(bytes(a),bytes(b));
    }

    function equal(bytes memory a, bytes memory b) internal pure returns(bool){
        return keccak256(a) == keccak256(b);
    }
    
    function notEmpty(string memory a) internal pure returns(bool){
        return bytes(a).length > 0;
    }

}


/*
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

contract WhiteList is Ownable{

    mapping(address=>bool) public whiteList;

    event AddWhiteList(address account);
    event RemoveWhiteList(address account);

    modifier onlyWhiteList(){
        require(whiteList[_msgSender()] == true, "not in white list");
        _;
    }

    function addWhiteList(address account) public onlyOwner{
        require(account != address(0), "address should not be 0");
        whiteList[account] = true;
        emit AddWhiteList(account);
    }

    function removeWhiteList(address account) public onlyOwner{
        whiteList[account] = false;
        emit RemoveWhiteList(account);
    }

}

contract FilChainStatOracle is WhiteList{
    using StringUtil for string;
    using SafeMath for uint256;

    // all FIL related value use attoFil
    uint256 public sectorInitialPledge; // attoFil/TiB
    mapping(string=>uint256) public minerAdjustedPower; // TiB
    mapping(string=>uint256) public minerMiningEfficiency; // attoFil/GiB
    mapping(string=>uint256) public minerSectorInitialPledge; // attoFil/TiB
    
    /**
        TiB, 
        the total adjusted power of all miners listed in the platform
     */
    uint256 public minerTotalAdjustedPower;
    
    /**
        attoFil/GiB/24H,
        the avg mining efficiency of all miners listed on this platform of last 24 hours
     */
    uint256 public avgMiningEfficiency;
    
    /**
        attoFil/24H,
        the total block rewards of last 24 hours of the the whole Filecoin network
     */
    uint256 public latest24hBlockReward;
    
    uint256 public rewardAttenuationFactor; // *10000
    uint256 public networkStoragePower; // TiB
    uint256 public dailyStoragePowerIncrease; //TiB

    event SectorInitialPledgeChanged(uint256 originalValue, uint256 newValue);
    event MinerSectorInitialPledgeChanged(string minerId, uint256 originalValue, uint256 newValue);
    event MinerAdjustedPowerChanged(string minerId, uint256 originalValue, uint256 newValue);
    event MinerMiningEfficiencyChanged(string minerId, uint256 originalValue, uint256 newValue);
    event AvgMiningEfficiencyChanged(uint256 originalValue, uint256 newValue);
    event Latest24hBlockRewardChanged(uint256 originalValue, uint256 newValue);
    event RewardAttenuationFactorChanged(uint256 originalValue, uint256 newValue);
    event NetworkStoragePowerChanged(uint256 originalValue, uint256 newValue);
    event DailyStoragePowerIncreaseChanged(uint256 originalValue, uint256 newValue);

    function setSectorInitialPledge(uint256 _sectorInitialPledge) public onlyWhiteList{
        require(_sectorInitialPledge>0, "value should not be 0");
        emit SectorInitialPledgeChanged(sectorInitialPledge, _sectorInitialPledge);
        sectorInitialPledge = _sectorInitialPledge;
    }

    function setMinerSectorInitialPledge(string memory _minerId, uint256 _minerSectorInitialPledge) public onlyWhiteList{
        require(_minerSectorInitialPledge>0, "value should not be 0");
        emit MinerSectorInitialPledgeChanged(_minerId, minerSectorInitialPledge[_minerId], _minerSectorInitialPledge);
        minerSectorInitialPledge[_minerId] = _minerSectorInitialPledge;
    }

    function setMinerSectorInitialPledgeBatch(string[] memory _minerIdList, uint256[] memory _minerSectorInitialPledgeList) public onlyWhiteList{
        require(_minerIdList.length>0, "miner array should not be 0 length");
        require(_minerSectorInitialPledgeList.length>0, "value array should not be 0 length");
        require(_minerIdList.length == _minerSectorInitialPledgeList.length, "array length not equal");

        for(uint i=0; i<_minerIdList.length; i++){
            require(_minerSectorInitialPledgeList[i]>0, "value should not be 0");
            emit MinerSectorInitialPledgeChanged(_minerIdList[i], minerSectorInitialPledge[_minerIdList[i]], _minerSectorInitialPledgeList[i]);
            minerSectorInitialPledge[_minerIdList[i]] = _minerSectorInitialPledgeList[i];
        }
    }

    function setMinerAdjustedPower(string memory _minerId, uint256 _minerAdjustedPower) public onlyWhiteList{
        require(_minerId.notEmpty(), "miner id should not be empty");
        require(_minerAdjustedPower>0, "value should not be 0");
        minerTotalAdjustedPower = minerTotalAdjustedPower.sub(minerAdjustedPower[_minerId]).add(_minerAdjustedPower);
        emit MinerAdjustedPowerChanged(_minerId, minerAdjustedPower[_minerId], _minerAdjustedPower);
        minerAdjustedPower[_minerId] = _minerAdjustedPower;
    }

    function setMinerAdjustedPowerBatch(string[] memory _minerIds, uint256[] memory _minerAdjustedPowers) public onlyWhiteList{
        require(_minerIds.length == _minerAdjustedPowers.length, "minerId list count is not equal to power list");
        for(uint i; i<_minerIds.length; i++){
            require(_minerIds[i].notEmpty(), "miner id should not be empty");
            require(_minerAdjustedPowers[i]>0, "value should not be 0");
            minerTotalAdjustedPower = minerTotalAdjustedPower.sub(minerAdjustedPower[_minerIds[i]]).add(_minerAdjustedPowers[i]);
            emit MinerAdjustedPowerChanged(_minerIds[i], minerAdjustedPower[_minerIds[i]], _minerAdjustedPowers[i]);
            minerAdjustedPower[_minerIds[i]] = _minerAdjustedPowers[i];
        }
    }

    function removeMinerAdjustedPower(string memory _minerId) public onlyWhiteList{
        uint256 adjustedPower = minerAdjustedPower[_minerId];
        minerTotalAdjustedPower = minerTotalAdjustedPower.sub(adjustedPower);
        delete minerAdjustedPower[_minerId];
        emit MinerAdjustedPowerChanged(_minerId, adjustedPower, 0);
    }

    function setMinerMiningEfficiency(string memory _minerId, uint256 _minerMiningEfficiency) public onlyWhiteList{
        require(_minerId.notEmpty(), "miner id should not be empty");
        require(_minerMiningEfficiency>0, "value should not be 0");
        emit MinerMiningEfficiencyChanged(_minerId, minerMiningEfficiency[_minerId], _minerMiningEfficiency);
        minerMiningEfficiency[_minerId] = _minerMiningEfficiency;
    }

    function setMinerMiningEfficiencyBatch(string[] memory _minerIds, uint256[] memory _minerMiningEfficiencys) public onlyWhiteList{
        require(_minerIds.length == _minerMiningEfficiencys.length, "minerId list count is not equal to power list");
        for(uint i; i<_minerIds.length; i++){
            require(_minerIds[i].notEmpty(), "miner id should not be empty");
            require(_minerMiningEfficiencys[i]>0, "value should not be 0");
            emit MinerMiningEfficiencyChanged(_minerIds[i], minerMiningEfficiency[_minerIds[i]], _minerMiningEfficiencys[i]);
            minerMiningEfficiency[_minerIds[i]] = _minerMiningEfficiencys[i];
        }
    }

    function setAvgMiningEfficiency(uint256 _avgMiningEfficiency) public onlyWhiteList{
        require(_avgMiningEfficiency>0, "value should not be 0");
        emit AvgMiningEfficiencyChanged(avgMiningEfficiency, _avgMiningEfficiency);
        avgMiningEfficiency = _avgMiningEfficiency;
    }

    function setLatest24hBlockReward(uint256 _latest24hBlockReward) public onlyWhiteList{
        require(_latest24hBlockReward>0, "value should not be 0");
        emit Latest24hBlockRewardChanged(latest24hBlockReward, _latest24hBlockReward);
        latest24hBlockReward = _latest24hBlockReward;
    }

    function setRewardAttenuationFactor(uint256 _rewardAttenuationFactor) public onlyWhiteList{
        require(_rewardAttenuationFactor>0, "value should not be 0");
        emit RewardAttenuationFactorChanged(rewardAttenuationFactor, _rewardAttenuationFactor);
        rewardAttenuationFactor = _rewardAttenuationFactor;
    }

    function setNetworkStoragePower(uint256 _networkStoragePower) public onlyWhiteList{
        require(_networkStoragePower>0, "value should not be 0");
        emit NetworkStoragePowerChanged(networkStoragePower, _networkStoragePower);
        networkStoragePower = _networkStoragePower;
    }

    function setDailyStoragePowerIncrease(uint256 _dailyStoragePowerIncrease) public onlyWhiteList{
        require(_dailyStoragePowerIncrease>0, "value should not be 0");
        emit DailyStoragePowerIncreaseChanged(dailyStoragePowerIncrease, _dailyStoragePowerIncrease);
        dailyStoragePowerIncrease = _dailyStoragePowerIncrease;
    }

}