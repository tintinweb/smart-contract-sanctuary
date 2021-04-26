/*
  Copyright 2019,2020 StarkWare Industries Ltd.

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
pragma solidity ^0.5.2;

import "CairoBootloaderProgram.sol";
import "CairoVerifierContract.sol";
import "CpuPublicInputOffsets.sol";
import "MemoryPageFactRegistry.sol";
import "FactRegistry.sol";
import "Identity.sol";
import "PrimeFieldElement0.sol";
import "GpsOutputParser.sol";

contract GpsStatementVerifier is
        GpsOutputParser, FactRegistry, Identity, CairoBootloaderProgramSize, PrimeFieldElement0 {
    CairoBootloaderProgram bootloaderProgramContractAddress;
    MemoryPageFactRegistry memoryPageFactRegistry;
    CairoVerifierContract[] cairoVerifierContractAddresses;

    uint256 internal constant N_MAIN_ARGS = 5;
    uint256 internal constant N_MAIN_RETURN_VALUES = 5;
    uint256 internal constant N_BUILTINS = 4;

    /*
      Constructs an instance of GpsStatementVerifier.
      bootloaderProgramContract is the address of the bootloader program contract
      and cairoVerifierContracts is a list of cairoVerifiers indexed by their id.
    */
    constructor(
        address bootloaderProgramContract,
        address memoryPageFactRegistry_,
        address[] memory cairoVerifierContracts) public {
        // solium-disable-previous-line no-empty-blocks
        bootloaderProgramContractAddress = CairoBootloaderProgram(bootloaderProgramContract);
        memoryPageFactRegistry = MemoryPageFactRegistry(memoryPageFactRegistry_);
        cairoVerifierContractAddresses = new CairoVerifierContract[](cairoVerifierContracts.length);
        for (uint256 i = 0; i < cairoVerifierContracts.length; ++i) {
            cairoVerifierContractAddresses[i] = CairoVerifierContract(cairoVerifierContracts[i]);
        }
    }

    function identify()
        external pure
        returns(string memory)
    {
        return "StarkWare_GpsStatementVerifier_2020_1";
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
    )
        external
    {
        require(
            cairoAuxInput.length > OFFSET_N_PUBLIC_MEMORY_PAGES,
            "Invalid cairoAuxInput length.");
        uint256 nPages = cairoAuxInput[OFFSET_N_PUBLIC_MEMORY_PAGES];
        require(
            cairoAuxInput.length == getPublicInputLength(nPages) + /*z and alpha*/ 2,
            "Invalid cairoAuxInput length.");

        // The values z and alpha are used only for the fact registration of the main page.
        // They are not needed in the auxiliary input of CpuVerifier as they are computed there.
        // Create a copy of cairoAuxInput without z and alpha.
        uint256[] memory cairoPublicInput = new uint256[](cairoAuxInput.length - /*z and alpha*/ 2);
        for (uint256 i = 0; i < cairoAuxInput.length - /*z and alpha*/ 2; i++) {
            cairoPublicInput[i] = cairoAuxInput[i];
        }

        {
        // Process public memory.
        (uint256 publicMemoryLength, uint256 memoryHash, uint256 prod) =
            registerPublicMemoryMainPage(taskMetadata, cairoAuxInput);

        // Make sure the first page is valid.
        // If the size or the hash are invalid, it may indicate that there is a mismatch between the
        // bootloader program contract and the program in the proof.
        require(
            cairoAuxInput[getOffsetPageSize(0)] == publicMemoryLength,
            "Invalid size for memory page 0.");
        require(
            cairoAuxInput[getOffsetPageHash(0)] == memoryHash,
            "Invalid hash for memory page 0.");
        require(
            cairoAuxInput[getOffsetPageProd(0, nPages)] == prod,
            "Invalid cumulative product for memory page 0.");
        }

        require(
            cairoVerifierId < cairoVerifierContractAddresses.length,
            "cairoVerifierId is out of range.");

        // NOLINTNEXTLINE: reentrancy-benign.
        cairoVerifierContractAddresses[cairoVerifierId].verifyProofExternal(
            proofParams, proof, cairoPublicInput);

        registerGpsFacts(taskMetadata, cairoAuxInput);
    }

    /*
      Registers the fact for memory page 0, which includes:
      1. The bootloader program,
      2. Arguments and return values of main()
      3. Some of the data required for computing the task facts. which is represented in
         taskMetadata.
      Returns information on the registered fact.

      Assumptions: cairoAuxInput is connected to the public input, which is verified by
      cairoVerifierContractAddresses.
      Guarantees: taskMetadata is consistent with the public memory, with some sanity checks.
    */
    function registerPublicMemoryMainPage(
        uint256[] memory taskMetadata,
        uint256[] memory cairoAuxInput
    ) internal returns (uint256 publicMemoryLength, uint256 memoryHash, uint256 prod) {
        uint256 nTasks = taskMetadata[0];
        require(nTasks < 2**30, "Invalid number of tasks.");

        // Public memory length.
        publicMemoryLength = (
            PROGRAM_SIZE + N_MAIN_ARGS + N_MAIN_RETURN_VALUES + /*Number of tasks cell*/1 +
            2 * nTasks);
        uint256[] memory publicMemory = new uint256[](
            N_WORDS_PER_PUBLIC_MEMORY_ENTRY * publicMemoryLength);

        uint256 offset = 0;

        // Write public memory, which is a list of pairs (address, value).
        {
        // Program segment.
        uint256[PROGRAM_SIZE] memory bootloaderProgram =
            bootloaderProgramContractAddress.getCompiledProgram();
        for (uint256 i = 0; i < bootloaderProgram.length; i++) {
            // Force that memory[i] = bootloaderProgram[i].
            publicMemory[offset] = i;
            publicMemory[offset + 1] = bootloaderProgram[i];
            offset += 2;
        }
        }

        {
        // Execution segment - main's arguments.
        uint256 executionBeginAddr = cairoAuxInput[OFFSET_EXECUTION_BEGIN_ADDR];
        publicMemory[offset + 0] = executionBeginAddr - 5;
        publicMemory[offset + 1] = cairoAuxInput[OFFSET_OUTPUT_BEGIN_ADDR];
        publicMemory[offset + 2] = executionBeginAddr - 4;
        publicMemory[offset + 3] = cairoAuxInput[OFFSET_PEDERSEN_BEGIN_ADDR];
        publicMemory[offset + 4] = executionBeginAddr - 3;
        publicMemory[offset + 5] = cairoAuxInput[OFFSET_RANGE_CHECK_BEGIN_ADDR];
        publicMemory[offset + 6] = executionBeginAddr - 2;
        publicMemory[offset + 7] = cairoAuxInput[OFFSET_ECDSA_BEGIN_ADDR];
        publicMemory[offset + 8] = executionBeginAddr - 1;
        publicMemory[offset + 9] = cairoAuxInput[OFFSET_CHECKPOINTS_BEGIN_PTR];
        offset += 10;
        }

        {
        // Execution segment - return values.
        uint256 executionStopPtr = cairoAuxInput[OFFSET_EXECUTION_STOP_PTR];
        publicMemory[offset + 0] = executionStopPtr - 5;
        publicMemory[offset + 1] = cairoAuxInput[OFFSET_OUTPUT_STOP_PTR];
        publicMemory[offset + 2] = executionStopPtr - 4;
        publicMemory[offset + 3] = cairoAuxInput[OFFSET_PEDERSEN_STOP_PTR];
        publicMemory[offset + 4] = executionStopPtr - 3;
        publicMemory[offset + 5] = cairoAuxInput[OFFSET_RANGE_CHECK_STOP_PTR];
        publicMemory[offset + 6] = executionStopPtr - 2;
        publicMemory[offset + 7] = cairoAuxInput[OFFSET_ECDSA_STOP_PTR];
        publicMemory[offset + 8] = executionStopPtr - 1;
        publicMemory[offset + 9] = cairoAuxInput[OFFSET_CHECKPOINTS_STOP_PTR];
        offset += 10;
        }

        // Program output.
        {
        // Check that there are enough range checks for the bootloader builtin validation.
        // Each builtin is validated for each task and each validation uses one range check.
        require(
            cairoAuxInput[OFFSET_RANGE_CHECK_STOP_PTR] >=
            cairoAuxInput[OFFSET_RANGE_CHECK_BEGIN_ADDR] + N_BUILTINS * nTasks,
            "Range-check stop pointer should be after all range checks used for validations.");
        // The checkpoint builtin is used once for each task, taking up two cells.
        require(
            cairoAuxInput[OFFSET_CHECKPOINTS_STOP_PTR] >=
            cairoAuxInput[OFFSET_CHECKPOINTS_BEGIN_PTR] + 2 * nTasks,
            "Number of checkpoints should be at least the number of tasks.");

        uint256 outputAddress = cairoAuxInput[OFFSET_OUTPUT_BEGIN_ADDR];
        // Force that memory[outputAddress] = nTasks.
        publicMemory[offset + 0] = outputAddress;
        publicMemory[offset + 1] = nTasks;
        offset += 2;
        outputAddress += 1;
        uint256 taskMetadataOffset = METADATA_TASKS_OFFSET;

        for (uint256 task = 0; task < nTasks; task++) {
            uint256 outputSize = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_OUTPUT_SIZE];
            require(2 <= outputSize && outputSize < 2**30, "Invalid task output size.");
            uint256 programHash = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_PROGRAM_HASH];
            uint256 nTreePairs = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_N_TREE_PAIRS];
            require(
                1 <= nTreePairs && nTreePairs < 2**20,
                "Invalid number of pairs in the Merkle tree structure.");
            // Force that memory[outputAddress] = outputSize.
            publicMemory[offset + 0] = outputAddress;
            publicMemory[offset + 1] = outputSize;
            // Force that memory[outputAddress + 1] = programHash.
            publicMemory[offset + 2] = outputAddress + 1;
            publicMemory[offset + 3] = programHash;
            offset += 4;
            outputAddress += outputSize;
            taskMetadataOffset += METADATA_TASK_HEADER_SIZE + 2 * nTreePairs;
        }
        require(taskMetadata.length == taskMetadataOffset, "Invalid length of taskMetadata.");

        require(
            cairoAuxInput[OFFSET_OUTPUT_STOP_PTR] == outputAddress,
            "Inconsistent program output length.");
        }

        require(publicMemory.length == offset, "Not all Cairo public inputs were written.");

        bytes32 factHash;
        (factHash, memoryHash, prod) = memoryPageFactRegistry.registerRegularMemoryPage(
            publicMemory,
            /*z=*/cairoAuxInput[cairoAuxInput.length - 2],
            /*alpha=*/cairoAuxInput[cairoAuxInput.length - 1],
            K_MODULUS);
    }
}