/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    struct DatasetLines {
        address tx;
        address[] authAddr;
        uint256[] prevIds;
        address rx;
    }

    mapping (uint256 => DatasetLines) table;

    address[] tmpAddr;
    uint256[] tmpUint;    
    
    function addRow(uint256 _id, 
                    uint256 _prevId, 
                    address _rx) public {
        require(_id > 0);
        address _tx = table[_id].tx;
        require(_tx == address(0));
        _tx = msg.sender;
        
        address[] memory _authAddr;
        uint256[] memory _prevIds;

        if (_prevId != 0 ) {
 
            for (uint256 i=0; i < table[_prevId].authAddr.length; i += 1) {
                if(i < tmpAddr.length){
                    tmpAddr[i] = table[_prevId].authAddr[i];
                } else {
                    tmpAddr.push(table[_prevId].authAddr[i]);
                }
            }

            for (uint256 i=0; i < table[_prevId].prevIds.length; i += 1){
                if(i < tmpUint.length){
                    tmpUint[i]=table[_prevId].prevIds[i] ;
                } else{
                    tmpUint.push(table[_prevId].prevIds[i]) ;
                }
            }
        }
        
        tmpAddr.push(_tx);
        tmpAddr.push(_rx);
        tmpUint.push(_prevId);
       
        _authAddr = tmpAddr;
        _prevIds = tmpUint;

        for (uint256 i=tmpUint.length; i >= 0; i--) {
            tmpUint.pop();
        }
        for (uint256 i=tmpAddr.length; i >= 0; i--) {
            tmpAddr.pop();
        }

        DatasetLines memory _Row = DatasetLines({tx:_tx,
                                            authAddr:_authAddr,
                                            prevIds:_prevIds,
                                            rx:_rx});

        table[_id] = _Row;

    }

    function getRow(uint256 _id) public view returns (address _tx,
                                                            address[] memory _authAddr,
                                                            uint256[] memory _prevIds,
                                                            address _rx){
        _tx = table[_id].tx;
        _authAddr = table[_id].authAddr;
        _prevIds = table[_id].prevIds;
        _rx = table[_id].rx;
        
    }
}