// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Policy.sol";

contract FactoryStorage is Policy {
    /* ======== STRUCTS ======== */

    struct BondDetails {
        address _payoutToken;
        address _principleToken;
        address _treasuryAddress;
        address _bondAddress;
        address _initialOwner;
        uint256[] _tierCeilings;
        uint256[] _fees;
    }

    /* ======== STATE VARIABLS ======== */
    BondDetails[] public bondDetails;

    address public bondFactory;

    mapping(address => uint256) public indexOfBond;

    /* ======== EVENTS ======== */

    event BondCreation(address treasury, address bond, address _initialOwner);

    /* ======== POLICY FUNCTIONS ======== */

    /**
        @notice pushes bond details to array
        @param _payoutToken address
        @param _principleToken address
        @param _customTreasury address
        @param _customBond address
        @param _initialOwner address
        @param _tierCeilings uint[]
        @param _fees uint[]
        @return _treasury address
        @return _bond address
     */
    function pushBond(
        address _payoutToken,
        address _principleToken,
        address _customTreasury,
        address _customBond,
        address _initialOwner,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees
    ) external returns (address _treasury, address _bond) {
        require(bondFactory == msg.sender, "Not Factory");

        indexOfBond[_customBond] = bondDetails.length;

        bondDetails.push(
            BondDetails({
                _payoutToken: _payoutToken,
                _principleToken: _principleToken,
                _treasuryAddress: _customTreasury,
                _bondAddress: _customBond,
                _initialOwner: _initialOwner,
                _tierCeilings: _tierCeilings,
                _fees: _fees
            })
        );

        emit BondCreation(_customTreasury, _customBond, _initialOwner);
        return (_customTreasury, _customBond);
    }

    /**
        @notice changes factory address
        @param _factory address
     */
    function setFactoryAddress(address _factory) external onlyPolicy {
        bondFactory = _factory;
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