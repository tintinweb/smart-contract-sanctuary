/**
 *Submitted for verification at Etherscan.io on 2021-03-13
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

// File: contracts/CrowdPooling/intf/ICP.sol


interface ICP {
    function init(
        address[] calldata addressList,
        uint256[] calldata timeLine,
        uint256[] calldata valueList,
        bool isOpenTWAP
    ) external;

    function bid(address to) external;

    function cancel(address assetTo, uint256 amount) external;

    function settle() external;

    function emergencySettle() external;

    function claimBase() external;

    function claimQuote() external;

    function claimLPToken() external;
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
}

// File: contracts/Factory/UpCrowdPoolingFactory.sol



/**
 * @title UpCrowdPoolingFacotry
 * @author DODO Breeder
 *
 * @notice Create And Register vary price CP Pools 
 */
contract UpCrowdPoolingFactory is InitializableOwnable {
    using SafeMath for uint256;
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public immutable _DVM_FACTORY_;
    address public immutable _DEFAULT_MAINTAINER_;
    address public immutable _DEFAULT_MT_FEE_RATE_MODEL_;
    address public immutable _DEFAULT_PERMISSION_MANAGER_;
    address public _CP_TEMPLATE_;

    // ============ Settings =============
    uint256 public _FREEZE_DURATION_ =  30 days;
    uint256 public _CALM_DURATION_ = 0;
    uint256 public _VEST_DURATION_ = 0;
    uint256 public _CLIFF_RATE_ = 10**18;


    // ============ Registry ============

    // base -> quote -> CP address list
    mapping(address => mapping(address => address[])) public _REGISTRY_;
    // creator -> CP address list
    mapping(address => address[]) public _USER_REGISTRY_;

    // ============ modifiers ===========

    modifier valueCheck(
        address cpAddress,
        address baseToken,
        uint256[] memory timeLine,
        uint256[] memory valueList)
    {
        require(timeLine[2] <= _CALM_DURATION_, "CP_FACTORY : PHASE_CALM_DURATION_INVALID");
        require(timeLine[4] == _VEST_DURATION_, "CP_FACTORY : VEST_DURATION_INVALID");
        require(valueList[3] == _CLIFF_RATE_, "CP_FACTORY : CLIFF_RATE_INVALID");
        require(timeLine[3] >= _FREEZE_DURATION_, "CP_FACTORY : FREEZE_DURATION_INVALID");
        _;
    }

    // ============ Events ============

    event NewCP(
        address baseToken,
        address quoteToken,
        address creator,
        address cp
    );

    constructor(
        address cloneFactory,
        address cpTemplate,
        address dvmFactory,
        address defaultMaintainer,
        address defaultMtFeeRateModel,
        address defaultPermissionManager
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _CP_TEMPLATE_ = cpTemplate;
        _DVM_FACTORY_ = dvmFactory;
        _DEFAULT_MAINTAINER_ = defaultMaintainer;
        _DEFAULT_MT_FEE_RATE_MODEL_ = defaultMtFeeRateModel;
        _DEFAULT_PERMISSION_MANAGER_ = defaultPermissionManager;
    }

    // ============ Functions ============

    function createCrowdPooling() external returns (address newCrowdPooling) {
        newCrowdPooling = ICloneFactory(_CLONE_FACTORY_).clone(_CP_TEMPLATE_);
    }

    function initCrowdPooling(
        address cpAddress,
        address creator,
        address baseToken,
        address quoteToken,
        uint256[] memory timeLine,
        uint256[] memory valueList,
        bool isOpenTWAP
    ) external valueCheck(cpAddress,baseToken,timeLine,valueList) {
        {
        address[] memory addressList = new address[](7);
        addressList[0] = creator;
        addressList[1] = _DEFAULT_MAINTAINER_;
        addressList[2] = baseToken;
        addressList[3] = quoteToken;
        addressList[4] = _DEFAULT_PERMISSION_MANAGER_;
        addressList[5] = _DEFAULT_MT_FEE_RATE_MODEL_;
        addressList[6] = _DVM_FACTORY_;

        if(valueList[0] == 0) valueList[0] = uint112(-1);

        ICP(cpAddress).init(
            addressList,
            timeLine,
            valueList,
            isOpenTWAP
        );
        }

        _REGISTRY_[baseToken][quoteToken].push(cpAddress);
        _USER_REGISTRY_[creator].push(cpAddress);

        emit NewCP(baseToken, quoteToken, creator, cpAddress);
    }

    // ============ View Functions ============

    function getCrowdPooling(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory pools)
    {
        return _REGISTRY_[baseToken][quoteToken];
    }

    function getCrowdPoolingBidirection(address token0, address token1)
        external
        view
        returns (address[] memory baseToken0Pools, address[] memory baseToken1Pools)
    {
        return (_REGISTRY_[token0][token1], _REGISTRY_[token1][token0]);
    }

    function getCrowdPoolingByUser(address user)
        external
        view
        returns (address[] memory pools)
    {
        return _USER_REGISTRY_[user];
    }

    // ============ Owner Functions ============
    
    function updateCPTemplate(address _newCPTemplate) external onlyOwner {
        _CP_TEMPLATE_ = _newCPTemplate;
    }

    function setFreezeDuration(uint256 _newFreeDuration) public onlyOwner {
        _FREEZE_DURATION_ = _newFreeDuration;
    }

    function setCalmDuration(uint256 _newCalmDuration) public onlyOwner {
        _CALM_DURATION_ = _newCalmDuration;
    }

    function setVestDuration(uint256 _newVestDuration) public onlyOwner {
        _VEST_DURATION_ = _newVestDuration;
    }

    function setCliffRate(uint256 _newCliffRate) public onlyOwner {
        require(_newCliffRate <= 10**18, "CP_FACTORY : INVALID");
        _CLIFF_RATE_ = _newCliffRate;
    }
}