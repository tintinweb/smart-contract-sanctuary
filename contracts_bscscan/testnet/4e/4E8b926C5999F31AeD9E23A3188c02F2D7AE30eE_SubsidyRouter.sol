// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Policy.sol";

interface IBond {
    function paySubsidy() external returns (uint256);
}

// Immutable contract routes between bonds and subsidy controllers
// Allows for subsidies on bonds offered through bond contracts
contract SubsidyRouter is Policy {
    mapping(address => address) public bondForController; // maps bond contract managed by subsidy controller

    /**
     *  @notice subsidy controller fetches and resets payout counter
     *  @return uint
     */
    function getSubsidyInfo() external returns (uint256) {
        require(
            bondForController[msg.sender] != address(0),
            "Address not mapped"
        );
        return IBond(bondForController[msg.sender]).paySubsidy();
    }

    /**
     *  @notice add new subsidy controller for bond contract
     *  @param _bond address
     *  @param _subsidyController address
     */
    function addSubsidyController(address _bond, address _subsidyController)
        external
        onlyPolicy
    {
        require(_bond != address(0));
        require(_subsidyController != address(0));

        bondForController[_subsidyController] = _bond;
    }

    /**
     *  @notice remove subsidy controller for bond contract
     *  @param _subsidyController address
     */
    function removeSubsidyController(address _subsidyController)
        external
        onlyPolicy
    {
        bondForController[_subsidyController] = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPolicy {
    function policy() external view returns (address);

    function renouncePolicy() external;

    function pushPolicy(address newPolicy_) external;

    function pullPolicy() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IPolicy.sol";

contract Policy is IPolicy {
    address internal _policy;
    address internal _newPolicy;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _policy = msg.sender;
        emit OwnershipTransferred(address(0), _policy);
    }

    function policy() public view override returns (address) {
        return _policy;
    }

    modifier onlyPolicy() {
        require(_policy == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renouncePolicy() public virtual override onlyPolicy {
        emit OwnershipTransferred(_policy, address(0));
        _policy = address(0);
    }

    function pushPolicy(address newPolicy_) public virtual override onlyPolicy {
        require(
            newPolicy_ != address(0),
            "Ownable: new owner is the zero address"
        );
        _newPolicy = newPolicy_;
    }

    function pullPolicy() public virtual override {
        require(msg.sender == _newPolicy);
        emit OwnershipTransferred(_policy, _newPolicy);
        _policy = _newPolicy;
    }
}