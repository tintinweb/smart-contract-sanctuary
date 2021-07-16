//SourceUnit: rainmakerX.sol

pragma solidity 0.5.8;

contract Hourglass {
    function reinvest() public {}
    function myTokens() public view returns(uint256) {}
    function myDividends(bool) public view returns(uint256) {}
}

contract PriceFloor {
    Hourglass hourglassInterface;
    address public hourglassAddress;
    
    constructor(address _hourglass) public {hourglassInterface = Hourglass(_hourglass);}
    function makeItRain() public {hourglassInterface.reinvest();}
    function myTokens() public view returns(uint256) {return hourglassInterface.myTokens();}
    function myDividends() public view returns(uint256) {return hourglassInterface.myDividends(true);}
}