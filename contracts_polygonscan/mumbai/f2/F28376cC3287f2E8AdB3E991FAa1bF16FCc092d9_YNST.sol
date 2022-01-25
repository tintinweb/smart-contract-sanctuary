// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../../../TC/token/TCERC20.sol";

contract YNST is TCERC20 {
    event AccountWhitelisted(address indexed account);

    mapping(address => bool) _whitelisted;

    function __YNST_init() public initializer {
        __TERC20_init(
            // name
            "YNST - Ynsitu",
            // symbol
            "YNST",
            // instantSwapOperatorAddress
            0x24C12056244425eF56d0a503df60E033C1bf84E0
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override returns (bool) {
        require(_whitelisted[to], "user is not whitelisted");
        return super._transfer(from, to, amount);
    }

    function _whitelistUser(address account) internal {
        _whitelisted[account] = true;
        emit AccountWhitelisted(account);
    }

    function whitelistAndTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner {
        _whitelistUser(to);
        _transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../access/UOwnable.sol";
import "./IERC20.sol";
import "../instantSwap/IERC20Swappable.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author TokenCity

abstract contract TCERC20 is UOwnable, IERC20Swappable, IERC20 {
    string public name;
    string public symbol;
    uint8 public constant override decimals = 18;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    address public instantSwapOperator;

    modifier onlyInstantSwapOperator() {
        require(
            msg.sender == instantSwapOperator,
            "ERC20Swappable: Not allowed"
        );
        _;
    }

    function __TERC20_init(
        string memory name_,
        string memory symbol_,
        address instantSwapOperator_
    ) internal initializer {
        __Ownable_init();
        name = name_;
        symbol = symbol_;
        instantSwapOperator = instantSwapOperator_;
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        allowance[_msgSender()][spender] = amount;

        emit Approval(_msgSender(), spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return _transfer(_msgSender(), to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 allowed = allowance[from][_msgSender()];

        if (allowed != type(uint256).max)
            allowance[from][_msgSender()] = allowed - amount;

        return _transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address to, uint256 amount) public virtual onlyOwner {
        _burn(to, amount);
    }

    function instantSwapTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external override onlyInstantSwapOperator {
        _transfer(from, to, amount);
    }

    function setInstantSwapOperator(address newOperator_)
        external
        override
        onlyInstantSwapOperator
    {
        emit InstantSwapOperatorChanged(instantSwapOperator, newOperator_);
        instantSwapOperator = newOperator_;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../openzeppelin/metatx/ERC2771Context.sol";

abstract contract UOwnable is ERC2771Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function __Ownable_init() internal initializer {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Contract that allows instant swaps int TC
interface IERC20Swappable {
    event InstantSwapOperatorChanged(
        address previousOperator,
        address newOperator
    );

    function instantSwapTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function setInstantSwapOperator(address newOperator_) external;
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
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context {
    address private _trustedForwarder;

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}