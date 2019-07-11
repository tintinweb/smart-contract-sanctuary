pragma solidity ^0.4.25;

import "./provableAPI_0.4.25.sol";

/* Interface for the DMEX base contract */
contract DMEX {

	function closeFuturesContract (bytes32 futuresContract, uint256 price) returns (bool);
	function getContractExpiration (bytes32 futuresContractHash) returns (uint256);
	function getContractClosed (bytes32 futuresContractHash) returns (bool);
	function getContractPriceUrl (bytes32 futuresContractHash) returns (string);
	function getContractPricePath (bytes32 futuresContractHash) returns (string);
}

// The DMEX Futures Contract
contract DMEX_Oracle is usingProvable {

	address public DMEX_contract;
	address public owner; // holds the address of the contract owner

	mapping (bytes32 => bytes32)            public oracle_queries;     // mapping of pending oracle price queries (queryId => futuresContractHash)
	mapping (address => bool) 				public admins;             // mapping of admin addresses


	event LogOracleRequest(bytes32 indexed queryId, bytes32 indexed futuresContractHash, string priceUrl, string pricePath);
    event LogOracleCallback(bytes32 indexed queryId, bytes32 indexed futuresContractHash, string result, bytes proof);

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    function assert(bool assertion) pure {

        if (!assertion) {
            throw;
        }
    }

    // Safe Multiply Function - prevents integer overflow
    function safeMul(uint a, uint b) pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow
    function safeSub(uint a, uint b) pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow
    function safeAdd(uint a, uint b) pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Adds or disables an admin account
    function setAdmin(address admin, bool isAdmin) onlyOwner {
        admins[admin] = isAdmin;
    }

    function setDmexContract(address DMEX_contract_)
    {
    	DMEX_contract = DMEX_contract_;
    }

    // Allows for admins only to call the function
    modifier onlyAdmin {
        if (msg.sender != owner && !admins[msg.sender]) throw;
        _;
    }


	// Constructor function, initializes the contract and sets the core variables
    function DMEX_Oracle() {
    	owner = msg.sender;

        provable_setProof(proofType_TLSNotary);
    }

    function deposit() payable {

    }

    function withdraw(uint256 amount) onlyOwner
    {
    	msg.sender.send(amount);
    }

	function closeFuturesContract (bytes32 futuresContractHash, uint256 gasPrice, uint256 gasLimit) onlyAdmin payable
    {
        if (DMEX(DMEX_contract).getContractExpiration(futuresContractHash) == 0) revert(); // contract not found
        if (DMEX(DMEX_contract).getContractClosed(futuresContractHash) == true) revert(); // contract already closed

        closeContractWithOraclePrice(futuresContractHash, gasPrice, gasLimit);
    }

    function closeContractWithOraclePrice(bytes32 futuresContractHash, uint256 gasPrice, uint256 gasLimit) private {
        string memory priceUrl = DMEX(DMEX_contract).getContractPriceUrl(futuresContractHash); // futuresAssets[DMEX(DMEX_contract).futuresContracts[futuresContractHash].asset].priceUrl;
        string memory path = DMEX(DMEX_contract).getContractPricePath(futuresContractHash); //  futuresAssets[DMEX(DMEX_contract).futuresContracts[futuresContractHash].asset].pricePath;

        provable_setCustomGasPrice(gasPrice);

        bytes32 queryId = provable_query("URL",strConcat("json(", priceUrl, ").",path), gasLimit);
        oracle_queries[queryId] = futuresContractHash;
        emit LogOracleRequest(queryId, futuresContractHash, priceUrl, path);

    }

    // Receives price from the oracle
    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != provable_cbAddress()) revert();
        if (oracle_queries[myid][0] == 0) revert();

        bytes32 futuresContractHash = oracle_queries[myid];

        emit LogOracleCallback(myid, futuresContractHash, result, proof);

        uint256 price = safeMul(parseInt(result, 2), 1e6);

        DMEX(DMEX_contract).closeFuturesContract(futuresContractHash, price);

    }

}