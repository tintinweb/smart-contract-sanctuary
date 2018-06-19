pragma solidity ^0.4.18;

/**
 * Contract that offers a Set structure for uint256 allowing 
 * at the same time to efficiently list all the elements in it.
 */
contract IterableSet {

    // Each element in the set is represented by this structure
    struct Element {
        uint256 value;      // Value of the element
        uint256 next;       // Value of the next element
        uint256 previous;   // Value of the previous element
    }

    // Mapping of values to the corresponding elements
    mapping(uint => Element) elements;

    uint256 public first;  // Id of the first element
    uint256 public last;   // Id of the last element
    uint256 public size;    // Size of the set

    // Adds an provided value to the Set
    function add(uint256 value) public {
        if (!contains(value)) {
            size += 1;
            Element memory element = Element({
                value: value,
                next: first,
                previous: value
            });

            first = value;
            if (size == 1) {
                last = value;
            } else {
                elements[element.next].previous = value;
            }
            elements[value] = element;
        }
    }

    // Removes the given value from the set 
    function remove(uint256 value) public {
        if (contains(value)) {
            Element storage element = elements[value];

            if (first == value) {
                first = element.next;
            } else {
                elements[element.previous].next = element.next;
            }
            if (last == value) {
                last = element.previous;
            } else {
                elements[element.next].previous = element.previous;
            }

            size -= 1;
            delete elements[value];
        }
    }

    // Returns true iff the value is contained in the set
    function contains(uint256 value) public view returns (bool) {
        return size > 0 && (first == value || last == value || elements[value].next != 0 || elements[value].previous != 0);
    }

    // Returns an array containing all the ids in the set
    function values() public view returns (uint256[]) {
        uint256[] memory result = new uint256[](size);
        Element storage position = elements[first];
        uint256 i;
        for (i = 0; i < size; i++) {
            result[i] = position.value;
            position = elements[position.next];
        }
        return result;
    }

    // Returns the next value in the set.
    // Fails if the provided value does not belong to the set or it has not next (it is the last one)
    function next(uint256 value) public view returns (uint256) {
        require(contains(value));
        require(value != last);
        return elements[value].next;
    }

    // Returns the previous value in the set.
    // Fails if the provided value does not belong to the set or it has not previous (it is the first one)
    function previous(uint256 value) public view returns (uint256) {
        require(contains(value));
        require(value != first);
        return elements[value].previous;
    }
}