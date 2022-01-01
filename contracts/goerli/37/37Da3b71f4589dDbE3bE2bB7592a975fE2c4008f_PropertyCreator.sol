/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title PropertyCreator
 * @notice Contract to create new properties. E.g. the city of Hamburg is the PropertyCreator and can create new Properties
 * @author testandwin.net
 */
contract PropertyCreator {
    address public creator;
    Property[] public properties;

    constructor() {
        creator = msg.sender;
    }

    /**
    * @notice Create a new property. Only the contract owner can create new properties.
    * @param location Address of the property
    * @param lot Official identifier (lot, plot) of the property
    * @param owner Public address of the owner 
    */
    function createProperty(string memory location, string memory lot, address owner) public returns (address propertyAddress){
        require(creator == msg.sender, "Only the creator of this contract can create new properties!");
        Property p = new Property(location, lot, payable(owner));
        properties.push(p);
        return address(p);
    }
}

/**
 * @title Property Contract
 * @notice Used to trade properties. On the property may also be other property such as a house. A different smart contract should be used for condominium trading.
 * @author testandwin.net
 */
contract Property {
    struct InterestedParty{
      address party;
      uint offer;
    }

    enum Sale_State {NotForSale, ForSale, Selled}

    /// Owner of the property
    address payable public owner; 
    /// The possible new owner of the property.
    address payable newOwner;
    /// If the property if for sale or not
    Sale_State public saleState;
    /// The official identifier (lot, plot) of the property.
    string public lot;
    /// The complete address of the property.
    string public location; 
    /// The selling price of the property.
    uint sellingPrice;
    /// Stores all the interested parties when the property is for sale.
    InterestedParty[] interested;

    event OfferAccepted(address owner, address newOwner, uint value);
    event Purchase(address oldOwner, address owner, uint value);
  
    constructor(string memory _location, string memory _lot, address payable eoa){
        location = _location;
        owner = eoa;  
        lot = _lot;
        saleState = Sale_State.NotForSale;
    }
    
    modifier onlyOwner(){
      require(owner == msg.sender, "Your are not the owner");
      _;
    }

    modifier onlyOwnerOrNewOwner(){
      require(owner == msg.sender || newOwner == msg.sender, "Your are not the owner or the selected new owner!");
      _;
    }

    function getSellingPrice() public view onlyOwner returns(uint){
      return sellingPrice;
    }

    function getNumberOfInterestedParties() public view onlyOwner returns(uint){
      return interested.length;
    }

    function getOffer(uint index) public view onlyOwner returns(address, uint) {
        require(index < interested.length, "Index is out of bounds");
        return (interested[index].party, interested[index].offer);
    } 

    function getNewOwner() public view onlyOwner returns(address){
        return newOwner;
    }

    /**
     * @notice Step 1. The owner can mark the property for sale
     */
     function markForSale() public onlyOwner {
         saleState = Sale_State.ForSale;
     }

    /**
     * @notice The owner can unmark the property for sale
     */
     function unmarkForSale() public onlyOwner {
         saleState = Sale_State.NotForSale;
         deleteInterestedParties();
         newOwner = payable(0);
     }

    /**
     * @notice Step 2. An interested party could send / or update an offer for the property.
     * @param offer The amount the interested party is willing to pay for the property.
     */
    function sendOffer(uint offer) public {
        require(saleState == Sale_State.ForSale, "Property is not for sale!");
        interested.push(
            InterestedParty({
            party: payable(msg.sender),
            offer: offer
        }));
    }

    /**
     * @notice Step 3. The owner accepts the sell of the property. The transfer of the propery and the money is done in step 3.
     * @param _newOwner The address of the new owner
     * @param _sellingPrice The amount to be paid for the property
     */
    function sell(address payable _newOwner, uint _sellingPrice) public onlyOwner {
        // Check if newOwner is interested and has offered enough money and if the property is for sale
        require(saleState == Sale_State.ForSale, "Property is not for sale!");
        require(hasSendOffer(_newOwner, _sellingPrice), "This public address is not interested in your property or did not offer enough money!");

        // Store the price to be paid and the new owner.
        newOwner = _newOwner;
        sellingPrice = _sellingPrice;
        saleState = Sale_State.Selled;
        deleteInterestedParties();

        emit OfferAccepted(owner, _newOwner, _sellingPrice);
    }

    /**
     * @notice Step 4. Transfer the money and change the propery owner
     */
    function transfer() public payable {
        // Check if the sender is the accepted new owner and if the value matches
        require(msg.sender != owner, "You cannot purchase your own property!"); 
        require(msg.sender == newOwner, "You had not been interested in this property!");
        require(msg.value == sellingPrice, "The offer value does not match!");

        // Transfer money from the new owner to the contract is done by calling this function. The value must be set.
        // Transfer the money from the contract to the "old" owner
        owner.transfer(msg.value);

        emit Purchase(owner, newOwner, msg.value);

        // Change the owner
        owner = newOwner;

        // Reset the newOwner so that this function cannot be called again
        newOwner = payable(0);

        // The property is not for sale anymore
        saleState = Sale_State.NotForSale;
    }

    /**
     * @notice Step 4 alternativ. Either the owner the possible new owner can cancel the sale.
     */
    function cancelSale() public onlyOwnerOrNewOwner {
        newOwner = payable(0);
        saleState = Sale_State.NotForSale;
    }

    receive() external payable {
    }

    fallback() external payable {
    }

    // Helper functions 

    /// Check of the newOwner has send an offer before and if the offer value had been high enough
    function hasSendOffer(address _newOwner, uint _value) private view returns(bool){
      for(uint i = 0; i < interested.length; i++) {
        if(interested[i].party == _newOwner && interested[i].offer >= _value) {
            return true;
        }
      }
      return false;
    } 

    /// Empty the list of interested parties
    function deleteInterestedParties() private {
        uint max = interested.length;
        for(uint i = 0; i < max; i++) {
            interested.pop();
        }
    }
}