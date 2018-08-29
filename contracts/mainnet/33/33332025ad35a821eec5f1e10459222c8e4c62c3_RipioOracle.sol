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
    function setOwner(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
}


contract Delegable is Ownable {
    event AddDelegate(address delegate);
    event RemoveDelegate(address delegate);

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
        emit AddDelegate(_address);
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
        emit RemoveDelegate(_address);
        return true;
    }
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
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


contract RipioOracle is Oracle, Delegable, BytesUtils {
    event DelegatedCall(address requester, address to);
    event CacheHit(address requester, bytes32 currency, uint256 requestTimestamp, uint256 deliverTimestamp, uint256 rate, uint256 decimals);
    event DeliveredRate(address requester, bytes32 currency, address signer, uint256 requestTimestamp, uint256 rate, uint256 decimals);

    uint256 public expiration = 6 hours;

    uint constant private INDEX_TIMESTAMP = 0;
    uint constant private INDEX_RATE = 1;
    uint constant private INDEX_DECIMALS = 2;
    uint constant private INDEX_V = 3;
    uint constant private INDEX_R = 4;
    uint constant private INDEX_S = 5;

    string private infoUrl;
    
    address public prevOracle;
    Oracle public fallback;
    mapping(bytes32 => RateCache) public cache;

    struct RateCache {
        uint256 timestamp;
        uint256 rate;
        uint256 decimals;
    }

    function url() public view returns (string) {
        return infoUrl;
    }

    /**
        @dev Sets the time window of the validity of the rates signed.

        @param time Duration of the window

        @return true is the time was set correctly
    */
    function setExpirationTime(uint256 time) public onlyOwner returns (bool) {
        expiration = time;
        return true;
    }

    /**
        @dev Sets the url to retrieve the data for &#39;getRate&#39;

        @param _url New url
    */
    function setUrl(string _url) public onlyOwner returns (bool) {
        infoUrl = _url;
        return true;
    }

    /**
        @dev Sets another oracle as the replacement to this oracle
        All &#39;getRate&#39; calls will be forwarded to this new oracle

        @param _fallback New oracle
    */
    function setFallback(Oracle _fallback) public onlyOwner returns (bool) {
        fallback = _fallback;
        return true;
    }

    /**
        @dev Invalidates the cache of a given currency

        @param currency Currency to invalidate the cache
    */
    function invalidateCache(bytes32 currency) public onlyOwner returns (bool) {
        delete cache[currency].timestamp;
        return true;
    }
    
    function setPrevOracle(address oracle) public onlyOwner returns (bool) {
        prevOracle = oracle;
        return true;
    }

    function isExpired(uint256 timestamp) internal view returns (bool) {
        return timestamp <= now - expiration;
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
            emit DelegatedCall(msg.sender, fallback);
            return fallback.getRate(currency, data);
        }

        uint256 timestamp = uint256(readBytes32(data, INDEX_TIMESTAMP));
        RateCache memory rateCache = cache[currency];
        if (rateCache.timestamp >= timestamp && !isExpired(rateCache.timestamp)) {
            emit CacheHit(msg.sender, currency, timestamp, rateCache.timestamp, rateCache.rate, rateCache.decimals);
            return (rateCache.rate, rateCache.decimals);
        } else {
            require(!isExpired(timestamp), "The rate provided is expired");
            uint256 rate = uint256(readBytes32(data, INDEX_RATE));
            uint256 decimals = uint256(readBytes32(data, INDEX_DECIMALS));
            uint8 v = uint8(readBytes32(data, INDEX_V));
            bytes32 r = readBytes32(data, INDEX_R);
            bytes32 s = readBytes32(data, INDEX_S);
            
            bytes32 _hash = keccak256(abi.encodePacked(this, currency, rate, decimals, timestamp));
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),v,r,s);

            if(!isDelegate(signer)) {
                _hash = keccak256(abi.encodePacked(prevOracle, currency, rate, decimals, timestamp));
                signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),v,r,s);
                if(!isDelegate(signer)) {
                    revert(&#39;Signature not valid&#39;);
                }
            }

            cache[currency] = RateCache(timestamp, rate, decimals);

            emit DeliveredRate(msg.sender, currency, signer, timestamp, rate, decimals);
            return (rate, decimals);
        }
    }
}