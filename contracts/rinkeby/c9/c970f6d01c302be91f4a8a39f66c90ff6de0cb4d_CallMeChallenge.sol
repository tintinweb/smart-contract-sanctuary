/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.4.18;

contract CallMeChallenge {
     address owner = 0x0;

    function CallMeChallenge() public payable {
        owner = msg.sender;
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
    
    //直接转账

    function transferEth(address _to) public payable returns (bool) {
        require(_to != address(0));

        require(msg.sender == owner);

        _to.transfer(msg.value);

        return true;
    }


}