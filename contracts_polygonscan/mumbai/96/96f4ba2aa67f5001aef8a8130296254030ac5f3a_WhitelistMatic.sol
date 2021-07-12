/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.6.0;

/**
    @author The Calystral Team
    @title A parent contract which can be used to keep track of a current contract state
*/
contract ContractState {
    /// @dev Get the current contract state enum.
    State private _currentState;
    /**
        @dev Get the current contract state enum.
        First activation == 1.
    */
    uint256 private _activatedCounter;
    /**
        @dev Get the current contract state enum.
        First inactivation == 1.
    */
    uint256 private _inactivatedCounter;
    /// @dev Includes all three possible contract states.
    enum State {CREATED, INACTIVE, ACTIVE}

    modifier isCurrentState(State _state) {
        _isCurrentState(_state);
        _;
    }

    modifier isCurrentStates(State _state1, State _state2) {
        _isCurrentStates(_state1, _state2);
        _;
    }

    modifier isAnyState() {
        _;
    }

    /**
        @notice Get the current contract state.
        @dev Get the current contract state enum.
        @return The current contract state
    */
    function getCurrentState() public view returns (State) {
        return _currentState;
    }

    /**
        @notice Get the current activated counter.
        @dev Get the current activated counter.
        @return The current activated counter.
    */
    function getActivatedCounter() public view returns (uint256) {
        return _activatedCounter;
    }

    /**
        @notice Get the current inactivated counter.
        @dev Get the current inactivated counter.
        @return The current inactivated counter.
    */
    function getInactivatedCounter() public view returns (uint256) {
        return _inactivatedCounter;
    }

    /**
        @dev Checks if the contract is in the correct state for execution.
        MUST revert if the `_currentState` does not match with the required `_state`.
    */
    function _isCurrentState(State _state) internal view {
        require(
            _currentState == _state,
            "The function call is not possible in the current contract state."
        );
    }

    /**
        @dev Checks if the contract is in one of the correct states for execution.
        MUST revert if the `_currentState` does not match with one of the required states `_state1`, `_state2`.
    */
    function _isCurrentStates(State _state1, State _state2) internal view {
        require(
            _currentState == _state1 || _currentState == _state2,
            "The function call is not possible in the current contract state."
        );
    }

    /**
        @dev Modifies the contract state from State.CREATED or State.ACTIVE into State.INACTIVE.
        Increments the `_inactivatedCounter`.
    */
    function _transitionINACTIVE()
        internal
        isCurrentStates(State.CREATED, State.ACTIVE)
    {
        _currentState = State.INACTIVE;
        _inactivatedCounter++;
        _inactivated(_inactivatedCounter);
    }

    /**
        @dev Modifies the contract state from State.INACTIVE into State.ACTIVE.
        Increments the `_activatedCounter`.
    */
    function _transitionACTIVE() internal isCurrentState(State.INACTIVE) {
        _currentState = State.ACTIVE;
        _activatedCounter++;
        _activated(_activatedCounter);
    }

    /**
        @dev Executes when the contract is set into State.ACTIVE.
        The child contract has to override this function to make use of it.
        The `activatedCouted` parameter is used to execute this function at a specific time only once.
        @param activatedCounter The `activatedCouted` for which the function should be executed once.
    */
    function _activated(uint256 activatedCounter)
        internal
        virtual
        isCurrentState(State.ACTIVE)
    {}

    /**
        @dev Executes when the contract is set into State.INACTIVE.
        The child contract has to override this function to make use of it.
        The `inactivatedCouted` parameter is used to execute this function at a specific time only once.
        @param inactivatedCounter The `inactivatedCouted` for which the function should be executed once.
    */
    function _inactivated(uint256 inactivatedCounter)
        internal
        virtual
        isCurrentState(State.INACTIVE)
    {}
}

/**
    @author The Calystral Team
    @title The Registry's Interface
*/
interface IRegistry {
    /**
        @notice Updates an incoming contract address for relevant contracts or itself. 
        @dev Updates an incoming contract address for relevant contracts or itself.
        Sets itself INACTIVE if it was updated by the registry.
        Sets itself ACTIVE if it was registered by the registry.
        @param contractAddress  The address of the contract update
        @param id               The id of the contract update
    */
    function updateContractAddress(address contractAddress, uint256 id)
        external;

