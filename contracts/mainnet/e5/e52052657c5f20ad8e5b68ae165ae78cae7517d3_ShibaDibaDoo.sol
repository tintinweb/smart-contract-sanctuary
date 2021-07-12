// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19 <0.8.5;
import "./Dooery.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract ShibaDibaDoo is Dooery, ERC721 { 

    using SafeMath for uint256;
    event DoosMinted(address owner);
    mapping(uint256 => uint256) private _totalSupply;

    constructor() ERC721("Shiba Diba Doo Hybrids", "SDDH") {
        dooPeople.push(MintMasters(payable(address(0x62CAD076adE9D7Ce4880c2c7362Bf63a7E83de39)), 50));
        dooPeople.push(MintMasters(payable(address(0xd528ceB24Fa1cc6De73BeDd70Ece22Af0226B4dA)), 50));
    }

    modifier canDoo(uint _qty){
        require(msg.value == (dooPrice * _qty));
        _;
    }

    modifier canDooit() {
        require(doos.length < 9999);
        _;
    }

    modifier canSendpayout(){
        require(address(this).balance > 0.01 ether);
        _;
    }

    struct MintMasters {
        address payable addr;
        uint percent;
    }

    MintMasters[] dooPeople;

    uint dooPrice = 0.06 ether;

    function setDooPrice(uint _fee) external onlyOwner {
        dooPrice = _fee;
    }

    function sendpayout() external payable onlyOwner() canSendpayout() {
        uint nbalance = address(this).balance - 0.01 ether;
        for(uint i = 0; i < dooPeople.length; i++){
            MintMasters storage o = dooPeople[i];
            o.addr.transfer((nbalance * o.percent) / 100);       
        }
        
    }


    function balance() external view onlyOwner returns (uint)  {
        return address(this).balance;
    }

    function getDooPrice() external view returns (uint){
        return dooPrice;
    }

    function getDoosIdsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerDooCount[_owner]);
        uint meter = 0;
        for (uint i = 0; i < doos.length; i++) {
            if (dooToOwner[i + 1] == _owner) {
                result[meter] = i;
                meter++;
            }
        }
        return result;
    }

    function getDoosCount() external view returns(uint){
        return doos.length;
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        if(address(0) != _from){
            ownerDooCount[_to] = ownerDooCount[_to].add(1);
        } 
        if(_to != dooToOwner[_tokenId]){
            ownerDooCount[_from] = ownerDooCount[_from].sub(1);
            dooToOwner[_tokenId] = _to;
        }
        
    }
    
    function mintDoo() internal canDooit() {
        Doo memory doo = Doo(doos.length + 1);
        doos.push(doo);
        uint id = doos.length;
        dooToOwner[id] = msg.sender;
        ownerDooCount[msg.sender] = ownerDooCount[msg.sender].add(1);
        _mint(msg.sender, id);
    }

    function buyDoos(uint _qty) external payable canDoo(_qty) {
        require(_qty <= 40, "max 40 Tokens per transaction");
        uint i = 0;
        while(i < _qty){
            mintDoo();
            i++;
        }
        emit DoosMinted(msg.sender);
    }

    function reserveDoos(uint _qty) external onlyOwner {
        require(_qty <= 2, "Max 2 Tokens can be reserved");
        uint i = 0;
        while(i < _qty){
            mintDoo();
            i++;
        }
        emit DoosMinted(msg.sender);
    }

}