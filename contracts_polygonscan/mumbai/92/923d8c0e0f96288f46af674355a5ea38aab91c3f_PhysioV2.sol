pragma solidity >=0.4.22 <0.9.0;

contract PhysioV2 {
    bool private initialized;
    struct PhysioNFT {
        string token_id;
        string chain;
        int quantity;
        address _address_sc;
    }

    mapping(string => PhysioNFT) public allPhysios;

    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
    }

    function makePhysio(string memory _token_id, string memory _chain, address _address_sc, int _quantity) public {
        string memory index  = string(abi.encodePacked(_token_id, _chain, _address_sc));
        if(allPhysios[index].quantity > 0) {
            allPhysios[index].quantity += _quantity;
        } else {
            allPhysios[index] = PhysioNFT( _token_id,_chain, _quantity, _address_sc);
        }
    }

    function makePhysioTwo(string memory _token_id, string memory _chain, address _address_sc, int _quantity) public {
        string memory index  = string(abi.encodePacked(_token_id, _chain, _address_sc));
        if(allPhysios[index].quantity > 0) {
            allPhysios[index].quantity += (_quantity + 2);
        } else {
            allPhysios[index] = PhysioNFT( _token_id,_chain, _quantity, _address_sc);
        }
    }

    function getTotalPhysios(string memory _token_id, string memory _chain, address _address_sc ) public view returns (int) {
        string memory index  = string(abi.encodePacked(_token_id, _chain, _address_sc));
        return allPhysios[index].quantity;
    }
}