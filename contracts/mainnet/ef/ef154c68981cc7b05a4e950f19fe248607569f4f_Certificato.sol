/**
 *Submitted for verification at Etherscan.io on 2020-07-06
*/

pragma solidity >=0.4.22 <0.7.0;

contract Certificato {

    struct CertificatoModel {
        string codice_verifica;
        string nome_liceo;
        string nome_corso;
        string cf_studente;
        string data_conseguimento;
    }

    address owner;
    mapping(string => CertificatoModel) private certificati;
    mapping(string => bool) private exist;

    modifier OnlyOwner {
        require(owner == msg.sender, 'Permission denied');
        _;
    }

    event CertificatoEmitted(string, string);


    constructor() public {
        owner = msg.sender;
    }


    function createCertificato(
        string calldata _codice_verifica,
        string calldata _nome_liceo,
        string calldata _nome_corso,
        string calldata _cf_studente,
        string calldata _data_conseguimento
        ) external {

            require(exist[_codice_verifica] == false, "Certificate already exist");
            require(bytes(_codice_verifica).length > 0, "_nome_corso empty");
            require(bytes(_nome_liceo).length > 0, "_nome_liceo empty");
            require(bytes(_nome_corso).length > 0, "_nome_corso empty");
            require(bytes(_cf_studente).length > 0, "_cf_studente empty");
            require(bytes(_data_conseguimento).length > 0, "_data_conseguimento empty");

            CertificatoModel memory certificato;
            certificato.codice_verifica = _codice_verifica;
            certificato.nome_liceo = _nome_liceo;
            certificato.nome_corso = _nome_corso;
            certificato.cf_studente = _cf_studente;
            certificato.data_conseguimento = _data_conseguimento;

            certificati[_codice_verifica] = certificato;
            exist[_codice_verifica] = true;

            emit CertificatoEmitted('Certificate emitted: ', _codice_verifica);
        }
}