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
    address public operator;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    mapping(address => bool) public blackListed;
    // Max holding rate in basis point. (default is 1% of total supply)
    // Transfers cannot result in a balance higher than the maxholdingrate*total supply
    // Except if the owner (masterchef) is interacting. Users would not be able to harvest rewards in edge cases
    // such as if an user has more than maxholding to harvest without this exception.
    // Addresses in the antiwhale exclude list can receive more too. This is for the liquidity pools and the token itself
    uint16 public maxHoldingRate = 100; // INMUTABLE 

    // Enable MaxHolding mechanism
    bool public maxHoldingEnable = true; // INMUTABLE

    // Addresses that are excluded from antiWhale
    mapping(address => bool) public excludedFromAntiWhale;

    event MaxHoldingEnableUpdated(address indexed operator, bool enabled);

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(operator == msg.sender, "operator: caller is not the operator");
        _;
    }
    
    /// @dev Apply antiwhale only if the owner (masterchef) isn't interacting.
    /// If the receiver isn't excluded from antiwhale,
    /// check if it's balance is over the max Holding otherwise the second condition would end up with an underflow
    /// and that it's balance + the amount to receive doesn't exceed the maxholding. This doesn't account for transfer tax.
    /// if any of those two condition apply, the transfer will be rejected with the correct error message
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        // Is maxHolding enabled?
        if(maxHoldingEnable) {
            if (maxHolding() > 0 && sender != owner() && recipient != owner()) {
                if ( excludedFromAntiWhale[recipient] == false ) {
                    require(amount <= maxHolding() - balanceOf(recipient) && balanceOf(recipient) <= maxHolding(), "GGRAIN::antiWhale: Transfer amount would result in a balance bigger than the maxHoldingRate");
                }
            }
        }
        
        _;
    }

    /**z
     * @notice Constructs the GOLDEN GRAIN token contract.
     */
    constructor() public BEP20("GoldenGrain", "GGRAIN") {
        operator = msg.sender;    
        setExcludedFromAntiWhale(BURN_ADDRESS);
        setExcludedFromAntiWhale(address(this));
        setExcludedFromAntiWhale(address(msg.sender));    
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of GOLDEN GRAIN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // console.log("sender", sender);
        require(amount > 0, "Transfer amount must be greater than zero");
        require( !blackListed[sender] && !blackListed[recipient], "The black list address");

        super._transfer(sender, recipient, amount);
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
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account) public onlyOperator {
        excludedFromAntiWhale[_account] = true;
    }

    function setBlacklist(address[] memory addresses, bool value) public onlyOperator {
        for (uint i = 0; i < addresses.length; i++) {
            blackListed[addresses[i]] = value;
        }
    }

    function transferOperator(address _operator) public onlyOperator {
        require(_operator != address(0), "zero address");

        operator = _operator;
    }
    /** NO NEED TO CHANGE MAX HOLDING ENABLED
     * @dev Enable / Disable Max Holding Mechanism.
     * Can only be called by the current operator.
     */
    function updateMaxHoldingEnable(bool _enabled) public onlyOperator {
        emit MaxHoldingEnableUpdated(msg.sender, _enabled);
        maxHoldingEnable = _enabled;
    }

    function updateMaxHoldingRate(uint16 _rate) public onlyOperator {
        maxHoldingRate = _rate;
    }

    // To receive BNB from SwapRouter when swapping
    receive() external payable {}
}