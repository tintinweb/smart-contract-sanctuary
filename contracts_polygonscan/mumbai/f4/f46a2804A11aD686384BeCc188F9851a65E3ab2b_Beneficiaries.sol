pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Beneficiaries{
    IERC20Metadata token = IERC20Metadata(0x675d3130C01cE1C402C903053033b8D9604CA712);

    address[] public accounts = [
        0xeecfCC1D4f2b9D99bA89643D98D6ea94c5692c3b,
        0x17519fd17e82dBfeD3776b89b31477eA4447A725,
        0xCBDD0293DfaD28E19523d8A540E83a27cB09b85b
    ];

    uint256[] public shares = [ 20, 30, 50 ]; // %

    function withdraw() external {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= accounts.length * 2);
        for(uint8 i = 0; i < shares.length; i++){
            uint256 value = ( shares[i] * balance ) / 100;
            if(value > 0){
                token.transfer( accounts[i], value );
            }
        }
    }
}