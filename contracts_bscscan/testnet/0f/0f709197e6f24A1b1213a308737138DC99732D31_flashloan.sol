/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-25
*/

pragma solidity = 0.8.6;

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
interface IPancakePair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}
interface WBNB{
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}
contract flashloan is IPancakeCallee{
    uint256 fee = 1;
    uint256 amount = 0;
    
    WBNB wbnb = WBNB(0xc3678D4E0242A5a0dD30e90066D377e521021f4F); //testnet 0xae13d989dac2f0debff460ac112a837c89baa7cd
    //WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IPancakePair LP = IPancakePair(0xfcBc3cd8EDA2a08b4DE6352E44b5Faf4cc1118C0); //testnet
    //IPancakePair LP = IPancakePair(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
    
    function loan() public payable{
        
        amount = fee*9975/25;
        LP.swap(amount,0,address(this),new bytes(1));//vay tiền
    }   
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) override external{
        //
        //Đang cóĐang có tiền, so du la amount+fee
        //
        wbnb.deposit{value:fee}();
        wbnb.transfer(address(LP),amount+fee);//tra tien
    }
}