// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

interface IPermissionService {
    function isAdmin(address _address) external view returns(bool);
    function isNotary(address _address) external view returns(bool);
    function isAuditor(address _address) external view returns(bool);
    function isTokenManagerAdmin(address _address) external view returns(bool);
    function isTokenManager(address _address) external view returns(bool);
    function isTokenManagerExecutive(address _address) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

interface ITransparentUpgradeableProxyOwner {
    function owner() external view returns (address);
    function isTokenRegistered(address token) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

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
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity 0.5.8;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

import "./Context.sol";
import "../interfaces/ITransparentUpgradeableProxyOwner.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address internal _owner;

    mapping (address => bool) _registeredTokens;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function isOwner() public view returns(bool) {
        return _owner == _msgSender();
    }
}

pragma solidity 0.5.8;

import "./vendor/ERC20Standard.sol";
import "../proxy/Initializable.sol";

contract AGLDTToken is ERC20Standard, Initializable {
    string public name;
    string public symbol;
    uint8 public decimals;

    function initialize(address _vaultWallet, address _feeProxy, address _whitelist, address _freeze, address _pausable, address _permissionService, uint256 chainId_) public payable initializer {
        vaultWallet = _vaultWallet;
        feeProxy = IFeeProxy(_feeProxy);
        permissionService = IPermissionService(_permissionService);
        whitelist = IWhitelist(_whitelist);
        freeze = IFreeze(_freeze);
        pausable = IPausable(_pausable);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));

        name = "AgAu gold backed token - test";
        symbol = "AGLDT";
        decimals = 18;

        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
}

