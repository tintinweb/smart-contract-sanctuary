//SourceUnit: trx_token_bridge_direct_out(watcher transferfrom).sol

pragma solidity ^0.4.25;

interface  TRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value)  external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract RoyalTokenBridge{
    address private watcher;
    
    event Deposit(address indexed sender, bytes32 indexed to1,bytes32 indexed to2, uint value);

   constructor (address _watcher) public {
        watcher = _watcher;
    }
    /**
    *  Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    function updateWatcher(address _watcher) public returns (bool){
        require(msg.sender == watcher && _watcher != address(0));
        watcher = _watcher;
        return true;
    }
    /**
     * withdraw by trc20
     * _from : trc20 contract address
     * _to: transfer to  the address
     * _value: the balance want to transfer 
     */ 
    function withdraw(address _from,address _to, uint _value) public returns (bool){
         require(msg.sender == watcher);
         return TRC20(_from).transfer(_to,_value);
    }
     /**
     * transfer to bridge by trc20 transferFrom
     * _from : who 
     * _to: address string, which can get the balance from the contract
     * _value: the balance want to transfer 
     */ 
    function deposit(address _token, address _from, string _to, uint _value) public returns (bool) {
        require(msg.sender == watcher);
        address to = address(this);
       require(TRC20(_token).transferFrom(_from,to,_value)== true);
        (bytes32 result1 ,bytes32 result2) = toBytes(_to);
        emit Deposit(_token, result1,result2, _value);
        return true;
    }
    
    /**
     * convert the TQ address to bytes32 array 
     */
    function toBytes(string  source) internal pure returns(bytes32 result1 ,bytes32 result2){
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