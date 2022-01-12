/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.8.7;
contract knjiznica{
    struct Knjiga{
        string _isbn;
        string _naslov;
        string _avtor;
        uint podaljsan;
        bool izposojena;
        uint vrniti;
        uint trenutni;
    }

    struct Izposojevalec{
        uint _id;
        string ime;
        
    }

    struct Izposoja{
        uint _id;
        uint datum;
        uint izpoId;
    }

    
    mapping(uint => Knjiga) public knjige;
    mapping(uint => Izposojevalec) public izposojevalci;
    mapping(uint => Izposoja) public izposoje;

    Knjiga knjiga = Knjiga("123123", "harry", "jk", 0, false, 0, 0);
    Knjiga knjiga2 = Knjiga("123", "harryp", "jkr", 0, false, 0, 0);
    Izposojevalec iz = Izposojevalec(1, "Janez");
    Izposojevalec iz2 = Izposojevalec(2, "David");
    constructor() public{
        knjige[0] = knjiga;
        knjige[1] = knjiga2;
        izposojevalci[0] = iz;
        izposojevalci[1] = iz2;
    }
    uint stknjig=2;
    
    uint stIzpo=2;

    event izposoja(
        uint izpId,
        string isb

    );

    event vrnitev(
        uint izpId,
        string isb

    );

    event podaljsanje(
        uint izpId,
        string isb

    );

    modifier neIzposojena(string memory a){
         for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(a))){
                if(knjige[i].izposojena==false){
                    _;
                }
            }
    }
    }
     modifier izposojena(string memory a){
         for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(a))){
                if(knjige[i].izposojena==true){
                    _;
                }
            }
    }
    }
     modifier pod(string memory a){
         for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(a))){
                    if(knjige[i].izposojena==true){
                        if(knjige[i].podaljsan<4){
                            _;
                        }
                        
                    }
                }
    }
    }

    function izposodi(string memory isb, uint a) public neIzposojena(isb){
        bool obstaja = false;
        
        for(uint i = 0; i< stIzpo; i++){
            if(izposojevalci[i]._id==a){
            obstaja=true;
            break;
            }
        }
        for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(isb)) && obstaja){
                
                    knjige[i].izposojena = true;
                    knjige[i].trenutni = a;
                    knjige[i].vrniti= block.timestamp+1814400;
                    emit izposoja(a, isb);
            }

        }

    } 

    function vrni(string memory isb) public izposojena(isb) {
       for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(isb))){
                emit vrnitev(knjige[i].trenutni, isb);
                knjige[i].izposojena = false;
                knjige[i].trenutni = 0;
                knjige[i].vrniti= 0;
                knjige[i].podaljsan=0;
                
                
            }

        } 
    }

    function podaljsaj(string memory isb) public pod(isb) {
        for(uint i = 0; i< stknjig; i++){
                if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(isb))){
                    
                            
                    knjige[i].vrniti+=259200;
                    knjige[i].podaljsan++;
                    emit podaljsanje(knjige[i].trenutni, isb);
                        
                    
                }

            } 
        }
    function raz(string memory nas) public view returns(uint){
        uint stevec=0;
       for(uint i = 0; i< stknjig; i++){
            if(keccak256(bytes(knjige[i]._naslov))==keccak256(bytes(nas))){
                if(knjige[i].izposojena==false){
                    stevec++;
                }
            }


        } 
        return stevec;
    }
    function iskanje(string memory isk) public view returns(Knjiga memory){
            
        for(uint i = 0; i< stknjig; i++){
                if(keccak256(bytes(knjige[i]._naslov))==keccak256(bytes(isk))){
                    return knjige[i];
                }
                if(keccak256(bytes(knjige[i]._isbn))==keccak256(bytes(isk))){
                    return knjige[i];
                }
                if(keccak256(bytes(knjige[i]._avtor))==keccak256(bytes(isk))){
                    return knjige[i];
                }

            } 
            return Knjiga("","", "", 0, false, 0, 0);
        }



    
}