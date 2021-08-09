// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

import "./Ownable.sol";
//Burnable 기능
import "./ERC20Burnable.sol";
//Pausable 기능 
import "./Pausable.sol";
//Permit 기능
import "./draft-ERC20Permit.sol";

import "./ERC20Votes.sol";

//SafeMath
import "./SafeMath.sol";

contract ElmoToken is Context, ERC20, ERC20Burnable, Ownable, Pausable, ERC20Permit, ERC20Votes {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;
    
    constructor()ERC20("ElmoToken", "EMT") ERC20Permit("MyToken"){

        
    }

    //owner에 한해서 to에게 amount만큼을 민트한다. 
    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override onlyOwner{
        // uint256 currentAllowance = allowance(account, _msgSender());
        // require(currentAllowance >= amount, "ERC20 : burn amount exceeds allowance");
        // unchecked {
        //     _approve(account, _msgSender(), currentAllowance - amount);
        // }
        _burn(account, amount);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
        //require(!paused(), "ERC20Pausable:token transfer while paused");
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Votes){
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)internal override (ERC20, ERC20Votes){
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes){
        super._burn(account, amount);
    }

}