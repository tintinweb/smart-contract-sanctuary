// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract Mikan is  ERC721URIStorage {

    string Messagefrom___CreatorName___ = "_______This message is written in BlockChain_______";

    mapping(uint256 => string) ipfsURIMap;
    mapping(uint256 => string) arweaveURIMap;
    mapping(uint256 => string) onchainDataMap;
    mapping(uint256 => string) additional1URIMap;
    mapping(uint256 => string) additional2URIMap;

    enum selectedStorageByOwner { IPFS , ARWEAVE ,  ADD1 , ADD2 }

    mapping(uint256 => selectedStorageByOwner) selectedStorageByOwnerMap;


    address staff1 = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;
    address staff2 = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;

    mapping(uint256 => string) onchainImageMap;


    address public creator;
    uint256 public number = 1;

    event Mint();
    event SetTokenURI( uint256 , string );


    function mint() public {
        require( creator == _msgSender() );
        _safeMint(_msgSender() , number);
        number++;
        emit Mint();
    }



    function setTokenURI( uint256 _num , string memory _uri ) public{
        require( creator == _msgSender() );
        _setTokenURI( _num , _uri );
        //emit SetTokenURI( _num , _uri );
    }

    function selectStorage(uint256 _id , selectedStorageByOwner _selected ) public {
        require(_msgSender() == ownerOf(_id));
        selectedStorageByOwnerMap[_id] = _selected;
        //emit SetTokenURI( _id , tokenURI(_id) );
    }
    

    function setIPFSURIMap(uint256 _id , string memory _ipfsURI ) public {
        require( _msgSender() == creator || _msgSender() == staff1 || _msgSender() == staff2 );
        ipfsURIMap[_id] = _ipfsURI;
        _setTokenURI( _id , _ipfsURI );
        //emit SetTokenURI( _id , _ipfsURI );
    }

    function setArweaveURIMap(uint256 _id , string memory _ArweaveURI ) public {
        require( _msgSender() == creator || _msgSender() == staff1 || _msgSender() == staff2 );
        arweaveURIMap[_id] = _ArweaveURI;
        _setTokenURI( _id , _ArweaveURI );
        //emit SetTokenURI( _id , _ArweaveURI );
    }


    function setAdditional1URIMap(uint256 _id , string memory _add1) public {
        require( _msgSender() == creator || _msgSender() == staff1 || _msgSender() == staff2 );
        additional1URIMap[_id] = _add1;
    }
    
    //owner can set setAdditional2URIMap function
    function setAdditional2URIMap(uint256 _id , string memory _add2) public {
        require( _msgSender() == creator || _msgSender() == staff1 || _msgSender() == staff2 || _msgSender() == ownerOf(_id) );
        additional2URIMap[_id] = _add2;
    }


    function getIPFSURIMap(uint256 _id ) public view returns(string memory){
        return ipfsURIMap[_id];
    }

    function getArweaveURIMap(uint256 _id ) public view returns(string memory){
        return arweaveURIMap[_id];
    }

    function tokenSvgDataOf(uint256 _id ) public view returns(string memory){
        string memory image = getOnchainImage(_id);
        string memory prefix_image = string(abi.encodePacked("", image ));
        return string(abi.encodePacked( prefix_image , ""));
    }
    
    function getOnchainImage(uint256 _id) public view returns(string memory){
        return onchainImageMap[_id];
    }

    function getAdditional1URIMap(uint256 _id ) public view returns(string memory){
        return additional1URIMap[_id];
    }
    
    function getAdditional2URIMap(uint256 _id ) public view returns(string memory){
        return additional2URIMap[_id];
    }

    function tokenURI(uint256 _id) override(ERC721URIStorage) public view returns (string memory) {
        if ( selectedStorageByOwnerMap[_id] == selectedStorageByOwner.IPFS ) {
            return ipfsURIMap[_id];  
        } else if (selectedStorageByOwnerMap[_id] == selectedStorageByOwner.ARWEAVE) {
            return arweaveURIMap[_id];  
        // } else if (selectedStorageByOwnerMap[_id] == selectedStorageByOwner.ONCHAIN){
        //     return onchainDataMap[_id];
        } else if (selectedStorageByOwnerMap[_id] == selectedStorageByOwner.ADD1){
            return additional1URIMap[_id];
        } else if (selectedStorageByOwnerMap[_id] == selectedStorageByOwner.ADD2){
            return additional2URIMap[_id];
        }
        return super.tokenURI(_id);
    }

    constructor() ERC721("Mikan" , "Mikan" ) {
        creator = _msgSender();
        onchainImageMap[1] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240"><g id="mikan" fill-rule="evenodd"><path fill="#4b692f" fill-opacity="1" class="c0" d="M110,60h20v10h-20z" /><path fill="#8f563b" fill-opacity="1" class="c1" d="M80,80h10v10h-10zM120,80h10v10h-10zM150,90h10v10h-10zM100,100h10v10h-10zM50,110h10v10h-10zM70,120h10v10h-10zM140,120h10v10h-10zM180,120h10v10h-10zM100,140h10v10h-10zM140,140h10v10h-10zM110,170h10v10h-10z" /><path fill="#c9dae4" fill-opacity="1" class="c2" d="M0,0h240v240h-240zM40,150h10v10h10v10h10v10h20v10h60v-10h20v-10h10v-10h10v-10h10v-50h-10v-20h-10v-10h-10v-10h-20v-10h-60v10h-20v10h-10v10h-10v20h-10z" /><path fill="#df7126" fill-opacity="1" class="c3" d="M90,50h60v10h20v10h10v10h10v20h10v50h-10v10h-10v10h-10v10h-20v10h-60v-10h-20v-10h-10v-10h-10v-10h-10v-50h10v-20h10v-10h10v-10h20zM110,70h20v-10h-20zM80,90h10v-10h-10zM120,90h10v-10h-10zM150,100h10v-10h-10zM100,110h10v-10h-10zM50,120h10v-10h-10zM70,130h10v-10h-10zM140,130h10v-10h-10zM180,130h10v-10h-10zM100,150h10v-10h-10zM140,150h10v-10h-10zM110,180h10v-10h-10z" /></g></svg>';
    } 

}