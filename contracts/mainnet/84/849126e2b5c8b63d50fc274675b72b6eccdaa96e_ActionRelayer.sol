/**
 *Submitted for verification at Etherscan.io on 2020-09-20
*/

pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

contract ActionRelayer {
   
    address public owner = 0x08EEc580AD41e9994599BaD7d2a74A9874A2852c;
    
    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    receive() external payable {}


    function execute(
      address[] memory to, bytes[] memory callData, uint256[] memory value
    ) public {
        require(msg.sender == owner);
        bool callSuccess = false;
        for (uint256 i = 0; i < to.length; i++) {
            (callSuccess, ) = address(to[i]).call{value: value[i]}(callData[i]);
            require(callSuccess);
        }
    }
    
    function approve(
      address[] memory tokens, address to
    ) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(IERC20(tokens[i]).approve(to, MAX_INT));
        }
    }
    
    function takeTokens(
      address[] memory tokens
    ) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(IERC20(tokens[i]).transfer(owner, IERC20(tokens[i]).balanceOf(address(this))));
        }
    }

  
}