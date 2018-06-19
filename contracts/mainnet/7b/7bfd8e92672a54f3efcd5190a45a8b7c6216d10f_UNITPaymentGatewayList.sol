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


contract UNITPaymentGatewayList is BasicWhitelist {
    function UNITPaymentGatewayList()
        public
    {
        setAdministrator(tx.origin);
    }
}