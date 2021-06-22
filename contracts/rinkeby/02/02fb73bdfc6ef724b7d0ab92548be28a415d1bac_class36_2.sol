/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.24;

contract class36{
    // 任何人都可以存取
    uint public a = 1;
    // 只能有合約內、或繼承(這份合約)的合約可以存取
    uint internal b = 10;
    // 只有這份合約內部可以存取(，但還是可以透過實作封裝來取得)
    uint private c = 50;
    
    // 只能由外部(送交易)、其他合約呼叫
    function external_example(uint x) external {
        a=x;
    }
    
    // 只能有合約內、或繼承(這份合約)的合約呼叫
    function internal_example(uint x) internal {
        a=x;
    }
    
    // 任何人都可以呼叫
    function public_example(uint x) public {
        a=x;
        internal_example(4);
    }
    
    // 只有這份合約內部可以呼叫
    function private_example(uint x) private {
        a=x;
    }
    
    // 封裝函式範例
    function getPrivate_c() public view returns(uint){
        return c;
    }
}

// inherit class36
contract class36_2 is class36{
    function call_internal2(uint x)public{
        internal_example(x);
        b = x*2;    // intrenal variable can be modified by inherit
    }
    // //can't call private
    // function call_private2(uint x)public{
    //     private_example(x);
    // }
}