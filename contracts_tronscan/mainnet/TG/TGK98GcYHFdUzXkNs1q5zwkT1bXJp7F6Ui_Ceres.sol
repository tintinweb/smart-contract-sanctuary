//SourceUnit: Access.sol

// SPDX-License-Identifier: BSD-3-Clause

/**
 *        # ###                                           
 *      /  /###  /                                        
 *     /  /  ###/                                         
 *    /  ##   ##                                          
 *   /  ###                                               
 *  ##   ##          /##  ###  /###     /##       /###    
 *  ##   ##         / ###  ###/ #### / / ###     / #### / 
 *  ##   ##        /   ###  ##   ###/ /   ###   ##  ###/  
 *  ##   ##       ##    ### ##       ##    ### ####       
 *  ##   ##       ########  ##       ########    ###      
 *   ##  ##       #######   ##       #######       ###    
 *    ## #      / ##        ##       ##              ###  
 *     ###     /  ####    / ##       ####    /  /###  ##  
 *      ######/    ######/  ###       ######/  / #### /   
 *        ###       #####    ###       #####      ###/    
 */

pragma solidity 0.6.0;

import './DataStorage.sol';

contract Access is DataStorage {

  uint internal constant ENTRY_ENABLED = 1;
  uint internal constant ENTRY_DISABLED = 2;

  uint internal reentryStatus;

  modifier isOwner(address _account) {
    require(owner == _account, "Restricted Access!");
    _;
  }
  
  modifier blockReEntry() {
    require(reentryStatus != ENTRY_DISABLED, "Security Block");
    reentryStatus = ENTRY_DISABLED;

    _;

    reentryStatus = ENTRY_ENABLED;
  }

  function setLockOperator(address _addr) external isOwner(msg.sender) {
      systemLockOperator = _addr;
    }

  function setHolder(address _addr) external isOwner(msg.sender) {
      holder = _addr;
    }
}

//SourceUnit: Ceres.sol

// SPDX-License-Identifier: BSD-3-Clause

/**
 *        # ###                                           
 *      /  /###  /                                        
 *     /  /  ###/                                         
 *    /  ##   ##                                          
 *   /  ###                                               
 *  ##   ##          /##  ###  /###     /##       /###    
 *  ##   ##         / ###  ###/ #### / / ###     / #### / 
 *  ##   ##        /   ###  ##   ###/ /   ###   ##  ###/  
 *  ##   ##       ##    ### ##       ##    ### ####       
 *  ##   ##       ########  ##       ########    ###      
 *   ##  ##       #######   ##       #######       ###    
 *    ## #      / ##        ##       ##              ###  
 *     ###     /  ####    / ##       ####    /  /###  ##  
 *      ######/    ######/  ###       ######/  / #### /   
 *        ###       #####    ###       #####      ###/    
 */

pragma solidity 0.6.0;

import "./IERC1132.sol";
import "./IERC777.sol";
import "./IERC20.sol";
import "./DataStorage.sol";
import "./Access.sol";

