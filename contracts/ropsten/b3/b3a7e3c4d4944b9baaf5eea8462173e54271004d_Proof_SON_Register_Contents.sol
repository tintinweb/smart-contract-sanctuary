/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.6.6;

contract Proof_SON_Register_Contents
{

    string public lastRegisteredHash;

    struct FileDetails
    {
        uint timestamp;
        string author_id;
        string content_id;
    }
    mapping (string => FileDetails) public files;
    event logFileAddedStatus(bool status, uint timestamp,
        string author_id, string fileHash, string content_id);

    struct RevisionDetails
    {
        uint timestamp;
        string author_id;
        string content_id;
        string fileHash;
        string editorAddress;
        uint fileLength;
        string fileState;
    }
    mapping (string =>  RevisionDetails[] ) public revisions;

    // Nota. Un ulteriore controllo deve essere aggiunto di modo che solo uno specifico
    // account possa registrare tali informazioni per evitare di lasciare il metodo
    // esposto.
    function set(string memory author_id, string memory fileHash, string memory content_id,
        string memory editorAddress, uint fileLength, string memory fileState
    ) public
    {
        // Questo controllo serve a verificare che l’hash del file
        // (ovvero per estensione il contenuto del lemma) non sia stato già registrato.
        if(files[fileHash].timestamp == 0) {

            lastRegisteredHash = fileHash;

            files[fileHash] = FileDetails(block.timestamp, author_id, content_id);

            revisions[content_id].push (
                RevisionDetails(
                    block.timestamp, author_id, content_id, fileHash,
                        editorAddress, fileLength, fileState
                )
            );

            // Tramite emit viene lanciato un evento (potrebbe permettere all’applicazione
            // di front end di sapere che nuove informazioni sono state memorizzate in blockchain).
            emit logFileAddedStatus(true, block.timestamp, author_id, fileHash, content_id);
        } else {
            emit logFileAddedStatus(false, block.timestamp, author_id, fileHash, content_id);
        }
    }
    // Questa funzione è accessibile pubblicamente al fine di verificare l’esistenza
    // di un dato hash all’interno dello smart contract.
    function get(string memory fileHash) public
    returns (uint timestamp, string memory author_id)
    {
        return (files[fileHash].timestamp, files[fileHash].author_id);
    }
}