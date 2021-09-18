pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC721.sol";

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC721 for ERC721;

    // Public Basic
    uint256 private dayTime;
    ERC721 private cuseNftContract;
    ERC20 private cuseTokenContract;

    // Events


    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 3600;
          cuseNftContract = ERC721(0xfc8AE87E4Fb6760cF3D90749eb4FC9E6D0362919);
    }

    // ================= Deposit Operation  =================

    function exitDeposit(uint256 _tokenId) public returns (bool) {
        // Data validation
        require(cuseNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: ownerOf not.");

        // Orders dispose
        cuseNftContract.sunshineTransferFrom(msg.sender,address(this),_tokenId);


        return true;
    }

    function joinDeposit(uint256 _tokenId) public returns (bool) {
        // Data validation
        require(cuseNftContract.ownerOf(_tokenId)==msg.sender,"-> ownerOf: ownerOf not.");

        // Orders dispose
        cuseNftContract.sunshineTransferFrom(address(this),address(msg.sender),_tokenId);

        return true;
    }

}