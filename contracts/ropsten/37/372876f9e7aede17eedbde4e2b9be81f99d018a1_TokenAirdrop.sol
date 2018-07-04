pragma solidity ^0.4.18;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}

contract TokenAirdrop {

    function sendTokens(address[] beneficiaries) public {
        ERC20 token = ERC20(0xa29e65a8cb83bab2a1f34c4635a6cfcccc4ac8d8); //Token address
        for (uint8 i = 0; i< beneficiaries.length; i++){
            address beneficiary = beneficiaries[i];
            token.transferFrom(0xE3B2065973eFa0D39a510E6049e436dde6Cb8133, beneficiary, 1);
        }

    }
}