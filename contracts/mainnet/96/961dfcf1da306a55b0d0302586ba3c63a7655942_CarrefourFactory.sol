pragma solidity ^0.4.24;

contract Articolo
{
    bytes   public codice_articolo;
    bytes10 public data_produzione;
    bytes10 public data_scadenza;
    bytes   public id_stabilimento;

    constructor(bytes   _codice_articolo,
                bytes10 _data_produzione,
                bytes10 _data_scadenza,
                bytes   _id_stabilimento) public
    {
        require(_codice_articolo.length > 0, "Codice Art. vuoto");
        require(_data_produzione.length > 0, "Data produzione vuota");
        require(_data_scadenza.length   > 0, "Data scadenza vuota");
        require(_id_stabilimento.length > 0, "ID stabilimento vuoto");

        codice_articolo = _codice_articolo;
        data_produzione = _data_produzione;
        data_scadenza   = _data_scadenza;
        id_stabilimento = _id_stabilimento;
    }
}

contract Lotto
{
    bytes   public id_owner_informazione;
    bytes   public codice_tracciabilita;
    bytes   public id_allevatore;
    bytes10 public data_nascita_pulcino;
    bytes10 public data_trasferimento_allevamento;

    mapping(bytes => mapping(bytes10 => address)) private articoli;

    address private owner;

    modifier onlymanager()
    {
        require(msg.sender == owner);
        _;
    }

    constructor(bytes _codice_tracciabilita,
                bytes _id_allevatore,
                bytes10 _data_nascita_pulcino,
                bytes10 _data_trasferimento_allevamento,
                bytes _id_owner_informazione) public
    {
        require(_codice_tracciabilita.length > 0, "cod. tra. non valido");
        require(_id_allevatore.length > 0, "id all. non valido");
        require(_data_nascita_pulcino.length > 0, "data nas. pul. non valida");
        require(_data_trasferimento_allevamento.length > 0, "data trasf. non valida");
        require(_id_owner_informazione.length > 0, "ID owner informazione non valido");

        // This will only be managed by the "father" contract ("CarrefourFactory"):
        owner = msg.sender;

        codice_tracciabilita = _codice_tracciabilita;
        id_allevatore = _id_allevatore;
        data_nascita_pulcino = _data_nascita_pulcino;
        data_trasferimento_allevamento = _data_trasferimento_allevamento;
        id_owner_informazione = _id_owner_informazione;
    }


    function addArticolo(bytes   _codice_articolo,
                         bytes10 _data_produzione,
                         bytes10 _data_scadenza,
                         bytes   _id_stabilimento) public onlymanager
    {
        require(_codice_articolo.length > 0, "Codice Art. vuoto");
        require(_data_produzione.length > 0, "Data produzione vuota");
        require(_data_scadenza.length   > 0, "Data scadenza vuota");
        require(_id_stabilimento.length > 0, "ID stabilimento vuoto");

        address articolo = new Articolo(_codice_articolo, _data_produzione, _data_scadenza, _id_stabilimento);

        articoli[_codice_articolo][_data_scadenza] = articolo;
    }

    function get_articolo(bytes codice_articolo, bytes10 data_scadenza) public view returns(bytes10, bytes)
    {
        address articolo_addr = articoli[codice_articolo][data_scadenza];

        Articolo articolo = Articolo(articolo_addr);

        return (
            articolo.data_produzione(),
            articolo.id_stabilimento()
        );
    }
}

contract CarrefourFactory
{
    address private owner;

    mapping(bytes => address) private lotti;

    event lottoAdded(bytes codice_tracciabilita);
    event articoloAdded(bytes lotto, bytes codice_articolo, bytes10 data_scadenza);

    constructor() public
    {
        owner = msg.sender;
    }

    modifier onlymanager()
    {
        require(msg.sender == owner);
        _;
    }

    function createLotto(bytes codice_tracciabilita,
                         bytes id_allevatore,
                         bytes10 data_nascita_pulcino,
                         bytes10 data_trasferimento_allevamento,
                         bytes id_owner_informazione) public onlymanager
    {
        require(codice_tracciabilita.length > 0, "Codice tracciabilit&#224; non valido");
        require(id_allevatore.length > 0, "Codice allevatore non valido");
        require(data_nascita_pulcino.length > 0, "Data di nascita non valida");
        require(data_trasferimento_allevamento.length > 0, "Data trasferimento allevamento non valida");

        address lotto = new Lotto(codice_tracciabilita, id_allevatore, data_nascita_pulcino, data_trasferimento_allevamento, id_owner_informazione);

        lotti[codice_tracciabilita] = lotto;

        emit lottoAdded(codice_tracciabilita);
    }

    function get_dati_lotto(bytes codice_tracciabilita) public view
             returns(bytes, bytes10, bytes10, bytes)
    {
        address lotto_addr = lotti[codice_tracciabilita];

        require(lotto_addr != 0x0, "Lotto non trovato");

        Lotto lotto = Lotto(lotto_addr);

        return (
            lotto.id_allevatore(),
            lotto.data_nascita_pulcino(),
            lotto.data_trasferimento_allevamento(),
            lotto.id_owner_informazione()
        );
    }

    function createArticolo(bytes   _lotto, // Here a synonym of "codice_tracciabilita"
                            bytes   _codice_articolo,
                            bytes10 _data_produzione,
                            bytes10 _data_scadenza,
                            bytes   _id_stabilimento) public onlymanager
    {
        require(_lotto.length > 0, "Codice tracciabilit&#224; vuoto");
        require(_codice_articolo.length > 0, "Codice Art. vuoto");
        require(_data_produzione.length > 0, "Data produzione vuota");
        require(_data_scadenza.length > 0, "Data scadenza vuota");
        require(_id_stabilimento.length > 0, "ID stabilimento vuoto");

        address lotto_addr = lotti[_lotto];

        require(lotto_addr != 0x0, "Lotto non trovato");

        Lotto lotto = Lotto(lotto_addr);

        lotto.addArticolo(_codice_articolo, _data_produzione, _data_scadenza, _id_stabilimento);

        emit articoloAdded(_lotto, _codice_articolo, _data_scadenza);
    }

    function get_dati_articolo(bytes codice_tracciabilita, bytes codice_articolo, bytes10 data_scadenza) public view
             returns(bytes10, bytes, bytes, bytes10, bytes10)
    {
        address lotto_addr = lotti[codice_tracciabilita];

        require(lotto_addr != 0x0, "Lotto non trovato");

        Lotto lotto = Lotto(lotto_addr);

        (bytes10 produzione, bytes memory stabilimento) = lotto.get_articolo(codice_articolo, data_scadenza);

        bytes memory allevatore = lotto.id_allevatore();
        bytes10 nascita = lotto.data_nascita_pulcino();
        bytes10 trasferimento = lotto.data_trasferimento_allevamento();

        return (
            produzione,
            stabilimento,
            allevatore,
            nascita,
            trasferimento
        );
    }
}