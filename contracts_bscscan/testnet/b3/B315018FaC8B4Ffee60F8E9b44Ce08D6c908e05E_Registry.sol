/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

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

// File: @axie/contract-library/contracts/proxy/ProxyStorage.sol

pragma solidity ^0.5.2;

/**
 * @title ProxyStorage
 * @dev Store the address of logic contact that the proxy should forward to.
 */
contract ProxyStorage is HasAdmin {
    address internal _proxyTo;
}

// File: @axie/contract-library/contracts/proxy/Proxy.sol

pragma solidity ^0.5.2;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy is ProxyStorage {

    event ProxyUpdated(address indexed _new, address indexed _old);

    constructor(address _proxyTo) public {
        updateProxyTo(_proxyTo);
    }

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
    function implementation() public view returns (address) {
        return _proxyTo;
    }

    /**
    * @dev See more at: https://eips.ethereum.org/EIPS/eip-897
  * @return type of proxy - always upgradable
  */
    function proxyType() external pure returns (uint256) {
        // Upgradeable proxy
        return 2;
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function updateProxyTo(address _newProxyTo) public onlyAdmin {
        require(_newProxyTo != address(0x0));

        _proxyTo = _newProxyTo;
        emit ProxyUpdated(_newProxyTo, _proxyTo);
    }
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

// File: contracts/chain/mainchain/MainchainGatewayProxy.sol

pragma solidity ^0.5.17;
contract MainchainGatewayProxy is Proxy, MainchainGatewayStorage {
    constructor(address _proxyTo, address _registry)
    public
    Proxy(_proxyTo)
    {
        registry = Registry(_registry);
    }
}