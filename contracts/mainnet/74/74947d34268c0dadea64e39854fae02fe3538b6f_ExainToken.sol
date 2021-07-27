// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

/*
import "OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/[email protected]/contracts/security/Pausable.sol";
import "OpenZeppelin/[email protected]/contracts/access/AccessControl.sol";
*/


contract ExainToken is  ERC20, Pausable, AccessControl  {
    mapping(address => bool) whitelist;
    uint256 immutable private _cap;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bool private _transferPaused;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event TransferPaused(address account);
    event TransferUnpaused(address account);  

    constructor (string memory name, string memory symbol, uint256 cap_, address admin) ERC20(name, symbol) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);  //can grant/revole all the roles
        _setupRole(OWNER_ROLE, msg.sender);        
        allow(msg.sender);   //whitelist the owner
        _transferPaused = true;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }    

    modifier whenTransferNotPaused() {
        require(!transferPaused(), "Transfer paused");
        _;
    }    

    modifier whenTransferPaused() {
        require(transferPaused(), "Transfer not paused");
        _;
    }        
    
    function decimals() public view override returns (uint8) {
        return 0;
    }

    function cap() public view  returns (uint256) {
        return _cap;
    }    


    function mint(address account, uint256 amount) public whenNotPaused returns (bool)  {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not the owner");
        require(ERC20.totalSupply() + amount <= cap(), "Cap exceeded");
        _mint(account, amount);
        //token_holders.push(account);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not the owner");
        _transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }    


    function burnFrom(address account, uint256 amount) public whenNotPaused returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the admin");
        _burn(account, amount);
        return true;
    }

    //grant KYC
    function allow(address _address) public whenNotPaused returns (bool){
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not the owner");
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
        return true;        
    }

    //revoke KYC
    function deny(address _address) public  whenNotPaused returns (bool){
        require(hasRole(OWNER_ROLE, msg.sender), "Caller is not the owner");        
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
        return true;        
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }    

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the admin");          
        _pause();
    }    
    
    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the admin");                  
        _unpause();
    }

    function transferPaused() public view returns (bool) {
        return _transferPaused;
    }

    function transferPause() public whenTransferNotPaused {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the admin"); 
        _transferPaused = true;
        emit TransferPaused(_msgSender());
    }    

    function transferUnpause() public whenTransferPaused {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the admin"); 
        _transferPaused = false;
        emit Unpaused(_msgSender());
    }



    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)){
            require(isWhitelisted(to) , "The receiver's account doesn't have the KYC");
        }
        else if (to != address(0)){
            require(!transferPaused(), "Token transfer paused");
            require(isWhitelisted(to) , "The receiver's account doesn't have the KYC");
            require(isWhitelisted(from) , "The sender's account doesn't have the KYC");            

        }
    }        

}