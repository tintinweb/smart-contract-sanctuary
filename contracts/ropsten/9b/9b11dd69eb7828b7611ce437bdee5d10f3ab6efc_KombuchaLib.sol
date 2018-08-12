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
    ) public {
        require(_fillAmount <= _capacity && _capacity > 0);
        self.flavor = _flavor;
        self.fillAmount = _fillAmount;
        self.capacity = _capacity;
    }
    
    function fill(KombuchaStorage storage self, uint amountToAdd) public {
        uint newAmount = self.fillAmount + amountToAdd;
        require(newAmount > self.fillAmount && newAmount <= self.capacity);
        self.fillAmount = newAmount;
        emit FilledKombucha(amountToAdd, newAmount);
    }
    // ... and etc. for all the other functions
}