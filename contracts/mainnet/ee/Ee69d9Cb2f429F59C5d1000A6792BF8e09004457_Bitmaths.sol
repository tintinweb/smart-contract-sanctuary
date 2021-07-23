// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Bitmaths is ERC721, ERC721Enumerable, Ownable {
    
    string public constant BITMATHS_PROVENANCE = "dcbeba80a2c080466964acad724e0d2bfe54b83bb7730d1443425be91e54e762";
    uint256 public constant MAX_NFT_SUPPLY = 64;
    uint256 public constant MAX_PURCHASABLE_NFT_SUPPLY = 61;
    uint256 private constant SECRET_REQUISIT_INDEX = 43;
    address public constant PHI_TAUS_EGG = 0x0a6b94dE308C0222408e84A4c8bA8bDBC2EE6C01;
    uint256 private constant VERIFICATION_SOLVED_MASK = 0x0000000100100100100101000001000010000000000100000000000000100011;
    uint256 private constant WINDOW_SIZE = 86400;
    
    uint256 public stakeAmount = 40 * 10**18;
    uint256 public lockedTotalStake = 0;
    uint256 public unlockedTotalStake = 0;
    
    // Initiall set to staking expiration, but reset to guessing begining upon sale of the 61st NFT
    uint256 public guessingBeginsTimestamp = 1629504000;
    
    // Which piece will become tokenID = 0. This is set to a random value 0 to 60 upon sale of the 61st NFT.
    uint256 public startingIndex = 65;
    
    // 64 4-bit codes. Common = 0, Uncommon = 2, Rare = 4, Epic_unsolved = 6, Legendary = 8, Epic_solved = 7 in order of preTokenIndex from right to left
    uint256 public nftRarities = 0x8840042642640620600646044206400262404200220604220400002000620266;

    // Mapping stakeholder address to their stake in the project
    struct Stake {
        uint128 amountStaked;
        uint128 amountNFTs;
    }
    mapping (address => Stake) public stakes;
    
    struct Guess {
        uint8 guessTokenId;
        uint16 guess;
        address rewardAddress;
        uint32 timestamp;
    }
    
    // The array to store the guesses submitted by each piece
    Guess[MAX_NFT_SUPPLY] private guesses;

    bytes32 private secretMintCodeHash = 0x0aadf7eaabe5d56139de8e76813c132769e31f1738b8633e8376ae55330c9de3;
    
    event StakingFeeChanged(uint256 _stakeAmount);
    
    // -----
    
    constructor() ERC721("8Bitmaths", "8BM") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmd8hZV3CcfGpc3AAd5Qgcmxhpd2qugTKVDFxwdDtNnsRk/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        require(totalSupply() >= MAX_PURCHASABLE_NFT_SUPPLY);

        return super.tokenURI(preTokenIndexFromTokenId(tokenId));
    }
    
    function contractURI() public pure returns (string memory) {
        return "https://phitau1016.com/8bitmaths/contract/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    // -----
    
    function preTokenIndexFromTokenId(uint256 tokenId) private view returns (uint256) {
        return tokenId < MAX_PURCHASABLE_NFT_SUPPLY ? (tokenId + startingIndex) % MAX_PURCHASABLE_NFT_SUPPLY : tokenId;
    }
    
    function tokenIdFromPreTokenIndex(uint256 preTokenIndex) private view returns (uint256) {
        return preTokenIndex < MAX_PURCHASABLE_NFT_SUPPLY ? (MAX_PURCHASABLE_NFT_SUPPLY + preTokenIndex - startingIndex) % MAX_PURCHASABLE_NFT_SUPPLY : preTokenIndex;
    }
    
    function tokenRarity(uint256 tokenId) private view returns (uint256) {
        return (nftRarities >> (4*preTokenIndexFromTokenId(tokenId))) & 15;
    }
    
    function timestampDay(uint256 _timestamp) private pure returns (uint256) {
        // returns the integer number of days since 0:00 UTC Saturday Januray 3 1970 for _timestamp
        return _timestamp/WINDOW_SIZE - 2;
    }
    
    function timestampDayCode(uint256 _timestamp) private pure returns (uint256) {
        // what day of the week is _timestamp. Sat = 0, Sun = 1 etc.
        return timestampDay(_timestamp) % 7;
    }
    
    function getNow() public view returns (uint) {
        // this function is an artifact of testing, with the testing logic removed, but still used throughout to get the current timestamp
        return block.timestamp;
    }
    
    function allEpicsSolved() private view returns (bool) {
        return nftRarities & VERIFICATION_SOLVED_MASK == VERIFICATION_SOLVED_MASK;
    }
    
    function noPendingGuesses() private view returns (bool){
        for(uint i = 0; i < MAX_NFT_SUPPLY; i++) {
            if(guesses[i].timestamp != 0) {
                return false;
            }
        }
        return true;
    }
    
    function tokenHasRewardAvailable(uint256 tokenId) public view returns (bool) {
       if(guesses[tokenId].timestamp == 0) {
           return false;
       } else {
           return timestampDay(getNow()) - timestampDay(guesses[tokenId].timestamp) >= 2;
       }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance - unlockedTotalStake;
    }
    
    function getPhaseCode() external view returns (uint256, uint256) {
        // A quick way to get the current state of the contract for the front end
        return ((totalSupply()<MAX_PURCHASABLE_NFT_SUPPLY?32:0) + (getNow()<guessingBeginsTimestamp?16:0) + (stakeAmount>0?8:0) + (allEpicsSolved()?4:0) + (noPendingGuesses()?2:0) + (totalSupply()>62?1:0), getNow());
    }
    
    // ----- Staking Phase
    
    /**
    * @dev Mints 8bitmaths
    */
    function stakeAClaim(uint256 numberOfNfts) public payable {
        require(totalSupply()+numberOfNfts <= MAX_PURCHASABLE_NFT_SUPPLY, "All 8bitmaths have been claimed");
        require(stakeAmount*numberOfNfts == msg.value, "Ether value sent is not correct");
        require(msg.value > 0);

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        stakes[msg.sender].amountStaked += uint128(msg.value);
        stakes[msg.sender].amountNFTs += uint128(numberOfNfts);
        lockedTotalStake +=  msg.value;
        
        if(totalSupply() == MAX_PURCHASABLE_NFT_SUPPLY) {
            startingIndex = uint256(keccak256(abi.encodePacked(getNow(), block.difficulty)))%MAX_PURCHASABLE_NFT_SUPPLY; // select a random piece to be Id 0 and hence randomizing the order
            uint secondsIntoWeek = getNow() % 604800; // how many seconds into the week are we right now (week starts at 0:00 Thursday UTC)
            uint secondsToSaturday = (secondsIntoWeek<172800)?172800:777600; // If less than 2 days into the week, than less than 2 days until next Saturday, otherwise more than 2 days until the next Saturday
            guessingBeginsTimestamp = getNow() - secondsIntoWeek + secondsToSaturday; // 0:00 the very next Saturday
        }
    }
    
    function changeStakeAmount(uint256 newAmount) onlyOwner external {
        _changeStakeAmount(newAmount);
    }
    
    function _changeStakeAmount(uint256 newAmount) private {
        require(newAmount < stakeAmount);
        require(totalSupply() < MAX_PURCHASABLE_NFT_SUPPLY);
        uint256 newLockedTotalStake = newAmount * totalSupply();
        unlockedTotalStake = unlockedTotalStake + lockedTotalStake - newLockedTotalStake;
        lockedTotalStake = newLockedTotalStake;
        stakeAmount = newAmount;
        if (newAmount == 0) {
            burnAll();
        }
        emit StakingFeeChanged(newAmount);
    }
    
    // only called when the stakeAmount is changed to 0, which only happens when the project is terminated. Everybody gets there money back, but no NFTs will be owned.
    function burnAll() private {
        while(totalSupply() > 0) {
            uint256 _tokenId = tokenByIndex(0);
            _burn(_tokenId);
        }
    }
    
    function claimUnlockedStake() external {
        uint256 claimAmount = stakes[msg.sender].amountStaked - stakeAmount * stakes[msg.sender].amountNFTs;
        require(claimAmount  > 0, "You have no unlocked stake");
        payable(msg.sender).transfer(claimAmount);
        unlockedTotalStake -= claimAmount;
        stakes[msg.sender].amountStaked -= uint128(claimAmount);
    }
    
    function terminateUponExpiration() external {
        require(totalSupply() < MAX_PURCHASABLE_NFT_SUPPLY, "All 8bitmaths were claimed");
        require(getNow() > guessingBeginsTimestamp, "Staking phase has not expired");
        require(stakeAmount > 0, "Staking was already terminated");
        _changeStakeAmount(0);
    }
    
    function mintSecret(string memory _secretMintCode) external {
        require(totalSupply() >= MAX_PURCHASABLE_NFT_SUPPLY, "Not all tokens minted");
        require(msg.sender == ownerOf(tokenIdFromPreTokenIndex(SECRET_REQUISIT_INDEX)), "You must own the right token");
        require(keccak256(abi.encodePacked(_secretMintCode)) == secretMintCodeHash, "Incorrect Mint Code");
        _safeMint(msg.sender,MAX_PURCHASABLE_NFT_SUPPLY);
    }
    
    // ----- Search for Keys Phase
    
    function submitGuess(uint256 ownerTokenId, uint8 guessTokenId, uint16 guess, address rewardAddress) external {
        require(startingIndex < 65, "Not all 8bitmaths minted yet");
        require(msg.sender == ownerOf(ownerTokenId), "You don't own this token");
        require(tokenRarity(guessTokenId) == 6, "Must guess on unsolved Epic");
        uint256 _currentDayCode = timestampDayCode(getNow());
        require(_currentDayCode <= 4 && _currentDayCode%2 == 0 && _currentDayCode <= tokenRarity(ownerTokenId) && getNow() > guessingBeginsTimestamp, "Not your 8bitmaths guessing day");
        require(guesses[ownerTokenId].timestamp == 0, "Your 8bitmaths has a guess pending");
        require(guesses[guessTokenId].timestamp == 0 || guesses[guessTokenId].guessTokenId != guessTokenId, "Epic owner has guessed on their token");
        require(guess < 2048, "Not a valid guess");
        guesses[ownerTokenId] = Guess(guessTokenId, guess, rewardAddress, uint32(getNow()));
    }
    
    function getGuesses() external view returns (Guess[MAX_NFT_SUPPLY] memory) {
        return guesses;
    }
    
    function verifyGuesses(uint256 verificationCode) onlyOwner external {
        // guesses are verified off chain. The off chain verification server calls getGuesses, processes these guesses according to the rules, creates the verificationCode, calls verifyGuesses with the verification code
        require(timestampDayCode(getNow())%2==1); //must be a verification day
        require(startingIndex < MAX_PURCHASABLE_NFT_SUPPLY);
        // verificationCode is in preTokenIndex order from right to left in 4 bit chunks
        for(uint i = 0; i < MAX_NFT_SUPPLY; i++) {
            if((verificationCode >> (4*i)) & 15 < 8) {
                delete guesses[tokenIdFromPreTokenIndex(i)];
            }
        }
        nftRarities = nftRarities | (verificationCode & VERIFICATION_SOLVED_MASK);
    }
    
    function claimReward(uint256 tokenId) external {
        // the mechanism will reward guesses that have been in the guesses array for more than 2 days. The only way a guess is deleted from the array is:
        //    if it is processed and determined incorrect, 
        //    if it is not processed because the owner guessed
        //    if it is not processed because an earlier guess was verified correct
        //    if it is more than 2 days old and the reward gets claimed
        require(tokenHasRewardAvailable(tokenId), "No reward avaiable for this 8bitmaths");
        payable(guesses[tokenId].rewardAddress).transfer(271828 * getBalance() / 10000000);
        delete guesses[tokenId];
    }
    
    function stockEgg() external {
        require(allEpicsSolved(), "Not all Epics solved");
        require(noPendingGuesses(), "There are 8bitmaths with pending rewards");
        payable(PHI_TAUS_EGG).transfer(getBalance() / 10);
        _safeMint(PHI_TAUS_EGG,MAX_NFT_SUPPLY-2);
        _safeMint(PHI_TAUS_EGG,MAX_NFT_SUPPLY-1);
    }
    
    // ----- Plundering Phase
    function withdraw() onlyOwner external {
        require(allEpicsSolved() && noPendingGuesses() && _exists(MAX_NFT_SUPPLY-2) && _exists(MAX_NFT_SUPPLY-1));
        payable(msg.sender).transfer(getBalance());
    }
}