pragma solidity 0.5.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "../../proxy/Ownable.sol";
import "./../../interfaces/IPermissionService.sol";
import "./IPausable.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    mapping (address => uint256) public time_of_last_transaction;

    mapping (address => bool) private _isHolder;

    IPausable public pausable;
    IPermissionService public permissionService;

    address[] internal _holders;

    uint256 internal _totalSupply;

    modifier whenNotPaused() {
        require(!pausable.paused());
        _;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value, address vaultWallet, uint256 receipentFee, uint256 senderFee) public returns (bool) {
        _transfer(from, to, value, vaultWallet, receipentFee, senderFee);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @param vaultWallet The wallet which receives fee.
     * @param receipentFee The amount of receipent fee be transferred.
     * @param senderFee The amount of sender fee be transferred.
     */
    function _transfer(address from, address to, uint256 value, address vaultWallet, uint256 receipentFee, uint256 senderFee) internal whenNotPaused {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value).sub(senderFee);
        _balances[to] = _balances[to].add(value).sub(receipentFee);
        _balances[vaultWallet] = _balances[vaultWallet].add(receipentFee.add(senderFee));

        if(!_isHolder[to]) {
            _isHolder[to] = true;
           _holders.push(to);
        }
        
        emit Transfer(from, vaultWallet, senderFee);
        emit Transfer(to, vaultWallet, receipentFee);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal whenNotPaused {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        if(!_isHolder[to]) {
            _isHolder[to] = true;
           _holders.push(to);
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal whenNotPaused {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);

        if(!_isHolder[account]) {
            _isHolder[account] = true;
           _holders.push(account);
        }

        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

pragma solidity 0.5.8;

import "./MetaERC20.sol";
import "./IFeeProxy.sol";
import "./IWhitelist.sol";
import "./IFreeze.sol";

contract ERC20Standard is MetaERC20 {
    address public vaultWallet;
    uint256 public MINIMUM_ACCOUNT_BALANCE = 1000000000000000;
    bool public defaultTxFeePayer;

    mapping (address => bool) public receivingPartyDefaultTxFeeSetting;
    mapping (address => bool) public reverse_charge_force;

    IFeeProxy public feeProxy;
    IWhitelist public whitelist;
    IFreeze public freeze;

    struct FeeDetails {
        uint256 storageFeeAmountFrom;
        uint256 storageFeeAmountTo;
        uint256 transferFeeAmount;
        uint256 receipentFeeAmount;
        uint256 senderFeeAmount;
    }

    event TransferDetails(uint256 txAmount, uint256 senderPays, uint256 receiverPays, uint256 senderStorageFee, uint256 receiverStorageFee, uint256 totalAmountPaid, uint256 totalAmountReceived);

    function setForceFeePayer(address _for, bool _reverse_charge) public onlyOwner {
        receivingPartyDefaultTxFeeSetting[_for] = true;
        reverse_charge_force[_for] = _reverse_charge;
    }

    function setDefaultTxFeePayer(bool _defaultTxFeePayer) public onlyOwner {
        defaultTxFeePayer = _defaultTxFeePayer;
    }

    function balanceOf(address owner) public view returns (uint256) {
        uint result = super.balanceOf(owner);

        if(owner == vaultWallet && _holders.length > 0) {
            for(uint i = 0; i < _holders.length; i++) {
                result = result.add(_calculateStorageFee(_holders[i], block.timestamp));
            }

            return result;
        }

        if(_calculateStorageFee(owner, block.timestamp) > 0) {
            return super.balanceOf(owner).sub(_calculateStorageFee(owner, block.timestamp));
        }

        return super.balanceOf(owner);
    }

    function balanceOfGross(address owner) public view returns(uint256) {
        return super.balanceOf(owner);
    }

    function metaTransfer(address to, uint256 amount, address signer, uint256 nonce, uint8 v, bytes32 r, bytes32 s, bool simpleTransfer) public {
        uint256 startGas = gasleft();

        require(checkSignature(to, signer, amount, TRANSFER_TYPEHASH, nonce, v, r, s));
        transferInternal(signer, to, amount, defaultTxFeePayer, simpleTransfer);

        uint256 gasUsed = startGas.sub(gasleft());
        uint256 amountSpentInEth = gasUsed.mul(tx.gasprice);
        uint256 amountToPayInAgAuTokens = amountSpentInEth.mul(100); //agau rate

        _transfer(signer, vaultWallet, amountToPayInAgAuTokens);
    }

    function transfer(address to, uint256 value, bool _reverse_charge) public returns (bool) {
        transferInternal(msg.sender, to, value, _reverse_charge, true);
    }

     function transfer(address to, uint256 value) public returns (bool) {
        transferInternal(msg.sender, to, value, defaultTxFeePayer, true);
    }

    function transferFrom(address from, address to, uint256 value, bool _reverse_charge) public returns (bool) {
        transferInternal(from, to, value, _reverse_charge, false);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        transferInternal(from, to, value, defaultTxFeePayer, false);
    }

    function transferInternal(address from, address to, uint256 value, bool _reverse_charge, bool simpleTransfer) internal returns (bool) {
        require(!freeze.isFreezed(from), "Account frozen");
        FeeDetails memory feeDetails;
        feeDetails.storageFeeAmountFrom = _calculateStorageFee(from, block.timestamp);
        feeDetails.storageFeeAmountTo = _calculateStorageFee(to, block.timestamp);
        feeDetails.transferFeeAmount = _calculateTransferFee(from, to, value, _reverse_charge);

        bool isSenderPays;

        if(feeDetails.storageFeeAmountFrom > 0 || feeDetails.storageFeeAmountTo > 0) {
            time_of_last_transaction[from] = block.timestamp;
            time_of_last_transaction[to] = block.timestamp;
        }

        if(feeDetails.transferFeeAmount > 0) {
            if(receivingPartyDefaultTxFeeSetting[to]) {
                if(!reverse_charge_force[to]) {
                    // sender pays fee
                    feeDetails.receipentFeeAmount = feeDetails.storageFeeAmountTo;
                    feeDetails.senderFeeAmount = feeDetails.storageFeeAmountFrom.add(feeDetails.transferFeeAmount);
                    isSenderPays = true;
                } else {
                    // receipent pays fee
                    feeDetails.receipentFeeAmount = feeDetails.storageFeeAmountTo.add(feeDetails.transferFeeAmount);
                    feeDetails.senderFeeAmount = feeDetails.storageFeeAmountFrom;
                    isSenderPays = false;
                }
            } else {
                if(!_reverse_charge) {
                    // sender pays fee
                    feeDetails.receipentFeeAmount = feeDetails.storageFeeAmountTo;
                    feeDetails.senderFeeAmount = feeDetails.storageFeeAmountFrom.add(feeDetails.transferFeeAmount);
                    isSenderPays = true;
                } else {
                    // receipent pays fee
                    feeDetails.receipentFeeAmount = feeDetails.storageFeeAmountTo.add(feeDetails.transferFeeAmount);
                    feeDetails.senderFeeAmount = feeDetails.storageFeeAmountFrom;
                    isSenderPays = false;
                }
            }

            uint256 senderBalance = _balances[from];

            // If user balance after transfer < then Minimum account balance, send all user balance to vault wallet
            if(senderBalance.sub(feeDetails.senderFeeAmount.add(value)) < MINIMUM_ACCOUNT_BALANCE) {
                if(simpleTransfer) {
                    _transfer(from, to, value, vaultWallet, feeDetails.receipentFeeAmount, senderBalance.sub(value));
                } else {
                    super.transferFrom(from, to, value, vaultWallet, feeDetails.receipentFeeAmount, senderBalance.sub(value));
                }
            } else {
                if(simpleTransfer) {
                    _transfer(from, to, value, vaultWallet, feeDetails.receipentFeeAmount, feeDetails.senderFeeAmount);
                } else {
                    super.transferFrom(from, to, value, vaultWallet, feeDetails.receipentFeeAmount, feeDetails.senderFeeAmount);
                }
            }

            emit TransferDetails(value, isSenderPays ? feeDetails.transferFeeAmount : 0, isSenderPays ? 0 : feeDetails.transferFeeAmount, feeDetails.storageFeeAmountFrom, feeDetails.storageFeeAmountTo, value.add(feeDetails.senderFeeAmount), value.sub(feeDetails.receipentFeeAmount));

            return true;
        } else {
            if(time_of_last_transaction[to] == 0) {
                time_of_last_transaction[to] = block.timestamp;
            }

            if(simpleTransfer) {
                _transfer(from, to, value, vaultWallet, feeDetails.storageFeeAmountTo, feeDetails.storageFeeAmountFrom);
            } else {
                super.transferFrom(from, to, value, vaultWallet, feeDetails.storageFeeAmountTo, feeDetails.storageFeeAmountFrom);
            }

            emit TransferDetails(value, 0, 0, feeDetails.storageFeeAmountFrom, feeDetails.storageFeeAmountTo, value.add(feeDetails.senderFeeAmount), value.sub(feeDetails.receipentFeeAmount));

            return true;
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        uint256 senderStorageFee = _calculateStorageFee(msg.sender, block.timestamp);

        if(senderStorageFee > 0) {
            _transfer(msg.sender, vaultWallet, senderStorageFee.add(_calculateStorageFee(spender, block.timestamp)));
            time_of_last_transaction[msg.sender] = block.timestamp;
        }

        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 senderStorageFee = _calculateStorageFee(msg.sender, block.timestamp);

        if(senderStorageFee > 0) {
            _transfer(msg.sender, vaultWallet, senderStorageFee.add(_calculateStorageFee(spender, block.timestamp)));
            time_of_last_transaction[msg.sender] = block.timestamp;
        }

        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 senderStorageFee = _calculateStorageFee(msg.sender, block.timestamp);

        if(senderStorageFee > 0) {
            _transfer(msg.sender, vaultWallet, senderStorageFee.add(_calculateStorageFee(spender, block.timestamp)));
            time_of_last_transaction[msg.sender] = block.timestamp;
        }

        return super.decreaseAllowance(spender, subtractedValue);
    }

    function mint(address to, uint256 value, uint256 timestamp) public onlyOwner returns (bool) {
        _mint(to, value);

        uint256 receipentStorageFee = _calculateStorageFee(to, timestamp);
        
        if(receipentStorageFee > 0) {
            _transfer(to, vaultWallet, receipentStorageFee);
            time_of_last_transaction[to] = block.timestamp;
        }

        if(time_of_last_transaction[to] == 0) {
            time_of_last_transaction[to] = block.timestamp;
        }

        emit TransferDetails(value, 0, receipentStorageFee, 0, receipentStorageFee, value, value.sub(receipentStorageFee));
        return true;
    }

    function burn(uint256 amount) public onlyOwner {
        uint256 senderStorageFee = _calculateStorageFee(msg.sender, block.timestamp);

        if(senderStorageFee > 0) {
            _transfer(msg.sender, vaultWallet, senderStorageFee);
            time_of_last_transaction[msg.sender] = block.timestamp;
        }

        _burn(msg.sender, amount);
    }

    function setVaultWallet(address newVaultWallet) public onlyOwner {
        require(newVaultWallet != address(0));

        whitelist.setStorageWhitelisted(vaultWallet, 0);
        whitelist.setTransferWhitelisted(vaultWallet, 0);

        vaultWallet = newVaultWallet;

        whitelist.setStorageWhitelisted(newVaultWallet, 255);
        whitelist.setTransferWhitelisted(newVaultWallet, 255);
    }

    function withdrawStorageFee(address[] calldata holders) external {
        require(permissionService.isTokenManagerAdmin(msg.sender));

        for(uint i = 0; i < holders.length; i ++) {
            uint fee = _calculateStorageFee(holders[i], block.timestamp);
            if(fee > 0) {
                _transfer(holders[i], vaultWallet, fee);
                time_of_last_transaction[holders[i]] = block.timestamp;
            }
        }
    }

    function seizeFunds(address user, uint256 amount) external {
        require(permissionService.isTokenManagerAdmin(msg.sender) || permissionService.isAuditor(msg.sender));
        _transfer(user, msg.sender, amount == 0 ? super.balanceOf(user) : amount);
    }

    function upgradeFeeProxy(address _newFeeProxy) external onlyOwner {
        require(_newFeeProxy != address(0));
        feeProxy = IFeeProxy(_newFeeProxy);
    }

    function getStorageFee(address _address, uint256 _fromBlock) public view returns(uint256) {
        return _calculateStorageFee(_address, _fromBlock);
    }
 
    function _calculateStorageFee(address _address, uint256 timestamp) internal view returns(uint256) {
        uint256 storageFeeDiscount = whitelist.getStorageDiscount(_address);
        uint256 finalDiscount;
        uint256 storageFee;

        if(time_of_last_transaction[_address] == 0) {
            storageFee = feeProxy.calculateStorageFee(_balances[_address], timestamp);
            finalDiscount = storageFee.mul(uint256(storageFeeDiscount)).div(10000);

            return storageFee.sub(finalDiscount);
        }

        if(time_of_last_transaction[_address] + 1 hours < block.timestamp) {
            return 0;
        }

        storageFee = feeProxy.calculateStorageFee(_balances[_address], time_of_last_transaction[_address]);
        finalDiscount = storageFee.mul(uint256(storageFeeDiscount)).div(10000);
        finalDiscount = finalDiscount.add(whitelist.getStorageFlatDiscount(_address));

        if(storageFee < finalDiscount) {
            return 0;
        } else {
            return storageFee.sub(finalDiscount);
        }
    }

    function _calculateTransferFee(address from, address to, uint256 value, bool _reverse_charge) internal view returns(uint256) {
        uint256 transferFeeDiscount;
        uint256 finalDiscount;
        uint256 transferFee = feeProxy.calculateTransferFee(value);

        transferFeeDiscount = whitelist.getTransferDiscount(_reverse_charge ? from : to);
        finalDiscount = transferFee.mul(uint256(transferFeeDiscount)).div(10000);
        finalDiscount = finalDiscount.add(whitelist.getTransferFlatDiscount(_reverse_charge ? from : to));
        
        if(transferFee < finalDiscount) {
            return 0;
        } else {
            return transferFee.sub(finalDiscount);
        }
    }
}

pragma solidity 0.5.8;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.5.8;

interface IFeeProxy {
    function calculateStorageFee(uint256 _balance, uint256 _timeUpdate) external view returns(uint256);
    function calculateTransferFee(uint256 value) external view returns(uint256);
}

pragma solidity 0.5.8;

interface IFreeze {
    function isFreezed(address account) external view returns(bool);
}

pragma solidity 0.5.8;

interface IPausable {
    function paused() external view returns (bool);
}

pragma solidity 0.5.8;

interface IWhitelist {
    function getStorageDiscount(address account) external view returns (uint256);
    function getTransferDiscount(address account) external view returns (uint256);
    function getStorageFlatDiscount(address account) external view returns (uint256);
    function getTransferFlatDiscount(address account) external view returns (uint256);
    
    function setStorageWhitelisted(address account, uint256 groupId) external;
    function setTransferWhitelisted(address account, uint256 groupId) external;
    function setTxGroupDiscountRate(uint256 groupId, uint256 discount) external;
    function setStorageGroupDiscountRate(uint256 groupId, uint256 discount) external;
    function setTxGroupDiscountFlatRate(uint256 groupId, uint256 discount) external;
    function setStorageGroupDiscountFlatRate(uint256 groupId, uint256 discount) external;
}

pragma solidity 0.5.8;

import "./ERC20.sol";

contract MetaERC20 is ERC20 {
    bytes32 public DOMAIN_SEPARATOR;

    // bytes32 public constant TRANSFER_TYPEHASH = keccak256("transfer(address to,uint256 value,address signer,uint256 nonce)");
    bytes32 public constant TRANSFER_TYPEHASH = 0xf931a2d2d43aecd909a3681a4b5c587b27a5871a2664fd7aa23c81e562ea9273;

    string public constant version  = "1";
    mapping (address => uint) public nonces;

    function checkSignature(address account, address signer, uint256 amount, bytes32 TYPEHASH, uint256 nonce, uint8 v, bytes32 r, bytes32 s) internal returns(bool) {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TYPEHASH, account, amount, signer, nonce))
        ));

        require(account != address(0), "AgAu/invalid-account-address");
        require(signer != address(0), "AgAu/invalid-signer-address");
        require(signer == ecrecover(digest, v, r, s), "AgAu/invalid-signature");
        require(nonce == nonces[signer]++, "AgAu/invalid-nonce");

        return true;
    }
}

pragma solidity 0.5.8;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "petersburg",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}