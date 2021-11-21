// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

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

pragma solidity 0.8.4;

import { Ownable } from "./Ownable.sol";

abstract contract Mintable is Ownable {
    mapping(address => bool) public isMinter;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Mintable: caller is not a minter");
        _;
    }

    function addToMinters(address minter) external onlyOwner {
        require(!isMinter[minter], "Mintable: address is already a minter");
        isMinter[minter] = true;
        emit MinterAdded(minter);
    }

    function removeFromMinters(address minter) external onlyOwner {
        require(isMinter[minter], "Mintable: address is not a minter");
        isMinter[minter] = false;
        emit MinterRemoved(minter);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import { Initializable } from "./Initializable.sol";
import { Mintable } from "./Mintable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";

contract SquidMoon is Initializable, Mintable, IERC20 {
    string public override name;
    string public override symbol;

    uint8 public immutable override decimals = 18;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public transferFee;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public initializer {
        name = _name;
        symbol = _symbol;
        _mint(msg.sender, _initialSupply);
        _transferOwnership(msg.sender);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMinter {
        _burn(from, amount);
    }

    function updateTransferFee(uint256 _transferFee) external onlyOwner {
        require(_transferFee <= 1e17, "max transfer fee is 1e17");
        transferFee = _transferFee;
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal {
        emit Approval(from, spender, allowance[from][spender] = amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 toBurn = (amount * transferFee) / 1e18;
        uint256 amountAfterFee = amount - toBurn;

        _burn(from, toBurn);
        balanceOf[from] -= amountAfterFee;
        balanceOf[to] += amountAfterFee;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address owner, uint256 amount) internal {
        balanceOf[owner] -= amount;
        totalSupply -= amount;

        emit Transfer(owner, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
    /**
     * @dev Emits an event indicating that tokens have moved from one account to another.
     * @param from  Account that tokens have moved from.
     * @param to    Account that tokens have moved to.
     * @param amount Amount of tokens that have been transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emits an event indicating that one account has set the allowance of another account over their tokens.
     * @param owner   Account that tokens are approved from.
     * @param spender Account that tokens are approved for.
     * @param amount  Amount of tokens that have been approved.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimal precision used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev   Returns the amount of tokens owned by a given account.
     * @param account Account that owns the tokens.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev   Function that returns the allowance that one account has given another over their tokens.
     * @param owner   Account that tokens are approved from.
     * @param spender Account that tokens are approved for.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev   Function that allows one account to set the allowance of another account over their tokens.
     * @dev   Emits an {Approval} event.
     * @param spender Account that tokens are approved for.
     * @param amount  Amount of tokens that have been approved.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev   Moves an amount of tokens from `msg.sender` to a specified account.
     * @dev   Emits a {Transfer} event.
     * @param recipient Account that recieves tokens.
     * @param amount    Amount of tokens that are transferred.
     * @return          Boolean amount indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev   Moves a pre-approved amount of tokens from a sender to a specified account.
     * @dev   Emits a {Transfer} event.
     * @dev   Emits an {Approval} event.
     * @param owner     Account that tokens are moving from.
     * @param recipient Account that recieves tokens.
     * @param amount    Amount of tokens that are transferred.
     */
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (bool);
}