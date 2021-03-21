/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

pragma solidity >=0.4.21 <0.6.0;

contract Marketplace {
    string public name;
    address payable public commissionAccount;
    address payable public contractAccount;
    uint public estateCount = 0;
    uint public comval = 10;
    uint public toPay = 90;
    mapping(uint => Estate) public estates; //place to store this products on the blockchain

    struct Estate {
        uint id;
        string name;
        uint price;
        string storedData;
        string haddress;
        address payable owner;
        bool purchased;
        bool onSale;
    }

    event EstateCreated(
        uint id,
        string name,
        uint price,
        string storedData,
        string haddress,
        address payable owner,
        bool purchased,
        bool onSale
    );

    event EstatePurchased(
        uint id,
        string name,
        uint price,
        string storedData,
        string haddress,
        address payable owner,
        bool purchased,
        bool onSale
);


    constructor() public {
        name = 'Marketplace';
        commissionAccount = 0x9c773590aCe0611F2580B4f5FC4eEC2C8Ec0006c;
        contractAccount = 0x197F7070b37Eee992753E7C1b0c309b534a694d3;

    }

    function createEstate(string memory _name, uint _price, string memory _storedData, string memory _haddress) public {
        //require a valid item
        require(bytes(_name).length > 0);

        //require a valid price
        require(_price > 0);

        //increment estateCount
        estateCount ++;

        //create Estate
        //msg.sender = owner/seller, address of user creating the estate
        estates[estateCount] = Estate(estateCount,_name,_price, _storedData,_haddress, msg.sender, false, false);

        //trigger event
        emit EstateCreated(estateCount,_name,_price, _storedData,_haddress,msg.sender, false, false);
    }

    function purchaseEstate(uint _id) public payable {
        //Fetch the estate
        Estate memory _estate = estates[_id];

        //Fetch the owner/seller
        address payable _seller = _estate.owner;

        //Make sure the estate id is valid
        require(_estate.id > 0 && _estate.id <= estateCount);

        //Make sure there is enough ether in transaction
        require(msg.value >= _estate.price);

        //Make sure estate is still available
        require(!_estate.purchased);

        //Make sure estate is still available for purchase
        require(_estate.onSale);

        //Make sure buyer is not seller
        require(_seller != msg.sender);

        //calculateActual price and commission
        uint _price = msg.value;
        uint _commission = (comval * _price) / 100;
        uint _actualPrice = (toPay * _price) / 100;


        //Purchase it/Transfer ownership
        _estate.owner = msg.sender;

        //Mark as purchased
        _estate.purchased = true;

        //update the estate
        estates[_id] = _estate;

        //pay commissionAccount
        address(commissionAccount).transfer(_commission);

        //pay seller with ether
        address(_seller).transfer(_actualPrice);


        //Trigger an event
        emit EstatePurchased(estateCount,_estate.name,_estate.price,_estate.storedData,_estate.haddress,msg.sender, true, false);
    }

    function RemoveEstate(uint _id) public {
        //Fetch the estate
        Estate memory _estate = estates[_id];

        //Fetch the owner/seller
        address payable _seller = _estate.owner;

        //Make sure estate is still available
        require(!_estate.purchased);

        //Make sure owner
        require(_seller == msg.sender);

        //delete estate
        delete estates[_id];
    }

    function putOnSale(uint _id) public {
        //Fetch the estate
        Estate memory _estate = estates[_id];

        //Fetch the owner/seller
        address payable _seller = _estate.owner;

        //Make sure estate is still available
        require(!_estate.purchased);

        //Make sure owner
        require(_seller == msg.sender);

        _estate.onSale = true;
        estates[_id] = _estate;
    }

    function withdraw(uint amount) public payable {
        //commission can be withdrawn only from commission account and by owner
        require(msg.sender == 0x9c773590aCe0611F2580B4f5FC4eEC2C8Ec0006c);
        address(contractAccount).transfer(amount);
    }

    function changeCommission(uint amount) public  {
        //only owner can change commission value
        require(msg.sender==0x197F7070b37Eee992753E7C1b0c309b534a694d3);

        comval = amount;
        toPay = (100 - amount);
    }

    function edit(uint _id, string memory _name,uint _price, string memory _haddress ) public {
        //Fetch the estate
        Estate memory _estate = estates[_id];

        //Fetch the owner/seller
        address payable _seller = _estate.owner;

        //Make sure estate is still available
        require(!_estate.purchased);

        //Make sure owner
        require(_seller == msg.sender);

        _estate.name = _name;
        _estate.price = _price;
        _estate.haddress = _haddress;
        estates[_id] = _estate;
    }
}