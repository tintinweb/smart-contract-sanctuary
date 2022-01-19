/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity ^0.7.0;


library BatchVerifier {
    function GroupOrder ()
        public pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }

    function getProofEntropy(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint proofNumber
    )
        internal pure returns (uint256)
    {
        
        return uint(
            keccak256(
                abi.encodePacked(
                    in_proof[proofNumber*8 + 0], in_proof[proofNumber*8 + 1], in_proof[proofNumber*8 + 2], in_proof[proofNumber*8 + 3],
                    in_proof[proofNumber*8 + 4], in_proof[proofNumber*8 + 5], in_proof[proofNumber*8 + 6], in_proof[proofNumber*8 + 7],
                    proof_inputs[proofNumber]
                )
            )
        ) >> 3;
    }

    function accumulate(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs, 
        uint256 num_proofs
    ) internal view returns (
        bool success,
        uint256[] memory proofsAandC,
        uint256[] memory inputAccumulators
    ) {
        uint256 q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 numPublicInputs = proof_inputs.length / num_proofs;
        uint256[] memory entropy = new uint256[](num_proofs);
        inputAccumulators = new uint256[](numPublicInputs + 1);

        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            if (proofNumber == 0) {
                entropy[proofNumber] = 1;
            } else {
                
                
                entropy[proofNumber] = getProofEntropy(in_proof, proof_inputs, proofNumber);
            }
            require(entropy[proofNumber] != 0, "Entropy should not be zero");
            
            inputAccumulators[0] = addmod(inputAccumulators[0], entropy[proofNumber], q);
            for (uint256 i = 0; i < numPublicInputs; i++) {
                require(proof_inputs[proofNumber * numPublicInputs + i] < q, "INVALID_INPUT");
                
                inputAccumulators[i+1] = addmod(inputAccumulators[i+1], mulmod(entropy[proofNumber], proof_inputs[proofNumber * numPublicInputs + i], q), q);
            }
            
        }

        
        uint256[3] memory mul_input;

        

        proofsAandC = new uint256[](num_proofs*2 + 2);

        proofsAandC[0] = in_proof[0];
        proofsAandC[1] = in_proof[1];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            require(entropy[proofNumber] < q, "INVALID_INPUT");
            mul_input[0] = in_proof[proofNumber*8];
            mul_input[1] = in_proof[proofNumber*8 + 1];
            mul_input[2] = entropy[proofNumber];
            assembly {
                
                
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, mul_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
            proofsAandC[proofNumber*2] = mul_input[0];
            proofsAandC[proofNumber*2 + 1] = mul_input[1];
        }

        

        uint256[4] memory add_input;

        add_input[0] = in_proof[6];
        add_input[1] = in_proof[7];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            mul_input[0] = in_proof[proofNumber*8 + 6];
            mul_input[1] = in_proof[proofNumber*8 + 7];
            mul_input[2] = entropy[proofNumber];
            assembly {
                
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }

            assembly {
                
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
        }

        proofsAandC[num_proofs*2] = add_input[0];
        proofsAandC[num_proofs*2 + 1] = add_input[1];
    }

    function prepareBatches(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory inputAccumulators
    ) internal view returns (
        bool success,
        uint256[4] memory finalVksAlphaX
    ) {
        
        
        uint256[4] memory add_input;
        uint256[3] memory mul_input;

        
        for (uint256 i = 0; i < inputAccumulators.length; i++) {
            mul_input[0] = vk_gammaABC[2*i];
            mul_input[1] = vk_gammaABC[2*i + 1];
            mul_input[2] = inputAccumulators[i];

            assembly {
                
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }

            assembly {
                
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }
        }

        finalVksAlphaX[2] = add_input[0];
        finalVksAlphaX[3] = add_input[1];

        
        uint256[3] memory finalVKalpha;
        finalVKalpha[0] = in_vk[0];
        finalVKalpha[1] = in_vk[1];
        finalVKalpha[2] = inputAccumulators[0];

        assembly {
            
            success := staticcall(sub(gas(), 2000), 7, finalVKalpha, 0x60, finalVKalpha, 0x40)
        }
        if (!success) {
            return (false, finalVksAlphaX);
        }

        finalVksAlphaX[0] = finalVKalpha[0];
        finalVksAlphaX[1] = finalVKalpha[1];
    }

    
    
    
    

    function BatchVerify (
        uint256[14] memory in_vk, 
        uint256[4] memory vk_gammaABC, 
        uint256[] memory in_proof, 
        uint256[] memory proof_inputs, 
        uint256 num_proofs
    )
    internal
    view
    returns (bool success)
    {
        require(in_proof.length == num_proofs * 8, "Invalid proofs length for a batch");
        require(proof_inputs.length % num_proofs == 0, "Invalid inputs length for a batch");
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length / num_proofs, "Invalid verification key");

        
        
        
        
        

        bool valid;
        uint256[] memory proofsAandC;
        uint256[] memory inputAccumulators;
        (valid, proofsAandC, inputAccumulators) = accumulate(in_proof, proof_inputs, num_proofs);
        if (!valid) {
            return false;
        }

        uint256[4] memory finalVksAlphaX;
        (valid, finalVksAlphaX) = prepareBatches(in_vk, vk_gammaABC, inputAccumulators);
        if (!valid) {
            return false;
        }

        uint256[] memory inputs = new uint256[](6*num_proofs + 18);
        
        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            inputs[proofNumber*6] = proofsAandC[proofNumber*2];
            inputs[proofNumber*6 + 1] = proofsAandC[proofNumber*2 + 1];
            inputs[proofNumber*6 + 2] = in_proof[proofNumber*8 + 2];
            inputs[proofNumber*6 + 3] = in_proof[proofNumber*8 + 3];
            inputs[proofNumber*6 + 4] = in_proof[proofNumber*8 + 4];
            inputs[proofNumber*6 + 5] = in_proof[proofNumber*8 + 5];
        }

        
        inputs[num_proofs*6] = finalVksAlphaX[0];
        inputs[num_proofs*6 + 1] = NegateY(finalVksAlphaX[1]);
        inputs[num_proofs*6 + 2] = in_vk[2];
        inputs[num_proofs*6 + 3] = in_vk[3];
        inputs[num_proofs*6 + 4] = in_vk[4];
        inputs[num_proofs*6 + 5] = in_vk[5];

        
        inputs[num_proofs*6 + 6] = finalVksAlphaX[2];
        inputs[num_proofs*6 + 7] = NegateY(finalVksAlphaX[3]);
        inputs[num_proofs*6 + 8] = in_vk[6];
        inputs[num_proofs*6 + 9] = in_vk[7];
        inputs[num_proofs*6 + 10] = in_vk[8];
        inputs[num_proofs*6 + 11] = in_vk[9];

        
        inputs[num_proofs*6 + 12] = proofsAandC[num_proofs*2];
        inputs[num_proofs*6 + 13] = NegateY(proofsAandC[num_proofs*2 + 1]);
        inputs[num_proofs*6 + 14] = in_vk[10];
        inputs[num_proofs*6 + 15] = in_vk[11];
        inputs[num_proofs*6 + 16] = in_vk[12];
        inputs[num_proofs*6 + 17] = in_vk[13];

        uint256 inputsLength = inputs.length * 32;
        uint[1] memory out;
        require(inputsLength % 192 == 0, "Inputs length should be multiple of 192 bytes");

        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(inputs, 0x20), inputsLength, out, 0x20)
        }
        return success && out[0] == 1;
    }
}