pragma solidity ^0.4.24;

library MerkleMap {

    using MerkleMap for *;

    /**
     * @title Node
     * @dev Contains the key, value, left, and right hashes of a Node
     * @param k The key of the node
     * @param v The value stored at the key
     * @param l The hash of the left child
     * @param r The hash of the right child
     */
    struct Node {
        bytes32 k;
        bytes32 v;
        bytes32 l;
        bytes32 r;
    }

    /**
     * @dev Verifies whether a path is in the tree with the given root
     * @param _list A list of nodes along the path
     * @param _root The root of the tree
     * @return bool Whether the path is in the tree
     */
    function verify(Node[] memory _list, bytes32 _root) internal pure returns (bool) {
        // Base case
        if (_list.length == 0)
            return false;

        // Iterate over each element
        for (uint i = 0; i < _list.length - 1; i++) {
            if (hashNode(_list[i]) == _list[i + 1].l) { // Current is left child
                // Ensure current key&#39;s hash is less than the parent key&#39;s hash
                // TODO check for non equality?
                if (_list[i].k.greaterHash(_list[i + 1].k))
                    return false;
            } else if (hashNode(_list[i]) == _list[i + 1].r) { // Current is right child
                // Ensure current key&#39;s hash is greater than the parent key&#39;s hash
                if (_list[i + 1].k.greaterHash(_list[i].k))
                    return false;
            } else { // Current does not equal next left or right
                return false;
            }
        }
        // If the hash of the final node is the root, this path is valid
        return hashNode(_list[_list.length - 1]) == _root;
    }

    /**
     * @dev Given a proof _p, returns the new state root formed after inserting (or updating) key _k to value _v
     * @param _p A list of Nodes in the path from the insert location to the root
     * @param _k The key at which the value will be set
     * @param _v The value to set
     * @param _r The current root of the tree
     * @return bytes32 The updated state root. If the proof is invalid, this function throws
     */
    function insertRec(Node[] memory _p, bytes32 _k, bytes32 _v, bytes32 _r) internal pure returns (bytes32) {
        // Allocate memory for a temp Node and set its key and value to _k and _v
        Node memory temp;
        kvSet(temp, _k, _v);
        // NOTE - Using a stack var here because I was repeating hashNode(temp) all over the place
        bytes32 temp_hash = hashNode(temp);
        
        // Base case
        if (_p.length == 0)
            return temp_hash;

        // Previous root (used to determine if proof is valid)
        bytes32 prev = hashNode(_p[0]);

        // Set up for either an update or insert
        if (_k == _p[0].k) { // _k matches first Node&#39;s key - update
            _p[0].v = _v;
        } else { // insert
            if (_k.keyGt(_p[0].k)) { // ins right
                // If there is a right child, we are not at the base of the tree
                require(_p[0].r == 0, "Insufficient proof");
                _p[0].r = temp_hash;
            } else { // ins left
                // If there is a left child, we are not at the base of the tree
                require(_p[0].l == 0, "Insufficient proof");
                _p[0].l = temp_hash;
            }
        }

        // Current root (used to calculate updated state root post-insert)
        bytes32 cur = hashNode(_p[0]);

        // Recursively validate proof, calculate updated state root, and retrieve previous state root
        (cur, prev) = updateRoot(_p, temp, 1, _k, cur, prev);

        // Ensure prev is the state root. If it is, return the updated root
        require(prev == _r, "Invalid proof at root");
        return cur;
    }

    /**
     * @dev Recursively calculates the updated state root after an insert, as well as the resulting state root from the
     * provided proof, pre-insert
     * @param _p A list of Nodes in the insert path
     * @param _temp A temporary Node variable
     * @param _i The index from the Node list in focus
     * @param _k The key being inserted
     * @param _cur The current calculated updated state root
     * @param _prev The state root produced by the proof using the non-updated list
     * @return bytes32 The updated state root, post-insert
     * @return bytes32 The previous state root, pre-insert
     */
    function updateRoot(Node[] memory _p, Node memory _temp, uint _i, bytes32 _k, bytes32 _cur, bytes32 _prev) private pure returns (bytes32, bytes32) {
        // Base case
        if (_i == _p.length)
            return(_cur, _prev);

        // If the key we want to insert matches the current Node&#39;s key, the insert point was invalid
        require(_k != _p[_i].k, "Invalid insert proof - key exists higher up in tree");

        // Copy current Node&#39;s k, v, l, r to temp location in memory
        copy(_temp, _p[_i]);
        if (_prev == _p[_i].l) // Previous Node was the left child, set new left child in temp
            _temp.l = _cur;
        else if (_prev == _p[_i].r) // Previous Node was the right child, set new right child in temp
            _temp.r = _cur;
        else // Previous Node was not left or right child - revert
            revert("Invalid proof");

        // Increment i, calculate cur as the hash of the temp Node, and prev as the hash of the unchanged list
        return updateRoot(_p, _temp, _i + 1, _k, hashNode(_temp), hashNode(_p[_i]));
    }

    /**
     * @dev Copies the values from _src to _target
     * @param _target A pointer in memory to which _src is copied
     * @param _src A pointer from which the data will be copied
     */
    function copy(Node memory _target, Node memory _src) private pure {
        assembly {
            mstore(_target, mload(_src))
            mstore(add(0x20, _target), mload(add(0x20, _src)))
            mstore(add(0x40, _target), mload(add(0x40, _src)))
            mstore(add(0x60, _target), mload(add(0x60, _src)))
        }
    }

    function keyGt(bytes32 _a, bytes32 _b) internal pure returns (bool) {
        return uint(keccak256(abi.encodePacked(_a))) > uint(keccak256(abi.encodePacked(_b)));
    }

    function kvSet(Node memory _n, bytes32 _k, bytes32 _v) internal pure {
        assembly {
            mstore(_n, _k)
            mstore(add(0x20, _n), _v)
            mstore(add(0x40, _n), 0)
            mstore(add(0x60, _n), 0) 
        }
    }

    /**
     * @dev Efficient hash of a given node
     * @param _n The node to hash
     * @return h The hash of the node
     */
    function hashNode(Node memory _n) internal pure returns (bytes32 h) {
        assembly {  
            let temp := mload(_n)
            mstore(_n, keccak256(_n, 0x20))
            h := keccak256(_n, 0x80)
            mstore(_n, temp)
        }
    }

    function hash(bytes32 _a) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_a));
    }

    function greaterHash(bytes32 _a, bytes32 _b) internal pure returns (bool) {
        return uint(_a.hash()) > uint(_b.hash());
    }

    function greaterThan(bytes32 _a, bytes32 _b) internal pure returns (bool) {
        return uint(_a) > uint(_b);
    }
}

