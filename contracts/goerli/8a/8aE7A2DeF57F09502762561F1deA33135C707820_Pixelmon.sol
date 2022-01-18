// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

error MintedOut();
error AuctionNotStarted();
error MintingTooMany();
error ValueTooLow();
error NotWhitelisted();
error AlreadyClaimed();
error Unauthorized();
error UnknownEvolution();

contract Pixelmon is ERC721, Ownable {

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address constant whitelistSigner = 0x0B6ff093fdEe1b004Bc5C68f414eDd61f16E693D;

    /// @dev 7510 due to 10 minted in constructor
    uint constant auctionSupply = 7504;
    uint constant secondEvolutionOffset = 10000;
    uint constant thirdEvolutionOffset = 14000;
    uint constant fourthEvolutionOffset = 15200;

    /*///////////////////////////////////////////////////////////////
                            AUCTION STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 constant auctionStartPrice = 1 ether;
    uint256 constant auctionStartTime = 1642500000;
    uint256 public whitelistPrice = 0.25 ether;

    /*///////////////////////////////////////////////////////////////
                        EVOLUTIONARY STORAGE
    //////////////////////////////////////////////////////////////*/

    uint secondEvolutionSupply = 0;
    uint thirdEvolutionSupply = 0;
    uint fourthEvolutionSupply = 0;

    address serumContract;

    mapping(address => bool) whitelistClaimed;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string baseURI;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory _baseURI) ERC721("TestMon NFT", "TESTMN") {
        baseURI = _baseURI;
        unchecked {
            balanceOf[msg.sender] += 4;
            totalSupply += 4;
            for (uint256 i = 0; i < 4; i++) {
                ownerOf[i] = msg.sender;
                emit Transfer(address(0), msg.sender, i);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id));
    }

    /*///////////////////////////////////////////////////////////////
                        DUTCH AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    function validCalculatedTokenPrice() private view returns (uint) {
        uint priceReduction = ((block.timestamp - auctionStartTime) / 20 minutes) * 0.05 ether;
        return auctionStartPrice >= priceReduction ? (auctionStartPrice - priceReduction) : 0;
    }

    function getCurrentTokenPrice() public view returns (uint256) {
        return max(validCalculatedTokenPrice(), 0.2 ether);
    }

    function auction(uint noOfMints) public payable {
        if(block.timestamp < auctionStartTime || block.timestamp > auctionStartTime + 2 days) revert AuctionNotStarted();
        if(totalSupply + noOfMints > auctionSupply) revert MintedOut();
        if(balanceOf[msg.sender] + noOfMints > 2) revert MintingTooMany();
        if(msg.value < getCurrentTokenPrice() * noOfMints) revert ValueTooLow();

        whitelistPrice = getCurrentTokenPrice() / 4;
        
        /// @dev While a _mintBulk saves gas if noOfMints == 2, it is not significant enough and loses gas for the case of 1 mint. 
        unchecked {
            for(uint i; i < noOfMints; i++) {
                _mint(msg.sender, totalSupply);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        WHITELIST MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function whitelistMint(bytes calldata signature) public payable {
        /// @dev We do not check if auction is over because the whitelist will be uploaded after the auction. 
        if(whitelistClaimed[msg.sender]) revert AlreadyClaimed();
        if(totalSupply >= secondEvolutionOffset) revert MintedOut();
        if(!isWhitelisted(msg.sender, signature)) revert NotWhitelisted();
        if(msg.value < whitelistPrice) revert ValueTooLow();

        whitelistClaimed[msg.sender] = true;
        _mint(msg.sender, totalSupply);
    }

    function withdrawal() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function isWhitelisted(address user, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == whitelistSigner;
    }

    /*///////////////////////////////////////////////////////////////
                            ROLL OVER LOGIC
    //////////////////////////////////////////////////////////////*/

    function rollOverPixelmons(address[] calldata addresses) public onlyOwner {
        /// @dev We do not check if auction is over because the whitelist will be uploaded after the auction. 
        if(totalSupply + addresses.length >= secondEvolutionOffset) revert MintedOut();

        whitelistClaimed[msg.sender] = true;
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(msg.sender, totalSupply);
        }
    }
    /*///////////////////////////////////////////////////////////////
                        EVOLUTIONARY LOGIC
    //////////////////////////////////////////////////////////////*/

    function setSerumContract(address _serumContract) public onlyOwner {
        serumContract = _serumContract; 
    }

    function mintEvolvedPixelmon(address receiver, uint evolutionStage) public payable {
        if(msg.sender != serumContract) revert Unauthorized();
        if (evolutionStage == 2) {
            if(secondEvolutionSupply >= 4000) revert MintedOut();
            _mint(receiver, secondEvolutionOffset + secondEvolutionSupply);
            unchecked {
                secondEvolutionSupply++;
            }
        } else if (evolutionStage == 3) {
            if(thirdEvolutionSupply >= 1200) revert MintedOut();
            _mint(receiver, thirdEvolutionOffset + thirdEvolutionSupply);
            unchecked {
                thirdEvolutionSupply++;
            }
        } else if (evolutionStage == 4) {
            if(thirdEvolutionSupply >= 8) revert MintedOut();
            _mint(receiver, fourthEvolutionOffset + fourthEvolutionSupply);
            unchecked {
                fourthEvolutionSupply++;
            }
        } else  {
            revert UnknownEvolution();
        }
    }


    /*///////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "sig invalid");

        assembly {
            /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}