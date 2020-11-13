pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./utils/BytesLib.sol";
import "./utils/AddressArrayUtils.sol";
import "./utils/OperatorParams.sol";


/// @title Stake Delegatable
/// @notice A base contract to allow stake delegation for staking contracts.
contract StakeDelegatable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Burnable;
    using BytesLib for bytes;
    using AddressArrayUtils for address[];
    using OperatorParams for uint256;

    ERC20Burnable public token;

    uint256 public initializationPeriod;
    uint256 public undelegationPeriod;

    mapping(address => address[]) public ownerOperators;

    mapping(address => Operator) public operators;

    struct Operator {
        uint256 packedParams;
        address owner;
        address payable beneficiary;
        address authorizer;
    }

    modifier onlyOperatorAuthorizer(address _operator) {
        require(
            operators[_operator].authorizer == msg.sender,
            "Not operator authorizer"
        );
        _;
    }

    /// @notice Gets the list of operators of the specified address.
    /// @return An array of addresses.
    function operatorsOf(address _address) public view returns (address[] memory) {
        return ownerOperators[_address];
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function balanceOf(address _address) public view returns (uint256 balance) {
        return operators[_address].packedParams.getAmount();
    }

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address _operator) public view returns (address) {
        return operators[_operator].owner;
    }

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator) public view returns (address payable) {
        return operators[_operator].beneficiary;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address) {
        return operators[_operator].authorizer;
    }
}
