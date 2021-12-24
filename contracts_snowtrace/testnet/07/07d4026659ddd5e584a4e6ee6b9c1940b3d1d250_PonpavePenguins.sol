/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract PonpavePenguins {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name = "NFT TESTOS";
    
    string public symbol = "NTOS";
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
    
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    /*///////////////////////////////////////////////////////////////
                        Ponpave PENGUINS STORAGE
    //////////////////////////////////////////////////////////////*/

    address payable public constant concaveTreasury = payable(0x8e260D609bA0C7B7818375b80635754EE2Ee21fc);

    address payable public immutable PonpavePenguinsTeam = payable(msg.sender);

    uint256 public constant mintFee = 0.5 ether;

    uint256 public constant divisor = 10000;

    uint256 public constant concaveShare = 3333; // bips

    uint256 public constant maxSupply = 3333;

    uint256 public constant maxMintAmount = 25;

    string public constant unrevealedURI = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";

    string public revealedURI;

    bool public revealed;
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        // This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[msg.sender]--; 
        
            balanceOf[to]++;
        }
        delete getApproved[tokenId];
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address, address to, uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender], 
            "NOT_APPROVED"
        );
        // This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed type(uint256).max!
        unchecked { 
            balanceOf[owner]--;
            balanceOf[to]++;
        }
        delete getApproved[tokenId];
        ownerOf[tokenId] = to;
        emit Transfer(owner, to, tokenId); 
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId) external {
        safeTransferFrom(address(0), to, tokenId, "");
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(address(0), to, tokenId);
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
            bytes4 selector = abi.decode(returned, (bytes4));
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    /*///////////////////////////////////////////////////////////////
                        PENGUIN Ponpave LOGIC
    //////////////////////////////////////////////////////////////*/

    bool _justInCase;

    function justInCase(bool wut) external {
        require(msg.sender == PonpavePenguinsTeam);
        _justInCase =  wut;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!revealed) return unrevealedURI;
        if (_justInCase) {
            return string(abi.encodePacked(revealedURI, "/", _toString(tokenId), ".json"));
        }
        return string(abi.encodePacked(revealedURI, _toString(tokenId), ".json"));
    }

    // hardcoded donation to concave treasury
    function withdraw() public {
        // get contract balance
        uint256 balance = address(this).balance;
        // calculate concave donation
        uint256 concaveAmount = balance * concaveShare / divisor;
        // transfer concave donation
        concaveTreasury.transfer(concaveAmount);
        // transfer out PP team share
        PonpavePenguinsTeam.transfer(address(this).balance);
    }

    // nfts get revealed after mint sells out
    function reveal(string memory _revealedURI) external {
        require(msg.sender == PonpavePenguinsTeam);
        revealedURI = _revealedURI;
        revealed = true;
    }

    uint256 public giveawayMints = 33;

    function giveawayMint(address to, uint256 amount) external {
        require(msg.sender == PonpavePenguinsTeam || msg.sender == concaveTreasury);
        // test that this reverts is more than 33 are minted
        giveawayMints -= amount;
        _batchMint(to, amount);
    }

    function mint(uint256 amount) external payable {
        // make sure user isn't minting more than 25 so the function doesn't fail
        require(amount <= maxMintAmount, "only 25 at a time");
        // make sure amount + total supply is less than max supply
        require(totalSupply + amount <= maxSupply, "sale over frenn");
        // make sure user sent enough avax
        require(msg.value >= amount * mintFee, "didn't send enough");
        // batch mint users penguins
        _batchMint(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _batchMint(address who, uint256 amount) internal {
        for (uint256 i; i < amount; i++) {
            if (totalSupply == 0) {
                _mint(who, 1);
                return;
            }
            _mint(who, totalSupply + 1);
        }
    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        totalSupply++;
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId); 
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
}