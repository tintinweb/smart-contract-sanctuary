/**
 *Submitted for verification at snowtrace.io on 2021-12-07
*/

pragma solidity 0.8.10;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------

contract RedBlack {
    struct Node {
        uint256 parent;
        uint256 left;
        uint256 right;
        bool red;
    }

    uint256 public root;
    uint256 public blackHeight;

    mapping(uint256 => Node) public nodes;

    uint256 constant EMPTY = 0;

    address immutable owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function exists(uint256 key) external view returns (bool) {
        return (key != EMPTY) && ((key == root) || (nodes[key].parent != EMPTY));
    }

    function rotateLeft(uint256 key) internal {
        uint256 cursor = nodes[key].right;
        uint256 keyParent = nodes[key].parent;
        uint256 cursorLeft = nodes[cursor].left;
        nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            nodes[cursorLeft].parent = key;
        }
        nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            root = cursor;
        } else if (key == nodes[keyParent].left) {
            nodes[keyParent].left = cursor;
        } else {
            nodes[keyParent].right = cursor;
        }
        nodes[cursor].left = key;
        nodes[key].parent = cursor;
    }

    function rotateRight(uint256 key) internal {
        uint256 cursor = nodes[key].left;
        uint256 keyParent = nodes[key].parent;
        uint256 cursorRight = nodes[cursor].right;
        nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            nodes[cursorRight].parent = key;
        }
        nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            root = cursor;
        } else if (key == nodes[keyParent].right) {
            nodes[keyParent].right = cursor;
        } else {
            nodes[keyParent].left = cursor;
        }
        nodes[cursor].right = key;
        nodes[key].parent = cursor;
    }

    function insertFixup(uint256 key) internal {
        uint256 cursor;
        while (key != root && nodes[nodes[key].parent].red) {
            uint256 keyParent = nodes[key].parent;
            if (keyParent == nodes[nodes[keyParent].parent].left) {
                cursor = nodes[nodes[keyParent].parent].right;
                if (nodes[cursor].red) {
                    nodes[keyParent].red = false;
                    nodes[cursor].red = false;
                    nodes[nodes[keyParent].parent].red = true;
                    key = nodes[keyParent].parent;
                } else {
                    if (key == nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(key);
                    }
                    keyParent = nodes[key].parent;
                    nodes[keyParent].red = false;
                    nodes[nodes[keyParent].parent].red = true;
                    rotateRight(nodes[keyParent].parent);
                }
            } else {
                cursor = nodes[nodes[keyParent].parent].left;
                if (nodes[cursor].red) {
                    nodes[keyParent].red = false;
                    nodes[cursor].red = false;
                    nodes[nodes[keyParent].parent].red = true;
                    key = nodes[keyParent].parent;
                } else {
                    if (key == nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(key);
                    }
                    keyParent = nodes[key].parent;
                    nodes[keyParent].red = false;
                    nodes[nodes[keyParent].parent].red = true;
                    rotateLeft(nodes[keyParent].parent);
                }
            }
        }
        if (nodes[root].red) {
            nodes[root].red = false;
            blackHeight++;
        }
    }

    function insert(uint256 key) external onlyOwner {
        uint256 cursor = EMPTY;
        uint256 probe = root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = nodes[probe].left;
            } else {
                probe = nodes[probe].right;
            }
        }
        nodes[key] = Node({parent : cursor, left : EMPTY, right : EMPTY, red : true});
        if (cursor == EMPTY) {
            root = key;
        } else if (key < cursor) {
            nodes[cursor].left = key;
        } else {
            nodes[cursor].right = key;
        }
        insertFixup(key);
    }

    function replaceParent(uint256 a, uint256 b) internal {
        uint256 bParent = nodes[b].parent;
        nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            root = a;
        } else {
            if (b == nodes[bParent].left) {
                nodes[bParent].left = a;
            } else {
                nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(uint256 key) internal {
        uint256 cursor;
        while (key != root && !nodes[key].red) {
            uint256 keyParent = nodes[key].parent;
            if (key == nodes[keyParent].left) {
                cursor = nodes[keyParent].right;
                if (nodes[cursor].red) {
                    nodes[cursor].red = false;
                    nodes[keyParent].red = true;
                    rotateLeft(keyParent);
                    cursor = nodes[keyParent].right;
                }
                if (!nodes[nodes[cursor].left].red && !nodes[nodes[cursor].right].red) {
                    nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!nodes[nodes[cursor].right].red) {
                        nodes[nodes[cursor].left].red = false;
                        nodes[cursor].red = true;
                        rotateRight(cursor);
                        cursor = nodes[keyParent].right;
                    }
                    nodes[cursor].red = nodes[keyParent].red;
                    nodes[keyParent].red = false;
                    nodes[nodes[cursor].right].red = false;
                    rotateLeft(keyParent);
                    return; // key = root;
                }
            } else {
                cursor = nodes[keyParent].left;
                if (nodes[cursor].red) {
                    nodes[cursor].red = false;
                    nodes[keyParent].red = true;
                    rotateRight(keyParent);
                    cursor = nodes[keyParent].left;
                }
                if (!nodes[nodes[cursor].right].red && !nodes[nodes[cursor].left].red) {
                    nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!nodes[nodes[cursor].left].red) {
                        nodes[nodes[cursor].right].red = false;
                        nodes[cursor].red = true;
                        rotateLeft(cursor);
                        cursor = nodes[keyParent].left;
                    }
                    nodes[cursor].red = nodes[keyParent].red;
                    nodes[keyParent].red = false;
                    nodes[nodes[cursor].left].red = false;
                    rotateRight(keyParent);
                    return; // key = root;
                }
            }
        }
        if (nodes[key].red) nodes[key].red = false;
        else blackHeight--;
    }

    function remove(uint256 key) external onlyOwner {
        uint256 probe;
        uint256 cursor;
        if (nodes[key].left == EMPTY || nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = nodes[key].right;
            while (nodes[cursor].left != EMPTY) {
                cursor = nodes[cursor].left;
            }
        }
        if (nodes[cursor].left != EMPTY) {
            probe = nodes[cursor].left;
        } else {
            probe = nodes[cursor].right;
        }
        uint256 yParent = nodes[cursor].parent;
        nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == nodes[yParent].left) {
                nodes[yParent].left = probe;
            } else {
                nodes[yParent].right = probe;
            }
        } else {
            root = probe;
        }
        bool doFixup = !nodes[cursor].red;
        if (cursor != key) {
            replaceParent(cursor, key);
            nodes[cursor].left = nodes[key].left;
            nodes[nodes[cursor].left].parent = cursor;
            nodes[cursor].right = nodes[key].right;
            nodes[nodes[cursor].right].parent = cursor;
            nodes[cursor].red = nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(probe);
        }
        delete nodes[cursor];
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------