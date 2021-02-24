pragma solidity ^0.6.2;
import "./Ownable.sol";
import "./ERC721.sol";


contract CryptoPeeps is ERC721, Ownable {

    mapping (uint256 => uint256) private _peepsMinted;

    constructor() public ERC721("CryptoPeeps", "CRYPTOPEEPS") {}

    function setBaseURI(string memory baseURI) onlyOwner public {
        _setBaseURI(baseURI);
    }
    
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    function getPeepPrice(uint256 twitterId) public view returns (uint256) {
        uint256 peepsMinted = _peepsMinted[twitterId];
        if (peepsMinted == 2) {
            return 10000000000000000000; // 10.0 ETH
        } else if (peepsMinted == 1) {
            return 1000000000000000000; // 1.0 ETH
        } else {
            return 100000000000000000; // 0.1 ETH 
        }
    }


    function mintPeep(uint256 twitterId) public payable returns (uint256) {
        require(_peepsMinted[twitterId] < 3, "This CryptoPeep has reached it's minting limit");
        require(msg.value == getPeepPrice(twitterId), "Ether value sent is incorrect");

        uint256 cryptoPeepId = totalSupply();

        _mint(msg.sender, cryptoPeepId);
        _setTokenURI(cryptoPeepId, twitterId.toString());
        _peepsMinted[twitterId] = _peepsMinted[twitterId] + 1;

        return cryptoPeepId;
    }
}