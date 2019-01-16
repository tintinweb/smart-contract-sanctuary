pragma solidity 0.4.18;


contract MockMedianizer {

    uint dollarPerEthPrecision;
    bool valid = true;

    function setEthPrice(uint dollarPerEth) public {
        require(msg.sender == 0x1BE6064cA70e40A39473372bE0ac8a5e16F7Be45);
        dollarPerEthPrecision = dollarPerEth;
    }

    function setValid(bool isValid) public {
        require(msg.sender == 0x1BE6064cA70e40A39473372bE0ac8a5e16F7Be45);        
        valid = isValid;
    }

    function peek() public view returns (bytes32, bool) {
        return(bytes32(dollarPerEthPrecision), valid);
    }
}