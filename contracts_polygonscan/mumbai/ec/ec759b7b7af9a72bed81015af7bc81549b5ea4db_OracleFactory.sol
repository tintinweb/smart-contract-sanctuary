/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2019-10-04
*/

// File: contracts/commons/Ownable.sol

pragma solidity ^0.5.12;


contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == _owner, "The owner should be the sender");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    /**
        @dev Transfers the ownership of the contract.
        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// File: contracts/utils/Math.sol

pragma solidity ^0.5.12;


library Math {
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/commons/SortedList.sol

pragma solidity 0.5.12;



/**
 * @title SortedList
 * @author Joaquin Gonzalez & Agustin Aguilar ([email protected] & [email protected])
 * @dev An utility library for using sorted list data structures.
 */
library SortedList {
    using SortedList for SortedList.List;

    uint256 private constant HEAD = 0;

    struct List {
        uint256 size;
        mapping(uint256 => uint256) values;
        mapping(uint256 => uint256) links;
        mapping(uint256 => bool) exists;
    }

    /**
     * @dev Returns the value of a `_node`
     * @param self stored linked list from contract
     * @param _node a node to search value of
     * @return value of the node
     */
    function get(List storage self, uint256 _node) internal view returns (uint256) {
        return self.values[_node];
    }

    /**
     * @dev Insert node `_node` with a value
     * @param self stored linked list from contract
     * @param _node new node to insert
     * @param _value value of the new `_node` to insert
     * @notice If the `_node` does not exists, it's added to the list
     *   if the `_node` already exists, it updates its value.
     */
    function set(List storage self, uint256 _node, uint256 _value) internal {
        // Check if node previusly existed
        if (self.exists[_node]) {

            // Load the new and old position
            (uint256 leftOldPos, uint256 leftNewPos) = self.findOldAndNewLeftPosition(_node, _value);

            // If node position changed, we need to re-do the linking
            if (leftOldPos != leftNewPos && _node != leftNewPos) {
                // Remove prev link
                self.links[leftOldPos] = self.links[_node];

                // Create new link
                uint256 next = self.links[leftNewPos];
                self.links[leftNewPos] = _node;
                self.links[_node] = next;
            }
        } else {
            // Update size of the list
            self.size = self.size + 1;
            // Set node as existing
            self.exists[_node] = true;
            // Find position for the new node and update the links
            uint256 leftPosition = self.findLeftPosition(_value);
            uint256 next = self.links[leftPosition];
            self.links[leftPosition] = _node;
            self.links[_node] = next;
        }

        // Set the value for the node
        self.values[_node] = _value;
    }

    /**
     * @dev Returns the previus node of a given `_node`
     *   alongside to the previus node of a hypothetical new `_value`
     * @param self stored linked list from contract
     * @param _node a node to search for its left node
     * @param _value a value to seach for its hypothetical left node
     * @return `leftNodePost` the node previus to the given `_node` and
     *   `leftValPost` the node previus to the hypothetical new `_value`
     * @notice This method performs two seemingly unrelated tasks at the same time
     *   because both of those tasks require a list iteration, thus saving gas.
     */
    function findOldAndNewLeftPosition(
        List storage self,
        uint256 _node,
        uint256 _value
    ) internal view returns (
        uint256 leftNodePos,
        uint256 leftValPos
    ) {
        // Find old and new value positions
        bool foundNode;
        bool foundVal;

        // Iterate links
        uint256 c = HEAD;
        while (!foundNode || !foundVal) {
            uint256 next = self.links[c];

            // We should have found the old position
            // the new one must be at the end
            if (next == 0) {
                leftValPos = c;
                break;
            }

            // If the next node is the current node
            // we found the old position
            if (next == _node) {
                leftNodePos = c;
                foundNode = true;
            }

            // If the next value is higher and we didn't found one yet
            // the next value if the position
            if (self.values[next] > _value && !foundVal) {
                leftValPos = c;
                foundVal = true;
            }

            c = next;
        }
    }

    /**
     * @dev Get the left node for a given hypothetical `_value`
     * @param self stored linked list from contract
     * @param _value value to seek
     * @return uint256 left node for the given value
     */
    function findLeftPosition(List storage self, uint256 _value) internal view returns (uint256) {
        uint256 next = HEAD;
        uint256 c;

        do {
            c = next;
            next = self.links[c];
        } while(self.values[next] < _value && next != 0);

        return c;
    }

    /**
     * @dev Get the node on a given `_position`
     * @param self stored linked list from contract
     * @param _position node position to retrieve
     * @return the node key
     */
    function nodeAt(List storage self, uint256 _position) internal view returns (uint256) {
        uint256 next = self.links[HEAD];
        for (uint256 i = 0; i < _position; i++) {
            next = self.links[next];
        }

        return next;
    }

    /**
     * @dev Removes an entry from the sorted list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     */
    function remove(List storage self, uint256 _node) internal {
        require(self.exists[_node], "the node does not exists");

        uint256 c = self.links[HEAD];
        while (c != 0) {
            uint256 next = self.links[c];
            if (next == _node) {
                break;
            }

            c = next;
        }

        self.size -= 1;
        self.exists[_node] = false;
        self.links[c] = self.links[_node];
        delete self.links[_node];
        delete self.values[_node];
    }

    /**
     * @dev Get median beetween entry from the sorted list
     * @param self stored linked list from contract
     * @return uint256 the median
     */
    function median(List storage self) internal view returns (uint256) {
        uint256 elements = self.size;
        if (elements % 2 == 0) {
            uint256 node = self.nodeAt(elements / 2 - 1);
            return Math.average(self.values[node], self.values[self.links[node]]);
        } else {
            return self.values[self.nodeAt(elements / 2)];
        }
    }
}

