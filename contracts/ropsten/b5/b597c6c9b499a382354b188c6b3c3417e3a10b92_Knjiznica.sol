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
        int knjiga_id;
        string naslov;
        string ISBN;
        string avtor;
        bool izposojena;
        uint datumVrnitve;
        uint trenutniIzposojevalec;
        uint podaljsanja;
    }



	function izposojaKnjige(int p, uint b) public returns(int result)
		{

			for(uint i = 0; i <= knjigeCount; i++)
				{
				int id = knjige[i].knjiga_id;
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