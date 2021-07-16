//SourceUnit: CustodianUpgradeable.sol

pragma solidity ^0.5.8;

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
*/
contract CustodianUpgradeable is LockRequestable {

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
      public
    {
        custodian = _custodian;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian, "only custodian");
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
    function requestCustodianChange(address _proposedCustodian) public returns (bytes32 lockId) {
        require(_proposedCustodian != address(0), "no null value for `_proposedCustodian`");

        lockId = generateLockId();

        custodianChangeReqs[lockId] = CustodianChangeRequest({
            proposedNew: _proposedCustodian
        });

        emit CustodianChangeRequested(lockId, msg.sender, _proposedCustodian);
    }

    /** @notice  Confirms a pending change of the custodian associated with this contract.
      *
      * @dev  When called by the current custodian with a lock id associated with a
      * pending custodian change, the `address custodian` member will be updated with the
      * requested address.
      *
      * @param  _lockId  The identifier of a pending change request.
      */
    function confirmCustodianChange(bytes32 _lockId) public onlyCustodian {
        custodian = getCustodianChangeReq(_lockId);

        delete custodianChangeReqs[_lockId];

        emit CustodianChangeConfirmed(_lockId, custodian);
    }

    // PRIVATE FUNCTIONS
    function getCustodianChangeReq(bytes32 _lockId) private view returns (address _proposedNew) {
        CustodianChangeRequest storage changeRequest = custodianChangeReqs[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(changeRequest.proposedNew != address(0), "reject ‘null’ results from the map lookup");

        return changeRequest.proposedNew;
    }

    //EVENTS
    /// @dev  Emitted by successful `requestCustodianChange` calls.
    event CustodianChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedCustodian
    );

    /// @dev Emitted by successful `confirmCustodianChange` calls.
    event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}

//SourceUnit: LockRequestable.sol

pragma solidity ^0.5.8;

/** @title  A contract for generating unique identifiers
  *
  * @notice  A contract that provides an identifier generation scheme,
  * guaranteeing uniqueness across all contracts that inherit from it,
  * as well as the unpredictability of future identifiers.
  *
  * @dev  This contract is intended to be inherited by any contract that
  * implements the callback software pattern for cooperative custodianship.
  *
*/
contract LockRequestable {

    // MEMBERS
    /// @notice  the count of all invocations of `generateLockId`.
    uint256 public lockRequestCount;

    // CONSTRUCTOR
    constructor() public {
        lockRequestCount = 0;
    }

    // FUNCTIONS
    /** @notice  Returns a fresh unique identifier.
      *
      * @dev the generation scheme uses three components.
      * First, the blockhash of the previous block.
      * Second, the deployed address.
      * Third, the next value of the counter.
      * This ensures that identifiers are unique across all contracts
      * following this scheme, and that future identifiers are
      * unpredictable.
      *
      * @return a 32-byte unique identifier.
    */
    function generateLockId() internal returns (bytes32 lockId) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount));
    }
}

//SourceUnit: TRC20Impl.sol

pragma solidity ^0.5.8;

import "./CustodianUpgradeable.sol";
import "./TRC20Proxy.sol";
import "./TRC20Store.sol";

/** @title  TRC20 compliant token intermediary contract holding core logic.
  *
  * @notice  This contract serves as an intermediary between the exposed TRC20
  * interface in TRC20Proxy and the store of balances in TRC20Store. This
  * contract contains core logic that the proxy can delegate to
  * and that the store is called by.
  *
  * @dev  This contract contains the core logic to implement the
  * TRC20 specification as well as several extensions.
  * 1. Changes to the token supply.
  * 2. Batched transfers.
  * 3. Relative changes to spending approvals.
  * 4. Delegated transfer control ('sweeping').
  *
  */
