/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// File: @axie/contract-library/contracts/cryptography/ECVerify.sol

pragma solidity ^0.5.2;


library ECVerify {

  enum SignatureMode {
    EIP712,
    GETH,
    TREZOR
  }

  function recover(bytes32 _hash, bytes memory _signature) internal pure returns (address _signer) {
    return recover(_hash, _signature, 0);
  }

  // solium-disable-next-line security/no-assign-params
  function recover(bytes32 _hash, bytes memory _signature, uint256 _index) internal pure returns (address _signer) {
    require(_signature.length >= _index + 66);

    SignatureMode _mode = SignatureMode(uint8(_signature[_index]));
    bytes32 _r;
    bytes32 _s;
    uint8 _v;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      _r := mload(add(_signature, add(_index, 33)))
      _s := mload(add(_signature, add(_index, 65)))
      _v := and(255, mload(add(_signature, add(_index, 66))))
    }

    if (_v < 27) {
      _v += 27;
    }

    require(_v == 27 || _v == 28);

    if (_mode == SignatureMode.GETH) {
      _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    } else if (_mode == SignatureMode.TREZOR) {
      _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n\x20", _hash));
    }

    return ecrecover(_hash, _v, _r, _s);
  }

  function ecverify(bytes32 _hash, bytes memory _signature, address _signer) internal pure returns (bool _valid) {
    return _signer == recover(_hash, _signature);
  }
}

// File: @axie/contract-library/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Since Solidity automatically asserts when dividing by 0,
    // but we only need it to revert.
    require(b > 0);
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Same reason as `div`.
    require(b > 0);
    return a % b;
  }

  function ceilingDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    return add(div(a, b), mod(a, b) > 0 ? 1 : 0);
  }

  function subU64(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require(b <= a);
    return a - b;
  }

  function addU8(uint8 a, uint8 b) internal pure returns (uint8 c) {
    c = a + b;
    require(c >= a);
  }
}

// File: @axie/contract-library/contracts/token/erc20/IERC20.sol

pragma solidity ^0.5.2;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

// File: @axie/contract-library/contracts/token/erc20/IERC20Mintable.sol

pragma solidity ^0.5.2;

interface IERC20Mintable {
  function mint(address _to, uint256 _value) external returns (bool _success);
}

// File: @axie/contract-library/contracts/token/erc721/IERC721.sol

pragma solidity ^0.5.2;


interface IERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId) external view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool _approved);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
}

// File: @axie/contract-library/contracts/token/erc721/IERC721Mintable.sol

pragma solidity ^0.5.2;


interface IERC721Mintable {
  function mint(address _to, uint256 _tokenId) external returns (bool);
  function mintNew(address _to) external returns (uint256 _tokenId);
}

// File: @axie/contract-library/contracts/util/AddressUtils.sol

pragma solidity ^0.5.2;


library AddressUtils {
  function toPayable(address _address) internal pure returns (address payable _payable) {
    return address(uint160(_address));
  }

  function isContract(address _address) internal view returns (bool _correct) {
    uint256 _size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { _size := extcodesize(_address) }
    return _size > 0;
  }
}

// File: @axie/contract-library/contracts/token/erc20/ERC20.sol

pragma solidity ^0.5.2;




contract ERC20 is IERC20 {
  using SafeMath for uint256;

  uint256 public totalSupply;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  function approve(address _spender, uint256 _value) public returns (bool _success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    require(_to != address(0));
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    require(_to != address(0));
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}

// File: @axie/contract-library/contracts/token/erc20/IERC20Detailed.sol

pragma solidity ^0.5.2;


interface IERC20Detailed {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function decimals() external view returns (uint8 _decimals);
}

// File: @axie/contract-library/contracts/token/erc20/ERC20Detailed.sol

pragma solidity ^0.5.2;




contract ERC20Detailed is ERC20, IERC20Detailed {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: @axie/contract-library/contracts/access/HasAdmin.sol

pragma solidity ^0.5.2;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0));
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}

// File: @axie/contract-library/contracts/access/HasMinters.sol

pragma solidity ^0.5.2;



