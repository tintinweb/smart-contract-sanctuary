pragma solidity ^0.4.23;

library KombuchaLib {
    event FilledKombucha(uint amountAdded, uint newFillAmount);
    event DrankKombucha(uint amountDrank, uint newFillAmount);
    struct KombuchaStorage {
        uint fillAmount;
        uint capacity;
        string flavor;
    }
    
    function init(
        KombuchaStorage storage self,
        string _flavor, uint _fillAmount, uint _capacity
    ) internal {
        require(_fillAmount <= _capacity && _capacity > 0);
        self.flavor = _flavor;
        self.fillAmount = _fillAmount;
        self.capacity = _capacity;
    }
    
    function fill(KombuchaStorage storage self, uint amountToAdd) internal {
        uint newAmount = self.fillAmount + amountToAdd;
        require(newAmount > self.fillAmount && newAmount <= self.capacity);
        self.fillAmount = newAmount;
        emit FilledKombucha(amountToAdd, newAmount);
    }
    // ... and etc. for all the other functions
    
    function getAddress() internal view returns (address) {
        return address(this);
    }
    
    // msg.data
    function getSenderAddress() internal view returns (address) {
        return address(msg.sender);
    }
    
    function getSenderValue() internal view returns (uint256) {
        return msg.value;
    }
    
    function getSenderSig() internal view returns (bytes4) {
        return msg.sig;
    }
    
    function getData() internal view returns (bytes) {
        return msg.data;
    }
}


contract Kombucha {
    using KombuchaLib for KombuchaLib.KombuchaStorage;
    // we have to repeat the event declarations in the contract
    // in order for some client-side frameworks to detect them
    // (otherwise they won&#39;t show up in the contract ABI)
    
    event FilledKombucha(uint amountAdded, uint newFillAmount);
    event DrankKombucha(uint amountDrank, uint newFillAmount);
    
    KombuchaLib.KombuchaStorage public self;
    
    constructor(string _flavor, uint _fillAmount, uint _capacity) public {
        // self.init(_flavor, _fillAmount, _capacity);
    }
    
    function fill(uint amountToAdd) public {
        return self.fill(amountToAdd);
    }
    
    // do same for drink(...) method
    function fillAmount() public view returns (uint) {
        return self.fillAmount;
    }
    // same for capacity and flavor accessors
    
    function readLib() public view returns (uint, uint, string) {
        return (self.fillAmount, self.capacity, self.flavor);
    }
    
    function getAddress() public view returns (address) {
        return KombuchaLib.getAddress();
    }
    
    function getSenderAddress() public view returns (address) {
        return KombuchaLib.getSenderAddress();
    }
    
    function getSenderValue() public payable returns (uint256) {
        return KombuchaLib.getSenderValue();
    }
    
    function getSenderSig() public view returns (bytes4) {
        return KombuchaLib.getSenderSig();
    }
    
    function getData() public view returns (bytes) {
        return KombuchaLib.getData();
    }
}