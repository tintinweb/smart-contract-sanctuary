/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface ChiToken {

    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

contract Chisample{

    ChiToken chi;

    constructor() {
        chi = ChiToken(chi_address);
    }

    address chi_address = 0x063f83affbCF64D7d84d306f5B85eD65C865Dca4;

    modifier discountCHI {

        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
    
    event GasMeasurement(uint gasleft);
    
    mapping(uint => string) map;
    
    function compute(uint start) public {
        
        uint256 gasStart = gasleft();
        emit GasMeasurement(gasStart);
        
        for(uint i = 0 ; i < 10 ; i++){
            map[start + i] = "ahasdfhasdfjhijsdoihjasdbgsadasfjadfjadfjadsf";
        }
        
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        emit GasMeasurement(gasSpent);
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
        emit GasMeasurement((gasSpent + 14154) / 41947);
        
    }
    
    function computeWithoutChi(uint start) public {
        
        for(uint i = 0 ; i < 10 ; i++){
            map[start - i] = "ahasdfhasdfjhijsdoihjasdbgsadasfjadfjadfjadsf";
        }
        
    }

    function destroy() external {
        selfdestruct(msg.sender);
    }

}