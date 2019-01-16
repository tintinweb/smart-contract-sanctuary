pragma solidity ^0.4.24;

// File: contracts/interfaces/IERC165.sol

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/diaspore/interfaces/RateOracle.sol

/**
    @dev Defines the interface of a standard Diaspore RCN Oracle,
    
    The contract should also implement it&#39;s ERC165 interface: 0xa265d8e0

    @notice Each oracle can only support one currency

    @author Agustin Aguilar
*/
contract RateOracle is IERC165 {
    uint256 public constant VERSION = 5;
    bytes4 internal constant RATE_ORACLE_INTERFACE = 0xa265d8e0;

    constructor() internal {}

    /**
        3 or 4 letters symbol of the currency, Ej: ETH
    */
    function symbol() external view returns (string);

    /**
        Descriptive name of the currency, Ej: Ethereum
    */
    function name() external view returns (string);

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
    function maintainer() external view returns (string);

    /**
        Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() external view returns (string);

    /** 
        Returns a sample on how many token() are equals to how many currency()
    */
    function readSample(bytes _data) external returns (uint256 _tokens, uint256 _equivalent);
}

// File: contracts/utils/ERC165.sol

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
    * 0x01ffc9a7 ===
    *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
    */

    /**
    * @dev a mapping of interface id to whether or not it&#39;s supported
    */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
    * @dev A contract implementing SupportsInterfaceWithLookup
    * implement ERC165 itself
    */
    constructor()
        internal
    {
        _registerInterface(_InterfaceId_ERC165);
    }

    /**
    * @dev implement supportsInterface(bytes4) using a lookup table
    */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
    * @dev internal method for registering an interface
    */
    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can&#39;t register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/utils/Ownable.sol

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
}

// File: contracts/interfaces/Token.sol

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

// File: contracts/interfaces/Oracle.sol

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return if the creation was done successfully
    */
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

    /**
        @return the currency encoded as a bytes32
    */
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }
    
    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
    
}

// File: contracts/diaspore/utils/OracleAdapter.sol

contract OracleAdapter is RateOracle, ERC165 {
    Oracle public legacyOracle;

    string private isymbol;
    string private iname;
    string private imaintainer;

    uint256 private idecimals;
    bytes32 private icurrency;

    address private itoken;

    constructor(
        Oracle _legacyOracle,
        string _symbol,
        string _name,
        string _maintainer,
        uint256 _decimals,
        bytes32 _currency,
        address _token
    ) public {
        legacyOracle = _legacyOracle;
        isymbol = _symbol;
        iname = _name;
        imaintainer = _maintainer;
        idecimals = _decimals;
        icurrency = _currency;
        itoken = _token;

        _registerInterface(RATE_ORACLE_INTERFACE);
    }

    function symbol() external view returns (string) { return isymbol; }

    function name() external view returns (string) { return iname; }

    function decimals() external view returns (uint256) { return idecimals; }

    function token() external view returns (address) { return itoken; }

    function currency() external view returns (bytes32) { return icurrency; }
    
    function maintainer() external view returns (string) { return imaintainer; }

    function url() external view returns (string) {
        return legacyOracle.url();
    }

    function readSample(bytes _data) external returns (uint256 _tokens, uint256 _equivalent) {
        (_tokens, _equivalent) = legacyOracle.getRate(icurrency, _data);
        _equivalent = 10 ** _equivalent;
    }
}