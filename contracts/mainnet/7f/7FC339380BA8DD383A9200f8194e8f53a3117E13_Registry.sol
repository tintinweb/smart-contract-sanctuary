pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Registry is Ownable {
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

    function isTokenMapped(
        address _token,
        uint32 _standard,
        bool _isMainchain
    ) external view returns (bool) {
        TokenMapping memory _mapping = _getTokenMapping(_token, _isMainchain);

        return
            _mapping.mainchainToken != address(0) &&
            _mapping.sidechainToken != address(0) &&
            _mapping.standard == _standard;
    }

    function updateContract(string calldata _name, address _newAddress)
        external
        onlyOwner
    {
        bytes32 _code = getCode(_name);
        contractAddresses[_code] = _newAddress;

        emit ContractAddressUpdated(_name, _code, _newAddress);
    }

    function mapToken(
        address _mainchainToken,
        address _sidechainToken,
        uint32 _standard
    ) external onlyOwner {
        TokenMapping memory _map = TokenMapping(
            _mainchainToken,
            _sidechainToken,
            _standard
        );

        mainchainMap[_mainchainToken] = _map;
        sidechainMap[_sidechainToken] = _map;

        emit TokenMapped(_mainchainToken, _sidechainToken, _standard);
    }

    function clearMapToken(address _mainchainToken, address _sidechainToken)
        external
        onlyOwner
    {
        TokenMapping storage _mainchainMap = mainchainMap[_mainchainToken];
        _clearMapEntry(_mainchainMap);

        TokenMapping storage _sidechainMap = sidechainMap[_sidechainToken];
        _clearMapEntry(_sidechainMap);
    }

    function getMappedToken(address _token, bool _isMainchain)
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

    function getCode(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }

    function _getTokenMapping(address _token, bool isMainchain)
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

    function _clearMapEntry(TokenMapping storage _entry) internal {
        _entry.mainchainToken = address(0);
        _entry.sidechainToken = address(0);
        _entry.standard = 0;
    }
}

