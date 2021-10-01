pragma solidity 0.5.16;

import "./ERC721.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";


// 솔리디티에서는 is 키워드를 통해 컨트랙트를 상속받을 수 있습니다.
// 또한 상속받을 컨트랙트를 ,(콤마) 로 구분해 둘 이상의 컨트랙트를 다중 상속받는것도 가능합니다.
contract DeedToken is ERC721, ERC165 {

    using SafeMath for uint256;
    using Address for address;

    address payable public owner;
    mapping(bytes4 => bool) supportedInterfaces;


    //매핑(mapping) 은 "키 - 값" 구조로 데이터를 저장할 때 활용되는 타입입니다.
    // (자바스크립트의 Object 나 파이썬의 딕셔너리를 생각하시면 됩니다)

    // mapping(uint => address) public zombieToOwner;
    // uint형 키 0에 호출한 사람의 주소(address)가 할당된 모습입니다.
    // zombieToOwner[0] = msg.sender;
    mapping(uint256 => address) tokenOwners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) allowance;
    mapping(address => mapping(address => bool)) operators;

    struct asset {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    // 정적배열 - uint[4] 
    // new 키워드를 활용한 배열 : new uint[](5) 
    // 동적 배열 - asset[]
    //public 속성과 함께 배열을 선언하면 다른 컨트랙트에서도 배열을 읽을 수 있게 되지만, 쓸 수는 없습니다.
    asset[] public allTokens;

    //for enumeration
    uint256[] public allValidTokenIds; //same as allTokens but does't have invalid tokens
    mapping(uint256 => uint256) private allValidTokenIndex;


    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;
        supportedInterfaces[0x01ffc9a7] = true; //ERC165
        supportedInterfaces[0x80ac58cd] = true; //ERC721
    }


    // 함수에는 private & public 속성의 접근자를 지정할 수가 있습니다.
    // 함수에는 private & public 속성의 접근자를 지정할 수가 있습니다.
    // 함수는 기본적으로 public  속성으로 선언됩니다.
    // private 을 붙이면 컨트랙트의 외부에서는 함수를 호출할 수 없습니다.
    // 접근 지정자는 매개변수 바로 다음에 지정합니다. 

    // 솔리디티에는 public과 private 이외에도 internal과 external이라는 함수 접근 제어자가 존재합니다.
    // internal : private과 유사하나, 상속을 받은 컨트랙트(자식 컨트랙트)에서는 함수를 사용할 수 있게 합니다.
    // external : external을 붙인 함수는 컨트랙트의 외부에서만 호출될 수 있습니다.

    //함수가 반환하는 타입(자료형)은 returns 라는 키워드를 통해 명시적으로 드러나야 합니다.

    // 함수 제어자 지정하기
    // 컨트랙트의 변수를 읽고 쓰는지 여부에 따라 제어자를 지정합니다.

    // view : 컨트랙트의 변수를 읽기만 할 때 (상태를 변화시키지 않을때)
    // pure : 컨트랙트의 변수를 읽지도, 쓰지도 않을 때
    // 제어자는 리턴 타입과 접근자 사이에 위치하게 됩니다.
    
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        //require 는 조건이 참이면 함수를 실행하고, 참이 아니면 함수를 실행하지 않고 에러를 출력합니다.
        require(_owner != address(0));
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {

        address addr_owner = tokenOwners[_tokenId];
        require(
            addr_owner != address(0),
            "Token is invalid"
        );
        return addr_owner;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {

        address addr_owner = ownerOf(_tokenId);

        require(
            addr_owner == _from,
            "_from is NOT the owner of the token"
        );

        require(
            _to != address(0),
            "Transfer _to address 0x0"
        );

        address addr_allowed = allowance[_tokenId];
        bool isOp = operators[addr_owner][msg.sender];

        require(
            addr_owner == msg.sender || addr_allowed == msg.sender || isOp,
            "msg.sender does not have transferable token"
        );


        //transfer : change the owner of the token
        tokenOwners[_tokenId] = _to;
        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(1);

        //reset approved address
        if (allowance[_tokenId] != address(0)) {
            delete allowance[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);

    }


    //솔리디티에는 변수를 저장할 수 있는 Storage와 Memory 라는 공간이 존재합니다.
    // Storage는 블록체인 상에 영구적으로 저장되며, Memory는 임시적으로 저장되는 변수로 함수의 외부 호출이 일어날 때마다 초기화됩니다.
    // (비유하자면 Storage는 하드 디스크, Memory는 RAM에 저장되는 것을 의미합니다.)
    // 대부분의 경우에는 솔리디티가 알아서 메모리 영역을 구분해 주는데요, 상태 변수(함수 외부에 선언된 변수)는 storage로 선언되어 블록체인에 영구적으로 저장되는 반면, 함수 내에 선언된 변수는 memory로 선언되어 함수 호출이 종료되면 사라지게 됩니다.

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {

        transferFrom(_from, _to, _tokenId);

        //check if _to is CA
        if (_to.isContract()) {
            bytes4 result = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);

            require(
                result == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),
                "receipt of token is NOT completed"
            );
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }


    function approve(address _approved, uint256 _tokenId) external payable {

        address addr_owner = ownerOf(_tokenId);
        bool isOp = operators[addr_owner][msg.sender];

        require(
            addr_owner == msg.sender || isOp,
            "Not approved by owner"
        );

        allowance[_tokenId] = _approved;

        emit Approval(addr_owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }


    function getApproved(uint256 _tokenId) external view returns (address) {
        return allowance[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }


    //non-ERC721 standard
    //
    //
    function () external payable {}

    function mint(uint8 _x, uint8 _y, uint8 _z) external payable {

        asset memory newAsset = asset(_x, _y, _z);
        uint tokenId = allTokens.push(newAsset) - 1;
        //token id starts from 0, index of assets array
        tokenOwners[tokenId] = msg.sender;
        balances[msg.sender] = balances[msg.sender].add(1);

        //for enumeration
        allValidTokenIndex[tokenId] = allValidTokenIds.length;
        //index starts from 0
        allValidTokenIds.push(tokenId);

        emit Transfer(address(0), msg.sender, tokenId);
    }

    function burn(uint _tokenId) external {

        address addr_owner = ownerOf(_tokenId);

        require(
            addr_owner == msg.sender,
            "msg.sender is NOT the owner of the token"
        );

        //reset approved address
        if (allowance[_tokenId] != address(0)) {
            delete allowance[_tokenId];
            // tokenId => 0
        }

        //transfer : change the owner of the token, but address(0)
        tokenOwners[_tokenId] = address(0);
        balances[msg.sender] = balances[msg.sender].sub(1);

        //for enumeration
        removeInvalidToken(_tokenId);

        emit Transfer(addr_owner, address(0), _tokenId);
    }

    function removeInvalidToken(uint256 tokenIdToRemove) private {

        uint256 lastIndex = allValidTokenIds.length.sub(1);
        uint256 removeIndex = allValidTokenIndex[tokenIdToRemove];

        uint256 lastTokenId = allValidTokenIds[lastIndex];

        //swap
        allValidTokenIds[removeIndex] = lastTokenId;
        allValidTokenIndex[lastTokenId] = removeIndex;

        //delete
        //Arrays have a length member to hold their number of elements.
        //Dynamic arrays can be resized in storage (not in memory) by changing the .length member.
        allValidTokenIds.length = allValidTokenIds.length.sub(1);
        //allValidTokenIndex is private so can't access invalid token by index programmatically
        allValidTokenIndex[tokenIdToRemove] = 0;
    }

    //ERC721Enumerable
    function totalSupply() public view returns (uint) {
        return allValidTokenIds.length;
    }

    //ERC721Enumerable
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return allValidTokenIds[index];
    }

    //ERC721Metadata
    function name() external pure returns (string memory) {
        return "EMOJI TOKEN";
    }

    //ERC721Metadata
    function symbol() external pure returns (string memory) {
        return "EMJ";
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }


    // // function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
    // function projectScriptByIndex(uint256 _projectId) view public returns (uint[3] memory){
    // // function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (asset memory) {
    //     // return projects[_projectId].scripts[_index];

    //     // uint256[] storage delim = allTokens[_projectId];
    //     // string[] storage parts = '';
    //     // for(uint i = 0; i < delim.length; i++) {
    //     //     parts = parts + delim(i).toString();
    //     // }
    //     return allTokens[_projectId];
    // }


    // function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
    //     return projects[_projectId].scripts[_index];
    // }

    //ERC721Metadata
    function projectScriptByIndex() view public returns (string memory){
        return "projectScriptByIndex";
    }

    //ERC721Metadata
    function testHtj() view public returns (string memory){
        return "testHtj";
    }

}

contract ERC721TokenReceiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4);
}