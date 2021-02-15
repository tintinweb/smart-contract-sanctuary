pragma solidity 0.5.16;

import "./CosmosBankStorage.sol";
import "./EthereumBankStorage.sol";
import "./CosmosWhiteListStorage.sol";

contract BankStorage is 
    CosmosBankStorage,
    EthereumBankStorage,
    CosmosWhiteListStorage {

    /**
    * @notice operator address that can update the smart contract
    */
    address public operator;

    /**
    * @notice address of the Oracle smart contract
    */
    address public oracle;

    /**
    * @notice address of the Cosmos Bridge smart contract
    */
    address public cosmosBridge;

    /**
    * @notice owner address that can use the admin API
    */
    address public owner;

    mapping (string => uint256) public maxTokenAmount;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

import "./CosmosBank.sol";
import "./EthereumBank.sol";
import "./EthereumWhitelist.sol";
import "./CosmosWhiteList.sol";
import "../Oracle.sol";
import "../CosmosBridge.sol";
import "./BankStorage.sol";
import "./Pausable.sol";

/*
 * @title BridgeBank
 * @dev Bank contract which coordinates asset-related functionality.
 *      CosmosBank manages the minting and burning of tokens which
 *      represent Cosmos based assets, while EthereumBank manages
 *      the locking and unlocking of Ethereum and ERC20 token assets
 *      based on Ethereum. WhiteList records the ERC20 token address 
 *      list that can be locked.
 **/

contract BridgeBank is BankStorage,
    CosmosBank,
    EthereumBank,
    EthereumWhiteList,
    CosmosWhiteList,
    Pausable {

    bool private _initialized;

    using SafeMath for uint256;

    /*
     * @dev: Initializer, sets operator
     */
    function initialize(
        address _operatorAddress,
        address _cosmosBridgeAddress,
        address _owner,
        address _pauser
    ) public {
        require(!_initialized, "Init");

        EthereumWhiteList.initialize();
        CosmosWhiteList.initialize();
        Pausable.initialize(_pauser);

        operator = _operatorAddress;
        cosmosBridge = _cosmosBridgeAddress;
        owner = _owner;
        _initialized = true;

        // hardcode since this is the first token
        lowerToUpperTokens["erowan"] = "erowan";
        lowerToUpperTokens["eth"] = "eth";
    }

    /*
     * @dev: Modifier to restrict access to operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "!operator");
        _;
    }

    /*
     * @dev: Modifier to restrict access to operator
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    /*
     * @dev: Modifier to restrict access to the cosmos bridge
     */
    modifier onlyCosmosBridge() {
        require(
            msg.sender == cosmosBridge,
            "!cosmosbridge"
        );
        _;
    }

    /*
     * @dev: Modifier to only allow valid sif addresses
     */
    modifier validSifAddress(bytes memory _sifAddress) {
        require(_sifAddress.length == 42, "Invalid len");
        require(verifySifPrefix(_sifAddress) == true, "Invalid sif address");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "invalid address");
        owner = _newOwner;
    }

    function changeOperator(address _newOperator) public onlyOperator {
        require(_newOperator != address(0), "invalid address");
        operator = _newOperator;
    }

    /*
     * @dev: function to validate if a sif address has a correct prefix
     */
    function verifySifPrefix(bytes memory _sifAddress) public pure returns (bool) {
        bytes3 sifInHex = 0x736966;

        for (uint256 i = 0; i < sifInHex.length; i++) {
            if (sifInHex[i] != _sifAddress[i]) {
                return false;
            }
        }
        return true;
    }

    /*
     * @dev: Creates a new BridgeToken
     *
     * @param _symbol: The new BridgeToken's symbol
     * @return: The new BridgeToken contract's address
     */
    function createNewBridgeToken(string memory _symbol)
        public
        onlyCosmosBridge
        returns (address)
    {
        address newTokenAddress = deployNewBridgeToken(_symbol);
        setTokenInCosmosWhiteList(newTokenAddress, true);

        return newTokenAddress;
    }

    /*
     * @dev: Creates a new BridgeToken
     *
     * @param _symbol: The new BridgeToken's symbol
     * @return: The new BridgeToken contract's address
     */
    function addExistingBridgeToken(
        address _contractAddress
    ) public onlyOwner returns (address) {
        setTokenInCosmosWhiteList(_contractAddress, true);

        return useExistingBridgeToken(_contractAddress);
    }

    /*
     * @dev: Set the token address in whitelist
     *
     * @param _token: ERC 20's address
     * @param _inList: set the _token in list or not
     * @return: new value of if _token in whitelist
     */
    function updateEthWhiteList(address _token, bool _inList)
        public
        onlyOperator
        returns (bool)
    {
        string memory symbol = BridgeToken(_token).symbol();
        address listAddress = lockedTokenList[symbol];
        
        // Do not allow a token with the same symbol to be whitelisted
        if (_inList) {
            // if we want to add it to the whitelist, make sure that the address
            // is 0, meaning we have not seen that symbol in the whitelist before
            require(listAddress == address(0), "whitelisted");
        } else {
            // if we want to de-whitelist it, make sure that the symbol is 
            // in fact stored in our locked token list before we set to false
            require(uint256(listAddress) > 0, "!whitelisted");
        }
        lowerToUpperTokens[toLower(symbol)] = symbol;
        return setTokenInEthWhiteList(_token, _inList);
    }

    // Method that is only for doing the setting of the mapping
    // private so that it is not inheritable or able to be called
    // by anyone other than this contract
    function _updateTokenLimits(address _token, uint256 _amount) private {
        string memory symbol = _token == address(0) ? "eth" : BridgeToken(_token).symbol();
        maxTokenAmount[symbol] = _amount;
    }

    function updateTokenLockBurnLimit(address _token, uint256 _amount)
        public
        onlyOperator
        returns (bool)
    {
        _updateTokenLimits(_token, _amount);
        return true;
    }

    function bulkWhitelistUpdateLimits(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenLimit
        ) external
        onlyOperator
        returns (bool)
    {
        require(tokenAddresses.length == tokenLimit.length, "!same length");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _updateTokenLimits(tokenAddresses[i], tokenLimit[i]);
            setTokenInEthWhiteList(tokenAddresses[i], true);
            string memory symbol = BridgeToken(tokenAddresses[i]).symbol();
            lowerToUpperTokens[toLower(symbol)] = symbol;
        }
        return true;
    }

    /*
     * @dev: Mints new BankTokens
     *
     * @param _cosmosSender: The sender's Cosmos address in bytes.
     * @param _ethereumRecipient: The intended recipient's Ethereum address.
     * @param _cosmosTokenAddress: The currency type
     * @param _symbol: comsos token symbol
     * @param _amount: number of comsos tokens to be minted
     */
    function mintBridgeTokens(
        address payable _intendedRecipient,
        address _bridgeTokenAddress,
        string memory _symbol,
        uint256 _amount
    ) public onlyCosmosBridge whenNotPaused {
        return
            mintNewBridgeTokens(
                _intendedRecipient,
                _bridgeTokenAddress,
                _symbol,
                _amount
            );
    }

    /*
     * @dev: Burns BridgeTokens representing native Cosmos assets.
     *
     * @param _recipient: bytes representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function burn(
        bytes memory _recipient,
        address _token,
        uint256 _amount
    ) public validSifAddress(_recipient) onlyCosmosTokenWhiteList(_token) whenNotPaused {
        string memory symbol = BridgeToken(_token).symbol();

        if (_amount > maxTokenAmount[symbol]) {
            revert("Amount being transferred is over the limit for this token");
        }

        BridgeToken(_token).burnFrom(msg.sender, _amount);
        burnFunds(msg.sender, _recipient, _token, symbol, _amount);
    }

    /*
     * @dev: Locks received Ethereum/ERC20 funds.
     *
     * @param _recipient: bytes representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function lock(
        bytes memory _recipient,
        address _token,
        uint256 _amount
    ) public payable onlyEthTokenWhiteList(_token) validSifAddress(_recipient) whenNotPaused {
        string memory symbol;

        // Ethereum deposit
        if (msg.value > 0) {
            require(
                _token == address(0),
                "!address(0)"
            );
            require(
                msg.value == _amount,
                "incorrect eth amount"
            );
            symbol = "eth";
            // ERC20 deposit
        } else {
            IERC20 tokenToTransfer = IERC20(_token);
            tokenToTransfer.safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
            symbol = BridgeToken(_token).symbol();
        }

        if (_amount > maxTokenAmount[symbol]) {
            revert("Amount being transferred is over the limit");
        }
        lockFunds(msg.sender, _recipient, _token, symbol, _amount);
    }

    /*
     * @dev: Unlocks Ethereum and ERC20 tokens held on the contract.
     *
     * @param _recipient: recipient's Ethereum address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function unlock(
        address payable _recipient,
        string memory _symbol,
        uint256 _amount
    ) public onlyCosmosBridge whenNotPaused {
        // Confirm that the bank has sufficient locked balances of this token type
        require(
            getLockedFunds(_symbol) >= _amount,
            "!Bank funds"
        );

        // Confirm that the bank holds sufficient balances to complete the unlock
        address tokenAddress = lockedTokenList[_symbol];
        if (tokenAddress == address(0)) {
            require(
                ((address(this)).balance) >= _amount,
                "Insufficient ethereum balance for delivery."
            );
        } else {
            require(
                BridgeToken(tokenAddress).balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 token balance for delivery."
            );
        }
        unlockFunds(_recipient, tokenAddress, _symbol, _amount);
    }

    /*
    * @dev fallback function for ERC223 tokens so that we can receive these tokens in our contract
    * Don't need to do anything to handle these tokens
    */
    function tokenFallback(address _from, uint _value, bytes memory _data) public {}
}

