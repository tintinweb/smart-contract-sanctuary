pragma solidity ^0.4.19;

contract EventStorage {
    
    struct BlockHeader {
        bytes32 derivedHash;        
        bytes32 parentHash;         
        bytes32 ommersHash;         
        
        bytes32 stateRoot;          
        bytes32 transactionsRoot;   
        bytes32 receiptsRoot;         
    
        bytes32 mixHash;            
        bytes32 extraData;          
        
        address miner;              
        
        bytes8 nonce;               

        uint difficulty;            
        uint32 blockNumber;         
        uint32 gasLimit;            
        uint32 gasUsed;             
        uint32 timeStamp;           
                                    
        bytes logsBloom;
    }
    
    bytes32 constant eventTopic = keccak256(keccak256(&quot;DataStored(bytes32,bytes)&quot;));
    
    event DataStored(bytes32 indexed _data, bytes data);
    
    BlockHeader bh;
    
    function getHashes() public view returns (bytes32 derivedHash, bytes32 parentHash, bytes32 ommersHash) { return (bh.derivedHash, bh.parentHash, bh.ommersHash); }
    function getRoots() public view returns (bytes32 stateRoot, bytes32 txRoot, bytes32 receiptsRoot) { return (bh.stateRoot, bh.transactionsRoot, bh.receiptsRoot); }
    function getData() public view returns (bytes32 mixHash, bytes32 extraData, address miner, bytes8 nonce, uint diff, uint32 number, uint32 gasLimit, uint32 gasUsed, uint32 timestamp, bytes bloom) {
        return (
            bh.mixHash, bh.extraData, bh.miner, bh.nonce, bh.difficulty, bh.blockNumber, bh.gasLimit, bh.gasUsed, bh.timeStamp, bh.logsBloom
        );
    }
    
    function StoreBytes(bytes data) public {
        emit DataStored(keccak256(data), data);
    }
    
    function ValidateAndStore(bytes rlpBlockHeader, bytes data) public returns (bool valid){
        bytes memory logsBloom = parseAndStore(rlpBlockHeader).logsBloom;
        
        bytes32 _topic1 = keccak256(address(this));
        bytes32 _topic2 = eventTopic;
        bytes32 _topic3 = keccak256(keccak256(data));
        
        bool foundInLogs = true;
        
        for(uint b = 0; b < 8; b++) {
            bytes32 bloom = 0;
            for(uint i = 0; i < 6; i += 2) {
                assembly {
                    if eq(mod(byte(i, _topic1),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic1)))
                    }
                    if eq(mod(byte(i, _topic2),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic2)))
                    }
                    if eq(mod(byte(i, _topic3),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic3)))
                    }
                }
            }
            
            assembly {
                if gt(bloom, 0) {
                    let bloomAnd := and(mload(add(logsBloom,mul(0x20,sub(8,b)))),bloom)
                    let equal := eq(bloomAnd,bloom)
                    
                    if eq(equal,0) {
                        b := 8
                        foundInLogs := 0
                    }
                }
            }
        }
        
        valid = foundInLogs;
    }
    
    function parseAndStore(bytes rlpData) internal returns (BlockHeader) {
        BlockHeader memory parsedHeader;
        
        parsedHeader.derivedHash = keccak256(rlpData);
        bytes memory logsBloom = new bytes(256);
        
        assembly {
            calldatacopy(add(parsedHeader,32), 104, 32)                 //parentHash
            calldatacopy(add(parsedHeader,64), 137, 32)                 //ommersHash
            calldatacopy(add(parsedHeader,268), 170, 20)                //miner    
            calldatacopy(add(parsedHeader,96), 191, 32)                 //stateRoot
            calldatacopy(add(parsedHeader,128), 224, 32)                //transactionsRoot
            calldatacopy(add(parsedHeader,160), 257, 32)                //receiptsRoot
            
            calldatacopy(add(logsBloom,32), 292, 256)                   //logsBloom
            
            let _size := sub(and(calldataload(517), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(352,_size)), 549, _size)  //difficulty
            
            let _idx := add(add(549,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(384,_size)), _idx, _size) //blockNumber
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(416,_size)), _idx, _size) //gasLimit
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(448,_size)), _idx, _size) //gasUsed
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(480,_size)), _idx, _size) //timeStamp
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(256,_size)), _idx, _size) //extraData
            
            _idx := add(add(_idx,_size),1)
            calldatacopy(add(parsedHeader,192), _idx, 32)               //mixHash

            _idx := add(_idx,33)
            calldatacopy(add(parsedHeader,288), _idx, 8)                //nonce
        }
        
        parsedHeader.logsBloom = logsBloom;
        
        require(parsedHeader.derivedHash == blockhash(parsedHeader.blockNumber));
        bh = parsedHeader;
        return parsedHeader;
    }
    
    function ValidateEventStorage(bytes rlpBlockHeader, bytes data) public view returns (bool valid){
        bytes memory logsBloom = parseRLPHeader(rlpBlockHeader).logsBloom;
        
        bytes32 _topic1 = keccak256(address(this));
        bytes32 _topic2 = eventTopic;
        bytes32 _topic3 = keccak256(keccak256(data));
        
        bool foundInLogs = true;
        
        for(uint b = 0; b < 8; b++) {
            bytes32 bloom = 0;
            for(uint i = 0; i < 6; i += 2) {
                assembly {
                    if eq(mod(byte(i, _topic1),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic1)))
                    }
                    if eq(mod(byte(i, _topic2),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic2)))
                    }
                    if eq(mod(byte(i, _topic3),8), b) {
                        bloom := or(bloom, exp(2,byte(add(1,i), _topic3)))
                    }
                }
            }
            
            assembly {
                if gt(bloom, 0) {
                    let bloomAnd := and(mload(add(logsBloom,mul(0x20,sub(8,b)))),bloom)
                    let equal := eq(bloomAnd,bloom)
                    
                    if eq(equal,0) {
                        b := 8
                        foundInLogs := 0
                    }
                }
            }
        }
        
        valid = foundInLogs;
    }
    
    function parseRLPHeader(bytes rlpData) internal view returns (BlockHeader) {
        BlockHeader memory parsedHeader;
        
        parsedHeader.derivedHash = keccak256(rlpData);
        bytes memory logsBloom = new bytes(256);
        
        assembly {
            calldatacopy(add(parsedHeader,32), 104, 32)                 //parentHash
            calldatacopy(add(parsedHeader,64), 137, 32)                 //ommersHash
            calldatacopy(add(parsedHeader,268), 170, 20)                //miner    
            calldatacopy(add(parsedHeader,96), 191, 32)                 //stateRoot
            calldatacopy(add(parsedHeader,128), 224, 32)                //transactionsRoot
            calldatacopy(add(parsedHeader,160), 257, 32)                //receiptsRoot
            
            calldatacopy(add(logsBloom,32), 292, 256)                   //logsBloom
            
            let _size := sub(and(calldataload(517), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(352,_size)), 549, _size)  //difficulty
            
            let _idx := add(add(549,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(384,_size)), _idx, _size) //blockNumber
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(416,_size)), _idx, _size) //gasLimit
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(448,_size)), _idx, _size) //gasUsed
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(480,_size)), _idx, _size) //timeStamp
            
            _idx := add(add(_idx,_size),1)
            _size := sub(and(calldataload(sub(_idx,32)), 0xFF), 128)
            calldatacopy(add(parsedHeader,sub(256,_size)), _idx, _size) //extraData
            
            _idx := add(add(_idx,_size),1)
            calldatacopy(add(parsedHeader,192), _idx, 32)               //mixHash

            _idx := add(_idx,33)
            calldatacopy(add(parsedHeader,288), _idx, 8)                //nonce
        }
        
        parsedHeader.logsBloom = logsBloom;
        
        require(parsedHeader.derivedHash == blockhash(parsedHeader.blockNumber));

        return parsedHeader;
    }
}

