// File: @0x/contracts-utils/contracts/src/LibReentrancyGuardRichErrors.sol

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibReentrancyGuardRichErrors {

    // bytes4(keccak256("IllegalReentrancyError()"))
    bytes internal constant ILLEGAL_REENTRANCY_ERROR_SELECTOR_BYTES =
        hex"0c3b823f";

    // solhint-disable func-name-mixedcase
    function IllegalReentrancyError()
        internal
        pure
        returns (bytes memory)
    {
        return ILLEGAL_REENTRANCY_ERROR_SELECTOR_BYTES;
    }
}

// File: @0x/contracts-utils/contracts/src/LibRichErrors.sol

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// File: @0x/contracts-utils/contracts/src/ReentrancyGuard.sol

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;




contract ReentrancyGuard {

    // Locked state of mutex.
    bool private _locked = false;

    /// @dev Functions with this modifer cannot be reentered. The mutex will be locked
    ///      before function execution and unlocked after.
    modifier nonReentrant() {
        _lockMutexOrThrowIfAlreadyLocked();
        _;
        _unlockMutex();
    }

    function _lockMutexOrThrowIfAlreadyLocked()
        internal
    {
        // Ensure mutex is unlocked.
        if (_locked) {
            LibRichErrors.rrevert(
                LibReentrancyGuardRichErrors.IllegalReentrancyError()
            );
        }
        // Lock mutex.
        _locked = true;
    }

    function _unlockMutex()
        internal
    {
        // Unlock mutex.
        _locked = false;
    }
}

// File: @0x/contracts-utils/contracts/src/LibSafeMathRichErrors.sol

pragma solidity ^0.5.9;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

// File: @0x/contracts-utils/contracts/src/LibSafeMath.sol

pragma solidity ^0.5.9;




library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

// File: contracts/vault/Operational.sol

/*

  Copyright 2020 Metaps Alpha Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity 0.5.17;


contract Operational {
    address public owner;
    address[] public operators;
    mapping (address => bool) public isOperator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorAdded(address indexed target, address indexed caller);
    event OperatorRemoved(address indexed target, address indexed caller);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_CONTRACT_OWNER");
        _;
    }

    modifier onlyOperator() {
        require(isOperator[msg.sender], "SENDER_IS_NOT_OPERATOR");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addOperator(address target) external onlyOwner {
        require(!isOperator[target], "TARGET_IS_ALREADY_OPERATOR");
        isOperator[target] = true;
        operators.push(target);
        emit OperatorAdded(target, msg.sender);
    }

    function removeOperator(address target) external onlyOwner {
        require(isOperator[target], "TARGET_IS_NOT_OPERATOR");
        delete isOperator[target];
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == target) {
                operators[i] = operators[operators.length - 1];
                operators.length -= 1;
                break;
            }
        }
        emit OperatorRemoved(target, msg.sender);
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/vault/Pausable.sol

pragma solidity ^0.5.16;



contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/vault/Vault.sol

/*

  Copyright 2020 Metaps Alpha Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity 0.5.17;






contract Vault is Operational, Pausable, ReentrancyGuard {
    using LibSafeMath for uint256;

    event Deposit(bytes32 indexed orderHash, address indexed from, address indexed to, uint256 amount, uint256 gasFee);
    event Pay(bytes32 indexed orderHash, address indexed from, address indexed to, uint256 amount);
    event Refund(bytes32 indexed orderHash, address indexed from, address indexed to, uint256 amount);

    struct DepositInfo {
        address payable from;
        address payable to;
        uint256 gasFee;
        bool filled;
    }

    // orderHash -> amount -> DepositInfo
    mapping (bytes32 => mapping (uint256 => DepositInfo)) public depositInfo;
    uint256 public miimeRevenue;
    uint256 public issuerRevenue;
    uint256 public gasLimit = 300000;

    function () external payable {
        miimeRevenue = miimeRevenue.safeAdd(msg.value);
    }

    function deposit(bytes32 orderHash, uint256 amount, uint256 gasFee, address payable to) external payable nonReentrant whenNotPaused {
        require(amount.safeAdd(gasFee) == msg.value, 'invalid amount and gasFee');
        require(depositInfo[orderHash][amount].from == address(0), 'already exist deposit');
        require(!depositInfo[orderHash][amount].filled, 'already filled');
        depositInfo[orderHash][amount] = DepositInfo(msg.sender, to, gasFee, false);
        emit Deposit(orderHash, msg.sender, to, amount, gasFee);
    }

    function pay(bytes32 orderHash, uint256 amount, uint256 miimeFeeAmount, uint256 issuerFeeAmount) external nonReentrant onlyOperator {
        require(depositInfo[orderHash][amount].from != address(0), 'not exist deposit');
        require(!depositInfo[orderHash][amount].filled, 'already filled');

        address from = depositInfo[orderHash][amount].from;
        address payable to = depositInfo[orderHash][amount].to;
        uint256 gasFee = depositInfo[orderHash][amount].gasFee;
        depositInfo[orderHash][amount].filled = true;
        depositInfo[orderHash][amount].from = address(0); // to save gas
        depositInfo[orderHash][amount].to = address(0); // to save gas
        depositInfo[orderHash][amount].gasFee = 0; // to save gas

        (bool success, bytes memory _data) = to.call.gas(gasLimit).value(amount.safeSub(miimeFeeAmount).safeSub(issuerFeeAmount))('');
        require(success, 'failed eth sending');

        miimeRevenue = miimeRevenue.safeAdd(miimeFeeAmount).safeAdd(gasFee);
        issuerRevenue = issuerRevenue.safeAdd(issuerFeeAmount);

        emit Pay(orderHash, from, to, amount);
    }

    function refund(bytes32 orderHash, uint256 amount) external nonReentrant onlyOperator {
        require(depositInfo[orderHash][amount].from != address(0), 'not exist deposit');
        require(!depositInfo[orderHash][amount].filled, 'already filled');

        address payable from = depositInfo[orderHash][amount].from;
        address to = depositInfo[orderHash][amount].to;
        uint256 gasFee = depositInfo[orderHash][amount].gasFee;
        delete depositInfo[orderHash][amount];

        (bool success, bytes memory _data) = from.call.gas(gasLimit).value(amount)('');
        require(success, 'failed eth sending');

        miimeRevenue = miimeRevenue.safeAdd(gasFee);

        emit Refund(orderHash, from, to, amount);
    }

    function withdrawMiimeRevenue(address payable to) external nonReentrant onlyOperator {
        (bool success, bytes memory _data) = to.call.gas(gasLimit).value(miimeRevenue)('');
        require(success, 'failed eth sending');
        miimeRevenue = 0;
    }

    function withdrawIssuerRevenue(address payable to) external nonReentrant onlyOperator {
        (bool success, bytes memory _data) = to.call.gas(gasLimit).value(issuerRevenue)('');
        require(success, 'failed eth sending');
        issuerRevenue = 0;
    }

    function setGasLimit(uint256 newGasLimit) external nonReentrant onlyOperator {
        gasLimit = newGasLimit;
    }
}