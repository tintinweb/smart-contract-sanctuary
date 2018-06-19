pragma solidity ^0.4.18;


interface Whitelist {
    function add(address _wlAddress) public;
    function addBulk(address[] _wlAddresses) public;
    function remove(address _wlAddresses) public;
    function removeBulk(address[] _wlAddresses) public;
    function getAll() public constant returns(address[]);
    function isInList(address _checkAddress) public constant returns(bool);
}

contract Administrated {
    address public administrator;

    modifier onlyAdministrator() {
        require(administrator == tx.origin);
        _;
    }

    modifier notAdministrator() {
        require(administrator != tx.origin);
        _;
    }

    function setAdministrator(address _administrator)
        internal
    {
        administrator = _administrator;
    }
}

contract BasicWhitelist is Whitelist, Administrated {
    address[] public whitelist;

    //Up to 65536 users in list
    mapping(address => uint16) public wlIndex;


    function BasicWhitelist()
        public
    {
        setAdministrator(tx.origin);
    }

    //Add whitelist
    function add(address _wlAddress)
        public
        onlyAdministrator
    {
        if ( !isInList(_wlAddress) ) {
            wlIndex[_wlAddress] = uint16(whitelist.length);
            whitelist.push(_wlAddress);
        }
    }

    //Bulk add
    function addBulk(address[] _wlAddresses)
        public
        onlyAdministrator
    {
        require(_wlAddresses.length <= 256);

        for (uint8 i = 0; i < _wlAddresses.length; i++) {
            add(_wlAddresses[i]);
        }
    }

    //Remove address from whitelist
    function remove(address _wlAddress)
        public
        onlyAdministrator
    {
        if ( isInList(_wlAddress) ) {
            uint16 index = wlIndex[_wlAddress];
            wlIndex[_wlAddress] = 0;

            for ( uint16 i = index; i < ( whitelist.length - 1 ); i++) {
                whitelist[i] = whitelist[i + 1];
            }

            delete whitelist[whitelist.length - 1];
            whitelist.length--;
        }
    }

    //Bulk remove
    function removeBulk(address[] _wlAddresses)
        public
        onlyAdministrator
    {
        require(_wlAddresses.length <= 256);

        for (uint8 i = 0; i < _wlAddresses.length; i++) {
            remove(_wlAddresses[i]);
        }
    }

    //Get list
    function getAll()
        public
        constant
        returns(address[])
    {
        return whitelist;
    }

    //
    function isInList(address _checkAddress)
        public
        constant
        returns(bool)
    {
        return whitelist.length > 0
                && (
                    wlIndex[_checkAddress] > 0
                    || whitelist[wlIndex[_checkAddress]] == _checkAddress
                   );
    }
}

contract UNITTransferWhiteList is BasicWhitelist {
    function UNITTransferWhiteList()
        public
    {
        setAdministrator(tx.origin);

        add(0x77660795BD361Cd43c3627eAdad44dDc2026aD17); //Advisors
        add(0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb); //BountyWe accept different cryptocurrencies. You should have ETH wallet to get UNIT Tokens

        //Team
        add(0x40e3D8fFc46d73Ab5DF878C751D813a4cB7B388D);
        add(0x5E065a80f6635B6a46323e3383057cE6051aAcA0);
        add(0x0cF3585FbAB2a1299F8347a9B87CF7B4fcdCE599);
        add(0x5fDd3BA5B6Ff349d31eB0a72A953E454C99494aC);
        add(0xC9be9818eE1B2cCf2E4f669d24eB0798390Ffb54);
        add(0xd13289203889bD898d49e31a1500388441C03663);
    }
}