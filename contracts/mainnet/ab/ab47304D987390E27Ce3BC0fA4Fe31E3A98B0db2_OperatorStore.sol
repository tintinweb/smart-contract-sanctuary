// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IOperatorStore.sol";

/** 
  @notice
  Addresses can give permissions to any other address to take specific actions 
  throughout the Juicebox ecosystem on their behalf. These addresses are called `operators`.
  
  @dev
  Permissions are stored as a uint256, with each boolean bit representing whether or not
  an oporator has the permission identified by that bit's index in the 256 bit uint256.
  Indexes must be between 0 and 255.

  The directory of permissions, along with how they uniquely mapp to indexes, are managed externally.
  This contract doesn't know or care about specific permissions and their indexes.
*/
contract OperatorStore is IOperatorStore {
    // --- public stored properties --- //

    /** 
      @notice
      The permissions that an operator has to operate on a specific domain.
      
      @dev
      An account can give an operator permissions that only pertain to a specific domain.
      There is no domain with an ID of 0 -- accounts can use the 0 domain to give an operator
      permissions to operator on their personal behalf.
    */
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public
        override permissionsOf;

    // --- public views --- //

    /** 
      @notice 
      Whether or not an operator has the permission to take a certain action pertaining to the specified domain.

      @param _operator The operator to check.
      @param _account The account that has given out permission to the operator.
      @param _domain The domain that the operator has been given permissions to operate.
      @param _permissionIndex the permission to check for.

      @return Whether the operator has the specified permission.
    */
    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view override returns (bool) {
        require(
            _permissionIndex <= 255,
            "OperatorStore::hasPermission: INDEX_OUT_OF_BOUNDS"
        );
        return
            ((permissionsOf[_operator][_account][_domain] >> _permissionIndex) &
                1) == 1;
    }

    /** 
      @notice 
      Whether or not an operator has the permission to take certain actions pertaining to the specified domain.

      @param _operator The operator to check.
      @param _account The account that has given out permissions to the operator.
      @param _domain The domain that the operator has been given permissions to operate.
      @param _permissionIndexes An array of permission indexes to check for.

      @return Whether the operator has all specified permissions.
    */
    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view override returns (bool) {
        for (uint256 _i = 0; _i < _permissionIndexes.length; _i++) {
            uint256 _permissionIndex = _permissionIndexes[_i];

            require(
                _permissionIndex <= 255,
                "OperatorStore::hasPermissions: INDEX_OUT_OF_BOUNDS"
            );

            if (
                ((permissionsOf[_operator][_account][_domain] >>
                    _permissionIndex) & 1) == 0
            ) return false;
        }
        return true;
    }

    // --- external transactions --- //

    /** 
      @notice 
      Sets permissions for an operator.

      @param _operator The operator to give permission to.
      @param _domain The domain that the operator is being given permissions to operate.
      @param _permissionIndexes An array of indexes of permissions to set.
    */
    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external override {
        // Pack the indexes into a uint256.
        uint256 _packed = _packedPermissions(_permissionIndexes);

        // Store the new value.
        permissionsOf[_operator][msg.sender][_domain] = _packed;

        emit SetOperator(
            _operator,
            msg.sender,
            _domain,
            _permissionIndexes,
            _packed
        );
    }

    /** 
      @notice 
      Sets permissions for many operators.

      @param _operators The operators to give permission to.
      @param _domains The domains that can be operated. Set to 0 to allow operation of account level actions.
      @param _permissionIndexes The level of power each operator should have.
    */
    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external override {
        // There should be a level for each operator provided.
        require(
            _operators.length == _permissionIndexes.length &&
                _operators.length == _domains.length,
            "OperatorStore::setOperators: BAD_ARGS"
        );
        for (uint256 _i = 0; _i < _operators.length; _i++) {
            // Pack the indexes into a uint256.
            uint256 _packed = _packedPermissions(_permissionIndexes[_i]);
            // Store the new value.
            permissionsOf[_operators[_i]][msg.sender][_domains[_i]] = _packed;
            emit SetOperator(
                _operators[_i],
                msg.sender,
                _domains[_i],
                _permissionIndexes[_i],
                _packed
            );
        }
    }

    // --- private helper functions --- //

    /** 
      @notice 
      Converts an array of permission indexes to a packed int.

      @param _indexes The indexes of the permissions to pack.

      @return packed The packed result.
    */
    function _packedPermissions(uint256[] calldata _indexes)
        private
        pure
        returns (uint256 packed)
    {
        for (uint256 _i = 0; _i < _indexes.length; _i++) {
            uint256 _permissionIndex = _indexes[_i];
            require(
                _permissionIndex <= 255,
                "OperatorStore::_packedPermissions: INDEX_OUT_OF_BOUNDS"
            );
            // Turn the bit at the index on.
            packed |= 1 << _permissionIndex;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IOperatorStore {
    event SetOperator(
        address indexed operator,
        address indexed account,
        uint256 indexed domain,
        uint256[] permissionIndexes,
        uint256 packed
    );

    function permissionsOf(
        address _operator,
        address _account,
        uint256 _domain
    ) external view returns (uint256);

    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view returns (bool);

    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view returns (bool);

    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external;

    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}