contract SFTSEV {

    string public name = "Smart First Time 7 Way Distributor";
    uint8 public decimals = 18;
    string public symbol = "SFT7";

    address dev = 0xC96CfB18C39DC02FBa229B6EA698b1AD5576DF4c;//	10
    address designer = 0x810c4de015a463E8b6AFAFf166f57A2B2F761032;//5
    address media = 0x2deE3DDbE1b0aC0Bb8918de07007B60B264f58D3;//10
    address reserve = 0x76D05E325973D7693Bb854ED258431aC7DBBeDc3;//10
    address partner1 = 0x73BB9A6Ea87Dd4067B39e4eCDBe75E9ffe90c69c;//5
    address partner2 = 0x6c5Cd0e2f4f5958216ef187505b617b3Cf1ed348;//30
    address partner3 = 0x448468d5591c724f5310027b859135d5f6434286;//30

    function SFTSEV() {

    }

    // automatically distribute incoming funds to the 7 addresses based on agreed %
    function () payable public {
        require(msg.value > 0);
        dev.transfer(div(mul(msg.value,1000),10000));
        designer.transfer(div(mul(msg.value,500),10000));
        media.transfer(div(mul(msg.value,1000),10000));
        reserve.transfer(div(mul(msg.value,1000),10000));
        partner1.transfer(div(mul(msg.value,500),10000));
        partner2.transfer(div(mul(msg.value,3000),10000));
        partner3.transfer(div(mul(msg.value,3000),10000));
    }

    function changeDev (address _receiver) public
    {
        require(msg.sender == dev);
        dev = _receiver;
    }

    function changeDesigner (address _receiver) public
    {
        require(msg.sender == designer);
        designer = _receiver;
    }

    function changeMedia (address _receiver) public
    {
        require(msg.sender == media);
        media = _receiver;
    }

    function changeReserve (address _receiver) public
    {
        require(msg.sender == reserve);
        reserve = _receiver;
    }

    function changePartner1 (address _receiver) public
    {
        require(msg.sender == partner1);
        partner1 = _receiver;
    }

    function changePartner2 (address _receiver) public
    {
        require(msg.sender == partner1);
        partner2 = _receiver;
    }

    function changePartner3 (address _receiver) public
    {
        require(msg.sender == partner1);
        partner3 = _receiver;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}