pragma solidity 0.5.16;

import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


/**
 * @title BridgeToken
 * @dev Mintable, ERC20Burnable, ERC20 compatible BankToken for use by BridgeBank
 **/

contract BridgeToken is ERC20Mintable, ERC20Burnable, ERC20Detailed {
    constructor(string memory _symbol)
        public
        ERC20Detailed(_symbol, _symbol, 18)
    {
        // Intentionally left blank
    }
}

pragma solidity 0.5.16;

import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./BridgeToken.sol";
import "./CosmosBankStorage.sol";
import "./ToLower.sol";

/**
 * @title CosmosBank
 * @dev Manages the deployment and minting of ERC20 compatible BridgeTokens
 *      which represent assets based on the Cosmos blockchain.
 **/

contract CosmosBank is CosmosBankStorage, ToLower {
    using SafeMath for uint256;

    /*
     * @dev: Event declarations
     */
    event LogNewBridgeToken(address _token, string _symbol);

    event LogBridgeTokenMint(
        address _token,
        string _symbol,
        uint256 _amount,
        address _beneficiary
    );

    /*
     * @dev: Get a token symbol's corresponding bridge token address.
     *
     * @param _symbol: The token's symbol/denom without 'e' prefix.
     * @return: Address associated with the given symbol. Returns address(0) if none is found.
     */
    function getBridgeToken(string memory _symbol)
        public
        view
        returns (address)
    {
        return (controlledBridgeTokens[_symbol]);
    }

    function safeLowerToUpperTokens(string memory _symbol)
        public
        view
        returns (string memory)
    {
        string memory retrievedSymbol = lowerToUpperTokens[_symbol];
        return keccak256(abi.encodePacked(retrievedSymbol)) == keccak256("") ? _symbol : retrievedSymbol;
    }

    /*
     * @dev: Deploys a new BridgeToken contract
     *
     * @param _symbol: The BridgeToken's symbol
     */
    function deployNewBridgeToken(string memory _symbol)
        internal
        returns (address)
    {
        bridgeTokenCount = bridgeTokenCount.add(1);

        // Deploy new bridge token contract
        BridgeToken newBridgeToken = (new BridgeToken)(_symbol);

        // Set address in tokens mapping
        address newBridgeTokenAddress = address(newBridgeToken);
        controlledBridgeTokens[_symbol] = newBridgeTokenAddress;
        lowerToUpperTokens[toLower(_symbol)] = _symbol;

        emit LogNewBridgeToken(newBridgeTokenAddress, _symbol);
        return newBridgeTokenAddress;
    }

    /*
     * @dev: Deploys a new BridgeToken contract
     *
     * @param _symbol: The BridgeToken's symbol
     *
     * @note the Rowan token symbol needs to be "Rowan" so that it integrates correctly with the cosmos bridge 
     */
    function useExistingBridgeToken(address _contractAddress)
        internal
        returns (address)
    {
        bridgeTokenCount = bridgeTokenCount.add(1);

        string memory _symbol = BridgeToken(_contractAddress).symbol();
        // Set address in tokens mapping
        address newBridgeTokenAddress = _contractAddress;
        controlledBridgeTokens[_symbol] = newBridgeTokenAddress;
        lowerToUpperTokens[toLower(_symbol)] = _symbol;

        emit LogNewBridgeToken(newBridgeTokenAddress, _symbol);
        return newBridgeTokenAddress;
    }

    /*
     * @dev: Mints new cosmos tokens
     *
     * @param _cosmosSender: The sender's Cosmos address in bytes.
     * @param _ethereumRecipient: The intended recipient's Ethereum address.
     * @param _cosmosTokenAddress: The currency type
     * @param _symbol: comsos token symbol
     * @param _amount: number of comsos tokens to be minted
     */
    function mintNewBridgeTokens(
        address payable _intendedRecipient,
        address _bridgeTokenAddress,
        string memory _symbol,
        uint256 _amount
    ) internal {
        require(
            controlledBridgeTokens[_symbol] == _bridgeTokenAddress,
            "Token must be a controlled bridge token"
        );

        // Mint bridge tokens
        require(
            BridgeToken(_bridgeTokenAddress).mint(_intendedRecipient, _amount),
            "Attempted mint of bridge tokens failed"
        );

        emit LogBridgeTokenMint(
            _bridgeTokenAddress,
            _symbol,
            _amount,
            _intendedRecipient
        );
    }
}

