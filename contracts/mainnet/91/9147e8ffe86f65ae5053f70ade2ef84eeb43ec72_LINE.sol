//                            @                                                   
//                           @                                                    
//                          @                                                     
//                         @                                                      
//                        @                                                       
//                       @                                                        
//                      @                                                         
//                     @                                                          
//                    @                                                           
//                   @                                                            
//                  @                                                             
//                 @        

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./PaymentSplitter.sol";

contract LINE is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, AccessControl, PaymentSplitter {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant PRICE = 11000000000000000; // 0.011 ETH
    uint256 public constant MAX_SUPPLY = 11111;
    
    uint256 private constant MAX_ADMIN_TOKENS = 111;
    uint256 private constant MAX_PER_MINT = 11;

    bool public publicSaleActive = false;
    
    string private _baseURIextended;
    uint256 private _adminTokenCounter = 0;
    uint256 private _publicTokenCounter = 111;

    constructor(address[] memory _payees, uint256[] memory _shares) ERC721("LINE", "LINE") PaymentSplitter(_payees, _shares) payable {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }
    
    // Modifiers
    
    modifier requireMint(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(numberOfTokens <= MAX_PER_MINT, "Cannot mint more than max");
        require(
            (_publicTokenCounter + numberOfTokens) <= MAX_SUPPLY,
            "Exceeded max supply"
        );
        require(
            calculateMintCost(numberOfTokens) == msg.value,
            "Value is not correct"
        );
        _;
    }
    
    // Admin

    function togglePublicSale() public onlyRole(ADMIN_ROLE) {
        publicSaleActive = !publicSaleActive;
    }

    function setBaseURI(string memory baseURI)
        public
        onlyRole(ADMIN_ROLE)
    {
        _baseURIextended = baseURI;
    }

    function reserveTokens(uint256 numberOfTokens, address recipient)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(
            (_adminTokenCounter + numberOfTokens) <= MAX_ADMIN_TOKENS,
            "Exceeds admin max"
        );
        
        uint256 startIndex = _adminTokenCounter;
        _adminTokenCounter += numberOfTokens;
        
        _mint(numberOfTokens, recipient, startIndex);
    }

    // Public Sale
    
    function mint(uint256 numberOfTokens)
        public
        payable
        requireMint(numberOfTokens)
    {
        require(publicSaleActive == true, "Sale must be active");

        uint256 startIndex = _publicTokenCounter;
        _publicTokenCounter += numberOfTokens;
        
        _mint(numberOfTokens, _msgSender(), startIndex);
    }
    
    function _mint(uint256 numberOfTokens, address sender, uint256 startIndex) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(sender, startIndex + i);
        }
    }

    // Utility

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function calculateMintCost(uint numberOfTokens) internal pure returns(uint) {
        return numberOfTokens * PRICE;
    }

    // The following functions are overrides required by Solidity.
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}