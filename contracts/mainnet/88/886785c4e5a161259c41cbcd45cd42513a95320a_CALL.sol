pragma solidity 0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Owned
 * @author Adria Massanet <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="caabaeb8a3ab8aa9a5aeafa9a5a4beafb2bee4a3a5">[email&#160;protected]</a>>
 * @notice The Owned contract has an owner address, and provides basic
 *  authorization control functions, this simplifies & the implementation of
 *  user permissions; this contract has three work flows for a change in
 *  ownership, the first requires the new owner to validate that they have the
 *  ability to accept ownership, the second allows the ownership to be
 *  directly transferred without requiring acceptance, and the third allows for
 *  the ownership to be removed to allow for decentralization
 */
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /**
     * @dev The constructor sets the `msg.sender` as the`owner` of the contract
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev `owner` is the only address that can call a function with this
     * modifier
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev In this 1st option for ownership transfer `proposeOwnership()` must
     *  be called first by the current `owner` then `acceptOwnership()` must be
     *  called by the `newOwnerCandidate`
     * @notice `onlyOwner` Proposes to transfer control of the contract to a
     *  new owner
     * @param _newOwnerCandidate The address being proposed as the new owner
     */
    function proposeOwnership(address _newOwnerCandidate) external onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /**
     * @notice Can only be called by the `newOwnerCandidate`, accepts the
     *  transfer of ownership
     */
    function acceptOwnership() external {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * @dev In this 2nd option for ownership transfer `changeOwnership()` can
     *  be called and it will immediately assign ownership to the `newOwner`
     * @notice `owner` can step down and assign some other address to this role
     * @param _newOwner The address of the new owner
     */
    function changeOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * @dev In this 3rd option for ownership transfer `removeOwnership()` can
     *  be called and it will immediately assign ownership to the 0x0 address;
     *  it requires a 0xdece be input as a parameter to prevent accidental use
     * @notice Decentralizes the contract, this operation cannot be undone
     * @param _dac `0xdac` has to be entered for this function to work
     */
    function removeOwnership(address _dac) external onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        emit OwnershipRemoved();
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

interface ERC777TokensSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

interface ERC777Token {
    function name() public view returns (string);

    function symbol() public view returns (string);

    function totalSupply() public view returns (uint256);

    function granularity() public view returns (uint256);

    function balanceOf(address owner) public view returns (uint256);

    function send(address to, uint256 amount) public;

    function send(address to, uint256 amount, bytes userData) public;

    function authorizeOperator(address operator) public;

    function revokeOperator(address operator) public;

    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);

    function operatorSend(address from, address to, uint256 amount, bytes userData, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

interface ERC20Token {
    function name() public view returns (string);

    function symbol() public view returns (string);

    function decimals() public view returns (uint8);

    function totalSupply() public view returns (uint256);

    function balanceOf(address owner) public view returns (uint256);

    function transfer(address to, uint256 amount) public returns (bool);

    function transferFrom(address from, address to, uint256 amount) public returns (bool);

    function approve(address spender, uint256 amount) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry public erc820Registry;

    constructor(address _registry) public {
        erc820Registry = ERC820Registry(_registry);
    }

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(ifaceLabel);
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

/**
 * @title ERC777 Helper Contract
 * @author Panos
 */
contract ERC777Helper is ERC777Token, ERC20Token, ERC820Implementer {
    using SafeMath for uint256;

    bool internal mErc20compatible;
    uint256 internal mGranularity;
    mapping(address => uint) internal mBalances;

    /**
     * @notice Internal function that ensures `_amount` is multiple of the granularity
     * @param _amount The quantity that want&#39;s to be checked
     */
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

    /**
     * @notice Check whether an address is a regular address or not.
     * @param _addr Address of the contract that has to be checked
     * @return `true` if `_addr` is a regular address (not a contract)
     */
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line no-inline-assembly
        return size == 0;
    }

    /**
     * @notice Helper function actually performing the sending of tokens.
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     * @param _userData Data generated by the user to be passed to the recipient
     * @param _operatorData Data generated by the operator to be passed to the recipient
     * @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
     *  implementing `erc777_tokenHolder`.
     *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *  functions SHOULD set this parameter to `false`.
     */
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
    internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));          // forbid sending to 0x0 (=burning)
        require(mBalances[_from] >= _amount); // ensure enough funds

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    /**
     * @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
     *  May throw according to `_preventLocking`
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     * @param _userData Data generated by the user to be passed to the recipient
     * @param _operatorData Data generated by the operator to be passed to the recipient
     * @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
     *  implementing `ERC777TokensRecipient`.
     *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *  functions SHOULD set this parameter to `false`.
     */
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) internal {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

    /**
     * @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
     *  May throw according to `_preventLocking`
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be sent
     * @param _userData Data generated by the user to be passed to the recipient
     * @param _operatorData Data generated by the operator to be passed to the recipient
     *  implementing `ERC777TokensSender`.
     *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *  functions SHOULD set this parameter to `false`.
     */
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    ) internal {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation != 0) {
            ERC777TokensSender(senderImplementation).tokensToSend(
                _operator, _from, _to, _amount, _userData, _operatorData);
        }
    }
}

