// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

abstract contract Whelps {
    mapping (uint256 => uint256) public tokenIdToBirthBlockNumber;
    uint8[20] public odds6;
    function tokenURIComputedName(uint256 tokenId) public view virtual returns (string memory);
    function mint(address minter, uint256 mintIndex) public virtual returns (uint256);
}

abstract contract WhelpsProxy {
    function proxyTransferFrom(address from, address to, uint256 tokenId, uint256 approvedIndex) external virtual;
}

contract WhelpsStaking is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    // Setup constants
    uint256 public constant WAITING_TIME_CLAIM_BACK_STAKED = 3888000; // 45 * 24 * 3600
    uint256[] public WAITING_TIMES_EGG_CLAIMING = [
        3024000, // 35 * 24 * 3600
        2419200, // 28 * 24 * 3600
        1814400, // 21 * 24 * 3600
        1209600, // 14 * 24 * 3600
        604800, //  7 * 24 * 3600
        259200 //  3 * 24 * 3600
    ];

    // Contract enabled setup
    bool public stakingEnabled = false;

    function toggleStakingEnabled() external onlyOwner {
        stakingEnabled = !stakingEnabled;
    }

    // 7th breed contract setup 
    uint256 public _mintIndex = 0;
    address public _7thBreedContract = address(0);
    address public _whelpsProxyContract = address(0);
    uint256 public _whelpsProxyIndex;
    address public _whelpsNFTContract = address(0);

    function setWhelpsNFTContract(address _contract) external onlyOwner {
        require(_whelpsNFTContract == address(0));
        _whelpsNFTContract = _contract;
    }
    
    function set7thBreedContract(address _contract) external onlyOwner {
        require(_7thBreedContract == address(0));
        _7thBreedContract = _contract;
    }

    function setWhelpsProxyContract(address _contract, uint256 _index) external onlyOwner {
        require(_whelpsProxyContract == address(0));
        _whelpsProxyContract = _contract;
        _whelpsProxyIndex = _index;
    }

    // Staking

    struct StakingSet {
        address owner;
        uint256 timestamp;
        uint256[] tokenIds;
        uint256 tokenId;
        bool eggClaimed;
        bool tokensClaimed;
    }

    event Stake(address indexed _owner, uint256 indexed _stakingSetKey);
    event ClaimEgg(address indexed _owner, uint256 indexed _stakingSetKey, uint256 indexed _eggTokenId);
    event ClaimTokens(address indexed _owner, uint256 indexed _stakingSetKey);

    mapping (uint256 => bool) public tokenIdHasBeenStaked;
    mapping (uint256 => StakingSet) public keyToStakingSet;
    uint256 public lastStakingSetKey = 0;
    
    function tokenIdsFromStakingSet(uint256 stakingSetKey) public view returns (uint256[] memory) {
        uint256[] memory tokens = keyToStakingSet[stakingSetKey].tokenIds;
        return tokens;
    }

    function stake(uint256[] calldata tokenIds) external {
        // checks
        require(stakingEnabled, "Staking not enabled");
        require(tokenIds.length > 0 && tokenIds.length <= 6, "Wrong no of tokens");

        // transfer tokens to self and count breeds
        Whelps w = Whelps(_whelpsNFTContract);
        WhelpsProxy wp = WhelpsProxy(_whelpsProxyContract);
        uint8[6] memory breeds;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenIdHasBeenStaked[tokenIds[i]] == false, "Token already staked");

            wp.proxyTransferFrom(msg.sender, address(this), tokenIds[i], _whelpsProxyIndex);
            tokenIdHasBeenStaked[tokenIds[i]] = true;
            
            uint256 blockNo = w.tokenIdToBirthBlockNumber(tokenIds[i]);
            uint256 index_breed = w.odds6((uint256(keccak256(abi.encodePacked(tokenIds[i], blockNo))) % 20));
            
            breeds[index_breed] = 1;
        }
        
        require(breeds[0]+breeds[1]+breeds[2]+breeds[3]+breeds[4]+breeds[5] == tokenIds.length, "Duplicate breed");

        // setup staking info
        keyToStakingSet[lastStakingSetKey] = StakingSet({
            owner: msg.sender,
            timestamp: block.timestamp,
            tokenIds: tokenIds,
            tokenId: _mintIndex,
            eggClaimed: false,
            tokensClaimed: false
        });
        
        _mintIndex++;

        // emit event and update staking set key
        emit Stake(msg.sender, lastStakingSetKey);
        lastStakingSetKey++;
    }

    // Claim egg and tokens

    function claimEgg(uint256 stakingSetKey) external {
        // checks
        require(keyToStakingSet[stakingSetKey].owner == msg.sender, "Unauthorized");
        require(keyToStakingSet[stakingSetKey].eggClaimed == false, "Already claimed");
        require(block.timestamp > keyToStakingSet[stakingSetKey].timestamp + WAITING_TIMES_EGG_CLAIMING[keyToStakingSet[stakingSetKey].tokenIds.length-1], "Too early");

        // mint egg and mark as claimed
        Whelps breed7NFT = Whelps(_7thBreedContract);
        uint256 eggTokenId = breed7NFT.mint(msg.sender, keyToStakingSet[stakingSetKey].tokenId);
        keyToStakingSet[stakingSetKey].eggClaimed = true;

        // emit event for further reference
        emit ClaimEgg(msg.sender, stakingSetKey, eggTokenId);
    }

    function claimStakedTokens(uint256 stakingSetKey) external {
        // checks
        require(keyToStakingSet[stakingSetKey].owner == msg.sender, "Unauthorized");
        require(keyToStakingSet[stakingSetKey].tokensClaimed == false, "Already claimed");
        require(block.timestamp > keyToStakingSet[stakingSetKey].timestamp + WAITING_TIMES_EGG_CLAIMING[keyToStakingSet[stakingSetKey].tokenIds.length-1] + WAITING_TIME_CLAIM_BACK_STAKED, "Too early");

        // mint egg and mark as claimed
        ERC721 whelpsNFT = ERC721(_whelpsNFTContract);
        for (uint i = 0; i < keyToStakingSet[stakingSetKey].tokenIds.length; i++) {
            whelpsNFT.transferFrom(address(this), msg.sender, keyToStakingSet[stakingSetKey].tokenIds[i]);
        }

        keyToStakingSet[stakingSetKey].tokensClaimed = true;

        // emit event for further reference
        emit ClaimTokens(msg.sender, stakingSetKey);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}