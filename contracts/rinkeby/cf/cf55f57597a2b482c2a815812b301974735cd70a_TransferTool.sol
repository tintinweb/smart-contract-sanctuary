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

         //添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
         function transferEths(address[] _tos,uint256[] values) payable public returns (bool) {
                require(msg.sender == owner);
                for(uint32 i=0;i<_tos.length;i++){
                   _tos[i].transfer(values[i]);
                }
             return true;
         }
        //直接转账
         function transferEth(address _to) payable public returns (bool){
                require(_to != address(0));
                require(msg.sender == owner);
                _to.transfer(msg.value);
                return true;
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