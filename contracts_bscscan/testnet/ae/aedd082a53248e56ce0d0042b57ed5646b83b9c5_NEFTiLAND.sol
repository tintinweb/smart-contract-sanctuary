// solhint-disable no-empty-blocks
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

import "./IDEXFactory.sol";
import "./IDEXRouter.sol";
import "./IDEXPair.sol";
import "./IPinkAntiBot.sol";

/// @custom:security-contact [email protected]
contract NEFTiLAND is
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

    address public dexFactory;
    address public dexRouter;
    address public dexPair;

    address internal antiBot;
    bool public enableAntiBot;

    bool internal inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => uint256) internal _isBlacklisted;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // note: constructor() required to see https://docs.openzeppelin.com/upgrades/2.6//writing-upgradeable#initializers.
    // constructor() initializer {}

    function initialize(
        address _dexRouter,
        address _antiBot
    )
        public initializer
    {
        __ERC20_init("X LAND", "XLAND");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("X LAND");
        // __UUPSUpgradeable_init();

        _mint(msg.sender, 99999999 * 10 ** decimals());

        initChained(
            _dexRouter,
            _antiBot
        );
    }

    function initChained(
        address _dexRouter,
        address _antiBot
    )
        private
    {
        setLogicVersion("2.0.6");

        antiBot = _antiBot;
        IPinkAntiBot(_antiBot).setTokenOwner(_msgSender());
        enableAntiBot = true;

        IPancakeRouter02 scDeXRouter = IPancakeRouter02(_dexRouter);
        dexPair = IPancakeFactory(scDeXRouter.factory()).createPair(address(this), scDeXRouter.WETH());
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

    event Log(address _addr);
    function _beforeTokenTransfer(address from, address to, uint256 amount, TransferMethods method)
        internal whenNotPaused override
    {
        require(!(_isBlacklisted[from] > 0) && !(_isBlacklisted[to] > 0), "Blacklisted address");
        if (enableAntiBot && method == TransferMethods.FROM) { IPinkAntiBot(antiBot).onPreTransferCheck(from, to, amount); }
        if (to.isContract()) {
            // if (IPancakeRouter02(to).WETH() != address(0)) { 
            //     revert("ERC20 token transfer to ERC20 token is not allowed");
            // }
            emit Log(IPancakeRouter02(to).WETH());
        }   

        super._beforeTokenTransfer(from, to, amount, method);
    }
}