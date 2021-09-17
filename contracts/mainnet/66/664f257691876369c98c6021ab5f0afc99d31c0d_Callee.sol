/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract Callee {
    function CompraMierdas(address weth_address, address destination, address[] calldata pairs, uint256[] calldata prices_wei) external payable
     {
         if (msg.value > 0)
            MeteDineros(weth_address);
            
         for(uint i = 0; i < pairs.length ; i++)
         {
             weth_address.call(abi.encodeWithSelector(0xa9059cbb, pairs[i], prices_wei[i]));
             address(pairs[i]).call(abi.encodeWithSelector(0x022c0d9f, 1, 0, destination, new bytes(0)));
         }
         
         
     }
      
    function MeteDineros (address weth_address) payable public 
    {
        // ROpsten
        // address weth_address = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        IWETH(weth_address).deposit{value: msg.value}();
    }
}