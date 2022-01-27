// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {ERC20} from "./ERC20.sol";

import {ILooksRareToken} from "./ILooksRareToken.sol";

/**
 * @title LooksRareToken (LOOKS)
 * @notice
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRAR'''''''''''''''''''''''''''''''''''OOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKS:.                                        .;OOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOO,.                                            .,KSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRAREL'                ..',;:LOOKS::;,'..                'RARELOOKSRARELOOKSR
LOOKSRARELOOKSRAR.              .,:LOOKSRARELOOKSRARELO:,.              .RELOOKSRARELOOKSR
LOOKSRARELOOKS:.             .;RARELOOKSRARELOOKSRARELOOKSl;.             .:OOKSRARELOOKSR
LOOKSRARELOO;.            .'OKSRARELOOKSRARELOOKSRARELOOKSRARE'.            .;KSRARELOOKSR
LOOKSRAREL,.            .,LOOKSRARELOOK:;;:"""":;;;lELOOKSRARELO,.            .,RARELOOKSR
LOOKSRAR.             .;okLOOKSRAREx:.              .;OOKSRARELOOK;.             .RELOOKSR
LOOKS:.             .:dOOOLOOKSRARE'      .''''..     .OKSRARELOOKSR:.             .LOOKSR
LOx;.             .cKSRARELOOKSRAR'     'LOOKSRAR'     .KSRARELOOKSRARc..            .OKSR
L;.             .cxOKSRARELOOKSRAR.    .LOOKS.RARE'     ;kRARELOOKSRARExc.             .;R
LO'             .;oOKSRARELOOKSRAl.    .LOOKS.RARE.     :kRARELOOKSRAREo;.             'SR
LOOK;.            .,KSRARELOOKSRAx,     .;LOOKSR;.     .oSRARELOOKSRAo,.            .;OKSR
LOOKSk:.            .'RARELOOKSRARd;.      ....       'oOOOOOOOOOOxc'.            .:LOOKSR
LOOKSRARc.             .:dLOOKSRAREko;.            .,lxOOOOOOOOOd:.             .ARELOOKSR
LOOKSRARELo'             .;oOKSRARELOOxoc;,....,;:ldkOOOOOOOOkd;.             'SRARELOOKSR
LOOKSRARELOOd,.            .,lSRARELOOKSRARELOOKSRARELOOKSRkl,.            .,OKSRARELOOKSR
LOOKSRARELOOKSx;.            ..;oxELOOKSRARELOOKSRARELOkxl:..            .:LOOKSRARELOOKSR
LOOKSRARELOOKSRARc.              .':cOKSRARELOOKSRALOc;'.              .ARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELl'                 ...'',,,,''...                 'SRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOo,.                                          .,OKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSx;.                                      .;xOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLO:.                                  .:SRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKl.                              .lOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRo'.                        .'oLOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARd;.                    .;xRELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELO:.                .:kRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKl.            .cOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRo'        'oLOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARE,.  .,dRELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
 */
contract LooksRareToken is ERC20, Ownable, ILooksRareToken {
    uint256 private immutable _SUPPLY_CAP;

    /**
     * @notice Constructor
     * @param _premintReceiver address that receives the premint
     * @param _premintAmount amount to premint
     * @param _cap supply cap (to prevent abusive mint)
     */
    constructor(
        address _premintReceiver,
        uint256 _premintAmount,
        uint256 _cap
    ) ERC20("LooksRare Token", "LOOKS") {
        require(_cap > _premintAmount, "LOOKS: Premint amount is greater than cap");
        // Transfer the sum of the premint to address
        _mint(_premintReceiver, _premintAmount);
        _SUPPLY_CAP = _cap;
    }

    /**
     * @notice Mint LOOKS tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view override returns (uint256) {
        return _SUPPLY_CAP;
    }
}