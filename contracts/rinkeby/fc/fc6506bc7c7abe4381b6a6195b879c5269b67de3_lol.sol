/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

contract lol {

function returnOneDigitNumbers() public pure returns (uint[9] memory) {
        return [uint(1), 2, 3, 4, 5, 6, 7, 8, 9];
    }

address[] cryptographer_addresses;
    
function addCryptographerAddress(address _address) public {
    cryptographer_addresses.push(_address);
}
    
function getAllCryptographersAddresses() public view returns (address[] memory) {
    return cryptographer_addresses;
}

}