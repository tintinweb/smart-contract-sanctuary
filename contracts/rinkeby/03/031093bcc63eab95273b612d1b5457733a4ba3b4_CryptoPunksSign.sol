// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./ICryptoPunks.sol";

contract CryptoPunksSign is ERC721URIStorage {
    
    using SafeMath for uint256;
    
    uint256 private _tokenIds;
    uint256 private _totalSupply;
    address private _manager;
    address payable _cryptoPunksDao;
    address private _cryptoPunksContract;
    // A record of punks - sign
    mapping (uint256 => uint256) private punkSignBind;
    struct User {
        string name;
        uint256 ID_Index;
        string ID_DID;
    }
    
     // A record of the signpunks - twitter
    mapping (uint256 => string) private punksTwitter;
    // A record of the signpunks - twitter
    mapping (uint256 => string) private punksNote;
     // A record of the signpunks - user
    mapping (uint256 => User) private punksUserBind;
    //record
    uint256 private _punksRecord;
    
    // A record of punks - hat
    mapping (uint256 => uint256) private punksHat;
    

    modifier onlyOwner() {
        require(msg.sender == _manager);
        _;
    }
    
    function updateManager(address manager) public onlyOwner {
        _manager = manager;
    }
    
    function setCryptoPunksDao(address payable punksDao)public onlyOwner {
        _cryptoPunksDao = punksDao;
    }
    
    function setCryptoPunksContract(address cryptoPunksAddress)public onlyOwner {
        require(isContract(cryptoPunksAddress),"setCryptoPunksContract: address error .");
        _cryptoPunksContract = cryptoPunksAddress;
    }
    
    function getMintPrice() public view returns(uint256){
        uint256 state =  SafeMath.div(_tokenIds,10);
        return mulDiv(state,1e18,100);
    } 
    
    function getUpdateSignPrice() public pure returns(uint256){
        return mulDiv(1,1e18,100);
    }
    
    constructor() ERC721("CryptoPunksSign", "PunksSign") {
        _manager = msg.sender;
        _punksRecord = 0;
    }

    function mintCryptoPunksSign(uint256 hat,string memory tokenURI,string memory twitter, string memory notes)
        payable
        public
        returns (uint256)
    {
        require(_cryptoPunksDao != address(0x0),"mintCryptoPunksSign: address error !");
        require(_totalSupply < 10000,"mintCryptoPunksSign: Total 10000 !");
        if(_tokenIds > 10){
            uint256 fees = getMintPrice();
            require(fees <= msg.value,"mintCryptoPunksSign: msg.value error !");
            _cryptoPunksDao.transfer(fees);
        }
        _tokenIds++;
        _totalSupply++;
        uint256 newItemId = _tokenIds;
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        punksTwitter[newItemId] = twitter;
        punksNote[newItemId] = notes;
        punksHat[newItemId] = hat;
        return newItemId;
    }
    
    function cryptoPunksClaim(uint256 hat,uint256 index,string memory tokenURI,string memory twitter,string memory notes)
        public
        returns (uint256)
    {
        require(_cryptoPunksDao != address(0x0),"cryptoPunksClaim: address error !");
        require(_totalSupply < 10000,"cryptoPunksClaim: Total 10000 !");
        CryptoPunksMarket cryptoPunks =  CryptoPunksMarket(_cryptoPunksContract);
        address cryptoPunksUser = cryptoPunks.punkIndexToAddress(index);
        require(cryptoPunksUser == msg.sender,"cryptoPunksClaim: no punks .");
        require(punkSignBind[index] == 0,"cryptoPunksClaim: exist claim .");
        _tokenIds++;
        _totalSupply++;
        uint256 newItemId = _tokenIds;
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        punkSignBind[index] = newItemId;
        punksTwitter[newItemId] = twitter;
        punksNote[newItemId] = notes;
        _punksRecord++;
        punksHat[newItemId] = hat;
        return newItemId;
    }

    function updatePunksSign(uint256 index,string memory tokenURI)
        payable
        public
        returns(bool)
    {
        require(index <= _tokenIds, "updatePunksSign: no index .");
        require(ownerOf(index) == msg.sender,"updatePunksSign: no permission .");
        require(getUpdateSignPrice() <= msg.value,"updatePunksSign: msg.value error !");
        _cryptoPunksDao.transfer(getUpdateSignPrice());
        _setTokenURI(index, tokenURI);
        return true;
    }


    function updatePunksTwitter(uint256 index,string memory twitter)
        public
        returns(bool)
    {
        require(index <= _tokenIds, "updatePunksTwitter: no index .");
        require(ownerOf(index) == msg.sender,"updatePunksTwitter: no permission .");
        punksTwitter[index] = twitter;
        return true;
    }

    function updatePunksNote(uint256 index,string memory notes)
        public
        returns(bool)
    {
        require(index <= _tokenIds, "updatePunksNote: no index .");
        require(ownerOf(index) == msg.sender,"updatePunksNote: no permission .");
        punksNote[index] = notes;
        return true;
    }

    function getpunksHat(uint256 index)public view returns(uint256){
        return punksHat[index];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function getpunksInfo(uint256 signPunks)public view returns(string memory meta,string memory twitter,string memory notes){
        require(signPunks <= _tokenIds, "getpunksInfo: no index .");
        return (tokenURI(signPunks),punksTwitter[signPunks],punksNote[signPunks]);
    }
    
    function getpunks()public view returns(uint256){
        
        return _punksRecord;
    }

    function getActiveState(uint256 signPunks) public view returns(bool){
        if(signPunks > _tokenIds){
            return false;
        }
        if(ownerOf(signPunks) != msg.sender){
            return false;
        }
        User storage _user = punksUserBind[signPunks];
        if(_user.ID_Index > 0){
            return true;
        }
        return false;
    }
    
    function activateUser(uint256 signPunks,string memory name,uint256 id_index,string memory id_did) payable public {
        require(signPunks <= _tokenIds, "activateUser: no signPunks .");
        require(ownerOf(signPunks) == msg.sender,"activateUser: no permission .");
        require(getUpdateSignPrice() <= msg.value,"activateUser: msg.value error !");
        _cryptoPunksDao.transfer(getUpdateSignPrice());
        
         User storage _user = punksUserBind[signPunks];
        _user.name = name;
        _user.ID_Index = id_index;
        _user.ID_DID = id_did;
        punksUserBind[signPunks] = _user;
    }
    
    function getUserInfo(uint256 signPunks)public view returns(uint256 state,uint256 id_index,string memory name,string memory id_did){
        if(getActiveState(signPunks)){
            User storage _user = punksUserBind[signPunks];
            return(10,_user.ID_Index,_user.name,_user.ID_DID);
        }
        return(0,0,"","");
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }
    
}