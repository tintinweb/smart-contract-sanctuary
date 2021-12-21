/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Tree {
    address public owner;

    struct ElementStruct {
        address elementId;
        address parentId;
        bool isElement;
        address[] children;
    }

    mapping(address => ElementStruct) public elements;
    address[] public elementsRegistry;

    event ElementAdded(address _elementId, address _parentId);
    event ElementMoved(address _elementId, address _parentId);

    constructor() {
        owner = msg.sender;

        elements[owner] = ElementStruct(owner, address(0), true, new address[](0));
        elementsRegistry.push(owner);
    }

    function addElement(address _elementId, address _parentId) public {
        require(msg.sender == owner);
        require(!isElement(_elementId));
        require(isElement(_parentId));
        require(_elementId != _parentId);

        elements[_elementId] = ElementStruct(_elementId, _parentId, true, new address[](0));
        elements[_parentId].children.push(_elementId);

        elementsRegistry.push(_elementId);

        assert(isElement(_elementId));

        emit ElementAdded(_elementId, _parentId);
    }

    function moveElement(address _elementId, address _parentId) public {
        require(msg.sender == owner);
        require(isElement(_elementId));
        require(isElement(_parentId));
        require(_elementId != _parentId);

        removeChild(elements[_elementId].parentId, _elementId);
        elements[_elementId].parentId = _parentId;
        elements[_parentId].children.push(_elementId);

        assert(isElement(_elementId));

        emit ElementMoved(_elementId, _parentId);
    }

    function removeElement(address _elementId) public {
        require(msg.sender == owner);
        require(isElement(_elementId));
        require(_elementId != owner);

        uint idxToRemove = 0;
        bool hasIdxToRemove = false;
        for (uint i = 0; i < elementsRegistry.length; i++) {
            if (elements[elementsRegistry[i]].elementId == _elementId) {
                idxToRemove = i;
                hasIdxToRemove = true;
            }

            if (elements[elementsRegistry[i]].parentId == _elementId) {
                moveElement(elementsRegistry[i], elements[_elementId].parentId);
            }
        }

        assert(hasIdxToRemove == true);

        delete elements[_elementId];
        elementsRegistry[idxToRemove] = elementsRegistry[elementsRegistry.length - 1];
        elementsRegistry.pop();
    }

    function getElement(address _elementId) view public returns (address, address) {
        require(isElement(_elementId));

        return (elements[_elementId].elementId, elements[_elementId].parentId);
    }

    function getElementChildren(address _elementId) public view returns (address[] memory) {
        require(isElement(_elementId));

        return elements[_elementId].children;
    }

    function getElementsRegistry() view public returns (address[] memory) {
        return elementsRegistry;
    }

    function getElementParent(address _elementId) view public returns (address) {
        require(isElement(_elementId));

        return elements[_elementId].parentId;
    }

    function getElementParents(address _elementId) view public returns (address[] memory){
        require(isElement(_elementId));

        address current = _elementId;

        uint level = getElementLevel(_elementId);
        address[] memory parents = new address[](level);

        for (uint i = 0; i < level; i++) {
            current = elements[current].parentId;
            if (isElement(current)) {
                parents[i] = current;
            }
        }

        return parents;
    }

    function getElementLevel(address _elementId) view public returns (uint) {
        require(isElement(_elementId));

        uint level = 0;

        address current = _elementId;
        while (isElement(current)) {
            current = elements[current].parentId;
            if (isElement(current)) {
                level++;
            }
        }

        return level;
    }

    function isElement(address _elementId) view private returns (bool) {
        return elements[_elementId].isElement;
    }

    function removeChild(address _elementId, address _childId) private {
        require(isElement(_elementId));

        uint idxToRemove = 0;
        bool hasIdxToRemove = false;
        for (uint i = 0; i < elements[_elementId].children.length; i++) {
            if (elements[_elementId].children[i] == _childId) {
                idxToRemove = i;
                hasIdxToRemove = true;
            }
        }

        assert(hasIdxToRemove == true);

        delete elements[_elementId].children[idxToRemove];
        elements[_elementId].children[idxToRemove] = elements[_elementId].children[elements[_elementId].children.length - 1];
        elements[_elementId].children.pop();
    }
}