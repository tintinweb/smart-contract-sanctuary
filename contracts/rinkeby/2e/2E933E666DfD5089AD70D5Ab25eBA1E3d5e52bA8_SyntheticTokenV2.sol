// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {IERC20} from "../token/IERC20.sol";

import {Adminable} from "../lib/Adminable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {Amount} from "../lib/Amount.sol";
import {Permittable} from "../token/Permittable.sol";

import {SyntheticStorageV2} from "./SyntheticStorageV2.sol";

contract SyntheticTokenV2 is Adminable, SyntheticStorageV2, IERC20, Permittable {

    using SafeMath for uint256;
    using Amount for Amount.Principal;

    /* ========== Events ========== */

    event MinterAdded(address _minter, uint256 _limit);

    event MinterRemoved(address _minter);

    event MinterLimitUpdated(address _minter, uint256 _limit);

    event InitCalled(
        string name,
        string symbol,
        string version
    );

    /* ========== Modifiers ========== */

    modifier onlyMinter() {
        require(
            _minters[msg.sender],
            "SyntheticTokenV2: only callable by minter"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor(
        string memory _name,
        string memory _version
    )
        Permittable(_name, _version)
        public
    { }

    /* ========== Init Function ========== */

/**
     * @dev Initialize the synthetic token
     *
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _version The version number of this token
     */
    function init(
        string memory _name,
        string memory _symbol,
        string memory _version
    )
        public
        onlyAdmin
    {
        require(
            !_initCalled,
            "SyntheticTokenV2: cannot be initialized twice"
        );

        name = _name;
        symbol = _symbol;
        version = _version;

        DOMAIN_SEPARATOR = _initDomainSeparator(_name, "1");

        _initCalled = true;

        emit InitCalled(
            _name,
            _symbol,
            _version
        );
    }

    /* ========== View Functions ========== */

    function decimals()
        external
        pure
        returns (uint8)
    {
        return 18;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function getAllMinters()
        external
        view
        returns (address[] memory)
    {
        return _mintersArray;
    }

    function isValidMinter(
        address _minter
    )
        external
        view
        returns (bool)
    {
        return _minters[_minter];
    }

    function getMinterIssued(
        address _minter
    )
        external
        view
        returns (Amount.Principal memory)
    {
        return _minterIssued[_minter];
    }

    function getMinterLimit(
        address _minter
    )
        external
        view
        returns (uint256)
    {
        return _minterLimits[_minter];
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Add a new minter to the synthetic token.
     *
     * @param _minter The address of the minter to add
     * @param _limit The starting limit for how much the minter can mint
     */
    function addMinter(
        address _minter,
        uint256 _limit
    )
        external
        onlyAdmin
    {
        require(
            _minters[_minter] != true,
            "SyntheticTokenV2: Minter already exists"
        );

        _mintersArray.push(_minter);
        _minters[_minter] = true;
        _minterLimits[_minter] = _limit;

        emit MinterAdded(_minter, _limit);
    }

    /**
     * @dev Remove a minter from the synthetic token
     *
     * @param _minter Address of the minter to remove
     */
    function removeMinter(
        address _minter
    )
        external
        onlyAdmin
    {
        require(
            _minters[_minter],
            "SyntheticTokenV2: not a minter"
        );

        for (uint256 i = 0; i < _mintersArray.length; i++) {
            if (_mintersArray[i] == _minter) {
                _mintersArray[i] = _mintersArray[_mintersArray.length - 1];
                _mintersArray.length--;

                break;
            }
        }

        delete _minters[_minter];
        delete _minterLimits[_minter];

        emit MinterRemoved(_minter);
    }

    /**
     * @dev Update the limit of the minter
     *
     * @param _minter The address of the minter to set
     * @param _limit The new limit to set for this address
     */
    function updateMinterLimit(
        address _minter,
        uint256 _limit
    )
        public
        onlyAdmin
    {
        require(
            _minters[_minter],
            "SyntheticTokenV2: minter does not exist"
        );

        require(
            _minterLimits[_minter] != _limit,
            "SyntheticTokenV2: cannot set the same limit"
        );

        _minterLimits[_minter] = _limit;

        emit MinterLimitUpdated(_minter, _limit);
    }

    /* ========== Minter Functions ========== */

    /**
     * @dev Mint synthetic tokens
     *
     * @notice Can only be called by a valid minter.
     *
     * @param _to The destination  to mint the synth to
     * @param _value The amount of synths to mint
     */
    function mint(
        address _to,
        uint256 _value
    )
        external
        onlyMinter
    {
        require(
            _value > 0,
            "SyntheticTokenV2: cannot mint zero"
        );

        Amount.Principal memory issuedAmount = _minterIssued[msg.sender].add(
            Amount.Principal({ sign: true, value: _value })
        );

        require(
            issuedAmount.value <= _minterLimits[msg.sender] || issuedAmount.sign == false,
            "SyntheticTokenV2: minter limit reached"
        );

        _minterIssued[msg.sender] = issuedAmount;
        _mint(_to, _value);
    }

    /**
     * @dev Burn synthetic tokens of the msg.sender
     *
     * @param _value The amount of the synth to destroy
     */
    function burn(
        uint256 _value
    )
        external
    {
        _burn(_value);
    }

    /**
     * @dev Burn synthetic tokens of the minter. Same as `burn()` but
     *      only callable by the minter. Used to record amounts issued
     *
     * @notice Can only be called by a valid minter
     *
     * @param _value The amount of the synth to destroy
     */
    function destroy(
        uint256 _value
    )
        external
        onlyMinter
    {
        _minterIssued[msg.sender] = _minterIssued[msg.sender].sub(
            Amount.Principal({ sign: true, value: _value })
        );

        _burn(_value);
    }

    /* ========== ERC20 Mutative Functions ========== */

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Allows `spender` to withdraw from msg.sender multiple times, up to the
     *      `amount`.
     *      Warning: It is recommended to first set the allowance to 0 before
     *      changing it, to prevent a double-spend exploit outlined below:
     *      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        require(
            _allowances[sender][msg.sender] >= amount,
            "SyntheticTokenV2: the amount has not been approved for this spender"
        );

        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );

        return true;
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * assuming the latter's signed approval.
     *
     * IMPORTANT: The same issues Erc20 `approve` has related to transaction
     * ordering also apply here.
     * In addition, please be aware that:
     * - If an owner signs a permit with no deadline, the corresponding spender
     *   can call permit at any time in the future to mess with the nonce,
     *   invalidating signatures to other spenders, possibly making their transactions
     *   fail.
     * - Even if only permits with finite deadline are signed, to avoid the above
     *   scenario, an owner would have to wait for the conclusion of the deadline
     *   to sign a permit for another spender.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future or zero.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     *   over the Eip712-formatted function arguments.
     * - The signature must use `owner`'s current nonce.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
    {
        _permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );

        _approve(owner, spender, value);
    }

    /* ========== Internal Functions ========== */

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
    {
        require(
            _sender != address(0),
            "SyntheticTokenV2: transfer from the zero address"
        );

        require(
            _recipient != address(0),
            "SyntheticTokenV2: transfer to the zero address"
        );

        require(
            _balances[_sender] >= _amount,
            "SyntheticTokenV2: sender does not have enough balance"
        );

        _balances[_sender]      = _balances[_sender].sub(_amount);
        _balances[_recipient]   = _balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(
        address _account,
        uint256 _amount
    )
        internal
    {
        require(
            _account != address(0),
            "SyntheticTokenV2: cannot mint to the zero address"
        );

        _totalSupply = _totalSupply.add(_amount);

        _balances[_account] = _balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(
        uint256 _value
    )
        internal
    {
        require(
            _balances[msg.sender] >= _value,
            "SyntheticTokenV2: cannot destroy more tokens than the balance"
        );

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);

        emit Transfer(msg.sender, address(0), _value);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        require(
            _owner != address(0),
            "SyntheticTokenV2: approve from the zero address"
        );

        require(
            _spender != address(0),
            "SyntheticTokenV2: approve to the zero address"
        );

        _allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { Storage } from "./Storage.sol";

/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "../lib/Math.sol";

library Amount {

    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // A Principal Amount is an amount that's been adjusted by an index

    struct Principal {
        bool sign; // true if positive
        uint256 value;
    }

    function zero()
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: false,
            value: 0
        });
    }

    function sub(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        return add(a, negative(b));
    }

    function add(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        Principal memory result;

        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Principal memory a
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: !a.sign,
            value: a.value
        });
    }

    function calculateAdjusted(
        Principal memory a,
        uint256 index
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(a.value, index, BASE);
    }

    function calculatePrincipal(
        uint256 value,
        uint256 index,
        bool sign
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: sign,
            value: Math.getPartial(value, BASE, index)
        });
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

