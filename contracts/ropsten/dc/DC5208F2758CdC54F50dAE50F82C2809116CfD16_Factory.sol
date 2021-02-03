/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity 0.5.6;

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
    address internal token = 0xC03De54B8004e309cdf11100dd1565ec3341f625;
    address payable internal hotWallet = 0x68B0af36Fa22b52904D8D423eff053C26d3848dD;
    constructor() public {
        // send all tokens from this contract to hotwallet
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        // hotWallet.transfer(address(this).balance);
        // selfdestruct to receive gas refund and reset nonce to 0
        selfdestruct(address(0x0));
    }
}

contract Factory {
    event Deployed(address addr, uint256 salt);
    
    function deploy(uint256 salt) public {
        // get wallet init_code
        bytes memory bytecode = type(Wallet).creationCode;
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
    
    function test001() public view returns(bytes memory) {
        bytes memory bytecode = type(Wallet).creationCode;
        return bytecode;
    }
    function deploy002(uint256 salt) public returns(address) {
        address addr;
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
          addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        //   if iszero(extcodesize(addr)) {
        //     revert(0, 0)
        //   }
        }
        // emit Deployed(addr, salt);
        return addr;
    }
    
    
     function computeAddress(uint256 salt) public view returns(address) {
        uint8 prefix = 0xff;
        bytes memory code = type(Wallet).creationCode;
        bytes32 initCodeHash = keccak256(abi.encodePacked(code));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
    
}