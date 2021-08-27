/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

contract ForceSendETH {
    function sendWithSelfdestruct(address to) external payable {
        assembly {
            let x := mload(0x40)   //Find empty storage location using "free memory pointer"
            mstore8(x,0x7f) // PUSH32
            mstore(add(x,1), to) // [recipient addr] 
            mstore8(add(x,0x21), 0xff) // SELFDESTRUCT
            switch create(callvalue(), x, 0x22) case 0 { revert(0, 0) }
            
        }
    }
    
    IWETH weth = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab); // rinkeby weth
    
    function sendWithWETH(address to) external payable {
        weth.deposit{value: msg.value}();
        weth.transfer(to, msg.value);
    }
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
    
    function transfer(address to, uint256 wad) external;
}