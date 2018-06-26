contract Sub {
    bytes32 one;
    function set(bytes32 _one) {
        one = _one;
    }
    function get() constant returns(bytes32) {
        return one;
    }
}

contract Main {
    struct Data {   
        bytes32 one;
        Sub two;
    }
    Data public d;
    function set(bytes32 _main, bytes32 _sub) returns (uint) {
        Sub s = new Sub();
        s.set(_sub);
        d.one = _main;
        d.two = s;
    }
    function getBoth() constant returns (bytes32, bytes32) {
        return (d.one, d.two.get());
    }
}