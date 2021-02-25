// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20Impl.sol";
import "./LockRequestable.sol";

/** @title  A contact to govern hybrid control over increases to the token supply.
  *
  * @notice  A contract that acts as a custodian of the active token
  * implementation, and an intermediary between it and the ‘true’ custodian.
  * It preserves the functionality of direct custodianship as well as granting
  * limited control of token supply increases to an additional key.
  *
  * @dev  This contract is a layer of indirection between an instance of
  * ERC20Impl and a custodian. The functionality of the custodianship over
  * the token implementation is preserved (printing and custodian changes),
  * but this contract adds the ability for an additional key
  * (the 'limited printer') to increase the token supply up to a ceiling,
  * and this supply ceiling can only be raised by the custodian.
  *
  * @author  Gemini Trust Company, LLC
  */
contract PrintLimiter is LockRequestable {

    // TYPES
    /// @dev The struct type for pending ceiling raises.
    struct PendingCeilingRaise {
        uint256 raiseBy;
    }

    // MEMBERS
    /// @dev  The reference to the active token implementation.
    ERC20Impl immutable public erc20Impl;

    /// @dev  The address of the account or contract that acts as the custodian.
    address immutable public custodian;

    /** @dev  The sole authorized caller of limited printing.
      * This account is also authorized to lower the supply ceiling.
      */
    address immutable public limitedPrinter;

    /** @dev  The maximum that the token supply can be increased to
      * through use of the limited printing feature.
      * The difference between the current total supply and the supply
      * ceiling is what is available to the 'limited printer' account.
      * The value of the ceiling can only be increased by the custodian.
      */
    uint256 public totalSupplyCeiling;

    /// @dev  The map of lock ids to pending ceiling raises.
    mapping (bytes32 => PendingCeilingRaise) public pendingRaiseMap;

    // CONSTRUCTOR
    constructor(
        address _erc20Impl,
        address _custodian,
        address _limitedPrinter,
        uint256 _initialCeiling
    )
    {
        erc20Impl = ERC20Impl(_erc20Impl);
        custodian = _custodian;
        limitedPrinter = _limitedPrinter;
        totalSupplyCeiling = _initialCeiling;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian, "unauthorized");
        _;
    }
    modifier onlyLimitedPrinter {
        require(msg.sender == limitedPrinter, "unauthorized");
        _;
    }

    /** @notice  Increases the token supply, with the newly created tokens
      * being added to the balance of the specified account.
      *
      * @dev  The function checks that the value to print does not
      * exceed the supply ceiling when added to the current total supply.
      * NOTE: printing to the zero address is disallowed.
      *
      * @param  _receiver  The receiving address of the print.
      * @param  _value  The number of tokens to add to the total supply and the
      * balance of the receiving address.
      */
    function limitedPrint(address _receiver, uint256 _value, bytes32 _merkleRoot) external onlyLimitedPrinter {
        uint256 totalSupply = erc20Impl.totalSupply();
        uint256 newTotalSupply = totalSupply + _value;

        require(newTotalSupply >= totalSupply, "overflow");
        require(newTotalSupply <= totalSupplyCeiling, "ceiling exceeded");
        erc20Impl.executePrint(_receiver, _value, _merkleRoot);
    }

    /** @notice  Requests an increase to the supply ceiling.
      *
      * @dev  Returns a unique lock id associated with the request.
      * Anyone can call this function, but confirming the request is authorized
      * by the custodian.
      *
      * @param  _raiseBy  The amount by which to raise the ceiling.
      *
      * @return  lockId  A unique identifier for this request.
      */
    function requestCeilingRaise(uint256 _raiseBy) external returns (bytes32 lockId) {
        require(_raiseBy != 0, "zero");

        (bytes32 preLockId, uint256 lockRequestIdx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                this.requestCeilingRaise.selector,
                _raiseBy
            )
        );

        pendingRaiseMap[lockId] = PendingCeilingRaise({
            raiseBy: _raiseBy
        });

        emit CeilingRaiseLocked(lockId, _raiseBy, lockRequestIdx);
    }

    /** @notice  Confirms a pending increase in the token supply.
      *
      * @dev  When called by the custodian with a lock id associated with a
      * pending ceiling increase, the amount requested is added to the
      * current supply ceiling.
      * NOTE: this function will not execute any raise that would overflow the
      * supply ceiling, but it will not revert either.
      *
      * @param  _lockId  The identifier of a pending ceiling raise request.
      */
    function confirmCeilingRaise(bytes32 _lockId) external onlyCustodian {
        PendingCeilingRaise storage pendingRaise = pendingRaiseMap[_lockId];

        // copy locals of references to struct members
        uint256 raiseBy = pendingRaise.raiseBy;
        // accounts for a gibberish _lockId
        require(raiseBy != 0, "no such lockId");

        delete pendingRaiseMap[_lockId];

        uint256 newCeiling = totalSupplyCeiling + raiseBy;
        // overflow check
        if (newCeiling >= totalSupplyCeiling) {
            totalSupplyCeiling = newCeiling;

            emit CeilingRaiseConfirmed(_lockId, raiseBy, newCeiling);
        }
    }

    /** @notice  Lowers the supply ceiling, further constraining the bound of
      * what can be printed by the limited printer.
      *
      * @dev  The limited printer is the sole authorized caller of this function,
      * so it is the only account that can elect to lower its limit to increase
      * the token supply.
      *
      * @param  _lowerBy  The amount by which to lower the supply ceiling.
      */
    function lowerCeiling(uint256 _lowerBy) external onlyLimitedPrinter {
        uint256 newCeiling = totalSupplyCeiling - _lowerBy;
        // overflow check
        require(newCeiling <= totalSupplyCeiling, "overflow");
        totalSupplyCeiling = newCeiling;

        emit CeilingLowered(_lowerBy, newCeiling);
    }

    /** @notice  Pass-through control of print confirmation, allowing this
      * contract's custodian to act as the custodian of the associated
      * active token implementation.
      *
      * @dev  This contract is the direct custodian of the active token
      * implementation, but this function allows this contract's custodian
      * to act as though it were the direct custodian of the active
      * token implementation. Therefore the custodian retains control of
      * unlimited printing.
      *
      * @param  _lockId  The identifier of a pending print request in
      * the associated active token implementation.
      */
    function confirmPrintProxy(bytes32 _lockId) external onlyCustodian {
        erc20Impl.confirmPrint(_lockId);
    }

    /** @notice  Pass-through control of custodian change confirmation,
      * allowing this contract's custodian to act as the custodian of
      * the associated active token implementation.
      *
      * @dev  This contract is the direct custodian of the active token
      * implementation, but this function allows this contract's custodian
      * to act as though it were the direct custodian of the active
      * token implementation. Therefore the custodian retains control of
      * custodian changes.
      *
      * @param  _lockId  The identifier of a pending custodian change request
      * in the associated active token implementation.
      */
    function confirmCustodianChangeProxy(bytes32 _lockId) external onlyCustodian {
        erc20Impl.confirmCustodianChange(_lockId);
    }

    // EVENTS
    /// @dev  Emitted by successful `requestCeilingRaise` calls.
    event CeilingRaiseLocked(bytes32 _lockId, uint256 _raiseBy, uint256 _lockRequestIdx);
    /// @dev  Emitted by successful `confirmCeilingRaise` calls.
    event CeilingRaiseConfirmed(bytes32 _lockId, uint256 _raiseBy, uint256 _newCeiling);

    /// @dev  Emitted by successful `lowerCeiling` calls.
    event CeilingLowered(uint256 _lowerBy, uint256 _newCeiling);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./CustodianUpgradeable.sol";
