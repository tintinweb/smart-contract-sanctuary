// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./BaseToken.sol";

contract Baks is BaseToken {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IEIP2612.sol";
import {Governed} from "./Governance.sol";
import {IMintableAndBurnableERC20} from "./interfaces/ERC20.sol";
import {Initializable} from "./libraries/Upgradability.sol";

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

contract BaseToken is Initializable, Governed, IMintableAndBurnableERC20, IEIP2612 {
    bytes32 private constant EIP_712_DOMAIN_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PERMIT_TYPE_HASH =
        keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");

    string public override name;
    string public override symbol;
    uint8 public override decimals;
    string public version;

    address public minter;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    mapping(address => uint256) public override nonces;

    event MinterChanged(address indexed minter, address indexed newMinter);

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert OnlyMinterAllowed();
        }
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _minter
    ) external initializer {
        setGovernor(msg.sender);

        if (_minter == address(0)) {
            revert MinterZeroAddress();
        }
        minter = _minter;

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        version = "1";
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

    function setMinter(address newMinter) external onlyGovernor {
        if (newMinter == address(0)) {
            revert MinterZeroAddress();
        }
        minter = newMinter;
        emit MinterChanged(minter, newMinter);
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
pragma solidity 0.8.10;

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

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "./ERC20.sol";

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
pragma solidity 0.8.10;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Address.sol";

error EIP1967ImplementationIsNotContract(address implementation);
error ContractAlreadyInitialized();
error OnlyProxyCallAllowed();
error OnlyCurrentImplementationAllowed();

library EIP1967 {
    using Address for address;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed newImplementation);

    function upgradeTo(address newImplementation) internal {
        if (!newImplementation.isContract()) {
            revert EIP1967ImplementationIsNotContract(newImplementation);
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);
    }

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Proxy {
    using Address for address;

    constructor(address implementation, bytes memory data) {
        EIP1967.upgradeTo(implementation);
        implementation.delegateCall(data, "Proxy: construction failed");
    }

    receive() external payable {
        delegateCall();
    }

    fallback() external payable {
        delegateCall();
    }

    function delegateCall() internal {
        address implementation = EIP1967.getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

abstract contract Upgradeable {
    address private immutable self = address(this);

    modifier onlyProxy() {
        if (address(this) == self) {
            revert OnlyProxyCallAllowed();
        }
        if (EIP1967.getImplementation() != self) {
            revert OnlyCurrentImplementationAllowed();
        }
        _;
    }

    function upgradeTo(address newImplementation) public virtual onlyProxy {
        EIP1967.upgradeTo(newImplementation);
    }
}

abstract contract Initializable {
    bool private initializing;
    bool private initialized;

    modifier initializer() {
        if (!initializing && initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }
}