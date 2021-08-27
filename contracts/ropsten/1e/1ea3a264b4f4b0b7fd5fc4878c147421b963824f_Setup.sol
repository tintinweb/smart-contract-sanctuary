pragma solidity 0.8.0;

import "./Wallet.sol";

contract Setup {
    Wallet public wallet;

    constructor() payable{
        wallet = (new Wallet){value : 0.1 ether}();
    }

    function isSolved() public view returns (bool) {
        return address(wallet).balance == 0;
    }
}