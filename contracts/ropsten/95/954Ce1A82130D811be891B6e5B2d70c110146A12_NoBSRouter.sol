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

    constructor(address owner, address _feeReceiver, address _lpRouter) public Ownable() {
        feeReceiver = payable(_feeReceiver);
        // 0.15%
        standardFee = 15;
        standardFeeDivisor = 10000;
        networkLPRouter = _lpRouter;
        _owner = owner;
        INoBSFactory _noBSFactory = new NoBSFactory(address(this), _lpRouter, _feeReceiver, standardFee, standardFeeDivisor);
        noBSFactory = _noBSFactory;
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

import "./interfaces/INoBSFactory.sol";
import "./NoBSDynamicReflector.sol";

contract NoBSFactory is INoBSFactory, Ownable {
    mapping(address => mapping(uint256 => address)) public override getReflector;
    mapping(address => bool) public override hasMultipleReflectors;
    mapping(address => uint256) public override reflectorsForContractCount;
    address[] public allReflectors;

    address public noBSRouter;
    address payable private feeReceiver;
    uint256 public standardFee;
    uint256 public standardFeeDivisor;
    address public networkLPRouter;

    event ReflectorCreated(address indexed forContract, address indexed reflectingToken, address reflectorAddress);

//    constructor() public {}

    constructor(address, address _lpRouter, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) public {
        _owner = _msgSender();
        noBSRouter = _msgSender();
        feeReceiver = payable(_feeReceiver);
        standardFee = _setFee;
        standardFeeDivisor = _setFeeDivisor;
        networkLPRouter = _lpRouter;
//        super.initialize(_noBSRouter, _noBSRouter, _feeReceiver, _setFee, _setFeeDivisor);
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
        bytes memory bytecode = type(NoBSDynamicReflector).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(requester, index));
        assembly {
            reflectorAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
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

import "./AuthorizedList.sol";
import "./NoBSInit.sol";
import "../interfaces/INoBSAccessControl.sol";

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

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import "./Ownable.sol";
import "../interfaces/IAuthorizedList.sol";

contract AuthorizedList is IAuthorizedList, Ownable
{
    using Address for address;

    event AuthorizationUpdated(address indexed user, bool authorized);
    event AuthorizationRenounced(address indexed user);

    bool private multiAuth;
    mapping(address => bool) internal authorizedCaller;

    modifier authorized() {
        require(authorizedCaller[_msgSender()] || _msgSender() == _owner, "You are not authorized to use this function");
        require(_msgSender() != address(0), "Zero address is not a valid caller");
        _;
    }

    constructor(bool allowNonOwnerAuths) Ownable() public {
        multiAuth = allowNonOwnerAuths;
        authorizedCaller[_msgSender()] = true;
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external virtual override onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;
        emit AuthorizationUpdated(authAddress, shouldAuthorize);
    }

    function renounceAuthorization() external authorized {
        authorizedCaller[_msgSender()] = false;
        emit AuthorizationRenounced(_msgSender());
    }

    function authorizeByAuthorized(address authAddress) external virtual override authorized {
        require(multiAuth, "Option not set to allow this function");
        authorizedCaller[authAddress] = true;
        emit AuthorizationUpdated(authAddress, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSAccessControl {
    function initialize(address _noBSRouter, address _authorizedParty) external;
}

// SPDX-License-Identifier: MIT

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IAuthorizedList {
    function authorizeCaller(address authAddress, bool shouldAuthorize) external;
    function authorizeByAuthorized(address authAddress) external;
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "./utils/LPSwapSupport.sol";
import "./utils/AuthorizedList.sol";
import "./utils/LockableFunction.sol";
import "./utils/NoBSAccessControl.sol";
import "./utils/NoBSContract.sol";
import "./interfaces/INoBSDynamicReflector.sol";
import "./utils/NoBSInit.sol";

contract NoBSDynamicReflector is INoBSDynamicReflector, NoBSInit, NoBSContract, LPSwapSupport, LockableFunction {
    using Address for address;
    using SafeMath for uint256;

    event ReflectionsDistributed(string indexed rewardName, uint256 accountsProcessed, uint256 rewardsSent);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 public rewardsToken;
    IBEP20 public controlToken;
    RewardType private rewardType;
    RewardInfo private rewardTokenInfo;
    string private defaultCurrencyName = "BNB";

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => bool) isExcludedFromDividends;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 private defaultDecimals = 10 ** 18;

    uint256 public minPeriod;
    uint256 public minDistribution;
    uint256 internal minXferGas = 3000;

    uint256 currentIndex;

    constructor () public {
        _owner = _msgSender();
    }

    function initialize(address _noBSRouter, address _lpRouter, address _controlToken, address _rewardsToken, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external override onlyOwner init {
        super.initialize(_noBSRouter, _controlToken, _feeReceiver, _setFee, _setFeeDivisor);
        updateRouter(_lpRouter);
        minSpendAmount = 0;
        maxSpendAmount = 100 ether;
        controlToken = IBEP20(payable(_controlToken));

        if(_rewardsToken == address(0)){
            rewardType = RewardType.CURRENCY;
            rewardTokenInfo.name = defaultCurrencyName;
            rewardTokenInfo.rewardAddress = address(0);
            rewardTokenInfo.decimals = defaultDecimals;
        } else {
            rewardType = RewardType.TOKEN;
            rewardsToken = IBEP20(_rewardsToken);
            rewardTokenInfo.name = rewardsToken.name();
            rewardTokenInfo.rewardAddress = _rewardsToken;
            rewardTokenInfo.decimals = 10 ** uint256(rewardsToken.decimals());
        }

        minDistribution = rewardTokenInfo.decimals;

        isExcludedFromDividends[_controlToken] = true;
        isExcludedFromDividends[address(this)] = true;
        isExcludedFromDividends[deadAddress] = true;

    }

    function rewardCurrency() public view override returns(string memory){
        return rewardTokenInfo.name;
    }

    function registerSelf() external override {
        require(!isExcludedFromDividends[_msgSender()], "This address is excluded and cannot self register");
        uint256 amount = controlToken.balanceOf(_msgSender());
        _setShare(_msgSender(), amount);
    }

    function enroll(address shareholder) external override {
        require(!isExcludedFromDividends[shareholder], "This address is excluded and cannot register");
        uint256 amount = controlToken.balanceOf(shareholder);
        _setShare(shareholder, amount);
    }

    function excludeFromReward(address shareholder, bool shouldExclude) external override onlyAuthorizedOrOwner {
        isExcludedFromDividends[shareholder] = shouldExclude;
        uint256 amount = 0;
        if(!shouldExclude)
            amount = controlToken.balanceOf(shareholder);
        _setShare(shareholder, amount);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyAuthorizedOrOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyAuthorizedOrOwner {
        _setShare(shareholder, amount);
    }

    function _setShare(address shareholder, uint256 amount) private {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        if(isExcludedFromDividends[shareholder]){
            if(shares[shareholder].amount == 0){
                return;
            } else {
                amount = 0;
            }
        }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    receive() external payable{
        if(!inSwap)
            swap();
    }

    function deposit() external payable override onlyAuthorizedOrOwner {
        if(!inSwap)
            swap();
    }

    function swap() lockTheSwap private {
        uint256 amount;
        if(rewardType == RewardType.TOKEN) {
            uint256 contractBalance = routingCall(address(this).balance);
            uint256 balanceBefore = rewardsToken.balanceOf(address(this));

            swapCurrencyForTokensAdv(address(rewardsToken), contractBalance, address(this));

            amount = rewardsToken.balanceOf(address(this)).sub(balanceBefore);
        } else {
            amount = routingCall(msg.value);
        }
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function setRewardToCurrency(bool andSwap) external override onlyAuthorizedOrOwner {
        require(rewardType != RewardType.CURRENCY, "Rewards already set to reflect currency");
        if(!inSwap)
            resetToCurrency(andSwap);
    }

    function resetToCurrency(bool andSwap) private lockTheSwap {
        uint256 contractBalance = rewardsToken.balanceOf(address(this));
        if(contractBalance > rewardTokenInfo.decimals && andSwap)
            swapTokensForCurrencyAdv(address(rewardsToken), contractBalance, address(this));
        rewardsToken = IBEP20(0);
        totalDividends = address(this).balance;
        dividendsPerShare = dividendsPerShareAccuracyFactor.mul(totalDividends).div(totalShares);

        rewardTokenInfo.name = "BNB";
        rewardTokenInfo.rewardAddress = address(0);
        rewardTokenInfo.decimals = defaultDecimals;

        rewardType = RewardType.CURRENCY;
    }

    function setRewardToToken(address _tokenAddress, bool andSwap) external override onlyAuthorizedOrOwner {
        require(rewardType != RewardType.TOKEN || _tokenAddress != address(rewardsToken), "Rewards already set to reflect this token");
        if(!inSwap)
            resetToToken(_tokenAddress, andSwap);
    }

    function resetToToken(address _tokenAddress, bool andSwap) private lockTheSwap {
        uint256 contractBalance;
        if(rewardType == RewardType.TOKEN && andSwap){
            contractBalance = rewardsToken.balanceOf(address(this));
            if(contractBalance > rewardTokenInfo.decimals)
                swapTokensForCurrencyAdv(address(rewardsToken), contractBalance, address(this));
        }
        contractBalance = address(this).balance;
        swapCurrencyForTokensAdv(_tokenAddress, contractBalance, address(this));

        rewardsToken = IBEP20(payable(_tokenAddress));
        totalDividends = rewardsToken.balanceOf(address(this));
        dividendsPerShare = dividendsPerShareAccuracyFactor.mul(totalDividends).div(totalShares);

        rewardTokenInfo.name = rewardsToken.name();
        rewardTokenInfo.rewardAddress = _tokenAddress;
        rewardTokenInfo.decimals = 10 ** uint256(rewardsToken.decimals());

        rewardType = RewardType.TOKEN;
    }

    function _approve(address, address, uint256) internal override {
        require(false);
    }

    function process(uint256 gas) external override {
        if(!locked){
            _process(gas);
        }
    }

    function _process(uint256 gas) private lockFunction {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }
        uint256 rewardsSent = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                rewardsSent = rewardsSent.add(_distributeDividend(shareholders[currentIndex]));
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        emit ReflectionsDistributed(rewardTokenInfo.name, iterations, rewardsSent);
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && getUnpaidEarnings(shareholder) > minDistribution && !isExcludedFromDividends[shareholder];
    }

    function distributeDividend(address shareholder) internal lockFunction returns(uint256 amount) {
        return _distributeDividend(shareholder);
    }

    function _distributeDividend(address shareholder) internal returns(uint256 amount) {
        if(shares[shareholder].amount == 0 || isExcludedFromDividends[shareholder]){ return 0; }

        amount = getUnpaidEarnings(shareholder);
        if(amount > minDistribution){
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            totalDistributed = totalDistributed.add(amount);

            if(rewardType == RewardType.TOKEN){
                rewardsToken.transfer(shareholder, amount);
            } else {
                (bool success,) = shareholder.call{gas: minXferGas, value: amount}("");
                if(!success)
                    return 0;
            }
        } else {
            return 0;
        }
    }

    function claimDividend() override external {
        if(!locked)
            distributeDividend(msg.sender);
    }

    function claimDividendFor(address shareholder) external override onlyAuthorizedOrOwner {
        if(!locked)
            distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view override returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function updateGasForTransfers(uint256 gasForTransfers) external override onlyAuthorizedOrOwner {
        require(gasForTransfers >= 2000, "Requires at least 2000 gas");
        minXferGas = gasForTransfers;
    }

    function getShares(address shareholder) external view override returns(uint256, uint256, uint256){
        return (shares[shareholder].amount, shares[shareholder].totalExcluded, shares[shareholder].totalRealised);
    }

    function getRewardType() external view override returns (string memory) {
        return rewardTokenInfo.name;
    }
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
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol';
import 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import "./NoBSAccessControl.sol";

abstract contract LPSwapSupport is NoBSAccessControl {
    using SafeMath for uint256;
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 currencyReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled = true;

    uint256 public minSpendAmount;
    uint256 public maxSpendAmount;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public liquidityReceiver;

    constructor() public {
        liquidityReceiver = deadAddress;
        minSpendAmount = 0.001 ether;
        maxSpendAmount = 10 ether;
    }

    function _approve(address owner, address spender, uint256 tokenAmount) internal virtual;

    function updateRouter(address newAddress) public onlyAuthorizedOrOwner {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyAuthorizedOrOwner {
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual onlyAuthorizedOrOwner {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual onlyAuthorizedOrOwner {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        pancakePair = newAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyAuthorizedOrOwner {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrency(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal {
        swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();

        if(tokenAddress != address(this)){
            IBEP20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }
        if(amount > maxSpendAmount){
            amount = maxSpendAmount;
        }
        if(amount < minSpendAmount) {return;}

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function updateSwapRange(uint256 minAmount, uint256 maxAmount) external onlyAuthorizedOrOwner {
        require(minAmount <= maxAmount, "Minimum must be less than maximum");
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract LockableFunction {
    bool internal locked;

    modifier lockFunction {
        locked = true;
        _;
        locked = false;
    }
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

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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