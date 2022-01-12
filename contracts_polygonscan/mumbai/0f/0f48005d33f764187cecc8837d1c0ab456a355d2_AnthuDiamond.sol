// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract AnthuDiamond is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public claimDuration;
    mapping(address => bool) public blackList;
    mapping(address => uint256) public claimLocks;

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
    event ChangeClaimDuration(uint256 indexed _claimDuration);
    event Claim(address indexed _claimer, uint256 amout);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner) public initializer {
        __ERC20_init("ANTHU DIAMOND", "ATD");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _owner);

        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _mint(_owner, 1000000000 * 10**decimals());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function transferAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_admin != address(0), "ZERO_ADDRESS");
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }
    /**
     * @dev function add condition when transfer, check transferred is in blacklist
     * @param _from sender's address
     * @param _to receiver's address
     * @param _amount number of token to transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override whenNotPaused {
        require(!blackList[_from], "ADDRESS_BLACKLIST");
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * @dev function add user into blacklist
     * @param _user account to add
     */
    function addBlackList(address _user) public onlyRole(OPERATOR_ROLE) {
        blackList[_user] = true;
        emit AddedBlackList(_user);
    }

    /**
     * @dev function remove user in blacklist
     * @param _user account to remove
     */
    function removeBlackList(address _user)
        public
        onlyRole(OPERATOR_ROLE)
    {
        blackList[_user] = false;
        emit RemovedBlackList(_user);
    }
    /**
     * @dev check user in blacklist
     * @param _user account to check
     */
    function isInBlackList(address _user) public view returns (bool) {
        return blackList[_user];
    }

    /**
     * @dev function override decimals, set new value
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev function return current verion of smart contract
     */
    function version() public pure returns (string memory) {
        return "v1.0!";
    }
}