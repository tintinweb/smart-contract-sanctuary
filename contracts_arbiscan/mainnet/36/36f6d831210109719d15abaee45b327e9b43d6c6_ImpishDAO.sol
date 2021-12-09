// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// Interface to the RandomWalkNFT contract.
abstract contract IRandomWalkNFT is IERC721 {
    uint256 public numWithdrawals;
    address public lastMinter;
    uint256 public lastMintTime;
    uint256 public nextTokenId;

    function mint() public virtual payable;
    function withdraw() public virtual;

    function getMintPrice() public virtual view returns (uint256);
    function timeUntilWithdrawal() public virtual view returns (uint256);
}

contract ImpishDAO is ERC20, ERC20Burnable, Ownable, IERC721Receiver, ReentrancyGuard {
    // How many ERC20 tokens per ETH.
    uint public constant MINT_RATIO = 1000;

    // The minimum price that the NFT will be sold
    // Note that even though it says 1 ether, it is actual 1 IMPISH tokens, 
    // since IMPISH also has 18 decimals
    uint256 public constant NFT_MIN_PRICE = 1 * 1 ether;

    // The price of secondary sales by the DAO decays over this time linearly. 
    uint256 private constant ONE_MONTH = 30 * 24 * 3600;

    // The (hard-coded) Randomwalk NFT round that we're playing. If we want to play
    // another round, we'll deploy another contract. 
    uint256 public constant RWNFT_ROUND = 0;

    // Interface to the underlying NFT contract. Filled in the constructor
    IRandomWalkNFT public rwNFT;

    // The state that the contract is in. Starts off PAUSED
    // PAUSED = 0;      // Contract has been paused, No minting, only withdrawal. Will be used in an emergency
    // PLAYING = 1;     // DAO is playing the game with RandomWalkNFT
    // FINISHED_WIN = 2;    // This round of RandomWalkNFT has finished, and the DAO won
    // FINISHED_LOST = 3;   // This round of RandomWalkNFT has finished, and the DAO lost.
    uint8 public contractState = 0;

    // Event for when NFT is available for sale or sold
    // tokenID, startPrice, forSale
    event NFTForSaleTx(uint256, uint256, bool);
    struct NFTForSale {
        uint256 startTime;      // When the NFT was first available, used to determine price
        uint256 startPrice;     // in IMPISH tokens.
    }
    mapping(uint256 => NFTForSale) public forSale;

    constructor(address _rwNFTaddress) ERC20("ImpishDAO", "IMPISH") {
        rwNFT = IRandomWalkNFT(_rwNFTaddress);

        // The contract is playable as soon as it is deployed. 
        contractState = 1;
    }    

    // Pause is a one-way function. Can't unpause it. 
    function pause() public onlyOwner {
        contractState = 0;
    }

    // Modifiers
    modifier whenNotPaused() {
        require(contractState != 0, "Paused");
        _;
    }
    
    modifier whenPlaying() {
        require(contractState == 1, "NotPlaying");
        _;
    }

    // Returns if the last minter of the RandomWalkNFT is us. 
    function areWeWinning() public view returns(bool) {
        return rwNFT.lastMinter() == address(this);
    }

    // For safety, the contract limits how much ETH it holds. It is higher of
    // 100 ether or
    // 10 times the next mint price
    function getMaxEth() public view returns(uint256) {
        uint256 maxETH = rwNFT.getMintPrice() * 10;
        if (maxETH < 100 ether) {
            maxETH = 100 ether;
        }

        return maxETH;
    }

    // How much additional ETH the contract can accept. 
    // Note, if you call this inside a payable function, this will include the msg.value 
    // of that function, so it might not be exactly what you're expecting. 
    function getMaxEthThatCanBeDeposit() public view returns(uint256) {
        uint256 maxEth = getMaxEth();

        if (address(this).balance >= maxEth) {
            return 0;
        } else {
            return maxEth - address(this).balance;
        }
    }

    // What is the price (in IMPISH tokens) that the given tokenID is available for purchase.
    function buyNFTPrice(uint256 tokenID) public view returns (uint256) {
        uint256 startTime = forSale[tokenID].startTime;
        uint256 startPrice = forSale[tokenID].startPrice;

        require(startTime > 0, "TokenID not owned");
        
        uint256 elapsedTime = block.timestamp - startTime;
        
        if (elapsedTime >= ONE_MONTH || startPrice < NFT_MIN_PRICE) {
            // Don't let price fall below the minimum price of NFT sales.
            return NFT_MIN_PRICE;
        } else {
            // Linearly decays over a month
            return NFT_MIN_PRICE + (( (ONE_MONTH - elapsedTime) * (startPrice - NFT_MIN_PRICE) ) / ONE_MONTH );
        }
    }

    // Obtain the next Random Walk NFT. Internal, so needs to be called from deposit()
    function _mintNextRwNFT() internal whenPlaying {
        // Make sure that we're still paying the correct round
        require(rwNFT.numWithdrawals() == RWNFT_ROUND, "Not Playable");

        // If we're already winning, don't bid against ourselves
        require(!areWeWinning(), "Already winning");

        // Next mint price from the RandomWalkNFT contract
        uint256 mintPrice = rwNFT.getMintPrice();

        // The newly minted NFT will have this ID. 
        uint256 mintedNFTTokenId = rwNFT.nextTokenId();

        // Call into the other contract and mint it. Re-entrancy risk here is minimal, 
        // since this contract is not upgradable and this particular method doesn't do any 
        // funky stuff. 
        rwNFT.mint{value: mintPrice}();

        // And put it up for sale (assuming the mint succeeds). 
        // Starting price is 10x the mint price, and decreases to 0.0001 ETH over one month (Dutch Auction)
        // Remember to multiply by MINT_RATIO, because price is in IMPISH
        uint256 forSalePrice =  mintPrice * MINT_RATIO * 10;
        forSale[mintedNFTTokenId] = NFTForSale(block.timestamp, forSalePrice);
        
        // Emit event
        emit NFTForSaleTx(mintedNFTTokenId, forSalePrice, true);
    }

    // Buy a NFT from the contract. It will automatically deduct the price from the 
    // sender's balance. 
    function buyNFT(uint256 tokenID) public nonReentrant {
        uint256 price = buyNFTPrice(tokenID);

        // Ensure sender has enough tokens
        require(balanceOf(msg.sender) >= price, "Not enough IMPISH");
        
        // Burn the tokens and delete the item from the for-sale list
        _burn(msg.sender, price);
        delete forSale[tokenID];

        // Transfer to sender
        rwNFT.safeTransferFrom(address(this), msg.sender, tokenID);

        // Emit event
        emit NFTForSaleTx(tokenID, price, false);
    }

    // Deposit ETH into the contract and mint IMPISH tokens
    function deposit() public whenNotPaused whenPlaying nonReentrant payable {
        // For protection, don't accept too much ETH. Note that since this is a payable
        // function, address(this).balance already includes the ETH sent to this function. 
        require(address(this).balance <= getMaxEth(), "Too much ETH");

        // Mint tokens
        if (msg.value > 0) {
            address to = msg.sender;
            uint256 mintAmount = msg.value * MINT_RATIO;
            _mint(to, mintAmount);
        }

        // Check if the current round is active
        if (rwNFT.numWithdrawals() != RWNFT_ROUND) {
            // We lost, since the winner has claimed the winnings and the round has advanced
            contractState = 3;
            return;
        }

        // Check if there is any housekeeping to be done.
        if (rwNFT.timeUntilWithdrawal() == 0 && areWeWinning()) {
            // We Won! So withdraw the funds from the RandomWalkNFT contract. 
            rwNFT.withdraw();
            contractState = 2;

            return;
        }

        if (!areWeWinning()) {
            // Check if we have enough to mint the next NFT
            if (address(this).balance >= rwNFT.getMintPrice()) {
                _mintNextRwNFT();
                return;
            }       
        }
    }

    // If the round is finished or paused, allow redeeming IMPISH tokens for the contract's ETH. 
    function redeem() public nonReentrant {
        require(contractState != 1, "Can't redeem while playing");
        require(totalSupply() > 0, "Empty!");

        uint256 tokens = balanceOf(msg.sender);
        require(tokens > 0, "Nothing to redeem");
        
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract Empty!");

        uint256 toRedeem = tokens * address(this).balance / totalSupply();

        // Burn tokens,
        _burn(msg.sender, tokens);

        // Last, send ether back
        (bool success, ) = msg.sender.call{value: toRedeem}("");
        require(success, "Transfer failed.");
    }

    // Default payable function, so the contract can accept winnings via rwNFT.withdraw() 
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Function that marks this contract can accept incoming NFT transfers
    function onERC721Received(address, address, uint256 , bytes calldata) public view returns(bytes4) {
        // Only accept NFT transfers from RandomWalkNFT
        require(msg.sender == address(rwNFT), "NFT not recognized");

        // Return this value to accept the NFT
        return IERC721Receiver.onERC721Received.selector;
    }
}