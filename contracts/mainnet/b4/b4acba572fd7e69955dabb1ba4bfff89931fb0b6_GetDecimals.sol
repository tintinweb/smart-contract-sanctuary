pragma solidity ^0.4.23;

interface ERC20 {
    function decimals() external view returns(uint);
}

contract GetDecimals {
    function getDecimals(ERC20 token) external view returns (uint){
        bytes memory data = abi.encodeWithSignature("decimals()");
        if(!address(token).call(data)) {
            // call failed
            return 18;
        }
        else {
            return token.decimals();
        }
    }
    
    function getDecimalsBetter(ERC20 token) external view returns(uint) {
        bytes memory data = abi.encodeWithSignature("decimals()");
        uint[1] memory value;
        if(!address(token).call(data)) {
            // call failed
            return 18;
        }
        else {
            assembly {
                returndatacopy(value,0,returndatasize)
                
            }
            
            return value[0];
        }
    }
    
    function testRevert() public pure returns(string) {
        revert("ilan is the king");
        return "hello world";
    }
    
    function testRevertTx() public returns(string) {
        return testRevert();
    }    
}