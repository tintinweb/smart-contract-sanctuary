/* solhint-disable no-empty-blocks */

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.9;

import "./AddressUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20MintableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
// import "./OwnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
// import "./UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract XLAND is
    Initializable,
    ERC20Upgradeable,
    ERC20MintableUpgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    // OwnableUpgradeable,
    ERC20PermitUpgradeable
    // UUPSUpgradeable
{
    using AddressUpgradeable for address;
    
    // solhint-disable var-name-mixedcase
    string  public VERSION;

    mapping(address => uint256) internal _isBlacklisted;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // note: constructor() required to see https://docs.openzeppelin.com/upgrades/2.6//writing-upgradeable#initializers.
    // constructor() initializer {}

    function initialize(
        address _dexRouter,
        address _antiBot,
        uint256[4] memory _feeSettings
    )
        public initializer
    {
        __ERC20_init(
            "X LAND",
            "XLAND",
            _dexRouter,
            _antiBot,
            _feeSettings
        );
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("X LAND");
        // __UUPSUpgradeable_init();

        _mint(msg.sender, 99999999 * 10 ** decimals());

        initChained();
    }

    function initChained()
        private
    {
        setLogicVersion("2.0.8");
    }

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setLogicVersion(string memory newVersion)
        public onlyOwner
    { VERSION = newVersion; }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }

    // function _authorizeUpgrade(address newImplementation)
    //     internal onlyOwner override
    // {}

    //----------------------------------------------------------------

    function blacklistAddress(address account, uint256 valueTo)
        public onlyOwner
    { _isBlacklisted[account] = valueTo; }

    function isBlacklisted(address account)
        public view
        returns (bool blacklisted, uint256 timeTo)
    { return ((_isBlacklisted[account] > 0), _isBlacklisted[account]); }

    function disabledAntiBot(bool _enable)
        public onlyOwner
    { enableAntiBot = !_enable; }

    function antiBotEngine(address _antiBot)
        public onlyOwner
    {
        antiBot = _antiBot;
        IPinkAntiBot(_antiBot).setTokenOwner(_msgSender());
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount, TransferMethods method)
        internal whenNotPaused override
    {
        require(!(_isBlacklisted[from] > 0) && !(_isBlacklisted[to] > 0), "Blacklisted address");
        
        super._beforeTokenTransfer(from, to, amount, method);
    }
}