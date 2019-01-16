pragma solidity ^0.4.21;

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
contract LockRequestable {

    // MEMBERS
    /// @notice  the count of all invocations of `generateLockId`.
    uint256 public lockRequestCount;

    // CONSTRUCTOR
    function LockRequestable() public {
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
      * @return a 32-byte unique identifier.
      */
    function generateLockId() internal returns (bytes32 lockId) {
        return keccak256(block.blockhash(block.number - 1), address(this), ++lockRequestCount);
    }
}


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
    function CustodianUpgradeable(
        address _custodian
    )
      LockRequestable()
      public
    {
        custodian = _custodian;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian);
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
        require(_proposedCustodian != address(0));

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
        require(changeRequest.proposedNew != 0);

        return changeRequest.proposedNew;
    }

    /// @dev  Emitted by successful `requestCustodianChange` calls.
    event CustodianChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedCustodian
    );

    /// @dev Emitted by successful `confirmCustodianChange` calls.
    event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}


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
contract ERC20ImplUpgradeable is CustodianUpgradeable  {

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
    function ERC20ImplUpgradeable(address _custodian) CustodianUpgradeable(_custodian) public {
        erc20Impl = ERC20Impl(0x0);
    }

    // MODIFIERS
    modifier onlyImpl {
        require(msg.sender == address(erc20Impl));
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
        require(_proposedImpl != address(0));

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
      * pending change, the `ERC20Impl erc20Impl` member will be updated
      * with the requested address.
      *
      * @param  _lockId  The identifier of a pending change request.
      */
    function confirmImplChange(bytes32 _lockId) public onlyCustodian {
        erc20Impl = getImplChangeReq(_lockId);

        delete implChangeReqs[_lockId];

        emit ImplChangeConfirmed(_lockId, address(erc20Impl));
    }

    // PRIVATE FUNCTIONS
    function getImplChangeReq(bytes32 _lockId) private view returns (ERC20Impl _proposedNew) {
        ImplChangeRequest storage changeRequest = implChangeReqs[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(changeRequest.proposedNew != address(0));

        return ERC20Impl(changeRequest.proposedNew);
    }

    /// @dev  Emitted by successful `requestImplChange` calls.
    event ImplChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedImpl
    );

    /// @dev Emitted by successful `confirmImplChange` calls.
    event ImplChangeConfirmed(bytes32 _lockId, address _newImpl);
}


contract ERC20Interface {
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
  function totalSupply() public view returns (uint256);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#balanceof
  function balanceOf(address _owner) public view returns (uint256 balance);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer
  function transfer(address _to, uint256 _value) public returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transferfrom
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approve
  function approve(address _spender, uint256 _value) public returns (bool success);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#allowance
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  // EVENTS
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer-1
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#approval
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


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
contract ERC20Proxy is ERC20Interface, ERC20ImplUpgradeable {

    // MEMBERS
    /// @notice  Returns the name of the token.
    string public name;

    /// @notice  Returns the symbol of the token.
    string public symbol;

    /// @notice  Returns the number of decimals the token uses.
    uint8 public decimals;

    // CONSTRUCTOR
    function ERC20Proxy(
        string _name,
        string _symbol,
        uint8 _decimals,
        address _custodian
    )
        ERC20ImplUpgradeable(_custodian)
        public
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
    function totalSupply() public view returns (uint256) {
        return erc20Impl.totalSupply();
    }

    /** @notice  Returns the account balance of another account with address
      * `_owner`.
      *
      * @return  balance  the balance of account with address `_owner`.
      */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return erc20Impl.balanceOf(_owner);
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
    function transfer(address _to, uint256 _value) public returns (bool success) {
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return erc20Impl.transferFromWithSender(msg.sender, _from, _to, _value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
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
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        return erc20Impl.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    /** @notice  Returns how much `_spender` is currently allowed to spend from
      * `_owner`&#39;s balance.
      *
      * @return  remaining  the remaining allowance.
      */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return erc20Impl.allowance(_owner, _spender);
    }
}


/** @title  兼容ERC20标准的代币合约，从架构上来讲，本合约是一个居间的媒介合约，
  * 一边连接着实现了ERC20标准接口的ERC20Proxy合约，另一边连接着存储着代币账本的ERC20Store合约。
  * ERC20Proxy将具体执行动作的授权给了本合约来实现，而ERC20Strore则接收本合约的信息，记录动作执行
  * 所引发的账本变化；
  *
  * @dev  本合约除了执行ERC20标准的规定动作之外，还做了一些扩展，列示如下：
  * 1. 更改代表的总供应量；
  * 2. 批量转账；
  * 3. 更改授信额度；（a账户可以将一定代币授信给b账户，供其支配）
  * 4. 行使各账户的转账委托，控制转账行为（sweeping）
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Impl is CustodianUpgradeable {
     
    // 记录“增加代币供应（即印钱）”申请的自定义结构体.
    struct PendingPrint {
        address receiver; // 申请人，也是新增代币的接收人；用户将Dollar存入Gemini，自然会要求获得对应额度的GUSD
        uint256 value; // 申请印发的代币数量
    }
    // 成员变量
    ERC20Proxy public erc20Proxy; // 关联实现了ERC20标准的接口界面
    ERC20Store public erc20Store; // 关联本代币的账簿
    address public sweeper; // 被委托执行sweeping动作的唯一被委托人
    bytes32 public sweepMsg; // 当用户将转账能力授权给sweeper时，需要使用ECDSA方法对一段消息进行签名，这段消息就是sweepMsg
    mapping (address => bool) public sweptSet; // 记录address的sweeping授权情况；如果授权了，则返回True；
    mapping (bytes32 => PendingPrint) public pendingPrintMap; // 记录“印钱”的申请历史，每个申请对应一个lock id
    /// @dev  构造函数，初始化本合约；custodian是合约监护人；sweeper是执行sweeping的执行人
    function ERC20Impl(address _erc20Proxy,address _erc20Store,address _custodian,address _sweeper)
        CustodianUpgradeable(_custodian)
        public
    {
        require(_sweeper != 0);
        erc20Proxy = ERC20Proxy(_erc20Proxy);
        erc20Store = ERC20Store(_erc20Store); // 即对外结构proxy和数据存储，放在不同的合约中
        sweeper = _sweeper;
        sweepMsg = keccak256(address(this), "sweep"); //将授权需要签署的消息，初始化
    }
    modifier onlyProxy {
        require(msg.sender == address(erc20Proxy)); // 保证只接受从proxy界面传递过来的动作指令
        _;
    }
    modifier onlySweeper {
        require(msg.sender == sweeper); // 保证只有sweeping的指定执行人才能调用
        _;
    }
 
    // @notice  ERC20标准中规定的`approve`（授信）函数；只有erc20proxy合约能够调用他
    function approveWithSender(address _sender,address _spender,uint256 _value)
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0));
        erc20Store.setAllowance(_sender, _spender, _value); // 指示后台store账簿，记录授信
        erc20Proxy.emitApproval(_sender, _spender, _value); // 告知前台proxy界面，授信成功
        return true;
    }
    /// @notice 增加授信的核心代码；只有前台proxy能够调用次函数；
    function increaseApprovalWithSender(address _sender,address _spender,uint256 _addedValue)
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0));
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender); // 从后台Store那里获取当前的授信额度
        uint256 newAllowance = currentAllowance + _addedValue; // 获取增加授信后，授信的总额度
        require(newAllowance >= currentAllowance); // 防止溢出
        erc20Store.setAllowance(_sender, _spender, newAllowance); // 指示后台Store账簿，更新授信数量
        erc20Proxy.emitApproval(_sender, _spender, newAllowance); // 告知其他proxy界面，增加授信成功
        return true;
    }
    /// @notice  降低授信额度的核心代码；只有前台Proxy能够调用此函数
    function decreaseApprovalWithSender(address _sender,address _spender,uint256 _subtractedValue)
        public
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0));
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;
        require(newAllowance <= currentAllowance);
        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }
    /** @notice  申请印发新币，并将新币存入指定账号；每次申请，都对对应一个新生成的lock id
      *任何人都可以申请，但是最终确认需要调用confirmPrint来确认
      */
    function requestPrint(address _receiver, uint256 _value) public returns (bytes32 lockId) {
        require(_receiver != address(0));
        lockId = generateLockId();
        pendingPrintMap[lockId] = PendingPrint({
            receiver: _receiver,
            value: _value
        });
        emit PrintingLocked(lockId, _receiver, _value);
    }
    /// @notice  确认某个“印发新币”的申请;只有监护人Custodian才能执行此动作
    function confirmPrint(bytes32 _lockId) public onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_lockId];
        address receiver = print.receiver;
        require (receiver != address(0));
        uint256 value = print.value;
        delete pendingPrintMap[_lockId]; // 既然都已经确认了，就不算是申请了；从申请表中移除
        uint256 supply = erc20Store.totalSupply(); // 从后台Store那里获取当前的代币供应量
        uint256 newSupply = supply + value; // 印发新币后，总供应量是多少
        if (newSupply >= supply) {
          erc20Store.setTotalSupply(newSupply); // 指示后台Store账簿，更新总发行量
          erc20Store.addBalance(receiver, value); // 指示后台Store账簿，将印发的新币，存储指定账户
          emit PrintingConfirmed(_lockId, receiver, value); // 激发事件，通告印发成功
          erc20Proxy.emitTransfer(address(0), receiver, value); // 告知proxy前台，印发并转账成功
        }
    }
    /// @notice  将sender账户里面的代币，销毁
    function burn(uint256 _value) public returns (bool success) {
        uint256 balanceOfSender = erc20Store.balances(msg.sender); // 从后台store那里获取sender账户的有余额
        require(_value <= balanceOfSender); // 不能超额销毁
        erc20Store.setBalance(msg.sender, balanceOfSender - _value); // 指示后台Store执行销毁
        erc20Store.setTotalSupply(erc20Store.totalSupply() - _value); // 既然销毁了，那么总发行量也要更新
        erc20Proxy.emitTransfer(msg.sender, address(0), _value); // 通知proxy前台，销毁完成
        return true;
    }
    /** @notice  允许函数调用人（sender）将自己账户里面的钱，一次性的向一批账户，完成转账；
      * 毫无疑问，这样省gas费
      */
    function batchTransfer(address[] _tos, uint256[] _values) public returns (bool success) {
        require(_tos.length == _values.length);
        uint256 numTransfers = _tos.length;
        uint256 senderBalance = erc20Store.balances(msg.sender); // 获取sender的代币余额
        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0));
          uint256 v = _values[i];
          require(senderBalance >= v);
          if (msg.sender != to) {
            senderBalance -= v;
            erc20Store.addBalance(to, v);
          }
          erc20Proxy.emitTransfer(msg.sender, to, v);
        }
        erc20Store.setBalance(msg.sender, senderBalance); // 完成后，告知后台store，更新sender的有余额
        return true;
    }
    /** @notice  将一批账号的转账权限，委托给sweeper账号；当sweeper账号获得这个授权后，
      * 他就可以将这些账号中的余额转给任意账号；
      *
      * @dev 单个账号进行委托授权时，需要调用ECDSA方法签署sweepMsg；传递给本本方法后，
      * sweeper需要relay签名，获取用户地址，从而获得委托授权；
      *
      * @param  _vs  v 是ECDSA签名中的产生的“V”元素 - recovery byte components
      * @param  _rs  r 是ECDSA签名中产生的“R”元素
      * @param  _ss  s 是ECDSA签名中产生的“S”元素
      * @param  _to  承接余额的目的地账户地址
      */
    function enableSweep(uint8[] _vs, bytes32[] _rs, bytes32[] _ss, address _to) public onlySweeper {
        require(_to != address(0));
        require((_vs.length == _rs.length) && (_vs.length == _ss.length));
        uint256 numSignatures = _vs.length;
        uint256 sweptBalance = 0;
        for (uint256 i=0; i<numSignatures; ++i) {
          // 用户地址用ECDSA方法对数据进行签名，得到v-r-s三组字符；
          // 收到签名的人，可以用ecrecover(消息哈希值，v，r，s)获取当初签名的用户地址
          address from = ecrecover(sweepMsg, _vs[i], _rs[i], _ss[i]);
          if (from != address(0)) {
            sweptSet[from] = true; // 将授权记录在案；一朝授权，无须反复授权，sweeper可以反复转账
            uint256 fromBalance = erc20Store.balances(from); // 从后台Store那里获取账户余额
            if (fromBalance > 0) {
              sweptBalance += fromBalance;
              erc20Store.setBalance(from, 0); // 将代币从委托账户里转出
              erc20Proxy.emitTransfer(from, _to, fromBalance);
            }
          }
        }
        if (sweptBalance > 0) {
          erc20Store.addBalance(_to, sweptBalance); // 将余额全部转入目的地账户
        }
    }
    /** @notice  对于已经授权过的账户，sweeper可以反复将手伸进来，把钱拿走；
      * 因为授权信息已经在第一次就记录到sweptSet[]里面了，所以无须再次授权
      */
    function replaySweep(address[] _froms, address _to) public onlySweeper {
        require(_to != address(0));
        uint256 lenFroms = _froms.length;
        uint256 sweptBalance = 0;
        for (uint256 i=0; i<lenFroms; ++i) {
            address from = _froms[i];
            if (sweptSet[from]) {
                uint256 fromBalance = erc20Store.balances(from);
                if (fromBalance > 0) {
                    sweptBalance += fromBalance;
                    erc20Store.setBalance(from, 0);
                    erc20Proxy.emitTransfer(from, _to, fromBalance);
                }
            }
        }
        if (sweptBalance > 0) {
            erc20Store.addBalance(_to, sweptBalance);
        }
    }
    /// @notice  类似ERC20标注接口中的TransferFrom；属于扩展功能
    function transferFromWithSender(address _sender,address _from,address _to,uint256 _value)
        public
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0));
        uint256 balanceOfFrom = erc20Store.balances(_from);
        require(_value <= balanceOfFrom);
        uint256 senderAllowance = erc20Store.allowed(_from, _sender);
        require(_value <= senderAllowance);
        erc20Store.setBalance(_from, balanceOfFrom - _value);
        erc20Store.addBalance(_to, _value);
        erc20Store.setAllowance(_from, _sender, senderAllowance - _value);
        erc20Proxy.emitTransfer(_from, _to, _value);
        return true;
    }
    /// @notice  类似ERC20标注接口中的Transfer; 属于扩展功能
    function transferWithSender(address _sender,address _to,uint256 _value)
        public
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0));
        uint256 balanceOfSender = erc20Store.balances(_sender);
        require(_value <= balanceOfSender);
        erc20Store.setBalance(_sender, balanceOfSender - _value);
        erc20Store.addBalance(_to, _value);
        erc20Proxy.emitTransfer(_sender, _to, _value);
        return true;
    }
    /// @notice  实现ERC20标准接口中的totalSupply
    function totalSupply() public view returns (uint256) {
        return erc20Store.totalSupply();
    }
    /// @notice  实现ERC20标准接口中的balanceOf
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return erc20Store.balances(_owner);
    }
    /// @notice  实现ERC20标准接口中的allowance
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }
    /// 印发新币申请成功时，会激发此事件
    event PrintingLocked(bytes32 _lockId, address _receiver, uint256 _value);
    /// 印发新币的申请被确认后，会激发此事件
    event PrintingConfirmed(bytes32 _lockId, address _receiver, uint256 _value);
}


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

    // CONSTRUCTOR
    function ERC20Store(address _custodian) ERC20ImplUpgradeable(_custodian) public {
        totalSupply = 0;
    }


    // PUBLIC FUNCTIONS
    // (ERC20 Ledger)

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

    /** @notice Adds `_balanceIncrease` to `_owner`&#39;s balance.
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
  * (the &#39;limited printer&#39;) to increase the token supply up to a ceiling,
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
    ERC20Impl public erc20Impl;

    /// @dev  The address of the account or contract that acts as the custodian.
    address public custodian;

    /** @dev  The sole authorized caller of limited printing.
      * This account is also authorized to lower the supply ceiling.
      */
    address public limitedPrinter;

    /** @dev  The maximum that the token supply can be increased to
      * through use of the limited printing feature.
      * The difference between the current total supply and the supply
      * ceiling is what is available to the &#39;limited printer&#39; account.
      * The value of the ceiling can only be increased by the custodian.
      */
    uint256 public totalSupplyCeiling;

    /// @dev  The map of lock ids to pending ceiling raises.
    mapping (bytes32 => PendingCeilingRaise) public pendingRaiseMap;

    // CONSTRUCTOR
    function PrintLimiter(
        address _erc20Impl,
        address _custodian,
        address _limitedPrinter,
        uint256 _initialCeiling
    )
        public
    {
        erc20Impl = ERC20Impl(_erc20Impl);
        custodian = _custodian;
        limitedPrinter = _limitedPrinter;
        totalSupplyCeiling = _initialCeiling;
    }

    // MODIFIERS
    modifier onlyCustodian {
        require(msg.sender == custodian);
        _;
    }
    modifier onlyLimitedPrinter {
        require(msg.sender == limitedPrinter);
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
    function limitedPrint(address _receiver, uint256 _value) public onlyLimitedPrinter {
        uint256 totalSupply = erc20Impl.totalSupply();
        uint256 newTotalSupply = totalSupply + _value;

        require(newTotalSupply >= totalSupply);
        require(newTotalSupply <= totalSupplyCeiling);
        erc20Impl.confirmPrint(erc20Impl.requestPrint(_receiver, _value));
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
    function requestCeilingRaise(uint256 _raiseBy) public returns (bytes32 lockId) {
        require(_raiseBy != 0);

        lockId = generateLockId();

        pendingRaiseMap[lockId] = PendingCeilingRaise({
            raiseBy: _raiseBy
        });

        emit CeilingRaiseLocked(lockId, _raiseBy);
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
    function confirmCeilingRaise(bytes32 _lockId) public onlyCustodian {
        PendingCeilingRaise storage pendingRaise = pendingRaiseMap[_lockId];

        // copy locals of references to struct members
        uint256 raiseBy = pendingRaise.raiseBy;
        // accounts for a gibberish _lockId
        require(raiseBy != 0);

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
    function lowerCeiling(uint256 _lowerBy) public onlyLimitedPrinter {
        uint256 newCeiling = totalSupplyCeiling - _lowerBy;
        // overflow check
        require(newCeiling <= totalSupplyCeiling);
        totalSupplyCeiling = newCeiling;

        emit CeilingLowered(_lowerBy, newCeiling);
    }

    /** @notice  Pass-through control of print confirmation, allowing this
      * contract&#39;s custodian to act as the custodian of the associated
      * active token implementation.
      *
      * @dev  This contract is the direct custodian of the active token
      * implementation, but this function allows this contract&#39;s custodian
      * to act as though it were the direct custodian of the active
      * token implementation. Therefore the custodian retains control of
      * unlimited printing.
      *
      * @param  _lockId  The identifier of a pending print request in
      * the associated active token implementation.
      */
    function confirmPrintProxy(bytes32 _lockId) public onlyCustodian {
        erc20Impl.confirmPrint(_lockId);
    }

    /** @notice  Pass-through control of custodian change confirmation,
      * allowing this contract&#39;s custodian to act as the custodian of
      * the associated active token implementation.
      *
      * @dev  This contract is the direct custodian of the active token
      * implementation, but this function allows this contract&#39;s custodian
      * to act as though it were the direct custodian of the active
      * token implementation. Therefore the custodian retains control of
      * custodian changes.
      *
      * @param  _lockId  The identifier of a pending custodian change request
      * in the associated active token implementation.
      */
    function confirmCustodianChangeProxy(bytes32 _lockId) public onlyCustodian {
        erc20Impl.confirmCustodianChange(_lockId);
    }

    // EVENTS
    /// @dev  Emitted by successful `requestCeilingRaise` calls.
    event CeilingRaiseLocked(bytes32 _lockId, uint256 _raiseBy);
    /// @dev  Emitted by successful `confirmCeilingRaise` calls.
    event CeilingRaiseConfirmed(bytes32 _lockId, uint256 _raiseBy, uint256 _newCeiling);

    /// @dev  Emitted by successful `lowerCeiling` calls.
    event CeilingLowered(uint256 _lowerBy, uint256 _newCeiling);
}