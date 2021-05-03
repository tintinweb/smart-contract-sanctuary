//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./ERC721URIStorage.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract DToken is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    mapping(uint256 => uint256) gisIds;
    
    event CountersPreIncremented(uint256 counter);
    event SetGIS(uint256 id, uint256 gis);


    constructor() ERC721("DToken", "DTK") {}


    function mint(address _receiver, string memory _tokenURI, uint256 _gisId) external onlyOwner returns (uint256) {
        emit CountersPreIncremented(_tokenIds.current());
        
        _tokenIds.increment();

        uint256 _newNftTokenId = _tokenIds.current();
        _mint(_receiver, _newNftTokenId);
        _setTokenURI(_newNftTokenId, _tokenURI);
        gisIds[_newNftTokenId] = _gisId;
        
        emit SetGIS(_newNftTokenId, _gisId);

        return _newNftTokenId;
    }
    
    
     function transferStuckToken(uint256 _id, address _to) public onlyOwner {
        address _thisAddress = address(this);
        
        require(ownerOf(_id) == _thisAddress, "DTK: tokens not accessed to transfer");
        
        _transfer(_thisAddress, _to, _id);
    }
    
    // Be carefull with tokens amount. It should not be too big so the call will not fail on out of gas error.
    function multiTransferStuckToken(uint256[] memory _ids, address _to) external onlyOwner {
         for (uint256 i = 0; i < _ids.length; i++) {
            transferStuckToken(_ids[i], _to);
        }
     }
    
    
    function transferStuckERC20(IERC20 _token, address _to, uint256 _amount) external onlyOwner {
        require(_token.transfer(_to, _amount), "DTK: Transfer failed");
    }
}