    /**
        @notice Get the contract address of a specific id.
        @dev Get the contract address of a specific id.
        @param id   The contract id
        @return     The contract address of a specific id
    */
    function getContractAddress(uint256 id) external view returns (address);

    /**
        @notice Get if a specific id is relevant for this contract.
        @dev Get if a specific id is relevant for this contract.
        @param id   The contract id
        @return     If the id is relevant for this contract
    */
    function isIdRelevant(uint256 id) external view returns (bool);

    /**
        @notice Get the list of relevant contract ids.
        @dev Get the list of relevant contract ids.
        @return The list of relevant contract ids.
    */
    function getRelevantList() external view returns (uint16[] memory);

    /**
        @notice Get this contract's registry id.
        @dev Get this contract's `_registryId`.
        @return Get this contract's registry id.
    */
    function getRegistryId() external view returns (uint256);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        override
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
    @author The Calystral Team
    @title A parent contract which can be used to integrate with a global contract registry
*/
contract Registry is IRegistry, ContractState, ERC165 {
    /// @dev id => contract address
    mapping(uint256 => address) private _idToContractAddress;
    /// @dev id => a bool showing if it is relevant for updates etc.
    mapping(uint256 => bool) private _idToIsRelevant;
    /**
        @dev This list includes all Ids of contracts that are relevant for this contract listening on address updates in the future.
        This should be immutable but immutable variables cannot have a non-value type.
    */
    uint16[] private _relevantList;
    /**
        @dev The id of this contract.
        Id 0 does not exist but is just reserved.
        Whenever a contract is INACTIVE its id is set to 0.
    */
    uint256 private _registryId;

    modifier isAuthorizedRegistryManager() {
        _isAuthorizedRegistryManager();
        _;
    }

    modifier isAuthorizedAny() {
        _;
    }

    /**
        @notice Initialized and creates the contract including the address of the RegistryManager and a list of relevant contract ids. 
        @dev Creates the contract with an initialized `registryManagerAddress` and `relevantList`.
        Registers this interface for ERC-165.
        MUST revert if the `relevantList` does not include id 1 at index 0.
        @param registryManagerAddress   Address of the RegistryManager contract
        @param relevantList             Array of ids for contracts that are relevant for execution and are tracked for updates
    */
    constructor(address registryManagerAddress, uint16[] memory relevantList)
        public
    {
        require(
            relevantList[0] == 1,
            "The registry manager is required to create a registry type contract."
        );

        _idToContractAddress[1] = registryManagerAddress;
        _relevantList = relevantList;
        for (uint256 i = 0; i < relevantList.length; i++) {
            _idToIsRelevant[relevantList[i]] = true;
        }

        _registerInterface(type(IRegistry).interfaceId); // 0x7bbb2267
    }

    /**
        @notice Updates an incoming contract address for relevant contracts or itself. 
        @dev Updates an incoming contract address for relevant contracts or itself.
        Sets itself INACTIVE if it was updated by the registry.
        Sets itself ACTIVE if it was registered by the registry.
        @param contractAddress  The address of the contract update
        @param id               The id of the contract update
    */
    function updateContractAddress(address contractAddress, uint256 id)
        external
        override
        isCurrentStates(State.ACTIVE, State.INACTIVE)
        isAuthorizedRegistryManager()
    {
        // only execute if it's an relevant contract or this contract
        if (
            _idToIsRelevant[id] == true ||
            contractAddress == address(this) ||
            id == _registryId
        ) {
            // if this contract was updated, set INACTIVE
            if (id == _registryId) {
                _registryId = 0;
                _transitionINACTIVE();
            } else {
                // if this contract got registered, set ACTIVE
                if (contractAddress == address(this)) {
                    _registryId = id;
                    _transitionACTIVE();
                }
                _idToContractAddress[id] = contractAddress;
            }
        }
    }

    /**
        @notice Get the contract address of a specific id.
        @dev Get the contract address of a specific id.
        @param id   The contract id
        @return     The contract address of a specific id
    */
    function getContractAddress(uint256 id)
        public
        override
        view
        returns (address)
    {
        return _idToContractAddress[id];
    }

    /**
        @notice Get if a specific id is relevant for this contract.
        @dev Get if a specific id is relevant for this contract.
        @param id   The contract id
        @return     If the id is relevant for this contract
    */
    function isIdRelevant(uint256 id) public override view returns (bool) {
        return _idToIsRelevant[id];
    }

    /**
        @notice Get the list of relevant contract ids.
        @dev Get the list of relevant contract ids.
        @return The list of relevant contract ids.
    */
    function getRelevantList() public override view returns (uint16[] memory) {
        return _relevantList;
    }

    /**
        @notice Get this contract's registry id.
        @dev Get this contract's `_registryId`.
        @return Get this contract's registry id.
    */
    function getRegistryId() public override view returns (uint256) {
        return _registryId;
    }

    /**
        @dev Checks if the msg.sender is the RegistryManager.
        Reverts if msg.sender is not the RegistryManager.
    */
    function _isAuthorizedRegistryManager() internal view {
        require(
            msg.sender == _idToContractAddress[1],
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }
}

/// @author The Calystral Team
/// @title Sign-up contract for all tech pioneers
/// @notice A list, which is maintained to grant extras to the community
contract WhitelistMatic is Registry {
    /// @dev Maps the subscriber index to an address
    mapping(uint256 => address) private _subscriberIndexToAddress;
    /// @dev Maps the subscriber address to the subscriber index or 0 if not subscriped.
    mapping(address => uint256) private _subscriberAddressToSubscribed;
    /// @dev Maps the subscriber address to the blocknumber of subscription or 0 if not subscriped.
    mapping(address => uint256) private _subscriberAddressToBlockNumber;

    /// @dev Used to point towards the subscriber address. Caution: This will be likely unequal to the actual subscriber count. We start at 1 because 0 will be the indicator that an address is not a subscriber.
    uint256 private _subscriberIndex = 1;
    /// @dev Address of the ListAdmin.
    address private immutable _listAdminAddress;

    /**
        @dev Emits on successful subscription.
        @param _subscriberAddress The address of the subscriber.
     */
    event OnSubscribed(address _subscriberAddress);
    /**
        @dev Emits on successful unsubscription.
        @param _subscriberAddress The address of the unsubscriber.
     */
    event OnUnsubscribed(address _subscriberAddress);

    /// @notice This modifier prevents other smart contracts from subscribing.
    modifier isNotAContract() {
        require(
            msg.sender == tx.origin,
            "Contracts are not allowed to interact."
        );
        _;
    }

    /// @notice This modifier allows the ListAdmin to subscribe users on sign-up.
    modifier isAuthorizedListAdmin() {
        require(
            _listAdminAddress == msg.sender,
            "Unauthorized call. Thanks for supporting the network with your MATIC."
        );
        _;
    }

    /**
        @notice Creates the smart contract and initializes the whitelist.
        @dev The constructor, which initializes the whitelist with all the subscribers from the legacy contract. Legacy subscribers are initialized by the current block number.
        @param subscriberList            Address of the list admin
        @param subscriberList            All subsribers that already signed up on Ethereum
        @param registryManagerAddress    Address of the RegistryManager contract
        @param relevantList              Array of ids for contracts that are relevant for execution and are tracked for updates
     */
    constructor(
        address listAdminAddress,
        address[] memory subscriberList,
        address registryManagerAddress,
        uint16[] memory relevantList
    ) public Registry(registryManagerAddress, relevantList) {
        _listAdminAddress = listAdminAddress;
        for (uint256 i = 0; i < subscriberList.length; i++) {
            _subscribe(subscriberList[i]);
        }
        _transitionINACTIVE();
    }

    /**
        @notice Calls the subscribe function if no specific function was called.
        @dev Fallback function forwards to subscribe function.
     */
    fallback() external {
        subscribe();
    }

    /**
        @notice Any user can add him or herself to the subscriber list.
        @dev Subscribes the message sender to the list. Other contracts are not allowed to subscribe.
     */
    function subscribe()
        public
        isNotAContract()
        isCurrentState(State.ACTIVE)
        isAuthorizedAny()
    {
        _subscribe(msg.sender);
    }

    /**
        @notice Any user is added to this whitelist on sign-up.
        @dev Subscribes the user to this whitelist on sign-up.
        @param user The user address of the new user
     */
    function subscribeOnSignUp(address user)
        public
        isCurrentState(State.ACTIVE)
        isAuthorizedListAdmin()
    {
        _subscribe(user);
    }

    /**
        @notice Any user can revoke his or her subscription.
        @dev Deletes the index entry in the _subscriberIndexToAddress mapping for the message sender.
     */
    function unsubscribe()
        public
        isNotAContract()
        isAnyState()
        isAuthorizedAny()
    {
        require(isSubscriber(msg.sender) != 0, "You have not subscribed yet.");

        uint256 index = _subscriberAddressToSubscribed[msg.sender];
        delete _subscriberIndexToAddress[index];

        emit OnUnsubscribed(msg.sender);
    }

    /**
        @notice Checks wether a user is in the subscriber list.
        @dev tx.origin is used instead of msg.sender so other contracts may forward a user request (e.g. limited rewards contract).
        @return The blocknumber at which the user has subscribed or 0 if not subscribed at all.
     */
    function isSubscriber() public view returns (uint256) {
        return isSubscriber(tx.origin);
    }

    /**
        @notice Checks wheter the given address is in the subscriber list.
        @dev This function isn't external since it's used by the contract as well.
        @param _subscriberAddress The address to check for.
        @return The blocknumber at which the user has subscribed or 0 if not subscribed at all.
     */
    function isSubscriber(address _subscriberAddress)
        public
        view
        returns (uint256)
    {
        if (
            _subscriberIndexToAddress[_subscriberAddressToSubscribed[_subscriberAddress]] !=
            address(0)
        ) {
            return _subscriberAddressToBlockNumber[_subscriberAddress];
        } else {
            return 0;
        }
    }

    /**
        @notice Shows the whole subscriber list.
        @dev Returns all current subscribers as an address array.
        @return A list of subscriber addresses.
     */
    function getSubscriberList() public view returns (address[] memory) {
        uint256 subscriberListCounter = 0;
        uint256 subscriberListCount = getSubscriberCount();
        address[] memory subscriberList = new address[](subscriberListCount);

        for (uint256 i = 1; i < _subscriberIndex; i++) {
            address subscriberAddress = _subscriberIndexToAddress[i];
            if (isSubscriber(subscriberAddress) != 0) {
                subscriberList[subscriberListCounter] = subscriberAddress;
                subscriberListCounter++;
            }
        }

        return subscriberList;
    }

    /**
        @notice Shows the count of subscribers.
        @dev Returns the subscriber count as an integer.
        @return The count of subscribers
     */
    function getSubscriberCount() public view returns (uint256) {
        uint256 subscriberListCount = 0;

        for (uint256 i = 1; i < _subscriberIndex; i++) {
            address subscriberAddress = _subscriberIndexToAddress[i];
            if (isSubscriber(subscriberAddress) != 0) {
                subscriberListCount++;
            }
        }

        return subscriberListCount;
    }

    /**
        @dev This function is necessary, so it can be used by the constructor. Nobody should be able to add other people to the list.
        @param _subscriber The user address, which should be added.
     */
    function _subscribe(address _subscriber) private {
        require(isSubscriber(_subscriber) == 0, "You already subscribed.");

        _subscriberAddressToSubscribed[_subscriber] = _subscriberIndex;
        _subscriberAddressToBlockNumber[_subscriber] = block.number;
        _subscriberIndexToAddress[_subscriberIndex] = _subscriber;
        _subscriberIndex++;

        emit OnSubscribed(_subscriber);
    }
}