contract TRC20Impl is CustodianUpgradeable {

    // TYPES
    /// @dev  The struct type for pending increases to the token supply (print).
    struct PendingPrint {
        address receiver;
        uint256 value;
    }

    // MEMBERS
    /// @dev  The reference to the proxy.
    TRC20Proxy public trc20Proxy;

    /// @dev  The reference to the store.
    TRC20Store public trc20Store;

    /// @dev  The sole authorized caller of delegated transfer control ('sweeping').
    address public sweeper;

    /** @dev  The static message to be signed by an external account that
      * signifies their permission to forward their balance to any arbitrary
      * address. This is used to consolidate the control of all accounts
      * backed by a shared keychain into the control of a single key.
      * Initialized as the concatenation of the address of this contract
      * and the word "sweep". This concatenation is done to prevent a replay
      * attack in a subsequent contract, where the sweeping message could
      * potentially be replayed to re-enable sweeping ability.
      */
    bytes32 public sweepMsg;

    /** @dev  The mapping that stores whether the address in question has
      * enabled sweeping its contents to another account or not.
      * If an address maps to "true", it has already enabled sweeping,
      * and thus does not need to re-sign the `sweepMsg` to enact the sweep.
      */
    mapping (address => bool) public sweptSet;

    /// @dev  The map of lock ids to pending token increases.
    mapping (bytes32 => PendingPrint) public pendingPrintMap;

    /// @dev The map of blocked addresses.
    mapping (address => bool) public blocked;

    // CONSTRUCTOR
    constructor(
          address _TRC20Proxy,
          address _TRC20Store,
          address _custodian,
          address _sweeper
    )
        CustodianUpgradeable(_custodian)
        public
    {
        require(_sweeper != address(0), "no null value for `_sweeper`");
        trc20Proxy = TRC20Proxy(_TRC20Proxy);
        trc20Store = TRC20Store(_TRC20Store);

        sweeper = _sweeper;
        sweepMsg = keccak256(abi.encodePacked(address(this), "sweep"));
    }

    // MODIFIERS
    modifier onlyProxy {
        require(msg.sender == address(trc20Proxy), "only TRC20Proxy");
        _;
    }
    modifier onlySweeper {
        require(msg.sender == sweeper, "only sweeper");
        _;
    }


    /** @notice  Core logic of the TRC20 `approve` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has an `approve` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval in a proxy.
      */
    function approveWithSender(
        address _sender,
        address _spender,
        uint256 _value
    )
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "no null value for `_spender`");
        require(blocked[_sender] != true, "_sender must not be blocked");
        require(blocked[_spender] != true, "_spender must not be blocked");
        trc20Store.setAllowance(_sender, _spender, _value);
        trc20Proxy.emitApproval(_sender, _spender, _value);
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
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0),"no null value for_spender");
        require(blocked[_sender] != true, "_sender must not be blocked");
        require(blocked[_spender] != true, "_spender must not be blocked");
        uint256 currentAllowance = trc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance, "new allowance must not be smaller than previous");

        trc20Store.setAllowance(_sender, _spender, newAllowance);
        trc20Proxy.emitApproval(_sender, _spender, newAllowance);
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
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "no unspendable approvals"); // disallow unspendable approvals
        require(blocked[_sender] != true, "_sender must not be blocked");
        require(blocked[_spender] != true, "_spender must not be blocked");
        uint256 currentAllowance = trc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance, "new allowance must not be smaller than previous");

        trc20Store.setAllowance(_sender, _spender, newAllowance);
        trc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
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
    function requestPrint(address _receiver, uint256 _value) public returns (bytes32 lockId) {
        require(_receiver != address(0), "no null value for `_receiver`");
        require(blocked[msg.sender] != true, "account blocked");
        require(blocked[_receiver] != true, "_receiver must not be blocked");
        lockId = generateLockId();

        pendingPrintMap[lockId] = PendingPrint({
            receiver: _receiver,
            value: _value
        });

        emit PrintingLocked(lockId, _receiver, _value);
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
    function confirmPrint(bytes32 _lockId) public onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        address receiver = print.receiver;
        require (receiver != address(0), "unknown `_lockId`");
        uint256 value = print.value;

        delete pendingPrintMap[_lockId];

        uint256 supply = trc20Store.totalSupply();
        uint256 newSupply = supply + value;
        if (newSupply >= supply) {
          trc20Store.setTotalSupply(newSupply);
          trc20Store.addBalance(receiver, value);

          emit PrintingConfirmed(_lockId, receiver, value);
          trc20Proxy.emitTransfer(address(0), receiver, value);
        }
    }

    /** @notice  Burns the specified value from the sender's balance.
      *
      * @dev  Sender's balanced is subtracted by the amount they wish to burn.
      *
      * @param  _value  The amount to burn.
      *
      * @return success true if the burn succeeded.
      */
    function burn(uint256 _value) public returns (bool success) {
        require(blocked[msg.sender] != true, "account blocked");
        uint256 balanceOfSender = trc20Store.balances(msg.sender);
        require(_value <= balanceOfSender, "disallow burning more, than amount of the balance");

        trc20Store.setBalance(msg.sender, balanceOfSender - _value);
        trc20Store.setTotalSupply(trc20Store.totalSupply() - _value);

        trc20Proxy.emitTransfer(msg.sender, address(0), _value);

        return true;
    }

     /** @notice  Burns the specified value from the balance in question.
      *
      * @dev  Suspected balance is subtracted by the amount which will be burnt.
      *
      * @dev If the suspected balance has less than the amount requested, it will be set to 0.
      *
      * @param  _from  The address of suspected balance.
      *
      * @param  _value  The amount to burn.
      *
      * @return success true if the burn succeeded.
      */
    function burn(address _from, uint256 _value) public onlyCustodian returns (bool success) {
        uint256 balance = trc20Store.balances(_from);
        if(_value <= balance){
            trc20Store.setBalance(_from, balance - _value);
            trc20Store.setTotalSupply(trc20Store.totalSupply() - _value);
            trc20Proxy.emitTransfer(_from, address(0), _value);
            emit Wiped(_from, _value, _value, balance - _value);
        }
        else {
            trc20Store.setBalance(_from,0);
            trc20Store.setTotalSupply(trc20Store.totalSupply() - balance);
            trc20Proxy.emitTransfer(_from, address(0), balance);
            emit Wiped(_from, _value, balance, 0);
        }
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
    function batchTransfer(address[] memory _tos, uint256[] memory _values) public returns (bool success) {
        require(_tos.length == _values.length, "_tos and _values must be the same length");
        require(blocked[msg.sender] != true, "account blocked");
        uint256 numTransfers = _tos.length;
        uint256 senderBalance = trc20Store.balances(msg.sender);

        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0), "no null values for _tos");
          require(blocked[to] != true, "_tos must not be blocked");
          uint256 v = _values[i];
          require(senderBalance >= v, "insufficient funds");

          if (msg.sender != to) {
            senderBalance -= v;
            trc20Store.addBalance(to, v);
          }
          trc20Proxy.emitTransfer(msg.sender, to, v);
        }

        trc20Store.setBalance(msg.sender, senderBalance);

        return true;
    }

    /** @notice  Enables the delegation of transfer control for many
      * accounts to the sweeper account, transferring any balances
      * as well to the given destination.
      *
      * @dev  An account delegates transfer control by signing the
      * value of `sweepMsg`. The sweeper account is the only authorized
      * caller of this function, so it must relay signatures on behalf
      * of accounts that delegate transfer control to it. Enabling
      * delegation is idempotent and permanent. If the account has a
      * balance at the time of enabling delegation, its balance is
      * also transferred to the given destination account `_to`.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _vs  The array of recovery byte components of the ECDSA signatures.
      * @param  _rs  The array of 'R' components of the ECDSA signatures.
      * @param  _ss  The array of 'S' components of the ECDSA signatures.
      * @param  _to  The destination for swept balances.
      */
    function enableSweep(uint8[] memory _vs, bytes32[] memory _rs, bytes32[] memory _ss, address _to) public onlySweeper {
        require(_to != address(0), "no null value for `_to`");
        require(blocked[_to] != true, "_to must not be blocked");
        require((_vs.length == _rs.length) && (_vs.length == _ss.length), "_vs[], _rs[], _ss lengths are different");

        uint256 numSignatures = _vs.length;
        uint256 sweptBalance = 0;

        for (uint256 i = 0; i < numSignatures; ++i) {
            address from = ecrecover(keccak256(abi.encodePacked("\x19TRON Signed Message:\n32",sweepMsg)), _vs[i], _rs[i], _ss[i]);
            require(blocked[from] != true, "_froms must not be blocked");
            // ecrecover returns 0 on malformed input
            if (from != address(0)) {
                sweptSet[from] = true;

                uint256 fromBalance = trc20Store.balances(from);

                if (fromBalance > 0) {
                    sweptBalance += fromBalance;

                    trc20Store.setBalance(from, 0);

                    trc20Proxy.emitTransfer(from, _to, fromBalance);
                }
            }
        }

        if (sweptBalance > 0) {
          trc20Store.addBalance(_to, sweptBalance);
        }
    }

    /** @notice  For accounts that have delegated, transfer control
      * to the sweeper, this function transfers their balances to the given
      * destination.
      *
      * @dev The sweeper account is the only authorized caller of
      * this function. This function accepts an array of addresses to have their
      * balances transferred for gas efficiency purposes.
      * NOTE: any address for an account that has not been previously enabled
      * will be ignored.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _froms  The addresses to have their balances swept.
      * @param  _to  The destination address of all these transfers.
      */
    function replaySweep(address[] memory _froms, address _to) public onlySweeper {
        require(_to != address(0), "no null value for `_to`");
        require(blocked[_to] != true, "_to must not be blocked");
        uint256 lenFroms = _froms.length;
        uint256 sweptBalance = 0;

        for (uint256 i = 0; i < lenFroms; ++i) {
            address from = _froms[i];
            require(blocked[from] != true, "_froms must not be blocked");
            if (sweptSet[from]) {
                uint256 fromBalance = trc20Store.balances(from);

                if (fromBalance > 0) {
                    sweptBalance += fromBalance;

                    trc20Store.setBalance(from, 0);

                    trc20Proxy.emitTransfer(from, _to, fromBalance);
                }
            }
        }

        if (sweptBalance > 0) {
            trc20Store.addBalance(_to, sweptBalance);
        }
    }

    /** @notice  Core logic of the TRC20 `transferFrom` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transferFrom` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in a proxy.
      */
    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        public
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "no null values for `_to`");
        require(blocked[_sender] != true, "_sender must not be blocked");
        require(blocked[_from] != true, "_from must not be blocked");
        require(blocked[_to] != true, "_to must not be blocked");

        uint256 balanceOfFrom = trc20Store.balances(_from);
        require(_value <= balanceOfFrom, "insufficient funds on `_from` balance");

        uint256 senderAllowance = trc20Store.allowed(_from, _sender);
        require(_value <= senderAllowance, "insufficient allowance amount");

        trc20Store.setBalance(_from, balanceOfFrom - _value);
        trc20Store.addBalance(_to, _value);

        trc20Store.setAllowance(_from, _sender, senderAllowance - _value);

        trc20Proxy.emitTransfer(_from, _to, _value);

        return true;
    }

    /** @notice  Core logic of the TRC20 `transfer` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transfer` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in a proxy.
      */
    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        public
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "no null value for `_to`");
        require(blocked[_sender] != true, "_sender must not be blocked");
        require(blocked[_to] != true, "_to must not be blocked");

        uint256 balanceOfSender = trc20Store.balances(_sender);
        require(_value <= balanceOfSender, "insufficient funds");

        trc20Store.setBalance(_sender, balanceOfSender - _value);
        trc20Store.addBalance(_to, _value);

        trc20Proxy.emitTransfer(_sender, _to, _value);

        return true;
    }

    /** @notice  Transfers the specified value from the balance in question.
      *
      * @dev  Suspected balance is subtracted by the amount which will be transferred.
      *
      * @dev If the suspected balance has less than the amount requested, it will be set to 0.
      *
      * @param  _from  The address of suspected balance.
      *
      * @param  _value  The amount to transfer.
      *
      * @return success true if the transfer succeeded.
      */
    function forceTransfer(
        address _from,
        address _to,
        uint256 _value
    )
        public
        onlyCustodian
        returns (bool success)
    {
        require(_to != address(0), "no null value for `_to`");
        uint256 balanceOfSender = trc20Store.balances(_from);
        if(_value <= balanceOfSender) {
            trc20Store.setBalance(_from, balanceOfSender - _value);
            trc20Store.addBalance(_to, _value);

            trc20Proxy.emitTransfer(_from, _to, _value);
        } else {
            trc20Store.setBalance(_from, 0);
            trc20Store.addBalance(_to, balanceOfSender);

            trc20Proxy.emitTransfer(_from, _to, balanceOfSender);
        }

        return true;
    }

    // METHODS (TRC20 sub interface impl.)
    /// @notice  Core logic of the TRC20 `totalSupply` function.
    function totalSupply() public view returns (uint256) {
        return trc20Store.totalSupply();
    }

    /// @notice  Core logic of the TRC20 `balanceOf` function.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return trc20Store.balances(_owner);
    }

    /// @notice  Core logic of the TRC20 `allowance` function.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return trc20Store.allowed(_owner, _spender);
    }

    /// @dev internal use only.
    function blockWallet(address wallet) public onlyCustodian returns (bool success) {
        blocked[wallet] = true;
        return true;
    }

    /// @dev internal use only.
    function unblockWallet(address wallet) public onlyCustodian returns (bool success) {
        blocked[wallet] = false;
        return true;
    }

    // EVENTS
    /// @dev  Emitted by successful `requestPrint` calls.
    event PrintingLocked(bytes32 _lockId, address _receiver, uint256 _value);

    /// @dev Emitted by successful `confirmPrint` calls.
    event PrintingConfirmed(bytes32 _lockId, address _receiver, uint256 _value);

    /** @dev Emitted by successful `confirmWipe` calls.
      *
      * @param _value Amount requested to be burned.
      *
      * @param _burned Amount which was burned.
      *
      * @param _balance Amount left on account after burn.
      *
      * @param _from Account which balance was burned.
      */
     event Wiped(address _from, uint256 _value, uint256 _burned, uint _balance);
}


