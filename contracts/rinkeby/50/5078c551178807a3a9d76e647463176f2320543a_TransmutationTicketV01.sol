pragma solidity >=0.4.22 <0.9.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./IERC721Custom.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./CryptoPunksMarket.sol";
import "./ERC721Burnable.sol";

contract TransmutationTicketV01 is ERC721Burnable, IERC721Custom, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public MAX_SUPPLY = 4000;
    uint256 private _totalSupply = 0;
    address _bichoTown;
    // @todo use this addresss, check
    address _cryptoPunkContractAdress;
    bool _isTransmutationTicketSellOpen = false;
    mapping (uint256 => uint256) pricePerRound;
    mapping (uint256 => uint256) generalTicketPricePerRound;
    mapping (uint256 => uint256) ticketsPerRound;
    mapping (uint256 => uint256) generalTicketsPerRound;
    mapping (uint256 => uint256) timePerRound;
    uint256 SECONDS_IN_A_DAY = 86400;
    uint256 openSaleTimeStamp;

    uint256 currentRound = 0;

    enum TicketType{ TRANSMUTATION, GENERAL }

    // have this as information in the json
    
    //struct 

    mapping(uint256 =>  uint256) public bichosContractTicketMapping; 

    mapping(uint256 =>  uint256) _ticketsSoldPerRound; 
    mapping(uint256 =>  bool) _selectedPunks;
    uint256 blockNumberStart = 0;

    //claimed tickettokens by nftcontract

    constructor() ERC721("Transmutation ticket", "TMTP") {
        //punkContract = punkContract(0);
    }

    //@todo check if there is need of modifier for controlling op
    function buyTransmutationTicket(address player, uint256 originalPunkId) 
        public payable
        returns (uint256)
    {
        require(_totalSupply < MAX_SUPPLY, "Max token created");
        //should we move direclty to the next round??===> no
        // set initial time for every phase
        if(currentRound == 1) {
              //if( block.timestamp > block.timestamp + timePerRound[1]*SECONDS_IN_A_DAY){ //phasetime[2]
              if (block.number > blockNumberStart + 5*timePerRound[1]){
                currentRound = 2;
                generalTicketsPerRound[1] = ticketsPerRound[1];
            }
        } else if(currentRound == 2) {
            //if(block.timestamp > block.timestamp + timePerRound[2]*SECONDS_IN_A_DAY) {
              if (block.number > blockNumberStart + 5*timePerRound[2]){

                currentRound = 3;
                generalTicketsPerRound[2] = ticketsPerRound[2];
            }

        }else if(currentRound == 3) {
            //if( block.timestamp > block.timestamp + timePerRound[3]*SECONDS_IN_A_DAY) {
              if (block.number > blockNumberStart + 5*timePerRound[3]){

                currentRound = 4;
                generalTicketsPerRound[3] = ticketsPerRound[3];

            }
        }else {
            //if(block.timestamp > block.timestamp + timePerRound[4]*SECONDS_IN_A_DAY) {
              if (block.number > blockNumberStart + 5*timePerRound[4]){

                _isTransmutationTicketSellOpen = false;
                generalTicketsPerRound[4] = ticketsPerRound[4];

            }
        }

        require(_isTransmutationTicketSellOpen, "No active sell right now");
        require(checkPunkOwnership(player, originalPunkId) == true, "This address does not own this punk");
        require(_selectedPunks[originalPunkId] == false, "Punk already claimed"); 
        require(msg.value >= pricePerRound[currentRound], "Not enough eth to buy the ticket");
        _tokenIds.increment();
        
        _totalSupply = _totalSupply.add(1);
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        bichosContractTicketMapping[newItemId] = originalPunkId;

        if(newItemId == 4000 || block.number > blockNumberStart + 6400*timePerRound[4]) {
            _isTransmutationTicketSellOpen = false;
        }
        ticketsPerRound[currentRound] = ticketsPerRound[currentRound].sub(1);
        //_ticketsSoldPerRound[currentRound] = _ticketsSoldPerRound[currentRound] + 1;
        //_setTokenURI(newItemId, tokenURI);
        _selectedPunks[originalPunkId] = true;
        return newItemId;
    }

    function buyGeneralTicket(address buyer, uint256 phase) public payable {
        require(_totalSupply < MAX_SUPPLY, "Max token created");
        require(phase > 0 && phase < 5, "Invalid phase ");
        //require(!_isTransmutationTicketSellOpen, "No active general ticket sell right now");
        require(generalTicketsPerRound[phase] > 0, "There are no more ticket for sale");
        require(msg.value >= generalTicketPricePerRound[phase], "Not enough to buy the ticket");
        _tokenIds.increment();
        
        _totalSupply = _totalSupply.add(1);
        generalTicketsPerRound[phase] = generalTicketsPerRound[phase].sub(1);
        uint256 newItemId = _tokenIds.current();
        _mint(buyer, newItemId);
        bichosContractTicketMapping[newItemId] = 11111; //this is a generation ticket

        // _ticketsSoldPerRound[currentRound] = _ticketsSoldPerRound[currentRound] + 1;
        
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        //@todo set our url
        return "https://opensea-creatures-api.herokuapp.com/api/creature/";
    }

    function setBichoTown(address _contractAddress) public onlyOwner {
        _bichoTown = _contractAddress;
    }

    function getCurrentOriginalNFTContract() public view returns (address) {
        return _cryptoPunkContractAdress;
    }

    function _isApprovedOrOwner(address spender, uint256 _tokenId) internal view override returns (bool) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(_tokenId);
        return (spender == owner || getApproved(_tokenId) == spender || ERC721.isApprovedForAll(owner, spender) || spender == _bichoTown);
    }

    function burn(uint256 _ticketId) public override{
        require(_isApprovedOrOwner(msg.sender, _ticketId), "NOt owner, approved or bichoTown contract");
        _burn(_ticketId);
    }

    function openTicketSale() public onlyOwner {
        require(!_isTransmutationTicketSellOpen, "Ticket sale is already open, cant be opened again in this round");
        _isTransmutationTicketSellOpen = true;
        // round 1
        pricePerRound[1] = 0.02 ether;
        ticketsPerRound[1] = 100;
        generalTicketPricePerRound[1] = 0.01 ether;
        //round 2
        pricePerRound[2] = 0.03 ether;
        ticketsPerRound[2] = 400;
        generalTicketPricePerRound[2] = 0.015 ether;
        //round 3
        pricePerRound[3] = 0.04 ether;
        ticketsPerRound[3] = 1000;
        generalTicketPricePerRound[3] = 0.02 ether;
        //round 4
        pricePerRound[4] = 0.05 ether;
        ticketsPerRound[4] = 2500;
        generalTicketPricePerRound[4] = 0.025 ether;
        timePerRound[1] = 15;
        timePerRound[2] = 30;
        timePerRound[3] = 60;
        timePerRound[4] = 90;

        openSaleTimeStamp = block.timestamp;
        blockNumberStart = block.number;
        currentRound = 1;

       // _setCurrentNftContractPair(originalNFTContract, _nftBichoContractAddres);
    }

    /*function ticketOf(uint256 _id) public view returns(address) {
        //return ticket;
        return ownerOf(_id);
    }*/
    address cp;
    function checkPunkOwnership(address owner, uint256 punkId) internal view returns (bool) {
        address punkOwner = CryptoPunksMarket(cp).punkIndexToAddress(punkId);

        return punkOwner == owner;
    }

    function getRound() public view returns (uint256) {
        return currentRound;
    }

    function closeTransmutationSells() public onlyOwner { 
        _isTransmutationTicketSellOpen = false;
        currentRound = 4;
    }

    function ticketsLeft(uint256 phase) public view returns (uint256) {
        return ticketsPerRound[phase];
    }
    function genralTicketsLeft(uint256 phase) public view returns (uint256) {
        return generalTicketsPerRound[phase];
    }
    // 0xcc495748df37dcfb0c1041a6fdfa257d350afd60 rinkeby
    function setPunkA(address punk) public onlyOwner {
        cp = punk;
    }
}