// File: contracts/interfaces/RateOracle.sol

pragma solidity ^0.5.12;


/**
    @dev Defines the interface of a standard Diaspore RCN Oracle,
    The contract should also implement it's ERC165 interface: 0xa265d8e0
    @notice Each oracle can only support one currency
    @author Agustin Aguilar
*/
contract RateOracle {
    uint256 public constant VERSION = 5;
    bytes4 internal constant RATE_ORACLE_INTERFACE = 0xa265d8e0;

    /**
        3 or 4 letters symbol of the currency, Ej: ETH
    */
    function symbol() external view returns (string memory);

    /**
        Descriptive name of the currency, Ej: Ethereum
    */
    function name() external view returns (string memory);

    /**
        The number of decimals of the currency represented by this Oracle,
            it should be the most common number of decimal places
    */
    function decimals() external view returns (uint256);

    /**
        The base token on which the sample is returned
            should be the RCN Token address.
    */
    function token() external view returns (address);

    /**
        The currency symbol encoded on a UTF-8 Hex
    */
    function currency() external view returns (bytes32);

    /**
        The name of the Individual or Company in charge of this Oracle
    */
    function maintainer() external view returns (string memory);

    /**
        Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() external view returns (string memory);

    /**
        Returns a sample on how many token() are equals to how many currency()
    */
    function readSample(bytes calldata _data) external view returns (uint256 _tokens, uint256 _equivalent);
}

// File: contracts/interfaces/PausedProvider.sol

pragma solidity ^0.5.12;


interface PausedProvider {
    function isPaused() external view returns (bool);
}

// File: contracts/commons/Pausable.sol

pragma solidity ^0.5.12;



contract Pausable is Ownable {
    mapping(address => bool) public canPause;
    bool public paused;

    event Paused();
    event Started();
    event CanPause(address _pauser, bool _enabled);

    function setPauser(address _pauser, bool _enabled) external onlyOwner {
        canPause[_pauser] = _enabled;
        emit CanPause(_pauser, _enabled);
    }

    function pause() external {
        require(!paused, "already paused");

        require(
            msg.sender == _owner ||
            canPause[msg.sender],
            "not authorized to pause"
        );

        paused = true;
        emit Paused();
    }

    function start() external onlyOwner {
        require(paused, "not paused");
        paused = false;
        emit Started();
    }
}

