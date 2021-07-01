/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity >=0.4.22 < 0.7.0;

contract ProductContract {
    uint total;
    struct myStruct {
        string productName;
        string locaton;
        uint count;
        uint timestamp;
    }

    event product (
        string productName,
        string location,
        uint count,
        uint timestamp
    );

    myStruct[] public products;

    /* 사용자가 입력한 제품을 등록 */
    function addProduct (string memory _productName, string memory _location, uint _count) public {
        products.push(myStruct(_productName, _location, _count, block.timestamp));
        total++;
        emit product(_productName, _location, _count, block.timestamp);
    }

    /* 번호에 해당하는 제품의 이름을 리턴 */
    function getProduct(uint _idx) public view returns (string memory, string memory, uint, uint) {
        return (products[_idx].productName, products[_idx].locaton, products[_idx].count, products[_idx].timestamp);
    }

    function getTotal() public view returns (uint) {
        return total;
    }
}