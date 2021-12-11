/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.8.0;

interface iec_card {
    function mintCards(uint256 numberOfCards, address recipient) external;
}

contract more_plutos {
    address owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner,"Unauthorised");
        _;
    }

    function mintTokens(iec_card token, address[] calldata recips, uint[] calldata amounts  ) external onlyOwner {
        require(recips.length == amounts.length,"Match");
        for (uint pos = 0; pos < recips.length; pos++) {
            token.mintCards(amounts[pos], recips[pos]);
        }
    }
}