pragma solidity 0.5.16;

contract CosmosBankStorage {

    /**
    * @notice Cosmos deposit struct
    */
    struct CosmosDeposit {
        bytes cosmosSender;
        address payable ethereumRecipient;
        address bridgeTokenAddress;
        uint256 amount;
        bool locked;
    }

    /**
    * @notice number of bridge tokens
    */
    uint256 public bridgeTokenCount;

    /**
    * @notice cosmos deposit nonce
    */
    uint256 public cosmosDepositNonce;
    
    /**
    * @notice mapping of symbols to token addresses
    */
    mapping(string => address) controlledBridgeTokens;
    
    /**
    * @notice mapping of lowercase symbols to properly capitalized tokens
    */
    mapping(string => string) public lowerToUpperTokens;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

import "./CosmosWhiteListStorage.sol";

/**
 * @title WhiteList
 * @dev WhiteList contract records the ERC 20 list that can be locked in BridgeBank.
 **/

contract CosmosWhiteList is CosmosWhiteListStorage {
    bool private _initialized;

    /*
     * @dev: Event declarations
     */
    event LogWhiteListUpdate(address _token, bool _value);

    function initialize() public {
        require(!_initialized, "Initialized");
        _cosmosTokenWhiteList[address(0)] = true;
        _initialized = true;
    }

    /*
     * @dev: Modifier to restrict erc20 can be locked
     */
    modifier onlyCosmosTokenWhiteList(address _token) {
        require(
            getCosmosTokenInWhiteList(_token),
            "Only token in whitelist can be transferred to cosmos"
        );
        _;
    }

    /*
     * @dev: Set the token address in whitelist
     *
     * @param _token: ERC 20's address
     * @param _inList: set the _token in list or not
     * @return: new value of if _token in whitelist
     */
    function setTokenInCosmosWhiteList(address _token, bool _inList)
        internal
        returns (bool)
    {
        _cosmosTokenWhiteList[_token] = _inList;
        emit LogWhiteListUpdate(_token, _inList);
        return _inList;
    }

    /*
     * @dev: Get if the token in whitelist
     *
     * @param _token: ERC 20's address
     * @return: if _token in whitelist
     */
    function getCosmosTokenInWhiteList(address _token) public view returns (bool) {
        return _cosmosTokenWhiteList[_token];
    }
}

pragma solidity 0.5.16;

contract CosmosWhiteListStorage {

    /**
    * @notice mapping to keep track of whitelisted tokens
    */
    mapping(address => bool) internal _cosmosTokenWhiteList;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

import "./BridgeToken.sol";
import "./EthereumBankStorage.sol";
import "../../node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
/*
 *  @title: EthereumBank
 *  @dev: Ethereum bank which locks Ethereum/ERC20 token deposits, and unlocks
 *        Ethereum/ERC20 tokens once the prophecy has been successfully processed.
 */
contract EthereumBank is EthereumBankStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /*
     * @dev: Event declarations
     */
    event LogBurn(
        address _from,
        bytes _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce
    );

    event LogLock(
        address _from,
        bytes _to,
        address _token,
        string _symbol,
        uint256 _value,
        uint256 _nonce
    );

    event LogUnlock(
        address _to,
        address _token,
        string _symbol,
        uint256 _value
    );

    /*
     * @dev: Gets the contract address of locked tokens by symbol.
     *
     * @param _symbol: The asset's symbol.
     */
    function getLockedTokenAddress(string memory _symbol)
        public
        view
        returns (address)
    {
        return lockedTokenList[_symbol];
    }

    /*
     * @dev: Gets the amount of locked tokens by symbol.
     *
     * @param _symbol: The asset's symbol.
     */
    function getLockedFunds(string memory _symbol)
        public
        view
        returns (uint256)
    {
        return lockedFunds[lockedTokenList[_symbol]];
    }

    /*
     * @dev: Creates a new Ethereum deposit with a unique id.
     *
     * @param _sender: The sender's ethereum address.
     * @param _recipient: The intended recipient's cosmos address.
     * @param _token: The currency type, either erc20 or ethereum.
     * @param _amount: The amount of erc20 tokens/ ethereum (in wei) to be itemized.
     */
    function burnFunds(
        address payable _sender,
        bytes memory _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount
    ) internal {
        lockBurnNonce = lockBurnNonce.add(1);
        emit LogBurn(_sender, _recipient, _token, _symbol, _amount, lockBurnNonce);
    }

    /*
     * @dev: Creates a new Ethereum deposit with a unique id.
     *
     * @param _sender: The sender's ethereum address.
     * @param _recipient: The intended recipient's cosmos address.
     * @param _token: The currency type, either erc20 or ethereum.
     * @param _amount: The amount of erc20 tokens/ ethereum (in wei) to be itemized.
     */
    function lockFunds(
        address payable _sender,
        bytes memory _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount
    ) internal {
        lockBurnNonce = lockBurnNonce.add(1);

        // Increment locked funds by the amount of tokens to be locked
        lockedTokenList[_symbol] = _token;
        lockedFunds[_token] = lockedFunds[_token].add(_amount);

        emit LogLock(_sender, _recipient, _token, _symbol, _amount, lockBurnNonce);
    }

    /*
     * @dev: Unlocks funds held on contract and sends them to the
     *       intended recipient
     *
     * @param _recipient: recipient's Ethereum address
     * @param _token: token contract address
     * @param _symbol: token symbol
     * @param _amount: wei amount or ERC20 token count
     */
    function unlockFunds(
        address payable _recipient,
        address _token,
        string memory _symbol,
        uint256 _amount
    ) internal {
        // Decrement locked funds mapping by the amount of tokens to be unlocked
        lockedFunds[_token] = lockedFunds[_token].sub(_amount);

        // Transfer funds to intended recipient
        if (_token == address(0)) {
            (bool success,) = _recipient.call.value(_amount)("");
            require(success, "error sending ether");
        } else {
            IERC20 tokenToTransfer = IERC20(_token);
            tokenToTransfer.safeTransfer(_recipient, _amount);
        }

        emit LogUnlock(_recipient, _token, _symbol, _amount);
    }
}

pragma solidity 0.5.16;

contract EthereumBankStorage {

    /**
    * @notice current lock and or burn nonce
    */
    uint256 public lockBurnNonce;

    /**
    * @notice how much funds we have stored of a certain token
    */
    mapping(address => uint256) public lockedFunds;

    /**
    * @notice map the token symbol to the token address
    */
    mapping(string => address) public lockedTokenList;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

/**
 * @title WhiteList
 * @dev WhiteList contract records the ERC 20 list that can be locked in BridgeBank.
 **/

contract EthereumWhiteList {
    bool private _initialized;

    /**
    * @notice mapping to keep track of whitelisted tokens
    */
    mapping(address => bool) private _ethereumTokenWhiteList;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
    /*
     * @dev: Event declarations
     */
    event LogWhiteListUpdate(address _token, bool _value);

    function initialize() public {
        require(!_initialized, "Initialized");
        _ethereumTokenWhiteList[address(0)] = true;
        _initialized = true;
    }

    /*
     * @dev: Modifier to restrict erc20 can be locked
     */
    modifier onlyEthTokenWhiteList(address _token) {
        require(
            getTokenInEthWhiteList(_token),
            "Only token in whitelist can be transferred to cosmos"
        );
        _;
    }

    /*
     * @dev: Set the token address in whitelist
     *
     * @param _token: ERC 20's address
     * @param _inList: set the _token in list or not
     * @return: new value of if _token in whitelist
     */
    function setTokenInEthWhiteList(address _token, bool _inList)
        internal
        returns (bool)
    {
        _ethereumTokenWhiteList[_token] = _inList;
        emit LogWhiteListUpdate(_token, _inList);
        return _inList;
    }

    /*
     * @dev: Get if the token in whitelist
     *
     * @param _token: ERC 20's address
     * @return: if _token in whitelist
     */
    function getTokenInEthWhiteList(address _token) public view returns (bool) {
        return _ethereumTokenWhiteList[_token];
    }
}

pragma solidity 0.5.16;

import "./PauserRole.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;


    function initialize (address _user) internal {
        _addPauser(_user);
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a owner to toggle pause
     */
    function togglePause() private {
        _paused = !_paused;
    }

    /**
     * @dev Called by a pauser to pause contract
     */
    function pause() external onlyPauser whenNotPaused {
        togglePause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause contract
     */
    function unpause() external onlyPauser whenPaused {
        togglePause();
        emit Unpaused(msg.sender);
    }
}

pragma solidity 0.5.16;

contract PauserRole {

    mapping (address => bool) public pausers;

    modifier onlyPauser() {
        require(pausers[msg.sender], "PauserRole: caller does not have the Pauser role");
        _;
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        pausers[account] = true;
    }

    function _removePauser(address account) internal {
        pausers[account] = false;
    }
}

pragma solidity 0.5.16;

contract ToLower {

    function toLower(string memory str) public pure returns (string memory) {
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			// Uppercase character...
			if ((bStr[i] >= bytes1(uint8(65))) && (bStr[i] <= bytes1(uint8(90)))) {
				// So we add 32 to make it lowercase
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
}

pragma solidity 0.5.16;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Valset.sol";
import "./Oracle.sol";
import "./BridgeBank/BridgeBank.sol";
import "./CosmosBridgeStorage.sol";


contract CosmosBridge is CosmosBridgeStorage, Oracle {
    using SafeMath for uint256;
    
    bool private _initialized;
    uint256[100] private ___gap;

    /*
     * @dev: Event declarations
     */

    event LogOracleSet(address _oracle);

    event LogBridgeBankSet(address _bridgeBank);

    event LogNewProphecyClaim(
        uint256 _prophecyID,
        ClaimType _claimType,
        address payable _ethereumReceiver,
        string _symbol,
        uint256 _amount
    );

    event LogProphecyCompleted(uint256 _prophecyID, ClaimType _claimType);

    /*
     * @dev: Modifier to restrict access to the operator.
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be the operator.");
        _;
    }

    /*
     * @dev: Modifier to restrict access to current ValSet validators
     */
    modifier onlyValidator() {
        require(
            isActiveValidator(msg.sender),
            "Must be an active validator"
        );
        _;
    }

    /*
     * @dev: Constructor
     */
    function initialize(
        address _operator,
        uint256 _consensusThreshold,
        address[] memory _initValidators,
        uint256[] memory _initPowers
    ) public {
        require(!_initialized, "Initialized");

        COSMOS_NATIVE_ASSET_PREFIX = "e";
        operator = _operator;
        hasBridgeBank = false;
        _initialized = true;
        Oracle._initialize(
            _operator,
            _consensusThreshold,
            _initValidators,
            _initPowers
        );
    }

    function changeOperator(address _newOperator) public onlyOperator {
        require(_newOperator != address(0), "invalid address");
        operator = _newOperator;
    }

    /*
     * @dev: setBridgeBank
     */
    function setBridgeBank(address payable _bridgeBank) public onlyOperator {
        require(
            !hasBridgeBank,
            "The Bridge Bank cannot be updated once it has been set"
        );

        hasBridgeBank = true;
        bridgeBank = _bridgeBank;

        emit LogBridgeBankSet(bridgeBank);
    }

    function getProphecyID(
        ClaimType _claimType,
        bytes calldata _cosmosSender,
        uint256 _cosmosSenderSequence,
        address payable _ethereumReceiver,
        string calldata _symbol,
        uint256 _amount
    ) external pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_claimType, _cosmosSender, _cosmosSenderSequence, _ethereumReceiver, _symbol, _amount)));
    }

    /*
     * @dev: newProphecyClaim
     *       Creates a new burn or lock prophecy claim, adding it to the prophecyClaims mapping.
     *       Burn claims require that there are enough locked Ethereum assets to complete the prophecy.
     *       Lock claims have a new token contract deployed or use an existing contract based on symbol.
     */
    function newProphecyClaim(
        ClaimType _claimType,
        bytes memory _cosmosSender,
        uint256 _cosmosSenderSequence,
        address payable _ethereumReceiver,
        string memory _symbol,
        uint256 _amount
    ) public onlyValidator {
        uint256 _prophecyID = uint256(keccak256(abi.encodePacked(_claimType, _cosmosSender, _cosmosSenderSequence, _ethereumReceiver, _symbol, _amount)));
        (bool prophecyCompleted, , ) = getProphecyThreshold(_prophecyID);
        require(!prophecyCompleted, "prophecyCompleted");

        if (oracleClaimValidators[_prophecyID] == 0) {
            string memory symbol;
            if (_claimType == ClaimType.Burn) {
                symbol = BridgeBank(bridgeBank).safeLowerToUpperTokens(_symbol);
                require(
                    BridgeBank(bridgeBank).getLockedFunds(symbol) >= _amount,
                    "Not enough locked assets to complete the proposed prophecy"
                );
                address tokenAddress = BridgeBank(bridgeBank).getLockedTokenAddress(symbol);
                if (tokenAddress == address(0) && uint256(keccak256(abi.encodePacked(symbol))) != uint256(keccak256("eth"))) {
                    revert("Invalid token address");
                }
            } else if (_claimType == ClaimType.Lock) {
                symbol = concat(COSMOS_NATIVE_ASSET_PREFIX, _symbol); // Add 'e' symbol prefix
                symbol = BridgeBank(bridgeBank).safeLowerToUpperTokens(symbol);
                address bridgeTokenAddress = BridgeBank(bridgeBank).getBridgeToken(symbol);
                if (bridgeTokenAddress == address(0)) {
                    // First lock of this asset, deploy new contract and get new symbol/token address
                    BridgeBank(bridgeBank).createNewBridgeToken(symbol);
                }
            } else {
                revert("Invalid claim type, only burn and lock are supported.");
            }

            emit LogNewProphecyClaim(
                _prophecyID,
                _claimType,
                _ethereumReceiver,
                symbol,
                _amount
            );
        }

        bool claimComplete = newOracleClaim(_prophecyID, msg.sender);

        if (claimComplete) {
            address tokenAddress;
            if (_claimType == ClaimType.Lock) {
                _symbol = concat(COSMOS_NATIVE_ASSET_PREFIX, _symbol);
                _symbol = BridgeBank(bridgeBank).safeLowerToUpperTokens(_symbol);
                tokenAddress = BridgeBank(bridgeBank).getBridgeToken(_symbol);
            } else {
                _symbol = BridgeBank(bridgeBank).safeLowerToUpperTokens(_symbol);
                tokenAddress = BridgeBank(bridgeBank).getLockedTokenAddress(_symbol);
            }
            completeProphecyClaim(
                _prophecyID,
                tokenAddress,
                _claimType,
                _ethereumReceiver,
                _symbol,
                _amount
            );
        }
    }

    /*
     * @dev: completeProphecyClaim
     *       Allows for the completion of ProphecyClaims once processed by the Oracle.
     *       Burn claims unlock tokens stored by BridgeBank.
     *       Lock claims mint BridgeTokens on BridgeBank's token whitelist.
     */
    function completeProphecyClaim(
        uint256 _prophecyID,
        address tokenAddress,
        ClaimType claimType,
        address payable ethereumReceiver,
        string memory symbol,
        uint256 amount
    ) internal {

        if (claimType == ClaimType.Burn) {
            unlockTokens(ethereumReceiver, symbol, amount);
        } else {
            issueBridgeTokens(ethereumReceiver, tokenAddress, symbol, amount);
        }

        emit LogProphecyCompleted(_prophecyID, claimType);
    }

    /*
     * @dev: issueBridgeTokens
     *       Issues a request for the BridgeBank to mint new BridgeTokens
     */
    function issueBridgeTokens(
        address payable ethereumReceiver,
        address tokenAddress,
        string memory symbol,
        uint256 amount
    ) internal {
        BridgeBank(bridgeBank).mintBridgeTokens(
            ethereumReceiver,
            tokenAddress,
            symbol,
            amount
        );
    }

    /*
     * @dev: unlockTokens
     *       Issues a request for the BridgeBank to unlock funds held on contract
     */
    function unlockTokens(
        address payable ethereumReceiver,
        string memory symbol,
        uint256 amount
    ) internal {
        BridgeBank(bridgeBank).unlock(
            ethereumReceiver,
            symbol,
            amount
        );
    }

    /*
     * @dev: Performs low gas-comsuption string concatenation
     *
     * @param _prefix: start of the string
     * @param _suffix: end of the string
     */
    function concat(string memory _prefix, string memory _suffix)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_prefix, _suffix));
    }
}

