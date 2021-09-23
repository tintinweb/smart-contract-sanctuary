// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721URIStorage.sol";
import "./Counters.sol";


contract TreeFactory is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address private minter;
    address private creator;
    address private palgunamu;
    bool private roleCount = false;

    mapping (uint256 => HTRData) private _htrlist;
    
    event MinterChanged(address indexed from, address to);
    event CreatedHTR(uint256 newItemId, uint256 coordinateX, uint256 coordinateY, uint256 timestamp, bool buyable);
    event SendedHTR(uint256 tokenId, address to);

    struct HTRData {
        uint256 tokenId;            // 토큰 id: 1부터 시작
        address[] ownerHistory;     // 소유자 기록: 소유했었던 사람들의 지갑 주소 배열
        uint256 timestamp;          // 토큰 생성 시각
        uint256 coordinateX;        
        uint256 coordinateY;
        bool buyable;
    }

    constructor() ERC721("HolomiTree", "HTR") {
        minter = msg.sender;
        creator = msg.sender;
    }
    
    function passMinterRole(address _caller, address _minter) public returns(bool) {
        require(roleCount == false, "[ ERROR ] Permission Denied : already passed once");
        require(_caller == minter, "[ ERROR ] Permission Denied : only owner can change pass minter role treeminter");
        minter = _minter; //transfer minting role to palgunamu
        roleCount = true;
        emit MinterChanged(msg.sender, _minter);
        
        return true;
    }
    
    function setApproveAddress(address _palgunamu) public{
        require(msg.sender == minter, "[ ERROR ] Permission Denied : msg.sender does not have role treeapprove");    //only palgunamu can setApprove
        palgunamu = _palgunamu;
    }
    
    function _setApprove(uint256 _tokenId) private {
        approve(palgunamu, _tokenId);
    }

    function createHTR(uint256 _coordinateX, uint256 _coordinateY, string memory _tokenURI, uint16 _count) public {
        require(msg.sender == creator, "[ ERROR ] Permission Denied : msg.sender does not have creator role");
        for(uint i = 0; i < _count; i++){
            _tokenIds.increment();
    
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, _tokenURI);
            
            address[] memory ownerHistory;
            
            HTRData memory newHTRData = HTRData({
                tokenId : newItemId,
                ownerHistory : ownerHistory,
                timestamp : block.timestamp,
                coordinateX: _coordinateX,
                coordinateY: _coordinateY,
                buyable: true
            });
            
            _htrlist[newItemId] = newHTRData;
            _htrlist[newItemId].ownerHistory.push(msg.sender);
            
            _setApprove(newItemId);
    
            emit CreatedHTR(newItemId, _coordinateX, _coordinateY, block.timestamp, true);
        }
    }
    
    function getHTR(uint _tokenId) public view returns(uint256, address[] memory, uint256, uint256, uint256, string memory, bool){
        require(_htrlist[_tokenId].tokenId != 0, "[ ERROR ] : HTR does not exist!");
        return (
            _htrlist[_tokenId].tokenId,
            _htrlist[_tokenId].ownerHistory,
            _htrlist[_tokenId].timestamp,
            _htrlist[_tokenId].coordinateX,
            _htrlist[_tokenId].coordinateY,
            tokenURI(_tokenId),
            _htrlist[_tokenId].buyable
        );
    }
    
    function getHTRCount() public view returns(uint256){
        return(_tokenIds.current());
    }
    
    function transferHTR(uint256 _tokenId, address _to) public {
        require(msg.sender == minter, "[ ERROR ] Permission Denied : msg.sender does not have transfer role");
        safeTransferFrom(creator, _to, _tokenId);
    }
    
    function sendHTR(uint256 _tokenId, address _to) public {
        safeTransferFrom(msg.sender, _to, _tokenId);
        emit SendedHTR(_tokenId, _to);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal override{
        super._transfer(from, to, tokenId);
        _htrlist[tokenId].ownerHistory.push(to);    // 토큰 전송 시 소유자 이력에 상대방 주소 추가 
        _htrlist[tokenId].buyable = false;
    }
}