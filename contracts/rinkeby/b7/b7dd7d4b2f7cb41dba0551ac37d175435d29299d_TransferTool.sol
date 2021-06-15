/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.4.18;
contract TransferTool {
 
    address owner = 0x0;
    //添加payable,支持在创建合约的时候，value往合约里面传eth
        function TransferTool () public  payable{
            owner = msg.sender;
        }

 
         function checkBalance() public view returns (uint) {
             return address(this).balance;
         }
         //添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
        function () payable public {
        }
        function destroy() public {
            require(msg.sender == owner);
            selfdestruct(msg.sender);
         }
 //token转账
    function transferTokensAvg(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
          
          require(caddress.call(id,from,_tos[i],v));
        }
        return true;
    }
      function transferTokens(address from,address caddress,address[] _tos,uint[] values)public returns (bool){
        require(_tos.length > 0);
        require(values.length > 0);
        require(values.length == _tos.length);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
           require(caddress.call(id,from,_tos[i],values[i]));
        }
        return true;
    }
}