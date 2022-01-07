/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    struct DatasetLines {
        address tx;
        address rx;
        address[] auth;
        uint256[] prev;
    }
    mapping (uint256 => DatasetLines) table;
    
    function addRow(uint256 _id, 
                    uint256 _oldId, 
                    address _rx) public {
        require(_id > 0);
        address _tx = table[_id].tx;
        require(_tx == address(0));
        
        _tx = msg.sender;
       
        address[] memory _auth;
        uint256[] memory _prev;

        if (_oldId != 0 ) {

            address[] memory _authTmp = new address[](table[_oldId].auth.length+2);
            for (uint256 i=0; i < table[_oldId].auth.length; i++) {
                _authTmp[i] = table[_oldId].auth[i];
            }
            _authTmp[_authTmp.length-1] = _tx;
            _authTmp[_authTmp.length-2] = _rx;

            uint256[] memory _prevTmp = new uint256[](table[_oldId].prev.length+1);
            for (uint256 i=0; i < table[_oldId].prev.length; i++) {
                _prevTmp[i] = table[_oldId].prev[i];
            }
            _prevTmp[_prevTmp.length-1] = _oldId;

            _auth = _authTmp;
            _prev = _prevTmp;

        } else {
            address[] memory _authTmp;
            _authTmp[0] = _tx;
            _authTmp[1] = _rx;

            uint256[] memory _prevTmp;
            _prevTmp[0] = _oldId;

            _auth = _authTmp;
            _prev = _prevTmp;
        }

        
        DatasetLines memory _Row = DatasetLines({tx:_tx,
                                            auth:_auth,
                                            prev:_prev,
                                            rx:_rx});

        table[_id] = _Row;

    }

    function getRow(uint256 _id) public view returns (address _tx,
                                                            address[] memory _auth,
                                                            uint256[] memory _prev,
                                                            address _rx){
        _tx = table[_id].tx;
        _auth = table[_id].auth;
        _prev = table[_id].prev;
        _rx = table[_id].rx;
        
    }

   
}