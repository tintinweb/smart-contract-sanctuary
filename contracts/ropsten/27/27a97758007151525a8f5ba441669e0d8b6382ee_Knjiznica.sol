/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity >=0.7.0 <0.8.11;
pragma experimental ABIEncoderV2;


contract Knjiznica 
{
    struct Knjiga
    {
        uint _id;
        string _ISBN;
        string _naslov;
        string _avtor;
        uint256 _vrnitev;
        uint _podaljsano;
        address _uporabnik;
        bool _stanje;

    }
    
    mapping(uint=> Knjiga) public Knjige;


    constructor () public 
    {
       Knjige[0] = Knjiga(0,"1234","The Witcher","Andrzej Sapkowski",0,0,address(0),false);
       Knjige[1] = Knjiga(1,"1234","The Witcher","Andrzej Sapkowski",0,0,address(0),false);
       Knjige[2] = Knjiga(2,"1234","The Witcher","Andrzej Sapkowski",0,0,address(0),false);
       Knjige[3] = Knjiga(3,"321","The Last Wish","Andrzej Sapkowski",0,0,address(0),false);
       Knjige[4] = Knjiga(4,"321","The Last Wish","Andrzej Sapkowski",0,0,address(0),false);
       Knjige[5] = Knjiga(5,"7890","Sword of Destiny","Andrzej Sapkowski",0,0,address(0),false);
    }
    
    modifier statusKnjige(uint id)
    {
        require(Knjige[id]._stanje==false);
        _;
    }
    
    modifier vraciloknjige(uint id)
    {
        require(Knjige[id]._uporabnik==msg.sender);
        _;
    }

    modifier statusPodaljsanja(uint id)
    {
        require(Knjige[id]._stanje==true);
        require(Knjige[id]._podaljsano<=2);
        _;
    }

    event izposoja_(
        Knjiga _knjiga
    );
    function izposoja(uint id) public statusKnjige(id)
    {
        Knjige[id]._stanje=true;
        Knjige[id]._uporabnik=msg.sender;
        Knjige[id]._vrnitev = block.timestamp+(21*86400000);
        emit izposoja_(Knjige[id]);
    }

    event vrnitev_(
        Knjiga _knjiga
    );

    function vrnitev(uint id) public vraciloknjige(id)
    {
        Knjige[id]._stanje=false;
        Knjige[id]._uporabnik=address(0);
        Knjige[id]._vrnitev = 0;
        Knjige[id]._podaljsano = 0;
        emit vrnitev_(Knjige[id]);
    }
    

    event podaljsanje_(
        Knjiga _knjiga
    );
    function podaljsanje(uint id) public statusPodaljsanja(id)
    {
        Knjige[id]._podaljsano = Knjige[id]._podaljsano+1;
        Knjige[id]._vrnitev = block.timestamp+(3*86400000);
        emit podaljsanje_(Knjige[id]);
    }

    function isciKnjigo(string memory isci) public view returns(string memory, string memory, string memory, bool, address, uint256)
    {
        uint i = 1;
        uint stevec = 0;
        while(Knjige[i]._id != 0)
        {
            stevec++;
            i++;
        }

        for(i = 0; i <= stevec; i++)
        {       
            if(keccak256(abi.encodePacked(Knjige[i]._naslov)) == keccak256(abi.encodePacked(isci)) || keccak256(abi.encodePacked(Knjige[i]._ISBN)) == keccak256(abi.encodePacked(isci)) || keccak256(abi.encodePacked(Knjige[i]._avtor)) == keccak256(abi.encodePacked(isci)))
                {
                    return (Knjige[i]._naslov, Knjige[i]._avtor, Knjige[i]._ISBN, Knjige[i]._stanje, Knjige[i]._uporabnik, Knjige[i]._vrnitev);
                }    
        }            
	}
    
    function preveriZalogo(string memory isci) public view returns(uint )
		{
            uint i = 1;
            uint stevec = 0;
            
            while(Knjige[i]._id != 0)
            {
                stevec++;
                i++;
            }

            uint stevilo = 0;

            for(i = 0; i <= stevec; i++)
            {

              if(Knjige[i]._stanje == false)
                {
                if(keccak256(abi.encodePacked(Knjige[i]._naslov)) == keccak256(abi.encodePacked(isci)))
                    {
                    stevilo = stevilo + 1;
                    }
                }
            }
            return stevilo;
		}
}