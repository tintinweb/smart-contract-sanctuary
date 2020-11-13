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

import "CpuPublicInputOffsets.sol";

/*
  A utility contract to parse the GPS output.
  See registerGpsFacts for more details.
*/
contract GpsOutputParser is CpuPublicInputOffsets {
    uint256 internal constant METADATA_TASKS_OFFSET = 1;
    uint256 internal constant METADATA_OFFSET_TASK_OUTPUT_SIZE = 0;
    uint256 internal constant METADATA_OFFSET_TASK_PROGRAM_HASH = 1;
    uint256 internal constant METADATA_OFFSET_TASK_N_TREE_PAIRS = 2;
    uint256 internal constant METADATA_TASK_HEADER_SIZE = 3;

    uint256 internal constant METADATA_OFFSET_TREE_PAIR_N_PAGES = 0;
    uint256 internal constant METADATA_OFFSET_TREE_PAIR_N_NODES = 1;

    uint256 internal constant NODE_STACK_OFFSET_HASH = 0;
    uint256 internal constant NODE_STACK_OFFSET_END = 1;
    // The size of each node in the node stack.
    uint256 internal constant NODE_STACK_ITEM_SIZE = 2;

    /*
      Fact registry logic that should be implemented by the derived classes.
    */
    function registerFact(bytes32 factHash) internal;

    /*
      Parses the GPS program output (using taskMetadata, which should be verified by the caller),
      and registers the facts of the tasks which were executed.

      The first entry in taskMetadata is the number of tasks.

      For each task, the structure is as follows:
        1. Size (including the size and hash fields).
        2. Program hash.
        3. The numebr of pairs in the Merkle tree structure (see below).
        4. The Merkle tree structure (see below).

      The fact of each task is stored as a (non-binary) Merkle tree.
      Each non-leaf node is 1 + the hash of (node0, end0, node1, end1, ...)
      where node* are its children and end* is the the total number of data words up to and
      including that node and its children (including the previous sybling nodes).
      We add 1 to the result of the hash to distinguish it from a leaf node.
      Leaf nodes are the hash of their data.

      The structure of the tree is passed as a list of pairs (n_pages, n_nodes), and the tree is
      constructed using a stack of nodes (initialized to an empty stack) by repeating for each pair:
      1. Add n_pages to the stack of nodes.
      2. Pop the top n_nodes, construct a parent node for them, and push it back to the stack.
      After applying the steps above, the stack much contain exactly one node, which will
      constitute the root of the Merkle tree.
      For example, [(2, 2)] will create a Merkle tree with a root and two direct children, while
      [(3, 2), (0, 2)] will create a Merkle tree with a root whose left child is a leaf and
      right child has two leaf children.

      Assumptions: taskMetadata and cairoAuxInput are verified externaly.
    */
    function registerGpsFacts(uint256[] memory taskMetadata, uint256[] memory cairoAuxInput)
        internal
    {
        uint256 nTasks = taskMetadata[0];

        // Skip the 3 first output cells which contain the number of tasks and the size and
        // program hash of the first task. curAddr points to the output of the first task.
        uint256 curAddr = cairoAuxInput[OFFSET_OUTPUT_BEGIN_ADDR] + 3;

        uint256 taskMetadataOffset = METADATA_TASKS_OFFSET;

        // Bound the size of the stack by the total number of pages.
        uint256[] memory nodeStack = new uint256[](
            NODE_STACK_ITEM_SIZE * cairoAuxInput[OFFSET_N_PUBLIC_MEMORY_PAGES]);

        // Skip the main page.
        uint256 curPage = 1;

        // Register the fact for each task.
        for (uint256 task = 0; task < nTasks; task++) {
            uint256 curOffset = 0;
            uint256 nTreePairs = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_N_TREE_PAIRS];

            // Build the Merkle tree using a stack (see the function documentation) to compute
            // the fact.
            uint256 nodeStackLen = 0;
            for (uint256 treePair = 0; treePair < nTreePairs; treePair++) {
                // Add n_pages to the stack of nodes.
                uint256 nPages = taskMetadata[
                    taskMetadataOffset + METADATA_TASK_HEADER_SIZE + 2 * treePair +
                    METADATA_OFFSET_TREE_PAIR_N_PAGES];
                require(nPages < 2**20, "Invalid value of n_pages in tree structure.");
                for (uint256 i = 0; i < nPages; i++) {
                    // Copy cairoAuxInput to avoid the "stack too deep" error.
                    uint256[] memory cairoAuxInputCopy = cairoAuxInput;
                    uint256 pageSize = pushPageToStack(
                        curPage, curAddr, curOffset, nodeStack, nodeStackLen, cairoAuxInputCopy);
                    curPage += 1;
                    nodeStackLen += 1;
                    curAddr += pageSize;
                    curOffset += pageSize;
                }

                // Pop the top n_nodes, construct a parent node for them, and push it back to the
                // stack.
                uint256 nNodes = taskMetadata[
                    taskMetadataOffset + METADATA_TASK_HEADER_SIZE + 2 * treePair +
                    METADATA_OFFSET_TREE_PAIR_N_NODES];
                if (nNodes != 0) {
                    nodeStackLen = constructNode(nodeStack, nodeStackLen, nNodes);
                }
            }
            require(nodeStackLen == 1, "Node stack must contain exactly one item.");

            uint256 programHash = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_PROGRAM_HASH];
            uint256 outputSize = taskMetadata[
                taskMetadataOffset + METADATA_OFFSET_TASK_OUTPUT_SIZE];

            bytes32 fact = keccak256(abi.encode(programHash, nodeStack[NODE_STACK_OFFSET_HASH]));

            // Update taskMetadataOffset.
            taskMetadataOffset += METADATA_TASK_HEADER_SIZE + 2 * nTreePairs;

            // Verify that the sizes of the pages correspond to the task output, to make
            // sure that the computed hash is indeed the hash of the entire output of the task.
            require(
                nodeStack[NODE_STACK_OFFSET_END] + 2 == outputSize,
                "The sum of the page sizes does not match output size.");

            registerFact(fact);

            // Move curAddr to the output of the next task (skipping the size and hash fields).
            curAddr += 2;
        }

        require(
            cairoAuxInput[OFFSET_N_PUBLIC_MEMORY_PAGES] == curPage,
            "Not all memory pages were processed.");
    }

    /*
      Push one page (curPage) to the top of the node stack.
      curAddr is the memory address, curOffset is the offset from the beginning of the task output.
      Verifies that the page has the right start address and returns the page size.
    */
    function pushPageToStack(
        uint256 curPage, uint256 curAddr, uint256 curOffset, uint256[] memory nodeStack,
        uint256 nodeStackLen, uint256[] memory cairoAuxInput)
        internal pure returns (uint256)
    {
        // Extract the page size, first address and hash from cairoAuxInput.
        uint256 pageSizeOffset = getOffsetPageSize(curPage);
        uint256 pageSize;
        uint256 pageAddrOffset = getOffsetPageAddr(curPage);
        uint256 pageAddr;
        uint256 pageHashOffset = getOffsetPageHash(curPage);
        uint256 pageHash;
        assembly {
            pageSize := mload(add(cairoAuxInput, mul(add(pageSizeOffset, 1), 0x20)))
            pageAddr := mload(add(cairoAuxInput, mul(add(pageAddrOffset, 1), 0x20)))
            pageHash := mload(add(cairoAuxInput, mul(add(pageHashOffset, 1), 0x20)))
        }
        require(pageSize < 2**30, "Invalid page size.");
        require(pageAddr == curAddr, "Invalid page address.");

        nodeStack[NODE_STACK_ITEM_SIZE * nodeStackLen + NODE_STACK_OFFSET_END] =
            curOffset + pageSize;
        nodeStack[NODE_STACK_ITEM_SIZE * nodeStackLen + NODE_STACK_OFFSET_HASH] = pageHash;
        return pageSize;
    }

    /*
      Pops the top nNodes nodes from the stack and pushes one parent node instead.
      Returns the new value of nodeStackLen.
    */
    function constructNode(uint256[] memory nodeStack, uint256 nodeStackLen, uint256 nNodes)
        internal pure returns (uint256) {
        require(nNodes <= nodeStackLen, "Invalid value of n_nodes in tree structure.");
        // The end of the node is the end of the last child.
        uint256 newNodeEnd = nodeStack[
            NODE_STACK_ITEM_SIZE * (nodeStackLen - 1) + NODE_STACK_OFFSET_END];
        uint256 newStackLen = nodeStackLen - nNodes;
        // Compute node hash.
        uint256 nodeStart = 0x20 + newStackLen * NODE_STACK_ITEM_SIZE * 0x20;
        uint256 newNodeHash;
        assembly {
            newNodeHash := keccak256(add(nodeStack, nodeStart), mul(
                nNodes, /*NODE_STACK_ITEM_SIZE * 0x20*/0x40))
        }

        nodeStack[NODE_STACK_ITEM_SIZE * newStackLen + NODE_STACK_OFFSET_END] = newNodeEnd;
        // Add one to the new node hash to distinguish it from the hash of a leaf (a page).
        nodeStack[NODE_STACK_ITEM_SIZE * newStackLen + NODE_STACK_OFFSET_HASH] = newNodeHash + 1;
        return newStackLen + 1;
    }
}
