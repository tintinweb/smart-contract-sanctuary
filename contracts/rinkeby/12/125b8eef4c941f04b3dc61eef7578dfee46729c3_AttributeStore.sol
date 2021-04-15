/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

library AttributeStore {
    struct Data {
        mapping(bytes32 => uint) store;
    }

    function getAttribute(Data storage self, bytes32  _UUID, string memory _attrName)
    public view returns (uint) {
        
        bytes32 key = keccak256(abi.encodePacked(_UUID, _attrName));
        return self.store[key];
    }

    function setAttribute(Data storage self, bytes32 _UUID, string memory _attrName, uint _attrVal)
    public {
        bytes32 key = keccak256(abi.encodePacked(_UUID, _attrName));
        self.store[key] = _attrVal;
    }
}