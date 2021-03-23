/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File contracts/lib/ownership/Ownable.sol

pragma solidity ^0.5.1;

contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public { owner = msg.sender; }

    /// @dev Throws if called by any contract other than latest designated caller
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// File contracts/lib/ownership/ZapCoordinatorInterface.sol

pragma solidity ^0.5.1;
contract ZapCoordinatorInterface is Ownable {
    function addImmutableContract(string calldata contractName, address newAddress) external;
    function updateContract(string calldata contractName, address newAddress) external;
    function getContractName(uint index) public view returns (string memory) ;
    function getContract(string memory contractName) public view returns (address);
    function updateAllDependencies() external;
}


// File contracts/lib/ownership/Upgradable.sol

pragma solidity ^0.5.1;
contract Upgradable {

    address coordinatorAddr;
    ZapCoordinatorInterface coordinator;

    constructor(address c) public{
        coordinatorAddr = c;
        coordinator = ZapCoordinatorInterface(c);
    }

    function updateDependencies() external coordinatorOnly {
        _updateDependencies();
    }

    function _updateDependencies() internal;

    modifier coordinatorOnly() {
        require(msg.sender == coordinatorAddr, "Error: Coordinator Only Function");
        _;
    }
}


// File contracts/lib/lifecycle/Destructible.sol

pragma solidity ^0.5.1;
contract Destructible is Ownable {
    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}


// File contracts/platform/bondage/BondageInterface.sol

pragma solidity ^0.5.1;

contract BondageInterface {
    function bond(address, bytes32, uint256) external returns(uint256);
    function unbond(address, bytes32, uint256) external returns (uint256);
    function delegateBond(address, address, bytes32, uint256) external returns(uint256);
    function escrowDots(address, address, bytes32, uint256) external returns (bool);
    function releaseDots(address, address, bytes32, uint256) external returns (bool);
    function returnDots(address, address, bytes32, uint256) external returns (bool success);
    function calcZapForDots(address, bytes32, uint256) external view returns (uint256);
    function currentCostOfDot(address, bytes32, uint256) public view returns (uint256);
    function getDotsIssued(address, bytes32) public view returns (uint256);
    function getBoundDots(address, address, bytes32) public view returns (uint256);
    function getZapBound(address, bytes32) public view returns (uint256);
    function dotLimit( address, bytes32) public view returns (uint256);
}


// File contracts/platform/arbiter/ArbiterInterface.sol

pragma solidity ^0.5.1;

contract ArbiterInterface {
    function initiateSubscription(address, bytes32, bytes32[] memory, uint256, uint64) public;
    function getSubscription(address, address, bytes32) public view returns (uint64, uint96, uint96);
    function endSubscriptionProvider(address, bytes32) public;
    function endSubscriptionSubscriber(address, bytes32) public;
    function passParams(address receiver, bytes32 endpoint, bytes32[] memory params) public;
}


// File contracts/platform/database/DatabaseInterface.sol

pragma solidity ^0.5.1;
contract DatabaseInterface is Ownable {
    function setStorageContract(address _storageContract, bool _allowed) public;
    /*** Bytes32 ***/
    function getBytes32(bytes32 key) external view returns(bytes32);
    function setBytes32(bytes32 key, bytes32 value) external;
    /*** Number **/
    function getNumber(bytes32 key) external view returns(uint256);
    function setNumber(bytes32 key, uint256 value) external;
    /*** Bytes ***/
    function getBytes(bytes32 key) external view returns(bytes memory);
    function setBytes(bytes32 key, bytes calldata value) external;
    /*** String ***/
    function getString(bytes32 key) external view returns(string memory);
    function setString(bytes32 key, string calldata value) external;
    /*** Bytes Array ***/
    function getBytesArray(bytes32 key) external view returns (bytes32[] memory);
    function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32);
    function getBytesArrayLength(bytes32 key) external view returns (uint256);
    function pushBytesArray(bytes32 key, bytes32 value) external;
    function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external;
    function setBytesArray(bytes32 key, bytes32[] calldata value) external;
    /*** Int Array ***/
    function getIntArray(bytes32 key) external view returns (int[] memory);
    function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int);
    function getIntArrayLength(bytes32 key) external view returns (uint256);
    function pushIntArray(bytes32 key, int value) external;
    function setIntArrayIndex(bytes32 key, uint256 index, int value) external;
    function setIntArray(bytes32 key, int[] calldata value) external;
    /*** Address Array ***/
    function getAddressArray(bytes32 key) external view returns (address[] memory );
    function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address);
    function getAddressArrayLength(bytes32 key) external view returns (uint256);
    function pushAddressArray(bytes32 key, address value) external;
    function setAddressArrayIndex(bytes32 key, uint256 index, address value) external;
    function setAddressArray(bytes32 key, address[] calldata value) external;
}


