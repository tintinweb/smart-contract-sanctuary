/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity 0.8.3;

struct Coin {
    address asset;
    uint amount;
}

// ROUTER Interface
interface iROUTER {
    function depositWithExpiry(address, address, uint, string calldata, uint) external;
    function deposit(address payable, address, uint, string memory) external payable; 
    function transferAllowance(address, address, address, uint, string memory) external;
    function transferOut(address payable, address, uint, string memory) external payable; 
    function batchTransferOut(address[] memory, Coin[] memory, string[] memory) external payable;
    function returnVaultAssets(address, address payable, Coin[] memory, string memory) external payable;
}


contract TestHalborn{

    iROUTER router;
    address token;

    constructor (){
        router = iROUTER(0xefA28233838f46a80AaaC8c309077a9ba70D123A);
        token = 0x72ec0194E183d24e57B649E552dd14397De1df93;
    }


    function test1() external payable {
        router.deposit{value:msg.value}(payable(msg.sender), token, 100, "MEMOTEST");
    }

    receive () payable external{

    }

}