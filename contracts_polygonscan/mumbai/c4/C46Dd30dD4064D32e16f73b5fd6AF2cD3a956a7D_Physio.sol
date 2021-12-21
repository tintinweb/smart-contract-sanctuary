pragma solidity >=0.4.22 <0.9.0;

contract Physio {

    address public owner = msg.sender;

    struct PhysioNFT {
        string token_id;
        string chain;
        int quantity;
        address _address_sc;
    }

    mapping(string => PhysioNFT) public allPhysios;

    function makePhysio(string memory _token_id, string memory _chain, address _address_sc, int _quantity) public {
        if(allPhysios[_token_id].quantity > 0) {
            allPhysios[_token_id].quantity += _quantity;
        } else {
            allPhysios[_token_id] = PhysioNFT( _token_id,_chain, _quantity, _address_sc);
        }
    }

    function getTotalPhysios(string memory token_id) public view returns (int) {
        return allPhysios[token_id].quantity;
    }
}