//sol Almacert
// Get Diploma Supplement hash from student ID.
// @authors:
// Flosslab s.r.l. <info@flosslab.com>
// Norman Argiolas <normanargiolas@flosslab.com>
// usage:
// use getHashDigest public view function to verify document hash


contract Almacert {

    uint constant MATRICOLA_LENGHT = 11;
    uint constant CODICEFISCALE_LENGHT = 16;
    uint constant SESSIONE_LENGHT = 10;

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    struct Studente {
        string codiceFiscale;
        string sessione;
        bytes32 hash;
    }

    address private manager;
    address public owner;

    mapping(string => Studente) private laureati;

    constructor() public{
        owner = msg.sender;
        manager = msg.sender;
    }

    function certificato(string _matricola) view public returns (bytes32) {
        return laureati[_matricola].hash;
    }

    function getHashDigest(string _matricola) view public returns (string, string, bytes32){
        return (laureati[_matricola].codiceFiscale, laureati[_matricola].sessione, laureati[_matricola].hash);
    }

    function verificaCertificato(string _matricola, bytes32 _hash) view public returns (bool) {
        return laureati[_matricola].hash == _hash;
    }

    function addLaureato(string _matricola, string _codiceFiscale, string _sessione, bytes32 _hash) restricted public {
        require(laureati[_matricola].hash == 0x0);
        laureati[_matricola].hash = _hash;
        laureati[_matricola].codiceFiscale = _codiceFiscale;
        laureati[_matricola].sessione = _sessione;
    }

    function addLaureati(string _matricole, string _codiciF, string _sessioni, bytes32 [] _hashes, uint _len) restricted public {
        string  memory matricola;
        string  memory codiceFiscale;
        string  memory sessione;
        for (uint i = 0; i < _len; i++) {
            matricola = sub_matricola(_matricole, i);
            codiceFiscale = sub_codicefiscale(_codiciF, i);
            sessione = sub_sessione(_sessioni, i);
            addLaureato(matricola, codiceFiscale, sessione, _hashes[i]);
        }
    }

    function subset(string _source, uint _pos, uint _lenght) constant private returns (string) {
        bytes memory strBytes = bytes(_source);
        bytes memory result = new bytes(_lenght);
        for (uint i = (_pos * _lenght); i < (_pos * _lenght + _lenght); i++) {
            result[i - (_pos * _lenght)] = strBytes[i];
        }
        return string(result);
    }

    function sub_matricola(string str, uint pos) constant private returns (string) {
        return subset(str, pos, MATRICOLA_LENGHT);
    }

    function sub_codicefiscale(string str, uint pos) constant private returns (string) {
        return subset(str, pos, CODICEFISCALE_LENGHT);
    }

    function sub_sessione(string str, uint pos) constant private returns (string) {
        return subset(str, pos, SESSIONE_LENGHT);
    }

    function removeLaureato(string _matricola) restricted public {
        require(laureati[_matricola].hash != 0x00);
        //prevent erroneous removed
        laureati[_matricola].hash = 0x00;
        laureati[_matricola].codiceFiscale = &#39;&#39;;
        laureati[_matricola].sessione = &#39;&#39;;
    }

    function changeOwner(address _old_owner, address _new_owner) public restricted {
        require(_old_owner == owner);
        owner = _new_owner;
    }

    function restoreOwner(address _manager) public {
        require(manager == _manager);
        owner = _manager;
    }

}