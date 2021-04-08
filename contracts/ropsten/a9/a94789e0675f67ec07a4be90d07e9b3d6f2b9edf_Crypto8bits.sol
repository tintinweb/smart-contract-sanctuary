/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.6.4;

// pragma experimental ABIEncoderV2;

contract Crypto8bits {
    
    uint256 public totalSupply = 10000; 
    string private name; 
    string private symbol; 
    uint256[] private listComputer; 
    bool public allComputersAssigned = false; 
    uint public computersRemainingToAssign = 0; 
 
    enum ComputerState { IN_SALE, OWNED } 

    struct Computer {
        uint256 id;
        address payable owner; 
        string image; 
        string name; 
        uint256 performance; 
        uint256 price; 
        ComputerState state; 
    }
    
    struct Offer {
        bool isForSale;
        uint computerIndex;
        address seller;
        uint minValue;          
        address onlySellTo;     
    }
    struct Bid {
        bool hasBid;
        uint computerIndex;
        address payable bidder;
        uint value;
    }
    
    mapping(uint256 => Computer) public computers; 
    mapping(uint => bool) _idComputerExists; 
    mapping(string => bool) _nomComputerExists;
    mapping(string => bool) _imageComputerExists;
    mapping(address => bool) admins;

    mapping (uint => address) public computerIndexToAddress;
    mapping (uint => Offer) public computersOfferedForSale;
    mapping (uint => Bid) public computersBids; 
    mapping (address => uint) public pendingWithdrawals;
    mapping (address => uint256) public balanceOf;
 
    event Vente(uint256 id, address ancienProprio, address newOwner);
    event MiseEnVente(uint256 id, uint256 price, uint256 date);
    event RetraitDeVente(uint256 id, uint256 date);

    event Assign(address indexed to, uint256 computerIndex); 
    event ComputerTransfer(address indexed from, address indexed to, uint256 computerIndex);
    event ComputerOffered(uint indexed compIndex, uint minValue, address indexed toAddress);
    event ComputerBidEntered(uint indexed compIndex, uint value, address indexed fromAddress);
    event ComputerBought (uint indexed computerIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 date);
    event ComputerBidWithdrawn(uint indexed computerIndex, uint value, address indexed fromAddress);

    constructor () public {
        name = "Crypto8bits";
        symbol = "C8b";

        admins[msg.sender] = true;
        computersRemainingToAssign = totalSupply;
    }
   
    modifier isAdmin() {
        require(admins[msg.sender], "Must be a admin");
        _;
    }
    modifier isOwner(uint256 _id) {
        require(computers[_id].owner == msg.sender, "You must be the owner");
        _;
    }
    modifier isMintable() {
        require(listComputer.length < totalSupply, "Computer limit reached");
        _;
    }


    // Stoker les [index => id] dans un tableau afin de les quantifier
    function computerIndex(uint256 _index) external view returns (uint256 id, address payable owner, string memory image, string memory _name, uint256 performance, uint256 price, ComputerState) {
        require(_index < listComputer.length, "Index out of bound");
        Computer memory  c  = computers[listComputer[_index]];
        return (c.id, c.owner, c.image, c.name, c.performance, c.price, c.state);
    }
    // // Stoker les [index => id] dans un tableau afin de les quantifier
    // function computerIndex(uint256 _index) external view returns (Computer memory) {
    //     require(_index < listComputer.length, "Index out of bound");
    //     return computers[listComputer[_index]];
        
    // }

    function getContractBalance() public view returns(uint256 _balance) {
        return address(this).balance;
    }


    function addAdmin(address _agent) isAdmin external {
        require(_agent != address(0x0), "The address must be different then 0x0");
        admins[_agent] = true;
    }

    function removeAdmin(address _agent) isAdmin external {
        admins[_agent] = false;
    }

    
    function buyComputer(uint256 _id)
        external
        payable
    {
        Computer memory computer = computers[_id];

        require(msg.value > 0, "The amount should be différent then 0"); 
        require(computer.state == ComputerState.IN_SALE, "The computer must be in sell"); 
        require(msg.value == computer.price, "The amout not correspond to the computer price"); 

        computer.owner.transfer(msg.value);
        Offer memory offer = computersOfferedForSale[_id];
        address seller = offer.seller;
        computerIndexToAddress[_id] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        computersRemainingToAssign--;
        
        changeOwner(_id, msg.sender);
        
        emit Vente(_id, computer.owner, msg.sender);
        emit Transfer(seller, msg.sender, msg.value, now);
        emit Assign(msg.sender, _id);
    }

    function addComputer(
        address payable _owner,
        uint256 _id,
        string calldata _image,
        string calldata _nom,
        uint256 _performance
    ) external isAdmin isMintable {
        require(_id > 0, "No 0 value for computer id");       
        require(!_idComputerExists[_id], "This id is already used"); 
        require(!_nomComputerExists[_nom], "This name is already used");
        require(!_imageComputerExists[_image], "This image hash is already used");
  
        computers[_id] = Computer( _id, _owner, _image, _nom, _performance, 0, ComputerState.OWNED);
        listComputer.push(_id);
        _idComputerExists[_id] = true;
        _nomComputerExists[_nom] = true;
        _imageComputerExists[_image] = true;
        computerIndexToAddress[_id] = _owner; 
        balanceOf[_owner]++;

        emit Assign(msg.sender, _id);
    }
   
    function changeOwner(uint256 _id, address payable _newOwner) private {
        require(computers[_id].owner != address(0x0), "This computer not exist");
        
        computers[_id].owner = _newOwner;
        computers[_id].state = ComputerState.OWNED;

        
        computerIndexToAddress[_id] = _newOwner;
        balanceOf[msg.sender]--;
        balanceOf[_newOwner]++;
        
        
        Bid memory bid = computersBids[_id];
        if (bid.bidder == _newOwner) {
            
            pendingWithdrawals[_newOwner] += bid.value;
            computersBids[_id] = Bid(false, _id, address(0x0), 0);
        }

        emit ComputerTransfer(msg.sender, _newOwner, _id);
    } 

    function setComputerInSell(uint256 _id, uint256 _prix) external isOwner(_id) {
        
        require(_prix > 0, "The sell price must be more then 0");
        require(computerIndexToAddress[_id] == msg.sender); 
        require (_id < 10000, "All computers is already assigned");

        computers[_id].price = _prix;
        computers[_id].state = ComputerState.IN_SALE;
        computersOfferedForSale[_id] = Offer(true, _id, msg.sender, _prix, address(0x0));

        emit MiseEnVente(_id, _prix, now);
        emit ComputerOffered(_id, _prix, address(0x0));
    }
    function removeComputerInSell(uint256 _id) external isOwner(_id) {
        computers[_id].state = ComputerState.OWNED;
        emit RetraitDeVente(_id, now);
    }

    function isComputerInSell(uint256 _id) public view returns(bool) {
        return computers[_id].state == ComputerState.IN_SALE;
    }


    function totalComputers() external view returns (uint256) {
        return listComputer.length;
    }


    function enterBidForComputer(uint compIndex) public payable {
        
        require (!(compIndex >= 10000));
        require(!(computerIndexToAddress[compIndex] == address(0x0)), "The address must be different then 0x0");
        require(!(computerIndexToAddress[compIndex] == msg.sender), "You can not make an offer on your own computer");
        require(!(msg.value == 0), "The offer amount must be more than 0");
        Bid memory existing = computersBids[compIndex];
        require(!(msg.value <= existing.value), "The offer amount must be more than the previous offer");
        
        if (existing.value > 0) {
            existing.bidder.transfer(existing.value); 
            emit Transfer(address(this), existing.bidder, existing.value, now);
            
            pendingWithdrawals[existing.bidder] += existing.value;

        }
        computersBids[compIndex] = Bid(true, compIndex, msg.sender, msg.value);

        emit ComputerBidEntered(compIndex, msg.value, msg.sender);
    }

    
    function acceptBidForComputer(uint compIndex, uint minPrice) public payable{
        
        require(compIndex < 10000, "Index out of bound");
        require(computerIndexToAddress[compIndex] == msg.sender, "You can not make an offer on your own computer");
        address seller = msg.sender;
        Bid memory bid = computersBids[compIndex];
        require(bid.value > 0, "No valid offer available"); 
        require(bid.value >= minPrice, "No offer available in the limit chosen");

        computerIndexToAddress[compIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        emit Transfer(seller, bid.bidder, msg.value, now);

        computersOfferedForSale[compIndex] = Offer(false, compIndex, bid.bidder, minPrice, address(0x0));
        uint amount = bid.value;
        computersBids[compIndex] = Bid(false, compIndex, address(0x0), 0);
        pendingWithdrawals[seller] += amount;
        emit ComputerBought(compIndex, bid.value, seller, bid.bidder);


        payable(seller).transfer(amount); 

        
        changeOwner(compIndex, bid.bidder);
    }
    
}