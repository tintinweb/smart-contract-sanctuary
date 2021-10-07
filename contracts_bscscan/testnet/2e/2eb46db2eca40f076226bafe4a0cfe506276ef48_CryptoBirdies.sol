pragma solidity ^0.5.12;

import "./Ownable.sol";
import "./Destroyable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";

contract CryptoBirdies is Ownable, Destroyable, IERC165, IERC721 {

    using SafeMath for uint256;

    uint256 public constant maxGen0Birds = 10;//allow a maximum of 10 Gen0 birds
    uint256 public gen0Counter = 0;

    bytes4 internal constant _ERC721Checksum = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    //checksum used to determine if a receiving contract is able to handle ERC721 tokens
    bytes4 private constant _InterfaceIdERC721 = 0x80ac58cd;
    //checksum of function headers that are required in standard interface
    bytes4 private constant _InterfaceIdERC165 = 0x01ffc9a7;
    //checksum of function headers that are required in standard interface

    string private _name;
    string private _symbol;

    struct Bird {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    Bird[] birdies;

    mapping(uint256 => address) public birdOwner;
    mapping(address => uint256) ownsNumberOfTokens;
    mapping(uint256 => address) public approvalOneBird;//which bird is approved to be transfered
                                                       //by an address other than the owner
    mapping(address => mapping (address => bool)) private _operatorApprovals;
    //approval to handle all tokens of an address by another
    //_operatorApprovals[owneraddress][operatoraddress] = true/false;

    //ERC721 events are not defined here as they are inherited from IERC721
    event Birth(address owner, uint256 birdId, uint256 mumId, uint256 dadId, uint256 genes);

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _createBird(0, 0, 0, uint256(-1), address(0));
        //Bird 0 doesn't do anything, but it exists in the mappings and arrays to avoid issues in the market place
    }

    function getContractOwner() external view returns (address contractowner) {
        return _owner;
    }

    function breed(uint256 _dadId, uint256 _mumId) external returns (uint256){
        require(birdOwner[_dadId] == msg.sender && birdOwner[_mumId] == msg.sender, 
        "You can't breed what you don't own");
        
        (uint256 _dadDna,,,, uint256 _dadGeneration) = getBird(_dadId);//discarding redundant data here
        (uint256 _mumDna,,,, uint256 _mumGeneration) = getBird(_mumId);//discarding redundant data here
        uint256 _newDna = _mixDna(
            _dadDna, 
            _mumDna,
            uint8(now % 255),//This will return a number 0-255. e.g. 10111000
            uint8(now % 1),//seventeenth digit
            uint8(now % 7),//number to select random pair.
            uint8((now % 89) + 10)//value of random pair, making sure there's no leading '0'.
            );
        uint256 _newGeneration;

        if (_dadGeneration <= _mumGeneration) {
            _newGeneration = _dadGeneration;
        } else {
            _newGeneration = _mumGeneration;
        }
        _newGeneration = SafeMath.add(_newGeneration, 1);
        return _createBird(_mumId, _dadId, _newGeneration, _newDna, msg.sender);
    }

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return (_interfaceId == _InterfaceIdERC721 || _interfaceId == _InterfaceIdERC165);
    }

    function createBirdGen0(uint256 genes) public onlyOwner returns (uint256) {
        require(gen0Counter < maxGen0Birds, "Maximum number of Birds is reached. No new birds allowed!");
        gen0Counter = SafeMath.add(gen0Counter, 1);
        return _createBird(0, 0, 0, genes, msg.sender);
    }

    function _createBird(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        Bird memory _bird = Bird({
            genes: _genes,
            birthTime: uint64(now),
            mumId: uint32(_mumId),  //easier to input 256 and later convert to 32.
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        birdies.push(_bird);
        uint256 newBirdId = SafeMath.sub(birdies.length, 1);//want to start with zero.
        _transfer(address(0), _owner, newBirdId);//transfer from nowhere. Creation event.
        emit Birth(_owner, newBirdId, _mumId, _dadId, _genes);
        return newBirdId;
    }

    function getBird(uint256 tokenId) public view returns (
        uint256 genes,
        uint256 birthTime,
        uint256 mumId,
        uint256 dadId,
        uint256 generation) //code looks cleaner when the params appear here vs. in the return statement.
        {
            require(tokenId < birdies.length, "Token ID doesn't exist.");
            Bird storage bird = birdies[tokenId];//saves space over using memory, which would make a copy
            
            genes = bird.genes;
            birthTime = uint256(bird.birthTime);
            mumId = uint256(bird.mumId);
            dadId = uint256(bird.dadId);
            generation = uint256(bird.generation);
    }

    function getAllBirdsOfOwner(address owner) external view returns(uint256[] memory) {
        uint256[] memory allBirdsOfOwner = new uint[](ownsNumberOfTokens[owner]);
        uint256 j = 0;
        for (uint256 i = 0; i < birdies.length; i++) {
            if (birdOwner[i] == owner) {
                allBirdsOfOwner[j] = i;
                j = SafeMath.add(j, 1);
            }
        }
        return allBirdsOfOwner;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return ownsNumberOfTokens[owner];
    }

    function totalSupply() external view returns (uint256 total) {
        return birdies.length;
    }

    function name() external view returns (string memory tokenName){
        return _name;
    }

    function symbol() external view returns (string memory tokenSymbol){
        return _symbol;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId < birdies.length, "Token ID doesn't exist.");
        return birdOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external {
        require(to != address(0), "Use the burn function to burn tokens!");
        require(to != address(this), "Wrong address, try again!");
        require(birdOwner[tokenId] == msg.sender);
        _transfer(msg.sender, to, tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(this));
        ownsNumberOfTokens[_to] = SafeMath.add(ownsNumberOfTokens[_to], 1);
        birdOwner[_tokenId] = _to;
        
        if (_from != address(0)) {
            ownsNumberOfTokens[_from] = SafeMath.sub(ownsNumberOfTokens[_from], 1);
            delete approvalOneBird[_tokenId];//when owner changes, approval must be removed.
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(birdOwner[_tokenId] == msg.sender || _operatorApprovals[birdOwner[_tokenId]][msg.sender] == true, 
        "You are not authorized to access this function.");
        approvalOneBird[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId < birdies.length, "Token doesn't exist");
        return approvalOneBird[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        require(_checkERC721Support(_from, _to, _tokenId, _data));
        _transfer(_from, _to, _tokenId);
    }
    
    function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data) 
            internal returns(bool) {
        if(!_isContract(_to)) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        //Call onERC721Received in the _to contract
        return returnData == _ERC721Checksum;
        //Check return value
    }

    function _isContract(address _to) internal view returns (bool) {
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
        //check if code size > 0; wallets have 0 size.
    }

    function _isOwnerOrApproved(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        require(_from == msg.sender || 
                approvalOneBird[_tokenId] == msg.sender || 
                _operatorApprovals[_from][msg.sender], 
                "You are not authorized to use this function");
        require(birdOwner[_tokenId] == _from, "Owner incorrect");
        require(_to != address(0), "Error: Operation would delete this token permanently");
        require(_tokenId < birdies.length, "Token doesn't exist");
        return true;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _isOwnerOrApproved(_from, _to, _tokenId);
        _transfer(_from, _to, _tokenId);
    }

    function _mixDna(
        uint256 _dadDna, 
        uint256 _mumDna,
        uint8 random,
        uint8 randomSeventeenthDigit,
        uint8 randomPair,
        uint8 randomNumberForRandomPair
        ) internal pure returns (uint256){
        
        uint256[9] memory geneArray;
        uint256 i;
        uint256 counter = 7; // start on the right end

        //DNA example: 11 22 33 44 55 66 77 88 9

        if(randomSeventeenthDigit == 0){
            geneArray[8] = uint8(_mumDna % 10); //this takes the 17th gene from mum.
        } else {
            geneArray[8] = uint8(_dadDna % 10); //this takes the 17th gene from dad.
        }

        _mumDna = SafeMath.div(_mumDna, 10); // division by 10 removes the last digit
        _dadDna = SafeMath.div(_dadDna, 10); // division by 10 removes the last digit

        for (i = 1; i <= 128; i=i*2) {                      //1, 2 , 4, 8, 16, 32, 64 ,128
            if(random & i == 0){                            //00000001
                geneArray[counter] = uint8(_mumDna % 100);  //00000010 etc.
            } else {                                        //11001011 &
                geneArray[counter] = uint8(_dadDna % 100);  //00000001 will go through random number bitwise
            }                                               //if(1) - dad gene
            _mumDna = SafeMath.div(_mumDna, 100);           //if(0) - mum gene
            _dadDna = SafeMath.div(_dadDna, 100);           //division by 100 removes last two digits from genes
            if(counter > 0) {
                counter = SafeMath.sub(counter, 1);
            }
        }

        geneArray[randomPair] = randomNumberForRandomPair; //extra randomness for random pair.

        uint256 newGene = 0;

        //geneArray example: [11, 22, 33, 44, 55, 66, 77, 88, 9]

        for (i = 0; i < 8; i++) {                           //8 is number of pairs in array
            newGene = SafeMath.mul(newGene, 100);           //adds two digits to newGene; no digits the first time
            newGene = SafeMath.add(newGene, geneArray[i]);  //adds a pair of genes
        }
        newGene = SafeMath.mul(newGene, 10);                //add seventeenth digit
        newGene = SafeMath.add(newGene, geneArray[8]);
        return newGene;
    }
}