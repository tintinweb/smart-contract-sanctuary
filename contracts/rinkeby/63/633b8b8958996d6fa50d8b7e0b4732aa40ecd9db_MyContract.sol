/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    //struct entspricht 'Tabellenspalten' - hier wird die Struktur der Tabelle definiert
    struct DatasetLines {
        //automatisch angelegt - folgende Variablen werden automatisch bei jeder Ausführung des Contracts ausgefüllt
        address senderId;
        address[] authorisedIds;
        //durch Versender angelegt - der Versender, der eine neue Lieferung anlegt, kann folgende Variablen beschreiben
        uint256 batchNumber;
        uint256[] prevOrderIds;
        uint256 shipmentDate;
        string workPerformed;
        string article;
        address receiverId;
        //durch Empfänger angelegt - der vom Versender eingetragene Empfänger hat die Möglichkeit, folgende Variablen zu verändern
        string deliveryConfirmation;
    }

    //Liste der Tabellenspalten: Zeilen
    mapping (uint256 => DatasetLines) table;
    
    //hier wird ein neuer Datensatz angelegt. Der Versender vergibt verpflichtend eine Sendungsnummer (orderId) und kann anschließend weitere Felder beschreiben
    function addRow(uint256 _orderId, 
                    uint256 _batchNumber, 
                    uint256 _prevOrderId, 
                    uint256 _shipmentDate, 
                    string memory _workPerformed, 
                    string memory _article,
                    address _receiverId) public {
        //Abfrage nach gültiger orderId
        require(_orderId > 0);
        //Abfrage nach neuem Datensatz (da senderId immer automatisch angelegt wird, kann dieses Datum stellvertretend abgefragt werden)
        address _senderId = table[_orderId].senderId;
        require(_senderId == address(0));
        //senderId wird automatisch zugewiesen
        _senderId = msg.sender;
        //folgende Variablen werden vom Empfänger beschrieben und daher hier zunächst auf '0' bzw. 'False' gesetzt
 
        string memory _deliveryConfirmation = "False";
        //Zugangsberechtigungen anlegen: Sender und Empfänger werden berechtigt, sowie alle Berechtigten der vorherigen Lieferungen (prevOrderId)
        //senderId & receiverId erhalten Berechtigung
        address[] memory _authorisedIds;

        uint256[] memory _prevOrderIds;
        
        if (_prevOrderId != 0 ) {
            address[] memory _authorisedIds = new address[](table[_prevOrderId].authorisedIds.length+2);
            for (uint256 i=0; i > table[_prevOrderId].authorisedIds.length; i += 1) {
                _authorisedIds[i] = table[_prevOrderId].authorisedIds[i];
            }
            _authorisedIds[_authorisedIds.length-1] = _senderId;
            _authorisedIds[_authorisedIds.length-2] = _receiverId;

            uint256[] memory _prevOrderIds = new uint256[](table[_prevOrderId].prevOrderIds.length+1);
            for (uint256 i=0; i > table[_prevOrderId].prevOrderIds.length; i += 1) {
                _prevOrderIds[i] = table[_prevOrderId].prevOrderIds[i];
            }
            _prevOrderIds[_prevOrderIds.length-1] = _prevOrderId;
        } else {
            address[2] memory _authorisedIds;
            _authorisedIds = [_senderId, _receiverId];

            uint256[1] memory _prevOrderIds;
            _prevOrderIds = [_prevOrderId];
        }
        
        DatasetLines memory _Row = DatasetLines({senderId:_senderId,
                                            authorisedIds:_authorisedIds,
                                            batchNumber:_batchNumber,
                                            prevOrderIds:_prevOrderIds,
                                            shipmentDate:_shipmentDate,
                                            workPerformed:_workPerformed,
                                            article:_article,
                                            receiverId:_receiverId,
                                            deliveryConfirmation:_deliveryConfirmation});

        table[_orderId] = _Row;

    }

   //Der vom Versender eingetragene Empfänger hat mit der folgenden Funktion die Möglichkeit, den Empfang der Lieferung zu bestätigen
    function changeRow(uint256 _orderId,
                        string memory _deliveryConfirmation) public {
        //orderId muss vorhanden sein
        require(_orderId > 0, "keine gueltige orderId");
        //nur der Empfänger darf diese Funktion ausführen
        address _receiverId = table[_orderId].receiverId;
        require(msg.sender == _receiverId);

        address _senderId = table[_orderId].senderId;
        address[] memory _authorisedIds = table[_orderId].authorisedIds;
        uint256 _batchNumber = table[_orderId].batchNumber;
        uint256[] memory _prevOrderIds = table[_orderId].prevOrderIds;
        uint256 _shipmentDate = table[_orderId].shipmentDate;
        string memory _workPerformed = table[_orderId].workPerformed;
        string memory _article = table[_orderId].article;
        
        DatasetLines memory _Row = DatasetLines({senderId:_senderId,
                                            authorisedIds:_authorisedIds,
                                            batchNumber:_batchNumber,
                                            prevOrderIds:_prevOrderIds,
                                            shipmentDate:_shipmentDate,
                                            workPerformed:_workPerformed,
                                            article:_article,
                                            receiverId:_receiverId,
                                            deliveryConfirmation:_deliveryConfirmation});

        table[_orderId] = _Row;        

    }

    //die folgende Funktion dient zur Abfrage von Datensätzen. Im aktuellen Schritt kann dafür lediglich nach der Bestellnummer gesucht werden
    function getRow(uint256 _orderId) public view returns (address _senderId,
                                                            address[] memory _authorisedIds,
                                                            uint256 _batchNumber, 
                                                            uint256[] memory _prevOrderIds,
                                                            uint256 _shipmentDate, 
                                                            string memory _workPerformed, 
                                                            string memory _article,
                                                            address _receiverId,
                                                            string memory _deliveryConfirmation){
        _senderId = table[_orderId].senderId;
        _authorisedIds = table[_orderId].authorisedIds;
        _batchNumber = table[_orderId].batchNumber;
        _prevOrderIds = table[_orderId].prevOrderIds;
        _shipmentDate = table[_orderId].shipmentDate;
        _workPerformed = table[_orderId].workPerformed;
        _article = table[_orderId].article;
        _receiverId = table[_orderId].receiverId;
        _deliveryConfirmation = table[_orderId].deliveryConfirmation;
        
    }

   
}