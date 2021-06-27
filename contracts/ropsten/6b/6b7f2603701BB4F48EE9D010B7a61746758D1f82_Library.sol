/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.5.1;
contract Library {
    uint public stevecKnjig = 0;
    uint public stevecOseb = 0;
    mapping(uint => Knjiga) public knjige;
    mapping(uint => Oseba) public osebe;
    
    //Knjiga
    struct Knjiga{
        uint ID;
        string ISBN;
        string avtor;
        string naslov;
        bool moznostIzposoje;
        int idOsebe;
        uint datumIzposoje;
        uint datumVrnitve;
    }
    
    //Oseba
    struct Oseba {
        uint ID;
        string ime;
        string priimek;
    }
    
    //Dodajanje knjige
    function addKnjiga(string memory ISBN, string memory avtor, string memory naslov) public{
        knjige[stevecKnjig] = Knjiga(stevecKnjig, ISBN, avtor, naslov, true, int(-1), uint(1), uint(1));
        stetjeKnjig();
    }
    
    //Dodajanje osebe
    function addOseba(string memory ime, string memory priimek) public{
        osebe[stevecOseb] = Oseba(stevecOseb, ime, priimek);
        stetjeOseb();
    }
    
    //Štetje knjig in oseb
    function stetjeKnjig() internal {
        stevecKnjig += 1;
    }
    
    function stetjeOseb() internal {
        stevecOseb += 1;
    }
    
    //Preverjanje, če je knjiga izposojena
    modifier jeIzposojena(string memory naslovKnjige){
        bool moznost = false;
        for(uint i; i<= stevecKnjig; i++){
            if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(naslovKnjige))){
                moznost = knjige[i].moznostIzposoje;
            }    
        }
        
        require(moznost == true);
        _;
    }
    
    //Preverjanje, če lahko knjigo vrnemo
    modifier moznostVrnitve(string memory naslovKnjige){
        bool moznost = true;
        for(uint i; i<= stevecKnjig; i++){
            if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(naslovKnjige))){
                moznost = knjige[i].moznostIzposoje;
            }    
        }
        
        require(moznost == false);
        _;
    }
    
    //Ko nekdo knjigo prevzame
    event izposojaKnjige (int Oseba, string Knjiganaslov);
    function izposoja(int OsebaID, string memory naslovKnjige) public jeIzposojena(naslovKnjige){
        for(uint i; i<= stevecKnjig; i++){
            if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(naslovKnjige))){
               if(knjige[i].moznostIzposoje == true){
                   knjige[i].moznostIzposoje = false;
                   knjige[i].idOsebe = OsebaID;
                   knjige[i].datumIzposoje = block.timestamp;
                   knjige[i].datumVrnitve = knjige[i].datumIzposoje + 1814400;
                   emit izposojaKnjige(OsebaID, naslovKnjige);
               }
            }    
        }
    }
    
    //Ko nekdo knjigo vrne
    event vrnitevKnjige (string Knjiganaslov);
    function return_Knjiga(int OsebaID, string memory naslovKnjige) public moznostVrnitve(naslovKnjige){
        for(uint i; i<= stevecKnjig; i++){
            if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(naslovKnjige)) && knjige[i].idOsebe == OsebaID){
               if(knjige[i].moznostIzposoje == false){
                   knjige[i].idOsebe = -1;
                   knjige[i].moznostIzposoje = true;
                   knjige[i].datumVrnitve = 0;
                   emit vrnitevKnjige(naslovKnjige);
               }
            }   
        }
    }
    
    //Preverimo zalogo knjige
    event razpolozljivostKnjige (uint zaloga);
    function zaloga_Knjiga(string memory naslovKnjige) public view returns(uint){
        uint st = 0;
        for(uint i; i<= stevecKnjig; i++){
            if(keccak256(abi.encodePacked(knjige[i].naslov)) == keccak256(abi.encodePacked(naslovKnjige)) && knjige[i].moznostIzposoje == true){
               st += 1;
            }   
        }
        return st;
    }

}