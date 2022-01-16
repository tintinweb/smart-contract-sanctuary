// SPDX-License-Identifier: MIT 
// @author: @CoolMonkes                                                                       
//                                  ...  ...                                       
//                                 ..............                                  
//                           .......************.......                            
//                       .....************************.....                        
//                    ....********************************.....                    
//                  ...,**************************************...                  
//       .............***************************,**************... ........       
//    ....*******...******.......*********...............*******,....******.....   
//   ...********...***.....%%%%%.....**.....%%%%%%%%%%%%....***...*************... 
//  ...***........**....%%%%%%%%%%%%....%%%%%%%%%%%%%%%%%%%...****,........*****...
//  ..****..%%%..**...%%%%%%%%%%%%%%%%%%%%%%%%%..%%%%%%%%%%%...****.%%%%%%..****...
//  ...****......*...%%%%%%.......%%%%%%%%%%%.......%%%%%%%%%...****/%%....*****...
//   ...******...*...%%%%%[email protected]%%%%%%%%%%...CM%..%%%%%%%%%...****,...******.... 
//     ....,**...*../%%%%%[email protected]%%%%%%%%%[email protected]%%%%%%%%%...************....   
//        .......*...%%%%%%[email protected]%%%%%%%%%%/[email protected]%%%%%%%%%...***..........      
//             ***,..%%%%%%%.....%%%%%%%%%%%%%....%%%%%%%%%%...*******,            
//            ...**...%%%%%%%%%%%%%%/.%%%%..%%%%%%%%%%%%%%%...*******...           
//            ...**...%%%%%%%%%%%%%%%...%..%%%%%%%%%%%%%%%%(..*******..            
//             ..**...%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%..******...            
//             ...**..%%%%%%%%%%%%%%%%%%%%%......%%%%%%%%%%%...****...             
//               ......%%%%%%%%%%%...........((...%%%%%%%%%%..,**....              
//                ......%%%%%%%%%%.........(((...%%%%%%%%%%...*....                
//                  ......%%%%%%%%%%%%%(/,.*%%%%%%%%%%%%%%(......                  
//                     ......%%%%%%%%%%%%%%%%%%%%%%%%%.......                      
//                          ........COOLMONKES.......                            
//                                   . .....        
// Features:
// MONKE ARMY SUPER GAS OPTIMIZATIONZ using binary search & probability theory to maximize gas savings!
// Secure permit list minting to allow our users gas war free presale mintingz!
// Auto approved for listing on Opensea, LooksRare & Rarible to reduce gas fees for our monke army!
// Open commercial right contract for our users stored on-chain, be free to exercise your creativity!

pragma solidity ^0.8.11;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ECDSA.sol";


