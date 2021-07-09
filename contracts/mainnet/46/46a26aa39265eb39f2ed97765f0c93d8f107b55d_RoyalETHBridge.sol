/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.4.17;

contract RoyalETHBridge{
    address private watcher;
    event Deposit(bytes32 indexed to1,bytes32 indexed to2, uint value);
    event Withdraw(address indexed to, uint value);

    function RoyalETHBridge (address _watcher) public payable{
        watcher = _watcher;
    }
    /**
     * isContract
     */
     function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

     function deposit(string  _to) public payable  {
        require(!isContract(msg.sender) && msg.sender == tx.origin && msg.value > 0);
        var ( result1 , result2) = toBytes(_to);
        uint msgValue = msg.value;
         Deposit( result1,result2, msgValue);
     }

    function withdraw(address _to, uint256 _value) public {
         require(msg.sender == watcher && _to != address(0));
         uint contractBalance = address(this).balance;
           require(_value > 0 && contractBalance >= _value);
         _to.transfer(_value);
         Withdraw(_to, _value);
    }
    
    function updateWatcher(address _watcher) public returns (bool){
        require(msg.sender == watcher && _watcher != address(0));
        watcher = _watcher;
        return true;
    }
      /**
     * convert the  address to bytes32 array 
     */
    function toBytes(string memory  source) internal pure returns(bytes32 result1 ,bytes32 result2){
       bytes memory value = bytes(source);
        if (value.length == 0) {
            return (0x0,0x0);
        }else if(value.length <= 32){
            assembly {
            result1 := mload(add(source, 32))
            result2 := 0x0
        }
        }else{
            bytes memory remain = substr(value,32);
            assembly {
            result1 := mload(add(source, 32))
            result2 := mload(add(remain, 32))
        }
        }
         
    }
     /**
     * sub  bytes  
     */
     function substr(bytes memory self, uint startIndex) internal pure returns (bytes memory) {
        require(startIndex <= self.length);
        uint len = self.length - startIndex;
        uint addr = dataPtr(self);
        return toBytes(addr + startIndex, len);
    }
     function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }
     function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }
     function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}