pragma solidity ^0.4.24;


interface ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData
    ) public;
}

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


interface ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;

    function send(address to, uint256 amount, bytes data) public;
    function operatorSend(address from, address to, uint256 amount, bytes data, bytes operatorData) public;

    function burn(uint256 amount, bytes data) public;
    function operatorBurn(address from, uint256 amount, bytes data, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

contract ERC820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns(address);
}


 /** 
  * @title ERC820Client - Base Client to contact registry
  * @dev ERC820Client Implementation from https://github.com/jbaylina/ERC820
  */
contract ERC820Client {
    ERC820Registry constant ERC820REGISTRY = ERC820Registry(0x820b586C8C28125366C998641B09DCbE7d4cBF06);

    function setInterfaceImplementation(string _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC820REGISTRY.setInterfaceImplementer(this, interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC820REGISTRY.setManager(this, _newManager);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 /** 
  * @title TxFeeManager
  * @dev Manages transaction fees associated with token transfers
  * Gas costs for transfers are refunded (up to a certain amount), and a 
  * transfer fee is deducted from the token transfer, going to a fee collector.
  * Whitelisted addresses do not receive gas refunds or transfer fee
  */
contract TxFeeManager is Ownable {
    
    using SafeMath for uint256;
    
    /** @dev Allow the public to whitelist address */
    bool public publicCanWhitelist = true;        

    /** @dev Max gas price refund - 10 GWEI */             
    uint256 public maxRefundableGasPrice = 10000000000;

    /** @dev Fee to deduct from token transfers (0.1% increments) */
    uint256 public transferFeePercentTenths = 10;

    /** @dev Flat transfer fee */
    uint256 public transferFeeFlat = 0;
    
    /** @dev Address to receive collected fees */
    address public feeRecipient;

    /** @dev Total transaction fees collected */
    uint256 public totalFees = 0;
    
    /** @dev Total transaction volume */
    uint256 public totalTX = 0; 
    
    /** @dev Total transaction count */
    uint256 public totalTXCount = 0;
    
    /** @dev Addresses who will not recieve refunds or tx fees */
    mapping(address => bool) feeWhitelist_;
    
    /**
     * @dev Constructor
     * @param _feeRecipient Address to receive collected fees
     */
    constructor(address _feeRecipient) public {
        feeRecipient = _feeRecipient;
        feeWhitelist_[address(this)] = true;
    }

    /**
     * @dev Modifier to apply the CanYa Network refund
     * Tracks gas spent, below a max gas price threshold
     * Checks if in the whitelist (does not apply the fee)
     * Adds a base gas amount to account for the processes outside of the tracking
     * Exits gracefully if no ether in this contract
     */
    modifier refundable() {
        uint256 _startGas = gasleft();
        _;
        if(!applyFeeToAddress(msg.sender)) return;
        uint256 gasPrice = tx.gasprice;
        if (gasPrice > maxRefundableGasPrice) gasPrice = maxRefundableGasPrice;
        uint256 _endGas = gasleft();
        uint256 _gasUsed = _startGas.sub(_endGas).add(31000);
        uint256 weiRefund = _gasUsed.mul(gasPrice);
        if (address(this).balance >= weiRefund) msg.sender.transfer(weiRefund);
    }

    /**
     * @dev Bool to determine whether or not an address should have a refund and tx fee applied
     * @param _address Address to check
     */
    function applyFeeToAddress(address _address)
    internal
    view
    returns (bool) {
        return isRegularAddress(_address) && !feeWhitelist_[_address];
    }

    /** 
     *  @notice Check whether an address is a regular address or not.
     *  @param _addr Address of the contract that has to be checked
     *  @return `true` if `_addr` is a regular address (not a contract)
     */
    function isRegularAddress(address _addr) 
    internal 
    view 
    returns(bool) {
        if (_addr == 0) {
            return false; 
        }
        uint size;
        assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
        return size == 0;
    }
    
    /**
     * @dev Set the rate with which to calculate tx fee
     * @param _feePercent Percentage of fee to collect, in 10ths. Where 10 = 1%
     */
    function setFeePercentTenths(uint256 _feePercent) 
    public 
    onlyOwner {
        transferFeePercentTenths = _feePercent;
    }

    /**
     * @dev Set the flat transaction fee rate
     * @param _feeFlat Value of flat fee
     */
    function setFeeFlat(uint256 _feeFlat) 
    public 
    onlyOwner {
        transferFeeFlat = _feeFlat;
    }

    /**
     * @dev Update the recipient of fees
     * @param _feeRecipient Recipient address
     */
    function setFeeRecipient(address _feeRecipient) 
    public 
    onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Change the anti-sybil attack threshold
     * @param _newMax Max gas price in wei
     */
    function setMaxRefundableGasPrice(uint256 _newMax) 
    public 
    onlyOwner {
        maxRefundableGasPrice = _newMax;
    }

    /**
     * @dev Allows owner to add addresses to the fee whitelist
     * @param _exempt Address to whitelist
     */
    function exemptFromFees(address _exempt) 
    public 
    onlyOwner {
        feeWhitelist_[_exempt] = true;
    }

    /**
     * @dev Allows owner to revoke others in case of abuse
     * @param _notExempt Address to remove from the whitelist
     */
    function revokeFeeExemption(address _notExempt) 
    public 
    onlyOwner {
        feeWhitelist_[_notExempt] = false;
    }

    /**
     * @dev Allows owner to disable/enable public whitelisting
     * @param _canWhitelist Bool which sets ability for the public to whitelist
     */
    function setPublicWhitelistAbility(bool _canWhitelist) 
    public 
    onlyOwner {
        publicCanWhitelist = _canWhitelist;
    }

    /**
     * @dev Allows public to opt-out of CanYa Network Fee
     */
    function exemptMeFromFees() 
    public {
        if (publicCanWhitelist) {
            feeWhitelist_[msg.sender] = true;
        }
    }

    /**
     * @dev Calculate transfer fee amount 
     * @param _operator Address that is executing the transfer
     * @param _value Amount of tokens being transferred
     */
    function _getTransferFeeAmount(address _operator, uint256 _value) 
    internal 
    view
    returns (uint256) {
        if (!applyFeeToAddress(_operator)){
            return 0;
        }
        if (transferFeePercentTenths > 0){
            return (_value.mul(transferFeePercentTenths)).div(1000) + transferFeeFlat;
        }
        return transferFeeFlat; 
    }
}

 /** 
  * @title ERC777BaseToken
  * @dev ERC777ERC20BaseToken Implementation from https://github.com/jacquesd/ERC777
  * Additionally implements TxFeeManager and applies a Token tx fee to all transfers
  */
contract ERC777BaseToken is TxFeeManager, ERC777Token, ERC820Client {

    string internal mName;
    string internal mSymbol;
    uint256 internal mGranularity;
    uint256 internal mTotalSupply;

    mapping(address => uint) internal mBalances;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;
    mapping(address => mapping(address => bool)) internal mAuthorizedOperators;

    /** 
     *  @notice Constructor to create a ReferenceToken
     *  @param _name Name of the new token
     *  @param _symbol Symbol of the new token.
     *  @param _granularity Minimum transferable chunk.
     */
    constructor(string _name, string _symbol, uint256 _granularity, address[] _defaultOperators, address _feeRecipient) 
    internal TxFeeManager(_feeRecipient) {
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = 0;
        require(_granularity >= 1, "Granularity must be > 1");
        mGranularity = _granularity;

        mDefaultOperators = _defaultOperators;
        for (uint256 i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

        setInterfaceImplementation("ERC777Token", this);
    }

    /* -- ERC777 Interface Implementation -- */
    //
    /** @return the name of the token */
    function name() public view returns (string) { return mName; }

    /** @return the symbol of the token */
    function symbol() public view returns (string) { return mSymbol; }

    /** @return the granularity of the token */
    function granularity() public view returns (uint256) { return mGranularity; }

    /** @return the total supply of the token */
    function totalSupply() public view returns (uint256) { return mTotalSupply; }

    /** 
     *  @notice Return the account balance of some account
     *  @param _tokenHolder Address for which the balance is returned
     *  @return the balance of `_tokenAddress`.
     */
    function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

    /** 
     *  @notice Return the list of default operators
     *  @return the list of all the default operators
     */
    function defaultOperators() public view returns (address[]) { return mDefaultOperators; }

    /** 
     *  @notice Send `_amount` of tokens to address `_to` passing `_data` to the recipient
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be sent
     *  @param _data Data to attach
     */
    function send(address _to, uint256 _amount, bytes _data) public {
        doSend(msg.sender, msg.sender, _to, _amount, _data, "", true);
    }

    /** 
     *  @notice Send `_amount` of tokens to address `_to` passing `_data` to the recipient
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be sent
     */
    function send(address _to, uint256 _amount) public {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", true);
    }

    /**
     *  @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens.
     *  @param _operator The operator that wants to be Authorized
     */
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender, "Cannot authorize yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = true;
        }
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /**
     *  @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens.
     *  @param _operator The operator that wants to be Revoked
     */
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender, "Cannot revoke yourself as an operator");
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorizedOperators[_operator][msg.sender] = false;
        }
        emit RevokedOperator(_operator, msg.sender);
    }

    /** 
     *  @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
     *  @param _operator address to check if it has the right to manage the tokens
     *  @param _tokenHolder address which holds the tokens to be managed
     *  @return `true` if `_operator` is authorized for `_tokenHolder`
     */
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return (_operator == _tokenHolder // solium-disable-line operator-whitespace
            || mAuthorizedOperators[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

    /**
     *  @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
     *  @param _from The address holding the tokens being sent
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be sent
     *  @param _data Data generated by the user to be sent to the recipient
     *  @param _operatorData Data generated by the operator to be sent to the recipient
     */
    function operatorSend(address _from, address _to, uint256 _amount, bytes _data, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from), "Not an operator");
        doSend(msg.sender, _from, _to, _amount, _data, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _data) public {
        doBurn(msg.sender, msg.sender, _amount, _data, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder), "Not an operator");
        doBurn(msg.sender, _tokenHolder, _amount, _data, _operatorData);
    }

    
    /**
     *  @notice Internal function that ensures `_amount` is multiple of the granularity
     *  @param _amount The quantity that want&#39;s to be checked
     */
    function requireMultiple(uint256 _amount) internal view {
        require(_amount % mGranularity == 0, "Amount is not a multiple of granualrity");
    }

    /**
     *  @notice Helper function actually performing the sending of tokens.
     *  @param _operator The address performing the send
     *  @param _from The address holding the tokens being sent
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be sent
     *  @param _data Data generated by the user to be passed to the recipient
     *  @param _operatorData Data generated by the operator to be passed to the recipient
     *  @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
     *   implementing `ERC777tokensRecipient`.
     *   ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *   functions SHOULD set this parameter to `false`.
     *  @dev Additionally, this function applies some implementation from TxFeeManager. 
     *   A transfer fee is calculated based off the current rates and send to the fee collector.
     *   If a user is eligible for fee collection, they will get the gas cost of the transfer refunded
     */
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
        refundable
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _data, _operatorData);

        require(_to != address(0), "Cannot send to 0x0");
        require(mBalances[_from] >= _amount, "Not enough funds");

        uint256 feeAmount = _getTransferFeeAmount(_operator, _amount);       

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount.sub(feeAmount));
        mBalances[feeRecipient] = mBalances[feeRecipient].add(feeAmount);

        totalTX = totalTX.add(_amount);
        totalTXCount += 1;

        if(feeAmount > 0){
            totalFees = totalFees.add(feeAmount);
            emit Sent(_operator, _from, feeRecipient, feeAmount, "", "");
        }

        callRecipient(_operator, _from, _to, _amount.sub(feeAmount), _data, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount.sub(feeAmount), _data, _operatorData);
    }
    
    /**
     *  @notice Helper function actually performing the burning of tokens.
     *  @param _operator The address performing the burn
     *  @param _tokenHolder The address holding the tokens being burn
     *  @param _amount The number of tokens to be burnt
     *  @param _data Data generated by the token holder
     *  @param _operatorData Data generated by the operator
     */
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
        internal
    {
        callSender(_operator, _tokenHolder, 0x0, _amount, _data, _operatorData);

        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount, "Not enough funds");

        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        emit Burned(_operator, _tokenHolder, _amount, _data, _operatorData);
    }

    /**
     *  @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
     *   May throw according to `_preventLocking`
     *  @param _operator The address performing the send or mint
     *  @param _from The address holding the tokens being sent
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be sent
     *  @param _data Data generated by the user to be passed to the recipient
     *  @param _operatorData Data generated by the operator to be passed to the recipient
     *  @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
     *   implementing `ERC777TokensRecipient`.
     *   ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
     *   functions SHOULD set this parameter to `false`.
     */
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _data, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to), "Cannot send to contract without ERC777TokensRecipient");
        }
    }

    /**
     *  @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
     *  May throw according to `_preventLocking`
     * @param _from The address holding the tokens being sent
     * @param _to The address of the recipient
     * @param _amount The amount of tokens to be sent
     * @param _data Data generated by the user to be passed to the recipient
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
        bytes _data,
        bytes _operatorData
    )
        internal
    {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation == 0) { return; }
        ERC777TokensSender(senderImplementation).tokensToSend(
            _operator, _from, _to, _amount, _data, _operatorData);
    }
}

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

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

 /** 
  * @title ERC777ERC20BaseToken
  * @dev ERC777ERC20BaseToken Implementation from https://github.com/jacquesd/ERC777
  */
contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
    bool internal mErc20compatible;

    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        address[] _defaultOperators,
        address _feeRecipient
    )
        internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators, _feeRecipient)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    /** 
     *  @notice This modifier is applied to erc20 obsolete methods that are
     *  implemented only to maintain backwards compatibility. When the erc20
     *  compatibility is disabled, this methods will fail.
     */
    modifier erc20 () {
        require(mErc20compatible, "ERC20 is disabled");
        _;
    }

    /**
     *  @notice For Backwards compatibility
     *  @return The decimls of the token. Forced to 18 in ERC777.
     */
    function decimals() public erc20 view returns (uint8) { return uint8(18); }

    /** 
     *  @notice ERC20 backwards compatible transfer.
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be transferred
     *  @return `true`, if the transfer can&#39;t be done, it should fail.
     */
    function transfer(address _to, uint256 _amount) 
    public 
    erc20 
    returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /**
     *  @notice ERC20 backwards compatible transferFrom.
     *  @param _from The address holding the tokens being transferred
     *  @param _to The address of the recipient
     *  @param _amount The number of tokens to be transferred
     *  @return `true`, if the transfer can&#39;t be done, it should fail.
     */
    function transferFrom(address _from, address _to, uint256 _amount) 
    public 
    erc20 
    returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender], "Not enough funds allowed");

        // Cannot be after doSend because of tokensReceived re-entry
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    /**
     *  @notice ERC20 backwards compatible approve.
     *   `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
     *  @param _spender The address of the account able to transfer the tokens
     *  @param _amount The number of tokens to be approved for transfer
     *  @return `true`, if the approve can&#39;t be done, it should fail.
     */
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     *  @notice ERC20 backwards compatible allowance.
     *   This function makes it easy to read the `allowed[]` map
     *  @param _owner The address of the account that owns the token
     *  @param _spender The address of the account able to transfer the tokens
     *  @return Amount of remaining tokens of _owner that _spender is allowed
     *   to spend
     */
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }
    
    /**
     *  @notice Execution of token transfer by calling parent implementation
     */
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _data,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        super.doSend(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    /** @dev Executes a token burn, calling the implementation from parent contract */
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _data, bytes _operatorData)
        internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _data, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
    }
}
 /** 
  * @title CanYaCoin
  * @dev ERC777 Implementation including ERC20 compatibility
  * Base implementation: https://github.com/jacquesd/ERC777
  * Custom functionality include 
  */
