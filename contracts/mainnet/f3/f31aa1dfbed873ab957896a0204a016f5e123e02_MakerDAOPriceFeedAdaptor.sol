pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// Adaptor to convert MakerDAO&#39;s "pip" price feed into BokkyPooBah&#39;s Pricefeed
//
// Used to convert MakerDAO ETH/USD pricefeed on the Ethereum mainnet at
//   https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B
// to be a slightly more useable form
//
// Deployed to: 0xF31AA1dFbEd873Ab957896a0204a016F5E123e02
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// PriceFeed Interface - _live is true if the rate is valid, false if invalid
// ----------------------------------------------------------------------------
contract PriceFeedInterface {
    function name() public view returns (string);
    function getRate() public view returns (uint _rate, bool _live);
}


// ----------------------------------------------------------------------------
// See https://github.com/bokkypoobah/MakerDAOSaiContractAudit/tree/master/audit#pip-and-pep-price-feeds
// ----------------------------------------------------------------------------
contract MakerDAOPriceFeedInterface {
    function peek() public view returns (bytes32 _value, bool _hasValue);
}


// ----------------------------------------------------------------------------
// Pricefeed with interface compatible with MakerDAO&#39;s "pip" PriceFeed
// ----------------------------------------------------------------------------
contract MakerDAOPriceFeedAdaptor is PriceFeedInterface {
    string private _name;
    MakerDAOPriceFeedInterface public makerDAOPriceFeed;

    constructor(string name, address _makerDAOPriceFeed) public {
        _name = name;
        makerDAOPriceFeed = MakerDAOPriceFeedInterface(_makerDAOPriceFeed);
    }
    function name() public view returns (string) {
        return _name;
    }
    function getRate() public view returns (uint _rate, bool _live) {
        bytes32 value;
        (value, _live) = makerDAOPriceFeed.peek();
        _rate = uint(value);
    }
}