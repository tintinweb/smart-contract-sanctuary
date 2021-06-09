// SPDX-License-Identifier: MIT


pragma solidity ^0.7.0;

import "./Context.sol";
import "./ERC20CappedUnburnable.sol";
import "./ERC20Unburnable.sol";
import "./ERC20PausableUnburnable.sol";

contract LBCToken is Context, ERC20CappedUnburnable {

    /*
    ** Global State
    */
    bool public initialized; // default : false

    /*
    ** Addresses
    */
    address public _deployingAddress; // should be changed to multisig contract address
    address public _pauserAddress; // should be deployer's
    address public _minterAddress; // should be ico's address then poe's
    address public _reserveAddress; // should be multisig then humble reserve

    /*
    ** Events
    */
    event InitializedContract(address indexed reserveAddress);
    event ChangedMinterAddress(address indexed minterAddress, address indexed changerAddress);
    event ChangedPauserAddress(address indexed pauserAddress, address indexed changerAddress);
    event ChangedReserveAddress(address indexed reserveAddress, address indexed changerAddress);
    event ChangedDeployerAddress(address indexed deployerAddress, address indexed changerAddress);


    constructor(
        string memory name,
        string memory symbol
    )
    ERC20Unburnable(name, symbol)
    ERC20CappedUnburnable(300000000000000000000000000)
    {
        _deployingAddress = msg.sender;
    }

    /*
    ** Initializes the contract address and affects addresses to their roles.
    */
    function init(
        address minterAddress,
        address pauserAddress,
        address reserveAddress
    )
    public
    isNotInitialized
    onlyDeployingAddress
    {
        require(minterAddress != address(0), "_minterAddress cannot be 0x");
        require(pauserAddress != address(0), "_pauserAddress cannot be 0x");
        require(reserveAddress != address(0), "_reserveAddress cannot be 0x");

        _minterAddress = minterAddress;
        _pauserAddress = pauserAddress;
        _reserveAddress = reserveAddress;

        initialized = true;

        emit InitializedContract(reserveAddress);
    }

    /*
    ** Mint function that can only be called by minter address and mints a specified amount and sends it to an address
    */
    function mint(address to, uint256 amount)
    public
    onlyMinterAddress
    virtual
    returns (bool) {
       _mint(to, amount);
       return true;
    }

    /*
    ** Freeze function that stops transactions and can only be called by pauser address
    */
    function pause()
    public
    onlyPauserAddress
    virtual {
        _pause();
    }

    /*
    ** Unfreeze function that resumes transactions and can only be called by pauser address
    */
    function unpause()
    public
    onlyPauserAddress
    virtual {
        _unpause();
    }

    /*
    ** Changes the address with pause role and can only be called by previous pauser address
    */
    function changePauser(address newPauserAddress)
    public
    onlyDeployingAddress
    whenNotPaused
    {
        _pauserAddress = newPauserAddress;
        emit ChangedPauserAddress(newPauserAddress, _msgSender());
    }

    /*
    ** Changes the address with minter role and can only be called by previous minter address
    */
    function changeMinter(address newMinterAddress)
    public
    onlyDeployingAddress
    whenNotPaused
    {
        _minterAddress = newMinterAddress;
        emit ChangedMinterAddress(newMinterAddress, _msgSender());
    }

    /*
    ** Changes the address with deployer role and can only be called by deployer
    */
    function changeDeployer(address newDeployerAddress)
    public
    onlyDeployingAddress
    {
        _deployingAddress = newDeployerAddress;
        emit ChangedDeployerAddress(_deployingAddress, _msgSender());
    }

    /*
    ** Checks if the sender is the minter controller address
    */
    modifier onlyDeployingAddress() {
        require(msg.sender == _deployingAddress, "Only the deploying address can call this method.");
        _;
    }

    /*
    ** Checks if the sender is the minter controller address
    */
    modifier onlyMinterAddress() {
        require(msg.sender == _minterAddress, "Only the minter address can call this method.");
        _;
    }

    /*
    ** Checks if the sender is the pauser controller address
    */
    modifier onlyPauserAddress() {
        require(msg.sender == _pauserAddress, "Only the pauser address can call this method.");
        _;
    }

    /*
    ** Checks if the contract hasn't already been initialized
    */
    modifier isNotInitialized() {
        require(initialized == false, "Contract is already initialized.");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20CappedUnburnable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}