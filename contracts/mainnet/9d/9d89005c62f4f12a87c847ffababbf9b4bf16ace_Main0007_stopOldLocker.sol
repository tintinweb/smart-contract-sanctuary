pragma solidity 0.4.24;

// File: contracts/generic/Restricted.sol

/*
    Generic contract to authorise calls to certain functions only from a given address.
    The address authorised must be a contract (multisig or not, depending on the permission), except for local test

    deployment works as:
           1. contract deployer account deploys contracts
           2. constructor grants "PermissionGranter" permission to deployer account
           3. deployer account executes initial setup (no multiSig)
           4. deployer account grants PermissionGranter permission for the MultiSig contract
                (e.g. StabilityBoardProxy or PreTokenProxy)
           5. deployer account revokes its own PermissionGranter permission
*/

pragma solidity 0.4.24;


contract Restricted {

    // NB: using bytes32 rather than the string type because it&#39;s cheaper gas-wise:
    mapping (address => mapping (bytes32 => bool)) public permissions;

    event PermissionGranted(address indexed agent, bytes32 grantedPermission);
    event PermissionRevoked(address indexed agent, bytes32 revokedPermission);

    modifier restrict(bytes32 requiredPermission) {
        require(permissions[msg.sender][requiredPermission], "msg.sender must have permission");
        _;
    }

    constructor(address permissionGranterContract) public {
        require(permissionGranterContract != address(0), "permissionGranterContract must be set");
        permissions[permissionGranterContract]["PermissionGranter"] = true;
        emit PermissionGranted(permissionGranterContract, "PermissionGranter");
    }

    function grantPermission(address agent, bytes32 requiredPermission) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        permissions[agent][requiredPermission] = true;
        emit PermissionGranted(agent, requiredPermission);
    }

    function grantMultiplePermissions(address agent, bytes32[] requiredPermissions) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        uint256 length = requiredPermissions.length;
        for (uint256 i = 0; i < length; i++) {
            grantPermission(agent, requiredPermissions[i]);
        }
    }

    function revokePermission(address agent, bytes32 requiredPermission) public {
        require(permissions[msg.sender]["PermissionGranter"],
            "msg.sender must have PermissionGranter permission");
        permissions[agent][requiredPermission] = false;
        emit PermissionRevoked(agent, requiredPermission);
    }

    function revokeMultiplePermissions(address agent, bytes32[] requiredPermissions) public {
        uint256 length = requiredPermissions.length;
        for (uint256 i = 0; i < length; i++) {
            revokePermission(agent, requiredPermissions[i]);
        }
    }

}

// File: contracts/generic/SafeMath.sol

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error

    TODO: check against ds-math: https://blog.dapphub.com/ds-math/
    TODO: move roundedDiv to a sep lib? (eg. Math.sol)
*/
pragma solidity 0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function roundedDiv(uint a, uint b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        uint256 z = a / b;
        if (a % b >= b / 2) {
            z++;  // no need for safe add b/c it can happen only if we divided the input
        }
        return z;
    }

    // Always rounds up
    function ceilDiv(uint a, uint b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        uint256 z = a / b;
        if (a % b != 0) {
            z++;  // no need for safe add b/c it can happen only if we divided the input
        }
        return z;
    }
}

// File: contracts/interfaces/TransferFeeInterface.sol

/*
 *  transfer fee calculation interface
 *
 */
pragma solidity 0.4.24;


interface TransferFeeInterface {
    function calculateTransferFee(address from, address to, uint amount) external view returns (uint256 fee);
}

// File: contracts/interfaces/ERC20Interface.sol

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
pragma solidity 0.4.24;


interface ERC20Interface {
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed from, address indexed to, uint amount);

    function transfer(address to, uint value) external returns (bool); // solhint-disable-line no-simple-event-func-name
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address who) external view returns (uint);
    function allowance(address _owner, address _spender) external view returns (uint remaining);

}

// File: contracts/interfaces/TokenReceiver.sol

/*
 *  receiver contract interface
 * see https://github.com/ethereum/EIPs/issues/677
 */
pragma solidity 0.4.24;


interface TokenReceiver {
    function transferNotification(address from, uint256 amount, uint data) external;
}

// File: contracts/interfaces/AugmintTokenInterface.sol

/* Augmint Token interface (abstract contract)

TODO: overload transfer() & transferFrom() instead of transferWithNarrative() & transferFromWithNarrative()
      when this fix available in web3& truffle also uses that web3: https://github.com/ethereum/web3.js/pull/1185
TODO: shall we use bytes for narrative?
 */
pragma solidity 0.4.24;







