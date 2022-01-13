/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Garić_Dino_Nal8
 * @dev Store & retrieve value in a variable
 */
contract Knjiznica 
{
    //Število izposojevalcev
    uint256 public StIzposojevalcev;

    //Število knjig
    uint256 public StKnjig;

    //Mapping "Array" za izposojevalce
    mapping(uint => Izposojevalec) public Izposojevalci;

    //Mapping "Array" za knjige
    mapping(uint=> Knjiga) public Knjige;

    //Struktura ali "class" za Izposojevalca !
    struct Izposojevalec
    {
        //Podatki izposojevalca:
        uint ID;
        string Ime;
        string Priimek;
    }

    //Struktura ali "class" za knjigo !
    struct Knjiga
    {
        //Podatki knjige:
        uint ID;
        string ISBN;
        string Naslov;
        string  Avtor;

        //Datum kdaj je treba knjigo vrnat
        uint256 DatumVrnitve;
        //Stevilo kolikokrat se je knjiga podaljšala
        uint  StPodaljsanj;    
        //Shrani se trenutni "call-er"
        uint Izposojevalec;
        //Stanje izposoje knjige
        bool Izposojena;
    }


    //Dodajanje izposojevalcev
    function DodajIzposojevalca(string memory Ime, string memory Priimek) public
    {        
        //Incrementira stevilo izposojevalcev
        StIzposojevalcev += 1;
        //Doda uporabnika v array (mapping)
        Izposojevalci[StIzposojevalcev] = Izposojevalec(StIzposojevalcev, Ime, Priimek);
    }

        //Dodajanje izposojevalcev
    function DodajKnjigo(string memory ISBN, string memory Naslov, string memory Avtor) public
    {        
        //Incrementira stevilo knjig
        StKnjig += 1;
        //Doda knjigo v array (mapping)
        Knjige[StKnjig] = Knjiga(StKnjig, ISBN, Naslov, Avtor, 0, 0, 0, false);
    }
    

    //----------------------------------------------------Glavne Funkcije----------------------------------------------------

    //Modifier za izposojanje knjige
    modifier MoznaIzposoja(uint ID_Knjige)
    {
        //Preveri, če je knjiga na voljo
        require(Knjige[ID_Knjige].Izposojena == false);
        _;
    }

        //Modifier za vrnitev knjige
    modifier MoznaVrnitev(uint ID_Knjige, uint ID_Izposojevalca)
    {
        //Preveri, če je zapisan uporabnik, ki si je izposodil
        require(Knjige[ID_Knjige].Izposojevalec == ID_Izposojevalca);
        _;
    }

    //Modifier za podaljsanje knjige
    modifier MoznoPodaljsanje(uint ID_Knjige)
    {
        //Preveri, če je knjiga bila že 3x podaljšana
        require(Knjige[ID_Knjige].StPodaljsanj < 3);
        //Preveri tudi ali je sploh izposojena
        require(Knjige[ID_Knjige].Izposojena != false);
        _;
    }
    
    //1. Izposoja knjige: knjigo je potrebno nastaviti na izposojeno, ter določiti datum, ko je potrebno knjigo vrniti v knjižnico (3 tedne po izposoji). 
    //Prav tako je potrebno določiti trenutnega izposojevalca. Pazite: če je knjiga že izposojena, si je ne moremo izposoditi še enkrat!
    function IzposojaKnjige(uint ID_Knjige, uint ID_Izposojevalca) public MoznaIzposoja(ID_Knjige)
    {
        //Zapišejo se podatki po izposoji
        Knjige[ID_Knjige].Izposojena = true;
        Knjige[ID_Knjige].Izposojevalec = ID_Izposojevalca;
        Knjige[ID_Knjige].DatumVrnitve = block.timestamp + 1814400;
    }

    //2. Vrnitev knjige: knjigo je potrebno nastaviti na neizposojeno, ter pobrisati datum vrnitve in trenutnega izposojevalca.
    function VrnitevKnjige(uint ID_Knjige, uint ID_Izposojevalca) public MoznaVrnitev(ID_Knjige, ID_Izposojevalca)
    {
        //Vse se nazaj nastavi na "default" vrednosti
        Knjige[ID_Knjige].Izposojena = false;
        Knjige[ID_Knjige].Izposojevalec = 0;
        Knjige[ID_Knjige].DatumVrnitve = 0;
        Knjige[ID_Knjige].StPodaljsanj = 0;
    }

    //3. Preverjanje razpoložljivosti: iskanje knjige po naslovu in vračanje števila razpoložljivih knjig s tem naslovom.
    function Razpolozljive(string memory Naslov) public view returns (uint)
    {
        uint StRazpolozljivih = 1;
         for(uint i = 0; i < StKnjig; i++)
         {
             if(keccak256(abi.encodePacked(Knjige[i].Naslov))==keccak256(abi.encodePacked(Naslov)))
             {
                StRazpolozljivih += 1;
             }
         }
         return StRazpolozljivih;
    }


    //4. Iskanje knjige: iskanje knjige po ISBN, avtorju ali naslovu, ter vračanje podatkov o knjigi.
    function IskanjeKnjige(string memory Niz) public view returns (Knjiga[] memory)
    {
        uint TempCounter=0;
        for(uint i = 0; i < StKnjig; i++)
        {
            if(keccak256(abi.encodePacked(Knjige[i].ISBN))==keccak256(abi.encodePacked(Niz)) 
                || keccak256(abi.encodePacked(Knjige[i].Naslov))==keccak256(abi.encodePacked(Niz)) 
                || keccak256(abi.encodePacked(Knjige[i].Avtor))==keccak256(abi.encodePacked(Niz)))
            {
                TempCounter++;
            }
        }

        Knjiga[] memory NajdeneKnjige = new Knjiga[](TempCounter);

        uint j=0;
        for (uint i = 0; i < 6; i++) 
        {
            if(keccak256(abi.encodePacked(Knjige[i].ISBN))==keccak256(abi.encodePacked(Niz)) 
                || keccak256(abi.encodePacked(Knjige[i].Naslov))==keccak256(abi.encodePacked(Niz)) 
                || keccak256(abi.encodePacked(Knjige[i].Avtor))==keccak256(abi.encodePacked(Niz))) 
            {
                Knjiga storage NajdenaKnjiga = Knjige[i];
                NajdeneKnjige[j] = NajdenaKnjiga;
                j++;
            }
        }

        return NajdeneKnjige;
    }

    //5. Podaljšanje knjige: za izbrano knjigo je potrebno posodobiti datum, do katerega je potrebno knjigo vrniti. 
    //Pri vsakem podaljšanju se datum podaljša za tri dni. Izposojeno knjigo se lahko podaljša samo trikrat, preden jo je potrebno vrniti.
    //Neizposojenih knjig ne morete podaljšati!
    function PodaljasanjeKnjige(uint ID_Knjige) public MoznoPodaljsanje(ID_Knjige)
    {
        Knjige[ID_Knjige].StPodaljsanj = Knjige[ID_Knjige].StPodaljsanj + 1;
        Knjige[ID_Knjige].DatumVrnitve = Knjige[ID_Knjige].DatumVrnitve + 10800;
    }


}