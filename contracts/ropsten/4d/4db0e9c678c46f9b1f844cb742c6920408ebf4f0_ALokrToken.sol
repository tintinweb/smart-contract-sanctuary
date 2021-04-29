// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "Initializable.sol";
import "AccessControlUpgradeable.sol";
import "ERC20Upgradeable.sol";
import "PausableUpgradeable.sol";
import "ILockerUser.sol";
import "Ilocker.sol";
contract ALokrToken is ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable, ILockerUser {

    string constant NAME    = 'ALokr';
    string constant SYMBOL  = 'ALKR';
    uint8 constant DECIMALS  = 18;
    uint256 constant TOTAL_SUPPLY = 100_000_000 * 10**uint256(DECIMALS);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); //Pauser can pause/unpause
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE"); //Whitelisted addresses can transfer token when paused
    bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE"); //Blacklisted addresses can not transfer token and their tokens can't be transferred by others

    ILocker public override locker; 

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    modifier onlyPauser(){
        require(hasRole(PAUSER_ROLE, _msgSender()), "!pauser");
        _;
    }

    function initialize() external initializer {
        __ALokrToken_init();
    }

    function __ALokrToken_init() internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(NAME, SYMBOL);
        __Pausable_init_unchained();
        __AccessControl_init_unchained();
        __ALokrToken_init_unchained();
    }

    function __ALokrToken_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(WHITELISTED_ROLE, _msgSender());
        _mint(_msgSender(), TOTAL_SUPPLY);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused() || hasRole(WHITELISTED_ROLE, _msgSender()), "transfers paused");
        require(!hasRole(BLACKLISTED_ROLE, _msgSender()), "sender blacklisted");
        require(!hasRole(BLACKLISTED_ROLE, from), "from blacklisted");

        if (address(locker) != address(0)) {
            // expected to revert if from or to address is banned
            // return values are not used in curren version of locker
            locker.lockOrGetPenalty(from, to); 
        }        
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    function setLocker(address _locker) external onlyAdmin() {
        locker = ILocker(_locker);
    }

}