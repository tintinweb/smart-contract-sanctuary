// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./NoBS/utils/Ownable.sol";
import "./NoBS/interfaces/INoBSRouter.sol";
import "./NoBS/utils/NoBSContract.sol";
import "./NoBS/NoBSFactory.sol";

contract NoBSRouter is INoBSRouter, Ownable {

    INoBSFactory public noBSFactory;
    address payable private feeReceiver;
    uint256 public standardFee;
    uint256 public standardFeeDivisor;
    address public networkLPRouter;
    address private reflectorReference;

    constructor(address owner, address _reflector, address _feeReceiver, address _lpRouter) public Ownable() {
        feeReceiver = payable(_feeReceiver);
        // 0.15%
        standardFee = 15;
        standardFeeDivisor = 10000;
        networkLPRouter = _lpRouter;
        _owner = owner;
        INoBSFactory _noBSFactory = new NoBSFactory(_reflector, _lpRouter, _feeReceiver, standardFee, standardFeeDivisor);
        noBSFactory = _noBSFactory;
        reflectorReference = _reflector;
    }

    function updateReflectorCode(address ad) external onlyOwner {
        reflectorReference = ad;
        noBSFactory.updateReflectorCode(ad);
    }

    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        feeReceiver = payable(_feeReceiver);
    }

    function setFactory(address _factory) external onlyOwner {
        noBSFactory = INoBSFactory(_factory);
    }

    function transferStuckCurrency(address destination) external onlyOwner {
        destination.call{value: address(this).balance}("");
    }

    function transferStuckToken(address _destination, address _token) external onlyOwner {
        IBEP20 token = IBEP20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_destination, balance);
    }

    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external override onlyOwner {
        standardFee = _setFee;
        standardFeeDivisor = _setFeeDivisor;
        noBSFactory.setRoutingFee(_setFee, _setFeeDivisor);
    }

    function updateLPRouter(address _lpRouter) external override onlyOwner {
        networkLPRouter = _lpRouter;
        noBSFactory.updateLPRouter(_lpRouter);
    }

    // Getters
    function factory() external view override returns(address) {
        return address(noBSFactory);
    }

    function getReflector() external view override returns(address) {
        return getReflectorFor(_msgSender());
    }

    function getReflectorFor(address tokenAddress) public view override returns(address) {
        return getReflectorAtIndexFor(tokenAddress, 0);
    }

    function reflectorAtIndex(uint256 index) external view override returns(address) {
        return getReflectorAtIndexFor(_msgSender(), index);
    }

    function getReflectorAtIndexFor(address tokenAddress, uint256 index) public view override returns(address) {
        return noBSFactory.getReflector(tokenAddress, index);
    }

    // Factory Interactions
    function createReflector(address tokenToReflect) external override returns(address) {
        return noBSFactory.createReflector(_msgSender(), tokenToReflect);
    }

    function createAdditionalReflector(address tokenToReflect) external override returns(address) {
        return noBSFactory.createAdditionalReflector(_msgSender(), tokenToReflect);
    }

    // Reflection interactions
    function getShares(address shareholder) external view override returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised) {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        return INoBSDynamicReflector(_reflector).getShares(shareholder);
    }

    function deposit() external payable override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).deposit{value: msg.value}();
    }

    function enroll(address shareholder) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).enroll(shareholder);
    }

    function claimDividendFor(address shareholder) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).claimDividendFor(shareholder);
    }

    function process(uint256 gas) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).process(gas);
    }

    function getSharesForReflector(address reflector, address shareholder) external view override returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised) {
        return INoBSDynamicReflector(reflector).getShares(shareholder);
    }

    function depositForReflector(address reflector) external override payable {
        INoBSDynamicReflector(reflector).deposit{value: msg.value}();
    }

    function enrollForReflector(address reflector, address shareholder) external override {
        INoBSDynamicReflector(reflector).enroll(shareholder);
    }

    function claimDividendForHolderForReflector(address reflector, address shareholder) external override {
        INoBSDynamicReflector(reflector).claimDividendFor(shareholder);
    }

    function processForReflector(address reflector, uint256 gas) external override {
        INoBSDynamicReflector(reflector).process(gas);
    }

    function setShare(address shareholder, uint256 amount) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).setShare(shareholder, amount);
    }

    function setShareForReflector(address reflector, address shareholder, uint256 amount) external override {
        INoBSDynamicReflector(reflector).setShare(shareholder, amount);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setRewardToCurrency(bool andSwap) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).setRewardToCurrency(andSwap);
    }

    function setRewardToToken(address _tokenAddress, bool andSwap) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).setRewardToToken(_tokenAddress, andSwap);
    }

    function rewardCurrency() external view override returns(string memory) {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        return INoBSDynamicReflector(_reflector).rewardCurrency();
    }

    function updateGasForTransfers(uint256 gasForTransfers) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).updateGasForTransfers(gasForTransfers);
    }

    function getUnpaidEarnings(address shareholder) external view override returns (uint256) {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        return INoBSDynamicReflector(_reflector).getUnpaidEarnings(shareholder);
    }

    function setDistributionCriteriaForReflector(address reflector, uint256 _minPeriod, uint256 _minDistribution) external override {
        INoBSDynamicReflector(reflector).setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setRewardToCurrencyForReflector(address reflector, bool andSwap) external override {
        INoBSDynamicReflector(reflector).setRewardToCurrency(andSwap);
    }

    function setRewardToTokenForReflector(address reflector, address _tokenAddress, bool andSwap) external override {
        INoBSDynamicReflector(reflector).setRewardToToken(_tokenAddress, andSwap);
    }

    function rewardCurrencyForReflector(address reflector) external view override returns (string memory) {
        return INoBSDynamicReflector(reflector).rewardCurrency();
    }

    function updateGasForTransfersForReflector(address reflector, uint256 gasForTransfers) external override {
        INoBSDynamicReflector(reflector).updateGasForTransfers(gasForTransfers);
    }

    function getUnpaidEarningsForReflector(address reflector, address shareholder) external view override returns (uint256) {
        return INoBSDynamicReflector(reflector).getUnpaidEarnings(shareholder);
    }

    function excludeFromReward(address shareholder, bool shouldExclude) external override {
        address _reflector = noBSFactory.getReflectorFor(_msgSender());
        INoBSDynamicReflector(_reflector).excludeFromReward(shareholder, shouldExclude);
    }

    function excludeFromRewardForReflector(address reflector, address shareholder, bool shouldExclude) external override {
        INoBSDynamicReflector(reflector).excludeFromReward(shareholder, shouldExclude);
    }

    // Reflection Settings
    function updateExcludedFromFeesByRouter(address reflector, bool _shouldExcludeContractFromFees) external onlyOwner {
        INoBSContract(reflector).updateExcludedFromFeesByRouter(_shouldExcludeContractFromFees);
    }
}

