contract MarriageContract {

    address a;
    address b;
    uint256 till;
    string agreement;

    mapping(address => bool) coupleConfirmations;
    mapping(address => bool) witnesses;

    modifier onlyCouple(){
        require(msg.sender == a || msg.sender == b);
        _;
    }

    function MarriageContract(address _a, address _b, uint256 _till, string _agreement){
        a = _a;
        b = _b;
        till = _till;
        agreement = _agreement;
    }

    function getA() returns (address) {
        return a;
    }

    function getB() returns (address) {
        return b;
    }

    function getTill() returns (uint256){
        return till;
    }

    function getAgreement() returns (string) {
        return agreement;
    }

    function married() constant returns (bool) {
        return coupleConfirmations[a] && coupleConfirmations[b] && till <= now;
    }

    function signContract() onlyCouple() {
        coupleConfirmations[msg.sender] = true;
    }

    function signWitness(){
        witnesses[msg.sender] = true;
    }

    function isWitness(address _address) constant returns (bool) {
        return witnesses[_address];
    }

}