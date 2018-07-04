pragma solidity ^0.4.18;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}

contract TokenAirdrop {

    function sendTokens(address[] beneficiaries) public {
        ERC20 token = ERC20(0x96c82E9668F425bED5130d7564f8ee592B60b5cB); //Token address
        for (uint8 i = 0; i< beneficiaries.length; i++){
            address beneficiary = beneficiaries[i];
            token.transferFrom(0x6032DdbA0765dd64e41Ce68C5cFACFaF01970CF5, beneficiary, 1);
        }

    }
}