pragma solidity 0.5.16;

import "./BridgeBank/CosmosBankStorage.sol";
import "./BridgeBank/EthereumBankStorage.sol";

contract CosmosBridgeStorage {
    /**
    * @notice gap of storage for future upgrades
    */
    string COSMOS_NATIVE_ASSET_PREFIX;

    /*
     * @dev: Public variable declarations
     */
    address public operator;
    
    /**
    * @notice gap of storage for future upgrades
    */
    address payable public valset;
    
    /**
    * @notice gap of storage for future upgrades
    */
    address payable public oracle;
    
    /**
    * @notice gap of storage for future upgrades
    */
    address payable public bridgeBank;
    
    /**
    * @notice gap of storage for future upgrades
    */
    bool public hasBridgeBank;

    /**
    * @notice gap of storage for future upgrades
    */
    mapping(uint256 => ProphecyClaim) public prophecyClaims;

    /**
    * @notice prophecy status enum
    */
    enum Status {Null, Pending, Success, Failed}

    /**
    * @notice claim type enum
    */
    enum ClaimType {Unsupported, Burn, Lock}

    /**
    * @notice Prophecy claim struct
    */
    struct ProphecyClaim {
        address payable ethereumReceiver;
        string symbol;
        uint256 amount;
    }

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Valset.sol";
import "./OracleStorage.sol";
import "./Valset.sol";


contract Oracle is OracleStorage, Valset {
    using SafeMath for uint256;

    bool private _initialized;

    /*
     * @dev: Event declarations
     */
    event LogNewOracleClaim(
        uint256 _prophecyID,
        address _validatorAddress
    );

    event LogProphecyProcessed(
        uint256 _prophecyID,
        uint256 _prophecyPowerCurrent,
        uint256 _prophecyPowerThreshold,
        address _submitter
    );

    /*
     * @dev: Modifier to restrict access to the operator.
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be the operator.");
        _;
    }

    /*
     * @dev: Initialize Function
     */
    function _initialize(
        address _operator,
        uint256 _consensusThreshold,
        address[] memory _initValidators,
        uint256[] memory _initPowers
    ) internal {
        require(!_initialized, "Initialized");
        require(
            _consensusThreshold > 0,
            "Consensus threshold must be positive."
        );
        require(
            _consensusThreshold <= 100,
            "Invalid consensus threshold."
        );
        operator = _operator;
        consensusThreshold = _consensusThreshold;
        _initialized = true;

        Valset._initialize(_operator, _initValidators, _initPowers);
    }

    /*
     * @dev: newOracleClaim
     *       Allows validators to make new OracleClaims on an existing Prophecy
     */
    function newOracleClaim(
        uint256 _prophecyID,
        address validatorAddress
    ) internal
        returns (bool)
    {
        // Confirm that this address has not already made an oracle claim on this prophecy
        require(
            !hasMadeClaim[_prophecyID][validatorAddress],
            "Cannot make duplicate oracle claims from the same address."
        );

        hasMadeClaim[_prophecyID][validatorAddress] = true;
        // oracleClaimValidators[_prophecyID].push(validatorAddress);
        oracleClaimValidators[_prophecyID] = oracleClaimValidators[_prophecyID].add(
            this.getValidatorPower(validatorAddress)
        );
        emit LogNewOracleClaim(
            _prophecyID,
            validatorAddress
        );

        // Process the prophecy
        (bool valid, , ) = getProphecyThreshold(_prophecyID);

        return valid;
    }

    /*
     * @dev: processProphecy
     *       Calculates the status of a prophecy. The claim is considered valid if the
     *       combined active signatory validator powers pass the consensus threshold.
     *       The threshold is x% of Total power, where x is the consensusThreshold param.
     */
    function getProphecyThreshold(uint256 _prophecyID)
        public
        view
        returns (bool, uint256, uint256)
    {
        uint256 signedPower = 0;
        uint256 totalPower = totalPower;

        signedPower = oracleClaimValidators[_prophecyID];

        // Prophecy must reach total signed power % threshold in order to pass consensus
        uint256 prophecyPowerThreshold = totalPower.mul(consensusThreshold);
        // consensusThreshold is a decimal multiplied by 100, so signedPower must also be multiplied by 100
        uint256 prophecyPowerCurrent = signedPower.mul(100);
        bool hasReachedThreshold = prophecyPowerCurrent >=
            prophecyPowerThreshold;

        return (
            hasReachedThreshold,
            prophecyPowerCurrent,
            prophecyPowerThreshold
        );
    }
}

pragma solidity 0.5.16;

contract OracleStorage {
    /*
     * @dev: Public variable declarations
     */
    address public cosmosBridge;

    /**
    * @notice Tracks the number of OracleClaims made on an individual BridgeClaim
    */
    address public operator;

    /**
    * @notice Tracks the number of OracleClaims made on an individual BridgeClaim
    */
    uint256 public consensusThreshold; // e.g. 75 = 75%

    /**
    * @notice Tracks the number of OracleClaims made on an individual BridgeClaim
    */
    mapping(uint256 => uint256) public oracleClaimValidators;

    /**
    * @notice mapping of prophecyid to validator address to boolean
    */
    mapping(uint256 => mapping(address => bool)) public hasMadeClaim;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity 0.5.16;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ValsetStorage.sol";

contract Valset is ValsetStorage {
    using SafeMath for uint256;

    bool private _initialized;

    /*
     * @dev: Event declarations
     */
    event LogValidatorAdded(
        address _validator,
        uint256 _power,
        uint256 _currentValsetVersion,
        uint256 _validatorCount,
        uint256 _totalPower
    );

    event LogValidatorPowerUpdated(
        address _validator,
        uint256 _power,
        uint256 _currentValsetVersion,
        uint256 _validatorCount,
        uint256 _totalPower
    );

    event LogValidatorRemoved(
        address _validator,
        uint256 _power,
        uint256 _currentValsetVersion,
        uint256 _validatorCount,
        uint256 _totalPower
    );

    event LogValsetReset(
        uint256 _newValsetVersion,
        uint256 _validatorCount,
        uint256 _totalPower
    );

    event LogValsetUpdated(
        uint256 _newValsetVersion,
        uint256 _validatorCount,
        uint256 _totalPower
    );

    /*
     * @dev: Modifier which restricts access to the operator.
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be the operator.");
        _;
    }

    /*
     * @dev: Constructor
     */
    function _initialize(
        address _operator,
        address[] memory _initValidators,
        uint256[] memory _initPowers
    ) internal {
        require(!_initialized, "Initialized");

        operator = _operator;
        currentValsetVersion = 0;
        _initialized = true;

        updateValset(_initValidators, _initPowers);
    }

    /*
     * @dev: addValidator
     */
    function addValidator(address _validatorAddress, uint256 _validatorPower)
        public
        onlyOperator
    {
        addValidatorInternal(_validatorAddress, _validatorPower);
    }

    /*
     * @dev: updateValidatorPower
     */
    function updateValidatorPower(
        address _validatorAddress,
        uint256 _newValidatorPower
    ) public onlyOperator {

        require(
            validators[_validatorAddress][currentValsetVersion],
            "Can only update the power of active valdiators"
        );

        // Adjust total power by new validator power
        uint256 priorPower = powers[_validatorAddress][currentValsetVersion];
        totalPower = totalPower.sub(priorPower);
        totalPower = totalPower.add(_newValidatorPower);

        // Set validator's new power
        powers[_validatorAddress][currentValsetVersion] = _newValidatorPower;

        emit LogValidatorPowerUpdated(
            _validatorAddress,
            _newValidatorPower,
            currentValsetVersion,
            validatorCount,
            totalPower
        );
    }

    /*
     * @dev: removeValidator
     */
    function removeValidator(address _validatorAddress) public onlyOperator {
        require(validators[_validatorAddress][currentValsetVersion], "Can only remove active validators");

        // Update validator count and total power
        validatorCount = validatorCount.sub(1);
        totalPower = totalPower.sub(powers[_validatorAddress][currentValsetVersion]);

        // Delete validator and power
        delete validators[_validatorAddress][currentValsetVersion];
        delete powers[_validatorAddress][currentValsetVersion];

        emit LogValidatorRemoved(
            _validatorAddress,
            0,
            currentValsetVersion,
            validatorCount,
            totalPower
        );
    }

    /*
     * @dev: updateValset
     */
    function updateValset(
        address[] memory _validators,
        uint256[] memory _powers
    ) public onlyOperator {
        require(
            _validators.length == _powers.length,
            "Every validator must have a corresponding power"
        );

        resetValset();

        for (uint256 i = 0; i < _validators.length; i = i.add(1)) {
            addValidatorInternal(_validators[i], _powers[i]);
        }

        emit LogValsetUpdated(currentValsetVersion, validatorCount, totalPower);
    }

    /*
     * @dev: isActiveValidator
     */
    function isActiveValidator(address _validatorAddress)
        public
        view
        returns (bool)
    {
        // Return bool indicating if this address is an active validator
        return validators[_validatorAddress][currentValsetVersion];
    }

    /*
     * @dev: getValidatorPower
     */
    function getValidatorPower(address _validatorAddress)
        external
        view
        returns (uint256)
    {
        return powers[_validatorAddress][currentValsetVersion];
    }

    /*
     * @dev: recoverGas
     */
    function recoverGas(uint256 _valsetVersion, address _validatorAddress)
        external
        onlyOperator
    {
        require(
            _valsetVersion < currentValsetVersion,
            "Gas recovery only allowed for previous validator sets"
        );
        // Delete from mappings and recover gas
        delete (validators[_validatorAddress][currentValsetVersion]);
        delete (powers[_validatorAddress][currentValsetVersion]);
    }

    /*
     * @dev: addValidatorInternal
     */
    function addValidatorInternal(
        address _validatorAddress,
        uint256 _validatorPower
    ) internal {
        validatorCount = validatorCount.add(1);
        totalPower = totalPower.add(_validatorPower);

        // Set validator as active and set their power
        validators[_validatorAddress][currentValsetVersion] = true;
        powers[_validatorAddress][currentValsetVersion] = _validatorPower;

        emit LogValidatorAdded(
            _validatorAddress,
            _validatorPower,
            currentValsetVersion,
            validatorCount,
            totalPower
        );
    }

    /*
     * @dev: resetValset
     */
    function resetValset() internal {
        currentValsetVersion = currentValsetVersion.add(1);
        validatorCount = 0;
        totalPower = 0;

        emit LogValsetReset(currentValsetVersion, validatorCount, totalPower);
    }
}

pragma solidity 0.5.16;

contract ValsetStorage {

    /**
     * @dev: Total power of all validators
     */
    uint256 public totalPower;

    /**
     * @dev: Current valset version
     */
    uint256 public currentValsetVersion;

    /**
     * @dev: validator count
     */
    uint256 public validatorCount;

    /**
     * @dev: Keep track of active validator
     */
    mapping(address => mapping(uint256 => bool)) public validators;

    /**
     * @dev: operator address
     */
    address public operator;

    /**
     * @dev: validator address + uint then hashed equals key mapped to powers
     */
    mapping(address => mapping(uint256 => uint256)) public powers;

    /**
    * @notice gap of storage for future upgrades
    */
    uint256[100] private ____gap;
}

pragma solidity ^0.5.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}