contract AugmintTokenInterface is Restricted, ERC20Interface {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    bytes32 public peggedSymbol;
    uint8 public decimals;

    uint public totalSupply;
    mapping(address => uint256) public balances; // Balances for each account
    mapping(address => mapping (address => uint256)) public allowed; // allowances added with approve()

    address public stabilityBoardProxy;
    TransferFeeInterface public feeAccount;
    mapping(bytes32 => bool) public delegatedTxHashesUsed; // record txHashes used by delegatedTransfer

    event TransferFeesChanged(uint transferFeePt, uint transferFeeMin, uint transferFeeMax);
    event Transfer(address indexed from, address indexed to, uint amount);
    event AugmintTransfer(address indexed from, address indexed to, uint amount, string narrative, uint fee);
    event TokenIssued(uint amount);
    event TokenBurned(uint amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address to, uint value) external returns (bool); // solhint-disable-line no-simple-event-func-name
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);

    function delegatedTransfer(address from, address to, uint amount, string narrative,
                                    uint maxExecutorFeeInToken, /* client provided max fee for executing the tx */
                                    bytes32 nonce, /* random nonce generated by client */
                                    /* ^^^^ end of signed data ^^^^ */
                                    bytes signature,
                                    uint requestedExecutorFeeInToken /* the executor can decide to request lower fee */
                                ) external;

    function delegatedTransferAndNotify(address from, TokenReceiver target, uint amount, uint data,
                                    uint maxExecutorFeeInToken, /* client provided max fee for executing the tx */
                                    bytes32 nonce, /* random nonce generated by client */
                                    /* ^^^^ end of signed data ^^^^ */
                                    bytes signature,
                                    uint requestedExecutorFeeInToken /* the executor can decide to request lower fee */
                                ) external;

    function increaseApproval(address spender, uint addedValue) external returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) external returns (bool);

    function issueTo(address to, uint amount) external; // restrict it to "MonetarySupervisor" in impl.;
    function burn(uint amount) external;

    function transferAndNotify(TokenReceiver target, uint amount, uint data) external;

    function transferWithNarrative(address to, uint256 amount, string narrative) external;
    function transferFromWithNarrative(address from, address to, uint256 amount, string narrative) external;

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address who) external view returns (uint);


}

// File: contracts/generic/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ECRecovery.sol
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}

// File: contracts/generic/AugmintToken.sol

/* Generic Augmint Token implementation (ERC20 token)
    This contract manages:
        * Balances of Augmint holders and transactions between them
        * Issues/burns tokens

    TODO:
        - reconsider delegatedTransfer and how to structure it
        - shall we allow change of txDelegator?
        - consider generic bytes arg instead of uint for transferAndNotify
        - consider separate transfer fee params and calculation to separate contract (to feeAccount?)
*/
pragma solidity 0.4.24;






