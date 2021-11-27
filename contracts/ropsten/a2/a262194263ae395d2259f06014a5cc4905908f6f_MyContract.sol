/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    //struct entspricht 'Tabellenspalten'
    struct DataType {
        //automatisch angelegt
        //address senderId;
        //durch Versender angelegt
        uint256 batchNumber;
        uint256 prevOrderId;
        uint256 shipmentDate;
        string workPerformed;
        string article;
        string shipmentNumber;
        address receiverId;
        //durch Empfänger angelegt
        uint256 deliveryDate;
        string deliveryConfirmation;
    }
    
    //Liste der Tabellenspalten: Zeilen
    mapping (uint256 => DataType) table;

  function addRow(uint256 _orderId, 
                    uint256 _batchNumber, 
                    uint256 _prevOrderId, 
                    uint256 _shipmentDate, 
                    string memory _workPerformed, 
                    string memory _article, 
                    string memory _shipmentNumber, 
                    address _receiverId, 
                    uint256 _deliveryDate, 
                    string memory _deliveryConfirmation) public {
        require(_orderId > 0);
        table[_orderId] = DataType(_batchNumber, 
                                    _prevOrderId, 
                                    _shipmentDate, 
                                    _workPerformed, 
                                    _article, 
                                    _shipmentNumber, 
                                    _receiverId,
                                    _deliveryDate, 
                                    _deliveryConfirmation);
    }

    function getRow(uint256 _orderId) public view returns (uint256 _batchNumber, 
                                                            uint256 _prevOrderId,
                                                            uint256 _shipmentDate, 
                                                            string memory _workPerformed, 
                                                            string memory _article, 
                                                            string memory _shipmentNumber, 
                                                            address _receiverId,
                                                            uint256 _deliveryDate,
                                                            string memory _deliveryConfirmation){
        _batchNumber = table[_orderId].batchNumber;
        _prevOrderId = table[_orderId].prevOrderId;
        _shipmentDate = table[_orderId].shipmentDate;
        _workPerformed = table[_orderId].workPerformed;
        _article = table[_orderId].article;
        _shipmentNumber = table[_orderId].shipmentNumber;
        _receiverId = table[_orderId].receiverId;
        _deliveryDate = table[_orderId].deliveryDate;
        _deliveryConfirmation = table[_orderId].deliveryConfirmation;
        
    }
}