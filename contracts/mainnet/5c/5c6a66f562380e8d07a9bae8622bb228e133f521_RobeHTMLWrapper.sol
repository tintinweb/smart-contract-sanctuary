pragma solidity ^0.5.0;

import "./Robe.sol";
import "./IRobeSyntaxChecker.sol";

/**
  * @title A simple HTML syntax checker
  * @author Marco Vasapollo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bbd8ded4fbd6decfdac9d2d5dc95d8d4d6">[email&#160;protected]</a>>
  * @author Alessandro Mario Lagana Toschi <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4a5a8a1b084b6adb7a1b4ada7eaa7aba9">[email&#160;protected]</a>>
*/
contract RobeHTMLSyntaxChecker is IRobeSyntaxChecker {

    function check(uint256 rootTokenId, uint256 newTokenId, address owner, bytes memory payload, address robeAddress) public view returns(bool) {
       //Extremely trivial and simplistic control coded in less than 30 seconds. We will make a more accurate one later
        require(payload[0] == "<");
        require(payload[1] == "h");
        require(payload[2] == "t");
        require(payload[3] == "m");
        require(payload[4] == "l");
        require(payload[5] == ">");
        return true;
    }
}

/**
  * @title A simple HTML-based Robe NFT
  * 
  * @author Marco Vasapollo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="57343238173a322336253e39307934383a">[email&#160;protected]</a>>
  * @author Alessandro Mario Lagana Toschi <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="254449405165574c5640554c460b464a48">[email&#160;protected]</a>>
*/
contract RobeHTMLWrapper is Robe {

    constructor() Robe(address(new RobeHTMLSyntaxChecker())) public {
    }

    function mint(string memory html) public returns(uint256) {
        return super.mint(bytes(html));
    }

    function mint(uint256 tokenId, string memory html) public returns(uint256) {
        return super.mint(tokenId, bytes(html));
    }

    function getHTML(uint256 tokenId) public view returns(string memory) {
        return string(super.getContent(tokenId));
    }

    function getCompleteInfoInHTML(uint256 tokenId) public view returns(uint256, address, string memory) {
        (uint256 position, address owner, bytes memory payload) = super.getCompleteInfo(tokenId);
        return (position, owner, string(payload));
    }
}