/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity >0.4.99 <0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Wallet {
     address public token;
     address payable public hotWallet;
    
    
    constructor(address _token, address payable _hotWallet) public {
        // send all tokens from this contract to hotwallet
        token = _token;
        hotWallet = _hotWallet;
        
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        if (address(this).balance > 0) hotWallet.transfer(address(this).balance);
        // selfdestruct to receive gas refund and reset nonce to 0
        selfdestruct(address(0x0));
    }
}

contract Factory {
    event Deployed(address addr, bytes32 salt);
    
    function deploy(uint256 salt, address _token, address payable _hotWallet) public {
        bytes memory bytecode = abi.encodePacked(type(Wallet).creationCode,uint256(_token),uint256(_hotWallet));
        assembly {
            let codeSize := mload(bytecode) // get size of init_bytecode
            let newAddr := create2(
                0, // 0 wei
                add(bytecode, 32), // the bytecode itself starts at the second slot. The first slot contains array length
                codeSize, // size of init_code
                salt // salt from function arguments
            )
        }
    }
    
    
    function computeAddress(uint256 salt, address _token, address payable _hotWallet) public view returns(address) {
        uint8 prefix = 0xff;
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(Wallet).creationCode,uint256(_token),uint256(_hotWallet)));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
    
    function computeAddress22(uint256 salt, address _token, address payable _hotWallet) public view returns(address) {
        uint8 prefix = 0xff;
        bytes memory bytecode = abi.encodePacked(type(Wallet).creationCode,uint256(_token),uint256(_hotWallet));
        bytes32 initCodeHash = keccak256(abi.encodePacked(bytecode));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
    
}