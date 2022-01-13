/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.7;
contract Knjiznica{


	
	mapping(uint => Stranka) public stranke;
    mapping(uint => Knjiga) public knjige;

    uint strankeCount;
	uint knjigeCount;

    struct Stranka{
        int stranka_id;
        address naslov;
        
    }

    struct Knjiga{
        uint knjiga_id;
        string naslov;
        string ISBN;
        string avtor;
        bool izposojena;
        uint datumVrnitve;
        uint trenutniIzposojevalec;
        uint podaljsanja;
    }

        function registerKnjiga(uint id, string memory naslov, string memory ISBN, 
                             string memory avtor, bool izposojena, uint datumVrnitve, uint256 trenutniIzposojevalec, uint podaljsanja) public {
        Knjiga memory newKnjiga;
        newKnjiga.knjiga_id = id;
        newKnjiga.naslov = naslov;
        newKnjiga.ISBN = ISBN;
        newKnjiga.avtor = avtor;
        newKnjiga.izposojena = izposojena;
        newKnjiga.datumVrnitve = datumVrnitve;
         newKnjiga.trenutniIzposojevalec = trenutniIzposojevalec;
        newKnjiga.podaljsanja = podaljsanja;
        knjige[id] = newKnjiga;
        
    }

     function getKnjiga(uint256 id) public view returns (string memory, string memory, string memory){
        Knjiga storage s = knjige[id];
        return (s.naslov,s.avtor,s.ISBN);
    }



	function izposojaKnjige(uint p, uint b) public returns(uint result)
		{

			for(uint i = 0; i <= knjigeCount; i++)
				{
				uint id = knjige[i].knjiga_id;
               if(id == p)
                {
                    knjige[i].izposojena = true;
                    knjige[i].trenutniIzposojevalec = b;
                  knjige[i].datumVrnitve = block.timestamp + 7889231; 
               result = knjige[i].knjiga_id;
             return result;

                }


					}
                   
			}

          





}