contract HasMinters is HasAdmin {
  event MinterAdded(address indexed _minter);
  event MinterRemoved(address indexed _minter);

  address[] public minters;
  mapping (address => bool) public minter;

  modifier onlyMinter {
    require(minter[msg.sender]);
    _;
  }

  function addMinters(address[] memory _addedMinters) public onlyAdmin {
    address _minter;

    for (uint256 i = 0; i < _addedMinters.length; i++) {
      _minter = _addedMinters[i];

      if (!minter[_minter]) {
        minters.push(_minter);
        minter[_minter] = true;
        emit MinterAdded(_minter);
      }
    }
  }

  function removeMinters(address[] memory _removedMinters) public onlyAdmin {
    address _minter;

    for (uint256 i = 0; i < _removedMinters.length; i++) {
      _minter = _removedMinters[i];

      if (minter[_minter]) {
        minter[_minter] = false;
        emit MinterRemoved(_minter);
      }
    }

    uint256 i = 0;

    while (i < minters.length) {
      _minter = minters[i];

      if (!minter[_minter]) {
        minters[i] = minters[minters.length - 1];
        delete minters[minters.length - 1];
        minters.length--;
      } else {
        i++;
      }
    }
  }

  function isMinter(address _addr) public view returns (bool) {
    return minter[_addr];
  }
}

// File: @axie/contract-library/contracts/token/erc20/ERC20Mintable.sol

pragma solidity ^0.5.2;




