// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";

contract MetaaniFor is  ERC721URIStorage  {

    address public owner;

    uint256 public nftid = 1;

    string currentURI = "";

    string[21] currentURIs;


    event Mint();
    event SetTokenURI( uint256 , string );
    event SetCurrentURI( string );

    function mint() public {
        require( _msgSender() == owner );
        _safeMint( owner , nftid);
        _setTokenURI( nftid , currentURI );
        emit Mint();
        emit SetTokenURI( nftid , currentURI );
        nftid++;
    }


    function setCurrentURI( string memory _uri ) public {
        require( _msgSender() == owner  );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        currentURI = _uri;
        emit SetCurrentURI( _uri );
    }

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( targetnftid , _uri );
        emit SetTokenURI( targetnftid , _uri );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
    }

    function setCurrentURIs1to20andMint() internal {
        currentURIs[1] = "ipfs://QmPmtGFideNaG9GqtTtQcKEqeiQP6jMxLLFdcyBnyYbjup";
        currentURIs[2] = "ipfs://QmQAw62gVSsgLgYBnocZ5AT7k8rrEoXCod7jg2p64auF5p";
        currentURIs[3] = "ipfs://QmPGJDf1jbEsANaFBoiem8zmu12ZEqz4HCqnebr2rXgujj";
        currentURIs[4] = "ipfs://QmWYxMcuZ4jFf3BEfNhkUqQTKHyB4CFPw2pQ9xryeR1zcB";
        currentURIs[5] = "ipfs://QmQirN5bWyP76yCorZQJQ6jfb98fXYfBDCDUDa8uPzJ4zf";
        currentURIs[6] = "ipfs://QmUPRsWnDCEiooav1oCBJTpgyKiW1jPYAZZHiVVMxvJL2B";
        currentURIs[7] = "ipfs://QmR7e7MP3fpJ1Hp9gzyPk8wQWEMHVfvu7bQwamGhV3yDvS";
        currentURIs[8] = "ipfs://QmXGaAcKBSWBtVAdh2112oiesvwtanxsPLZr4wiLjgZeYc";
        currentURIs[9] = "ipfs://QmaYHf6BqWh2ycLvfRJVFJBHrFkv3cbX3o2qWpWDjRT7qT";
        currentURIs[10] = "ipfs://QmUisPEsZFJJvERVJGdn5NRuKdv8emio6V5ixEKBHephdc";
        currentURIs[11] = "ipfs://QmbynZkXrMZCik7P9F9yqJyb8RTMmKTKQdjwgnKwatbJv9";
        currentURIs[12] = "ipfs://QmdnNs27WB19XxNhqF2RrBTnhgM4r7vhYXp6TJbRjs8CBN";
        currentURIs[13] = "ipfs://QmaXNh7CXkeuBBGXAbMCor6GzKTELHkbxqdRyDPKrjXhsk";
        currentURIs[14] = "ipfs://QmV7MNVyG3CVMWpLLwos4uGw4TrrfpgUCuhAWdNmnefDeR";
        currentURIs[15] = "ipfs://QmXEQsTWxDDZHgusxp59SKRE8JbzME8QKPSFrPv4jUBeLw";
        currentURIs[16] = "ipfs://QmfSi92TrMX6vVu4WJ2f7vwq1rgmPwXEcawzbGQJerU3rN";
        currentURIs[17] = "ipfs://QmUdhrdjQYtuwRj82Lb6SeDuHZUoe7UzNEvY6NUchK7jrT";
        currentURIs[18] = "ipfs://QmXCCUP625brpCSGMFdGjVLZDkp2yh73BVzMde3T1V12uf";
        currentURIs[19] = "ipfs://QmSx5XdTd4JBPM3VQY7evhSNEfGNyVzKsU1Ci5urYwuxQk";
        currentURIs[20] = "ipfs://QmYeh5GhRfLgucWwsdh8CNVrZ3XviBeC7dL2zQh7pC5pz4";
        for (uint i = 1; i <= 20; i++){
            _safeMint( 0x9A796Fcab2b3d3b6fe6A8ED257529168ab3B7041 , nftid);
            // _safeMint( msg.sender , nftid);
            _setTokenURI( nftid , currentURIs[i] );
            nftid++;
        }
    }



    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("Metaani For" , "MTANFOR" ) {
        owner = _msgSender();
        setCurrentURIs1to20andMint();
    } 
}