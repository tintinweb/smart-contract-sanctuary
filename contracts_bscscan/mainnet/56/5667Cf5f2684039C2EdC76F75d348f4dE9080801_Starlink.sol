// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./base/access/AccessControlled.sol";
import "./base/token/BEP20/IBEP20.sol";
import "./pools/base/IStarlinkPool.sol";
import "./IDepositable.sol";

contract Starlink is AccessControlled, IDepositable  {
    IStarlinkPool[] public pools;
    mapping(address => uint256) public poolIndexByAddress;
    mapping(address => uint256) public tokensPendingDisburse;

    uint256 public updatePoolIndex;
    address payable public xld;

    constructor(address payable _xld) {
        xld = _xld;
    }

    function addPool(address poolAddress) public onlyAdmins {
        require(!poolExists(address(poolAddress)), "Starlink: Pool already exists");

        pools.push(IStarlinkPool(poolAddress));
        poolIndexByAddress[poolAddress] = pools.length - 1;
        
        address outTokenAddress = IStarlinkPool(poolAddress).outTokenAddress();
        if (outTokenAddress != address(0)) {
            IBEP20(outTokenAddress).approve(poolAddress, ~uint256(0));
        }
    }

    function deletePool(address poolAddress) public onlyAdmins {
        require(poolExists(poolAddress), "Starlink: Pool does not exist");

        uint256 index = poolIndexByAddress[poolAddress];

        if (index < pools.length - 1) {
            // Replace with last one
            IStarlinkPool lastPool = pools[pools.length - 1];
            pools[index] = lastPool;
            poolIndexByAddress[address(lastPool)] = index;
        }
        
        // Delete
        delete poolIndexByAddress[poolAddress];
        pools.pop();

        address outTokenAddress = IStarlinkPool(poolAddress).outTokenAddress();
        if (outTokenAddress != address(0)) {
            IBEP20(outTokenAddress).approve(poolAddress, 0);
        }
    }

    function poolExists(address poolAddress) public view returns(bool) {
        return pools.length > 0 && address(pools[poolIndexByAddress[poolAddress]]) == poolAddress;
    }


    function deposit(address tokenAddress, uint256 amount) external override payable onlyAdmins {
        if (amount > 0) {
            IBEP20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }
    }

    function processFunds(uint256 gas) external onlyAdmins {
        if (pools.length == 0) {
            return;
        }

        uint256 fundsPerPool = address(this).balance / pools.length;

        uint256 gasUsed;
		uint256 gasLeft = gasleft();
		uint256 iteration;
        uint256 poolIndex = updatePoolIndex; //Save gas by updating storage only once

        while(gasUsed < gas && iteration < pools.length) {
            if (poolIndex >= pools.length) {
                poolIndex = 0;
            }

           unchecked {
                IStarlinkPool pool = pools[poolIndex];
                pool.deposit{value: fundsPerPool}(IBEP20(pool.outTokenAddress()).balanceOf(address(this)), gas - gasUsed);

                uint256 newGasLeft = gasleft();

                if (gasLeft > newGasLeft) {
                    gasUsed += gasLeft - newGasLeft;
                    gasLeft = newGasLeft;
                }

                iteration++;
                poolIndex++;
            }
        }

        updatePoolIndex = poolIndex;
    }

    function poolInfos(uint256 index) external view returns(PoolInfo memory) {
        IStarlinkPool pool = pools[index];
        return PoolInfo(address(pool), pool.outTokenAddress(), pool.inTokenAddress(), pool.amountOut(), pool.amountIn(), pool.totalDividends(), pool.totalDividendPoints(), 
            pool.starlinkPointsPerToken(), pool.isStakingEnabled(), pool.earlyUnstakingFeeDuration(), pool.unstakingFeeMagnitude());
    }

    function totalValueOf(address user) external view returns(uint256, uint256) {
        uint256 totalUnclaimedValue;
        uint256 totalValueClaimed;

        for(uint i = 0; i < pools.length; i++) {
            totalUnclaimedValue += pools[i].unclaimedValueOf(user);
            totalValueClaimed += pools[i].totalValueClaimed(user);
        }

        return (totalValueClaimed, totalUnclaimedValue);
    }

    function poolsLength() external view returns(uint256) {
        return pools.length;
    }

    struct PoolInfo {
        address poolAddress;
        address outTokenAddress;
        address inTokenAddress;
        uint256 amountOut;
        uint256 amountIn;
        uint256 totalDividends;
        uint256 totalDividendPoints;
        uint16 starlinkPointsPerToken;
        bool isStakingEnabled;
        uint256 earlyUnstakingFeeDuration;
        uint16 unstakingFeeMagnitude;
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent calls to a function.
 */
abstract contract AccessControlled {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address private _owner;
    bool private _isPaused;
    mapping(address => bool) private _admins;
    mapping(address => bool) private _authorizedContracts;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _status = _NOT_ENTERED;
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        setAdmin(_owner, true);
        setAdmin(address(this), true);
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "AccessControlled: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "AccessControlled: contract not allowed");
        require(msg.sender == tx.origin, "AccessControlled: proxy contract not allowed");
        _;
    }

    modifier notUnauthorizedContract() {
        if (!_authorizedContracts[msg.sender]) {
            require(!_isContract(msg.sender), "AccessControlled: unauthorized contract not allowed");
            require(msg.sender == tx.origin, "AccessControlled: unauthorized proxy contract not allowed");
        }
        _;
    }

    modifier isNotUnauthorizedContract(address addr) {
        if (!_authorizedContracts[addr]) {
            require(!_isContract(addr), "AccessControlled: contract not allowed");
        }
        
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "AccessControlled: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by a non-admin account
     */
    modifier onlyAdmins() {
        require(_admins[msg.sender], "AccessControlled: caller does not have permission");
        _;
    }

    modifier notPaused() {
        require(!_isPaused, "AccessControlled: paused");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function setAdmin(address addr, bool _isAdmin) public onlyOwner {
        _admins[addr] = _isAdmin;
    }

    function isAdmin(address addr) public view returns(bool) {
        return _admins[addr];
    }

    function setAuthorizedContract(address addr, bool isAuthorized) public onlyOwner {
        _authorizedContracts[addr] = isAuthorized;
    }

    function pause() public onlyOwner {
        _isPaused = true;
    }

    function unpause() public onlyOwner {
        _isPaused = false;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStarlinkPool {
    function outTokenAddress() external view returns (address);

    function inTokenAddress() external view returns (address);

    function amountIn() external view returns(uint256);

    function amountOut() external view returns(uint256);

    function totalDividends() external view returns(uint256);

    function totalDividendPoints() external view returns(uint256);

    function starlinkPointsPerToken() external view returns(uint16);

    function isStakingEnabled() external view returns(bool);

    function earlyUnstakingFeeDuration() external view returns(uint256);

    function unstakingFeeMagnitude() external view returns(uint16);

    function unclaimedValueOf(address userAddress) external view returns (uint256);

    function totalValueClaimed(address userAddress) external view returns(uint256);

    function deposit(uint256 amount, uint256 gas) external payable;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IDepositable {
    function deposit(address token, uint256 amount) external payable;
}

