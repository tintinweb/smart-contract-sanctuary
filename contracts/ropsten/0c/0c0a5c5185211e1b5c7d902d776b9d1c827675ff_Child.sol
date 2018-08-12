pragma solidity >0.4.23 <0.5.0;

contract Parent {
    int value;

    function setValue(int v) public {
        value = v;
    }

    function getValue() external view returns (int) {
        return value;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }
}

contract Child {
    Parent parent;

    function setParent(address a) public {
        parent = Parent(a);
    }

    function getValue() external view returns (int value) {
        return parent.getValue();
    }

    function getSender() external view returns (address value) {
        return parent.getSender();
    }
}