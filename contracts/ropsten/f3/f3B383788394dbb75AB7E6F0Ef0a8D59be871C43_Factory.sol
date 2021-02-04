/**
 *Submitted for verification at Etherscan.io on 2021-02-03
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
    
    
    constructor(address _token,address payable _hotWallet) public {
        // send all tokens from this contract to hotwallet
        token = _token;
        hotWallet = _hotWallet;
        
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        hotWallet.transfer(address(this).balance);
        // selfdestruct to receive gas refund and reset nonce to 0
        // selfdestruct(address(0x0));
    }
}

contract Factory {
    event Deployed(address addr, uint256 salt);
    
    function deployCode() public pure returns(bytes memory) {
        bytes memory bytecode = type(Wallet).creationCode;
        return bytecode;
    }
    
    function deployToken(address _token) public pure returns(bytes memory) {
        bytes memory code;
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
          code := add(bytecode,_token)
        }
        return code;
    }
    
    function deploy32() public pure returns(bytes memory) {
        bytes memory code;
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
          code := add(bytecode,32)
        }
        return code;
    }
    
    
    function deploy002(uint256 salt) public returns(address) {
        address addr;
        bytes memory bytecode = type(Wallet).creationCode;
        assembly {
          addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        emit Deployed(addr, salt);
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