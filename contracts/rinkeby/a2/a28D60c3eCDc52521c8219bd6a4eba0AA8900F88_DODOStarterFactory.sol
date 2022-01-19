/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/CloneFactory.sol


interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/lib/SafeMath.sol



/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/intf/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeERC20.sol



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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/DecimalMath.sol



/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e.div(2));
            p = p.mul(p) / (10**18);
            if (e % 2 == 1) {
                p = p.mul(target) / (10**18);
            }
            return p;
        }
    }
}

// File: contracts/DODOStarter/intf/IDODOStarter.sol


interface IDODOStarter {
    //Instant mode
    function init(
        address[] calldata addressList,
        uint256[] calldata timeLine,
        uint256[] calldata valueList
    ) external;

    //Fair mode
    function init(
        address[] calldata addressList,
        uint256[] calldata timeLine,
        uint256[] calldata valueList,
        bool isOverCapStop
    ) external;

    function _FUNDS_ADDRESS_() external view returns (address);

    function depositFunds(address to) external returns (uint256);
}

// File: contracts/Factory/DODOStarterFactory.sol



/**
 * @title DODOStarterFactory
 * @author DODO Breeder
 *
 * @notice Create And Register DODOStarter Pools 
 */
contract DODOStarterFactory is InitializableOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public _FAIR_FUND_TEMPLATE_;
    address public _INSTANT_FUND_TEMPLATE_;

    mapping(address => address) fundingWhitelist;

    // ============ Registry ============
    // baseToken -> fundToken ->  fair Pool list
    mapping(address => mapping(address => address[])) public _FAIR_REGISTRY_;
    // baseToken -> fundToken ->  Instant Pool list
    mapping(address => mapping(address => address[])) public _INSTANT_REGISTRY_;

    // ============ Events ============
    event NewFairFund(
        address baseToken,
        address fundToken,
        address creator,
        address fairFundPool
    );

    event NewInstantFund(
        address baseToken,
        address fundToken,
        address creator,
        address instantFundPool
    );

    event SetWhitelist(address creator, address baseToken);
    event UpdateFairFundTempalte(address newTemplate);
    event UpdateInstantFundTempalte(address newTemplate);

    // ============ modifiers ===========

    modifier permissionCheck(address creator, address baseToken) {
        require(fundingWhitelist[creator] == baseToken || msg.sender == _OWNER_, "NO_PERMISSION");
        _;
    }

    constructor(
        address cloneFactory,
        address fairFundTemplate,
        address instantFundTemplate
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _FAIR_FUND_TEMPLATE_ = fairFundTemplate;
        _INSTANT_FUND_TEMPLATE_ = instantFundTemplate;
    }

    // ============ Functions ============
    function createFairFund(
        address[] memory addressList,
        uint256[] memory timeLine,
        uint256[] memory valueList,
        uint256 sellTokenAmount,
        bool isOverCapStop
    ) external payable permissionCheck(addressList[0],addressList[1]) returns(address newFairFundPool){
        newFairFundPool = ICloneFactory(_CLONE_FACTORY_).clone(_FAIR_FUND_TEMPLATE_);

        IERC20(addressList[1]).safeTransferFrom(msg.sender, newFairFundPool,sellTokenAmount);
        (bool success, ) = newFairFundPool.call{value: msg.value}("");
        require(success, "Settle fund Transfer failed");

        IDODOStarter(newFairFundPool).init(
            addressList,
            timeLine,
            valueList,
            isOverCapStop
        );

        _FAIR_REGISTRY_[addressList[1]][addressList[2]].push(newFairFundPool);

        emit NewFairFund(addressList[1], addressList[2], addressList[0], newFairFundPool);
    }

    function createInstantFund(
        address[] memory addressList,
        uint256[] memory timeLine,
        uint256[] memory valueList,
        uint256 sellTokenAmount
    ) external permissionCheck(addressList[0],addressList[1]) returns(address newInstantFundPool){
        newInstantFundPool = ICloneFactory(_CLONE_FACTORY_).clone(_INSTANT_FUND_TEMPLATE_);

        IERC20(addressList[1]).safeTransferFrom(msg.sender, newInstantFundPool,sellTokenAmount);
        
        IDODOStarter(newInstantFundPool).init(
            addressList,
            timeLine,
            valueList
        );

        _INSTANT_REGISTRY_[addressList[1]][addressList[2]].push(newInstantFundPool);

        emit NewInstantFund(addressList[1], addressList[2], addressList[0], newInstantFundPool);
    }

    // ============ View Functions ============

    function getFairFundPools(address baseToken, address fundToken)
        external
        view
        returns (address[] memory pools)
    {
        return _FAIR_REGISTRY_[baseToken][fundToken];
    }

    function getFairFundPoolsBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Pools, address[] memory baseToken1Pools)
    {
        return (_FAIR_REGISTRY_[token0][token1], _FAIR_REGISTRY_[token1][token0]);
    }

    function getInstantFundPools(address baseToken, address fundToken)
        external
        view
        returns (address[] memory pools)
    {
        return _INSTANT_REGISTRY_[baseToken][fundToken];
    }

    function getInstantFundPoolsBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Pools, address[] memory baseToken1Pools)
    {
        return (_INSTANT_REGISTRY_[token0][token1], _INSTANT_REGISTRY_[token1][token0]);
    }


    // ============ Owner Functions ============

    function setWhitelist(address creator, address baseToken) external onlyOwner {
        fundingWhitelist[creator] = baseToken;
        emit SetWhitelist(creator, baseToken);
    }
    
    function updateFairFundTemplate(address _newFairFundTemplate) external onlyOwner {
        _FAIR_FUND_TEMPLATE_ = _newFairFundTemplate;
        emit UpdateFairFundTempalte(_newFairFundTemplate);
    }

    function updateInstantFundTemplate(address _newInstantFundTemplate) external onlyOwner {
        _INSTANT_FUND_TEMPLATE_ = _newInstantFundTemplate;
        emit UpdateInstantFundTempalte(_newInstantFundTemplate);
    }

}