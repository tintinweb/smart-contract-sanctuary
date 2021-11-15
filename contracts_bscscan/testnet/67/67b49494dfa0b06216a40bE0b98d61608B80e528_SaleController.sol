// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./RiverSale.sol";
import "./libs/Payment.sol";

contract SaleController is Ownable {
    struct SwapRouter {
        address router;
        string name;
        bool active;
    }

    SwapRouter[] public routers;

    address public saleContract;
    uint256 public creationFee = 10**18;
    address public feeCollector;

    mapping(address => address[]) public userSales;
    address[] public sales;

    constructor(address _saleContract, address _feeCollector) {
        setSaleContract(_saleContract);
        setFeeCollector(_feeCollector);
    }

    function createSale(
        IERC20 _token, 
        uint256 _softCap, 
        uint256 _hardCap, 
        uint256 _minContribution, 
        uint256 _maxContribution, 
        uint256 _liquidityPercentage, 
        uint256 _listingPrice, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _liquidityLockUntilTime,
        MetaInfoStruct memory _meta
    ) public payable returns (address) {
        Payment.chargeSender(creationFee, feeCollector, true);
        RiverSale sale = RiverSale(Clones.clone(address(saleContract)));
        sale.init(_token, _softCap, _hardCap, _minContribution, _maxContribution, _liquidityPercentage, _listingPrice, _startTime, _endTime, _liquidityLockUntilTime);
        sale.setMetaInfo(_meta);
        sale.setFeeCollector(feeCollector);
        return address(sale);
    }

    function setSaleContract(address _contract) public onlyOwner {
        saleContract = _contract;
    }

    function setFeeCollector(address _account) public onlyOwner {
        feeCollector = _account;
    }

    function setCreationFee(uint256 _fee) public onlyOwner {
        creationFee = _fee;
    }

    function setSaleFees(address _sale, uint256 _raisedPerc, uint256 _tokensPerc) public onlyOwner {
        RiverSale(_sale).setFees(_raisedPerc, _tokensPerc);
    }

    function routerCount() public view returns (uint256) {
        return routers.length;
    }

    function routerAdd(address _router, string memory _name) public onlyOwner {
        routers.push(SwapRouter({
            router: _router,
            name: _name,
            active: true
        }));
    }

    function routerStatus(uint256 _routerId, bool _active) public onlyOwner {
        routers[_routerId].active = _active;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Payment {
    function chargeSender(uint256 amount, address recipient, bool returnLeft) internal {
        require(msg.value >= amount, 'Insufficient funds provided.');

        payable(recipient).transfer(amount);

        if (returnLeft) {
            uint256 amountLeft = msg.value - amount;
            payable(msg.sender).transfer(amountLeft);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../offering/libs/swap/IUniswapV2Router02.sol";
import "../offering/libs/swap/IUniswapV2Factory.sol";
import "./Fees.sol";
import "./MetaInfo.sol";
import "./Managed.sol";

contract RiverSale is Ownable, Initializable, Managed, Fees, MetaInfo, ReentrancyGuard {
    uint256 public version = 1;

    IERC20 public token;
    uint256 public tokenPrice;
    uint256 public softCap;
    uint256 public hardCap;

    uint256 public minContribution;
    uint256 public maxContribution;

    // Percentage of raised funds that should be allocated to DEX, min: 51%, max 100% - feePercentage, recom >75%
    uint256 public liquidityPercentage; // 100 = 100%

    uint256 public listingPrice;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public liquidityLockUntilTime;

    IUniswapV2Router02 public swapRouter;
    IERC20 public lpToken;

    uint256 totalContribution;
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public claimed;
    
    bool public finished = false;
    bool public canceled = false;

    event DepositTokens(uint256 amount);
    event Contribution(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);
    event Cancel();

    modifier saleOpen() {
        require(block.timestamp >= startTime, 'Not yet started.');
        require(block.timestamp < endTime, 'End time reached.');
        require(totalContribution < hardCap, 'Hardcap reached.');
        require(isDeposited(), 'Tokens not accounted for.');
        _;
    }

    function init(
        IERC20 _token, 
        uint256 _softCap, 
        uint256 _hardCap, 
        uint256 _minContribution, 
        uint256 _maxContribution, 
        uint256 _liquidityPercentage, 
        uint256 _listingPrice, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _liquidityLockUntilTime
    ) public initializer {
        token = _token;
        _setCaps(_softCap, _hardCap);
        _setContribution(_minContribution, _maxContribution);
        _setListing(_liquidityPercentage, _listingPrice, _liquidityLockUntilTime);
        _setStartEndTime(_startTime, _endTime);
    }

    function _setStartEndTime(uint256 _startTime, uint256 _endTime) internal {
        require(_startTime < _endTime, 'Start time needs to be smaller than end.');
        require(_startTime + 7 days >= _endTime, 'Duration cannot be more than 7 days.');

        startTime = _startTime;
        endTime = _endTime;
    }

    function _setListing(uint256 _liquidityPercentage, uint256 _listingPrice, uint256 _liquidityLockUntilTime) internal {
        require(_liquidityPercentage >= 60, 'At least 60% should go to liquidity.');
        require(_liquidityPercentage <= 100, 'Not more than 100% for liquidity');
        require(_liquidityLockUntilTime > block.timestamp + 13 weeks, 'Minimum locktime is 3 months.');

        listingPrice = _listingPrice;
        liquidityPercentage = _liquidityPercentage;
        liquidityLockUntilTime = _liquidityLockUntilTime;
    }

    function _setCaps(uint256 _softCap, uint256 _hardCap) internal {
        require(_softCap <= _hardCap, 'SoftCap cannot be more than hardcap');
        require(_hardCap > 0, 'Hardcap cannot be zero');

        softCap = _softCap;
        hardCap = _hardCap;
    }

    function _setContribution(uint256 _min, uint256 _max) internal {
        require(_min <= _max, 'Minimum contribution cannot be larger than max.');
        require(_max <= hardCap, 'Contribution must be less than hardcap');
        minContribution = _min;
        maxContribution = _max;
    }

    

    function tokensRequired() public view returns (uint256) {
        uint256 saleTokens = tokenPrice * hardCap;
        uint256 liqTokens = listingPrice * (hardCap * liquidityPercentage / 100);
        uint256 saleFee = _calcTokenFee(saleTokens);

        return saleTokens + liqTokens + saleFee;
    }

    function _liqTokenAmount() internal view returns (uint256) {
        return listingPrice * _liqEthAmount();
    }

    function _liqEthAmount() internal view returns (uint256) {
        return totalContribution * liquidityPercentage / 100;
    }

    function isDeposited() public view returns (bool) {
        return token.balanceOf(address(this)) >= tokensRequired();
    }

    function hasEnded() public view returns (bool) {
        if (hardCap <= totalContribution) {
            return true;
        }

        if (endTime <= block.timestamp) {
            return true;
        }

        return false;
    }

    function depositTokens() public onlyManager {
        uint256 amount = tokensRequired();
        token.transferFrom(_msgSender(), address(this), amount);

        require(isDeposited(), 'Not enough tokens, whitelist contract from deflation.');

        emit DepositTokens(amount);
    }

    function buy() public payable nonReentrant saleOpen {
        require(msg.value >= minContribution, 'Minimum not met.');
        require(msg.value <= maxContribution, 'Maximum exceeded.');

        uint256 contribution = msg.value;
        uint256 remaining = hardCap - totalContribution;

        // Return what could not be allocated
        if (remaining < contribution) {
            payable(_msgSender()).transfer(contribution - remaining);
            contribution = remaining;
        }

        contributions[_msgSender()] += contribution;
        totalContribution += contribution;

        emit Contribution(_msgSender(), contribution);
    }

    function finish() public onlyManager nonReentrant {
        require(!finished, 'finished');
        require(!canceled, 'canceled');

        if (totalContribution > softCap) {
            _payFees();
            _addLiquidity();
            _returnRemainder();

            finished = true;
        } else {
            _cancel();
        }
    }

    function unlockLiquidity() public onlyManager {
        require(block.timestamp > liquidityLockUntilTime, 'Locked');
        lpToken.transfer(_msgSender(), lpToken.balanceOf(address(this)));
    }

    function setNewLock(uint256 _timestamp) public onlyManager {
        require(_timestamp > liquidityLockUntilTime, 'Should be large than current lock.');
        liquidityLockUntilTime = _timestamp;
    }

    function _addLiquidity() internal {
        uint256 liqToken = _liqTokenAmount();
        uint256 liqEth = _liqEthAmount();

        token.approve(address(swapRouter), liqToken);
        swapRouter.addLiquidityETH{
            value: liqEth
        }(address(token), liqToken, liqToken, liqEth, address(this), block.timestamp);
        lpToken = IERC20(IUniswapV2Factory(swapRouter.factory()).getPair(address(token), address(swapRouter.WETH())));
    }

    function _payFees() internal {
        uint256 saleTokens = tokenPrice * hardCap;
        uint256 tokenFee = _calcTokenFee(saleTokens);
        uint256 raiseFee = _calcRaisedFee(totalContribution);

        token.transfer(feeCollector, tokenFee);
        payable(feeCollector).transfer(raiseFee);
    }

    function _returnRemainder() internal {
        uint256 tokensLeft = token.balanceOf(address(this));
        uint256 ethLeft = address(this).balance;

        token.transfer(manager(), tokensLeft);
        payable(manager()).transfer(ethLeft);
    }

    function setSwapRouter(IUniswapV2Router02 _router) public onlyOwner {
        swapRouter = _router;
    }

    function claimable(address account) public view returns(uint256) {
        if (!finished)
            return 0;

        return (contributions[account] * tokenPrice) - claimed[account];
    }

    function claim() public nonReentrant {
        require(finished, 'not finished');

        uint256 amount = claimable(_msgSender());
        claimed[_msgSender()] += amount;
        token.transfer(_msgSender(), amount);

        emit Claim(_msgSender(), amount);
    }

    function refund() public nonReentrant {
        require(canceled && finished, 'not canceled');
        uint256 amount = contributions[_msgSender()] - claimed[_msgSender()];
        claimed[_msgSender()] += amount;
        payable(_msgSender()).transfer(amount);
        
        emit Claim(_msgSender(), amount);
    }

    function _cancel() internal {
        canceled = true;
        finished = true;

        token.transfer(manager(), token.balanceOf(address(this)));

        emit Cancel();
    }

    /**
     * Protection Methods in case Manager doesn't finish the sale.
     */
    uint256 public finishDeadline;
    event CallForFinish();

    function callForFinish() public {
        require(hasEnded(), 'Sales has not ended.');

        if (finishDeadline == 0) {
            finishDeadline = block.timestamp + 3600*48;
        }
        emit CallForFinish();
    }

    function emergencyCancel() public {
        require(finishDeadline > 0 && finishDeadline < block.timestamp, 'Call for finish first.');

        _cancel();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Managed.sol";

struct MetaInfoStruct {
    string logoUrl;
    string websiteUrl;
    string description;
}

contract MetaInfo is Managed {
    MetaInfoStruct public metaInfo;

    function setMetaInfo(
        MetaInfoStruct memory _meta
    ) public onlyOwnerAndManager {
        metaInfo = _meta;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Managed is Ownable {
    address private _manager;

    modifier onlyManager() {
        require(_msgSender() == _manager, 'onlyManager');
        _;
    }

    modifier onlyOwnerAndManager() {
        require(_msgSender() == _manager || _msgSender() == owner(), 'onlyOwnerAndManager');
        _;
    }

    constructor() {
        _manager = _msgSender();
    }

    event TransferManagement(address indexed account);

    function transferManagement(address account) public onlyOwnerAndManager {
        _manager = account;
        emit TransferManagement(account);
    }

    function revokeManagement() public onlyManager {
        transferManagement(address(0));
    }

    function manager() public view returns (address) {
        return _manager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Fees is Ownable {
    struct Fee {
        uint256 raisedPerc;
        uint256 tokensPerc;
    }

    Fee public fee = Fee({
        raisedPerc: 250,
        tokensPerc: 250
    });

    address public feeCollector;

    function _calcTokenFee(uint256 _amount) internal view returns (uint256) {
        return _amount * fee.tokensPerc / 10000;
    }

    function _calcRaisedFee(uint256 _amount) internal view returns (uint256) {
        return _amount * fee.raisedPerc / 10000;
    }

    function setFeeCollector(address account) public onlyOwner {
        feeCollector = account;
    }

    function setFees(uint256 _raisedPerc, uint256 _tokensPerc) public onlyOwner {
        fee.raisedPerc = _raisedPerc;
        fee.tokensPerc = _tokensPerc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

// You can add this typing "uniV2Router01" 
import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// https://uniswap.org/docs/v2/smart-contracts/factory/
// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.solimplementation
// SPDX-License-Identifier: MIT
// UniswapV2Factory is deployed at 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f on the Ethereum mainnet, and the Ropsten, Rinkeby, Görli, and Kovan testnets
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

