/**
 *Submitted for verification at Etherscan.io on 2020-05-25
*/

pragma solidity ^0.6.0;

interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
}


contract Deloyer {
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    event ContractCreated(address);
    
    modifier burnGas(uint _amount) {
        uint gst2Amount = _amount;

        if (_amount == 0) {
            gst2Amount = (gasleft() + 14154) / (2 * 24000 - 6870);
            gst2Amount = gst2Amount - (gst2Amount / 8); // 12.5% less because of gaslimit != gas_used
        }

        if (gasToken.balanceOf(address(this)) >= gst2Amount) {
            gasToken.free(gst2Amount);
        }

        _;
    }
    
    function deploy(bytes memory _data) public burnGas(0) {
        address contractAddr;
        
         assembly {
            contractAddr := create(0, add(_data, 32), mload(_data))
        }
        
        emit ContractCreated(contractAddr);
    }
}