import "./ERC20Proxy.sol";
import "./ERC20Store.sol";

/** @title  ERC20 compliant token intermediary contract holding core logic.
  *
  * @notice  This contract serves as an intermediary between the exposed ERC20
  * interface in ERC20Proxy and the store of balances in ERC20Store. This
  * contract contains core logic that the proxy can delegate to
  * and that the store is called by.
  *
  * @dev  This contract contains the core logic to implement the
  * ERC20 specification as well as several extensions.
  * 1. Changes to the token supply.
  * 2. Batched transfers.
  * 3. Relative changes to spending approvals.
  * 4. Delegated transfer control ('sweeping').
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Impl is CustodianUpgradeable {

    // TYPES
    /// @dev  The struct type for pending increases to the token supply (print).
    struct PendingPrint {
        address receiver;
        uint256 value;
        bytes32 merkleRoot;
    }

    // MEMBERS
    /// @dev  The reference to the proxy.
    ERC20Proxy immutable public erc20Proxy;

    /// @dev  The reference to the store.
    ERC20Store immutable public erc20Store;

    address immutable public implOwner;

    /// @dev  The map of lock ids to pending token increases.
    mapping (bytes32 => PendingPrint) public pendingPrintMap;

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    bytes32 private immutable _PERMIT_TYPEHASH;


    // CONSTRUCTOR
    constructor(
          address _erc20Proxy,
          address _erc20Store,
          address _custodian,
          address _implOwner
    )
        CustodianUpgradeable(_custodian)
    {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
        erc20Store = ERC20Store(_erc20Store);
        implOwner = _implOwner;

        bytes32 hashedName = keccak256(bytes(ERC20Proxy(_erc20Proxy).name()));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"); 
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion, _erc20Proxy);
        _TYPE_HASH = typeHash;

        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    // MODIFIERS
    modifier onlyProxy {
        require(msg.sender == address(erc20Proxy), "unauthorized");
        _;
    }

    modifier onlyImplOwner {
        require(msg.sender == implOwner, "unauthorized");
        _;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        private
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        erc20Store.setAllowance(_owner, _spender, _amount);
        erc20Proxy.emitApproval(_owner, _spender, _amount);
    }

    /** @notice  Core logic of the ERC20 `approve` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has an `approve` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval in proxy.
      */
    function approveWithSender(
        address _sender,
        address _spender,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        _approve(_sender, _spender, _value);
        return true;
    }

    /** @notice  Core logic of the `increaseApproval` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has an `increaseApproval` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval.
      */
    function increaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _addedValue
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance, "overflow");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    /** @notice  Core logic of the `decreaseApproval` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `decreaseApproval` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval.
      */
    function decreaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance, "overflow");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(owner != address(0x0), "zero address");
        require(block.timestamp <= deadline, "expired");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                erc20Store.getNonceAndIncrement(owner),
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                structHash
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "invalid signature");

        _approve(owner, spender, value);
    }
    function nonces(address owner) external view returns (uint256) {
      return erc20Store.nonces(owner);
    }
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
      return _domainSeparatorV4();
    }

    /** @notice  Requests an increase in the token supply, with the newly created
      * tokens to be added to the balance of the specified account.
      *
      * @dev  Returns a unique lock id associated with the request.
      * Anyone can call this function, but confirming the request is authorized
      * by the custodian.
      * NOTE: printing to the zero address is disallowed.
      *
      * @param  _receiver  The receiving address of the print, if confirmed.
      * @param  _value  The number of tokens to add to the total supply and the
      * balance of the receiving address, if confirmed.
      *
      * @return  lockId  A unique identifier for this request.
      */
    function requestPrint(address _receiver, uint256 _value, bytes32 _merkleRoot) external returns (bytes32 lockId) {
        require(_receiver != address(0), "zero address");

        (bytes32 preLockId, uint256 lockRequestIdx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                this.requestPrint.selector,
                _receiver,
                _value,
                _merkleRoot
            )
        );

        pendingPrintMap[lockId] = PendingPrint({
            receiver: _receiver,
            value: _value,
            merkleRoot: _merkleRoot
        });

        emit PrintingLocked(lockId, _receiver, _value, lockRequestIdx);
    }

    function _executePrint(address _receiver, uint256 _value, bytes32 _merkleRoot) private {
        uint256 supply = erc20Store.totalSupply();
        uint256 newSupply = supply + _value;
        if (newSupply >= supply) {
          erc20Store.setTotalSupplyAndAddBalance(newSupply, _receiver, _value);

          erc20Proxy.emitTransfer(address(0), _receiver, _value);
          emit AuditPrint(_merkleRoot);
        }
    }

    function executePrint(address _receiver, uint256 _value, bytes32 _merkleRoot) external onlyCustodian {
        _executePrint(_receiver, _value, _merkleRoot);
    }

    /** @notice  Confirms a pending increase in the token supply.
      *
      * @dev  When called by the custodian with a lock id associated with a
      * pending increase, the amount requested to be printed in the print request
      * is printed to the receiving address specified in that same request.
      * NOTE: this function will not execute any print that would overflow the
      * total supply, but it will not revert either.
      *
      * @param  _lockId  The identifier of a pending print request.
      */
    function confirmPrint(bytes32 _lockId) external onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        address receiver = print.receiver;
        require (receiver != address(0), "no such lockId");
        uint256 value = print.value;
        bytes32 merkleRoot = print.merkleRoot;

        delete pendingPrintMap[_lockId];

        emit PrintingConfirmed(_lockId, receiver, value);
        _executePrint(receiver, value, merkleRoot);
    }

    /** @notice  Burns the specified value from the sender's balance.
      *
      * @dev  Sender's balanced is subtracted by the amount they wish to burn.
      *
      * @param  _value  The amount to burn.
      *
      * @return  success  true if the burn succeeded.
      */
    function burn(uint256 _value, bytes32 _merkleRoot) external returns (bool success) {
        uint256 balanceOfSender = erc20Store.balances(msg.sender);
        require(_value <= balanceOfSender, "insufficient balance");

        erc20Store.setBalanceAndDecreaseTotalSupply(
            msg.sender,
            balanceOfSender - _value,
            _value
        );

        erc20Proxy.emitTransfer(msg.sender, address(0), _value);
        emit AuditBurn(_merkleRoot);

        return true;
    }

    /** @notice  A function for a sender to issue multiple transfers to multiple
      * different addresses at once. This function is implemented for gas
      * considerations when someone wishes to transfer, as one transaction is
      * cheaper than issuing several distinct individual `transfer` transactions.
      *
      * @dev  By specifying a set of destination addresses and values, the
      * sender can issue one transaction to transfer multiple amounts to
      * distinct addresses, rather than issuing each as a separate
      * transaction. The `_tos` and `_values` arrays must be equal length, and
      * an index in one array corresponds to the same index in the other array
      * (e.g. `_tos[0]` will receive `_values[0]`, `_tos[1]` will receive
      * `_values[1]`, and so on.)
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _tos  The destination addresses to receive the transfers.
      * @param  _values  The values for each destination address.
      * @return  success  If transfers succeeded.
      */
    function batchTransfer(address[] calldata _tos, uint256[] calldata _values) external returns (bool success) {
        require(_tos.length == _values.length, "inconsistent length");

        uint256 numTransfers = _tos.length;
        uint256 senderBalance = erc20Store.balances(msg.sender);

        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0), "zero address");
          uint256 v = _values[i];
          require(senderBalance >= v, "insufficient balance");

          if (msg.sender != to) {
            senderBalance -= v;
            erc20Store.addBalance(to, v);
          }
          erc20Proxy.emitTransfer(msg.sender, to, v);
        }

        erc20Store.setBalance(msg.sender, senderBalance);

        return true;
    }

    /** @notice  Core logic of the ERC20 `transferFrom` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transferFrom` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in proxy.
      */
    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "zero address"); // ensure burn is the cannonical transfer to 0x0

        (uint256 balanceOfFrom, uint256 senderAllowance) = erc20Store.balanceAndAllowed(_from, _sender);
        require(_value <= balanceOfFrom, "insufficient balance");
        require(_value <= senderAllowance, "insufficient allowance");

        erc20Store.setBalanceAndAllowanceAndAddBalance(
            _from, balanceOfFrom - _value,
            _sender, senderAllowance - _value,
            _to, _value
        );

        erc20Proxy.emitTransfer(_from, _to, _value);

        return true;
    }

    /** @notice  Core logic of the ERC20 `transfer` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transfer` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in proxy.
      */
    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "zero address"); // ensure burn is the cannonical transfer to 0x0

        uint256 balanceOfSender = erc20Store.balances(_sender);
        require(_value <= balanceOfSender, "insufficient balance");

        erc20Store.setBalanceAndAddBalance(
            _sender, balanceOfSender - _value,
            _to, _value
        );

        erc20Proxy.emitTransfer(_sender, _to, _value);

        return true;
    }

    // METHODS (ERC20 sub interface impl.)
    /// @notice  Core logic of the ERC20 `totalSupply` function.
    function totalSupply() external view returns (uint256) {
        return erc20Store.totalSupply();
    }

    /// @notice  Core logic of the ERC20 `balanceOf` function.
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return erc20Store.balances(_owner);
    }

    /// @notice  Core logic of the ERC20 `allowance` function.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }

    function executeCallInProxy(
        address contractAddress,
        bytes calldata callData
    ) external onlyImplOwner {
        erc20Proxy.executeCallWithData(contractAddress, callData);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() private view returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, address(erc20Proxy));
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version, address verifyingContract) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                verifyingContract
            )
        );
    }

    function _getChainId() private view returns (uint256 chainId) {
        // SEE:
        //   - https://github.com/ethereum/solidity/issues/8854#issuecomment-629436203
        //   - https://github.com/ethereum/solidity/issues/10090
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    // EVENTS
    /// @dev  Emitted by successful `requestPrint` calls.
    event PrintingLocked(bytes32 _lockId, address _receiver, uint256 _value, uint256 _lockRequestIdx);
    /// @dev Emitted by successful `confirmPrint` calls.
    event PrintingConfirmed(bytes32 _lockId, address _receiver, uint256 _value);

    event AuditBurn(bytes32 merkleRoot);
    event AuditPrint(bytes32 merkleRoot);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./LockRequestable.sol";

/** @title  A contract to inherit upgradeable custodianship.
  *
  * @notice  A contract that provides re-usable code for upgradeable
  * custodianship. That custodian may be an account or another contract.
  *
  * @dev  This contract is intended to be inherited by any contract
  * requiring a custodian to control some aspect of its functionality.
  * This contract provides the mechanism for that custodianship to be
  * passed from one custodian to the next.
  *
  * @author  Gemini Trust Company, LLC
  */
abstract contract CustodianUpgradeable is LockRequestable {

    // TYPES
    /// @dev  The struct type for pending custodian changes.
    struct CustodianChangeRequest {
        address proposedNew;
    }

    // MEMBERS
    /// @dev  The address of the account or contract that acts as the custodian.
    address public custodian;

    /// @dev  The map of lock ids to pending custodian changes.
    mapping (bytes32 => CustodianChangeRequest) public custodianChangeReqs;

    // CONSTRUCTOR
    constructor(
        address _custodian
    )
      LockRequestable()
    {
        custodian = _custodian;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian, "unauthorized");
        _;
    }

    // PUBLIC FUNCTIONS
    // (UPGRADE)

    /** @notice  Requests a change of the custodian associated with this contract.
      *
      * @dev  Returns a unique lock id associated with the request.
      * Anyone can call this function, but confirming the request is authorized
      * by the custodian.
      *
      * @param  _proposedCustodian  The address of the new custodian.
      * @return  lockId  A unique identifier for this request.
      */
    function requestCustodianChange(address _proposedCustodian) external returns (bytes32 lockId) {
        require(_proposedCustodian != address(0), "zero address");

        (bytes32 preLockId, uint256 lockRequestIdx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                this.requestCustodianChange.selector,
                _proposedCustodian
            )
        );

        custodianChangeReqs[lockId] = CustodianChangeRequest({
            proposedNew: _proposedCustodian
        });

        emit CustodianChangeRequested(lockId, msg.sender, _proposedCustodian, lockRequestIdx);
    }

    /** @notice  Confirms a pending change of the custodian associated with this contract.
      *
      * @dev  When called by the current custodian with a lock id associated with a
      * pending custodian change, the `address custodian` member will be updated with the
      * requested address.
      *
      * @param  _lockId  The identifier of a pending change request.
      */
    function confirmCustodianChange(bytes32 _lockId) external onlyCustodian {
        custodian = getCustodianChangeReq(_lockId);

        delete custodianChangeReqs[_lockId];

        emit CustodianChangeConfirmed(_lockId, custodian);
    }

    // PRIVATE FUNCTIONS
    function getCustodianChangeReq(bytes32 _lockId) private view returns (address _proposedNew) {
        CustodianChangeRequest storage changeRequest = custodianChangeReqs[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(changeRequest.proposedNew != address(0), "no such lockId");

        return changeRequest.proposedNew;
    }

    /// @dev  Emitted by successful `requestCustodianChange` calls.
    event CustodianChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedCustodian,
        uint256 _lockRequestIdx
    );

    /// @dev Emitted by successful `confirmCustodianChange` calls.
    event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

