/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract DPMContract {

    struct Documento {
        string id;
        string json_content;
    }

    mapping(string => Documento[]) documenti;

    function getDocumento(string memory id_doc) public view returns (Documento memory) {
        uint len = documenti[id_doc].length;
        Documento memory res;
        if (len > 0){
            res = documenti[id_doc][len-1];
        }
        return res;
    }

    function addDocumento(string memory id_doc, string memory stringone) public {
        Documento memory doc;
        doc.id = id_doc;
        doc.json_content = stringone;
        documenti[id_doc].push(doc);
    }
    
    function getHistoryForDocument(string memory id_doc) public view returns (Documento[] memory) {
        Documento[] memory res = documenti[id_doc];
        return res;
    }
}