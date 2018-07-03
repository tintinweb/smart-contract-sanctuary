pragma solidity ^0.4.23;

contract TestERC20 {
    
    bytes public constant bts = hex&quot;6000357C0100000000000000000000000000000000000000000000000000000000900463FFFFFFFF16806318160DDD141560465768056BC75E2D6310000060005260206000F35B8063313CE5671415605C57601260005260206000F35B806306FDDE03141560A0577F41757468696f000000000000000000000000000000000000000000000000000060208060005280600690526040909190526003026000F35B806395D89B41141560E4577F415554480000000000000000000000000000000000000000000000000000000060208060005280600490526040909190526003026000F35B6001806000525B8060641160F85760206000F35B80420273FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9033027Fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206000A360010160EB56&quot;;
    
    constructor () public {
        bytes memory contract_identifier = bts;
        assembly { return(add(0x20, contract_identifier), mload(contract_identifier)) }
    }
    
    string public constant name = &quot;Hello there my boi&quot;;
    string public constant symbol = &quot;ABC123&quot;;
    uint public constant decimals = 122;
    uint public constant totalSupply = 1;
    
    function transfer(address, uint) public returns (bool) { return true; }
    
    function approve(address, uint) public returns (bool) { return true; }
    
    function transferFrom(address, address, uint) public returns (bool) { return true; }
}