/**
 * @title ERC20 Compatibility Contract
 * @author Panos
 */
contract ERC20TokenCompat is ERC777Helper, Owned {

    mapping(address => mapping(address => uint256)) private mAllowed;

    /**
     * @notice Contract construction
     */
    constructor() public {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /**
     * @notice This modifier is applied to erc20 obsolete methods that are
     * implemented only to maintain backwards compatibility. When the erc20
     * compatibility is disabled, this methods will fail.
     */
    modifier erc20 () {
        require(mErc20compatible);
        _;
    }

    /**
     * @notice Disables the ERC20 interface. This function can only be called
     * by the owner.
     */
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
    }

    /**
     * @notice Re enables the ERC20 interface. This function can only be called
     *  by the owner.
     */
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /*
     * @notice For Backwards compatibility
     * @return The decimals of the token. Forced to 18 in ERC777.
     */
    function decimals() public erc20 view returns (uint8) {return uint8(18);}

    /**
     * @notice ERC20 backwards compatible transfer.
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be transferred
     * @return `true`, if the transfer can&#39;t be done, it should fail.
     */
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", false);
        return true;
    }

    /**
     * @notice ERC20 backwards compatible transferFrom.
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be transferred
     * @return `true`, if the transfer can&#39;t be done, it should fail.
     */
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

        // Cannot be after doSend because of tokensReceived re-entry
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(_from, _to, _amount, "", msg.sender, "", false);
        return true;
    }

    /**
     * @notice ERC20 backwards compatible approve.
     *  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
     * @param _spender The address of the account able to transfer the tokens
     * @param _amount The number of tokens to be approved for transfer
     * @return `true`, if the approve can&#39;t be done, it should fail.
     */
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @notice ERC20 backwards compatible allowance.
     *  This function makes it easy to read the `allowed[]` map
     * @param _owner The address of the account that owns the token
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens of _owner that _spender is allowed
     *  to spend
     */
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }
}

/**
 * @title ERC777 Standard Contract
 * @author Panos
 */
contract ERC777StandardToken is ERC777Helper, Owned {
    string private mName;
    string private mSymbol;
    uint256 private mTotalSupply;

    mapping(address => mapping(address => bool)) private mAuthorized;

    /**
     * @notice Constructor to create a ERC777StandardToken
     * @param _name Name of the new token
     * @param _symbol Symbol of the new token.
     * @param _totalSupply Total tokens issued
     * @param _granularity Minimum transferable chunk.
     */
    constructor(
        string _name,
        string _symbol,
        uint256 _totalSupply,
        uint256 _granularity
    )
    public {
        require(_granularity >= 1);
        require(_totalSupply > 0);

        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = _totalSupply;
        mGranularity = _granularity;
        mBalances[msg.sender] = mTotalSupply;

        setInterfaceImplementation("ERC777Token", this);
    }

    /**
     * @return the name of the token
     */
    function name() public view returns (string) {return mName;}

    /**
     * @return the symbol of the token
     */
    function symbol() public view returns (string) {return mSymbol;}

    /**
     * @return the granularity of the token
     */
    function granularity() public view returns (uint256) {return mGranularity;}

    /**
     * @return the total supply of the token
     */
    function totalSupply() public view returns (uint256) {return mTotalSupply;}

    /**
     * @notice Return the account balance of some account
     * @param _tokenHolder Address for which the balance is returned
     * @return the balance of `_tokenAddress`.
     */
    function balanceOf(address _tokenHolder) public view returns (uint256) {return mBalances[_tokenHolder];}

    /**
     * @notice Send `_amount` of tokens to address `_to`
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     */
    function send(address _to, uint256 _amount) public {
        doSend(msg.sender, _to, _amount, "", msg.sender, "", true);
    }

    /**
     * @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     * @param _userData The user supplied data
     */
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, _to, _amount, _userData, msg.sender, "", true);
    }

    /**
     * @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens.
     * @param _operator The operator that wants to be Authorized
     */
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /**
     * @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens.
     * @param _operator The operator that wants to be Revoked
     */
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        mAuthorized[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    /**
     * @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
     * @param _operator address to check if it has the right to manage the tokens
     * @param _tokenHolder address which holds the tokens to be managed
     * @return `true` if `_operator` is authorized for `_tokenHolder`
     */
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
    }

    /**
     * @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     * @param _userData Data generated by the user to be sent to the recipient
     * @param _operatorData Data generated by the operator to be sent to the recipient
     */
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(_from, _to, _amount, _userData, msg.sender, _operatorData, true);
    }
}

