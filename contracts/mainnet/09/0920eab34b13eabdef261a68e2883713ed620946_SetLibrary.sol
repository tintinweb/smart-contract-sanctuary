pragma solidity ^0.4.17;

library SetLibrary
{
    struct ArrayIndexAndExistsFlag
    {
        uint256 index;
        bool exists;
    }
    struct Set
    {
        mapping(uint256 => ArrayIndexAndExistsFlag) valuesMapping;
        uint256[] values;
    }
    function add(Set storage self, uint256 value) public returns (bool added)
    {
        // If the value is already in the set, we don&#39;t need to do anything
        if (self.valuesMapping[value].exists == true) return false;
        
        // Remember that the value is in the set, and remember the value&#39;s array index
        self.valuesMapping[value] = ArrayIndexAndExistsFlag({index: self.values.length, exists: true});
        
        // Add the value to the array of unique values
        self.values.push(value);
        
        return true;
    }
    function contains(Set storage self, uint256 value) public view returns (bool contained)
    {
        return self.valuesMapping[value].exists;
    }
    function remove(Set storage self, uint256 value) public returns (bool removed)
    {
        // If the value is not in the set, we don&#39;t need to do anything
        if (self.valuesMapping[value].exists == false) return false;
        
        // Remember that the value is not in the set
        self.valuesMapping[value].exists = false;
        
        // Now we need to remove the value from the array. To prevent leaking
        // storage space, we move the last value in the array into the spot that
        // contains the element we&#39;re removing.
        if (self.valuesMapping[value].index < self.values.length-1)
        {
            uint256 valueToMove = self.values[self.values.length-1];
            uint256 indexToMoveItTo = self.valuesMapping[value].index;
            self.values[indexToMoveItTo] = valueToMove;
            self.valuesMapping[valueToMove].index = indexToMoveItTo;
        }
        
        // Now we remove the last element from the array, because we just duplicated it.
        // We don&#39;t free the storage allocation of the removed last element,
        // because it will most likely be used again by a call to add().
        // De-allocating and re-allocating storage space costs more gas than
        // just keeping it allocated and unused.
        
        // Uncomment this line to save gas if your use case does not call add() after remove():
        // delete self.values[self.values.length-1];
        self.values.length--;
        
        // We do free the storage allocation in the mapping, because it is
        // less likely that the exact same value will added again.
        delete self.valuesMapping[value];
        
        return true;
    }
    function size(Set storage self) public view returns (uint256 amountOfValues)
    {
        return self.values.length;
    }
    
    // Also accept address and bytes32 types, so the user doesn&#39;t have to cast.
    function add(Set storage self, address value) public returns (bool added) { return add(self, uint256(value)); }
    function add(Set storage self, bytes32 value) public returns (bool added) { return add(self, uint256(value)); }
    function contains(Set storage self, address value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function contains(Set storage self, bytes32 value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function remove(Set storage self, address value) public returns (bool removed) { return remove(self, uint256(value)); }
    function remove(Set storage self, bytes32 value) public returns (bool removed) { return remove(self, uint256(value)); }
}