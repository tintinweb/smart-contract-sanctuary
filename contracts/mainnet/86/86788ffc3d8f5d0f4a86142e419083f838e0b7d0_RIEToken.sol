// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


import "./ERC20Permit.sol";
import "./Ownable.sol";


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/


/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract RIEToken is ERC20Permit, Ownable {
    using SafeMath for uint256;
    //Define total Distribution Pilot Program Supply
    uint256 private _DistPilotSupply = 5.5e8 ether;
    
    //Define total devTeam allocated token funds
    uint256 private _devTeamSupply = 3.5e8 ether;
    
    //Define total bounty allocated token funds
    uint256 private _bountySupply = 0.5e8 ether;

    //Define owner address funds 
    uint256 private _ownerSupply = 1.55e9 ether;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner) ERC20("Ralie Token", "RIE") EIP712("Ralie Token", "1") {
                 
        transferOwnership(_owner);
        _mint(_owner, _ownerSupply);
        _mint(0x0D82fB6990d7dC8A22f79623c3A662db099a50be, _DistPilotSupply);
        _mint(0xc307c195b7380656598e992cf104cF1671B35476, _devTeamSupply);
        _mint(0x801e2ab2197c1a13bB39335de47211a447Ff875F, _bountySupply);

    }


    function mintbyOwner(address account, uint256 amount) public virtual onlyOwner{
        require(totalSupply().add(amount) <= 2.5e9 ether, "ERC20: amount higher than total supply");
        _mint(account, amount);
    }
    
    /**
    * @dev Extension of {ERC20} that allows token holders to destroy both their own
    * tokens and those that they have an allowance for, in a way that can be
    * recognized off-chain (via event analysis).
    */
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

}