pragma solidity ^0.4.23;

/// @title A contract that remembers its creator (owner). Part of the
///        Lition Smart Contract.
///
/// @author Bj&#246;rn Stein, Quantum-Factory GmbH,
///                      https://quantum-factory.de
///
/// @dev License: Attribution-NonCommercial-ShareAlike 2.0 Generic (CC
///              BY-NC-SA 2.0), see
///              https://creativecommons.org/licenses/by-nc-sa/2.0/
contract owned {
    constructor() public { owner = msg.sender; }
    address owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

/// @title A contract that allows consumer addresses to be
///        registered. Part of the Lition Smart Contract.
///
/// @author Bj&#246;rn Stein, Quantum-Factory GmbH,
///                      https://quantum-factory.de
///
/// @dev License: Attribution-NonCommercial-ShareAlike 2.0 Generic (CC
///              BY-NC-SA 2.0), see
///              https://creativecommons.org/licenses/by-nc-sa/2.0/
contract consumerRegistry is owned {
    event consumerRegistered(address indexed consumer);
    event consumerDeregistered(address indexed consumer);

    // map address to userID
    mapping(address => uint32) public consumers;

    modifier onlyRegisteredConsumers {
        require(consumers[msg.sender] > 0);
        _;
    }

    /// @notice Allow the owner of the address `aconsumer.address()`
    ///         to make transactions on behalf of user id `auserID`.
    ///
    /// @dev Register address aconsumer to belong to userID
    ///      auserID. Addresses can be delisted ("unregistered") by
    ///      setting the userID auserID to zero.
    function registerConsumer(address aconsumer, uint32 auserID) onlyOwner external {
        if (auserID != 0) {
            emit consumerRegistered(aconsumer);
        } else {
            emit consumerDeregistered(aconsumer);
        }
        consumers[aconsumer] = auserID;
    }
}

/// @title A contract that allows producer addresses to be registered.
///
/// @author Bj&#246;rn Stein, Quantum-Factory GmbH,
///                      https://quantum-factory.de
///
/// @dev License: Attribution-NonCommercial-ShareAlike 2.0 Generic (CC
///              BY-NC-SA 2.0), see
///              https://creativecommons.org/licenses/by-nc-sa/2.0/
contract producerRegistry is owned {
    event producerRegistered(address indexed producer);
    event producerDeregistered(address indexed producer);
    
    // map address to bool "is a registered producer"
    mapping(address => bool) public producers;

    modifier onlyRegisteredProducers {
        require(producers[msg.sender]);
        _;
    }
    
    /// @notice Allow the owner of address `aproducer.address()` to
    ///         act as a producer (by offering energy).
    function registerProducer(address aproducer) onlyOwner external {
        emit producerRegistered(aproducer);
        producers[aproducer] = true;
    }

    /// @notice Cease allowing the owner of address
    ///         `aproducer.address()` to act as a producer (by
    ///         offering energy).
    function deregisterProducer(address aproducer) onlyOwner external {
        emit producerDeregistered(aproducer);
        producers[aproducer] = false;
    }
}

/// @title The Lition Smart Contract, initial development version.
///
/// @author Bj&#246;rn Stein, Quantum-Factory GmbH,
///                      https://quantum-factory.de
///
/// @dev License: Attribution-NonCommercial-ShareAlike 2.0 Generic (CC
///              BY-NC-SA 2.0), see
///              https://creativecommons.org/licenses/by-nc-sa/2.0/
contract EnergyStore is owned, consumerRegistry, producerRegistry {

    event BidMade(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event BidRevoked(address indexed producer, uint32 indexed day, uint32 indexed price, uint64 energy);
    event Deal(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);
    event DealRevoked(address indexed producer, uint32 indexed day, uint32 price, uint64 energy, uint32 indexed userID);
    
    uint64 constant mWh = 1;
    uint64 constant  Wh = 1000 * mWh;
    uint64 constant kWh = 1000 * Wh;
    uint64 constant MWh = 1000 * kWh;
    uint64 constant GWh = 1000 * MWh;
    uint64 constant TWh = 1000 * GWh;
    uint64 constant maxEnergy = 18446 * GWh;
  
    struct Bid {
        // producer&#39;s public key
        address producer;
        
        // day for which the offer is valid
        uint32 day;
        
        // price vs market price
        uint32 price;
        
        // energy to sell
        uint64 energy;
        
        // timestamp for when the offer was submitted
        uint64 timestamp;
    }
    
    struct Ask {
        address producer;
        uint32 day;
        uint32 price;
        uint64 energy;
        uint32 userID;
        uint64 timestamp;
    }

    // bids (for energy: offering energy for sale)
    Bid[] public bids;

    // asks (for energy: demanding energy to buy)
    Ask[] public asks;
    
    // map (address, day) to index into bids
    mapping(address => mapping(uint32 => uint)) public bidsIndex;
    
    // map (userid) to index into asks [last take written]
    mapping(uint32 => uint) public asksIndex;
    
    /// @notice Offer `(aenergy / 1.0e6).toFixed(6)` kWh of energy for
    ///         day `aday` at a price `(aprice / 1.0e3).toFixed(3) + &#39;
    ///         ct/kWh&#39;` above market price for a date given as day
    ///         `aday` whilst asserting that the current date and time
    ///         in nanoseconds since 1970 is `atimestamp`.
    ///
    /// @param aday Day for which the offer is valid.
    /// @param aprice Price surcharge in millicent/kWh above market
    ///        price
    /// @param aenergy Energy to be offered in mWh
    /// @param atimestamp UNIX time (seconds since 1970) in
    ///        nanoseconds
    function offer_energy(uint32 aday, uint32 aprice, uint64 aenergy, uint64 atimestamp) onlyRegisteredProducers external {
        // require a minimum offer of 1 kWh
        require(aenergy >= kWh);
        
        uint idx = bidsIndex[msg.sender][aday];
        
        // idx is either 0 or such that bids[idx] has the right producer and day (or both 0 and ...)
        if ((bids.length > idx) && (bids[idx].producer == msg.sender) && (bids[idx].day == aday)) {
            // we will only let newer timestamps affect the stored data
            require(atimestamp > bids[idx].timestamp);
            
            // NOTE: Should we sanity-check timestamps here (ensure that
            //       they are either in the past or not in the too-distant
            //       future compared to the last block&#39;s timestamp)?

            emit BidRevoked(bids[idx].producer, bids[idx].day, bids[idx].price, bids[idx].energy);   
        }
        
        // create entry with new index idx for (msg.sender, aday)
        idx = bids.length;
        bidsIndex[msg.sender][aday] = idx; 
        bids.push(Bid({
            producer: msg.sender,
            day: aday,
            price: aprice,
            energy: aenergy,
            timestamp: atimestamp
        }));
        emit BidMade(bids[idx].producer, bids[idx].day, bids[idx].price, bids[idx].energy);
    }
    
    function getBidsCount() external view returns(uint count) {
        return bids.length;
    }

    function getBidByProducerAndDay(address producer, uint32 day) external view returns(uint32 price, uint64 energy) {
        uint idx = bidsIndex[producer][day];
        require(bids.length > idx);
        require(bids[idx].producer == producer);
        require(bids[idx].day == day);
        return (bids[idx].price, bids[idx].energy);
    }

    /// @notice Buy `(aenergy / 1.0e6).toFixed(6)` kWh of energy on
    ///         behalf of user id `auserID` (possibly de-anonymized by
    ///         randomization) for day `aday` at a surcharge `(aprice
    ///         / 1.0e3).toFixed(3)` ct/kWh from the energy producer
    ///         using the address `aproducer.address()` whilst
    ///         asserting that the current time in seconds since 1970
    ///         is `(atimestamp / 1.0e9)` seconds.
    ///
    /// @param aproducer Address of the producer offering the energy
    ///        to be bought.
    /// @param aday Day for which the offer is valid.
    /// @param aprice Price surcharge in millicent/kWh above market
    ///        price
    /// @param aenergy Energy to be offered in mWh
    /// @param atimestamp UNIX time (seconds since 1970) in
    ///        nanoseconds
    ///
    /// @dev This function is meant to be called by Lition on behalf
    ///      of customers.
    function buy_energy(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) onlyOwner external {
        buy_energy_core(aproducer, aday, aprice, aenergy, auserID, atimestamp);
    }
    
    /// @notice Buy `(aenergy / 1.0e6).toFixed(6)` kWh of energy on
    ///          for day `aday` at a surcharge `(aprice /
    ///          1.0e3).toFixed(3)` ct/kWh from the energy producer
    ///          using the address `aproducer.address()`.
    ///
    /// @param aproducer Address of the producer offering the energy
    ///        to be bought.
    /// @param aday Day for which the offer is valid.
    /// @param aprice Price surcharge in millicent/kWh above market
    ///        price
    /// @param aenergy Energy to be offered in mWh
    ///
    /// @dev This function is meant to be called by a Lition customer
    ///      who has chosen to be registered for this ability and to
    ///      decline anonymization by randomization of user ID.
    function buy_energy(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy) onlyRegisteredConsumers external {
        buy_energy_core(aproducer, aday, aprice, aenergy, consumers[msg.sender], 0);
    }

    function buy_energy_core(address aproducer, uint32 aday, uint32 aprice, uint64 aenergy, uint32 auserID, uint64 atimestamp) internal {
        // find offer by producer (aproducer) for day (aday), or zero
        uint idx = bidsIndex[aproducer][aday];
        
        // if the offer exists...
        if ((bids.length > idx) && (bids[idx].producer == aproducer) && (bids[idx].day == aday)) {
            // ...and has the right price...
            require(bids[idx].price == aprice);
            
            // ...and is not overwriting a (by timestamp) later choice...
            //
            // NOTE: Only works if a single (same) day is written, not for
            //       a bunch of writes (with different days)
            //
            // NOTE: The timestamp checking logic can be turned off by
            //       using a timestamp of zero.
            uint asksIdx = asksIndex[auserID];
            if ((asks.length > asksIdx) && (asks[asksIdx].day == aday)) {
                require((atimestamp == 0) || (asks[asksIdx].timestamp < atimestamp));
                emit DealRevoked(asks[asksIdx].producer, asks[asksIdx].day, asks[asksIdx].price, asks[asksIdx].energy, asks[asksIdx].userID);
            }
            
            // ...then record the customer&#39;s choice
            asksIndex[auserID] = asks.length;
            asks.push(Ask({
                producer: aproducer,
                day: aday,
                price: aprice,
                energy: aenergy,
                userID: auserID,
                timestamp: atimestamp
            }));
            emit Deal(aproducer, aday, aprice, aenergy, auserID);
        } else {
            // the offer does not exist
            revert();
        }
    }

    function getAsksCount() external view returns(uint count) {
        return asks.length;
    }
        
    function getAskByUserID(uint32 userID) external view returns(address producer, uint32 day, uint32 price, uint64 energy) {
        uint idx = asksIndex[userID];
        require(asks[idx].userID == userID);
        return (asks[idx].producer, asks[idx].day, asks[idx].price, asks[idx].energy);
    }
}