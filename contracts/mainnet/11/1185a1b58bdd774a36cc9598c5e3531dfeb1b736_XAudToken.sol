pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./MultiOwned.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./XAudTokenConfig.sol";




contract XAudToken is XAudTokenConfig, ERC20Burnable, ERC20Mintable {

    constructor()
        MultiOwned(
            makeAddressSingleton(msg.sender),
            1)
        ERC20(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            TOKEN_INITIALSUPPLY)
        ERC20Mintable(
            TOKEN_MINTCAPACITY,
            TOKEN_MINTPERIOD)
        public
    {}
}