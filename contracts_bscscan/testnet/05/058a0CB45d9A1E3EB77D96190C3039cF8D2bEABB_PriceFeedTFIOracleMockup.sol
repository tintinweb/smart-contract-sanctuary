pragma solidity 0.5.17;

contract PriceFeedTFIOracleMockup {
    uint256 public value;
    bool public has;

    function getPricing() public view returns(uint256, uint256) {
        return (value, block.timestamp);
    }

    function setValue(
        uint256 _value)
        public
    {
        value = _value;
    }

    function setHas(bool _has) public {
        has = _has;
    }
}