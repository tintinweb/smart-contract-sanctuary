/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.6.2;
/**
*@title Invoices_ERC721
*@author Pedro Machado
*@company ReservaFS
*@dev DAPP based on NFTs ERC721
*/

contract Invoices_ERC721 {
	address payable public ownerSC;
    uint private id;
    uint[] public idS;
    struct Invoice {
        address payable owner;
        string descripction;
        uint id;
        uint price;
        uint expiditionDate;
        uint expirationDate;
        uint bidDate;
    }

    mapping (uint => Invoice) public invoice;
    mapping (address => uint16) public balanceOf;
    mapping (uint => address) public approve;
    event InvoiceMade(address owner, uint id, uint price, uint expiditionDate, uint expirationDate);
    event Transfer(address from, address to, uint id);
    event Approval(address owner, address approved, uint id);


    constructor() public {
    	ownerSC = msg.sender;
        id = 0;
    }

    modifier isId(uint _tokenId) {
        require(invoice[_tokenId].id == _tokenId, "error");
        _;
    }

    modifier isOwner(uint _tokenId) {
        require(invoice[_tokenId].owner == msg.sender, "error");
        _;
    } 

    modifier isAddressDeploy(address _addressTo) {
        require(_addressTo != 0x0000000000000000000000000000000000000000, "error");
        _;
    }

    function createInvoice(string memory  _description, uint _price) public {
        id += 1;
        balanceOf[msg.sender] += 1; 
        idS.push(id);
        invoice[id].owner = msg.sender;
        invoice[id].descripction = _description;
        invoice[id].id = id;
        invoice[id].price = _price;
        invoice[id].expiditionDate = now;
        invoice[id].expirationDate = invoice[id].expiditionDate + 30 days;
        invoice[id].bidDate = 0;
        emit InvoiceMade(invoice[id].owner, invoice[id].id, invoice[id].price, invoice[id].expiditionDate, invoice[id].expirationDate); 
    }

    function receivePayment(uint256 _tokenId) external payable isId(_tokenId) {
        address _oldOwner = invoice[_tokenId].owner;
    	require(invoice[_tokenId].price == msg.value, "error");
        require(invoice[_tokenId].expirationDate <= now, "error");
    	invoice[_tokenId].owner.transfer(msg.value);
        balanceOf[invoice[_tokenId].owner] -= 1; 
        invoice[_tokenId].owner = msg.sender;
        invoice[_tokenId].bidDate = now;
        balanceOf[msg.sender] += 1;        
        emit Transfer( msg.sender, _oldOwner, _tokenId);
    }
    
    function transferFrom(address _to, uint256 _tokenId) external isAddressDeploy(_to) isId(_tokenId) {
        require(invoice[_tokenId].owner == msg.sender || approve[_tokenId] == msg.sender, "error");      
        balanceOf[invoice[_tokenId].owner] -= 1; 
        invoice[_tokenId].owner = payable(_to);
        invoice[_tokenId].bidDate = now;
        balanceOf[_to] += 1;   
        emit Transfer(msg.sender, _to, _tokenId);
        }
    
    function setApprove(address _to, uint256 _tokenId) external isAddressDeploy(_to) isId(_tokenId) isOwner(_tokenId) {
        approve[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function getIssuedInvoices() public view returns(uint) {
        return idS.length;
    }
    
    function getAddressSC() public view returns(address) {
        return address(this);
    }

}