/**
 * @title ERC20 Multi Transfer Contract
 * @author Panos
 */
contract ERC20Multi is ERC20TokenCompat {

    /**
     * @dev Transfer the specified amounts of tokens to the specified addresses.
     * @dev Be aware that there is no check for duplicate recipients.
     * @param _toAddresses Receiver addresses.
     * @param _amounts Amounts of tokens that will be transferred.
     */
    function multiPartyTransfer(address[] _toAddresses, uint256[] _amounts) external erc20 {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

    /**
    * @dev Transfer the specified amounts of tokens to the specified addresses from authorized balance of sender.
    * @dev Be aware that there is no check for duplicate recipients.
    * @param _from The address of the sender
    * @param _toAddresses The addresses of the recipients (MAX 255)
    * @param _amounts The amounts of tokens to be transferred
    */
    function multiPartyTransferFrom(address _from, address[] _toAddresses, uint256[] _amounts) external erc20 {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }
}

/**
 * @title ERC777 Multi Transfer Contract
 * @author Panos
 */
contract ERC777Multi is ERC777Helper {

    /**
     * @dev Transfer the specified amounts of tokens to the specified addresses as `_from`.
     * @dev Be aware that there is no check for duplicate recipients.
     * @param _from Address to use as sender
     * @param _to Receiver addresses.
     * @param _amounts Amounts of tokens that will be transferred.
     * @param _userData User supplied data
     * @param _operatorData Operator supplied data
     */
    function multiOperatorSend(address _from, address[] _to, uint256[] _amounts, bytes _userData, bytes _operatorData)
    external {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_to.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_to.length == _amounts.length);

        for (uint8 i = 0; i < _to.length; i++) {
            operatorSend(_from, _to[i], _amounts[i], _userData, _operatorData);
        }
    }

    /**
     * @dev Transfer the specified amounts of tokens to the specified addresses.
     * @dev Be aware that there is no check for duplicate recipients.
     * @param _toAddresses Receiver addresses.
     * @param _amounts Amounts of tokens that will be transferred.
     * @param _userData User supplied data
     */
    function multiPartySend(address[] _toAddresses, uint256[] _amounts, bytes _userData) public {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            doSend(msg.sender, _toAddresses[i], _amounts[i], _userData, msg.sender, "", true);
        }
    }

    /**
     * @dev Transfer the specified amounts of tokens to the specified addresses.
     * @dev Be aware that there is no check for duplicate recipients.
     * @param _toAddresses Receiver addresses.
     * @param _amounts Amounts of tokens that will be transferred.
     */
    function multiPartySend(address[] _toAddresses, uint256[] _amounts) public {
        /* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            doSend(msg.sender, _toAddresses[i], _amounts[i], "", msg.sender, "", true);
        }
    }
}

/**
 * @title Safe Guard Contract
 * @author Panos
 */
contract SafeGuard is Owned {

    event Transaction(address indexed destination, uint value, bytes data);

    /**
     * @dev Allows owner to execute a transaction.
     */
    function executeTransaction(address destination, uint value, bytes data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

    /**
     * @dev call has been separated into its own function in order to take advantage
     *  of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
     */
    function externalCall(address destination, uint value, uint dataLength, bytes data)
    private
    returns (bool) {
        bool result;
        assembly { // solhint-disable-line no-inline-assembly
        let x := mload(0x40)   // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 34710), // 34710 is the value that solidity is currently emitting
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}

/**
 * @title ERC664 Standard Balances Contract
 * @author chrisfranko
 */
contract ERC664Balances is SafeGuard {
    using SafeMath for uint256;

    uint256 public totalSupply;

    event BalanceAdj(address indexed module, address indexed account, uint amount, string polarity);
    event ModuleSet(address indexed module, bool indexed set);

    mapping(address => bool) public modules;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyModule() {
        require(modules[msg.sender]);
        _;
    }

    /**
     * @notice Constructor to create ERC664Balances
     * @param _initialAmount Database initial amount
     */
    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
    }

    /**
     * @notice Set allowance of `_spender` in behalf of `_sender` at `_value`
     * @param _sender Owner account
     * @param _spender Spender account
     * @param _value Value to approve
     * @return Operation status
     */
    function setApprove(address _sender, address _spender, uint256 _value) external onlyModule returns (bool) {
        allowed[_sender][_spender] = _value;
        return true;
    }

    /**
     * @notice Decrease allowance of `_spender` in behalf of `_from` at `_value`
     * @param _from Owner account
     * @param _spender Spender account
     * @param _value Value to decrease
     * @return Operation status
     */
    function decApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        return true;
    }

    /**
    * @notice Increase total supply by `_val`
    * @param _val Value to increase
    * @return Operation status
    */
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.add(_val);
        return true;
    }

    /**
     * @notice Decrease total supply by `_val`
     * @param _val Value to decrease
     * @return Operation status
     */
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        totalSupply = totalSupply.sub(_val);
        return true;
    }

    /**
     * @notice Set/Unset `_acct` as an authorized module
     * @param _acct Module address
     * @param _set Module set status
     * @return Operation status
     */
    function setModule(address _acct, bool _set) external onlyOwner returns (bool) {
        modules[_acct] = _set;
        emit ModuleSet(_acct, _set);
        return true;
    }

    /**
     * @notice Get `_acct` balance
     * @param _acct Target account to get balance.
     * @return The account balance
     */
    function getBalance(address _acct) external view returns (uint256) {
        return balances[_acct];
    }

    /**
     * @notice Get allowance of `_spender` in behalf of `_owner`
     * @param _owner Owner account
     * @param _spender Spender account
     * @return Allowance
     */
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Get if `_acct` is an authorized module
     * @param _acct Module address
     * @return Operation status
     */
    function getModule(address _acct) external view returns (bool) {
        return modules[_acct];
    }

    /**
     * @notice Get total supply
     * @return Total supply
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice Increment `_acct` balance by `_val`
     * @param _acct Target account to increment balance.
     * @param _val Value to increment
     * @return Operation status
     */
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].add(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "+");
        return true;
    }

    /**
     * @notice Decrement `_acct` balance by `_val`
     * @param _acct Target account to decrement balance.
     * @param _val Value to decrement
     * @return Operation status
     */
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].sub(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "-");
        return true;
    }
}

