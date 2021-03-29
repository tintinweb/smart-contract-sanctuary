pragma solidity 0.5.2;

import "./CustomToken.sol";

contract QuestToken is CustomToken {
    uint8 private DECIMALS = 18;
    uint256 private MAX_TOKEN_COUNT = 2100000000;
    uint256 private MAX_SUPPLY = MAX_TOKEN_COUNT * (10 ** uint256(DECIMALS));
    uint256 private INITIAL_SUPPLY = MAX_SUPPLY * 1 / 10;

    bool private issued = false;

    constructor()
        CustomToken("QuestToken", "Quest", DECIMALS, MAX_SUPPLY)
        public {
            require(issued == false);
            super.mint(msg.sender, INITIAL_SUPPLY);
            issued = true;
    }

}