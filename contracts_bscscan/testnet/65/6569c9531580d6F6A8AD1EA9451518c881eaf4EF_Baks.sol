// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import {BaseToken, MinterZeroAddress} from "./BaseToken.sol";
import {Governed} from "./Governance.sol";
import "./interfaces/IEIP2612.sol";

contract Baks is Governed, BaseToken {
    event MinterChanged(address indexed minter, address indexed newMinter);

    constructor(address minter) BaseToken("Baks", "BAKS", 18, "1", minter) {}

    function setMinter(address newMinter) external onlyGovernor {
        if (newMinter == address(0)) {
            revert MinterZeroAddress();
        }
        minter = newMinter;
        emit MinterChanged(minter, newMinter);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import {IMintableAndBurnableERC20} from "./interfaces/IERC20.sol";
import "./interfaces/IEIP2612.sol";

error ApproveFromZeroAddress(address spender, uint256 amount);
error ApproveToZeroAddress(address owner, uint256 amount);

error MintToZeroAddress(uint256 amount);

error BurnFromZeroAddress(uint256 amount);
error BurnAmountExceedsBalance(address from, uint256 amount, uint256 balance);

error TransferFromZeroAddress(address to, uint256 amount);
error TransferToZeroAddress(address from, uint256 amount);
error TransferAmountExceedsAllowance(address from, address to, uint256 amount, uint256 allowance);
error TransferAmountExceedsBalance(address from, address to, uint256 amount, uint256 balance);

error MinterZeroAddress();
error OnlyMinterAllowed();

error EIP2612PermissionExpired(uint256 deadline);
error EIP2612InvalidSignature(address owner, address signer);

contract BaseToken is IMintableAndBurnableERC20, IEIP2612 {
    bytes32 private constant EIP_712_DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPE_HASH =
        keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");

    string public override name;
    string public override symbol;
    uint8 public override decimals;
    string public version;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    address public minter;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable override DOMAIN_SEPARATOR;
    mapping(address => uint256) public override nonces;

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert OnlyMinterAllowed();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _version,
        address _minter
    ) {
        if (_minter == address(0)) {
            revert MinterZeroAddress();
        }
        minter = _minter;

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        version = _version;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP_712_DOMAIN_TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (from != msg.sender) {
            uint256 _allowance = allowance[from][msg.sender];
            if (_allowance < amount) {
                revert TransferAmountExceedsAllowance(from, to, amount, _allowance);
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override onlyMinter {
        _burn(from, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (deadline < block.timestamp) {
            revert EIP2612PermissionExpired(deadline);
        }

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, owner, spender, amount, nonces[owner]++, deadline))
            )
        );
        address signer = ecrecover(hash, v, r, s);
        if (signer != owner) {
            revert EIP2612InvalidSignature(owner, signer);
        }
        _approve(owner, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if (owner == address(0)) {
            revert ApproveFromZeroAddress(spender, amount);
        }
        if (spender == address(0)) {
            revert ApproveToZeroAddress(owner, amount);
        }

        allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) {
            revert MintToZeroAddress(amount);
        }

        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        if (from == address(0)) {
            revert BurnFromZeroAddress(amount);
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) {
            revert BurnAmountExceedsBalance(from, amount, balance);
        }
        unchecked {
            balanceOf[from] = balance - amount;
        }
        totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == address(0)) {
            revert TransferFromZeroAddress(to, amount);
        }
        if (to == address(0)) {
            revert TransferToZeroAddress(from, amount);
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) {
            revert TransferAmountExceedsBalance(from, to, amount, balance);
        }
        unchecked {
            balanceOf[from] = balance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    constructor() {
        governor = msg.sender;
        emit PendingGovernanceTransition(address(0), governor);
        emit GovernanceTransited(address(0), governor);
    }

    function transitGovernance(address newGovernor) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        emit PendingGovernanceTransition(governor, newGovernor);
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

interface IEIP2612 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IMintableAndBurnableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

