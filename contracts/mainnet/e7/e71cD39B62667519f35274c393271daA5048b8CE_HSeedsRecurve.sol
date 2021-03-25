// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

// previous contract
contract PreviousContract {
    //function setApprovalForAll(address, uint256) public {}
    function balanceOf(address) public returns (uint256) {}
    function tokenOfOwnerByIndex(address, uint256) public returns (uint256) {}
    function safeTransferFrom(address, address, uint256, bytes memory) public {}
}

contract HSeedsRecurve is ERC721Enumerable, IERC721Receiver, Ownable, ReentrancyGuard {
    // Previous contract we deployed. Respnsible for first sales.
    PreviousContract private PREVIOUS_CONTRACT;

    // The address of the previous contract.
    string public constant PREVIOUS_CONTRACT_ADDR = "0xDc31e48b66A1364BFea922bfc2972AB5C286F9fe";
    
    // last token sold on previous contract.
    uint256 public constant FINAL_TOKEN_ID = 1724;
    
    // indicies coverred by the first level [0-1499]
    uint256 public constant LAST_TOKEN_ID_FIRST_LEVEL = 1499;

    // indicies reserved from first sale. Do not resell these indicies [0-1949].
    uint256 public constant RESERVED_TOKEN_ID = FINAL_TOKEN_ID + (FINAL_TOKEN_ID - LAST_TOKEN_ID_FIRST_LEVEL);
    
    // number of tokens we owe to those that bought in 0.6 range, our "airdrops".
    uint256 private AIRDROPS_CLAIMED = FINAL_TOKEN_ID - LAST_TOKEN_ID_FIRST_LEVEL;

    // track the total number of tokens claimed (included airdrops).
    uint256 public TOTAL_CLAIMED = 0;
    
    // This is the provenance record of all artwork in existence
    string public constant ENTROPYSEEDS_PROVENANCE = "51aab9a30a64f0b1f8325ccfa7e80cbcc20b9dbab4b4e6765c3e5178e507d210";

    // opens Mar 11 2021 15:00:00 GMT+0000
    uint256 public constant SALE_START_TIMESTAMP = 1615474800;

    // Time after which we randomly assign and allotted (s*m*h*d)
    // sale lasts for 21 days
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (60*60*24*21);

    uint256 public constant MAX_NFT_SUPPLY = 8275;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    bool private halt_mint = false;
    bool private halt_claim = false;

    // Mapping from token ID to whether the Entropyseed was minted before reveal
    mapping (uint256 => bool) private _mintedBeforeReveal;

    /*================================================================================
    //================================================================================
    //================================================================================
    //===============================================================================*/
    
    constructor(address previous) public ERC721("EntropySeeds", "HSEED") {
        PREVIOUS_CONTRACT = PreviousContract(previous);
    }
    
    /**
     * @dev - we use this to compute the mintIndex. We reserve the token up to FINAL_TOKEN for
     * buyers on the previous contract.
     **/
    function totalSupply() public view override returns (uint256) {
        uint256 supply = super.totalSupply();
        uint256 remaining_claims = (RESERVED_TOKEN_ID + 1) - TOTAL_CLAIMED;
        return supply + remaining_claims; // so we mint after
    }

    /**
    * @dev - Only accept if the tokenId is below the final one
    * and it comes from the last contract.
    **/
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public override returns (bytes4) {
            require(msg.sender == address(PREVIOUS_CONTRACT), "Request must come from previous contract address");
            require(tokenId <= FINAL_TOKEN_ID, "We are not accepting tokens past the cutoff");
            return IERC721Receiver.onERC721Received.selector;
    }
    
    function claimMyTokens(uint256 numberOfNfts) public nonReentrant {
        require(halt_claim == false, "Claims have been halted");
        require(numberOfNfts <= 10, "Max of 10 at a time");
        require(numberOfNfts > 0, "Need to claim something");

        require(TOTAL_CLAIMED <= (RESERVED_TOKEN_ID+1), "All claims have been filled."); 
        require((TOTAL_CLAIMED + numberOfNfts) <= (RESERVED_TOKEN_ID+1), "Claimed exceeds reserved.");
        
        uint256 balance = PREVIOUS_CONTRACT.balanceOf(msg.sender);
        require(balance > 0, "You own no tokens");
        require(numberOfNfts <= balance, "Claiming too many tokens");

        for (uint i = 0; i < numberOfNfts; ) {
            // has to be 0 because as we transfer the tokens the next one becomes 0.
            // need this info to understand how we handle the token (where it sold before).
            uint256 tokenId = PREVIOUS_CONTRACT.tokenOfOwnerByIndex(msg.sender, 0); 

            // It *might* be out of order and they can still buy from the previous contract
            // [0,1724] INCLUSIVE.
            // Should be handled by the onERC721Received but should be fine doing it this way
            if (tokenId > FINAL_TOKEN_ID) {
                unchecked{i++;}
                continue;
            }
            
            // mint a new one under this smart contact
            unchecked{TOTAL_CLAIMED = TOTAL_CLAIMED + 1;} // @dev save gas 
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[tokenId] = true;
            }
            _safeMint(msg.sender, tokenId);

            // if they bought after the 0.2 level, at 0.6, we want to airdrop them
            // another token since this price level is now 0.3.
            if (tokenId > LAST_TOKEN_ID_FIRST_LEVEL) {
                // because we want to preserve the order for previous holders
                // we mint after the FINAL_TOKEN.
                uint256 mintIndex = FINAL_TOKEN_ID + AIRDROPS_CLAIMED;
                unchecked{TOTAL_CLAIMED = TOTAL_CLAIMED + 1;} // @dev save gas
                if (block.timestamp < REVEAL_TIMESTAMP) {
                    _mintedBeforeReveal[mintIndex] = true;
                }
                AIRDROPS_CLAIMED = AIRDROPS_CLAIMED - 1;
                require(AIRDROPS_CLAIMED >= 0, "Oversold.");

                _safeMint(msg.sender, mintIndex);
            }

            // Here we are "burning" the old tokens. They will stay in this contract forever.
            // stops ppl from using the old ones after.
            PREVIOUS_CONTRACT.safeTransferFrom(msg.sender, address(this), tokenId, "");

            unchecked{i++;} // @dev save gas
        }
    }

    /**
     * @dev Returns if the NFT has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }
    
    /**
     * @dev Gets current price level
     */
    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint256 currentSupply = totalSupply();
        if (currentSupply >= 8270) {
            return 5000000000000000000; // 8270 - 8275 5 ETH
        } else if (currentSupply >= 8250) {
            return 3000000000000000000; // 8250 - 8269 3 ETH
        } else if (currentSupply >= 8200) {
            return 1000000000000000000; // 8200  - 8249  1 ETH
        } else if (currentSupply >= 7000) {
            return 500000000000000000; // 7000 - 8199 0.5 ETH
        } else if (currentSupply >= 4500) {
            return 400000000000000000; // 4500 - 6999 0.4 ETH
        } else if (currentSupply >= 1500) {
            return 300000000000000000; // 1500 - 4499 0.3 ETH
        } else {
            return 200000000000000000; // 0 - 1499 0.2 ETH 
        }
    }
    
    /**
    * @dev Mints numberOfNfts Entropyseeds
    * Price slippage is okay between levels. Known "bug".
    * Minting starts above RESERVED_TOKEN_ID 
    */
    function mintNFT(uint256 numberOfNfts) public payable nonReentrant {
        require(halt_mint == false, "Minting has been halted.");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 10, "You may not buy more than 10 NFTs at once");
        require((totalSupply() + numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require((getNFTPrice() * numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = totalSupply(); 
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of "randomness". Theoretically miners could influence this but not worried for the scope of this project
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }
    
    /**
     * @dev Called after the sale ends or reveal period is over
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        

        uint256 _start = uint256(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        if ((block.number - _start) > 255) {
            _start = uint256(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        if (_start == 0) {
            _start = _start + 1;
        }
        
        startingIndex = _start;
    }

    /**
     * @dev Admin only mint function. Last resort to fix any issues after deployment
    **/
    function mint(address to, uint256 idx) public onlyOwner nonReentrant {
        _safeMint(to, idx);
    }

    /**
     * @dev Admin only burn function. Last resort to fix any issues after deployment
    **/
    function burn(uint256 idx) public onlyOwner nonReentrant {
        _burn(idx);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Halt minting 
    */
    function setHaltMint(bool v) public onlyOwner {
        halt_mint = v;
    }

    /**
     * @dev Halt claims 
    */
    function setHaltClaim(bool v) public onlyOwner {
        halt_claim = v;
    }
}