//SourceUnit: TRC20ImplUpgradeable.sol

pragma solidity ^0.5.8;

import "./CustodianUpgradeable.sol";
import "./TRC20Impl.sol";

/** @title  A contract to inherit upgradeable token implementations.
  *
  * @notice  A contract that provides re-usable code for upgradeable
  * token implementations. It itself inherits from `CustodianUpgradable`
  * as the upgrade process is controlled by the custodian.
  *
  * @dev  This contract is intended to be inherited by any contract
  * requiring a reference to the active token implementation, either
  * to delegate calls to it, or authorize calls from it. This contract
  * provides the mechanism for that implementation to be replaced,
  * which constitutes an implementation upgrade.
  *
  */
contract TRC20ImplUpgradeable is CustodianUpgradeable  {

    // TYPES
    /// @dev  The struct type for pending implementation changes.
    struct ImplChangeRequest {
        address proposedNew;
    }

    // MEMBERS
    // @dev  The reference to the active token implementation.
    TRC20Impl public trc20Impl;

    /// @dev  The map of lock ids to pending implementation changes.
    mapping (bytes32 => ImplChangeRequest) public implChangeReqs;

    // CONSTRUCTOR
    constructor(address _custodian) CustodianUpgradeable(_custodian) public {
        trc20Impl = TRC20Impl(0x0);
    }

    // MODIFIERS
    modifier onlyImpl {
        require(msg.sender == address(trc20Impl), "only TRC20Impl");
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
    function requestImplChange(address _proposedImpl) public returns (bytes32 lockId) {
        require(_proposedImpl != address(0), "no null value for `_proposedImpl`");

        lockId = generateLockId();

        implChangeReqs[lockId] = ImplChangeRequest({
            proposedNew: _proposedImpl
        });

        emit ImplChangeRequested(lockId, msg.sender, _proposedImpl);
    }

    /** @notice  Confirms a pending change of the active implementation
      * associated with this contract.
      *
      * @dev  When called by the custodian with a lock id associated with a
      * pending change, the `TRC20Impl TRC20Impl` member will be updated
      * with the requested address.
      *
      * @param  _lockId  The identifier of a pending change request.
      */
    function confirmImplChange(bytes32 _lockId) public onlyCustodian {
        trc20Impl = getImplChangeReq(_lockId);

        delete implChangeReqs[_lockId];

        emit ImplChangeConfirmed(_lockId, address(trc20Impl));
    }

    // PRIVATE FUNCTIONS
    function getImplChangeReq(bytes32 _lockId) private view returns (TRC20Impl _proposedNew) {
        ImplChangeRequest storage changeRequest = implChangeReqs[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(changeRequest.proposedNew != address(0), "reject ‘null’ results from the map lookup");

        return TRC20Impl(changeRequest.proposedNew);
    }

    //EVENTS
    /// @dev  Emitted by successful `requestImplChange` calls.
    event ImplChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedImpl
    );

    /// @dev Emitted by successful `confirmImplChange` calls.
    event ImplChangeConfirmed(bytes32 _lockId, address _newImpl);
}

//SourceUnit: TRC20Interface.sol

pragma solidity ^0.5.8;

contract TRC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//SourceUnit: TRC20Proxy.sol

pragma solidity ^0.5.8;

import "./TRC20Impl.sol";
import "./TRC20Interface.sol";
import "./TRC20ImplUpgradeable.sol";

/** @title  Public interface to TRC20 compliant token.
  *
  * @notice  This contract is a permanent entry point to an TRC20 compliant
  * system of contracts.
  *
  * @dev  This contract contains no business logic and instead
  * delegates to an instance of TRC20Impl. This contract also has no storage
  * that constitutes the operational state of the token. This contract is
  * upgradeable in the sense that the `custodian` can update the
  * `TRC20Impl` address, thus redirecting the delegation of business logic.
  * The `custodian` is also authorized to pass custodianship.
  *
*/
contract TRC20Proxy is TRC20Interface, TRC20ImplUpgradeable {

    // MEMBERS
    /// @notice  Returns the name of the token.
    string public name;

    /// @notice  Returns the symbol of the token.
    string public symbol;

    /// @notice  Returns the number of decimals the token uses.
    uint8 public decimals;

    // CONSTRUCTOR
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _custodian
    )
        TRC20ImplUpgradeable(_custodian)
        public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // PUBLIC FUNCTIONS
    // (TRC20Interface)
    /** @notice  Returns the total token supply.
      *
      * @return  the total token supply.
      */
    function totalSupply() public view returns (uint256) {
        return trc20Impl.totalSupply();
    }

    /** @notice  Returns the account balance of another account with an address
      * `_owner`.
      *
      * @return  balance  the balance of account with address `_owner`.
      */
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return trc20Impl.balanceOf(tokenOwner);
    }

    /** @dev Internal use only.
      */
    function emitTransfer(address _from, address _to, uint256 _value) public onlyImpl {
        emit Transfer(_from, _to, _value);
    }

    /** @notice  Transfers `_value` amount of tokens to address `_to`.
      *
      * @dev Will fire the `Transfer` event. Will revert if the `_from`
      * account balance does not have enough tokens to spend.
      *
      * @return  success  true if transfer completes.
      */
    function transfer(address to, uint256 tokens) public returns (bool success) {
        return trc20Impl.transferWithSender(msg.sender, to, tokens);
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
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        return trc20Impl.transferFromWithSender(msg.sender, from, to, tokens);
    }

    /** @dev Internal use only.
      */
    function emitApproval(address _owner, address _spender, uint256 _value) public onlyImpl {
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
    function approve(address spender, uint256 tokens) public returns (bool success) {
        return trc20Impl.approveWithSender(msg.sender, spender, tokens);
    }

    /** @notice Increases the amount `_spender` is allowed to withdraw from
      * your account.
      * This function is implemented to avoid the race condition in standard
      * TRC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used instead of
      * `approve`.
      *
      * @return  success  true if approval completes.
      */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        return trc20Impl.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

    /** @notice  Decreases the amount `_spender` is allowed to withdraw from
      * your account. This function is implemented to avoid the race
      * condition in standard TRC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used
      * instead of `approve`.
      *
      * @return  success  true if approval completes.
      */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        return trc20Impl.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    /** @notice  Returns how much `_spender` is currently allowed to spend from
      * `_owner`'s balance.
      *
      * @return  remaining  the remaining allowance.
      */
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return trc20Impl.allowance(tokenOwner, spender);
    }
}