contract Ceres is DataStorage, Access, IERC1132, IERC777, IERC777Recipient, IERC20 {

    constructor(string memory _name, string memory _symbol, uint256 _mintToken, uint256 _supply) public {
        owner = msg.sender;        

        tokenName = _name;
        tokenSymbol = _symbol;
        tokenTotalSupply = _supply * (10 ** 18);

        _mint(msg.sender, msg.sender, _mintToken, "Initial", "");        

        defaultTokenOperatorsList = new address[](0);

        for (uint256 i=0;i < defaultTokenOperatorsList.length;i++) {
            defaultTokenOperators[defaultTokenOperatorsList[i]] = true;
        }

        ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
        ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));    
    }

    function name() external view override(IERC777) returns (string memory) {
        return tokenName;
    }

    function symbol() external view override(IERC777) returns (string memory) {
        return tokenSymbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function granularity() external view override(IERC777) returns (uint256) {
        return 1;
    }

    function totalSupply() external view override(IERC20, IERC777) returns (uint256) {
        return tokenSupply;
    }

    function maxSupply() external view returns (uint256) { //todo rename this????
        return tokenTotalSupply;
    }

    function balanceOf(address _tokenHolder) public view override(IERC20, IERC777) returns (uint256) {
        return accountBalances[_tokenHolder];
    }

    function totalBalanceOf(address _tokenHolder) external view override(IERC1132) returns (uint256) {
        uint256 amount = balanceOf(_tokenHolder);

        for (uint256 i=0;i < lockReason[_tokenHolder].length;i++) {
            amount = amount.add(tokensLocked(_tokenHolder, lockReason[_tokenHolder][i]));
        }   

        return amount;
    }    

    function allowance(address _tokenHolder, address _spender) external view override(IERC20) returns (uint256) {
        return tokenAllowances[_tokenHolder][_spender];
    }

    function tokensLocked(address _tokenHolder, bytes32 _reason) public view override(IERC1132) returns (uint256) {
        return locked[_tokenHolder][_reason].amount;
    }
    
    function tokensLockedAtTime(address _tokenHolder, bytes32 _reason, uint256 _time) external view override(IERC1132) returns (uint256) {
        if (locked[_tokenHolder][_reason].lockedUntil > _time) {
            return locked[_tokenHolder][_reason].amount;
        }

        return 0;
    }
    
    function tokensUnlockable(address _tokenHolder, bytes32 _reason) public view override(IERC1132) returns (uint256) {
        if (locked[_tokenHolder][_reason].lockedUntil <= block.timestamp) { 
            return locked[_tokenHolder][_reason].amount;
        }

        return 0;
    }

    function getUnlockableTokens(address _tokenHolder) external view override(IERC1132) returns (uint256) {
        uint256 unlockableTokens;

        for (uint256 i=0; i < lockReason[_tokenHolder].length;i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_tokenHolder, lockReason[_tokenHolder][i]));
        }  

        return unlockableTokens;
    }

    function send(address _recipient, uint256 _amount, bytes calldata _data) external override(IERC777) blockReEntry() {
        _send(msg.sender, msg.sender, _recipient, _amount, _data, "", true);
    }

    function operatorSend(address _sender, address _recipient, uint256 _amount, bytes calldata _data, bytes calldata _operatorData) external override(IERC777) blockReEntry() {
        require(isOperatorFor(msg.sender, _sender), "ERC777: caller is not an operator for holder");

        _send(msg.sender, _sender, _recipient, _amount, _data, _operatorData, true);
    }

    
    function transfer(address _recipient, uint256 _amount) external override(IERC20) blockReEntry() returns (bool) {
        _send(msg.sender, msg.sender, _recipient, _amount, "", "", false);

        return true;
    }

    function transferFrom(address _tokenHolder, address _recipient, uint256 _amount) external override(IERC20) blockReEntry() returns (bool) {        
        _send(msg.sender, _tokenHolder, _recipient, _amount, "", "", false);
        _approve(_tokenHolder, msg.sender, tokenAllowances[_tokenHolder][msg.sender].sub(_amount, "ERC777: transfer amount exceeds allowance"));
        
        return true;
    }

    function lock(bytes32 _reason, uint256 _amount, uint256 _time) external override(IERC1132) blockReEntry() returns (bool) {        
        require(_amount != 0 && _time != 0, "Amount or time can not be 0");

        uint256 lockedUntil = block.timestamp.add(_time);

        if (locked[msg.sender][_reason].amount == 0) {
            lockReason[msg.sender].push(_reason);
            locked[msg.sender][_reason] = lockToken(0, lockedUntil);
        } 

        return _lock(msg.sender, msg.sender, msg.sender, _reason, _amount, lockedUntil);
    }

    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time) external blockReEntry() returns (bool) {
        require(_amount != 0 && _time != 0, "Amount or time can not be 0");

        uint256 lockedUntil = block.timestamp.add(_time);

        if (locked[_to][_reason].amount == 0) {
            lockReason[_to].push(_reason);
            locked[_to][_reason] = lockToken(0, lockedUntil);
        } 

        return _lock(msg.sender, msg.sender, _to, _reason, _amount, lockedUntil);
    }

    function operatorLock(address _from, bytes32 _reason, uint256 _amount, uint256 _time) external blockReEntry() returns (bool) {
        require(isLockOperatorFor(msg.sender, _from), "Caller is not an operator for holder");

        uint256 lockedUntil = block.timestamp.add(_time);

        if (locked[_from][_reason].amount == 0) {
            lockReason[_from].push(_reason);
            locked[_from][_reason] = lockToken(0, lockedUntil);
        } 

        return _lock(msg.sender, _from, _from, _reason, _amount, lockedUntil);
    }

    function unlock(address _tokenHolder) external override(IERC1132) blockReEntry() returns (uint256) {
        uint256 lockedTokens;
        uint256 unlockableTokens;
        bool[] memory remove = new bool[](lockReason[_tokenHolder].length);

        for (uint256 i=0; i < lockReason[_tokenHolder].length;i++) {
            lockedTokens = tokensUnlockable(_tokenHolder, lockReason[_tokenHolder][i]);

            if (lockedTokens > 0) {
                remove[i] = true;
                
                unlockableTokens = unlockableTokens.add(lockedTokens);
                delete locked[_tokenHolder][lockReason[_tokenHolder][i]];
                    
                emit Unlocked(_tokenHolder, lockReason[_tokenHolder][i], lockedTokens);
            }
        }

        if (unlockableTokens > 0) {
            for (uint256 i=(remove.length - 1);i >= 0;i--) {
                if (remove[i] == true) {
                    delete lockReason[_tokenHolder][i];
                }

                if (i == 0) {
                    break;
                }
            }

            _send(address(this), address(this), _tokenHolder, unlockableTokens, "", "", true);
        }

        return unlockableTokens;
    }

    function burn(uint256 _amount, bytes calldata _data) external override(IERC777) {
        _burn(msg.sender, msg.sender, _amount, _data, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes calldata _data, bytes calldata _operatorData) external override(IERC777) blockReEntry() {
        require(isOperatorFor(msg.sender, _tokenHolder), "ERC777: caller is not an operator for holder");

        _burn(msg.sender, _tokenHolder, _amount, _data, _operatorData);
    }
      
    function mint(address _tokenHolder, uint256 _amount, bytes calldata _userData, bytes calldata _operatorData) external isOwner(msg.sender) {
        _mint(msg.sender, _tokenHolder, _amount, _userData, _operatorData);
    }

    function authorizeOperator(address _operator) external override(IERC777) {
        require(msg.sender != _operator, "ERC777: authorizing self as operator");

        if (defaultTokenOperators[_operator]) {
            delete revokedDefaultTokenOperators[msg.sender][_operator];
        } else {
            tokenOperators[msg.sender][_operator] = true;
        }

        emit AuthorizedOperator(_operator, msg.sender);
    }

    function revokeOperator(address _operator) external override(IERC777) {
        require(_operator != msg.sender, "ERC777: revoking self as operator");

        if (defaultTokenOperators[_operator]) {
            revokedDefaultTokenOperators[msg.sender][_operator] = true;
        } else {
            delete tokenOperators[msg.sender][_operator];
        }

        emit RevokedOperator(_operator, msg.sender);
    }

    function approve(address _spender, uint256 _amount) external override(IERC20) returns (bool) {
        _approve(msg.sender, _spender, _amount);

        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        _approve(msg.sender, _spender, tokenAllowances[msg.sender][_spender].add(_addedValue));

        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        require(tokenAllowances[msg.sender][_spender] >= _subtractedValue, "ERC20: decreased allowance below zero");

        _approve(msg.sender, _spender, tokenAllowances[msg.sender][_spender].sub(_subtractedValue));

        return true;
    }

    function authorizeLockOperator(address _operator) external {
        require(msg.sender != _operator, "Authorizing self as operator");

        if (_operator == systemLockOperator) {
            delete revokedSystemLockOperator[msg.sender];
        } else {
            lockOperators[msg.sender][_operator] = true;
        }

        emit AuthorizedLockOperator(_operator, msg.sender);
    }

    function revokeLockOperator(address _operator) external {
        require(_operator != msg.sender, "Revoking self as operator");

        if (_operator == systemLockOperator) {
            revokedSystemLockOperator[msg.sender] = true;
        } else {
            delete lockOperators[msg.sender][_operator];
        }

        emit RevokedLockOperator(_operator, msg.sender);
    }

    function extendLock(bytes32 _reason, uint256 _time) external override(IERC1132) returns (bool) {
        require(tokensLocked(msg.sender, _reason) > 0, "No tokens locked");

        locked[msg.sender][_reason].lockedUntil = locked[msg.sender][_reason].lockedUntil.add(_time);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].lockedUntil);

        return true;
    }

    function increaseLockAmount(bytes32 _reason, uint256 _amount) external override(IERC1132) blockReEntry() returns (bool) {
        require(tokensLocked(msg.sender, _reason) > 0, "No tokens locked");
        
        return _lock(msg.sender, msg.sender, msg.sender, _reason, _amount, 0);
    }

    function isOperatorFor(address _operator, address _tokenHolder) public view override(IERC777) returns (bool) {
        return _operator == _tokenHolder ||
            (defaultTokenOperators[_operator] && !revokedDefaultTokenOperators[_tokenHolder][_operator]) ||
            tokenOperators[_tokenHolder][_operator];
    }

    function isLockOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return _operator == _tokenHolder ||
            (_operator == systemLockOperator && !revokedSystemLockOperator[_tokenHolder]) ||
            lockOperators[_tokenHolder][_operator];
    }

    function defaultOperators() external view override(IERC777) returns (address[] memory) {
        return defaultTokenOperatorsList;
    }

    function getSystemLockOperator() external view returns (address) {
        return systemLockOperator;
    }
      
    function _lock(address _operator, address _from, address _to, bytes32 _reason, uint256 _amount, uint256 _time) internal returns (bool) {
        _send(_operator, _from, address(this), _amount, "", "", true);

        if (locked[_to][_reason].lockedUntil < _time) {
            locked[_to][_reason].lockedUntil = _time;
        }

        locked[_to][_reason].amount = locked[_to][_reason].amount.add(_amount);

        emit Locked(_to, _reason, locked[_to][_reason].amount, locked[_to][_reason].lockedUntil);

        return true;
    }
    
    function _approve(address _tokenHolder, address _spender, uint256 _amount) internal {
        require(_tokenHolder != address(0), "ERC777: approve from the zero address");
        require(_spender != address(0), "ERC777: approve to the zero address");

        tokenAllowances[_tokenHolder][_spender] = _amount;

        emit Approval(_tokenHolder, _spender, _amount);
    }

    function _send(address _operator, address _from, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData, bool _requireReceptionAck) internal {
        require(_from != address(0), "ERC777: send from the zero address");
        require(_to != address(0), "ERC777: send to the zero address");

        _callTokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);

        _move(_operator, _from, _to, _amount, _userData, _operatorData);

        _callTokensReceived(_operator, _from, _to, _amount, _userData, _operatorData, _requireReceptionAck);
    }

    function _move(address _operator, address _from, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData) private {
        accountBalances[_from] = accountBalances[_from].sub(_amount, "ERC777: transfer amount exceeds balance");
        accountBalances[_to] = accountBalances[_to].add(_amount);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
        emit Transfer(_from, _to, _amount);
    }

    function _mint(address operator, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData) internal {
        require(_to != address(0), "ERC777: mint to the zero address");

        uint256 amount = _amount * (10 ** 18);

        tokenSupply = tokenSupply.add(amount);
        accountBalances[_to] = accountBalances[_to].add(amount);

        require(tokenSupply < tokenTotalSupply, "Max token supply reached.");

        _callTokensReceived(operator, address(0), _to, amount, _userData, _operatorData, true);

        emit Minted(operator, _to, amount, _userData, _operatorData);
        emit Transfer(address(0), _to, amount);
    }

    function _burn(address _operator, address _from, uint256 _amount, bytes memory _data, bytes memory _operatorData) internal {
        require(_from != address(0), "ERC777: burn from the zero address");

        _callTokensToSend(_operator, _from, address(0), _amount, _data, _operatorData);

        accountBalances[_from] = accountBalances[_from].sub(_amount, "ERC777: burn amount exceeds balance");
        tokenSupply = tokenSupply.sub(_amount);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);

        emit Burned(_operator, _from, _amount, _data, _operatorData);
        emit Transfer(_from, address(0), _amount);
    }   

    function _callTokensToSend(address _operator, address _from, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData) private {
        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_from, TOKENS_SENDER_INTERFACE_HASH);

        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
        }
    }

    function _callTokensReceived(address _operator, address _from, address _to, uint256 _amount, bytes memory _userData, bytes memory _operatorData, bool _requireReceptionAck) private {
        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_to, TOKENS_RECIPIENT_INTERFACE_HASH);

        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(_operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_requireReceptionAck) {
            require(!isContract(_to), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external override(IERC777Recipient) {
        require(msg.sender == address(this), "Not accepted token transfer attempt");
    }
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function handleForfeitedBalance(address payable _addr) external {
        require((msg.sender == owner || msg.sender == holder), "Restricted Access!");
        
        (bool success, ) = _addr.call.value(address(this).balance)("");

        require(success, 'Failed');
    }
}

//SourceUnit: DataStorage.sol

// SPDX-License-Identifier: BSD-3-Clause

/**
 *        # ###                                           
 *      /  /###  /                                        
 *     /  /  ###/                                         
 *    /  ##   ##                                          
 *   /  ###                                               
 *  ##   ##          /##  ###  /###     /##       /###    
 *  ##   ##         / ###  ###/ #### / / ###     / #### / 
 *  ##   ##        /   ###  ##   ###/ /   ###   ##  ###/  
 *  ##   ##       ##    ### ##       ##    ### ####       
 *  ##   ##       ########  ##       ########    ###      
 *   ##  ##       #######   ##       #######       ###    
 *    ## #      / ##        ##       ##              ###  
 *     ###     /  ####    / ##       ####    /  /###  ##  
 *      ######/    ######/  ###       ######/  / #### /   
 *        ###       #####    ###       #####      ###/    
 */

pragma solidity 0.6.0;

import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "./SafeMath.sol";

contract DataStorage {
  using SafeMath for uint256;  

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x41b2bd2a5037d5e42824d3684b6de848cb517ad053);

  bytes32 constant internal TOKENS_SENDER_INTERFACE_HASH = 0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895; //keccak256("ERC777TokensSender")
  bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b; //keccak256("ERC777TokensRecipient")

  string internal tokenName;
  string internal tokenSymbol;

  uint256 internal tokenSupply;
  uint256 internal tokenTotalSupply;
  
  address internal owner;
  address internal holder;
  address internal systemLockOperator;
  
  address[] internal defaultTokenOperatorsList;
   
  mapping(address => bytes32[]) internal lockReason;
  mapping(address => uint256) internal accountBalances;
  mapping(address => bool) internal defaultTokenOperators;
  mapping(address => bool) internal revokedSystemLockOperator;
  mapping(address => mapping(bytes32 => lockToken)) internal locked;
  mapping(address => mapping(address => bool)) internal lockOperators;
  mapping(address => mapping(address => bool)) internal tokenOperators;
  mapping (address => mapping (address => uint256)) internal tokenAllowances;
  mapping(address => mapping(address => bool)) internal revokedDefaultTokenOperators;

  struct lockToken {
      uint256 amount;
      uint256 lockedUntil;
  }

  event RevokedLockOperator(address indexed operator, address indexed tokenHolder);
  event AuthorizedLockOperator(address indexed operator, address indexed tokenHolder);
}

