// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./BEP20.sol";

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title MinterRole
 * @dev Implementation of the {MinterRole} interface.
 */
contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// GoldGrainToken
contract GoldGrainToken is BEP20, MinterRole {
    address public lpToken;
    address public _operator;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    bool private tradingOpen = false;
    
    // Max holding rate in basis point. (default is 1% of total supply)
    // Transfers cannot result in a balance higher than the maxholdingrate*total supply
    // Except if the owner (masterchef) is interacting. Users would not be able to harvest rewards in edge cases
    // such as if an user has more than maxholding to harvest without this exception.
    // Addresses in the antiwhale exclude list can receive more too. This is for the liquidity pools and the token itself
    uint16 public maxHoldingRate = 100; // INMUTABLE 

    // Enable MaxHolding mechanism
    bool private _maxHoldingEnable = true; // INMUTABLE

    // Addresses excluded from fees
    mapping (address => bool) private _isExcludedFromFee;

    // Addresses that are excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    // GGRAIN MOD - ADD WHITELIST MAP
    mapping(address=>bool) isWhitelisted;

    event MaxHoldingEnableUpdated(address indexed operator, bool enabled);

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }
    
    /// @dev Apply antiwhale only if the owner (masterchef) isn't interacting.
    /// If the receiver isn't excluded from antiwhale,
    /// check if it's balance is over the max Holding otherwise the second condition would end up with an underflow
    /// and that it's balance + the amount to receive doesn't exceed the maxholding. This doesn't account for transfer tax.
    /// if any of those two condition apply, the transfer will be rejected with the correct error message
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        // Is maxHolding enabled?
        if(_maxHoldingEnable) {
            if (maxHolding() > 0 && sender != owner() && recipient != owner()) {
                if ( _excludedFromAntiWhale[recipient] == false ) {
                    require(amount <= maxHolding() - balanceOf(recipient) && balanceOf(recipient) <= maxHolding(), "GGRAIN::antiWhale: Transfer amount would result in a balance bigger than the maxHoldingRate");
                }
            }
        }
        
        _;
    }

    /**z
     * @notice Constructs the GOLDEN GRAIN token contract.
     */
    constructor() public BEP20("GOLDEN GRAIN", "GGRAIN") {
        _operator = msg.sender;        
    }

    // GGRAIN MOD - ADD ROUTER WHITELIST UTILS
    function whiteListRouter(address _token) public {
        require(_operator == msg.sender, 'GGRAIN: ONLY FEE TO SETTER');
        require(!isWhitelisted[_token], "GGRAIN: ALREADY WHITELISTED");
        isWhitelisted[_token] = true;
    }

    function removeFromWhiteList(address _token) public {
        require(_operator == msg.sender, 'GGRAIN: ONLY FEE TO SETTER');
        require(isWhitelisted[_token], "GGRAIN: ALREADY REMOVED FROM WHITELIST");
        isWhitelisted[_token] = false;
    }

    function whiteListed(address _token) public view returns (bool) {
        return isWhitelisted[_token];
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of GOLDEN GRAIN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // console.log("sender", sender);
        require(amount > 0, "Transfer amount must be greater than zero");

        if (isWhitelisted[sender] || sender == owner() || recipient == lpToken || sender == lpToken) {
            super._transfer(sender, recipient, amount);
        } else {
            require(tradingOpen == true, "GOLDEN GRAIN TRADING CLOSED");    
        }
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    // Return actual supply of rice
    function ggrainSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(BURN_ADDRESS));
    }
    
    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        return totalSupply().mul(maxHoldingRate).div(10000);
    }

    /**
     * @dev Open trading (PCS) onlyOperator
     */
    function openTrading() public onlyOperator {
        // Can open trading only once!
        require(tradingOpen != true, "GGRAIN: Trading not yet open.");
        tradingOpen = true;
    }
    
    /** 
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account) public onlyOperator {
        _excludedFromAntiWhale[_account] = true;
    }

    /**
     * @dev Add to exclude from fee.
     * Can only be called by the current operator.
     */
    function setExcludeFromFee(address _account, bool _trueOrFalse) public onlyOperator {
        _isExcludedFromFee[_account] = _trueOrFalse;
    }

    /**
     * @dev Transfers/Sets lpToken address to a new address (`newLpToken`).
     * Can only be called by the current operator.
     */
    function transferLpToken(address newLpToken) public onlyOperator {
        // Can transfer LP only once!
        require(lpToken == address(0), "GGRAIN: LP Token Transfer can be only be set once");
        lpToken = newLpToken;
    }

    /** NO NEED TO CHANGE MAX HOLDING ENABLED
     * @dev Enable / Disable Max Holding Mechanism.
     * Can only be called by the current operator.
     */
    function updateMaxHoldingEnable(bool _enabled) public onlyOperator {
        emit MaxHoldingEnableUpdated(msg.sender, _enabled);
        _maxHoldingEnable = _enabled;
    }
    // To receive BNB from SwapRouter when swapping
    receive() external payable {}
}