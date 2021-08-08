// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HalimWutan is ERC721, ERC721Enumerable, Ownable {
    // 토큰 최대 발행량
    uint32 private constant MAX_Supply = 20;
    
    // 토큰 구조체
    struct HWTData {
        uint256 tokenId;    // 토큰 id: 1부터 시작
        address[] ownerHistory;     // 소유자 기록: 소유했었던 사람들의 지갑 주소 배열
        uint256 timestamp;      // 토큰 생성 시각
    }
    
    // 토큰 생성
    mapping (uint256 => HWTData) private _hwtlist;
    event HWTCreated (uint indexed tokenId, uint256 timestamp);

    //토큰 전송
    event HWTTransfered (uint256 tokenId, address to);
    
    constructor() ERC721("HalimWutan", "HWT") {}
    
    // 토큰 기능 함수

    /**
     * @dev 토큰 생성 onlyOwner 최초 생성자만 사용가능
     */
    function createHWT() public onlyOwner{
        require(totalSupply() != MAX_Supply, "Can not create HWT anymore!");
        
        uint256 tokenId = totalSupply() + 1; // 토큰 id: 1부터 시작
        
        _safeMint(msg.sender, tokenId);
        
        address[] memory ownerHistory;
        
        HWTData memory newHWTData = HWTData({
            tokenId : tokenId,
            ownerHistory : ownerHistory,
            timestamp : block.timestamp
        });
        
        _hwtlist[tokenId] = newHWTData;
        _hwtlist[tokenId].ownerHistory.push(msg.sender);
        
        emit HWTCreated(tokenId, block.timestamp);
    }
    
    /**
     * @dev 토큰 전송
     * @param tokenId_ 전송할 토큰 id 입력
     * @param to_ 전송할 주소 입력 
     */
    function transferHWT(uint256 tokenId_, address to_) public {
        safeTransferFrom(msg.sender, to_, tokenId_);
        emit HWTTransfered(tokenId_, to_);
    }
    
    /**
     * @dev 토큰 정보 조회
     * @param tokenId_ 조회할 토큰 id 입력
     * @return 토큰 id, 역대 소유자들 지갑 주소, 생성 시각, 이미지URI 반환
     */
    function getHWT(uint tokenId_) public view returns(uint256, address[] memory, uint256, string memory){
        require(_hwtlist[tokenId_].tokenId != 0, "HWT does not exist!");
        return (
            _hwtlist[tokenId_].tokenId,
            _hwtlist[tokenId_].ownerHistory,
            _hwtlist[tokenId_].timestamp,
            tokenURI(tokenId_)
        );
    }
    
    /**
     * @dev 토큰 수량 정보 조회
     * @return 발행된 토큰 수량 반환
     */
    function getHWTCount() public view returns(uint256){
        return(totalSupply());
    }

    // 오버라이딩 함수들
    function _transfer(address from, address to, uint256 tokenId) internal override{
        super._transfer(from, to, tokenId);
        _hwtlist[tokenId].ownerHistory.push(to);    // 토큰 전송 시 소유자 이력에 상대방 주소 추가 
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmVkjyhHhHgwcM4h4SLQNpa7AfcdXWK24u8jdUBAzRFd5i?filename=halimwutan.jpg";   // 토큰 이미지 URI : 보안성을 위해 IPFS 사용
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}