contract AugmintToken is AugmintTokenInterface {

    event FeeAccountChanged(TransferFeeInterface newFeeAccount);

    constructor(address permissionGranterContract, string _name, string _symbol, bytes32 _peggedSymbol, uint8 _decimals, TransferFeeInterface _feeAccount)
    public Restricted(permissionGranterContract) {
        require(_feeAccount != address(0), "feeAccount must be set");
        require(bytes(_name).length > 0, "name must be set");
        require(bytes(_symbol).length > 0, "symbol must be set");

        name = _name;
        symbol = _symbol;
        peggedSymbol = _peggedSymbol;
        decimals = _decimals;

        feeAccount = _feeAccount;

    }
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount, "");
        return true;
    }

    /* Transfers based on an offline signed transfer instruction. */
    function delegatedTransfer(address from, address to, uint amount, string narrative,
                                     uint maxExecutorFeeInToken, /* client provided max fee for executing the tx */
                                     bytes32 nonce, /* random nonce generated by client */
                                     /* ^^^^ end of signed data ^^^^ */
                                     bytes signature,
                                     uint requestedExecutorFeeInToken /* the executor can decide to request lower fee */
                                     )
    external {
        bytes32 txHash = keccak256(abi.encodePacked(this, from, to, amount, narrative, maxExecutorFeeInToken, nonce));

        _checkHashAndTransferExecutorFee(txHash, signature, from, maxExecutorFeeInToken, requestedExecutorFeeInToken);

        _transfer(from, to, amount, narrative);
    }

    function approve(address _spender, uint256 amount) external returns (bool) {
        require(_spender != 0x0, "spender must be set");
        allowed[msg.sender][_spender] = amount;
        emit Approval(msg.sender, _spender, amount);
        return true;
    }

    /**
     ERC20 transferFrom attack protection: https://github.com/DecentLabs/dcm-poc/issues/57
     approve should be called when allowed[_spender] == 0. To increment allowed value is better
     to use this function to avoid 2 calls (and wait until the first transaction is mined)
     Based on MonolithDAO Token.sol */
    function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
        return _increaseApproval(msg.sender, _spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _transferFrom(from, to, amount, "");
        return true;
    }

    // Issue tokens. See MonetarySupervisor but as a rule of thumb issueTo is only allowed:
    //      - on new loan (by trusted Lender contracts)
    //      - when converting old tokens using MonetarySupervisor
    //      - strictly to reserve by Stability Board (via MonetarySupervisor)
    function issueTo(address to, uint amount) external restrict("MonetarySupervisor") {
        balances[to] = balances[to].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Transfer(0x0, to, amount);
        emit AugmintTransfer(0x0, to, amount, "", 0);
    }

    // Burn tokens. Anyone can burn from its own account. YOLO.
    // Used by to burn from Augmint reserve or by Lender contract after loan repayment
    function burn(uint amount) external {
        require(balances[msg.sender] >= amount, "balance must be >= amount");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, 0x0, amount);
        emit AugmintTransfer(msg.sender, 0x0, amount, "", 0);
    }

    /* to upgrade feeAccount (eg. for fee calculation changes) */
    function setFeeAccount(TransferFeeInterface newFeeAccount) external restrict("StabilityBoard") {
        feeAccount = newFeeAccount;
        emit FeeAccountChanged(newFeeAccount);
    }

    /*  transferAndNotify can be used by contracts which require tokens to have only 1 tx (instead of approve + call)
        Eg. repay loan, lock funds, token sell order on exchange
        Reverts on failue:
            - transfer fails
            - if transferNotification fails (callee must revert on failure)
            - if targetContract is an account or targetContract doesn&#39;t have neither transferNotification or fallback fx
        TODO: make data param generic bytes (see receiver code attempt in Locker.transferNotification)
    */
    function transferAndNotify(TokenReceiver target, uint amount, uint data) external {
        _transfer(msg.sender, target, amount, "");

        target.transferNotification(msg.sender, amount, data);
    }

    /* transferAndNotify based on an  instruction signed offline  */
    function delegatedTransferAndNotify(address from, TokenReceiver target, uint amount, uint data,
                                     uint maxExecutorFeeInToken, /* client provided max fee for executing the tx */
                                     bytes32 nonce, /* random nonce generated by client */
                                     /* ^^^^ end of signed data ^^^^ */
                                     bytes signature,
                                     uint requestedExecutorFeeInToken /* the executor can decide to request lower fee */
                                     )
    external {
        bytes32 txHash = keccak256(abi.encodePacked(this, from, target, amount, data, maxExecutorFeeInToken, nonce));

        _checkHashAndTransferExecutorFee(txHash, signature, from, maxExecutorFeeInToken, requestedExecutorFeeInToken);

        _transfer(from, target, amount, "");
        target.transferNotification(from, amount, data);
    }


    function transferWithNarrative(address to, uint256 amount, string narrative) external {
        _transfer(msg.sender, to, amount, narrative);
    }

    function transferFromWithNarrative(address from, address to, uint256 amount, string narrative) external {
        _transferFrom(from, to, amount, narrative);
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function _checkHashAndTransferExecutorFee(bytes32 txHash, bytes signature, address signer,
                                                uint maxExecutorFeeInToken, uint requestedExecutorFeeInToken) private {
        require(requestedExecutorFeeInToken <= maxExecutorFeeInToken, "requestedExecutorFee must be <= maxExecutorFee");
        require(!delegatedTxHashesUsed[txHash], "txHash already used");
        delegatedTxHashesUsed[txHash] = true;

        address recovered = ECRecovery.recover(ECRecovery.toEthSignedMessageHash(txHash), signature);
        require(recovered == signer, "invalid signature");

        _transfer(signer, msg.sender, requestedExecutorFeeInToken, "Delegated transfer fee", 0);
    }

    function _increaseApproval(address _approver, address _spender, uint _addedValue) private returns (bool) {
        allowed[_approver][_spender] = allowed[_approver][_spender].add(_addedValue);
        emit Approval(_approver, _spender, allowed[_approver][_spender]);
    }

    function _transferFrom(address from, address to, uint256 amount, string narrative) private {
        require(balances[from] >= amount, "balance must >= amount");
        require(allowed[from][msg.sender] >= amount, "allowance must be >= amount");
        // don&#39;t allow 0 transferFrom if no approval:
        require(allowed[from][msg.sender] > 0, "allowance must be >= 0 even with 0 amount");

        /* NB: fee is deducted from owner. It can result that transferFrom of amount x to fail
                when x + fee is not availale on owner balance */
        _transfer(from, to, amount, narrative);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
    }

    function _transfer(address from, address to, uint transferAmount, string narrative) private {
        uint fee = feeAccount.calculateTransferFee(from, to, transferAmount);

        _transfer(from, to, transferAmount, narrative, fee);
    }

    function _transfer(address from, address to, uint transferAmount, string narrative, uint fee) private {
        require(to != 0x0, "to must be set");
        uint amountWithFee = transferAmount.add(fee);
        // to emit proper reason instead of failing on from.sub()
        require(balances[from] >= amountWithFee, "balance must be >= amount + transfer fee");

        if (fee > 0) {
            balances[feeAccount] = balances[feeAccount].add(fee);
            emit Transfer(from, feeAccount, fee);
        }

        balances[from] = balances[from].sub(amountWithFee);
        balances[to] = balances[to].add(transferAmount);

        emit Transfer(from, to, transferAmount);
        emit AugmintTransfer(from, to, transferAmount, narrative, fee);
    }

}

// File: contracts/generic/SystemAccount.sol

