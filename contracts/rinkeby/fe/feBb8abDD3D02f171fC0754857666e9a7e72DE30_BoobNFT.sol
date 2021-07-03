pragma solidity ^0.5.16;


import './ERC1155Tradable.sol';

contract BoobNFT is ERC1155Tradable {

    constructor(string memory _newBaseMetadataURI) ERC1155Tradable("BOOB NFT","BNFT",proxyRegistryAddress) public {
        setBaseMetadataURI(_newBaseMetadataURI); 
    }

    //burn function - accessible only by the owner of the contract ? tester cette fonction pour comprendre la portée !!! 
    // si tu peux burn les tokens de n'importe qui ^^' dans ce cas là voir comment faire ^^ 
    function burn(address _from, uint256 _id, uint256 _amount) public onlyOwner {
        _burn(_from,_id,_amount);
    }
    
    //batch burn 
    function batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        _batchBurn(_from,_ids,_amounts);
    }


}