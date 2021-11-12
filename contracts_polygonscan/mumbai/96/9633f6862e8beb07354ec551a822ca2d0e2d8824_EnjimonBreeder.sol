pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract EnjimonBreeder is IERC721 {

    address owner;

    string public constant _name = "AncientEnimon";
    string public constant _symbol = "AEU";
    
    uint256 CREATION_LIMIT_GEN0 = 27;
    uint256 newEnjimonId = 0;
    uint256 gen0EnjimonCounter;

    modifier onlyOwner{
        require(msg.sender == owner, "ASA, Only owner can execute this function");
        _;
    }

    bytes4 internal constant SPECIFIC_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256, bytes)"));


    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    event Birth(address owner, uint256 enjimonId, uint256 momId, uint256 popsId, uint256 genes);

    struct AncientEnjimon{
        uint256 genes;
        uint64 birthTime;
        uint32 momId;
        uint32 popsId;
        string sex;
        uint16 generation; 
        
    }
    
    AncientEnjimon[] enjimon;

    mapping(uint => address)public enjimonIndexToOwner; //who owns this tokenId
    mapping(address => uint)enjimonTokenCount; //amount of tokens this address owns
    mapping(uint256 => AncientEnjimon) private _tokenDetails;
    mapping(uint256 => address) public enjimonIdToApprove; //approval for one token

    function breed(uint256 _popsId, uint256 _momId) public  returns(uint256 ) {
        require(_owns(msg.sender, _popsId),"Trainer does not own $Enjimon!");
        require(_owns(msg.sender, _momId),"Trainer does not own $Enjimon!");

        ( uint256 popsDna,,,,,uint256 PopsGeneration ) = getEnjimon(_popsId);
        (uint256 momDna,,,,,uint256 MomGeneration ) = getEnjimon(_momId);
        
       
        uint256 newDna = _mixDna(popsDna, momDna);
        string memory XXY;

        uint256 kidGen = 0;
        if(PopsGeneration < MomGeneration){
            kidGen = MomGeneration + 1;
            kidGen /= 2;
            XXY = "Female";
        } else if (PopsGeneration > MomGeneration){
            kidGen = PopsGeneration + 1;
            kidGen /= 2;
            XXY = "Male";
        } else {
            kidGen = MomGeneration + 1;
            XXY = "Female";
        }

        _createEnjimon(newDna, _momId,_popsId, XXY, kidGen, msg.sender );
    }
    
    //it takes MYADDR(or someother owner) => OPERATORSADDRESS (contract to give permission to) => mapps back to TRUE/False
    mapping(address => mapping(address => bool)) private _operatorAprovals;
    
    // _operatorApprovals[MYADDRESS][OPERATORSADDRESS] will return true or false and we set it to true or false with = 

    constructor(){

        owner = msg.sender;

    }
    
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool){
        return (_interfaceId == _INTERFACE_ID_ERC721 || _interfaceId == _INTERFACE_ID_ERC165);
    }

    function createGen0Enjimon(uint256 _genes, string memory _sex) public onlyOwner returns(uint256){
        require(gen0EnjimonCounter < CREATION_LIMIT_GEN0);

        gen0EnjimonCounter++;

        return _createEnjimon(_genes, 0, 0, _sex, 0, msg.sender);
    }

    function _createEnjimon(
        uint256 _genes,
        uint256 _momId,
        uint256 _popsId,
        string memory _sex,
        uint256 _generation,
        address _owner
    ) private returns(uint256){
        AncientEnjimon memory _enjimon = AncientEnjimon({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            momId: uint32(_momId),
            popsId: uint32(_popsId),
            sex: _sex,
            generation: uint16(_generation)
        });
        
         enjimon.push(_enjimon);
        _transfer(address(0), _owner, newEnjimonId); //Enjimon birth cause it comes from no where i.e. 0x0
        emit Birth(_owner, newEnjimonId,  _momId, _popsId, _genes);
        newEnjimonId++;
        
        return (newEnjimonId - 1);
        
    }

    function enjimonDetails(uint256 _tokenId) external view returns(
        uint256 genes, 
        uint64 birthTime,
        uint256 momId, 
        uint256 popsId, 
        string memory sex, 
        uint16 generation, 
        address _owner){
        
        AncientEnjimon storage _enjimon = enjimon[_tokenId];

        genes = uint256(_enjimon.genes);
        birthTime = uint64(_enjimon.birthTime);
        momId = uint64(_enjimon.momId);
        popsId = uint64(_enjimon.popsId);
        sex = string(_enjimon.sex);
        generation = uint16(_enjimon.generation);
        _owner = address( enjimonIndexToOwner[_tokenId]);
    }

    function balanceOf(address _owner) external view override returns (uint256 balance){
        return enjimonTokenCount[_owner];
    }

    function totalSupply() public view override returns (uint256){
       
        return enjimon.length;
    }

    function name() external pure override returns (string memory tokenName){   
        return _name;
    }
    function symbol() external pure override returns (string memory tokenSymbol){
        return _symbol;
    } 
    
    function ownerOf(uint256 tokenId) external view override returns (address){
        
        return enjimonIndexToOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external override{
        require(to != address(0));
        require(to != address(this));
        require(_owns(msg.sender, tokenId), "must be the owner");
        
       
        _transfer(msg.sender, to, tokenId);
    
       
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {

        //as long as from address is not 0x0 decrease token count
        if(_from != address(0)){
            enjimonTokenCount[_from]--;
            delete enjimonIdToApprove[_tokenId]; //when from is not zero address (not being minted) 
            //we have to remove the approval from that id
        }

        enjimonTokenCount[_to]++; //increase token count of reciever
         
        enjimonIndexToOwner[_tokenId] = _to; //set ownership to the reciever

        emit Transfer(_from, _to, _tokenId);

    }
    //safeTransfer with data
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override{
        require(msg.sender == _from || _approvedFor(msg.sender, _tokenId) || isApprovedForAll(_from, msg.sender));
        require(_owns(_from, _tokenId)); //from address owns token
        require(_to != address(0));
        require(_tokenId < enjimon.length, "ASA, not a valid token id"); //token exisit

        _safeTransfer(_from, _to, _tokenId, _data);
    }

    //safeTransfer without data - [same function just pass empty string] 
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override{
        require(msg.sender == _from || _approvedFor(msg.sender, _tokenId) || isApprovedForAll(_from, msg.sender));
        require(_owns(_from, _tokenId)); //from address owns token
        require(_to != address(0));
        require(_tokenId < enjimon.length, "ASA, not a valid token id"); //token exisit

        _safeTransfer(_from, _to, _tokenId, '');
    }
    
    //_data is an optional parameter just incase we would like to send data to receipent
    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal{
            _transfer(_from, _to, _tokenId);
            require( _checkERC721Support(_from, _to, _tokenId, _data) );
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        //1 either msg.sender IS the _from  2. OR msg.sender IS APRROVED for _tokenId  3. OR msg.sender has approval for all tokens 
        require(msg.sender == _from || _approvedFor(msg.sender, _tokenId) || isApprovedForAll(_from, msg.sender));
        require(_owns(_from, _tokenId)); //from address owns token
        require(_to != address(0));
        require(_tokenId < enjimon.length, "ASA, not a valid token id"); //token exisit

        _transfer(_from, _to, _tokenId);
    }
 

   function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return enjimonIndexToOwner[_tokenId] == _claimant;
   }


   function approve(address _approved, uint256 _tokenId) external override{
       require(_owns(msg.sender, _tokenId), "ASA, Only owner of Enjimon or approved operators can set approval.");
       
       _approve(_approved, _tokenId);
        emit Approval(msg.sender, _approved, _tokenId);
   }

   function _approve(address _approved, uint256 _tokenId) internal {
       enjimonIdToApprove[_tokenId] = _approved; 
   }

   function getApproved(uint256 _tokenId) public view override returns (address){
           require(_tokenId < enjimon.length, "ASA, This Token does not exist"); //token must exist

           return enjimonIdToApprove[_tokenId];
   }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender);

        _setApprovalForAll(_operator, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);     
    }

    function _setApprovalForAll(address _operator, bool _approved) internal {
        _operatorAprovals[msg.sender][_operator] = _approved;    
     }


    
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
            return _operatorAprovals[_owner][_operator];
      }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return enjimonIdToApprove[_tokenId] == _claimant;
    }  

    function getEnjimon(uint256 _id) public view returns(
        uint256 genes,
        uint256 birthTime,
        uint256 momId,
        uint256 popsId,
        string  memory sex,
        uint256 generation
    ){
        AncientEnjimon storage _enjimon = enjimon[_id];

        birthTime = uint256(_enjimon.birthTime);
        momId = uint256(_enjimon.momId);
        popsId = uint256(_enjimon.popsId);
        sex = string(_enjimon.sex);
        generation = uint256(_enjimon.generation);
        genes = uint256(_enjimon.genes);
    }

   function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns(bool){
       
       if( !_isContract(_to) ) {
           return true;
       }

        //call onERC721Received in the _to contract
       bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
       //check return value
       return returnData == SPECIFIC_ERC721_RECEIVED;
  
   }

   
//We need to check if codeSize > 0 if its a smart contract
// if codeSize = 0 its a wallet, if codesize > 0 its a contract
function _isContract(address _to) view internal returns(bool){
//we use a specific function in solidity to check the code size of a smart contract.

uint32 size;

//assembly line - get the codesize of _to
assembly{
    size := extcodesize(_to)
}

//if size returns larger than zero its true mean its a contract
return size > 0;
//if its not a contract it will return false -- if it returns false then we can freely transfer the tokens see control flow

}

function _mixDna(uint256 _popsDna, uint256 _momDna) internal pure returns (uint256){
   

            uint256 XY = _popsDna / 1000000000000; //male half of DNA strand

            uint256 XX = _momDna % 1000000000000; //female half of DNA strand

            uint256 newDna = XY * 1000000000000; //the 12 zeros

            newDna+= XX; //combine to get final dna string

            return newDna;
}


}