/* Contract to collect fees from system */
pragma solidity 0.4.24;




contract SystemAccount is Restricted {
    event WithdrawFromSystemAccount(address tokenAddress, address to, uint tokenAmount, uint weiAmount,
                                    string narrative);

    constructor(address permissionGranterContract) public Restricted(permissionGranterContract) {} // solhint-disable-line no-empty-blocks

    /* TODO: this is only for first pilots to avoid funds stuck in contract due to bugs.
      remove this function for higher volume pilots */
    function withdraw(AugmintToken tokenAddress, address to, uint tokenAmount, uint weiAmount, string narrative)
    external restrict("StabilityBoard") {
        tokenAddress.transferWithNarrative(to, tokenAmount, narrative);
        if (weiAmount > 0) {
            to.transfer(weiAmount);
        }

        emit WithdrawFromSystemAccount(tokenAddress, to, tokenAmount, weiAmount, narrative);
    }

}

// File: contracts/AugmintReserves.sol

/* Contract to hold Augmint reserves (ETH & Token)
    - ETH as regular ETH balance of the contract
    - ERC20 token reserve (stored as regular Token balance under the contract address)

NB: reserves are held under the contract address, therefore any transaction on the reserve is limited to the
    tx-s defined here (i.e. transfer is not allowed even by the contract owner or StabilityBoard or MonetarySupervisor)

 */

pragma solidity 0.4.24;




contract AugmintReserves is SystemAccount {

    function () public payable { // solhint-disable-line no-empty-blocks
        // to accept ETH sent into reserve (from defaulted loan&#39;s collateral )
    }

    constructor(address permissionGranterContract) public SystemAccount(permissionGranterContract) {} // solhint-disable-line no-empty-blocks

    function burn(AugmintTokenInterface augmintToken, uint amount) external restrict("MonetarySupervisor") {
        augmintToken.burn(amount);
    }

}

// File: contracts/InterestEarnedAccount.sol

/* Contract to hold earned interest from loans repaid
   premiums for locks are being accrued (i.e. transferred) to Locker */

pragma solidity 0.4.24;




contract InterestEarnedAccount is SystemAccount {

    constructor(address permissionGranterContract) public SystemAccount(permissionGranterContract) {} // solhint-disable-line no-empty-blocks

    function transferInterest(AugmintTokenInterface augmintToken, address locker, uint interestAmount)
    external restrict("MonetarySupervisor") {
        augmintToken.transfer(locker, interestAmount);
    }

}

// File: contracts/MonetarySupervisor.sol

/* MonetarySupervisor
    - maintains system wide KPIs (eg totalLockAmount, totalLoanAmount)
    - holds system wide parameters/limits
    - enforces system wide limits
    - burns and issues to AugmintReserves
    - Send funds from reserve to exchange when intervening (not implemented yet)
    - Converts older versions of AugmintTokens in 1:1 to new
*/

pragma solidity 0.4.24;








