pragma solidity 0.8.0;

contract callFees {

function callFee (uint256 tokenId) public view returns (uint256 fees0,uint256 fees1){
    address ULM = 0x274E879A747251e618e614d0343A350a5AEBd8ca;
    (bool success, bytes memory result)  = ULM.staticcall(abi.encodeWithSignature("getUserFees(uint256)",tokenId));
    (fees0,fees1) = abi.decode(result,(uint256,uint256));
}
}