contract CoolMonkes is ERC721, ERC721URIStorage, Ownable {
   using SafeMath for uint256;
   using ECDSA for bytes32;

    //Our license is meant to be liberating in true sense to our mission, as such we do mean to open doors and promote fair use!
    //Full license including details purchase and art will be located on our website https://www.coolmonkes.io/license [as of 01/01/2022]
    //At the time of writing our art licensing entails: 
    //Cool Monke holders are given complete commercial & non-commericial rights to their specific Cool Monkes so long as it is in fair usage to the Cool Monkes brand 
    //The latest version of the license will supersede any previous licenses
    string public constant License = "MonkeLicense CC";
    bytes public constant Provenance = "0x5e9c0665630C8659180DA179cef43edEa40152D3";
    address public constant enforcerAddress = 0xD8A7fd1887cf690119FFed888924056aF7f299CE;

    //Monkeworld Socio-economic Ecosystem
    uint256 public constant maxGenesisMonkes = 10000;

    //Team reserves will be utilized for marketing, community building, giveaways and rewards for good actors
    uint256 public constant maxTeamReserveMonkes = 275;
    uint256 public teamReserveCounter = 0;

    //Max mints per role
    uint256 public constant ogMaxMints = 4;
    uint256 public constant wlMaxMints = 3; 
    uint256 public constant publicMaxMints = 2;

    //Fair community contribution pricing to reward our community builders
    uint256 public constant ogPrice = 0.05 ether;
    uint256 public constant wlPrice = 0.06 ether;
    uint256 public constant publicPrice = 0.08 ether;
    
    //Minting tracking and efficient rule enforcement, nounce sent must always be unique
    mapping(address => uint256) public nounceTracker;

    //Sale states
    bool public presaleEnabled = false;
    bool public publicSaleEnabled = false;

    //Reveal will be conducted on our API to prevent rarity sniping
    //Post reveal token metadata will be migrated from API and permanently frozen on IPFS
    string public baseTokenURI = "https://www.coolmonkes.io/api/metadata/genesis/";

    constructor() ERC721("Cool Monkes", "CMNKS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function totalTokens() public view returns (uint256) {
        return _owners.length;
    }

    //Yes this is ugly but it saves gas through binary search & probability theory, a total of 5-10 ETH for our dear hodlers will be saved because of this ugliness
    function multiMint(uint amount, address to) private {
        require(amount > 0, "Invalid amount");
        require(_checkOnERC721Received(address(0), to, _mint(to), ''), "ERC721: transfer to non ERC721Receiver implementer"); //Safe mint 1st and regular mint rest to save gas! 
        if (amount < 4) {
            if (amount == 2) {
                _mint(to);
            } else if (amount == 3) {
                _mint(to);
                _mint(to);
            }
        } else {
            if (amount > 5) {
                if (amount == 6) {
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                } else { // 7
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                }
            } else {
                if (amount == 4) {
                    _mint(to);
                    _mint(to);
                    _mint(to);
                } else { // 5
                    _mint(to);
                    _mint(to);
                    _mint(to);
                    _mint(to);
                }
            }
        }

    }

    function mint(uint256 amount) public payable {
        require(publicSaleEnabled == true, "Public sale is not enabled yet!");
        require(_owners.length + amount <= maxGenesisMonkes, "Cool Monkes are sold out!");
        require(amount <= publicMaxMints, "Too much hoarding, max 2 per transaction!");
        require(msg.value >= publicPrice.mul(amount), "Incorrect amount of funds");
        
        multiMint(amount, _msgSender());
    }

    function getMessageHash(address _to, uint _amount, uint _price, uint _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _price, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(address _signer, address _to, uint _amount, uint _price, uint _nounce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _price, _nounce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function presaleMint(uint amount, uint price, uint nounce, bytes memory signature) public payable  {
        require(presaleEnabled == true, "Presale is not enabled yet!");
        require(_owners.length + amount <= maxGenesisMonkes, "Cool Monkes are sold out!");
        require((nounceTracker[_msgSender()] >> 16) + amount <= ogMaxMints + wlMaxMints, "Too much hoarding m8!");
        require(uint16(nounceTracker[_msgSender()]) != nounce, "Can not repeat a prior transaction!");
        require(msg.value >= price, "Incorrect amount of funds");
        require(verify(enforcerAddress, _msgSender(), amount, price, nounce, signature) == true, "Presale must be minted from our website");

        nounceTracker[_msgSender()] += (amount << 16) + nounce;
        multiMint(amount, _msgSender());
    }

    function teamReserve(uint8 amount, address to) public onlyOwner {
        require(_owners.length + amount <= maxGenesisMonkes, "Cool Monkes are sold out!");
        require(teamReserveCounter + amount <= maxTeamReserveMonkes, "Team reserve completed");
        teamReserveCounter += amount;
        for(uint256 i = 0; i < amount; i++) {
            _mint(to);
        }
    }

    function flipPresale() public onlyOwner {
        presaleEnabled = !presaleEnabled;
    }

    function flipPublicsale() public onlyOwner {
        publicSaleEnabled = !publicSaleEnabled;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw transfer failiure");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}