contract MonetarySupervisor is Restricted, TokenReceiver { // solhint-disable-line no-empty-blocks
    using SafeMath for uint256;

    uint public constant PERCENT_100 = 1000000;

    AugmintTokenInterface public augmintToken;
    InterestEarnedAccount public interestEarnedAccount;
    AugmintReserves public augmintReserves;

    uint public issuedByStabilityBoard; // token issued  by Stability Board

    uint public totalLoanAmount; // total amount of all loans without interest, in token
    uint public totalLockedAmount; // total amount of all locks without premium, in token

    /**********
        Parameters to ensure totalLoanAmount or totalLockedAmount difference is within limits and system also works
        when total loan or lock amounts are low.
            for test calculations: https://docs.google.com/spreadsheets/d/1MeWYPYZRIm1n9lzpvbq8kLfQg1hhvk5oJY6NrR401S0
    **********/
    struct LtdParams {
        uint  lockDifferenceLimit; /* only allow a new lock if Loan To Deposit ratio would stay above
                                            (1 - lockDifferenceLimit) with new lock. Stored as parts per million */
        uint  loanDifferenceLimit; /* only allow a new loan if Loan To Deposit ratio would stay above
                                            (1 + loanDifferenceLimit) with new loan. Stored as parts per million */
        /* allowedDifferenceAmount param is to ensure the system is not "freezing" when totalLoanAmount or
            totalLockAmount is low.
        It allows a new loan or lock (up to an amount to reach this difference) even if LTD will go below / above
            lockDifferenceLimit / loanDifferenceLimit with the new lock/loan */
        uint  allowedDifferenceAmount;
    }

    LtdParams public ltdParams;

    /* Previously deployed AugmintTokens which are accepted for conversion (see transferNotification() )
        NB: it&#39;s not iterable so old version addresses needs to be added for UI manually after each deploy */
    mapping(address => bool) public acceptedLegacyAugmintTokens;

    event LtdParamsChanged(uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount);

    event AcceptedLegacyAugmintTokenChanged(address augmintTokenAddress, bool newAcceptedState);

    event LegacyTokenConverted(address oldTokenAddress, address account, uint amount);

    event KPIsAdjusted(uint totalLoanAmountAdjustment, uint totalLockedAmountAdjustment);

    event SystemContractsChanged(InterestEarnedAccount newInterestEarnedAccount, AugmintReserves newAugmintReserves);

    constructor(address permissionGranterContract, AugmintTokenInterface _augmintToken, AugmintReserves _augmintReserves,
        InterestEarnedAccount _interestEarnedAccount,
        uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount)
    public Restricted(permissionGranterContract) {
        augmintToken = _augmintToken;
        augmintReserves = _augmintReserves;
        interestEarnedAccount = _interestEarnedAccount;

        ltdParams = LtdParams(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);
    }

    function issueToReserve(uint amount) external restrict("StabilityBoard") {
        issuedByStabilityBoard = issuedByStabilityBoard.add(amount);
        augmintToken.issueTo(augmintReserves, amount);
    }

    function burnFromReserve(uint amount) external restrict("StabilityBoard") {
        issuedByStabilityBoard = issuedByStabilityBoard.sub(amount);
        augmintReserves.burn(augmintToken, amount);
    }

    /* Locker requesting interest when locking funds. Enforcing LTD to stay within range allowed by LTD params
        NB: it does not know about min loan amount, it&#39;s the loan contract&#39;s responsibility to enforce it  */
    function requestInterest(uint amountToLock, uint interestAmount) external {
        // only whitelisted Locker
        require(permissions[msg.sender]["Locker"], "msg.sender must have Locker permission");
        require(amountToLock <= getMaxLockAmountAllowedByLtd(), "amountToLock must be <= maxLockAmountAllowedByLtd");

        totalLockedAmount = totalLockedAmount.add(amountToLock);
        // next line would revert but require to emit reason:
        require(augmintToken.balanceOf(address(interestEarnedAccount)) >= interestAmount,
            "interestEarnedAccount balance must be >= interestAmount");
        interestEarnedAccount.transferInterest(augmintToken, msg.sender, interestAmount); // transfer interest to Locker
    }

    // Locker notifying when releasing funds to update KPIs
    function releaseFundsNotification(uint lockedAmount) external {
        // only whitelisted Locker
        require(permissions[msg.sender]["Locker"], "msg.sender must have Locker permission");
        totalLockedAmount = totalLockedAmount.sub(lockedAmount);
    }

    /* Issue loan if LTD stays within range allowed by LTD params
        NB: it does not know about min loan amount, it&#39;s the loan contract&#39;s responsibility to enforce it */
    function issueLoan(address borrower, uint loanAmount) external {
         // only whitelisted LoanManager contracts
        require(permissions[msg.sender]["LoanManager"],
            "msg.sender must have LoanManager permission");
        require(loanAmount <= getMaxLoanAmountAllowedByLtd(), "loanAmount must be <= maxLoanAmountAllowedByLtd");
        totalLoanAmount = totalLoanAmount.add(loanAmount);
        augmintToken.issueTo(borrower, loanAmount);
    }

    function loanRepaymentNotification(uint loanAmount) external {
        // only whitelisted LoanManager contracts
       require(permissions[msg.sender]["LoanManager"],
           "msg.sender must have LoanManager permission");
        totalLoanAmount = totalLoanAmount.sub(loanAmount);
    }

    // NB: this is called by Lender contract with the sum of all loans collected in batch
    function loanCollectionNotification(uint totalLoanAmountCollected) external {
        // only whitelisted LoanManager contracts
       require(permissions[msg.sender]["LoanManager"],
           "msg.sender must have LoanManager permission");
        totalLoanAmount = totalLoanAmount.sub(totalLoanAmountCollected);
    }

    function setAcceptedLegacyAugmintToken(address legacyAugmintTokenAddress, bool newAcceptedState)
    external restrict("StabilityBoard") {
        acceptedLegacyAugmintTokens[legacyAugmintTokenAddress] = newAcceptedState;
        emit AcceptedLegacyAugmintTokenChanged(legacyAugmintTokenAddress, newAcceptedState);
    }

    function setLtdParams(uint lockDifferenceLimit, uint loanDifferenceLimit, uint allowedDifferenceAmount)
    external restrict("StabilityBoard") {
        ltdParams = LtdParams(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);

        emit LtdParamsChanged(lockDifferenceLimit, loanDifferenceLimit, allowedDifferenceAmount);
    }

    /* function to migrate old totalLoanAmount and totalLockedAmount from old monetarySupervisor contract
        when it&#39;s upgraded.
        Set new monetarySupervisor contract in all locker and loanManager contracts before executing this */
    function adjustKPIs(uint totalLoanAmountAdjustment, uint totalLockedAmountAdjustment)
    external restrict("StabilityBoard") {
        totalLoanAmount = totalLoanAmount.add(totalLoanAmountAdjustment);
        totalLockedAmount = totalLockedAmount.add(totalLockedAmountAdjustment);

        emit KPIsAdjusted(totalLoanAmountAdjustment, totalLockedAmountAdjustment);
    }

    /* to allow upgrades of InterestEarnedAccount and AugmintReserves contracts. */
    function setSystemContracts(InterestEarnedAccount newInterestEarnedAccount, AugmintReserves newAugmintReserves)
    external restrict("StabilityBoard") {
        interestEarnedAccount = newInterestEarnedAccount;
        augmintReserves = newAugmintReserves;
        emit SystemContractsChanged(newInterestEarnedAccount, newAugmintReserves);
    }

    /* User can request to convert their tokens from older AugmintToken versions in 1:1
      transferNotification is called from AugmintToken&#39;s transferAndNotify
     Flow for converting old tokens:
        1) user calls old token contract&#39;s transferAndNotify with the amount to convert,
                addressing the new MonetarySupervisor Contract
        2) transferAndNotify transfers user&#39;s old tokens to the current MonetarySupervisor contract&#39;s address
        3) transferAndNotify calls MonetarySupervisor.transferNotification
        4) MonetarySupervisor checks if old AugmintToken is permitted
        5) MonetarySupervisor issues new tokens to user&#39;s account in current AugmintToken
        6) MonetarySupervisor burns old tokens from own balance
    */
    function transferNotification(address from, uint amount, uint /* data, not used */ ) external {
        AugmintTokenInterface legacyToken = AugmintTokenInterface(msg.sender);
        require(acceptedLegacyAugmintTokens[legacyToken], "msg.sender must be allowed in acceptedLegacyAugmintTokens");

        legacyToken.burn(amount);
        augmintToken.issueTo(from, amount);
        emit LegacyTokenConverted(msg.sender, from, amount);
    }

    function getLoanToDepositRatio() external view returns (uint loanToDepositRatio) {
        loanToDepositRatio = totalLockedAmount == 0 ? 0 : totalLockedAmount.mul(PERCENT_100).div(totalLoanAmount);
    }

    /* Helper function for UI.
        Returns max lock amount based on minLockAmount, interestPt, using LTD params & interestEarnedAccount balance */
    function getMaxLockAmount(uint minLockAmount, uint interestPt) external view returns (uint maxLock) {
        uint allowedByEarning = augmintToken.balanceOf(address(interestEarnedAccount)).mul(PERCENT_100).div(interestPt);
        uint allowedByLtd = getMaxLockAmountAllowedByLtd();
        maxLock = allowedByEarning < allowedByLtd ? allowedByEarning : allowedByLtd;
        maxLock = maxLock < minLockAmount ? 0 : maxLock;
    }

    /* Helper function for UI.
        Returns max loan amount based on minLoanAmont using LTD params */
    function getMaxLoanAmount(uint minLoanAmount) external view returns (uint maxLoan) {
        uint allowedByLtd = getMaxLoanAmountAllowedByLtd();
        maxLoan = allowedByLtd < minLoanAmount ? 0 : allowedByLtd;
    }

    /* returns maximum lockable token amount allowed by LTD params. */
    function getMaxLockAmountAllowedByLtd() public view returns(uint maxLockByLtd) {
        uint allowedByLtdDifferencePt = totalLoanAmount.mul(PERCENT_100).div(PERCENT_100
                                            .sub(ltdParams.lockDifferenceLimit));
        allowedByLtdDifferencePt = totalLockedAmount >= allowedByLtdDifferencePt ?
                                        0 : allowedByLtdDifferencePt.sub(totalLockedAmount);

        uint allowedByLtdDifferenceAmount =
            totalLockedAmount >= totalLoanAmount.add(ltdParams.allowedDifferenceAmount) ?
                0 : totalLoanAmount.add(ltdParams.allowedDifferenceAmount).sub(totalLockedAmount);

        maxLockByLtd = allowedByLtdDifferencePt > allowedByLtdDifferenceAmount ?
                                        allowedByLtdDifferencePt : allowedByLtdDifferenceAmount;
    }

    /* returns maximum borrowable token amount allowed by LTD params */
    function getMaxLoanAmountAllowedByLtd() public view returns(uint maxLoanByLtd) {
        uint allowedByLtdDifferencePt = totalLockedAmount.mul(ltdParams.loanDifferenceLimit.add(PERCENT_100))
                                            .div(PERCENT_100);
        allowedByLtdDifferencePt = totalLoanAmount >= allowedByLtdDifferencePt ?
                                        0 : allowedByLtdDifferencePt.sub(totalLoanAmount);

        uint allowedByLtdDifferenceAmount =
            totalLoanAmount >= totalLockedAmount.add(ltdParams.allowedDifferenceAmount) ?
                0 : totalLockedAmount.add(ltdParams.allowedDifferenceAmount).sub(totalLoanAmount);

        maxLoanByLtd = allowedByLtdDifferencePt > allowedByLtdDifferenceAmount ?
                                        allowedByLtdDifferencePt : allowedByLtdDifferenceAmount;
    }

}

