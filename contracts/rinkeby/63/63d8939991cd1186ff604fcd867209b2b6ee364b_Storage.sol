/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Storage {

    mapping(uint256 => bytes) private wizardTraits;
    
    function storeWizardTraits(uint256[] calldata ids, uint16[6][] calldata traits) public {
        for(uint256 id=0; id< ids.length;id++){
            wizardTraits[id] = encode(traits[id][0],traits[id][1],traits[id][2],traits[id][3],traits[id][4],traits[id][5]);
        }
    }
    
    function getWizardTraits(uint256 id) public view returns(uint16 t0, uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5){
        return decode(wizardTraits[id]);
    }
    
    function getWizardTraitsEncoded(uint256 id) public view returns(bytes memory){
        return wizardTraits[id];
    }
    
    function encode( uint16 t0, uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) public view returns(bytes memory) {
        bytes memory data = new bytes(14);
        
        assembly {
            
            mstore(
                add(
                    data,
                    32
                ),
                32
            )
            
           mstore(
                add(
                    data,
                    34
                ),
                shl(240, t0)
            )
            mstore(
                add(
                    data,
                    36
                ),
                shl(240, t1)
            )
            mstore(
                add(
                    data,
                    38
                ),
                shl(240,t2)
            )
            mstore(
                add(
                    data,
                    40
                ),
                shl(240, t3)
            )
             mstore(
                add(
                    data,
                    42
                ),
                shl(240,t4)
            )
             mstore(
                add(
                    data,
                    44
                ),
                shl(240,t5)
            )
            
            
        }
        
        return data;
    }
    function decode(bytes memory data) public view returns(uint16 t0, uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) {
        assembly {
            let len := mload(
                add(
                    data,
                    0
                )
            )
            
            t0 := mload(
                add(
                    data,
                    4
                )
            )
            
            t1 := mload(
                add(
                    data,
                    6
                )
            )
            
            t2 := mload(
                add(
                    data,
                    8
                )
            )
            
            t3 := mload(
                add(
                    data,
                    10
                )
            )
            
             t4 := mload(
                add(
                    data,
                    12
                )
            )
            t5 := mload(
                add(
                    data,
                    14
                )
            )
        }
    }
    
}