// SPDX-License-Identifier: MIT

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';

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
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = _msgSender();
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
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSRouter {

    // Router interactions
    function setFeeReceiver(address ad) external;
    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external;
    function updateLPRouter(address _lpRouter) external;

    // Getters
    function factory() external view returns(address);
    function getReflector() external view returns(address);
    function getReflectorFor(address tokenAddress) external view returns(address);
    function reflectorAtIndex(uint256 index) external view returns(address);
    function getReflectorAtIndexFor(address tokenAddress, uint256 index) external view returns(address);

    // Factory Interactions
    function createReflector(address tokenToReflect) external returns(address);
    function createAdditionalReflector(address tokenToReflect) external returns(address);

    // Reflection interactions
    function getShares(address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function deposit() external payable;
    function enroll(address shareholder) external;
    function claimDividendFor(address shareholder) external;
    function process(uint256 gas) external;

    function getSharesForReflector(address reflector, address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function depositForReflector(address reflector) external payable;
    function enrollForReflector(address reflector, address shareholder) external;
    function claimDividendForHolderForReflector(address reflector, address shareholder) external;
    function processForReflector(address reflector, uint256 gas) external;

    function setShare(address shareholder, uint256 amount) external;
    function setShareForReflector(address reflector, address shareholder, uint256 amount) external;

    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function excludeFromRewardForReflector(address reflector, address shareholder, bool shouldExclude) external;

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function rewardCurrency() external view returns(string memory);
    function updateGasForTransfers(uint256 gasForTransfers) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);

    function setDistributionCriteriaForReflector(address reflector, uint256 _minPeriod, uint256 _minDistribution) external;
    function setRewardToCurrencyForReflector(address reflector, bool andSwap) external;
    function setRewardToTokenForReflector(address reflector, address _tokenAddress, bool andSwap) external;
    function rewardCurrencyForReflector(address reflector) external view returns (string memory);
    function updateGasForTransfersForReflector(address reflector, uint256 gasForTransfers) external;
    function getUnpaidEarningsForReflector(address reflector, address shareholder) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import "../interfaces/INoBSContract.sol";
import "./NoBSAccessControl.sol";
import "./NoBSInit.sol";

contract NoBSContract is INoBSContract, NoBSInit, NoBSAccessControl {
    using SafeMath for uint256;

    bool private contractIsExcludedFromFeesByRouter;
    uint256 internal routingFee;
    uint256 internal routingFeeDivisor;
    uint256 private routingGas = 4000;
    address payable internal routingFeeReceiver;

    constructor() NoBSAccessControl() internal {}

    function initialize(address _noBSRouter, address _authorizedParty, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) public virtual override onlyOwner init {
        super.initialize(_noBSRouter, _authorizedParty);
        routingFeeReceiver = payable(_feeReceiver);
        routingFee = _setFee;
        routingFeeDivisor = _setFeeDivisor;
    }

    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external override onlyRouter {
        routingFee = _setFee;
        routingFeeDivisor = _setFeeDivisor;
    }

    function updateRoutingGas(uint256 _newGas) external override onlyRouter {
        routingGas = _newGas;
    }

    function updateExcludedFromFeesByRouter(bool _shouldExcludeContractFromFees) external override onlyRouter {
        contractIsExcludedFromFeesByRouter = _shouldExcludeContractFromFees;
    }

    function updateNoBSRouter(address _noBSRouterAddress) external override onlyRouter {
        noBSRouter = _noBSRouterAddress;
        transferOwnership(_noBSRouterAddress);
    }

    function updateRoutingFeeReceiver(address _feeReceiver) external override onlyRouter {
        routingFeeReceiver = payable(_feeReceiver);
    }

    function isExcludedFromFeesByRouter() external view onlyRouter override returns(bool){
        return contractIsExcludedFromFeesByRouter;
    }

    function routingCall(uint256 _txAmount) internal returns(uint256){
        if(contractIsExcludedFromFeesByRouter)
            return _txAmount;
        if(routingFee == 0 || routingFeeDivisor == 0 || _txAmount == 0){
            return _txAmount;
        }
        uint256 _routerBasedFee = _txAmount.mul(routingFee).div(routingFeeDivisor);
        (bool success,) = routingFeeReceiver.call{value : _routerBasedFee, gas: routingGas}("");
        if(!success)
            _routerBasedFee = 0;
        return _txAmount.sub(_routerBasedFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "./interfaces/INoBSFactory.sol";
import "./interfaces/INoBSDynamicReflector.sol";
import "./utils/Ownable.sol";

contract NoBSFactory is INoBSFactory, Ownable {
    bytes private bytecode;
    mapping(address => mapping(uint256 => address)) public override getReflector;
    mapping(address => bool) public override hasMultipleReflectors;
    mapping(address => uint256) public override reflectorsForContractCount;
    address[] public allReflectors;

    address public noBSRouter;
    address payable private feeReceiver;
    uint256 public standardFee;
    uint256 public standardFeeDivisor;
    address public networkLPRouter;
    address private reflectorReference;

    event ReflectorCreated(address indexed forContract, address indexed reflectingToken, address reflectorAddress);

//    constructor() public {}

    constructor(address _reflector, address _lpRouter, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) public {
        _owner = _msgSender();
        noBSRouter = _msgSender();
        feeReceiver = payable(_feeReceiver);
        standardFee = _setFee;
        standardFeeDivisor = _setFeeDivisor;
        networkLPRouter = _lpRouter;
        reflectorReference = _reflector;
//        super.initialize(_noBSRouter, _noBSRouter, _feeReceiver, _setFee, _setFeeDivisor);
    }

    function updateReflectorCode(address ad) external override onlyOwner {
        reflectorReference = ad;
    }

    function allReflectorsLength() external view override returns (uint256){
        return allReflectors.length;
    }

    function createReflector(address requester, address tokenToReflect) external override onlyOwner returns(address) {
        return _createDynamicReflector(requester, 0, tokenToReflect);
    }

    function createAdditionalReflector(address requester, address tokenToReflect) external override onlyOwner returns(address){
        hasMultipleReflectors[requester] = true;
        return _createDynamicReflector(requester, reflectorsForContractCount[requester], tokenToReflect);
    }

    function _createDynamicReflector(address requester, uint256 index, address tokenToReflect) private returns(address reflectorAddress){
        require(getReflector[requester][index] == address(0), "Reflector Already Exists");
        bytes memory _bytecode = at(reflectorReference);
        bytes32 salt = keccak256(abi.encodePacked(requester, index));
        assembly {
            reflectorAddress := create2(0, add(_bytecode, 32), mload(_bytecode), salt)
        }

        INoBSDynamicReflector(reflectorAddress).initialize(noBSRouter, networkLPRouter, requester, tokenToReflect, feeReceiver, standardFee, standardFeeDivisor);
        getReflector[requester][index] = reflectorAddress;
        reflectorsForContractCount[requester]++;
        allReflectors.push(reflectorAddress);

        emit ReflectorCreated(requester, tokenToReflect, reflectorAddress);
    }

    function updateLPRouter(address _lpRouter) external override onlyOwner {
        noBSRouter = _lpRouter;
    }

    function reflector() external override view returns(address) {
        return getReflectorFor(_msgSender());
    }

    function getReflectorFor(address tokenAddress) public view override returns(address) {
        return getReflector[tokenAddress][0];
    }

    function transferStuckCurrency(address destination) external override onlyOwner {
        destination.call{value: address(this).balance}("");
    }

    function transferStuckToken(address _destination, address _token) override external onlyOwner {
        IBEP20 token = IBEP20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_destination, balance);
    }

    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external override onlyOwner {
        standardFee = _setFee;
        standardFeeDivisor = _setFeeDivisor;
    }

    function updateNoBSRouter(address _noBSRouterAddress) external override onlyOwner {
        noBSRouter = _noBSRouterAddress;
    }
    function updateRoutingFeeReceiver(address _feeReceiver) external override onlyOwner {
        feeReceiver = payable(_feeReceiver);
    }

    function at(address _addr) private view returns (bytes memory o_code) {
        assembly {
        // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
            o_code := mload(0x40)
        // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
            mstore(o_code, size)
        // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSContract {
    function initialize(address _noBSRouter, address _authorizedParty, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external;
    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external;
    function updateRoutingGas(uint256 _newGas) external;
    function updateExcludedFromFeesByRouter(bool _shouldExcludeContractFromFees) external;
    function updateNoBSRouter(address _noBSRouterAddress) external;
    function updateRoutingFeeReceiver(address _feeReceiver) external;
    function isExcludedFromFeesByRouter() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../interfaces/INoBSAccessControl.sol";
import "./NoBSInit.sol";
import "./Ownable.sol";

contract NoBSAccessControl is INoBSAccessControl, NoBSInit, Ownable {
    address private authorizedParty;
    address public noBSRouter;

    modifier onlyAuthorizedOrOwner() {
        require(_owner == _msgSender() || authorizedParty == _msgSender() || noBSRouter == _msgSender(), "Caller is not authorized");
        _;
    }

    modifier onlyRouter() {
        require(noBSRouter == _msgSender(), "Caller is not authorized");
        _;
    }

    constructor() internal {
        _owner = _msgSender();
    }

    // Authorized party cannot be changed, hard requirement to tie an authorized address to a controlling token
    // contract at deployment time.
    function initialize(address _noBSRouter, address _authorizedParty) public override onlyOwner init {
        authorizedParty = _authorizedParty;
        noBSRouter = _noBSRouter;
        _owner = _noBSRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract NoBSInit {
    bool internal isInitialized;

    modifier init {
        require(!isInitialized, "Contract is already initialized");
        _;
        isInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSAccessControl {
    function initialize(address _noBSRouter, address _authorizedParty) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSFactory {
    function getReflector(address, uint256) external view returns(address);
    function hasMultipleReflectors(address) external view returns(bool);
    function reflectorsForContractCount(address) external view returns(uint256);

//    function initialize(address _noBSRouter, address requester, address _lpRouter, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external;
    function allReflectorsLength() external view returns (uint256);
    function createReflector(address requester, address tokenToReflect) external returns(address);
    function createAdditionalReflector(address requester, address tokenToReflect) external returns(address);
    function updateLPRouter(address _lpRouter) external;
    function reflector() external view returns(address);
    function getReflectorFor(address tokenAddress) external view returns(address);
    function transferStuckCurrency(address destination) external;
    function transferStuckToken(address _destination, address _token) external;


//    function initialize(address _noBSRouter, address _authorizedParty, address _lpRouter, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external;
    function setRoutingFee(uint256 _setFee, uint256 _setFeeDivisor) external;
    function updateNoBSRouter(address _noBSRouterAddress) external;
    function updateRoutingFeeReceiver(address _feeReceiver) external;
    function updateReflectorCode(address ad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";

interface INoBSDynamicReflector is IBaseDistributor {
    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function getRewardType() external view returns (string memory);
    function updateGasForTransfers(uint256 gasForTransfers) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);

    function initialize(address _noBSRouter, address _lpRouter, address _controlToken, address _rewardsToken, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    function getShares(address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function deposit() external payable;
    function rewardCurrency() external view returns(string memory);
    function registerSelf() external;
    function enroll(address shareholder) external;
    function claimDividend() external;

    function process(uint256 gas) external;

    function setShare(address shareholder, uint256 amount) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}