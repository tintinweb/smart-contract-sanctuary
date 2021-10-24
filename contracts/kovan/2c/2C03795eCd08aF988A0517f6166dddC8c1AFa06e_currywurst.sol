pragma solidity >=0.6.6 <0.8.0;
pragma experimental ABIEncoderV2;

//this is because solidity does not yet support two levels of dynamic arrays.strings and arrays being both dynamic.
// string[] memory as return hence only works expirimentally

contract currywurst {
    address public owner;
    string[] public menu;
    string[] public orders;

    constructor() public {
        owner = msg.sender;
        menu.push("seidewurst");
        menu.push("Laugeweckle");
        //.push does not work with two parameters at once
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "sorry no rights lmao");
        _;
    }

    function Menu() public view returns (string[] memory) {
        //memory because, returned values are only temporarily stored. the values still exist in state variable storage though
        return menu;
    }

    function MenuChange(bool _change, string memory _value) public onlyOwner {
        //_value is memory as it is a throw away
        if (_change == true) {
            menu.pop();
        } else {
            menu.push(_value);
        }
    }

    function Order(string memory _order) public {
        orders.push(_order);
    }

    function filledOrder() public {
        orders.pop();
    }
}