/**
 * @title ERC664 Database Contract
 * @author Panos
 */
contract CStore is ERC664Balances, ERC820Implementer {

    mapping(address => mapping(address => bool)) private mAuthorized;

    /**
     * @notice Database construction
     * @param _totalSupply The total supply of the token
     * @param _registry The ERC820 Registry Address
     */
    constructor(uint256 _totalSupply, address _registry) public
    ERC664Balances(_totalSupply)
    ERC820Implementer(_registry) {
        setInterfaceImplementation("ERC664Balances", this);
    }

    /**
     * @notice Increase total supply by `_val`
     * @param _val Value to increase
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function incTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

    /**
     * @notice Decrease total supply by `_val`
     * @param _val Value to decrease
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function decTotalSupply(uint _val) external onlyOwner returns (bool) {
        return false;
    }

    /**
     * @notice moving `_amount` from `_from` to `_to`
     * @param _from The sender address
     * @param _to The receiving address
     * @param _amount The moving amount
     * @return bool The move result
     */
    function move(address _from, address _to, uint256 _amount) external
    onlyModule
    returns (bool) {
        balances[_from] = balances[_from].sub(_amount);
        emit BalanceAdj(msg.sender, _from, _amount, "-");
        balances[_to] = balances[_to].add(_amount);
        emit BalanceAdj(msg.sender, _to, _amount, "+");
        return true;
    }

    /**
     * @notice Setting operator `_operator` for `_tokenHolder`
     * @param _operator The operator to set status
     * @param _tokenHolder The token holder to set operator
     * @param _status The operator status
     * @return bool Status of operation
     */
    function setOperator(address _operator, address _tokenHolder, bool _status) external
    onlyModule
    returns (bool) {
        mAuthorized[_operator][_tokenHolder] = _status;
        return true;
    }

    /**
     * @notice Getting operator `_operator` for `_tokenHolder`
     * @param _operator The operator address to get status
     * @param _tokenHolder The token holder address
     * @return bool Operator status
     */
    function getOperator(address _operator, address _tokenHolder) external
    view
    returns (bool) {
        return mAuthorized[_operator][_tokenHolder];
    }

    /**
     * @notice Increment `_acct` balance by `_val`
     * @param _acct Target account to increment balance.
     * @param _val Value to increment
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }

    /**
     * @notice Decrement `_acct` balance by `_val`
     * @param _acct Target account to decrement balance.
     * @param _val Value to decrement
     * @return Operation status
     */
    // solhint-disable-next-line no-unused-vars
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        return false;
    }
}

