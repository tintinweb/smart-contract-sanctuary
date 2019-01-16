contract A {
    address b = 0xea7b971ed5643693e8f84f5768ddf4db511b6625;
    function a(address to, uint value) {
        B(b).b(to, value);
    }
}

contract B {
    function b(address to, uint value) {
        to.transfer(value);
    }
    function () payable {
    }
}