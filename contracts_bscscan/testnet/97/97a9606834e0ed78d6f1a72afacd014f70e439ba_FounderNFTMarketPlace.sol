// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Initializable.sol";
import "./IERC721Upgradeable.sol";
import "./IAddFounderNFTForSale.sol";
import "./IERC721ReceiverUpgradeable.sol";

contract FounderNFTMarketPlace is Initializable, PausableUpgradeable, OwnableUpgradeable, IAddFounderNFTForSale, IERC721ReceiverUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // shard price
    uint256 private _founderNFTPrice;

    // used for what token should be used for purchasing a sealed nft
    address private _tokenAddress;

    // used for receiving the token (REWARDS AND POOL CONTRA)
    address private _rewardPoolAddress;

    //mapping if the wallet is whitelisted
    mapping(address => bool) private whiteListed;
    event UpdateWhiteListMultipleAccounts(address[] accounts, bool isWhiteListed );

    uint256[] private _founderNFTTokenId;
    mapping(uint256 => bool) private _founderNFTTokenIdMap;

    // address of nft contract
    address private nftContract;

    event SoldFounderNFT(address account, uint256 tokenId, uint256 founderPrice);

    uint256 public totalSold;

    mapping(address => bool) public userAlreadyBuy;

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();

        _founderNFTPrice = 0; // founder nft price
    }

    // token address
    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address _token) external onlyOwner {
        _tokenAddress = _token;
    }

    // nft contract address
    function nftContractAddress() external view returns (address) {
        return nftContract;
    }

    function setNFTContractAddress(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }

    // pause
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function founderNFTPrice() external view returns (uint256) {
        return _founderNFTPrice;
    }

    function setFounderNFTPrice(uint256 founderNFTPrice_) public onlyOwner {
        _founderNFTPrice = founderNFTPrice_;
    }

    function getFounderNFTTokensLength() external view returns (uint256) {
        return _founderNFTTokenId.length;
    }

    // reward pool address
    function rewardPoolAddress() external view returns (address) {
        return _rewardPoolAddress;
    }

    function setRewardPoolAddress(address _rewardPool) external onlyOwner {
        _rewardPoolAddress = _rewardPool;
    }

    function buyFounderNFT() external whenNotPaused {
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");
        require(_founderNFTPrice > 0,"Founder NFT Price is not set");
        require(nftContract != address(0),"NFT Contract Address is not set");
        require(whiteListed[_msgSender()] == true, "Your wallet is not whitelisted for buying founder nft");
        require(_founderNFTTokenId.length > 0, "No Founder NFT To Buy");
        require(userAlreadyBuy[_msgSender()]==false,"Wallet is already buy founder nft");
        
        uint256 founderPrice = _founderNFTPrice.mul(1);
        
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=founderPrice,"Token amount allowance is not enough to buy founder NFT");

        uint256 tokenId = _founderNFTTokenId[_founderNFTTokenId.length - 1]; // get the last token id from the list
        delete _founderNFTTokenId[_founderNFTTokenId.length - 1]; // removed the last token id from the list

        totalSold = totalSold.add(1);

        _founderNFTTokenIdMap[tokenId] = false;

        whiteListed[_msgSender()] = false; // removed from whitelist once the wallet successfully buy

        userAlreadyBuy[_msgSender()] = true; // set already buy

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, founderPrice);

        // transfer nft to wallet
        IERC721Upgradeable(nftContract).approve(_msgSender(), tokenId);

        IERC721Upgradeable(nftContract).safeTransferFrom(address(this), _msgSender(), tokenId);

        emit SoldFounderNFT(_msgSender(), tokenId, founderPrice);          
    }

    function addFounderNFTToList(uint256 tokenId) public virtual override {
        require(nftContract==_msgSender(),"Not called by nft contract");
        require(_founderNFTTokenIdMap[tokenId] == false,"Already Added");
        
        
        _founderNFTTokenId.push(tokenId);

        _founderNFTTokenIdMap[tokenId] = true;
    }

    function updateWhiteListMultipleAccounts(address[] calldata accounts, bool _isWhiteListed ) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            whiteListed[accounts[i]] = _isWhiteListed;
        }

        emit UpdateWhiteListMultipleAccounts(accounts, _isWhiteListed);
    }

    function isWhiteListed(address account) public view returns(bool) {
        return whiteListed[account];
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4){
        require(nftContract != address(0),"NFT Contract Address is not set");
        require(operator!=address(0),"Operator is address 0");
        require(tokenId>=0,"Invalid token id");
        require(data.length>=0,"Invalid data");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

  
}