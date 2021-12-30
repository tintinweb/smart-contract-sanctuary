/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "CairoBootloaderProgram.sol";
import "CairoVerifierContract.sol";
import "MemoryPageFactRegistry.sol";
import "Identity.sol";
import "PrimeFieldElement0.sol";
import "GpsOutputParser.sol";

contract GpsStatementVerifier is
    GpsOutputParser,
    Identity,
    CairoBootloaderProgramSize,
    PrimeFieldElement0
{
    CairoBootloaderProgram bootloaderProgramContractAddress;
    MemoryPageFactRegistry memoryPageFactRegistry;
    CairoVerifierContract[] cairoVerifierContractAddresses;

    uint256 internal constant N_BUILTINS = 5;
    uint256 internal constant N_MAIN_ARGS = N_BUILTINS;
    uint256 internal constant N_MAIN_RETURN_VALUES = N_BUILTINS;

    /*
      Constructs an instance of GpsStatementVerifier.
      bootloaderProgramContract is the address of the bootloader program contract
      and cairoVerifierContracts is a list of cairoVerifiers indexed by their id.
    */
    constructor(
        address bootloaderProgramContract,
        address memoryPageFactRegistry_,
        address[] memory cairoVerifierContracts
    ) public {
        bootloaderProgramContractAddress = CairoBootloaderProgram(bootloaderProgramContract);
        memoryPageFactRegistry = MemoryPageFactRegistry(memoryPageFactRegistry_);
        cairoVerifierContractAddresses = new CairoVerifierContract[](cairoVerifierContracts.length);
        for (uint256 i = 0; i < cairoVerifierContracts.length; ++i) {
            cairoVerifierContractAddresses[i] = CairoVerifierContract(cairoVerifierContracts[i]);
        }
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_GpsStatementVerifier_2021_4";
    }

    /*
      Verifies a proof and registers the corresponding facts.
      For the structure of cairoAuxInput, see cpu/CpuPublicInputOffsets.sol.
      taskMetadata is structured as follows:
      1. Number of tasks.
      2. For each task:
         1. Task output size (including program hash and size).
         2. Program hash.
    */
    function verifyProofAndRegister(
        uint256[] calldata proofParams,
        uint256[] calldata proof,
        uint256[] calldata taskMetadata,
        uint256[] calldata cairoAuxInput,
        uint256 cairoVerifierId
    ) external {
        require(
            cairoVerifierId < cairoVerifierContractAddresses.length,
            "cairoVerifierId is out of range."
        );
        CairoVerifierContract cairoVerifier = cairoVerifierContractAddresses[cairoVerifierId];

        // The values z and alpha are used only for the fact registration of the main page.
        // They are not part of the public input of CpuVerifier as they are computed there.
        // Take the relevant slice from 'cairoAuxInput'.
        uint256[] calldata cairoPublicInput = (
            cairoAuxInput[:cairoAuxInput.length -
                // z and alpha.
                2]
        );

        uint256[] memory publicMemoryPages;
        {
            (uint256 publicMemoryOffset, uint256 selectedBuiltins) = cairoVerifier.getLayoutInfo();

            require(cairoAuxInput.length > publicMemoryOffset, "Invalid cairoAuxInput length.");
            publicMemoryPages = (uint256[])(cairoPublicInput[publicMemoryOffset:]);
            uint256 nPages = publicMemoryPages[0];
            require(nPages < 10000, "Invalid nPages.");

            // Each page has a page info and a hash.
            require(
                publicMemoryPages.length == nPages * (PAGE_INFO_SIZE + 1),
                "Invalid publicMemoryPages length."
            );

            // Process public memory.
            (
                uint256 publicMemoryLength,
                uint256 memoryHash,
                uint256 prod
            ) = registerPublicMemoryMainPage(taskMetadata, cairoAuxInput, selectedBuiltins);

            // Make sure the first page is valid.
            // If the size or the hash are invalid, it may indicate that there is a mismatch between the
            // bootloader program contract and the program in the proof.
            require(
                publicMemoryPages[PAGE_INFO_SIZE_OFFSET] == publicMemoryLength,
                "Invalid size for memory page 0."
            );
            require(
                publicMemoryPages[PAGE_INFO_HASH_OFFSET] == memoryHash,
                "Invalid hash for memory page 0."
            );
            require(
                publicMemoryPages[nPages * PAGE_INFO_SIZE] == prod,
                "Invalid cumulative product for memory page 0."
            );
        }

        // NOLINTNEXTLINE: reentrancy-benign.
        cairoVerifier.verifyProofExternal(proofParams, proof, (uint256[])(cairoPublicInput));

        registerGpsFacts(taskMetadata, publicMemoryPages, cairoAuxInput[OFFSET_OUTPUT_BEGIN_ADDR]);
    }

    /*
      Registers the fact for memory page 0, which includes:
      1. The bootloader program,
      2. Arguments and return values of main()
      3. Some of the data required for computing the task facts. which is represented in
         taskMetadata.
      Returns information on the registered fact.

      Arguments:
        selectedBuiltins: A bit-map of builtins that are present in the layout.
            See CairoVerifierContract.sol for more information.
        taskMetadata: Per task metadata.
        cairoAuxInput: Auxiliary input for the cairo verifier.

      Assumptions: cairoAuxInput is connected to the public input, which is verified by
      cairoVerifierContractAddresses.
      Guarantees: taskMetadata is consistent with the public memory, with some sanity checks.
    */
    function registerPublicMemoryMainPage(
        uint256[] calldata taskMetadata,
        uint256[] calldata cairoAuxInput,
        uint256 selectedBuiltins
    )
        internal
        returns (
            uint256 publicMemoryLength,
            uint256 memoryHash,
            uint256 prod
        )
    {
        uint256 nTasks = taskMetadata[0];
        require(nTasks < 2**30, "Invalid number of tasks.");

        // Public memory length.
        publicMemoryLength = (PROGRAM_SIZE +
            // return fp and pc =
            2 +
            N_MAIN_ARGS +
            N_MAIN_RETURN_VALUES +
            // Number of tasks cell =
            1 +
            2 *
            nTasks);
        uint256[] memory publicMemory = new uint256[](
            N_WORDS_PER_PUBLIC_MEMORY_ENTRY * publicMemoryLength
        );

        uint256 offset = 0;

        // Write public memory, which is a list of pairs (address, value).
        {
            // Program segment.
            uint256[PROGRAM_SIZE] memory bootloaderProgram = bootloaderProgramContractAddress
                .getCompiledProgram();
            for (uint256 i = 0; i < bootloaderProgram.length; i++) {
                // Force that memory[i + INITIAL_PC] = bootloaderProgram[i].
                publicMemory[offset] = i + INITIAL_PC;
                publicMemory[offset + 1] = bootloaderProgram[i];
                offset += 2;
            }
        }

        {
            // Execution segment - Make sure [initial_fp - 2] = initial_fp and .
            // This is required for the "safe call" feature (that is, all "call" instructions will
            // return, even if the called function is malicious).
            // It guarantees that it's not possible to create a cycle in the call stack.
            uint256 initialFp = cairoAuxInput[OFFSET_EXECUTION_BEGIN_ADDR];
            require(initialFp >= 2, "Invalid execution begin address.");
            publicMemory[offset + 0] = initialFp - 2;
            publicMemory[offset + 1] = initialFp;
            // Make sure [initial_fp - 1] = 0.
            publicMemory[offset + 2] = initialFp - 1;
            publicMemory[offset + 3] = 0;
            offset += 4;

            // Execution segment: Enforce main's arguments and return values.
            // Note that the page hash depends on the order of the (address, value) pair in the
            // publicMemory and consequently the arguments must be written before the return values.
            uint256 returnValuesAddress = cairoAuxInput[OFFSET_EXECUTION_STOP_PTR] - N_BUILTINS;
            uint256 builtinSegmentInfoOffset = OFFSET_OUTPUT_BEGIN_ADDR;

            for (uint256 i = 0; i < N_BUILTINS; i++) {
                // Write argument address.
                publicMemory[offset] = initialFp + i;
                uint256 returnValueOffset = offset + 2 * N_BUILTINS;

                // Write return value address.
                publicMemory[returnValueOffset] = returnValuesAddress + i;

                // Write values.
                if ((selectedBuiltins & 1) != 0) {
                    // Set the argument to the builtin start pointer.
                    publicMemory[offset + 1] = cairoAuxInput[builtinSegmentInfoOffset];
                    // Set the return value to the builtin stop pointer.
                    publicMemory[returnValueOffset + 1] = cairoAuxInput[
                        builtinSegmentInfoOffset + 1
                    ];
                    builtinSegmentInfoOffset += 2;
                } else {
                    // Builtin is not present in layout, set the argument value and return value to 0.
                    publicMemory[offset + 1] = 0;
                    publicMemory[returnValueOffset + 1] = 0;
                }
                offset += 2;
                selectedBuiltins >>= 1;
            }
            require(selectedBuiltins == 0, "SELECTED_BUILTINS_VECTOR_IS_TOO_LONG");
            // Skip the return values which were already written.
            offset += 2 * N_BUILTINS;
        }

        // Program output.
        {
            // Check that there are enough range checks for the bootloader builtin validation.
            // Each builtin is validated for each task and each validation uses one range check.
            require(
                cairoAuxInput[OFFSET_RANGE_CHECK_STOP_PTR] >=
                    cairoAuxInput[OFFSET_RANGE_CHECK_BEGIN_ADDR] + N_BUILTINS * nTasks,
                "Range-check stop pointer should be after all range checks used for validations."
            );

            {
                uint256 outputAddress = cairoAuxInput[OFFSET_OUTPUT_BEGIN_ADDR];
                // Force that memory[outputAddress] = nTasks.
                publicMemory[offset + 0] = outputAddress;
                publicMemory[offset + 1] = nTasks;
                offset += 2;
                outputAddress += 1;

                uint256[] calldata taskMetadataSlice = taskMetadata[METADATA_TASKS_OFFSET:];
                for (uint256 task = 0; task < nTasks; task++) {
                    uint256 outputSize = taskMetadataSlice[METADATA_OFFSET_TASK_OUTPUT_SIZE];
                    require(2 <= outputSize && outputSize < 2**30, "Invalid task output size.");
                    uint256 programHash = taskMetadataSlice[METADATA_OFFSET_TASK_PROGRAM_HASH];
                    uint256 nTreePairs = taskMetadataSlice[METADATA_OFFSET_TASK_N_TREE_PAIRS];
                    require(
                        1 <= nTreePairs && nTreePairs < 2**20,
                        "Invalid number of pairs in the Merkle tree structure."
                    );
                    // Force that memory[outputAddress] = outputSize.
                    publicMemory[offset + 0] = outputAddress;
                    publicMemory[offset + 1] = outputSize;
                    // Force that memory[outputAddress + 1] = programHash.
                    publicMemory[offset + 2] = outputAddress + 1;
                    publicMemory[offset + 3] = programHash;
                    offset += 4;
                    outputAddress += outputSize;
                    taskMetadataSlice = taskMetadataSlice[METADATA_TASK_HEADER_SIZE +
                        2 *
                        nTreePairs:];
                }
                require(taskMetadataSlice.length == 0, "Invalid length of taskMetadata.");

                require(
                    cairoAuxInput[OFFSET_OUTPUT_STOP_PTR] == outputAddress,
                    "Inconsistent program output length."
                );
            }
        }

        require(publicMemory.length == offset, "Not all Cairo public inputs were written.");

        uint256 z = cairoAuxInput[cairoAuxInput.length - 2];
        uint256 alpha = cairoAuxInput[cairoAuxInput.length - 1];
        bytes32 factHash;
        (factHash, memoryHash, prod) = memoryPageFactRegistry.registerRegularMemoryPage(
            publicMemory,
            z,
            alpha,
            K_MODULUS
        );
    }
}