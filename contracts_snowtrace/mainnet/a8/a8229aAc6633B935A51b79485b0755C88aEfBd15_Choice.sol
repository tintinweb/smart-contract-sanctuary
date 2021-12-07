// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./RedBlack.sol";
import "./Firn.sol";

contract Choice {
    RedBlack immutable tree;
    Firn immutable firn;

    constructor(address _tree, address _firn) {
        tree = RedBlack(_tree);
        firn = Firn(_firn);
    }

    function choose(bytes32 seed, uint32 amount) external view returns (bytes32[N] memory result) {
        uint256 successes = 0;
        uint256 attempts = 0;
        while (successes < N) {
            attempts++;
            if (attempts > 50) {
                amount >>= 1;
                attempts = 0;
            }
            seed = keccak256(abi.encode(seed));
            uint256 entropy = uint256(seed);
            uint256 layer = entropy % tree.blackHeight();
            entropy >>= 8; // an overestimate on the _log_ (!) of the blackheight of the tree. blackheight <= 256.
            uint256 cursor = tree.root();
            bool red = false; // avoid a "shadowing" warning
            for (uint256 i = 0; i < layer; i++) {
                // inv: at the beginning of the loop, it points to the index-ith black node in the rightmost path.
                (,,cursor,) = tree.nodes(cursor); // tree.nodes[cursor].right
                (,,,red) = tree.nodes(cursor); // if (tree.nodes[cursor].red)
                if (red) (,,cursor,) = tree.nodes(cursor);
            }
            uint256 subLayer; // (weighted) random element of {0, ..., blackHeight - 1 - layer}, low more likely.
            while (true) {
                bool found = false;
                for (uint256 i = 0; i < tree.blackHeight() - layer; i++) {
                    if (entropy & 0x01 == 0x01) {
                        subLayer = i;
                        found = true;
                        break;
                    }
                    entropy >>= 1;
                }
                if (found) break;
            }
            entropy >>= 1; // always a 1 here. get rid of it.
            for (uint256 i = 0; i < tree.blackHeight() - 1 - layer - subLayer; i++) {
                // at beginning of loop, points to the layer + ith black node down _random_ path...
                if (entropy & 0x01 == 0x01) (,,cursor,) = tree.nodes(cursor); // cursor = tree.nodes[cursor].right
                else (,cursor,,) = tree.nodes(cursor); // cursor = tree.nodes[cursor].left
                entropy >>= 1;
                (,,,red) = tree.nodes(cursor); // if (tree.nodes[cursor].red)
                if (red) {
                    if (entropy & 0x01 == 0x01) (,,cursor,) = tree.nodes(cursor);
                    else (,cursor,,) = tree.nodes(cursor);
                    entropy >>= 1;
                }
            }
            (,,uint256 right,) = tree.nodes(cursor);
            (,,,red) = tree.nodes(right);
            if (entropy & 0x01 == 0x01 && red) {
                (,,cursor,) = tree.nodes(cursor);
            }
            else if (entropy & 0x20 == 0x20) {
                (,uint256 left,,) = tree.nodes(cursor);
                (,,,red) = tree.nodes(left);
                if (red) (,cursor,,) = tree.nodes(cursor);
            }
            entropy >>= 2;
            uint256 length = firn.lengths(cursor);
            bytes32 account = firn.lists(cursor, entropy % length);
            (,uint32 candidate,) = firn.info(account); // what is the total amount this person has deposited?
            if (candidate < amount) continue; // skip them for now
            bool duplicate = false;
            for (uint256 i = 0; i < successes; i++) {
                if (result[i] == account) {
                    duplicate = true;
                    break;
                }
            }
            if (duplicate) continue;
            attempts = 0;
            result[successes++] = account;
        }
    }
}