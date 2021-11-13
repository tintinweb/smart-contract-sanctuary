pragma solidity ^0.8.1;

// by XonaLabs 2021-2022

import "./ERC721URIStorage.sol";

contract ValhallaHipsters is ERC721URIStorage {
    uint public constant version = 1;
    uint public constant MAX_NFTS = 10000;
    uint public constant FREE_NFTS = 500;
    address public OWNER1;
    address public OWNER2 = 0x48122D8Fa6D9F24DD27906e4221b8d1beE16e006;
    uint public SMART_CONTRACT_RELEASE_BY_UNIXTIME;
    string public xonalabsBaseUrl = "https://ipfs.xonalabs.com/ipfs/";
    string public jsonsIpfsId = "QmUzqJhKPzSviZoDA9ytxV7uiqbuFBMXaVEsYX9oEwTM7B";
    uint public projectPaused;
    uint public mintedNfts;
    uint256 public freePhaseFee = 0.00 ether;
    uint256 public generalFee = 19 ether;
    uint256 private twoNftsFee = 38 ether;
    uint256 private threeNftsFee = 57 ether;
    uint256 private fourNftsFee = 76 ether;
    uint256 private fiveNftsFee = 95 ether;
    uint256 private sixNftsFee = 114 ether;
    uint256 private sevenNftsFee = 133 ether;
    uint256 private eightNftsFee = 152 ether;
    uint256 private nineNftsFee = 171 ether;
    uint256 private tenNftsFee = 190 ether;
    mapping(address => mapping(uint256 => uint256)) private ownerTokens;
    address[] public ethLegacyMints =  
    [
        0xAA4830313654C86417aca0292dd3573daf7905C8, 
        0xD9a673F3dBC459D2e2943DC82B1294c483f26365,
        0xd19AEA0a223015DfED6d0bb290dAcdBcC5EA9370,
        0x0A4DE625aa7624dD72cb09a41a6E52FCe1993310,
        0x05195AC340AC38e0710F4Ce45a432321A645201b,
        0xD19523A0E087bc62ee1D8A0153a2b753035DA72A,
        0xb8779D3Cf3e0F61806130b23A5ce619a8F02cca6,
        0xB56Cdccfc00e949D37b06592EFf031003196802d,
        0xD9a673F3dBC459D2e2943DC82B1294c483f26365,
        0xc9c6D5044e3fB14Ff2E1Baa82768543B02F8D286,
        0xB0E4BE83DF49bf88BF6A5817A73f7A1cdF3ED5d2,
        0x4ADb6b079CaF051Cfb45935c79c982d6a9960FBE,
        0x5A0EA13A3E172432aaee058687e4999389Aa947a,
        0xE746Cab01D0e3c86d1ed7AD85F4eA1deC4023B67,
        0xb08992Bd285B48B1C743Ca4e7ad8E543A65d4126,
        0xEa1b40dE5487CB20806e1dE3FCC27D1C20398757,
        0x917C5B1Ff016e5e8C90aC679a63CF87251dB257F,
        0x1Ab7F9e5bcC70bc6f2529a0aAcd0230C4C90a157
    ];


    constructor() ERC721("ValhallaHipsters", "VAHI") {
        OWNER1 = msg.sender;
        projectPaused = 1;
        mintedNfts = 0;
        SMART_CONTRACT_RELEASE_BY_UNIXTIME = block.timestamp;
        
        // Mint NFTs that were on ETH;
        for(uint i = 0; i < ethLegacyMints.length; i++) {
            mintEthereumLegacyNfts(ethLegacyMints[i]);
        }
    }

    event SubscribePayments(
        uint indexed id,
        address indexed user,
        uint256 indexed date,
        uint256 amount
    );

    function totalSupply() public pure returns (uint256) {
        return MAX_NFTS;
    }

    function contractURI() public view returns (string memory) {
        string memory url = string(abi.encodePacked(xonalabsBaseUrl, jsonsIpfsId, "/",  "about", ".json"));
        return url;
    }

    function mintNft(uint amount) internal {
        for(uint i = 0; i < amount; i++) {
            mintedNfts++;
            uint new_item_id = mintedNfts;
            string memory tokenuri = string(abi.encodePacked(xonalabsBaseUrl, jsonsIpfsId, "/",  uint2str(new_item_id), ".json"));
            _safeMint(msg.sender, new_item_id);
            _setTokenURI(new_item_id, tokenuri);
            emit SubscribePayments(new_item_id, msg.sender, block.timestamp, msg.value);
        }
    }
    
    function mintEthereumLegacyNfts(address user) internal {
            mintedNfts++;
            uint new_item_id = mintedNfts;
            string memory tokenuri = string(abi.encodePacked(xonalabsBaseUrl, jsonsIpfsId, "/",  uint2str(new_item_id), ".json"));
            _safeMint(user, new_item_id);
            _setTokenURI(new_item_id, tokenuri);
            emit SubscribePayments(new_item_id, user, block.timestamp, 0);
    }

    function changeOwner2(address _newaddr) public isOwner {
        OWNER2 = _newaddr;
    }

    function changeXonalabsBaseUrl(string memory _url) public isOwner {
        xonalabsBaseUrl = _url;
    }

    function changeJsonsIpfsId(string memory _ipfsid) public isOwner {
        jsonsIpfsId = _ipfsid;
    }

    function suspendProject(uint _param) public isOwner {
        projectPaused = _param;
    }

    function getScBalance() public view returns (uint) {
        return address(this).balance;
    }

    function changefreePhaseFee(uint256 _new) public isOwner {
        freePhaseFee = _new;
    }

    function chengeFee(uint256 _new) public isOwner {
        generalFee = _new;
    }

    function changeBatchedFees(uint256 _second, uint256 _third, uint256 _fourth, uint256 _fifth, uint256 _sixth, uint256 _seventh, uint256 _eighth, uint256 _nineth, uint256 _tenth) public isOwner {
        twoNftsFee = _second;
        threeNftsFee = _third;
        fourNftsFee = _fourth;
        fiveNftsFee = _fifth;
        sixNftsFee = _sixth;
        sevenNftsFee = _seventh;
        eightNftsFee = _eighth;
        nineNftsFee = _nineth;
        tenNftsFee = _tenth;
    }

    function payout(address payable _addr) public isOwner {
        _addr.transfer(address(this).balance);
    }


    function checkHowManyToMint() internal returns (uint) {
        if (msg.value == generalFee) {
            return(1);
        } else if (msg.value == twoNftsFee) {
            return(2);
        } else if (msg.value == threeNftsFee) {
            return(3);
        } else if (msg.value == fourNftsFee) {
            return(4);
        } else if (msg.value == fiveNftsFee) {
            return(5);
        } else if (msg.value == sixNftsFee) {
            return(6);
        } else if (msg.value == sevenNftsFee) {
            return(7);
        } else if (msg.value == eightNftsFee) {
            return(8);
        } else if (msg.value == nineNftsFee) {
            return(9);
        } else if (msg.value == tenNftsFee) {
            return(10);
        } else {
            require (1 == 0, "The ether amount is not correct to mint one or multiple NFTs!");
        }
    }

    function checkMintPhaseFee() internal {
        if (mintedNfts < FREE_NFTS) {
            mintNft(1);
        } else {
            mintNft(checkHowManyToMint());
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return ownerTokens[owner][index];
    }

    function uint2str(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    receive() external
    isPausedProject
    isMaxCountReached
    payable {
        checkMintPhaseFee();
    }

    modifier isMaxCountReached() {
        require(mintedNfts < MAX_NFTS, "The ValhallaHipsters buying period has ended. 10000 NFTs were minted!");
        _;
    }

    modifier isPausedProject() {
        require (projectPaused == 0, "The project not started yet or owners stopped it. Sorry for the inconvenience");
        _;
    }

    modifier isOwner() {
    require(msg.sender == OWNER1 || msg.sender == OWNER2, "Caller is not smart contract owner");
    _;
    }
}