/** @title  A contract for generating unique identifiers
  *
  * @notice  A contract that provides a identifier generation scheme,
  * guaranteeing uniqueness across all contracts that inherit from it,
  * as well as unpredictability of future identifiers.
  *
  * @dev  This contract is intended to be inherited by any contract that
  * implements the callback software pattern for cooperative custodianship.
  *
  * @author  Gemini Trust Company, LLC
  */
abstract contract LockRequestable {

    // MEMBERS
    /// @notice  the count of all invocations of `generatePreLockId`.
    uint256 public lockRequestCount;

    // CONSTRUCTOR
    constructor() {
        lockRequestCount = 0;
    }

    // FUNCTIONS
    /** @notice  Returns a fresh unique identifier.
      *
      * @dev the generation scheme uses three components.
      * First, the blockhash of the previous block.
      * Second, the deployed address.
      * Third, the next value of the counter.
      * This ensure that identifiers are unique across all contracts
      * following this scheme, and that future identifiers are
      * unpredictable.
      *
      * @return preLockId a 32-byte unique identifier.
      * @return lockRequestIdx index of lock request

      */
    function generatePreLockId() internal returns (bytes32 preLockId, uint256 lockRequestIdx) {
        lockRequestIdx = ++lockRequestCount;
        preLockId = keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            address(this),
            lockRequestIdx
          )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./EIP2612Interface.sol";
import "./ERC20Interface.sol";
import "./ERC20ImplUpgradeable.sol";

/** @title  Public interface to ERC20 compliant token.
  *
  * @notice  This contract is a permanent entry point to an ERC20 compliant
  * system of contracts.
  *
  * @dev  This contract contains no business logic and instead
  * delegates to an instance of ERC20Impl. This contract also has no storage
  * that constitutes the operational state of the token. This contract is
  * upgradeable in the sense that the `custodian` can update the
  * `erc20Impl` address, thus redirecting the delegation of business logic.
  * The `custodian` is also authorized to pass custodianship.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Proxy is ERC20Interface, ERC20ImplUpgradeable, EIP2612Interface {

    // MEMBERS
    /// @notice  Returns the name of the token.
    string public name; // TODO: use `constant` for mainnet

    /// @notice  Returns the symbol of the token.
    string public symbol; // TODO: use `constant` for mainnet

    /// @notice  Returns the number of decimals the token uses.
    uint8 immutable public decimals; // TODO: use `constant` (18) for mainnet

    // CONSTRUCTOR
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _custodian
    )
        ERC20ImplUpgradeable(_custodian)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // PUBLIC FUNCTIONS
    // (ERC20Interface)
    /** @notice  Returns the total token supply.
      *
      * @return  the total token supply.
      */
    function totalSupply() external override view returns (uint256) {
        return erc20Impl.totalSupply();
    }

    /** @notice  Returns the account balance of another account with address
      * `_owner`.
      *
      * @return  balance  the balance of account with address `_owner`.
      */
    function balanceOf(address _owner) external override view returns (uint256 balance) {
        return erc20Impl.balanceOf(_owner);
    }

    /** @dev Internal use only.
      */
    function emitTransfer(address _from, address _to, uint256 _value) external onlyImpl {
        emit Transfer(_from, _to, _value);
    }

    /** @notice  Transfers `_value` amount of tokens to address `_to`.
      *
      * @dev Will fire the `Transfer` event. Will revert if the `_from`
      * account balance does not have enough tokens to spend.
      *
      * @return  success  true if transfer completes.
      */
    function transfer(address _to, uint256 _value) external override returns (bool success) {
        return erc20Impl.transferWithSender(msg.sender, _to, _value);
    }

    /** @notice  Transfers `_value` amount of tokens from address `_from`
      * to address `_to`.
      *
      * @dev  Will fire the `Transfer` event. Will revert unless the `_from`
      * account has deliberately authorized the sender of the message
      * via some mechanism.
      *
      * @return  success  true if transfer completes.
      */
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        return erc20Impl.transferFromWithSender(msg.sender, _from, _to, _value);
    }

    /** @dev Internal use only.
      */
    function emitApproval(address _owner, address _spender, uint256 _value) external onlyImpl {
        emit Approval(_owner, _spender, _value);
    }

    /** @notice  Allows `_spender` to withdraw from your account multiple times,
      * up to the `_value` amount. If this function is called again it
      * overwrites the current allowance with _value.
      *
      * @dev  Will fire the `Approval` event.
      *
      * @return  success  true if approval completes.
      */
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        return erc20Impl.approveWithSender(msg.sender, _spender, _value);
    }

    /** @notice Increases the amount `_spender` is allowed to withdraw from
      * your account.
      * This function is implemented to avoid the race condition in standard
      * ERC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used instead of
      * `approve`.
      *
      * @return  success  true if approval completes.
      */
    function increaseApproval(address _spender, uint256 _addedValue) external returns (bool success) {
        return erc20Impl.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

    /** @notice  Decreases the amount `_spender` is allowed to withdraw from
      * your account. This function is implemented to avoid the race
      * condition in standard ERC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used
      * instead of `approve`.
      *
      * @return  success  true if approval completes.
      */
    function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool success) {
        return erc20Impl.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    /** @notice  Returns how much `_spender` is currently allowed to spend from
      * `_owner`'s balance.
      *
      * @return  remaining  the remaining allowance.
      */
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining) {
        return erc20Impl.allowance(_owner, _spender);
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
      erc20Impl.permit(owner, spender, value, deadline, v, r, s);
    }
    function nonces(address owner) external override view returns (uint256) {
      return erc20Impl.nonces(owner);
    }
    function DOMAIN_SEPARATOR() external override view returns (bytes32) {
      return erc20Impl.DOMAIN_SEPARATOR();
    }

    function executeCallWithData(address contractAddress, bytes calldata callData) external {
        address implAddr = address(erc20Impl);
        require(msg.sender == implAddr, "unauthorized");
        require(contractAddress != implAddr, "disallowed");

        (bool success, bytes memory returnData) = contractAddress.call(callData);
        if (success) {
            emit CallWithDataSuccess(contractAddress, callData, returnData);
        } else {
            emit CallWithDataFailure(contractAddress, callData, returnData);
        }
    }

    event CallWithDataSuccess(address contractAddress, bytes callData, bytes returnData);
    event CallWithDataFailure(address contractAddress, bytes callData, bytes returnData);
}

