// File: contracts/interfaces/ISynthetix.sol

pragma solidity ^0.5.0;

interface ISynthetix {

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

}

// File: @emilianobonassi/referral/SimpleReferral.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;


contract SimpleReferral {

    bool internal _justReferred;

    mapping (address => address) public referrerForUser;


    event NewReferral(address indexed referrer, address indexed user);


    modifier referral(address user, address referrer) {
        if (referrer != address(0) && !_hasReferrer(user)) {

            referrerForUser[user] = referrer;
            emit NewReferral(referrer, user);

            _justReferred = true;
            _;
            _justReferred = false;
        } else {
            _;
        }
    }


    function _hasReferrer(address user) internal view returns (bool) {
        return referrerForUser[user] != address(0);
    }
}

// File: @emilianobonassi/gas-saver/ChiGasSaver.sol

pragma solidity ^0.5.0;

contract IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

contract ChiGasSaver {

    modifier saveGas(address payable sponsor) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
        chi.freeFromUpTo(sponsor, (gasSpent + 14154) / 41947);
    }
}

// File: contracts/SNXLinkTradeSaverV1.sol

pragma solidity ^0.5.0;





contract SNXLinkTradeSaverV1 is SimpleReferral, ChiGasSaver {
    // SNX addresses
    ISynthetix public constant Synthetix = ISynthetix(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);

    // Partner program
    bytes32 public constant trackingCode = 0x534e582e4c494e4b000000000000000000000000000000000000000000000000;

    // Custom referral initiative
    address public constant originator = 0x59846C1F45C67FA757438EC1B67bdd72BBe483b7;


    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address referrer
    )
    external
    saveGas(msg.sender)
    referral(msg.sender, referrer)
    returns (uint amountReceived) {
        return Synthetix.exchangeOnBehalfWithTracking(
            msg.sender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            originator,
            trackingCode
        );
    }
}