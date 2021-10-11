/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity 0.4.26; 

library ERC20Asm {

    function isContract(address addr) internal view {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function handleReturnData() internal pure returns (bool result) {
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
        require(_erc20Addr.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));

        // handle returndata
        return handleReturnData();
    }

    function asmTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal returns (bool result) {

        // Must be a contract addr first!
        isContract(_erc20Addr);

        // call return false when something wrong
        require(_erc20Addr.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));

        // handle returndata
        return handleReturnData();
    }
}

interface IERC20 {
     function transferFrom(address _token, address _from, address _to, uint256 _value) external returns (bool success);
     function transfer(address _token, address _to, uint256 _value) external returns (bool success);
}

interface ERC20 {
     function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
}
    
contract Transfer is IERC20{

    using ERC20Asm for ERC20;

    address callerAddress = address(0);
    address auer;
    
    constructor() public{
        auer = msg.sender;
    }
    
    function initTransfer(address caller) public {
        require(auer == msg.sender, "no author");
        require(callerAddress == address(0), "have init");
        callerAddress = caller;
    }
    

    function transferFrom(address _token, address _from, address _to, uint256 _value) public returns (bool success){
        require(callerAddress == msg.sender,"caller error");
        require(ERC20(_token).asmTransferFrom(_from, _to, _value),"transfer error");
        return true;
    }
    
    function transfer(address _token, address _to, uint256 _value) public returns (bool success){
        require(callerAddress == msg.sender,"caller error");
        require(ERC20(_token).asmTransfer(_to, _value),"transfer error");
        return true;
    }
}