// File: contracts/Locker.sol

/* contract for tracking locked funds

 requirements
  -> lock funds
  -> unlock funds
  -> index locks by address

 For flows see: https://github.com/Augmint/augmint-contracts/blob/master/docs/lockFlow.png

 TODO / think about:
  -> self-destruct function?

*/

pragma solidity 0.4.24;







contract Locker is Restricted, TokenReceiver {

    using SafeMath for uint256;

    uint public constant CHUNK_SIZE = 100;

    event NewLockProduct(uint32 indexed lockProductId, uint32 perTermInterest, uint32 durationInSecs,
                            uint32 minimumLockAmount, bool isActive);

    event LockProductActiveChange(uint32 indexed lockProductId, bool newActiveState);

    // NB: amountLocked includes the original amount, plus interest
    event NewLock(address indexed lockOwner, uint lockId, uint amountLocked, uint interestEarned,
                    uint40 lockedUntil, uint32 perTermInterest, uint32 durationInSecs);

    event LockReleased(address indexed lockOwner, uint lockId);

    event MonetarySupervisorChanged(MonetarySupervisor newMonetarySupervisor);

    struct LockProduct {
        // perTermInterest is in millionths (i.e. 1,000,000 = 100%):
        uint32 perTermInterest;
        uint32 durationInSecs;
        uint32 minimumLockAmount;
        bool isActive;
    }

    /* NB: we don&#39;t need to store lock parameters because lockProducts can&#39;t be altered (only disabled/enabled) */
    struct Lock {
        uint amountLocked;
        address owner;
        uint32 productId;
        uint40 lockedUntil;
        bool isActive;
    }

    AugmintTokenInterface public augmintToken;
    MonetarySupervisor public monetarySupervisor;

    LockProduct[] public lockProducts;

    Lock[] public locks;

    // lock ids for an account
    mapping(address => uint[]) public accountLocks;

    constructor(address permissionGranterContract, AugmintTokenInterface _augmintToken,
                    MonetarySupervisor _monetarySupervisor)
    public Restricted(permissionGranterContract) {
        augmintToken = _augmintToken;
        monetarySupervisor = _monetarySupervisor;

    }

    function addLockProduct(uint32 perTermInterest, uint32 durationInSecs, uint32 minimumLockAmount, bool isActive)
    external restrict("StabilityBoard") {

        uint _newLockProductId = lockProducts.push(
                                    LockProduct(perTermInterest, durationInSecs, minimumLockAmount, isActive)) - 1;
        uint32 newLockProductId = uint32(_newLockProductId);
        require(newLockProductId == _newLockProductId, "lockProduct overflow");
        emit NewLockProduct(newLockProductId, perTermInterest, durationInSecs, minimumLockAmount, isActive);

    }

    function setLockProductActiveState(uint32 lockProductId, bool isActive) external restrict("StabilityBoard") {
        // next line would revert but require to emit reason:
        require(lockProductId < lockProducts.length, "invalid lockProductId");

        lockProducts[lockProductId].isActive = isActive;
        emit LockProductActiveChange(lockProductId, isActive);

    }

    /* lock funds, called from AugmintToken&#39;s transferAndNotify
     Flow for locking tokens:
        1) user calls token contract&#39;s transferAndNotify lockProductId passed in data arg
        2) transferAndNotify transfers tokens to the Lock contract
        3) transferAndNotify calls Lock.transferNotification with lockProductId
    */
    function transferNotification(address from, uint256 amountToLock, uint _lockProductId) external {
        require(msg.sender == address(augmintToken), "msg.sender must be augmintToken");
        // next line would revert but require to emit reason:
        require(lockProductId < lockProducts.length, "invalid lockProductId");
        uint32 lockProductId = uint32(_lockProductId);
        require(lockProductId == _lockProductId, "lockProductId overflow");
        /* TODO: make data arg generic bytes
            uint productId;
            assembly { // solhint-disable-line no-inline-assembly
                productId := mload(data)
        } */
        _createLock(lockProductId, from, amountToLock);
    }

    function releaseFunds(uint lockId) external {
        // next line would revert but require to emit reason:
        require(lockId < locks.length, "invalid lockId");
        Lock storage lock = locks[lockId];
        LockProduct storage lockProduct = lockProducts[lock.productId];

        require(lock.isActive, "lock must be in active state");
        require(now >= lock.lockedUntil, "current time must be later than lockedUntil");

        lock.isActive = false;

        uint interestEarned = calculateInterest(lockProduct.perTermInterest, lock.amountLocked);

        monetarySupervisor.releaseFundsNotification(lock.amountLocked); // to maintain totalLockAmount
        augmintToken.transferWithNarrative(lock.owner, lock.amountLocked.add(interestEarned),
                                                                                "Funds released from lock");

        emit LockReleased(lock.owner, lockId);
    }

    function setMonetarySupervisor(MonetarySupervisor newMonetarySupervisor) external restrict("StabilityBoard") {
        monetarySupervisor = newMonetarySupervisor;
        emit MonetarySupervisorChanged(newMonetarySupervisor);
    }

    function getLockProductCount() external view returns (uint) {

        return lockProducts.length;

    }

    // returns 20 lock products starting from some offset
    // lock products are encoded as [ perTermInterest, durationInSecs, minimumLockAmount, maxLockAmount, isActive ]
    function getLockProducts(uint offset) external view returns (uint[5][CHUNK_SIZE] response) {
        for (uint8 i = 0; i < CHUNK_SIZE; i++) {

            if (offset + i >= lockProducts.length) { break; }

            LockProduct storage lockProduct = lockProducts[offset + i];

            response[i] = [ lockProduct.perTermInterest, lockProduct.durationInSecs, lockProduct.minimumLockAmount,
                        monetarySupervisor.getMaxLockAmount(lockProduct.minimumLockAmount, lockProduct.perTermInterest),
                        lockProduct.isActive ? 1 : 0 ];
        }
    }

    function getLockCount() external view returns (uint) {
        return locks.length;
    }

    function getLockCountForAddress(address lockOwner) external view returns (uint) {
        return accountLocks[lockOwner].length;
    }

    // returns CHUNK_SIZE locks starting from some offset
    // lock products are encoded as
    //       [lockId, owner, amountLocked, interestEarned, lockedUntil, perTermInterest, durationInSecs, isActive ]
    // NB: perTermInterest is in millionths (i.e. 1,000,000 = 100%):
    function getLocks(uint offset) external view returns (uint[8][CHUNK_SIZE] response) {

        for (uint16 i = 0; i < CHUNK_SIZE; i++) {

            if (offset + i >= locks.length) { break; }

            Lock storage lock = locks[offset + i];
            LockProduct storage lockProduct = lockProducts[lock.productId];

            uint interestEarned = calculateInterest(lockProduct.perTermInterest, lock.amountLocked);

            response[i] = [uint(offset + i), uint(lock.owner), lock.amountLocked, interestEarned, lock.lockedUntil,
                                lockProduct.perTermInterest, lockProduct.durationInSecs, lock.isActive ? 1 : 0];
        }
    }

    // returns CHUNK_SIZE locks of a given account, starting from some offset
    // lock products are encoded as
    //             [lockId, amountLocked, interestEarned, lockedUntil, perTermInterest, durationInSecs, isActive ]
    function getLocksForAddress(address lockOwner, uint offset) external view returns (uint[7][CHUNK_SIZE] response) {

        uint[] storage locksForAddress = accountLocks[lockOwner];

        for (uint16 i = 0; i < CHUNK_SIZE; i++) {

            if (offset + i >= locksForAddress.length) { break; }

            Lock storage lock = locks[locksForAddress[offset + i]];
            LockProduct storage lockProduct = lockProducts[lock.productId];

            uint interestEarned = calculateInterest(lockProduct.perTermInterest, lock.amountLocked);

            response[i] = [ locksForAddress[offset + i], lock.amountLocked, interestEarned, lock.lockedUntil,
                                lockProduct.perTermInterest, lockProduct.durationInSecs, lock.isActive ? 1 : 0 ];
        }
    }

    function calculateInterest(uint32 perTermInterest, uint amountToLock) public pure returns (uint interestEarned) {
        interestEarned = amountToLock.mul(perTermInterest).ceilDiv(1000000);
    }

    // Internal function. assumes amountToLock is already transferred to this Lock contract
    function _createLock(uint32 lockProductId, address lockOwner, uint amountToLock) internal returns(uint lockId) {
        LockProduct storage lockProduct = lockProducts[lockProductId];
        require(lockProduct.isActive, "lockProduct must be in active state");
        require(amountToLock >= lockProduct.minimumLockAmount, "amountToLock must be >= minimumLockAmount");

        uint interestEarned = calculateInterest(lockProduct.perTermInterest, amountToLock);
        uint expiration = now.add(lockProduct.durationInSecs);
        uint40 lockedUntil = uint40(expiration);
        require(lockedUntil == expiration, "lockedUntil overflow");

        lockId = locks.push(Lock(amountToLock, lockOwner, lockProductId, lockedUntil, true)) - 1;
        accountLocks[lockOwner].push(lockId);

        monetarySupervisor.requestInterest(amountToLock, interestEarned); // update KPIs & transfer interest here

        emit NewLock(lockOwner, lockId, amountToLock, interestEarned, lockedUntil, lockProduct.perTermInterest,
                    lockProduct.durationInSecs);
    }

}

// File: contracts/SB_scripts/mainnet/Main0007_stopOldLocker.sol

/* Disable all products in old locker contract
*/

pragma solidity 0.4.24;


contract Main0007_stopOldLocker {

    Locker constant oldLocker = Locker(0x095c0F071Fd75875a6b5a1dEf3f3a993F591080c);

    function execute(Main0007_stopOldLocker /* self (not used)*/ ) external {
        oldLocker.setLockProductActiveState(3, true);
        oldLocker.setLockProductActiveState(4, true);
        oldLocker.setLockProductActiveState(5, true);
    }

}