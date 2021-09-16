/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


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

// File: contracts/lib/InitializableOwnable.sol


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

// File: contracts/external/ERC20/InitializableInternalMintableERC20.sol


contract InitializableInternalMintableERC20 is InitializableOwnable {
    using SafeMath for uint256;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Mint(address indexed user, uint256 value);
    event Burn(address indexed user, uint256 value);

    function init(
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        initOwner(_creator);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initSupply;
        balances[_creator] = _initSupply;
        emit Transfer(address(0), _creator, _initSupply);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        require(to != address(0), "TO_ADDRESS_IS_EMPTY");
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function _mint(address user, uint256 value) internal {
        balances[user] = balances[user].add(value);
        totalSupply = totalSupply.add(value);
        emit Mint(user, value);
        emit Transfer(address(0), user, value);
    }

    function _burn(address user, uint256 value) internal {
        balances[user] = balances[user].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }
}

// File: contracts/NFTPool/intf/IController.sol


interface IController {
    function getMintFeeRate(address filterAdminAddr) external view returns (uint256);

    function getBurnFeeRate(address filterAdminAddr) external view returns (uint256);

    function isEmergencyWithdrawOpen(address filter) external view returns (bool);
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
            return 1;
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

// File: contracts/NFTPool/impl/FilterAdmin.sol



contract FilterAdmin is InitializableInternalMintableERC20 {
    using SafeMath for uint256;

    // ============ Storage ============
    address[] public _FILTERS_;
    mapping(address => bool) public _FILTER_REGISTRY_;
    uint256 public _FEE_RATE_;
    address public _CONTROLLER_;
    address public _MAINTAINER_;
    uint256 public _INIT_SUPPLY_;

    // ============ Event ============
    event ChangeFeeRate(uint256 fee);
    event AddFilter(address filter);
    event FilterAdminInit(address owner, uint256 feeRate);

    function init(
        address owner,
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint256 feeRate,
        address controller,
        address maintainer,
        address[] memory filters
    ) external {
        super.init(owner, initSupply, name, symbol, 18);
        _INIT_SUPPLY_ = initSupply;
        _FEE_RATE_ = feeRate;
        _CONTROLLER_ = controller;
        _MAINTAINER_ = maintainer;
        _FILTERS_ = filters;
        for (uint256 i = 0; i < filters.length; i++) {
            _FILTER_REGISTRY_[filters[i]] = true;
        }

        emit FilterAdminInit(owner, feeRate);
    }

    function mintFragTo(address to, uint256 rawAmount) external returns (uint256) {
        require(isRegisteredFilter(msg.sender), "FILTER_NOT_REGISTERED");

        (uint256 poolFee, uint256 mtFee, uint256 received) = queryMintFee(rawAmount);
        if (poolFee > 0) _mint(_OWNER_, poolFee);
        if (mtFee > 0) _mint(_MAINTAINER_, mtFee);

        _mint(to, received);
        return received;
    }

    function burnFragFrom(address from, uint256 rawAmount) external returns (uint256) {
        require(isRegisteredFilter(msg.sender), "FILTER_NOT_REGISTERED");

        (uint256 poolFee, uint256 mtFee, uint256 paid) = queryBurnFee(rawAmount);
        if (poolFee > 0) _mint(_OWNER_, poolFee);
        if (mtFee > 0) _mint(_MAINTAINER_, mtFee);

        _burn(from, paid);
        return paid;
    }

    //================ View ================
    function queryMintFee(uint256 rawAmount)
        public
        returns (
            uint256 poolFee,
            uint256 mtFee,
            uint256 afterChargedAmount
        )
    {
        uint256 mtFeeRate = IController(_CONTROLLER_).getMintFeeRate(address(this));
        poolFee = DecimalMath.mulFloor(rawAmount, _FEE_RATE_);
        mtFee = DecimalMath.mulFloor(rawAmount, mtFeeRate);
        afterChargedAmount = rawAmount.sub(poolFee).sub(mtFee);
    }

    function queryBurnFee(uint256 rawAmount)
        public
        returns (
            uint256 poolFee,
            uint256 mtFee,
            uint256 afterChargedAmount
        )
    {
        uint256 mtFeeRate = IController(_CONTROLLER_).getBurnFeeRate(address(this));
        poolFee = DecimalMath.mulFloor(rawAmount, _FEE_RATE_);
        mtFee = DecimalMath.mulFloor(rawAmount, mtFeeRate);
        afterChargedAmount = rawAmount.add(poolFee).add(mtFee);
    }

    function isRegisteredFilter(address filter) public view returns (bool) {
        return _FILTER_REGISTRY_[filter];
    }

    function getFilters() public view returns (address[] memory) {
        return _FILTERS_;
    }

    //================= Owner ================
    function addFilter(address[] memory filters) external onlyOwner {
        for(uint256 i = 0; i < filters.length; i++) {
            require(!isRegisteredFilter(filters[i]), "FILTER_ALREADY_EXIST");
            _FILTERS_.push(filters[i]);
            _FILTER_REGISTRY_[filters[i]] = true;
            emit AddFilter(filters[i]);
        }
    }

    function changeFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= DecimalMath.ONE, "FEE_RATE_TOO_LARGE");
        _FEE_RATE_ = newFeeRate;
        emit ChangeFeeRate(newFeeRate);
    }

    //================= Support ================
    function version() external pure virtual returns (string memory) {
        return "FILTER ADMIN 1.0.0";
    }
}