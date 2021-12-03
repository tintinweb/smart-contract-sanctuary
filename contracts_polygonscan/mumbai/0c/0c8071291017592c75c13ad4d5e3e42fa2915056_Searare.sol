// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Searare is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public timeLock;
    mapping(address => bool) public blackList;
    mapping(address => uint256) public claimLocks;

    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);
    event ChangeTimeLock(uint256 indexed _timeLock);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("TESTING_MARKETPLACE", "TMP");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10**decimals());

        // default time clock in 14 days
        timeLock = 14;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(!blackList[from], "Address is in blackList");
        require(to != address(0), "Receive Address is a zero address");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function version() public pure returns (string memory) {
        return "v1!";
    }

    function addBlackList(address _user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        blackList[_user] = true;
        emit AddedBlackList(_user);
    }

    function removeBlackList(address _user)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        blackList[_user] = false;
        emit RemovedBlackList(_user);
    }

    function changeTimeLock(uint256 _day) public onlyRole(DEFAULT_ADMIN_ROLE) {
        timeLock = _day;
    }

    function claim(address _to, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 current = block.timestamp;
        if (claimLocks[_to] > 0)
            require(
                claimLocks[_to] > current + (timeLock * 1 days),
                "Account is in lock time"
            );

        require(transfer(_to, amount), "Transfer is fail");
        claimLocks[_to] = current;
    }

    function getBlackListByAddress(address _user) public view returns (bool) {
        return blackList[_user];
    }

    function getConfigTimeLock() public view returns (uint256) {
        return timeLock;
    }

    function getClaimLockByUser(address _user)
        public
        view
        returns (uint256, bool)
    {
        uint256 claimLock = claimLocks[_user];
        if (claimLock == 0) return (0, true);
        bool isClaim = claimLock > (timeLock * 1 days) + block.timestamp;
        return (claimLock, isClaim);
    }
}