contract ERC20Mintable is HasMinters, ERC20 {
  function mint(address _to, uint256 _value) public onlyMinter returns (bool _success) {
    return _mint(_to, _value);
  }

  function _mint(address _to, uint256 _value) internal returns (bool success) {
    totalSupply = totalSupply.add(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(address(0), _to, _value);
    return true;
  }
}

// File: contracts/chain/mainchain/WETH.sol

pragma solidity ^0.5.17;




contract WETH is ERC20Detailed {

  event Deposit(
    address _sender,
    uint256 _value
  );

  event Withdrawal(
    address _sender,
    uint256 _value
  );

  constructor () ERC20Detailed("Wrapped Ether", "WETH", 18)
    public
  {}

  function deposit()
    external
    payable
  {
    balanceOf[msg.sender] += msg.value;

    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 _wad)
    external
  {
    require(balanceOf[msg.sender] >= _wad);
    balanceOf[msg.sender] -= _wad;
    msg.sender.transfer(_wad);

    emit Withdrawal(msg.sender, _wad);
  }
}

// File: @axie/contract-library/contracts/proxy/ProxyStorage.sol

pragma solidity ^0.5.2;

/**
 * @title ProxyStorage
 * @dev Store the address of logic contact that the proxy should forward to.
 */
contract ProxyStorage is HasAdmin {
  address internal _proxyTo;
}

// File: @axie/contract-library/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.2;



contract Pausable is HasAdmin {
  event Paused();
  event Unpaused();

  bool public paused;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() public onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

  function unpause() public onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

// File: contracts/chain/common/IValidator.sol

pragma solidity ^0.5.17;


contract IValidator {
  event ValidatorAdded(uint256 indexed _id, address indexed _validator);
  event ValidatorRemoved(uint256 indexed _id, address indexed _validator);
  event ThresholdUpdated(
    uint256 indexed _id,
    uint256 indexed _numerator,
    uint256 indexed _denominator,
    uint256 _previousNumerator,
    uint256 _previousDenominator
  );

  function isValidator(address _addr) public view returns (bool);
  function getValidators() public view returns (address[] memory _validators);

  function checkThreshold(uint256 _voteCount) public view returns (bool);
}

// File: contracts/chain/common/Validator.sol

pragma solidity ^0.5.17;




contract Validator is IValidator {
  using SafeMath for uint256;

  mapping(address => bool) validatorMap;
  address[] public validators;
  uint256 public validatorCount;

  uint256 public num;
  uint256 public denom;

  constructor(address[] memory _validators, uint256 _num, uint256 _denom)
    public
  {
    validators = _validators;
    validatorCount = _validators.length;

    for (uint256 _i = 0; _i < validatorCount; _i++) {
      address _validator = _validators[_i];
      validatorMap[_validator] = true;
    }

    num = _num;
    denom = _denom;
  }

  function isValidator(address _addr)
    public
    view
    returns (bool)
  {
    return validatorMap[_addr];
  }

  function getValidators()
    public
    view
    returns (address[] memory _validators)
  {
    _validators = validators;
  }

  function checkThreshold(uint256 _voteCount)
    public
    view
    returns (bool)
  {
    return _voteCount.mul(denom) >= num.mul(validatorCount);
  }

  function _addValidator(uint256 _id, address _validator)
    internal
  {
    require(!validatorMap[_validator]);

    validators.push(_validator);
    validatorMap[_validator] = true;
    validatorCount++;

    emit ValidatorAdded(_id, _validator);
  }

  function _removeValidator(uint256 _id, address _validator)
    internal
  {
    require(isValidator(_validator));

    uint256 _index;
    for (uint256 _i = 0; _i < validatorCount; _i++) {
      if (validators[_i] == _validator) {
        _index = _i;
        break;
      }
    }

    validatorMap[_validator] = false;
    validators[_index] = validators[validatorCount - 1];
    validators.pop();

    validatorCount--;

    emit ValidatorRemoved(_id, _validator);
  }

  function _updateQuorum(uint256 _id, uint256 _numerator, uint256 _denominator)
    internal
  {
    require(_numerator <= _denominator);
    uint256 _previousNumerator = num;
    uint256 _previousDenominator = denom;

    num = _numerator;
    denom = _denominator;

    emit ThresholdUpdated(
      _id,
      _numerator,
      _denominator,
      _previousNumerator,
      _previousDenominator
    );
  }
}

// File: contracts/chain/mainchain/MainchainValidator.sol

pragma solidity ^0.5.17;




/**
 * @title Validator
 * @dev Simple validator contract
 */
contract MainchainValidator is Validator, HasAdmin {
  uint256 nonce;

  constructor(
    address[] memory _validators,
    uint256 _num,
    uint256 _denom
  ) Validator(_validators, _num, _denom) public {
  }

  function addValidators(address[] calldata _validators) external onlyAdmin {
    for (uint256 _i; _i < _validators.length; ++_i) {
      _addValidator(nonce++, _validators[_i]);
    }
  }

  function removeValidator(address _validator) external onlyAdmin {
    _removeValidator(nonce++, _validator);
  }

  function updateQuorum(uint256 _numerator, uint256 _denominator) external onlyAdmin {
    _updateQuorum(nonce++, _numerator, _denominator);
  }
}

// File: contracts/chain/common/Registry.sol

pragma solidity ^0.5.17;



contract Registry is HasAdmin {

  event ContractAddressUpdated(
    string indexed _name,
    bytes32 indexed _code,
    address indexed _newAddress
  );

  event TokenMapped(
    address indexed _mainchainToken,
    address indexed _sidechainToken,
    uint32 _standard
  );

  string public constant GATEWAY = "GATEWAY";
  string public constant WETH_TOKEN = "WETH_TOKEN";
  string public constant VALIDATOR = "VALIDATOR";
  string public constant ACKNOWLEDGEMENT = "ACKNOWLEDGEMENT";

  struct TokenMapping {
    address mainchainToken;
    address sidechainToken;
    uint32 standard; // 20, 721 or any other standards
  }

  mapping(bytes32 => address) public contractAddresses;
  mapping(address => TokenMapping) public mainchainMap;
  mapping(address => TokenMapping) public sidechainMap;

  function getContract(string calldata _name)
    external
    view
    returns (address _address)
  {
    bytes32 _code = getCode(_name);
    _address = contractAddresses[_code];
    require(_address != address(0));
  }

  function isTokenMapped(address _token, uint32 _standard, bool _isMainchain)
    external
    view
    returns (bool)
  {
    TokenMapping memory _mapping = _getTokenMapping(_token, _isMainchain);

    return _mapping.mainchainToken != address(0) &&
      _mapping.sidechainToken != address(0) &&
      _mapping.standard == _standard;
  }

  function updateContract(string calldata _name, address _newAddress)
    external
    onlyAdmin
  {
    bytes32 _code = getCode(_name);
    contractAddresses[_code] = _newAddress;

    emit ContractAddressUpdated(_name, _code, _newAddress);
  }

  function mapToken(address _mainchainToken, address _sidechainToken, uint32 _standard)
    external
    onlyAdmin
  {
    TokenMapping memory _map = TokenMapping(
      _mainchainToken,
      _sidechainToken,
      _standard
    );

    mainchainMap[_mainchainToken] = _map;
    sidechainMap[_sidechainToken] = _map;

    emit TokenMapped(
      _mainchainToken,
      _sidechainToken,
      _standard
    );
  }

  function clearMapToken(address _mainchainToken, address _sidechainToken)
    external
    onlyAdmin
  {
    TokenMapping storage _mainchainMap = mainchainMap[_mainchainToken];
    _clearMapEntry(_mainchainMap);

    TokenMapping storage _sidechainMap = sidechainMap[_sidechainToken];
    _clearMapEntry(_sidechainMap);
  }

  function getMappedToken(
    address _token,
    bool _isMainchain
  )
    external
    view
  returns (
    address _mainchainToken,
    address _sidechainToken,
    uint32 _standard
  )
  {
    TokenMapping memory _mapping = _getTokenMapping(_token, _isMainchain);
    _mainchainToken = _mapping.mainchainToken;
    _sidechainToken = _mapping.sidechainToken;
    _standard = _mapping.standard;
  }

  function getCode(string memory _name)
    public
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_name));
  }

  function _getTokenMapping(
    address _token,
    bool isMainchain
  )
    internal
    view
    returns (TokenMapping memory _mapping)
  {
    if (isMainchain) {
      _mapping = mainchainMap[_token];
    } else {
      _mapping = sidechainMap[_token];
    }
  }

  function _clearMapEntry(TokenMapping storage _entry)
    internal
  {
    _entry.mainchainToken = address(0);
    _entry.sidechainToken = address(0);
    _entry.standard = 0;
  }
}

