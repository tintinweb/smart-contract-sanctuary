pragma solidity ^0.4.24;

contract GasForwardInterface{
    function forwardGas(address behalfOf, uint cUsage) public;
}

contract ERC20VaultInterface{
    function internalTransfer(int delta, address target, address from) public;
}

//0x627306090abab3a6e1400e9345bc60c78a8bef57


contract OffchainRolling {
    
    GasForwardInterface GasForwarder;
    ERC20VaultInterface ERC20UserVault;
    //0x0000000000000000000000000000000000000000000000000000000000000fff
    mapping(address => uint) public txCount;
    mapping(address => bool) public notary;
    
    uint public minBet = 1e18;
    uint public maxBet = 100e18;
    
    address owner = msg.sender;

    constructor(address GF, address UV) public {
        GasForwarder = GasForwardInterface(GF);
        ERC20UserVault = ERC20VaultInterface(UV);
    }
    
    function ownerSetMinBet(uint n) public {
        require(msg.sender == owner);
        minBet = n;   
    }
    
    function ownerSetMaxBet(uint n) public {
        require(msg.sender == owner);
        maxBet = n;           
    }

    function setNotary(address newNotary, bool targ) public {
        require(msg.sender == owner);
        notary[newNotary] = targ;
    }
    
    function getHashedData(uint Nonce, uint Value, bytes32 UserSeed, bytes32 ServerSeed, uint Rolls) public pure returns (bytes32){
        return keccak256(abi.encodePacked(Nonce, Value, UserSeed, ServerSeed, Rolls));
    }

    function soliditySha3(bytes32 hash) public pure returns (bytes32){
        return keccak256(abi.encodePacked(hash));
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function checkHash(bytes32 chainstart, bytes32 endstart, uint rolls) public pure returns (bool){
        bytes32 sHash = chainstart;
        for (uint i=0; i<rolls; i++){
            sHash = keccak256(abi.encodePacked(sHash));
        }
        return (sHash == endstart);
    }//0x5a704744927776cd7d72709bd96a4c0f0d45a846

    function web3ViewRoll(bytes32 unHashedSeed, bytes32 UserSeed, uint Rolls, uint bet, uint Nonce) public pure returns (int, uint8[]){
        uint8[] memory arr = new uint8[](Rolls);
        int delta=0;
        bytes32 cHash;
        bytes32 sHash = unHashedSeed;
        for (uint i=0; i<Rolls; i++){
            cHash = keccak256(abi.encodePacked(sHash,UserSeed,Nonce+i)); 
            sHash = keccak256(abi.encodePacked(sHash));
            if (uint(cHash) % 100 <=44){
                delta += int(bet);
            }
            else{
                delta -= int(bet);
            }
            arr[i] = uint8(uint(cHash) % 100);
        }
        return (delta, arr);
    }

    function internalDoRoll(bytes32 unHashedSeed, bytes32 UserSeed, uint Rolls, uint bet, uint Nonce) public pure returns (int, bytes32){
        int delta=0;
        bytes32 cHash;
        bytes32 sHash = unHashedSeed;
        for (uint i=0; i<Rolls; i++){
            cHash = keccak256(abi.encodePacked(sHash,UserSeed,Nonce+i)); 
            sHash = keccak256(abi.encodePacked(sHash));
            if (uint(cHash) % 100 <=44){
                delta += int(bet);
            }
            else{
                delta -= int(bet);
            }
        }
        return (delta, sHash);
    }
    
    function externalCheckSignBool(bytes32 hash, bytes Recover, address Gambler) public returns (bool) {
        bytes32 realhash = prefixed(hash);
        return (ecverify(realhash, Recover, Gambler));
    }
    
    function externalCheckSign(bytes32 hash, bytes Recover, address Gambler) public {
        bytes32 realhash = prefixed(hash);
        require(ecverify(realhash, Recover, Gambler));
    }

    function _roll(address Gambler, uint Nonce, uint Value, bytes32 UserSeed, bytes32 ServerSeed, bytes Recover, bytes32 unHashedSeed, uint Rolls) public{
        require( (txCount[Gambler] == 0 && Nonce == 0) || txCount[Gambler] == (Nonce));
        txCount[Gambler] = txCount[Gambler]+1; 
        require(notary[tx.origin]);
        bytes32 hash = prefixed(getHashedData(Nonce, Value, UserSeed, ServerSeed, Rolls));
        require(ecverify(hash, Recover, Gambler));
        uint bet = Value / Rolls;
        require(bet >= minBet);
        require(bet <= maxBet);
        (int delta, bytes32 cHash) = internalDoRoll(unHashedSeed, UserSeed, Rolls, bet, Nonce);
        require(cHash == ServerSeed); // verify seed 
        ERC20UserVault.internalTransfer(delta, Gambler, tx.origin);
    }
    //0x8ac5025a2b47b9be5ed0c77cebd60e69e4251a32d8fde879d298ad81571c0efc32a3d8abf914bdebaea8b1ed7a6aa58da369afa6fb92bbcc6d01d19e01424f451b
    function getData(bytes data) internal pure returns (bytes32[] rem) {
            bytes32[] memory out_b;
            uint len = data.length/32;
            if (data.length % 32 != 0){
                len += 1;
            }
            assembly {
                out_b := mload(0x40)
                mstore(0x40, add(mload(0x40), add(mul(len, 0x20), 0x40))) 
                mstore(out_b, len)
                for { let i := 0 } lt(i, len) { i := add(i, 0x1) } {
                    let mem_slot := add(out_b, mul(0x20, add(i,1)))
                    let load_slot := add(data,mul(0x20, add(i,1)))
                    mstore(mem_slot, mload(load_slot))
                }
            }
        return (out_b);
    }
    
    function roll_normal(address Gambler, uint Nonce,uint Value,bytes32 UserSeed,bytes32 ServerSeed, bytes Recover, bytes32 unHashedSeed, uint Rolls) public {
        uint gas = gasleft();
        _roll(Gambler, Nonce, Value, UserSeed, ServerSeed, Recover, unHashedSeed, Rolls);
        GasForwarder.forwardGas(Gambler, gas - gasleft());
    }
    
    // use bytes data because of tokenFallback;
   /* function roll(bytes data_iput){
        uint gas = gasleft();
        uint gasprice = tx.gasprice;
        bytes32[] memory data = getData(data_iput);
        bytes32 Gambler = data[1];
        bytes32 Nonce = data[3];
        bytes32 Value = data[5];
        bytes32 UserSeed = data[7];
        bytes32 ServerSeed = data[9];
        bytes32 Recover = data[11];
        // can revert but user still has to pay for gas 
        address(this).call(abi.encodeWithSignature("_roll(address,uint256,uint256,bytes32,bytes32,bytes32)", Gambler, Nonce, Value, UserSeed, ServerSeed, Recover)); 
    }*/
    
/*
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) internal returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return address(0x0);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27)
          v += 27;
        if (v != 27 && v != 28)
            return address(0x0);
        return ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) public returns (bool) {

        address addr;
        addr = ecrecovery(hash, sig);
        return addr == signer;
    }
*/

    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27)
          v += 27;
        if (v != 27 && v != 28)
            return (false, 0);
        return safer_ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) internal returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }

}