contract Permittable {

    /* ============ Variables ============ */

    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public nonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* solium-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    constructor(
        string memory name,
        string memory version
    )
        public
    {
        DOMAIN_SEPARATOR = _initDomainSeparator(name, version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _initDomainSeparator(
        string memory name,
        string memory version
    )
        internal
        view
        returns (bytes32)
    {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(
            deadline == 0 || deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    nonces[owner]++,
                    deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "Permittable: Signature invalid"
        );

    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import {Amount} from "../lib/Amount.sol";

contract SyntheticStorageV2 {

    bool internal _initCalled;

    /**
     * @dev ERC20 Properties
     */
    string  public      name;
    string  public      symbol;
    string  public      version;
    uint256 internal    _totalSupply;

    /**
     * @dev _balances records the amounts minted to each user by each minter
     */
    mapping (address => uint256)                        internal _balances;
    mapping (address => mapping (address => uint256))   internal _allowances;

    /**
     * @dev Minter Properties
     */
    address[]                               internal _mintersArray;
    mapping(address => bool)                internal _minters;
    mapping(address => uint256)             internal _minterLimits;
    mapping(address => Amount.Principal)    internal _minterIssued;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";

/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 BASE = 10**18;
        uint256 basedAmount = a.mul(BASE.mul(10));

        return basedAmount
            .div(b)
            .add(5)
            .div(10);
    }

    /**
     * @dev Performs _a * _b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        uint256 BASE = 10**18;
        return a
            .mul(b)
            .add(BASE)
            .div(BASE);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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