contract CAN777 is ERC777ERC20BaseToken {

    string internal mURI;

    event ERC20Enabled();
    event ERC20Disabled();

    /**
     * @dev Constructor
     * @param _name Name of the token
     * @param _symbol Symbol of the token
     * @param _uri URI of the token
     * @param _granularity Minimum token multiple used in calculations
     * @param _defaultOperators Array of default global operators
     * @param _feeRecipient Address to receive token fees collected during transaction
     * @param _initialSupply Amount of tokens to mint
     */
    constructor(
        string _name,
        string _symbol,
        string _uri,
        uint256 _granularity,
        address[] _defaultOperators,
        address _feeRecipient,
        uint256 _initialSupply
    )
        public ERC777ERC20BaseToken(_name, _symbol, _granularity, _defaultOperators, _feeRecipient)
    {
        mURI = _uri;
        doMint(msg.sender, _initialSupply, "");
    }


    /**
     * @dev Accepts Ether from anyone since this contract refunds gas
     */
    function() public payable { } 

    /**
     * @dev Updates the basic token details if required
     * @param _updatedName New token name
     * @param _updatedSymbol New token symbol
     * @param _updatedURI New token URI
     */
    function updateDetails(string _updatedName, string _updatedSymbol, string _updatedURI) 
    public 
    onlyOwner {
        mName = _updatedName;
        mSymbol = _updatedSymbol;
        mURI = _updatedURI;
    }

    /** @dev Getter for token URI */
    function URI() 
    public 
    view 
    returns (string) { 
        return mURI; 
    }

    /** @dev Disables the ERC20 interface */
    function disableERC20() 
    public 
    onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
        emit ERC20Disabled();
    }

    /** @dev Re enables the ERC20 interface. */
    function enableERC20() 
    public 
    onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
        emit ERC20Enabled();
    }

    /**
     * @dev Mints token to a particular token holder
     * @param _tokenHolder Address of minting recipient
     * @param _amount Amount of tokens to mint
     * @param _operatorData Bytecode to send alongside minting 
     */
    function doMint(address _tokenHolder, uint256 _amount, bytes _operatorData) 
    private {
        requireMultiple(_amount);
        mTotalSupply = mTotalSupply.add(_amount);
        mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

        emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
        if (mErc20compatible) { 
            emit Transfer(0x0, _tokenHolder, _amount); 
        }
    }
}