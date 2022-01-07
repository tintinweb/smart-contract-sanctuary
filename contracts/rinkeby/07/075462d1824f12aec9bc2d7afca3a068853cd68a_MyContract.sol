/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    struct DatasetLines {
        address tx;
        address[] auth;
        uint256[] prev;
    }
    mapping (uint256 => DatasetLines) table;

    address[] tmpAddr;
    uint256[] tmpUint;
    
    function addRow(uint256 _id, 
                    uint256 _oldId) public {
        require(_id > 0);
        address _tx = table[_id].tx;
        require(_tx == address(0));
        
        _tx = msg.sender;
       
        address[] memory _auth;
        uint256[] memory _prev;

        if (_oldId != 0 ) {

            for (uint256 i=0; i < table[_oldId].auth.length; i++) {
                tmpAddr.push(table[_oldId].auth[i]);
            }

            for (uint256 i=0; i < table[_oldId].prev.length; i++) {
                tmpUint.push(table[_oldId].prev[i]);
            }
        }

        tmpAddr.push(_tx);
        tmpUint.push(_oldId);

        _auth = tmpAddr;
        _prev = tmpUint;

        for (uint256 i=0; i <= tmpUint.length; i++) {
            tmpUint.pop();
        }
        for (uint256 i=0; i <= tmpAddr.length; i++) {
            tmpAddr.pop();
        }
        
        DatasetLines memory _Row = DatasetLines({tx:_tx,
                                            auth:_auth,
                                            prev:_prev});

        table[_id] = _Row;

    }

    function getRow(uint256 _id) public view returns (address _tx,
                                                            address[] memory _auth,
                                                            uint256[] memory _prev){
        _tx = table[_id].tx;
        _auth = table[_id].auth;
        _prev = table[_id].prev;
        
    }

   
}