// File: contracts/chain/mainchain/MainchainGatewayStorage.sol

pragma solidity ^0.5.17;







/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainGatewayStorage is ProxyStorage, Pausable {

  event TokenDeposited(
    uint256 indexed _depositId,
    address indexed _owner,
    address indexed _tokenAddress,
    address _sidechainAddress,
    uint32  _standard,
    uint256 _tokenNumber // ERC-20 amount or ERC721 tokenId
  );

  event TokenWithdrew(
    uint256 indexed _withdrawId,
    address indexed _owner,
    address indexed _tokenAddress,
    uint256 _tokenNumber
  );

  struct DepositEntry {
    address owner;
    address tokenAddress;
    address sidechainAddress;
    uint32  standard;
    uint256 tokenNumber;
  }

  struct WithdrawalEntry {
    address owner;
    address tokenAddress;
    uint256 tokenNumber;
  }

  Registry public registry;

  uint256 public depositCount;
  DepositEntry[] public deposits;
  mapping(uint256 => WithdrawalEntry) public withdrawals;

  function updateRegistry(address _registry) external onlyAdmin {
    registry = Registry(_registry);
  }
}

// File: contracts/chain/mainchain/MainchainGatewayManager.sol

pragma solidity ^0.5.17;











/**
 * @title MainchainGatewayManager
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
contract MainchainGatewayManager is MainchainGatewayStorage {
  using AddressUtils for address;
  using SafeMath for uint256;
  using ECVerify for bytes32;

  modifier onlyMappedToken(address _token, uint32 _standard) {
    require(
      registry.isTokenMapped(_token, _standard, true),
      "MainchainGatewayManager: Token is not mapped"
    );
    _;
  }

  modifier onlyNewWithdrawal(uint256 _withdrawalId) {
    WithdrawalEntry storage _entry = withdrawals[_withdrawalId];
    require(_entry.owner == address(0) && _entry.tokenAddress == address(0));
    _;
  }

  // Should be able to withdraw from WETH
  function()
    external
    payable
  {}

  function depositEth()
    external
    whenNotPaused
    payable
    returns (uint256)
  {
    return depositEthFor(msg.sender);
  }

  function depositERC20(address _token, uint256 _amount)
    external
    whenNotPaused
    returns (uint256)
  {
    return depositERC20For(msg.sender, _token, _amount);
  }

  function depositERC721(address _token, uint256 _tokenId)
    external
    whenNotPaused
    returns (uint256)
  {
    return depositERC721For(msg.sender, _token, _tokenId);
  }

  function depositEthFor(address _owner)
    public
    whenNotPaused
    payable
    returns (uint256)
  {
    address _weth = registry.getContract(registry.WETH_TOKEN());
    WETH(_weth).deposit.value(msg.value)();
    return _createDepositEntry(_owner, _weth, 20, msg.value);
  }

  function depositERC20For(address _user, address _token, uint256 _amount)
    public
    whenNotPaused
    returns (uint256)
  {
    require(
      IERC20(_token).transferFrom(msg.sender, address(this), _amount),
      "MainchainGatewayManager: ERC-20 token transfer failed"
    );
    return _createDepositEntry(_user, _token, 20, _amount);
  }

  function depositERC721For(address _user, address _token, uint256 _tokenId)
    public
    whenNotPaused
    returns (uint256)
  {
    IERC721(_token).transferFrom(msg.sender, address(this), _tokenId);
    return _createDepositEntry(_user, _token, 721, _tokenId);
  }

  function depositBulkFor(
    address _user,
    address[] memory _tokens,
    uint256[] memory _tokenNumbers
  )
    public
    whenNotPaused
  {
    require(_tokens.length == _tokenNumbers.length);

    for (uint256 _i = 0; _i < _tokens.length; _i++) {
      address _token = _tokens[_i];
      uint256 _tokenNumber = _tokenNumbers[_i];
      (,, uint32 _standard) = registry.getMappedToken(_token, true);

      if (_standard == 20) {
        depositERC20For(_user, _token, _tokenNumber);
      } else if (_standard == 721) {
        depositERC721For(_user, _token, _tokenNumber);
      } else {
        revert("Token is not mapped or token type not supported");
      }
    }
  }

  function withdrawToken(
    uint256 _withdrawalId,
    address _token,
    uint256 _amount,
    bytes memory _signatures
  )
    public
    whenNotPaused
  {
    withdrawTokenFor(
      _withdrawalId,
      msg.sender,
      _token,
      _amount,
      _signatures
    );
  }

  function withdrawTokenFor(
    uint256 _withdrawalId,
    address _user,
    address _token,
    uint256 _amount,
    bytes memory _signatures
  )
    public
    whenNotPaused
  {
    (,, uint32 _tokenType) = registry.getMappedToken(_token, true);

    if (_tokenType == 20) {
      withdrawERC20For(
        _withdrawalId,
        _user,
        _token,
        _amount,
        _signatures
      );
    } else if (_tokenType == 721) {
      withdrawERC721For(
        _withdrawalId,
        _user,
        _token,
        _amount,
        _signatures
      );
    }
  }

  function withdrawERC20(
    uint256 _withdrawalId,
    address _token,
    uint256 _amount,
    bytes memory _signatures
  )
    public
    whenNotPaused
  {
    withdrawERC20For(
      _withdrawalId,
      msg.sender,
      _token,
      _amount,
      _signatures
    );
  }

  function withdrawERC20For(
    uint256 _withdrawalId,
    address _user,
    address _token,
    uint256 _amount,
    bytes memory _signatures
  )
    public
    whenNotPaused
    onlyMappedToken(_token, 20)
  {
    bytes32 _hash = keccak256(
      abi.encodePacked(
        "withdrawERC20",
        _withdrawalId,
        _user,
        _token,
        _amount
      )
    );

    require(verifySignatures(_hash, _signatures));

    if (_token == registry.getContract(registry.WETH_TOKEN())) {
      _withdrawETHFor(_user, _amount);
    } else {
      uint256 _gatewayBalance = IERC20(_token).balanceOf(address(this));

      if (_gatewayBalance < _amount) {
        require(
          IERC20Mintable(_token).mint(address(this), _amount.sub(_gatewayBalance)),
          "MainchainGatewayManager: Minting ERC20 token to gateway failed"
        );
      }

      require(IERC20(_token).transfer(_user, _amount), "Transfer failed");
    }

    _insertWithdrawalEntry(
      _withdrawalId,
      _user,
      _token,
      _amount
    );
  }

  function withdrawERC721(
    uint256 _withdrawalId,
    address _token,
    uint256 _tokenId,
    bytes memory _signatures
  )
    public
    whenNotPaused
  {
    withdrawERC721For(
      _withdrawalId,
      msg.sender,
      _token,
      _tokenId,
      _signatures
    );
  }

  function withdrawERC721For(
    uint256 _withdrawalId,
    address _user,
    address _token,
    uint256 _tokenId,
    bytes memory _signatures
  )
    public
    whenNotPaused
    onlyMappedToken(_token, 721)
  {
    bytes32 _hash = keccak256(
      abi.encodePacked(
        "withdrawERC721",
        _withdrawalId,
        _user,
        _token,
        _tokenId
      )
    );

    require(verifySignatures(_hash, _signatures));

    if (!_tryERC721TransferFrom(_token, address(this), _user, _tokenId)) {
      require(
        IERC721Mintable(_token).mint(_user, _tokenId),
        "MainchainGatewayManager: Minting ERC721 token to gateway failed"
      );
    }

    _insertWithdrawalEntry(_withdrawalId, _user, _token, _tokenId);
  }

  /**
   * @dev returns true if there is enough signatures from validators.
   */
  function verifySignatures(
    bytes32 _hash,
    bytes memory _signatures
  )
    public
    view
    returns (bool)
  {
    uint256 _signatureCount = _signatures.length.div(66);

    Validator _validator = Validator(registry.getContract(registry.VALIDATOR()));
    uint256 _validatorCount = 0;
    address _lastSigner = address(0);

    for (uint256 i = 0; i < _signatureCount; i++) {
      address _signer = _hash.recover(_signatures, i.mul(66));
      if (_validator.isValidator(_signer)) {
        _validatorCount++;
      }
      // Prevent duplication of signatures
      require(_signer > _lastSigner);
      _lastSigner = _signer;
    }

    return _validator.checkThreshold(_validatorCount);
  }

  function _createDepositEntry(
    address _owner,
    address _token,
    uint32 _standard,
    uint256 _number
  )
    internal
    onlyMappedToken(_token, _standard)
    returns (uint256 _depositId)
  {
    (,address _sidechainToken, uint32 _tokenStandard) = registry.getMappedToken(_token, true);
    require(_standard == _tokenStandard);

    DepositEntry memory _entry = DepositEntry(
      _owner,
      _token,
      _sidechainToken,
      _standard,
      _number
    );

    deposits.push(_entry);
    _depositId = depositCount++;

    emit TokenDeposited(
      _depositId,
      _owner,
      _token,
      _sidechainToken,
      _standard,
      _number
    );
  }

  function _insertWithdrawalEntry(
    uint256 _withdrawalId,
    address _owner,
    address _token,
    uint256 _number
  )
    internal
    onlyNewWithdrawal(_withdrawalId)
  {
    WithdrawalEntry memory _entry = WithdrawalEntry(
      _owner,
      _token,
      _number
    );

    withdrawals[_withdrawalId] = _entry;

    emit TokenWithdrew(_withdrawalId, _owner, _token, _number);
  }

  function _withdrawETHFor(
    address _user,
    uint256 _amount
  )
    internal
  {
    address _weth = registry.getContract(registry.WETH_TOKEN());
    WETH(_weth).withdraw(_amount);
    _user.toPayable().transfer(_amount);
  }

  // See more here https://blog.polymath.network/try-catch-in-solidity-handling-the-revert-exception-f53718f76047
  function _tryERC721TransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
    returns (bool)
  {
    (bool success,) = _token.call(
      abi.encodeWithSelector(
        IERC721(_token).transferFrom.selector, _from, _to, _tokenId
      )
    );
    return success;
  }
}