/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Tree {
    address public owner;

    struct ElementStruct {
        address elementId;
        address parentId;
        bool isElement;
    }

    mapping(address => ElementStruct) public elements;
    address[] public elementsRegistry;

    event ElementAdded(address _elementId, address _parentId);
    event ElementMoved(address _elementId, address _parentId);

    constructor() {
        owner = msg.sender;

        elements[owner] = ElementStruct(owner, address(0), true);
        elementsRegistry.push(owner);
    }

    function addElement(address _elementId, address _parentId) public {
        require(msg.sender == owner);
        require(!isElement(_elementId));
        require(isElement(_parentId));
        require(_elementId != _parentId);

        elements[_elementId] = ElementStruct(_elementId, _parentId, true);
        elementsRegistry.push(_elementId);

        assert(isElement(_elementId));

        emit ElementAdded(_elementId, _parentId);
    }

    function moveElement(address _elementId, address _parentId) public {
        require(msg.sender == owner);
        require(isElement(_elementId));
        require(isElement(_parentId));
        require(_elementId != _parentId);

        elements[_elementId].parentId = _parentId;

        assert(isElement(_elementId));

        emit ElementMoved(_elementId, _parentId);
    }

    function removeElement(address _elementId) public {
        require(msg.sender == owner);
        require(isElement(_elementId));
        require(_elementId != owner);

        uint idxToRemove = 0;
        for (uint i = 0; i < elementsRegistry.length; i++) {
            if (elements[elementsRegistry[i]].elementId == _elementId) {
                idxToRemove = i;
            }

            if (elements[elementsRegistry[i]].parentId == _elementId) {
                moveElement(elementsRegistry[i], elements[_elementId].parentId);
            }
        }

        assert(idxToRemove != 0);

        delete elements[_elementId];
        elementsRegistry[idxToRemove] = elementsRegistry[elementsRegistry.length - 1];
        elementsRegistry.pop();
    }

    function getElement(address _elementId) view public returns (address, address) {
        require(isElement(_elementId));

        return (elements[_elementId].elementId, elements[_elementId].parentId);
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
}