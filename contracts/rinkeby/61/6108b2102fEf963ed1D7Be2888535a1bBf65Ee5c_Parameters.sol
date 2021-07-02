/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/libraries/math/SafeMath.sol

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// File contracts/libraries/utils/Address.sol

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/interfaces/IParameters.sol

pragma solidity ^0.6.0;

abstract contract IParameters {
    function commit_transfer_ownership(address _owner) external virtual;

    function apply_transfer_ownership() external virtual;

    function setVault(address _token, address _vault) external virtual;

    function setLockup(address _address, uint256 _target) external virtual;

    function setGrace(address _address, uint256 _target) external virtual;

    function setMindate(address _address, uint256 _target) external virtual;

    function setPremium2(address _address, uint256 _target) external virtual;

    function setFee2(address _address, uint256 _target) external virtual;

    function setWithdrawable(address _address, uint256 _target)
        external
        virtual;

    function setPremiumModel(address _address, address _target)
        external
        virtual;

    function setFeeModel(address _address, address _target) external virtual;

    function setCondition(bytes32 _reference, bytes32 _target) external virtual;

    function getVault(address _token) external view virtual returns (address);

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view virtual returns (uint256);

    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view virtual returns (uint256);

    function getLockup() external view virtual returns (uint256);

    function getWithdrawable() external view virtual returns (uint256);

    function getGrace() external view virtual returns (uint256);

    function get_owner() public view virtual returns (address);

    function isOwner() public view virtual returns (bool);

    function getMin() external view virtual returns (uint256);

    function getFee2(uint256 _amount) external view virtual returns (uint256);

    function getPremium2(uint256 _amount)
        external
        view
        virtual
        returns (uint256);

    function getCondition(bytes32 _reference)
        external
        view
        virtual
        returns (bytes32);
}


// File contracts/interfaces/IPremiumModel.sol

pragma solidity ^0.6.0;

interface IPremiumModel {
    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}


// File contracts/interfaces/IFeeModel.sol

pragma solidity ^0.6.0;

interface IFeeModel {
    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view returns (uint256);
}


// File contracts/Parameters.sol

/**
 * @title Parameters
 * @author @kohshiba
 * @notice This contract manages parameters of markets.
 */

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;





contract Parameters is IParameters {
    using SafeMath for uint256;
    using Address for address;

    event CommitNewAdmin(uint256 deadline, address future_admin);
    event NewAdmin(address admin);

    address public owner;
    address public future_owner;
    uint256 public transfer_ownership_deadline;
    uint256 public constant ADMIN_ACTIONS_DELAY = 3 * 86400;

    mapping(address => address) private _vaults;
    mapping(address => address) private _fee;
    mapping(address => address) private _premium;
    mapping(address => uint256) private _fee2;
    mapping(address => uint256) private _premium2;
    mapping(address => uint256) private _grace;
    mapping(address => uint256) private _lockup;
    mapping(address => uint256) private _min;
    mapping(address => uint256) private _withdawable;
    mapping(bytes32 => bytes32) private _conditions;

    constructor(address _target) public {
        owner = _target;
    }

    function get_owner() public view override returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view override returns (bool) {
        return msg.sender == owner;
    }

    function commit_transfer_ownership(address _owner) external override {
        require(msg.sender == owner, "dev: only owner");
        require(transfer_ownership_deadline == 0, "dev: active transfer");

        uint256 _deadline = block.timestamp.add(ADMIN_ACTIONS_DELAY);
        transfer_ownership_deadline = _deadline;
        future_owner = _owner;

        emit CommitNewAdmin(_deadline, _owner);
    }

    function apply_transfer_ownership() external override {
        require(msg.sender == owner, "dev: only owner");
        require(
            block.timestamp >= transfer_ownership_deadline,
            "dev: insufficient time"
        );
        require(transfer_ownership_deadline != 0, "dev: no active transfer");

        transfer_ownership_deadline = 0;
        address _owner = future_owner;

        owner = _owner;

        emit NewAdmin(owner);
    }

    function setVault(address _token, address _vault)
        external
        override
        onlyOwner
    {
        require(_vaults[_token] == address(0), "dev: already initialized");
        _vaults[_token] = _vault;
    }

    function setLockup(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _lockup[_address] = _target;
    }

    function setGrace(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _grace[_address] = _target;
    }

    function setMindate(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _min[_address] = _target;
    }

    function setPremium2(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _premium2[_address] = _target;
    }

    function setFee2(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _fee2[_address] = _target;
    }

    function setWithdrawable(address _address, uint256 _target)
        external
        override
        onlyOwner
    {
        _withdawable[_address] = _target;
    }

    function setPremiumModel(address _address, address _target)
        external
        override
        onlyOwner
    {
        _premium[_address] = _target;
    }

    function setFeeModel(address _address, address _target)
        external
        override
        onlyOwner
    {
        _fee[_address] = _target;
    }

    function setCondition(bytes32 _reference, bytes32 _target)
        external
        override
        onlyOwner
    {
        _conditions[_reference] = _target;
    }

    function getVault(address _token) external view override returns (address) {
        if (_vaults[_token] == address(0)) {
            return address(0);
        } else {
            return _vaults[_token];
        }
    }

    function getPremium(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view override returns (uint256) {
        if (_premium[msg.sender] == address(0)) {
            return
                IPremiumModel(_premium[address(0)]).getPremium(
                    _amount,
                    _term,
                    _totalLiquidity,
                    _lockedAmount
                );
        } else {
            return
                IPremiumModel(_premium[msg.sender]).getPremium(
                    _amount,
                    _term,
                    _totalLiquidity,
                    _lockedAmount
                );
        }
    }

    function getFee(
        uint256 _amount,
        uint256 _term,
        uint256 _totalLiquidity,
        uint256 _lockedAmount
    ) external view override returns (uint256) {
        if (_fee[msg.sender] == address(0)) {
            return
                IFeeModel(_fee[address(0)]).getFee(
                    _amount,
                    _term,
                    _totalLiquidity,
                    _lockedAmount
                );
        } else {
            return
                IFeeModel(_fee[msg.sender]).getFee(
                    _amount,
                    _term,
                    _totalLiquidity,
                    _lockedAmount
                );
        }
    }

    function getFee2(uint256 _amount) external view override returns (uint256) {
        if (_fee2[msg.sender] == 0) {
            return _amount.mul(_fee2[address(0)]).div(100000);
        } else {
            return _amount.mul(_fee2[msg.sender]).div(100000);
        }
    }

    function getPremium2(uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        if (_premium2[msg.sender] == 0) {
            return _amount.mul(_premium2[address(0)]).div(100000);
        } else {
            return _amount.mul(_premium2[msg.sender]).div(100000);
        }
    }

    function getLockup() external view override returns (uint256) {
        if (_lockup[msg.sender] == 0) {
            return _lockup[address(0)];
        } else {
            return _lockup[msg.sender];
        }
    }

    function getWithdrawable() external view override returns (uint256) {
        if (_withdawable[msg.sender] == 0) {
            return _withdawable[address(0)];
        } else {
            return _withdawable[msg.sender];
        }
    }

    function getGrace() external view override returns (uint256) {
        if (_grace[msg.sender] == 0) {
            return _grace[address(0)];
        } else {
            return _grace[msg.sender];
        }
    }

    function getMin() external view override returns (uint256) {
        if (_min[msg.sender] == 0) {
            return _min[address(0)];
        } else {
            return _min[msg.sender];
        }
    }

    function getCondition(bytes32 _reference)
        external
        view
        override
        returns (bytes32)
    {
        return _conditions[_reference];
    }
}