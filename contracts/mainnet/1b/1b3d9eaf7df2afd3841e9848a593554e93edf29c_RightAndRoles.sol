pragma solidity ^0.4.21;

// Project: imigize.io (original)
// v13, 2018-06-19
// This code is the property of CryptoB2B.io
// Copying in whole or in part is prohibited.
// Authors: Ivan Fedorov and Dmitry Borodin
// Do you want the same TokenSale platform? www.cryptob2b.io

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function setManagerPowerful(bool _mode) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract RightAndRoles is IRightAndRoles {
    bool managerPowerful = true;

    function RightAndRoles(address[] _roles) public {
        uint8 len = uint8(_roles.length);
        require(len > 0&&len <16);
        wallets.length = len;

        for(uint8 i = 0; i < len; i++){
            wallets[i].push(_roles[i]);
            roles[_roles[i]] += uint16(2)**i;
            emit WalletChanged(_roles[i], address(0),i);
        }
    }

    function changeClons(address _clon, uint8 _role, bool _mod) external {
        require(wallets[_role][0] == msg.sender&&_clon != msg.sender);
        emit CloneChanged(_clon,_role,_mod);
        uint16 roleMask = uint16(2)**_role;
        if(_mod){
            require(roles[_clon]&roleMask == 0);
            wallets[_role].push(_clon);
        }else{
            address[] storage tmp = wallets[_role];
            uint8 i = 1;
            for(i; i < tmp.length; i++){
                if(tmp[i] == _clon) break;
            }
            require(i > tmp.length);
            tmp[i] = tmp[tmp.length];
            delete tmp[tmp.length];
        }
        roles[_clon] = _mod?roles[_clon]|roleMask:roles[_clon]&~roleMask;
    }

    // Change the address for the specified role.
    // Available to any wallet owner except the observer.
    // Available to the manager until the round is initialized.
    // The Observer&#39;s wallet or his own manager can change at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        depend...
    // @ When it is launched automatically  -
    // @ Who can call the function          staff (all 7+ roles)
    function changeWallet(address _wallet, uint8 _role) external {
        require(wallets[_role][0] == msg.sender || wallets[0][0] == msg.sender || (wallets[1][0] == msg.sender && managerPowerful));
        emit WalletChanged(wallets[_role][0],_wallet,_role);
        uint16 roleMask = uint16(2)**_role;
        address[] storage tmp = wallets[_role];
        for(uint8 i = 0; i < tmp.length; i++){
            roles[tmp[i]] = roles[tmp[i]]&~roleMask;
        }
        delete  wallets[_role];
        tmp.push(_wallet);
        roles[_wallet] = roles[_wallet]|roleMask;
    }

    function setManagerPowerful(bool _mode) external {
        require(wallets[0][0] == msg.sender);
        managerPowerful = _mode;
    }

    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool) {
        return roles[_sender]&_roleMask != 0;
    }

    function getMainWallets() view external returns(address[]){
        address[] memory _wallets = new address[](wallets.length);
        for(uint8 i = 0; i<wallets.length; i++){
            _wallets[i] = wallets[i][0];
        }
        return _wallets;
    }

    function getCloneWallets(uint8 _role) view external returns(address[]){
        return wallets[_role];
    }
}