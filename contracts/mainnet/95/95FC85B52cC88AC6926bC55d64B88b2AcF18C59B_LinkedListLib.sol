pragma solidity 0.4.21;

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 *
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.1.0
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-network/ethereum-libraries/blob/master/LICENSE
 *
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
        public
        view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, uint256 _node)
        public
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) public view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, uint256 _node)
        public view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}