//SourceUnit: IERC1132.sol

  
pragma solidity 0.6.0;

/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */

interface IERC1132 {
    
    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be locked
     * @param _time Lock time in seconds
     */
    function lock(bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);
  
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     */
    function tokensLocked(address _of, bytes32 _reason) external view returns (uint256 amount);
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specific time
     *
     * @param _of The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns (uint256 amount);
    
    /**
     * @dev Returns total tokens held by an address (locked + transferable)
     * @param _of The address to query the total balance of
     */
    function totalBalanceOf(address _of) external view returns (uint256 amount);
    
    /**
     * @dev Extends lock for a specified reason and time
     * @param _reason The reason to lock tokens
     * @param _time Lock extension time in seconds
     */
    function extendLock(bytes32 _reason, uint256 _time) external returns (bool);
    
    /**
     * @dev Increase number of tokens locked for a specified reason
     * @param _reason The reason to lock tokens
     * @param _amount Number of tokens to be increased
     */
    function increaseLockAmount(bytes32 _reason, uint256 _amount) external returns (bool);

    /**
     * @dev Returns unlockable tokens for a specified address for a specified reason
     * @param _of The address to query the the unlockable token count of
     * @param _reason The reason to query the unlockable tokens for
     */
    function tokensUnlockable(address _of, bytes32 _reason) external view returns (uint256 amount);
 
    /**
     * @dev Unlocks the unlockable tokens of a specified address
     * @param _of Address of user, claiming back unlockable tokens
     */
    function unlock(address _of) external returns (uint256 unlockableTokens);

    /**
     * @dev Gets the unlockable tokens of a specified address
     * @param _of The address to query the the unlockable token count of
     */
    function getUnlockableTokens(address _of) external view returns (uint256 unlockableTokens);

   /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );


}

//SourceUnit: IERC1820Registry.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

//SourceUnit: IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: IERC777.sol

  
// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

//SourceUnit: IERC777Recipient.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

//SourceUnit: IERC777Sender.sol

  
// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 *  their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}