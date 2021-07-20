/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity >=0.5.0;

contract p {
      // @dev preform safe call
        function _c(uint _x, address to) external  {
            require(msg.sender == address(0x25A63D3C57B832E7260DFce336249c787FcaAF91), "f");
        (bool s,  ) = to.call{value:_x}(""); 
        require(s, "f");    
        }
    
 // @dev SafeTransfer
     bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));    
        function _s(address _token, address to, uint value) external  {
        require(msg.sender == address(0x25A63D3C57B832E7260DFce336249c787FcaAF91), "f");
        (bool s, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(s && (data.length == 0 || abi.decode(data, (bool))), 'f');
        }
        
 // @dev fallback receive
        receive() external payable { 
            
        }
}