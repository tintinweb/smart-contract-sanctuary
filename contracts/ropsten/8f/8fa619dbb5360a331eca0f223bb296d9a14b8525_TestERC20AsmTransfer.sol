/*

badERC20 POC Fix by SECBIT Team

USE WITH CAUTION & NO WARRANTY

REFERENCE & RELATED READING
- https://github.com/ethereum/solidity/issues/4116
- https://medium.com/@chris_77367/explaining-unexpected-reverts-starting-with-solidity-0-4-22-3ada6e82308c
- https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
- https://gist.github.com/BrendanChou/88a2eeb80947ff00bcf58ffdafeaeb61

*/

pragma solidity ^0.4.24;

library ERC20AsmFn {

    function isContract(address addr) internal {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function handleReturnData() internal returns (bool result) {
        assembly {
            switch returndatasize()
            case 0 { // not a std erc20
                result := 1
            }
            case 32 { // std erc20
                returndatacopy(0, 0, 32)
                result := mload(0)
            }
            default { // anything else, should revert for safety
                revert(0, 0)
            }
        }
    }

    function asmTransfer(address _erc20Addr, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);
        
        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256(&quot;transfer(address,uint256)&quot;)), _to, _value));
        
        // handle returndata
        return handleReturnData();
    }

    function asmTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256(&quot;transferFrom(address,address,uint256)&quot;)), _from, _to, _value));
        
        // handle returndata
        return handleReturnData();
    }

    function asmApprove(address _erc20Addr, address _spender, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256(&quot;approve(address,uint256)&quot;)), _spender, _value));
        
        // handle returndata
        return handleReturnData();
    }
}

interface ERC20 {
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
}

contract TestERC20AsmTransfer {

    using ERC20AsmFn for ERC20;

    function dexTestTransfer(address _token, address _to, uint256 _value) public {
        require(ERC20(_token).asmTransfer(_to, _value));
    }

    function dexTestTransferFrom(address _token, address _from, address _to, uint256 _value) public {
        require(ERC20(_token).asmTransferFrom(_from, _to, _value));
    }

    function dexTestApprove(address _token, address _spender, uint256 _value) public {
        require(ERC20(_token).asmApprove(_spender, _value));
    }
    
    function dexTestNormalTransfer(address _token, address _to, uint256 _value) public {
        require(ERC20(_token).transfer(_to, _value));
    }
}