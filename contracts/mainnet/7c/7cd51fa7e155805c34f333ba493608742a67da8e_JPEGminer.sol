//SPDX-License-Identifier: MIT

/// @title JPEG Mining
/// @author Xatarrer
/// @notice Unaudited
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./SSTORE2.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./SafeMath.sol";

/** 
    @dev Return data URL:
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
    https://en.wikipedia.org/wiki/Data_URI_scheme

    @dev Base64 encoding/decoding available at https://github.com/Brechtpd/base64/blob/main/base64.sol
    
    @dev Large efficient immutable storage: https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol
*/

contract JPEGminer is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    event Mined(address minerAddress, string indexed phase);

    uint256 public constant NSCANS = 100;

    string private constant _NAME = "Mined JPEG";
    string private constant _SYMBOL = "MJ";
    string private constant _DESCRIPTION =
        "JPEG Mining is a collaborative effort to store %2a%2athe largest on-chain image%2a%2a %281.5MB in Base64 format %26 1.1MB in binary%29. "
        "The image is split into 100 pieces which are uploaded by every wallet that calls the function mine%28%29. "
        "Thanks to the %2a%2aprogressive JPEG%2a%2a technology the image is viewable since its first piece is mined, "
        "and its quality gradually improves until the last piece is mined.  %5Cr  %5Cr"
        "As the image's quality improves over each successive mining, it goes through 3 different clear phases%3A  %5Cr"
        "1. image is %2a%2black & white%2a%2 only,  %5Cr2. %2a%2color%2a%2 is added, and  %5Cr3. %2a%2resolution%2a%2 improves until the final version.  %5Cr"
        "The B&W phase is the shortest and only lasts 11 uploads, "
        "the color phase last 22 uploads, and the resolution phase is the longest with 67 uploads.  %5Cr  %5Cr"
        "Every JPEG miner gets an NFT of the image with the quality at the time of minting.  %5Cr  %5Cr"
        "Art by Logan Turner. Idea and code by Xatarrer.";

    // Replace the hashes before deployment
    address private immutable _mintingGasFeesPointer;
    address private immutable _imageHashesPointer;
    address private immutable _imageHeaderPointer;
    address[] private _imageScansPointers;
    string private constant _imageFooterB64 = "/9k=";

    constructor(
        string memory imageHeaderB64,
        bytes32[] memory imageHashes,
        uint256[] memory mintingGasFees
    ) ERC721(_NAME, _SYMBOL) {
        require(imageHashes.length == NSCANS);

        // Store minting gas fees
        _mintingGasFeesPointer = SSTORE2.write(abi.encodePacked(mintingGasFees));

        // Store header
        _imageHeaderPointer = SSTORE2.write(bytes(imageHeaderB64));

        // Store hashes
        _imageHashesPointer = SSTORE2.write(abi.encodePacked(imageHashes));

        // Initialize array of pointers to scans
        _imageScansPointers = new address[](NSCANS);
    }

    /// @return JSON with properties
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return
            mergeScans(
                tokenId,
                string(
                    abi.encodePacked(
                        "data:application/json;charset=UTF-8,%7B%22name%22%3A %22",
                        _NAME,
                        "%3A ",
                        Strings.toString(tokenId + 1),
                        " of ",
                        Strings.toString(NSCANS),
                        "%22, %22description%22%3A %22",
                        _DESCRIPTION,
                        "%22, %22image%22%3A %22data%3Aimage/jpeg;base64,",
                        string(SSTORE2.read(_imageHeaderPointer))
                    )
                ),
                string(
                    abi.encodePacked(
                        _imageFooterB64,
                        "%22,%22attributes%22%3A %5B%7B%22trait_type%22%3A %22kilobytes%22, %22value%22%3A "
                    )
                ),
                string(
                    abi.encodePacked(
                        "%7D, %7B%22trait_type%22%3A %22phase%22, %22value%22%3A %22",
                        getPhase(tokenId),
                        "%22%7D%5D%7D"
                    )
                )
            );
    }

    function mergeScans(
        uint256 tokenId,
        string memory preImage,
        string memory posImage,
        string memory lastText
    ) private view returns (string memory) {
        // Get scans
        uint256 KB = 0;
        string[] memory data = new string[](9);

        for (uint256 i = 0; i < 9; i++) {
            if (tokenId < 12 * i) break;

            string[] memory scans = new string[](12);

            for (uint256 j = 0; j < 12; j++) {
                if (tokenId < 12 * i + j) break;

                bytes memory scan = SSTORE2.read(_imageScansPointers[12 * i + j]);
                scans[j] = string(scan);
                KB += scan.length;
            }

            data[i] = string(
                abi.encodePacked(
                    scans[0],
                    scans[1],
                    scans[2],
                    scans[3],
                    scans[4],
                    scans[5],
                    scans[6],
                    scans[7],
                    scans[8],
                    scans[9],
                    scans[10],
                    scans[11]
                )
            );
        }

        return (
            string(
                abi.encodePacked(
                    preImage,
                    data[0],
                    data[1],
                    data[2],
                    data[3],
                    data[4],
                    data[5],
                    data[6],
                    data[7],
                    data[8],
                    posImage,
                    string(abi.encodePacked(Strings.toString(KB / 1024), lastText))
                )
            )
        );
    }

    function getPhase(uint256 tokenId) public pure returns (string memory) {
        require(tokenId < NSCANS);

        if (tokenId <= 10) return "Black & White";
        else if (tokenId <= 32) return "Color";
        else return "Resolution";
    }

    function getMintingGasFee(uint256 tokenId) public view returns (uint256) {
        require(tokenId < NSCANS);

        bytes memory hashBytes = SSTORE2.read(_mintingGasFeesPointer, tokenId * 32, (tokenId + 1) * 32);

        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(hashBytes[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }

    function getHash(uint256 tokenId) public view returns (bytes32) {
        require(tokenId < NSCANS);

        bytes memory hashBytes = SSTORE2.read(_imageHashesPointer, tokenId * 32, (tokenId + 1) * 32);

        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(hashBytes[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /// @param imageScanB64 Piece of image data in base64
    function mine(string calldata imageScanB64) external payable {
        // Checks
        require(msg.sender == tx.origin, "Only EA's can mine");
        require(balanceOf(msg.sender) == 0, "Cannot mine more than once");
        require(totalSupply() < NSCANS, "Mining is over");

        // Check gas minting fee
        uint256 mintingFee = tx.gasprice.mul(getMintingGasFee(totalSupply()));
        require(msg.value >= mintingFee, "ETH fee insufficient");

        // Check hash matches
        require(keccak256(bytes(imageScanB64)) == getHash(totalSupply()), "Wrong data");

        // SSTORE2 scan
        _imageScansPointers[totalSupply()] = SSTORE2.write(bytes(imageScanB64));

        // Return change
        payable(msg.sender).transfer(msg.value - mintingFee);

        // Mint scan
        uint256 tokenId = totalSupply();
        _mint(msg.sender, tokenId);

        emit Mined(msg.sender, getPhase(tokenId));
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(address addrERC20) external onlyOwner {
        uint256 balance = IERC20(addrERC20).balanceOf(address(this));
        IERC20(addrERC20).transfer(owner(), balance);
    }
}