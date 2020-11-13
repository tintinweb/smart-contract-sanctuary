pragma solidity 0.5.17;

import "@keep-network/sortition-pools/contracts/AbstractSortitionPool.sol";

contract CandidatesPools {
    // Notification that a new sortition pool has been created.
    event SortitionPoolCreated(
        address indexed application,
        address sortitionPool
    );

    // Mapping of pools with registered member candidates for each application.
    mapping(address => address) candidatesPools; // application -> candidates pool

    /// @notice Creates new sortition pool for the application.
    /// @dev Emits an event after sortition pool creation.
    /// @param _application Address of the application.
    /// @return Address of the created sortition pool contract.
    function createSortitionPool(address _application)
        external
        returns (address)
    {
        require(
            candidatesPools[_application] == address(0),
            "Sortition pool already exists"
        );

        address sortitionPoolAddress = newSortitionPool(_application);

        candidatesPools[_application] = sortitionPoolAddress;

        emit SortitionPoolCreated(_application, sortitionPoolAddress);

        return candidatesPools[_application];
    }

    /// @notice Register caller as a candidate to be selected as keep member
    /// for the provided customer application.
    /// @dev If caller is already registered it returns without any changes.
    /// @param _application Address of the application.
    function registerMemberCandidate(address _application) external {
        AbstractSortitionPool candidatesPool = AbstractSortitionPool(
            getSortitionPool(_application)
        );

        address operator = msg.sender;
        if (!candidatesPool.isOperatorInPool(operator)) {
            candidatesPool.joinPool(operator);
        }
    }

    /// @notice Checks if operator's details in the member candidates pool are
    /// up to date for the given application. If not update operator status
    /// function should be called by the one who is monitoring the status.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function isOperatorUpToDate(address _operator, address _application)
        external
        view
        returns (bool)
    {
        return
            getSortitionPoolForOperator(_operator, _application)
                .isOperatorUpToDate(_operator);
    }

    /// @notice Invokes update of operator's details in the member candidates pool
    /// for the given application
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function updateOperatorStatus(address _operator, address _application)
        external
    {
        getSortitionPoolForOperator(_operator, _application)
            .updateOperatorStatus(_operator);
    }

    /// @notice Gets the sortition pool address for the given application.
    /// @dev Reverts if sortition does not exist for the application.
    /// @param _application Address of the application.
    /// @return Address of the sortition pool contract.
    function getSortitionPool(address _application)
        public
        view
        returns (address)
    {
        require(
            candidatesPools[_application] != address(0),
            "No pool found for the application"
        );

        return candidatesPools[_application];
    }

    /// @notice Checks if operator is registered as a candidate for the given
    /// customer application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    /// @return True if operator is already registered in the candidates pool,
    /// false otherwise.
    function isOperatorRegistered(address _operator, address _application)
        public
        view
        returns (bool)
    {
        if (candidatesPools[_application] == address(0)) {
            return false;
        }

        AbstractSortitionPool candidatesPool = AbstractSortitionPool(
            candidatesPools[_application]
        );

        return candidatesPool.isOperatorRegistered(_operator);
    }

    /// @notice Checks if given operator is eligible for the given application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function isOperatorEligible(address _operator, address _application)
        public
        view
        returns (bool)
    {
        if (candidatesPools[_application] == address(0)) {
            return false;
        }

        AbstractSortitionPool candidatesPool = AbstractSortitionPool(
            candidatesPools[_application]
        );

        return candidatesPool.isOperatorEligible(_operator);
    }

    /// @notice Gets the total weight of operators
    /// in the sortition pool for the given application.
    /// @dev Reverts if sortition does not exits for the application.
    /// @param _application Address of the application.
    /// @return The sum of all registered operators' weights in the pool.
    /// Reverts if sortition pool for the application does not exist.
    function getSortitionPoolWeight(address _application)
        public
        view
        returns (uint256)
    {
        return
            AbstractSortitionPool(getSortitionPool(_application)).totalWeight();
    }

    /// @notice Creates new sortition pool for the application.
    /// @dev Have to be implemented by keep factory to call desired sortition
    /// pool factory.
    /// @param _application Address of the application.
    /// @return Address of the created sortition pool contract.
    function newSortitionPool(address _application) internal returns (address);

    /// @notice Gets bonded sortition pool of specific application for the
    /// operator.
    /// @dev Reverts if the operator is not registered for the application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    /// @return Bonded sortition pool.
    function getSortitionPoolForOperator(
        address _operator,
        address _application
    ) internal view returns (AbstractSortitionPool) {
        require(
            isOperatorRegistered(_operator, _application),
            "Operator not registered for the application"
        );

        return AbstractSortitionPool(candidatesPools[_application]);
    }
}