// SPDX-License-Identifier: MIT
// Adapted from
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/ceb7324657ed4e73df6cb6f853c60c8d3fb3a0e9/contracts/drafts/IERC20Permit.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface EIP2612Interface {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

interface ERC20Interface {
  // METHODS

  // NOTE:
  //   public getter functions are not currently recognised as an
  //   implementation of the matching abstract function by the compiler.

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#name
  // function name() public view returns (string);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#symbol
  // function symbol() public view returns (string);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#totalsupply
  // function decimals() public view returns (uint8);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#totalsupply
  function totalSupply() external view returns (uint256);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#balanceof
  function balanceOf(address _owner) external view returns (uint256 balance);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer
  function transfer(address _to, uint256 _value) external returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transferfrom
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approve
  function approve(address _spender, uint256 _value) external returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#allowance
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  // EVENTS
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer-1
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approval
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./CustodianUpgradeable.sol";
import "./ERC20Impl.sol";

/** @title  A contract to inherit upgradeable token implementations.
  *
  * @notice  A contract that provides re-usable code for upgradeable
  * token implementations. It itself inherits from `CustodianUpgradable`
  * as the upgrade process is controlled by the custodian.
  *
  * @dev  This contract is intended to be inherited by any contract
  * requiring a reference to the active token implementation, either
  * to delegate calls to it, or authorize calls from it. This contract
  * provides the mechanism for that implementation to be be replaced,
  * which constitutes an implementation upgrade.
  *
  * @author Gemini Trust Company, LLC
  */
abstract contract ERC20ImplUpgradeable is CustodianUpgradeable {

    // TYPES
    /// @dev  The struct type for pending implementation changes.
    struct ImplChangeRequest {
        address proposedNew;
    }

    // MEMBERS
    // @dev  The reference to the active token implementation.
    ERC20Impl public erc20Impl;

    /// @dev  The map of lock ids to pending implementation changes.
    mapping (bytes32 => ImplChangeRequest) public implChangeReqs;

    // CONSTRUCTOR
    constructor(address _custodian) CustodianUpgradeable(_custodian) {
        erc20Impl = ERC20Impl(0x0);
    }

    // MODIFIERS
    modifier onlyImpl {
        require(msg.sender == address(erc20Impl), "unauthorized");
        _;
    }

    // PUBLIC FUNCTIONS
    // (UPGRADE)
    /** @notice  Requests a change of the active implementation associated
      * with this contract.
      *
      * @dev  Returns a unique lock id associated with the request.
      * Anyone can call this function, but confirming the request is authorized
      * by the custodian.
      *
      * @param  _proposedImpl  The address of the new active implementation.
      * @return  lockId  A unique identifier for this request.
      */
    function requestImplChange(address _proposedImpl) external returns (bytes32 lockId) {
        require(_proposedImpl != address(0), "zero address");

        (bytes32 preLockId, uint256 lockRequestIdx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                this.requestImplChange.selector,
                _proposedImpl
            )
        );

        implChangeReqs[lockId] = ImplChangeRequest({
            proposedNew: _proposedImpl
        });

        emit ImplChangeRequested(lockId, msg.sender, _proposedImpl, lockRequestIdx);
    }

    /** @notice  Confirms a pending change of the active implementation
      * associated with this contract.
      *
      * @dev  When called by the custodian with a lock id associated with a
      * pending change, the `ERC20Impl erc20Impl` member will be updated
      * with the requested address.
      *
      * @param  _lockId  The identifier of a pending change request.
      */
    function confirmImplChange(bytes32 _lockId) external onlyCustodian {
        erc20Impl = getImplChangeReq(_lockId);

        delete implChangeReqs[_lockId];

        emit ImplChangeConfirmed(_lockId, address(erc20Impl));
    }

    // PRIVATE FUNCTIONS
    function getImplChangeReq(bytes32 _lockId) private view returns (ERC20Impl _proposedNew) {
        ImplChangeRequest storage changeRequest = implChangeReqs[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(changeRequest.proposedNew != address(0), "no such lockId");

        return ERC20Impl(changeRequest.proposedNew);
    }

    /// @dev  Emitted by successful `requestImplChange` calls.
    event ImplChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedImpl,
        uint256 _lockRequestIdx
    );

    /// @dev Emitted by successful `confirmImplChange` calls.
    event ImplChangeConfirmed(bytes32 _lockId, address _newImpl);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20ImplUpgradeable.sol";

/** @title  ERC20 compliant token balance store.
  *
  * @notice  This contract serves as the store of balances, allowances, and
  * supply for the ERC20 compliant token. No business logic exists here.
  *
  * @dev  This contract contains no business logic and instead
  * is the final destination for any change in balances, allowances, or token
  * supply. This contract is upgradeable in the sense that its custodian can
  * update the `erc20Impl` address, thus redirecting the source of logic that
  * determines how the balances will be updated.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Store is ERC20ImplUpgradeable {

    // MEMBERS
    /// @dev  The total token supply.
    uint256 public totalSupply;

    /// @dev  The mapping of balances.
    mapping (address => uint256) public balances;

    /// @dev  The mapping of allowances.
    mapping (address => mapping (address => uint256)) public allowed;

    mapping (address => uint256) public nonces;

    // CONSTRUCTOR
    constructor(address _custodian) ERC20ImplUpgradeable(_custodian) {
        totalSupply = 0;
    }


    // PUBLIC FUNCTIONS
    // (ERC20 Ledger)

    /** @notice  Sets how much `_owner` allows `_spender` to transfer on behalf
      * of `_owner`.
      *
      * @dev  Intended for use by token implementation functions
      * that update spending allowances. The only authorized caller
      * is the active implementation.
      *
      * @param  _owner  The account that will allow an on-behalf-of spend.
      * @param  _spender  The account that will spend on behalf of the owner.
      * @param  _value  The limit of what can be spent.
      */
    function setAllowance(
        address _owner,
        address _spender,
        uint256 _value
    )
        external
        onlyImpl
    {
        allowed[_owner][_spender] = _value;
    }

    /** @notice  Sets the balance of `_owner` to `_newBalance`.
      *
      * @dev  Intended for use by token implementation functions
      * that update balances. The only authorized caller
      * is the active implementation.
      *
      * @param  _owner  The account that will hold a new balance.
      * @param  _newBalance  The balance to set.
      */
    function setBalance(
        address _owner,
        uint256 _newBalance
    )
        external
        onlyImpl
    {
        balances[_owner] = _newBalance;
    }

    /** @notice Adds `_balanceIncrease` to `_owner`'s balance.
      *
      * @dev  Intended for use by token implementation functions
      * that update balances. The only authorized caller
      * is the active implementation.
      * WARNING: the caller is responsible for preventing overflow.
      *
      * @param  _owner  The account that will hold a new balance.
      * @param  _balanceIncrease  The balance to add.
      */
    function addBalance(
        address _owner,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }

    function setTotalSupplyAndAddBalance(
        uint256 _newTotalSupply,
        address _owner,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        totalSupply = _newTotalSupply;
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }

    function setBalanceAndDecreaseTotalSupply(
        address _owner,
        uint256 _newBalance,
        uint256 _supplyDecrease
    )
        external
        onlyImpl
    {
        balances[_owner] = _newBalance;
        totalSupply = totalSupply - _supplyDecrease;
    }

    function setBalanceAndAddBalance(
        address _ownerToSet,
        uint256 _newBalance,
        address _ownerToAdd,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_ownerToSet] = _newBalance;
        balances[_ownerToAdd] = balances[_ownerToAdd] + _balanceIncrease;
    }

    function setBalanceAndAllowanceAndAddBalance(
        address _ownerToSet,
        uint256 _newBalance,
        address _spenderToSet,
        uint256 _newAllowance,
        address _ownerToAdd,
        uint256 _balanceIncrease
    )
        external
        onlyImpl
    {
        balances[_ownerToSet] = _newBalance;
        allowed[_ownerToSet][_spenderToSet] = _newAllowance;
        balances[_ownerToAdd] = balances[_ownerToAdd] + _balanceIncrease;
    }

    function balanceAndAllowed(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256 ownerBalance, uint256 spenderAllowance)
    {
        ownerBalance = balances[_owner];
        spenderAllowance = allowed[_owner][_spender];
    }

    function getNonceAndIncrement(
        address _owner
    )
        external
        onlyImpl
        returns (uint256 current)
    {
        current = nonces[_owner];
        nonces[_owner] = current + 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20Proxy.sol";
import "./ERC20Impl.sol";
import "./ERC20Store.sol";

contract Initializer {

  function initialize(
      ERC20Store _store,
      ERC20Proxy _proxy,
      ERC20Impl _impl,
      address _implChangeCustodian,
      address _printCustodian) external {

    // set impl as active implementation for store and proxy
    _store.confirmImplChange(_store.requestImplChange(address(_impl)));
    _proxy.confirmImplChange(_proxy.requestImplChange(address(_impl)));

    // pass custodianship of store and proxy to impl change custodian
    _store.confirmCustodianChange(_store.requestCustodianChange(_implChangeCustodian));
    _proxy.confirmCustodianChange(_proxy.requestCustodianChange(_implChangeCustodian));

    // pass custodianship of impl to print custodian
    _impl.confirmCustodianChange(_impl.requestCustodianChange(_printCustodian));
  }

}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./ERC20Store.sol";

/** @title  ERC20 compliant token intermediary contract holding core logic.
  *
  * @notice  This contract serves as an intermediary between the exposed ERC20
  * interface in ERC20Proxy and the store of balances in ERC20Store. This
  * contract contains core logic that the proxy can delegate to
  * and that the store is called by.
  *
  * @dev  This version of ERC20Impl is intended to revert all ERC20 functions
  * that are state mutating; only view functions remain operational. Upgrading
  * to this contract places the system into a read-only paused state.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20ImplPaused {

    // MEMBERS

    /// @dev  The reference to the store.
    ERC20Store immutable public erc20Store;

    // CONSTRUCTOR
    constructor(
          address _erc20Store
    )
    {
        erc20Store = ERC20Store(_erc20Store);
    }

    // METHODS (ERC20 sub interface impl.)
    /// @notice  Core logic of the ERC20 `totalSupply` function.
    function totalSupply() external view returns (uint256) {
        return erc20Store.totalSupply();
    }

    /// @notice  Core logic of the ERC20 `balanceOf` function.
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return erc20Store.balances(_owner);
    }

    /// @notice  Core logic of the ERC20 `allowance` function.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }
}