//SourceUnit: TRC20Store.sol

pragma solidity ^0.5.8;

import "./TRC20ImplUpgradeable.sol";

/** @title  TRC20 compliant token balance store.
  *
  * @notice  This contract serves as the store of balances, allowances, and
  * supply for the TRC20 compliant token. No business logic exists here.
  *
  * @dev  This contract contains no business logic and instead
  * is the final destination for any change in balances, allowances, or token
  * supply. This contract is upgradeable in the sense that its custodian can
  * update the `TRC20Impl` address, thus redirecting the source of logic that
  * determines how the balances will be updated.
  *
  */
contract TRC20Store is TRC20ImplUpgradeable {

    // MEMBERS
    /// @dev  The total token supply.
    uint256 public totalSupply;

    /// @dev  The mapping of balances.
    mapping (address => uint256) public balances;

    /// @dev  The mapping of allowances.
    mapping (address => mapping (address => uint256)) public allowed;

    // CONSTRUCTOR
    constructor(address _custodian) TRC20ImplUpgradeable(_custodian) public {
        totalSupply = 0;
    }

    // PUBLIC FUNCTIONS
    // (TRC20 Ledger)

    /** @notice  The function to set the total supply of tokens.
      *
      * @dev  Intended for use by token implementation functions
      * that update the total supply. The only authorized caller
      * is the active implementation.
      *
      * @param _newTotalSupply the value to set as the new total supply
      */
    function setTotalSupply(
        uint256 _newTotalSupply
    )
        public
        onlyImpl
    {
        totalSupply = _newTotalSupply;
    }

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
        public
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
        public
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
        public
        onlyImpl
    {
        balances[_owner] = balances[_owner] + _balanceIncrease;
    }
}