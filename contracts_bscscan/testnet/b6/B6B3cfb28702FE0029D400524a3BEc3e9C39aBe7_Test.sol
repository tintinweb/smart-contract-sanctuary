pragma solidity ^0.8.0;

contract Test{
    uint public eamount = 0;

    struct Wallet{
        uint amount;
        uint withdrawAmount;
    }

    mapping(address=>Wallet) wallets;

    receive() payable external{

    }

    function assign(bytes[] memory amounts) public{
        address buyer;
        uint amount;
        for(uint i=0;i<amounts.length; i++){
            (buyer, amount) = abi.decode(amounts[i], (address, uint));
            wallets[buyer] = Wallet(amount, 0);
        }
    }

}