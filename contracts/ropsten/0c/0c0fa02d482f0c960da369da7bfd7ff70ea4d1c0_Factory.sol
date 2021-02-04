/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity ^0.6.2;

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
        token = _token;
        hotWallet = _hotWallet;
    }
    
    function transfer001() public {
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );
        if (address(this).balance > 0) hotWallet.transfer(address(this).balance);
    }
}

contract Factory {
    event Deployed(address addr);
    
    
    function deploy(address _token, address payable _hotWallet, bytes32 _salt) public {
        Wallet a = new Wallet{salt: _salt}(_token, _hotWallet);
        emit Deployed(address(a));
    }
    
    function deploy002(address _token, address payable _hotWallet, bytes32 _salt) public {
        bytes memory deploymentData = abi.encodePacked(
            type(Wallet).creationCode,
            uint256(_token),
            uint256(_hotWallet)
        );

        address a;
        assembly {
            a := create2(
                0x0, add(0x20, deploymentData), mload(deploymentData), _salt
            )
        }
        emit Deployed(a);
    }
    
    function computeAddress(address _token, address payable _hotWallet, bytes32 _salt) public view returns(address) {
        uint8 prefix = 0xff;
        bytes memory code = abi.encodePacked(
            type(Wallet).creationCode,
            uint256(_token),
            uint256(_hotWallet)
        );
        bytes32 initCodeHash = keccak256(abi.encodePacked(code));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), _salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
    
}