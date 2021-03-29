// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;
import './Ownable.sol';
import './Killable.sol';


contract EnoNurseryCompanyContract  is Ownable,Killable  {
    
    bool isSealed; 
    string _name;
    string _lon;
    string _lat;
    string _piva;
    address _creator;
    
    struct ImpiantoViticolo {
        uint    upc; // Universal Product Code (UPC)
        string  denominazione; // Place Name
        string  foglioParticella; // Foglio-Particella
        string  varieta; // varieta
        string  superficie; // superficie
    }
    
    struct LocaleTecnico {
        
        uint    upc; // Universal Product Code (UPC)
        string  denominazione; // Place Name
        string  foglioParticella; // Foglio-Particella
        string  tipologia; // tipologia
        string  superficie; // superficie
    }
    
     struct Barbatellaio {
        
        uint    upc; // Universal Product Code (UPC)
        string  denominazione; // Place Name
        string  foglioParticella; // Foglio-Particella
        string  superficie; // superficie
    }

    mapping (uint => ImpiantoViticolo) impViticoli;
    mapping (uint => LocaleTecnico) locTecnici;
    mapping (uint => Barbatellaio) barbatellai;
    
    
  
    modifier onlyIfNotSealed() //semantic when sealed is not possible to change sensible data
    {
        if (isSealed)
            revert();
        _;
    }

    event EventCreated(address self,address creator);
    event EventChangedString(address self,string property,string value); 
    event EventSealed(address self);

   constructor(string memory name, string memory lon,string memory lat,string memory piva)  {
        _name = name;
        _lon=lon;
        _lat=lat;
        _piva=piva;
        _creator=msg.sender;
       emit EventCreated(address(this),owner); 
    }
    
    function setSealed() public  onlyOwner  { isSealed = true;  emit EventSealed(address(this));   } //seal down contract not reversible
    
     // Define a modifier that checks if an grapeItem.state of a upc is Planted
    modifier isAddedImpiantoViticolo(uint _upc) {
        require(impViticoli[_upc].upc == 0, "not Added");
        _;
    }

    //verificare se non è già inserito uno con lo stesso codice    
    function addImpiantoViticolo(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _varieta, string memory _superficie) onlyOwner onlyIfNotSealed isAddedImpiantoViticolo(_upc) public returns (bool retVal) {
        ImpiantoViticolo memory newImpVit = ImpiantoViticolo({upc: _upc,denominazione: _denominazione, foglioParticella: _foglioParticella, varieta: _varieta, superficie:_superficie });
        impViticoli[_upc]=newImpVit;
        emit EventChangedString(address(this),'addImpiantoViticolo',_denominazione);
        retVal= true;
    }
    
    
    function updateImpiantoViticolo(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _varieta, string memory _superficie) onlyOwner onlyIfNotSealed public returns (bool retVal) {
        require(impViticoli[_upc].upc != 0);
        impViticoli[_upc].denominazione =_denominazione;
        impViticoli[_upc].foglioParticella = _foglioParticella;
        impViticoli[_upc].varieta = _varieta;
        impViticoli[_upc].superficie = _superficie;
        emit EventChangedString(address(this),'updateImpiantoViticolo',_denominazione);
        retVal= true;
    }
    
    function retrieveImpiantoViticoloInfo(uint _upc) public view returns
    (
    uint    upc,
    string  memory _denominazione,
    string  memory _foglioParticella,
    string  memory _varieta,
    string  memory _superficie,
    address creator
    )
    {
    ImpiantoViticolo memory impV = impViticoli[_upc];

    return
    (
      impV.upc,
      impV.denominazione,
      impV.foglioParticella,
      impV.varieta,
      impV.superficie,
      _creator
    );

  }
  
   function addLocalTecnico(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _tipologia, string memory _superficie) onlyOwner onlyIfNotSealed public returns (bool retVal) {
        require(locTecnici[_upc].upc == 0);
        LocaleTecnico memory newLocTec = LocaleTecnico({upc: _upc,denominazione: _denominazione, foglioParticella: _foglioParticella, tipologia: _tipologia, superficie:_superficie });
        locTecnici[_upc]=newLocTec;
        emit EventChangedString(address(this),'addLocalTecnico',_denominazione);
        retVal= true;
    }
    
    
    function updateLocaleTecnico(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _tipologia, string memory _superficie) onlyOwner onlyIfNotSealed public returns (bool retVal) {
        require(locTecnici[_upc].upc != 0);
        locTecnici[_upc].denominazione =_denominazione;
        locTecnici[_upc].foglioParticella = _foglioParticella;
        locTecnici[_upc].tipologia = _tipologia;
        locTecnici[_upc].superficie = _superficie;
        emit EventChangedString(address(this),'updateLocaleTecnico',_denominazione);
        retVal= true;
    }
    
    function retrieveLocaleTecnico(uint _upc) public view returns
    (
    uint    upc,
    string  memory _denominazione,
    string  memory _foglioParticella,
    string  memory _tipologia,
    string  memory _superficie,
    address creator
    )
    {
    LocaleTecnico memory locTec = locTecnici[_upc];

    return
    (
      locTec.upc,
      locTec.denominazione,
      locTec.foglioParticella,
      locTec.tipologia,
      locTec.superficie,
      _creator
    );

  }
  
  
  function addBarbatellaio(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _superficie) onlyOwner onlyIfNotSealed public returns (bool retVal) {
        require(barbatellai[_upc].upc == 0);
        Barbatellaio memory newBarb = Barbatellaio({upc: _upc,denominazione: _denominazione, foglioParticella: _foglioParticella, superficie:_superficie });
        barbatellai[_upc]=newBarb;
        emit EventChangedString(address(this),'addBarbatellaio',_denominazione);
        retVal= true;
    }
    
    
    function updateBarbatellaio(uint _upc,string memory _denominazione, string memory _foglioParticella, string memory _superficie) onlyOwner onlyIfNotSealed public returns (bool retVal) {
        require(barbatellai[_upc].upc != 0);
        barbatellai[_upc].denominazione =_denominazione;
        barbatellai[_upc].foglioParticella = _foglioParticella;
        barbatellai[_upc].superficie = _superficie;
        emit EventChangedString(address(this),'updateBarbatellaio',_denominazione);
        retVal= true;
    }
    
    function retrieveBarbatellaio(uint _upc) public view returns
    (
    uint    upc,
    string  memory _denominazione,
    string  memory _foglioParticella,
    string  memory _superficie,
    address creator
    )
    {
    Barbatellaio memory barb = barbatellai[_upc];

    return
    (
      barb.upc,
      barb.denominazione,
      barb.foglioParticella,
      barb.superficie,
      _creator
    );

  }
  
   function retrieveCompanyInfo() public view returns ( string  memory name, string  memory lon, string  memory lat, string  memory piva){
        name=_name;
        lon=_lon;
        lat=_lat;
        piva=_piva;
    }
}