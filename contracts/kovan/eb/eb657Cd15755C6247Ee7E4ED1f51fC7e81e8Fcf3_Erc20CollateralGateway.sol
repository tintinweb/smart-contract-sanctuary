/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// File contracts/libs/Fragments.sol

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Fragments {
    enum TypeOf { SINGLE_VALUE, SET }

    struct Instance {
        TypeOf typeOf;
        bool initialized;
        uint256[] values;
        mapping(uint256 => uint256) indexes;
    }

    modifier onlyInitialized(Instance storage self) {
        require(self.initialized == true, "Fragments: not initialized");
        _;
    }

    function init(Instance storage self, TypeOf typeOf) internal returns (bool) {
        require(self.initialized == false, "Fragments: already initialized");
        self.typeOf = typeOf;
        self.initialized = true;
        return true;
    }

    function add(Instance storage self, uint256[] calldata values) internal onlyInitialized(self) returns (bool) {
        if (self.typeOf == TypeOf.SINGLE_VALUE) {
            require(values.length == 1, "Fragments: invalid number of values");
            self.values[0] += values[0];
        } else {
            for (uint256 i; i < values.length; i++) {
                require(self.indexes[values[i]] == 0, "Fragments: value already exists in instance");
                self.values.push(values[i]);
                self.indexes[values[i]] = self.values.length;
            }
        }
        return true;
    }

    function remove(Instance storage self, uint256[] calldata values) internal onlyInitialized(self) returns (bool) {
        if (self.typeOf == TypeOf.SINGLE_VALUE) {
            require(values.length == 1, "Fragments: invalid number of values");
            self.values[0] -= values[0];
        } else {
            for (uint256 i; i < values.length; i++) {
                require(self.indexes[values[i]] != 0, "Fragments: value doesn't exist in instance");
                delete (self.values[self.indexes[values[i]] - 1]);
                self.indexes[values[i]] = 0;
            }
        }
        return true;
    }

    function empty(Instance storage self) internal onlyInitialized(self) returns (bool) {
        if (self.typeOf == TypeOf.SINGLE_VALUE) {
            self.values[0] = 0;
        } else {
            for (uint256 i = 0; i < self.values.length; i++) {
                self.indexes[self.values[i]] = 0;
            }
            delete self.values;
        }
        return true;
    }

    function length(Instance storage self) internal view returns (uint256) {
        return self.values.length;
    }

    function get(Instance storage self, uint256 i) internal view returns (uint256) {
        return self.values[i];
    }

    function contains(Instance storage self, uint256 value) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}


// File contracts/CollateralGatewayInterface.sol


pragma solidity ^0.8.0;

interface CollateralGatewayInterface {
    // NON-CONSTANT FUNCTIONS

    /**
     * @notice Transfer collateral to address
     * @param collateral The collateral to transfer
     * @param values The collateral values to transfer
     * @return True if succeeds, otherwise reverts
     */
    function transfer(
        address collateral,
        address to,
        uint256[] calldata values
    ) external returns (bool);

    /**
     * @notice Transfer collateral from address to address
     * @param collateral The collateral to transfer
     * @param from The account to transfer the collateral from
     * @param to The account to transfer the collateral to
     * @param values The collateral values to transfer
     * @return True if succeeds, otherwise reverts
     */
    function transferFrom(
        address collateral,
        address from,
        address to,
        uint256[] calldata values
    ) external returns (bool);
}


// File @paulrberg/contracts/token/erc20/[email protected]


pragma solidity ^0.8.0;

/// @title Erc20Storage
/// @author Paul Razvan Berg
/// @notice The storage interface of an Erc20 contract.
abstract contract Erc20Storage {
    /// @notice Returns the number of decimals used to get its user representation.
    uint8 public decimals;

    /// @notice Returns the name of the token.
    string public name;

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    string public symbol;

    /// @notice Returns the amount of tokens in existence.
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}


// File @paulrberg/contracts/token/erc20/[email protected]


pragma solidity ^0.8.0;

/// @title Erc20Interface
/// @author Paul Razvan Berg
/// @notice Contract interface adhering to the Erc20 standard.
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/IERC20.sol
abstract contract Erc20Interface is Erc20Storage {
    /// CONSTANT FUNCTIONS ///
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /// EVENTS ///
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 amount);
}


// File contracts/Erc20CollateralGateway.sol


pragma solidity ^0.8.0;


contract Erc20CollateralGateway is CollateralGatewayInterface {
    /// @inheritdoc CollateralGatewayInterface
    function transfer(
        address collateral,
        address to,
        uint256[] calldata values
    ) external override returns (bool) {
        Erc20Interface(collateral).transferFrom(msg.sender, to, values[0]);
        return true;
    }

    /// @inheritdoc CollateralGatewayInterface
    function transferFrom(
        address collateral,
        address from,
        address to,
        uint256[] calldata values
    ) external override returns (bool) {
        Erc20Interface(collateral).transferFrom(from, to, values[0]);
        return true;
    }
}