contract SFT {

    string public name = "Smart First Time 4 Way Distributor";
    uint8 public decimals = 18;
    string public symbol = "SFT4";

    address public dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;
    address public foundation = 0x6eBe6E38ba1bDa9131C785f6491B2C8374B968fE;
    address public management = 0x12CD0732249F4c14c7E11B397E28dEF3CF276251;
    address public agency = 0xD02D2cDA1fA2250f809d6E9025e92d30AEd6C002;

    function SFT() {

    }

    // automatically distribute incoming funds to the 4 addresses equally
    function () payable public {
        require(msg.value > 0);
        uint256 share = (msg.value * 2500) / 10000; // split the incoming 4 ways
        dev.transfer(share);
        foundation.transfer(share);
        management.transfer(share);
        agency.transfer(share);
    }

    function changeDev (address _receiver) public
    {
        require(msg.sender == dev);
        dev = _receiver;
    }

    function changeFoundation (address _receiver) public
    {
        require(msg.sender == foundation);
        foundation = _receiver;
    }

    function changeManagement (address _receiver) public
    {
        require(msg.sender == management);
        management = _receiver;
    }

    function changeAgency (address _receiver) public
    {
        require(msg.sender == agency);
        agency = _receiver;
    }

    // just in case
    function safeWithdrawal() public {
        uint256 split = (this.balance * 2500) / 10000; // split the incoming 4 ways
        dev.transfer(split);
        foundation.transfer(split);
        management.transfer(split);
        agency.transfer(split);
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}