contract MerkleToken {

    using MerkleMap for *;

    // Token state root
    bytes32 public root;

    // Token constants
    uint public constant totalSupply = 1000;
    string public constant name = "MerkleToken";
    string public constant symbol  = "MTK";
    uint8 public constant decimals = 18;

    event RootUpdate(bytes32 indexed prev, bytes32 indexed cur);
    event Transfer(address indexed owner, address indexed recipient, uint amount);

    constructor () public {
        MerkleMap.Node[] memory nodes;
        root = nodes.insertRec(balanceLoc(msg.sender), bytes32(totalSupply), 0);
        emit RootUpdate(0, root);
    }

    /**
     * @dev Returns the address at which a given address&#39; balance is stored
     * @param _owner The address to locate
     * @return bytes32 The storage address at which the owner&#39;s balance is located
     */
    function balanceLoc(address _owner) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, "balances"));
    }

    /**
     * @dev Transfer tokens to a recipient
     * @param _to The address to which tokens will be transferred
     * @param _amt The amount of tokens to transfer
     * @param _s_proof A proof of the sender&#39;s current balance
     * @param _r_proof A proof of the recipient&#39;s current balance
     */
    function transfer(address _to, uint _amt, bytes32[4][] memory _s_proof, bytes32[4][] memory _r_proof) public {
        // Get storage locations of sender&#39;s and recipient&#39;s balances
        bytes32 s_loc = balanceLoc(msg.sender);
        bytes32 r_loc = balanceLoc(_to);

        // Ensure sender has adequate balance
        uint s_bal = uint(_s_proof[0][1]); // Corresponds to Node.v
        require(s_bal >= _amt, "Insufficient funds");

        // Ensure recipient balance does not overflow
        uint r_bal;
        if (_r_proof[0][0] == r_loc) // If the recipient has a nonzero balance (corresponds to Node.k)
            r_bal = uint(_r_proof[0][1]);
        require(r_bal + _amt >= r_bal, "Overflow in recipient balance");
        
        MerkleMap.Node[] memory path;
        assembly { path := _s_proof }

        // Update root with new sender balance
        bytes32 updated = path.insertRec(s_loc, bytes32(s_bal - _amt), root);
        // Update root with new recipient balance
        assembly { path := _r_proof }
        updated = path.insertRec(r_loc, bytes32(r_bal + _amt), updated);

        // Log events, update state root, and finish
        emit RootUpdate(root, updated);
        emit Transfer(msg.sender, _to, _amt);
        root = updated;
    }

}