// File: contracts/utils/StringUtils.sol

pragma solidity ^0.5.12;


library StringUtils {
    function toBytes32(string memory _a) internal pure returns (bytes32 b) {
        require(bytes(_a).length <= 32, "string too long");

        assembly {
            let bi := mul(mload(_a), 8)
            b := and(mload(add(_a, 32)), shl(sub(256, bi), sub(exp(2, bi), 1)))
        }
    }
}

// File: contracts/MultiSourceOracle.sol

pragma solidity ^0.5.12;









contract MultiSourceOracle is RateOracle, Ownable, Pausable {
    using SortedList for SortedList.List;
    using StringUtils for string;

    uint256 public constant BASE = 10 ** 36;

    mapping(address => bool) public isSigner;
    mapping(address => string) public nameOfSigner;
    mapping(string => address) public signerWithName;

    SortedList.List private list;
    RateOracle public upgrade;
    PausedProvider public pausedProvider;

    string private isymbol;
    string private iname;
    uint256 private idecimals;
    address private itoken;
    bytes32 private icurrency;
    string private imaintainer;

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _decimals,
        address _token,
        string memory _maintainer
    ) public {
        // Create legacy bytes32 currency
        bytes32 currency = _symbol.toBytes32();
        // Save Oracle metadata
        isymbol = _symbol;
        iname = _name;
        idecimals = _decimals;
        itoken = _token;
        icurrency = currency;
        imaintainer = _maintainer;
        pausedProvider = PausedProvider(msg.sender);
    }

    function providedBy(address _signer) external view returns (uint256) {
        return list.get(uint256(_signer));
    }

    /**
     * @return metadata, 3 or 4 letter symbol of the currency provided by this oracle
     *   (ej: ARS)
     * @notice Defined by the RCN RateOracle interface
     */
    function symbol() external view returns (string memory) {
        return isymbol;
    }

    /**
     * @return metadata, full name of the currency provided by this oracle
     *   (ej: Argentine Peso)
     * @notice Defined by the RCN RateOracle interface
     */
    function name() external view returns (string memory) {
        return iname;
    }

    /**
     * @return metadata, decimals to express the common denomination
     *   of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function decimals() external view returns (uint256) {
        return idecimals;
    }

    /**
     * @return metadata, token address of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function token() external view returns (address) {
        return itoken;
    }

    /**
     * @return metadata, bytes32 code of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function currency() external view returns (bytes32) {
        return icurrency;
    }

    /**
     * @return metadata, human readable name of the entity maintainer of this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function maintainer() external view returns (string memory) {
        return imaintainer;
    }

    /**
     * @dev Returns the URL required to retrieve the auxiliary data
     *   as specified by the RateOracle spec, no auxiliary data is required
     *   so it returns an empty string.
     * @return An empty string, because the auxiliary data is not required
     * @notice Defined by the RCN RateOracle interface
     */
    function url() external view returns (string memory) {
        return "";
    }

    /**
     * @dev Updates the medatada of the oracle
     * @param _name Name of the oracle currency
     * @param _decimals Decimals for the common representation of the currency
     * @param _maintainer Name of the maintainer entity of the Oracle
     */
    function setMetadata(
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer
    ) external onlyOwner {
        iname = _name;
        idecimals = _decimals;
        imaintainer = _maintainer;
    }

    /**
     * @dev Updates the Oracle contract, all subsequent calls to `readSample` will be forwareded to `_upgrade`
     * @param _upgrade Contract address of the new updated oracle
     * @notice If the `upgrade` address is set to the address `0` the Oracle is considered not upgraded
     */
    function setUpgrade(RateOracle _upgrade) external onlyOwner {
        upgrade = _upgrade;
    }

    /**
     * @dev Adds a `_signer` who is going to be able to provide a new rate
     * @param _signer Address of the signer
     * @param _name Metadata - Human readable name of the signer
     */
    function addSigner(address _signer, string calldata _name) external onlyOwner {
        require(!isSigner[_signer], "signer already defined");
        require(signerWithName[_name] == address(0), "name already in use");
        require(bytes(_name).length > 0, "name can't be empty");
        isSigner[_signer] = true;
        signerWithName[_name] = _signer;
        nameOfSigner[_signer] = _name;
    }

    /**
     * @dev Updates the `_name` metadata of a given `_signer`
     * @param _signer Address of the signer
     * @param _name Metadata - Human readable name of the signer
     */
    function setName(address _signer, string calldata _name) external onlyOwner {
        require(isSigner[_signer], "signer not defined");
        require(signerWithName[_name] == address(0), "name already in use");
        require(bytes(_name).length > 0, "name can't be empty");
        string memory oldName = nameOfSigner[_signer];
        signerWithName[oldName] = address(0);
        signerWithName[_name] = _signer;
        nameOfSigner[_signer] = _name;
    }

    /**
     * @dev Removes an existing `_signer`, removing any provided rate
     * @param _signer Address of the signer
     */
    function removeSigner(address _signer) external onlyOwner {
        require(isSigner[_signer], "address is not a signer");
        string memory signerName = nameOfSigner[_signer];

        isSigner[_signer] = false;
        signerWithName[signerName] = address(0);
        nameOfSigner[_signer] = "";

        // Only remove from list if it provided a value
        if (list.exists[uint256(_signer)]) {
            list.remove(uint256(_signer));
        }
    }

    /**
     * @dev Provides a `_rate` for a given `_signer`
     * @param _signer Address of the signer who is providing the rate
     * @param _rate Rate to be provided
     * @notice This method can only be called by the Owner and not by the signer
     *   this is intended to allow the `OracleFactory.sol` to provide multiple rates
     *   on a single call. The `OracleFactory.sol` contract has the responsability of
     *   validating the signer address.
     */
    function provide(address _signer, uint256 _rate) external onlyOwner {
        require(isSigner[_signer], "signer not valid");
        require(_rate != 0, "rate can't be zero");
        list.set(uint256(_signer), _rate);
    }

    /**
     * @dev Reads the rate provided by the Oracle
     *   this being the median of the last rate provided by each signer
     * @param _oracleData Oracle auxiliar data defined in the RCN Oracle spec
     *   not used for this oracle, but forwarded in case of upgrade.
     * @return `_equivalent` is the median of the values provided by the signer
     *   `_tokens` are equivalent to `_equivalent` in the currency of the Oracle
     */
    function readSample(bytes memory _oracleData) public view returns (uint256 _tokens, uint256 _equivalent) {
        // Check if paused
        require(!paused && !pausedProvider.isPaused(), "contract paused");

        // Check if Oracle contract has been upgraded
        RateOracle _upgrade = upgrade;
        if (address(_upgrade) != address(0)) {
            return _upgrade.readSample(_oracleData);
        }

        // Tokens is always base
        _tokens = BASE;
        _equivalent = list.median();
    }

    /**
     * @dev Reads the rate provided by the Oracle
     *   this being the median of the last rate provided by each signer
     * @return `_equivalent` is the median of the values provided by the signer
     *   `_tokens` are equivalent to `_equivalent` in the currency of the Oracle
     * @notice This Oracle accepts reading the sample without auxiliary data
     */
    function readSample() external view returns (uint256 _tokens, uint256 _equivalent) {
        (_tokens, _equivalent) = readSample(new bytes(0));
    }
}

