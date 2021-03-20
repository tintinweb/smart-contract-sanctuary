pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";

contract NFTMultiOwner is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    mapping(address => bool) public managers; 
    address[] public managersArray; 
    address public deployer;
    string[] public messagesArray;

    constructor() ERC721("NFT MultiOwner", "NMO") {
        managers[msg.sender] = true;
        managersArray.push(msg.sender);
        deployer = msg.sender;
    }

    function addNFT(address ownerNews, string memory tokenURI)
        public restricted
        returns (uint256, address)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(ownerNews, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return (newItemId, ownerNews);
    }
    
    function addManagers(address newManagerAddress) public restricted{ // Funzione per aggiungere owners
        require(!managers[newManagerAddress]); 
        
        managers[newManagerAddress] = true;
        managersArray.push(newManagerAddress);
    }
    
    function deleteManager(address managerAddress) public restricted{ // rimuovere un manager da un array
        if(managerAddress == deployer)
        {
            revert();
        }
        
        require(managers[managerAddress], "Not deleted! Manager not present");
        require(managersArray.length>1, "The contract requires at least one manager"); 
        
        
        delete managers[managerAddress]; // lo elimina dalla maps
        
        //remove from array
        for(uint i = 0; i < managersArray.length; i++)
        {
            if(managersArray[i] == managerAddress)
            {
                delete managersArray[i];
                //managersArray.length--;
                return;
            }
        }
    }
    
    function viewManagers() public view returns(address[] memory){
        return managersArray;
    }
    
    modifier restricted() { // permette operazione solo ai managers
        require(managers[msg.sender], "this is not manager");
        _;
    }

}