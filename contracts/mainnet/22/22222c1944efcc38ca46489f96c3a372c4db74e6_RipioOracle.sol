pragma solidity ^0.4.19;

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


contract Delegable is Ownable {
    mapping(address => DelegateLog) public delegates;

    struct DelegateLog {
        uint256 started;
        uint256 ended;
    }

    /**
        @dev Only allows current delegates.
    */
    modifier onlyDelegate() {
        DelegateLog memory delegateLog = delegates[msg.sender];
        require(delegateLog.started != 0 && delegateLog.ended == 0);
        _;
    }
    
    /**
        @dev Checks if a delegate existed at the timestamp.

        @param _address Address of the delegate
        @param timestamp Moment to check

        @return true if at the timestamp the delegate existed
    */
    function wasDelegate(address _address, uint256 timestamp) public view returns (bool) {
        DelegateLog memory delegateLog = delegates[_address];
        return timestamp >= delegateLog.started && delegateLog.started != 0 && (delegateLog.ended == 0 || timestamp < delegateLog.ended);
    }

    /**
        @dev Checks if a delegate is active

        @param _address Address of the delegate
        
        @return true if the delegate is active
    */
    function isDelegate(address _address) public view returns (bool) {
        DelegateLog memory delegateLog = delegates[_address];
        return delegateLog.started != 0 && delegateLog.ended == 0;
    }

    /**
        @dev Adds a new worker.

        @param _address Address of the worker
    */
    function addDelegate(address _address) public onlyOwner returns (bool) {
        DelegateLog storage delegateLog = delegates[_address];
        require(delegateLog.started == 0);
        delegateLog.started = block.timestamp;
        return true;
    }

    /**
        @dev Removes an existing worker, removed workers can&#39;t be added back.

        @param _address Address of the worker to remove
    */
    function removeDelegate(address _address) public onlyOwner returns (bool) {
        DelegateLog storage delegateLog = delegates[_address];
        require(delegateLog.started != 0 && delegateLog.ended == 0);
        delegateLog.ended = block.timestamp;
        return true;
    }
}

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


contract RipioOracle is Oracle, Delegable {
    uint256 public expiration = 15 minutes;

    uint constant private INDEX_TIMESTAMP = 0;
    uint constant private INDEX_RATE = 1;
    uint constant private INDEX_DECIMALS = 2;
    uint constant private INDEX_V = 3;
    uint constant private INDEX_R = 4;
    uint constant private INDEX_S = 5;

    string private infoUrl;

    mapping(bytes32 => RateCache) private cache;

    address public fallback;

    struct RateCache {
        uint256 timestamp;
        uint256 rate;
        uint256 decimals;
    }

    function url() public view returns (string) {
        return infoUrl;
    }

    /**
        @notice Sets the time window of the validity of the signed rates.
        
        @param time Duration of the window

        @return true is the time was set correctly
    */
    function setExpirationTime(uint256 time) public onlyOwner returns (bool) {
        expiration = time;
        return true;
    }

    /**
        @notice Sets the URL where the oracleData can be retrieved

        @param _url The URL

        @return true if it was set correctly
    */
    function setUrl(string _url) public onlyOwner returns (bool) {
        infoUrl = _url;
        return true;
    }

    /**
        @notice Sets the address of another contract to handle the requests of this contract,
            it can be used to deprecate this Oracle

        @dev The fallback is only used if is not address(0)

        @param _fallback The address of the contract

        @return true if it was set correctly
    */
    function setFallback(address _fallback) public onlyOwner returns (bool) {
        fallback = _fallback;
        return true;
    }

    /**
        @notice Reads a bytes32 word of a bytes array

        @param data The bytes array
        @param index The index of the word, in chunks of 32 bytes

        @return o The bytes32 word readed, or 0x0 if index out of bounds
    */
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        if(data.length / 32 > index) {
            assembly {
                o := mload(add(data, add(32, mul(32, index))))
            }
        }
    }

    /**
        @notice Executes a transaction from this contract

        @dev It can be used to retrieve lost tokens or ETH

        @param to Address to call
        @param value Ethers to send
        @param data Data for the call

        @return true If the call didn&#39;t throw an exception
    */
    function sendTransaction(address to, uint256 value, bytes data) public onlyOwner returns (bool) {
        return to.call.value(value)(data);
    }


    /**
        @dev Retrieves the convertion rate of a given currency, the information of the rate is carried over the 
        data field. If there is a newer rate on the cache, that rate is delivered and the data field is ignored.

        If the data contains a more recent rate than the cache, the cache is updated.

        @param currency Hash of the currency
        @param data Data with the rate signed by a delegate

        @return the rate and decimals of the currency convertion
    */
    function getRate(bytes32 currency, bytes data) public returns (uint256, uint256) {
        if (fallback != address(0)) {
            return Oracle(fallback).getRate(currency, data);
        }

        uint256 timestamp = uint256(readBytes32(data, INDEX_TIMESTAMP));
        require(timestamp <= block.timestamp);

        uint256 expirationTime = block.timestamp - expiration;

        if (cache[currency].timestamp >= timestamp && cache[currency].timestamp >= expirationTime) {
            return (cache[currency].rate, cache[currency].decimals);
        } else {
            require(timestamp >= expirationTime);
            uint256 rate = uint256(readBytes32(data, INDEX_RATE));
            uint256 decimals = uint256(readBytes32(data, INDEX_DECIMALS));
            uint8 v = uint8(readBytes32(data, INDEX_V));
            bytes32 r = readBytes32(data, INDEX_R);
            bytes32 s = readBytes32(data, INDEX_S);
            
            bytes32 _hash = keccak256(this, currency, rate, decimals, timestamp);
            address signer = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _hash),v,r,s);

            require(isDelegate(signer));

            cache[currency] = RateCache(timestamp, rate, decimals);

            return (rate, decimals);
        }
    }
}