contract GasMeterValidation {
    
    bytes constant rlpHeader = hex&quot;f90202a0bb40f5ea64d3818889d53a5228fd8d5b40b5cf054b4a43cf2f13a284dea307f5a0dbbc448dce3f730703962e9f1af001069ff5fa57b38feeb24fb7def33fe05eaa94bbf5029fd710d227630c8b7d338051b8e76d50b3a05adaa7a9844707268c54d92ba3dff4cedeac2b2c0ea4bf907510d41c6c5134baa0083f94d1d425785c79b3831f010383e8a7bec11ccb3959bfa25c676e1d21d153a0c6093a5eceffdec3e547094a5acb1e7678a9e963e55f58a5ca316893e4338453b9010000000002000000000000000101000000108080000001001000000000000000000000000000080000000000000000000000000000040000000020002000400000010080000020020000800008000000000000000000000000004000000000000008800000020000000000000000000000080000000000400000000010040040000000010000100000040000040000020000040000200000002000000000200050004080000000000020000000003000200000000000008000000000000000004200000002000015000400880000000010000000000000000000000000080000803000000008080000000040001000000020000000000200008010000000100000847c1da7408337cae58347e7ca830d1042845b4e18b98474657374a001098418d5b0f7d3c113a1a5da8ea1a5d08aa68a2db9d4e43f35eea4c3e1f75688ec4f434001ec9ffa&quot;;
    bytes constant data = hex&quot;54686520717569636b2c2062726f776e20666f78206a756d7073206f76657220746865206c617a7920626c61636b20646f672e&quot;;
    
    uint public gas_used;
    bool public succeeded;
    
    function validate(bytes, bytes) public {
        uint lim_before;
        uint lim_after;
        bytes4 sel = bytes4(keccak256(&#39;ValidateEventStorage(bytes,bytes)&#39;));
        bool success;
        assembly {
            let ptr_in := mload(0x40)
            mstore(ptr_in, sel)
            calldatacopy(add(0x04, ptr_in), 0x04, sub(calldatasize, 0x04))
            lim_before := gas
            let ret := staticcall(gas, 0xbab537fd1537f46cedddbdd0a6f96ea50e25e772, ptr_in, calldatasize, 0, 0)
            lim_after := gas
            if iszero(eq(returndatasize, 0x20)) { revert(0, 0) }
            returndatacopy(0, 0, returndatasize)
            success := mload(0)
        }
        gas_used = lim_before - lim_after - 6000; // 6k for staticcall
        succeeded = success;
    }
}