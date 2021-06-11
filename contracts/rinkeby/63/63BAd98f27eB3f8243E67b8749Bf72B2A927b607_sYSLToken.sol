// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

///@title sYSL Token contract
///@author Artem Martiukhin
///@notice Second stage contract. sYSL Token. 
contract sYSLToken is ERC20, Ownable, AccessControl{
    ///@notice Hash of minter role for access control
    bytes32 public constant MINTER_ROLE=keccak256("MINTER_ROLE");

    ///@notice Modifier that gives access only for minter
    modifier _isMinter(){
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    ///@notice Perform contaract initial setup
    constructor() public ERC20("sYSL token", "sYSL") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    ///@notice Checks if provided address is minter
    ///@param _addr address that must be checked
    function isMinter(address _addr) external view returns(bool result){
        result=hasRole(MINTER_ROLE, _addr);
        return result;
    }

    ///@dev Available only for minter contract
    ///@param account Choosen account for mintage
    ///@param amount Amount of tokens to mint
    ///@param amount Lock time of the minted tokens
    function mintPurchased(address account, uint amount, uint lockTime) external {
        // TODO: add lock for the transfer function

        _mint(account, amount);
    }


    ///@notice Provides mintage functionality
    ///@dev Available only for minter contract
    ///@param account Choosen account for mintage
    ///@param amount Amount of tokens to mint
    function mintFor(address account, uint amount) public _isMinter{
        _mint(account, amount);
    }

    ///@notice Provides mintage functionality
    ///@dev Available only for minter contract
    ///@param amount Amount of tokens to mint
    function mint(uint amount) public _isMinter{
        _mint(_msgSender(), amount);
    }
    ///@notice Provides burning functionality
    ///@dev Available only for minter contract
    ///@param account Choosen account for burning
    ///@param amount Amount of tokens to burn
    function burnFrom(address account, uint amount) public _isMinter{
        _burn(account, amount);
    }
    ///@notice Provides burning functionality
    ///@dev Available only for minter contract
    ///@param amount Amount of tokens to burn
    function burn(uint amount) public _isMinter{
        _burn(_msgSender(), amount);
    }
    ///@notice Sets minter role
    ///@param _minter Address that will be set as minter
    function setMinter(address _minter) external onlyOwner{
        require(_minter!=address(0), "Null address provided");
        _setupRole(MINTER_ROLE, _minter);
    }
}