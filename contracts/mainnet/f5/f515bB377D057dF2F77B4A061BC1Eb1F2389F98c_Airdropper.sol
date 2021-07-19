/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

pragma solidity ^0.8.0;

interface IERC20 { function transfer(address recipient, uint amount) external returns (bool); }

contract Airdropper {
    uint private constant TRANSFER_AMOUNT = 5000 * 10**18;
    address private immutable OWNER;
    IERC20 private immutable MMM;

    constructor(IERC20 _MMM) {
        OWNER = msg.sender;
        MMM = _MMM;
    }

    function distribute() external {
        require(msg.sender == OWNER);

        address[20] memory accounts = [
            0x2187C65cD25C984A4040C81b6b659f59B3A997C1,
            0x58745fA64DF8052da6678d4e1a11840979F11622,
            0xBfa0D0eEa225855cf07137Bc664DC89505C7614c,
            0xd919296303D6166A25a8a0a4F328E43B07E0fb27,
            0x1D7E454Ab11603667c211B065246062C95DA81d8,
            0x8edE26F2e7c9af725c20e4bAE69CB2475a3Ad4fb,
            0xd8Fa4fc7E2F905d85bDB4d0A9a69156c2D58ED11,
            0x1D104aD019Abc432b8D38c15257999FE12705eb5,
            0xa8af061fd4F3504691e52Fc2150200d5915Cd7cA,
            0xA65661b2CA9BF4cd8af4E268a6e9BAB6863D58e0,
            0xE2ea0f346F66F216Ec91F2572A4E07e1a1A4EF2c,
            0x9D310f3AC0178ece5b3e3a51e4399Ca491adb896,
            0xBFFc3dd2490c44015c6eA06d62B8bFac7F666663,
            0xad5395627309774916B08b721C228f18D9973530,
            0x192FcF067D36a8BC9322b96Bb66866c52C43B43F,
            0x9b0726e95e72eB6f305b472828b88D2d2bDD41C7,
            0x76FAF2af35E49Ea1739bC1DC9DF4EF58B293cD71,
            0xf1a83E65543C28403316C0eCAbDFFac01dbB22cc,
            0x593b29B7e723f2B7b40888e79D293980eF4c876f,
            0xeE3c21c21848ed1C787C7c0205E8dE40722846d6
        ];

        for (uint i; i < accounts.length; i++) {
            MMM.transfer(accounts[i], TRANSFER_AMOUNT);
        }
    }
}