// File: contracts/OracleFactory.sol

pragma solidity ^0.5.12;







contract OracleFactory is Ownable, Pausable, PausedProvider {
    mapping(string => address) public symbolToOracle;
    mapping(address => string) public oracleToSymbol;

    event NewOracle(
        string _symbol,
        address _oracle,
        string _name,
        uint256 _decimals,
        address _token,
        string _maintainer
    );

    event Upgraded(
        address indexed _oracle,
        address _new
    );

    event AddSigner(
        address indexed _oracle,
        address _signer,
        string _name
    );

    event RemoveSigner(
        address indexed _oracle,
        address _signer
    );

    event UpdateSignerName(
        address indexed _oracle,
        address _signer,
        string _newName
    );

    event UpdatedMetadata(
        address indexed _oracle,
        string _name,
        uint256 _decimals,
        string _maintainer
    );

    event Provide(
        address indexed _oracle,
        address _signer,
        uint256 _rate
    );

    event OraclePaused(
        address indexed _oracle,
        address _pauser
    );

    event OracleStarted(
        address indexed _oracle
    );

    /**
     * @dev Creates a new Oracle contract for a given `_symbol`
     * @param _symbol metadata symbol for the currency of the oracle to create
     * @param _name metadata name for the currency of the oracle
     * @param _decimals metadata number of decimals to express the common denomination of the currency
     * @param _token metadata token address of the currency
     *   (if the currency has no token, it should be the address 0)
     * @param _maintainer metadata maintener human readable name
     * @notice Only one oracle by symbol can be created
     */
    function newOracle(
        string calldata _symbol,
        string calldata _name,
        uint256 _decimals,
        address _token,
        string calldata _maintainer
    ) external onlyOwner {
        // Check for duplicated oracles
        require(symbolToOracle[_symbol] == address(0), "Oracle already exists");
        // Create oracle contract
        MultiSourceOracle oracle = new MultiSourceOracle(
            _symbol,
            _name,
            _decimals,
            _token,
            _maintainer
        );
        // Sanity check new oracle
        assert(bytes(oracleToSymbol[address(oracle)]).length == 0);
        // Save Oracle in registry
        symbolToOracle[_symbol] = address(oracle);
        oracleToSymbol[address(oracle)] = _symbol;
        // Emit events
        emit NewOracle(
            _symbol,
            address(oracle),
            _name,
            _decimals,
            _token,
            _maintainer
        );
    }

    /**
     * @return true if the Oracle ecosystem is paused
     * @notice Used by PausedProvided and readed by the Oracles on each `readSample()`
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Adds a `_signer` to a given `_oracle`
     * @param _oracle Address of the oracle on which add the `_signer`
     * @param _signer Address of the signer to be added
     * @param _name Human readable metadata name of the `_signer`
     * @notice Acts as a proxy of `_oracle.addSigner`
     */
    function addSigner(address _oracle, address _signer, string calldata _name) external onlyOwner {
        MultiSourceOracle(_oracle).addSigner(_signer, _name);
        emit AddSigner(_oracle, _signer, _name);
    }

    /**
     * @dev Adds a `_signer` to multiple `_oracles`
     * @param _oracles List of oracles on which add the `_signer`
     * @param _signer Address of the signer to be added
     * @param _name Human readable metadata name of the `_signer`
     * @notice Acts as a proxy for all the `_oracles` `_oracle.addSigner`
     */
    function addSignerToOracles(
        address[] calldata _oracles,
        address _signer,
        string calldata _name
    ) external onlyOwner {
        for (uint256 i = 0; i < _oracles.length; i++) {
            address oracle = _oracles[i];
            MultiSourceOracle(oracle).addSigner(_signer, _name);
            emit AddSigner(oracle, _signer, _name);
        }
    }

    /**
     * @dev Updates the `_name` of a given `_signer`@`_oracle`
     * @param _oracle Address of the oracle on which the `_signer` it's found
     * @param _signer Address of the signer to be updated
     * @param _name Human readable metadata name of the `_signer`
     * @notice Acts as a proxy of `_oracle.setName`
     */
    function setName(address _oracle, address _signer, string calldata _name) external onlyOwner {
        MultiSourceOracle(_oracle).setName(_signer, _name);
        emit UpdateSignerName(
            _oracle,
            _signer,
            _name
        );
    }

    /**
     * @dev Removes a `_signer` to a given `_oracle`
     * @param _oracle Address of the oracle on which remove the `_signer`
     * @param _signer Address of the signer to be removed
     * @notice Acts as a proxy of `_oracle.removeSigner`
     */
    function removeSigner(address _oracle, address _signer) external onlyOwner {
        MultiSourceOracle(_oracle).removeSigner(_signer);
        emit RemoveSigner(_oracle, _signer);
    }


    /**
     * @dev Removes a `_signer` from multiple `_oracles`
     * @param _oracles List of oracles on which remove the `_signer`
     * @param _signer Address of the signer to be removed
     * @notice Acts as a proxy for all the `_oracles` `_oracle.removeSigner`
     */
    function removeSignerFromOracles(
        address[] calldata _oracles,
        address _signer
    ) external onlyOwner {
        for (uint256 i = 0; i < _oracles.length; i++) {
            address oracle = _oracles[i];
            MultiSourceOracle(oracle).removeSigner(_signer);
            emit RemoveSigner(oracle, _signer);
        }
    }

    /**
     * @dev Provides a `_rate` for a given `_oracle`, msg.sener becomes the `signer`
     * @param _oracle Address of the oracle on which provide the rate
     * @param _rate Rate to be provided
     * @notice Acts as a proxy of `_oracle.provide`, using the parameter `msg.sender` as signer
     */
    function provide(address _oracle, uint256 _rate) external {
        MultiSourceOracle(_oracle).provide(msg.sender, _rate);
        emit Provide(_oracle, msg.sender, _rate);
    }

    /**
     * @dev Provides multiple rates for a set of oracles, with the same signer
     *   msg.sender becomes the signer for all the provides
     *
     * @param _oracles List of oracles to provide a rate for
     * @param _rates List of rates to provide
     * @notice Acts as a proxy for multiples `_oracle.provide`, using the parameter `msg.sender` as signer
     */
    function provideMultiple(
        address[] calldata _oracles,
        uint256[] calldata _rates
    ) external {
        uint256 length = _oracles.length;
        require(length == _rates.length, "arrays should have the same size");

        for (uint256 i = 0; i < length; i++) {
            address oracle = _oracles[i];
            uint256 rate = _rates[i];
            MultiSourceOracle(oracle).provide(msg.sender, rate);
            emit Provide(oracle, msg.sender, rate);
        }
    }

    /**
     * @dev Updates the Oracle contract, all subsequent calls to `readSample` will be forwareded to `_upgrade`
     * @param _oracle oracle address to be upgraded
     * @param _upgrade contract address of the new updated oracle
     * @notice Acts as a proxy of `_oracle.setUpgrade`
     */
    function setUpgrade(address _oracle, address _upgrade) external onlyOwner {
        MultiSourceOracle(_oracle).setUpgrade(RateOracle(_upgrade));
        emit Upgraded(_oracle, _upgrade);
    }

    /**
     * @dev Pauses the given `_oracle`
     * @param _oracle oracle address to be paused
     * @notice Acts as a proxy of `_oracle.pause`
     */
    function pauseOracle(address _oracle) external {
        require(
            canPause[msg.sender] ||
            msg.sender == _owner,
            "not authorized to pause"
        );

        MultiSourceOracle(_oracle).pause();
        emit OraclePaused(_oracle, msg.sender);
    }

    /**
     * @dev Starts the given `_oracle`
     * @param _oracle oracle address to be started
     * @notice Acts as a proxy of `_oracle.start`
     */
    function startOracle(address _oracle) external onlyOwner {
        MultiSourceOracle(_oracle).start();
        emit OracleStarted(_oracle);
    }

    /**
     * @dev Updates the medatada of the oracle
     * @param _oracle oracle address to update its metadata
     * @param _name Name of the oracle currency
     * @param _decimals Decimals for the common representation of the currency
     * @param _maintainer Name of the maintainer entity of the Oracle
     * @notice Acts as a proxy of `_oracle.setMetadata`
     */
    function setMetadata(
        address _oracle,
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer
    ) external onlyOwner {
        MultiSourceOracle(_oracle).setMetadata(
            _name,
            _decimals,
            _maintainer
        );

        emit UpdatedMetadata(
            _oracle,
            _name,
            _decimals,
            _maintainer
        );
    }
}