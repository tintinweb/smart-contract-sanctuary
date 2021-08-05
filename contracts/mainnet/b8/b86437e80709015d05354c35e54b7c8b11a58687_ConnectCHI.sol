/**
 *Submitted for verification at Etherscan.io on 2020-08-06
*/

pragma solidity ^0.6.0;

interface CHIInterface {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint256) external;
}

contract ChiHelpers  {
    /**
     * @dev CHI token Address
     */
    function getCHIAddress() internal pure returns (address) {
        return 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    }

    /**
    * @dev Connector Details.
    */
    function connectorID() public view returns(uint model, uint id) {
        (model, id) = (1, 36);
    }
}

contract ChiResolver is ChiHelpers {
    /**
     * @dev Mint CHI token.
     * @param amt token amount to mint.
     */
    function mint(uint amt) public payable {
        uint _amt = amt == uint(-1) ? 140 : amt;
        require(_amt <= 140, "Max minting is 140 chi");
        CHIInterface(getCHIAddress()).mint(_amt);
    }

    /**
     * @dev burn CHI token.
     * @param amt token amount to burn.
     */
    function burn(uint amt) public payable {
        CHIInterface chiToken = CHIInterface(getCHIAddress());
        uint _amt = amt == uint(-1) ? chiToken.balanceOf(address(this)) : amt;
        chiToken.approve(address(chiToken), _amt);
        chiToken.free(_amt);
    }
}

contract ConnectCHI is ChiResolver {
    string public name = "CHI-v1";
}