/**
 * @title ERC777 CALL Contract
 * @author Panos
 */
contract CALL is ERC820Implementer, ERC777StandardToken, ERC20TokenCompat, ERC20Multi, ERC777Multi, SafeGuard {
    using SafeMath for uint256;

    CStore public balancesDB;

    /**
     * @notice Token construction
     * @param _intRegistry The ERC820 Registry Address
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _totalSupply The total supply of the token
     * @param _granularity The granularity of the token
     * @param _balancesDB The address of balances database
     */
    constructor(address _intRegistry, string _name, string _symbol, uint256 _totalSupply,
        uint256 _granularity, address _balancesDB) public
    ERC820Implementer(_intRegistry)
    ERC777StandardToken(_name, _symbol, _totalSupply, _granularity) {
        balancesDB = CStore(_balancesDB);
        setInterfaceImplementation("ERC777CALLToken", this);
    }

    /**
     * @notice change the balances database to `_newDB`
     * @param _newDB The new balances database address
     */
    function changeBalancesDB(address _newDB) public onlyOwner {
        balancesDB = CStore(_newDB);
    }

    /**
     * @notice ERC20 backwards compatible transferFrom using backendDB.
     * @param _from The address holding the tokens being transferred
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be transferred
     * @return `true`, if the transfer can&#39;t be done, it should fail.
     */
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        uint256 allowance = balancesDB.getAllowance(_from, msg.sender);
        require(_amount <= allowance);

        // Cannot be after doSend because of tokensReceived re-entry
        require(balancesDB.decApprove(_from, msg.sender, _amount));
        doSend(_from, _to, _amount, "", msg.sender, "", false);
        return true;
    }

    /**
     * @notice ERC20 backwards compatible approve.
     *  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
     * @param _spender The address of the account able to transfer the tokens
     * @param _amount The number of tokens to be approved for transfer
     * @return `true`, if the approve can&#39;t be done, it should fail.
     */
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        require(balancesDB.setApprove(msg.sender, _spender, _amount));
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @notice ERC20 backwards compatible allowance.
     *  This function makes it easy to read the `allowed[]` map
     * @param _owner The address of the account that owns the token
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens of _owner that _spender is allowed
     *  to spend
     */
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return balancesDB.getAllowance(_owner, _spender);
    }

    /**
     * @return the total supply of the token
     */
    function totalSupply() public view returns (uint256) {
        return balancesDB.getTotalSupply();
    }

    /**
     * @notice Return the account balance of some account
     * @param _tokenHolder Address for which the balance is returned
     * @return the balance of `_tokenAddress`.
     */
    function balanceOf(address _tokenHolder) public view returns (uint256) {
        return balancesDB.getBalance(_tokenHolder);
    }

    /**
         * @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens at remote database.
         * @param _operator The operator that wants to be Authorized
         */
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        require(balancesDB.setOperator(_operator, msg.sender, true));
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /**
     * @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens at remote database.
     * @param _operator The operator that wants to be Revoked
     */
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        require(balancesDB.setOperator(_operator, msg.sender, false));
        emit RevokedOperator(_operator, msg.sender);
    }

    /**
     * @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder`
     *  address at remote database.
     * @param _operator address to check if it has the right to manage the tokens
     * @param _tokenHolder address which holds the tokens to be managed
     * @return `true` if `_operator` is authorized for `_tokenHolder`
     */
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return _operator == _tokenHolder || balancesDB.getOperator(_operator, _tokenHolder);
    }

    /**
     * @notice Helper function actually performing the sending of tokens using a backend database.
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The number of tokens to be sent
     * @param _userData Data generated by the user to be passed to the recipient
     * @param _operatorData Data generated by the operator to be passed to the recipient
     * @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
     *  implementing `erc777_tokenHolder`.
     *  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *  functions SHOULD set this parameter to `false`.
     */
    function doSend(
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        address _operator,
        bytes _operatorData,
        bool _preventLocking
    )
    internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));          // forbid sending to 0x0 (=burning)
        // require(mBalances[_from] >= _amount); // ensure enough funds
        // (Not Required due to SafeMath throw if underflow in database and false check)

        require(balancesDB.move(_from, _to, _amount));

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }
}