// File contracts/platform/arbiter/Arbiter.sol

pragma solidity ^0.5.1;
// v1.0
contract Arbiter is Destructible, ArbiterInterface, Upgradable {
    // Called when a data purchase is initiated
    event DataPurchase(
        address indexed provider,          // Etheruem address of the provider
        address indexed subscriber,        // Ethereum address of the subscriber
        uint256 publicKey,                 // Public key of the subscriber
        uint256 indexed amount,            // Amount (in 1/100 ZAP) of ethereum sent
        bytes32[] endpointParams,          // Endpoint specific(nonce,encrypted_uuid),
        bytes32 endpoint                   // Endpoint specifier
    );

    // Called when a data subscription is ended by either provider or terminator
    event DataSubscriptionEnd(
        address indexed provider,                      // Provider from the subscription
        address indexed subscriber,                    // Subscriber from the subscription
        SubscriptionTerminator indexed terminator      // Which terminated the contract
    );

    // Called when party passes arguments to another party
    event ParamsPassed(
        address indexed sender,
        address indexed receiver,
        bytes32 endpoint,
        bytes32[] params
    );

    // Used to specify who is the terminator of a contract
    enum SubscriptionTerminator { Provider, Subscriber }

    BondageInterface bondage;
    address public bondageAddress;

    // database address and reference
    DatabaseInterface public db;

    constructor(address c) Upgradable(c) public {
        _updateDependencies();
    }

    function _updateDependencies() internal {
        bondageAddress = coordinator.getContract("BONDAGE");
        bondage = BondageInterface(bondageAddress);

        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);
    }

    //@dev broadcast parameters from sender to offchain receiver
    /// @param receiver address
    /// @param endpoint Endpoint specifier
    /// @param params arbitrary params to be passed
    function passParams(address receiver, bytes32 endpoint, bytes32[] memory params) public {
        emit ParamsPassed(msg.sender, receiver, endpoint, params);
    }

    /// @dev subscribe to specified number of blocks of provider
    /// @param providerAddress Provider address
    /// @param endpoint Endpoint specifier
    /// @param endpointParams Endpoint specific params
    /// @param publicKey Public key of the purchaser
    /// @param blocks Number of blocks subscribed, 1block=1dot
    function initiateSubscription(
        address providerAddress,   //
        bytes32 endpoint,          //
        bytes32[] memory endpointParams,  //
        uint256 publicKey,         // Public key of the purchaser
        uint64 blocks              //
    )
        public
    {
        // Must be atleast one block
        require(blocks > 0, "Error: Must be at least one block");

        // Can't reinitiate a currently active contract
        require(getDots(providerAddress, msg.sender, endpoint) == 0, "Error: Cannot reinstantiate a currently active contract");

        // Escrow the necessary amount of dots
        bondage.escrowDots(msg.sender, providerAddress, endpoint, blocks);

        // Initiate the subscription struct
        setSubscription(
            providerAddress,
            msg.sender,
            endpoint,
            blocks,
            uint96(block.number),
            uint96(block.number) + uint96(blocks)
        );

        emit DataPurchase(
            providerAddress,
            msg.sender,
            publicKey,
            blocks,
            endpointParams,
            endpoint
        );
    }

    /// @dev get subscription info
    function getSubscription(address providerAddress, address subscriberAddress, bytes32 endpoint)
        public
        view
        returns (uint64 dots, uint96 blockStart, uint96 preBlockEnd)
    {
        return (
            getDots(providerAddress, subscriberAddress, endpoint),
            getBlockStart(providerAddress, subscriberAddress, endpoint),
            getPreBlockEnd(providerAddress, subscriberAddress, endpoint)
        );
    }

    /// @dev Finish the data feed from the provider
    function endSubscriptionProvider(
        address subscriberAddress,
        bytes32 endpoint
    )
        public
    {
        // Emit an event on success about who ended the contract
        if (endSubscription(msg.sender, subscriberAddress, endpoint))
            emit DataSubscriptionEnd(
                msg.sender,
                subscriberAddress,
                SubscriptionTerminator.Provider
            );
    }

    /// @dev Finish the data feed from the subscriber
    function endSubscriptionSubscriber(
        address providerAddress,
        bytes32 endpoint
    )
        public
    {
        // Emit an event on success about who ended the contract
        if (endSubscription(providerAddress, msg.sender, endpoint))
            emit DataSubscriptionEnd(
                providerAddress,
                msg.sender,
                SubscriptionTerminator.Subscriber
            );
    }

    /// @dev Finish the data feed
    function endSubscription(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        private
        returns (bool)
    {
        // get the total value/block length of this subscription
        uint256 dots = getDots(providerAddress, subscriberAddress, endpoint);
        uint256 preblockend = getPreBlockEnd(providerAddress, subscriberAddress, endpoint);
        // Make sure the subscriber has a subscription
        require(dots > 0, "Error: Subscriber must have a subscription");

        if (block.number < preblockend) {
            // Subscription ended early
            uint256 earnedDots = block.number - getBlockStart(providerAddress, subscriberAddress, endpoint);
            uint256 returnedDots = dots - earnedDots;

            // Transfer the earned dots to the provider
            bondage.releaseDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                earnedDots
            );
            //  Transfer the returned dots to the subscriber
            bondage.returnDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                returnedDots
            );
        } else {
            // Transfer all the dots
            bondage.releaseDots(
                subscriberAddress,
                providerAddress,
                endpoint,
                dots
            );
        }
        // Kill the subscription
        deleteSubscription(providerAddress, subscriberAddress, endpoint);
        return true;
    }


    /*** --- *** STORAGE METHODS *** --- ***/

    /// @dev get subscriber dots remaining for specified provider endpoint
    function getDots(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint64)
    {
        return uint64(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots'))));
    }

    /// @dev get first subscription block number
    function getBlockStart(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint96)
    {
        return uint96(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart'))));
    }

    /// @dev get last subscription block number
    function getPreBlockEnd(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        public
        view
        returns (uint96)
    {
        return uint96(db.getNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd'))));
    }

    /**** Set Methods ****/

    /// @dev store new subscription
    function setSubscription(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint,
        uint64 dots,
        uint96 blockStart,
        uint96 preBlockEnd
    )
        private
    {
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots')), dots);
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart')), uint256(blockStart));
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd')), uint256(preBlockEnd));
    }

    /**** Delete Methods ****/

    /// @dev remove subscription
    function deleteSubscription(
        address providerAddress,
        address subscriberAddress,
        bytes32 endpoint
    )
        private
    {
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'dots')), 0);
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'blockStart')), uint256(0));
        db.setNumber(keccak256(abi.encodePacked('subscriptions', providerAddress, subscriberAddress, endpoint, 'preBlockEnd')), uint256(0));
    }
}

    /*************************************** STORAGE ****************************************
    * 'holders', holderAddress, 'initialized', oracleAddress => {uint256} 1 -> provider-subscriber initialized, 0 -> not initialized
    * 'holders', holderAddress, 'bonds', oracleAddress, endpoint => {uint256} number of dots this address has bound to this endpoint
    * 'oracles', oracleAddress, endpoint, 'broker' => {address} address of endpoint broker, 0 if none
    * 'escrow', holderAddress, oracleAddress, endpoint => {uint256} amount of Zap that have been escrowed
    * 'totalBound', oracleAddress, endpoint => {uint256} amount of Zap bound to this endpoint
    * 'totalIssued', oracleAddress, endpoint => {uint256} number of dots issued by this endpoint
    * 'holders', holderAddress, 'oracleList' => {address[]} array of oracle addresses associated with this holder
    ****************************************************************************************/