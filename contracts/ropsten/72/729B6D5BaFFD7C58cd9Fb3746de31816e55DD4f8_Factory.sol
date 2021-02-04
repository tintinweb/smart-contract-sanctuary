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
    
    //常用写法：
    function joinString(string memory _str1, string memory _str2) public pure returns (string memory){
        bytes memory _str1ToBytes = bytes(_str1);
        bytes memory _str2ToBytes = bytes(_str2);
        string memory ret = new string(_str1ToBytes.length + _str2ToBytes.length);
        bytes memory retTobytes = bytes(ret);
        uint index = 0;
        for (uint i = 0; i < _str1ToBytes.length; i++)retTobytes[index++] = _str1ToBytes[i];
        for (uint i = 0; i < _str2ToBytes.length; i++) retTobytes[index++] = _str2ToBytes[i];
        return string(retTobytes);
    } 
    
    function test001(bytes memory _str) public pure returns (string memory){
        bytes memory retTobytes;
        uint index = 0;
        for (uint i = 2; i < _str.length; i++) retTobytes[index++] = _str[i];
        return string(retTobytes);
    } 
    
    
    // // solidity address转账成64位bytes
    // function deploy002(uint256 salt,address _token,address payable _hotWallet) public returns(address) {
    //     address addr;
    //     bytes memory bytecode = type(Wallet).creationCode;
    //     assembly {
    //       addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    //     }
    //     emit Deployed(addr, salt);
    //     return addr;
    // }
    
    
     function computeAddress(uint256 salt) public view returns(address) {
        uint8 prefix = 0xff;
        bytes memory code = type(Wallet).creationCode;
        bytes32 initCodeHash = keccak256(abi.encodePacked(code));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
    
}