/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Staking is ERC721Holder, ERC1155Holder, Ownable {
    address public whaleMakerAddress = 0xA87121eDa32661C0c178f06F8b44F12f80ae4E88;
    address public alphaPassAddress = 0xABC550e4Bff18e37c04083dCae2AcF77B6bE6CAd;
    address public podAddress = 0x5B3E42382C3AaAd8Ff9e106664E362C308CBa3BC;
    address public stakeMasterAddress = 0xDBef1bbCb494fAcd6cD1BF426e25dA7A10d96eAa;
    address nullAddress = 0x0000000000000000000000000000000000000000;

    uint256 public maxWalletStaked = 10;

    uint256 public contractPublishedAt = block.timestamp;

    // Mapping of WHALE/ALPHA TokenId to timestamp
    mapping(uint256 => uint256) public tokenIdToStakeTime;
    mapping(uint256 => uint256) public tokenIdToLastClaimTime;

    // Mapping of WHALE/ALPHA TokenId to staker
    mapping(uint256 => address) _tokenIdToStaker;

    // Mapping of staker to WHALE/ALPHA TokenIds
    mapping(address => uint256[]) _stakerToTokenIds;

    uint256[] private _stakedTokenIds;

    uint256 public claimStartTime = 1672531199; // Dec 31 2022 11:59:59 PM

    /**
     * [ Dec 31 2022 11:59:59 PM, Dec 31 2023 11:59:59 PM, Dec 31 2024 11:59:59 PM, Dec 31 2025 11:59:59 PM, Dec 31 2026 11:59:59 PM, Dec 31 2027 11:59:59 PM, Dec 31 2031 11:59:59 PM ]
    */
    uint256[] public rewardsStepsTimestamp = [1672531199, 1704067199, 1735689599, 1767225599, 1798761599, 1830297599, 1956527999]; 
    mapping(uint256 => uint256) public rewardsStepsMonthlyAmount;

    constructor() {
        rewardsStepsMonthlyAmount[1672531199] = 4500; // Till Dec 31 2022 11:59:59 PM
        rewardsStepsMonthlyAmount[1704067199] = 3500;
        rewardsStepsMonthlyAmount[1735689599] = 2500;
        rewardsStepsMonthlyAmount[1767225599] = 1500;
        rewardsStepsMonthlyAmount[1798761599] = 1000;
        rewardsStepsMonthlyAmount[1830297599] = 500;
        rewardsStepsMonthlyAmount[1956527999] = 250;
    }

    function stakedTokenIds() public view returns (uint256[] memory) {
        return _stakedTokenIds;
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return _stakerToTokenIds[staker];
    }

    function _remove(address staker, uint256 index) internal {
        if (index >= _stakerToTokenIds[staker].length) return;

        for (uint256 i=index; i<_stakerToTokenIds[staker].length-1; i++) {
            _stakerToTokenIds[staker][i] = _stakerToTokenIds[staker][i + 1];
        }
        _stakerToTokenIds[staker].pop();
    }

    function _removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i=0; i<_stakerToTokenIds[staker].length; i++) {
            if (_stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                _remove(staker, i);
            }
        }
    }

    function _removeItem(uint256 index) internal {
        if (index >= _stakedTokenIds.length) return;
        for (uint256 i=index; i<_stakedTokenIds.length-1; i++) {
            _stakedTokenIds[i] = _stakedTokenIds[i+1];
        }
        _stakedTokenIds.pop();
    }

    function _removeStakedTokenId(uint256 tokenId) internal {
        for (uint256 i=0; i<_stakedTokenIds.length; i++) {
            if (_stakedTokenIds[i] == tokenId) {
                _removeStakedTokenId(i);
            }
        }
    }

    function _calculateRewardsById(uint256 tokenId) internal view returns (uint256) {
        require (_tokenIdToStaker[tokenId] != nullAddress, "NOT_STAKED_TOKEN");
        uint256 rewards = 0;
        uint256 staked_days; // The token staked days in this step
        uint256 startTs = tokenIdToLastClaimTime[tokenId] + 1; // The timestamp that the step started
        for (uint256 i=0; i<rewardsStepsTimestamp.length; i++) {
            if (rewardsStepsTimestamp[i] < block.timestamp) {
                if (tokenIdToStakeTime[tokenId] < rewardsStepsTimestamp[i]) { // if token was staked in the step
                    staked_days = (rewardsStepsTimestamp[i] - startTs) / 86400; 
                    rewards = rewards + staked_days * rewardsStepsMonthlyAmount[rewardsStepsTimestamp[i]] * 10 ** 18 / 30;
                    startTs = rewardsStepsTimestamp[i] + 1;
                }
            } else { // the current step
                staked_days = block.timestamp - startTs;
                rewards = rewards + staked_days * rewardsStepsMonthlyAmount[rewardsStepsTimestamp[i]] * 10 ** 18 / 30;
                break; // Ignore the next steps
            }
        }
        return rewards;
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(_stakerToTokenIds[msg.sender].length + tokenIds.length <= maxWalletStaked, "EXCEED_MAX_WALLET_STAKED");
        for (uint256 i=0; i<tokenIds.length; i++) {
            require(
                IERC721(whaleMakerAddress).ownerOf(tokenIds[i]) == msg.sender && IERC1155(alphaPassAddress).balanceOf(msg.sender, tokenIds[i]) > 0 && _tokenIdToStaker[tokenIds[i]] == nullAddress,
                "NOT_BOTH_TOKEN_OWNER"
            );
            IERC721(whaleMakerAddress).safeTransferFrom(msg.sender, stakeMasterAddress, tokenIds[i]);
            IERC1155(alphaPassAddress).safeTransferFrom(msg.sender, stakeMasterAddress, tokenIds[i], 1, "");
            _stakerToTokenIds[msg.sender].push(tokenIds[i]);
            tokenIdToStakeTime[tokenIds[i]] = block.timestamp;
            tokenIdToLastClaimTime[tokenIds[i]] = block.timestamp;
            _tokenIdToStaker[tokenIds[i]] = msg.sender;
            _stakedTokenIds.push(tokenIds[i]);
        }
    }

    function _unstakeTokenId(uint256 tokenId) internal {
        IERC721(whaleMakerAddress).safeTransferFrom(stakeMasterAddress, msg.sender, tokenId);
        IERC1155(alphaPassAddress).safeTransferFrom(stakeMasterAddress, msg.sender, tokenId, 1, "");
        _removeTokenIdFromStaker(msg.sender, tokenId);
        _removeStakedTokenId(tokenId);
        _tokenIdToStaker[tokenId] = nullAddress;
    }
    
    function unstakeByIds(uint256[] memory tokenIds) public {
        require(claimStartTime < block.timestamp, "DISABLED_CLIAM");
        // Get Total Rewards
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenIdToStaker[tokenIds[i]] == msg.sender, "NOT_VALID_STAKER");
            totalRewards = totalRewards + _calculateRewardsById(tokenIds[i]);
        }
        
        require(totalRewards < IERC20(podAddress).balanceOf(stakeMasterAddress), "NOT_ENOUGH_BALANCE_ON_CONTRACT");

        // Unstake all Whale/AP tokens
        for (uint256 i=0; i<tokenIds.length; i++) {
            _unstakeTokenId(tokenIds[i]);
        }

        // Transfer rewards
        IERC20(podAddress).transferFrom(stakeMasterAddress, msg.sender, totalRewards);
    }

    function unstakeAll() public {
        require(_stakerToTokenIds[msg.sender].length > 0, "ZERO_STAKED_TOKEN");
        unstakeByIds(_stakerToTokenIds[msg.sender]);
    }

    function claimByTokenIds(uint256[] memory tokenIds) public {
        require(claimStartTime < block.timestamp, "DISABLED_CLIAM");
        // Get Total Claim ammount
        uint256 totalRewards = 0;
        for (uint256 i=0; i<tokenIds.length; i++) {
            require(_tokenIdToStaker[tokenIds[i]] == msg.sender, "NOT_VALID_STAKER");
            totalRewards = totalRewards + _calculateRewardsById(tokenIds[i]);
        }
        
        require(totalRewards < IERC20(podAddress).balanceOf(stakeMasterAddress), "NOT_ENOUGH_BALANCE_ON_CONTRACT");
        IERC20(podAddress).transferFrom(stakeMasterAddress, msg.sender, totalRewards);

        for (uint256 i=0; i<tokenIds.length; i++) {
            tokenIdToLastClaimTime[tokenIds[i]] = block.timestamp;
        }
    }

    function claimAll() public {
        require(_stakerToTokenIds[msg.sender].length > 0, "ZERO_STAKED_TOKEN");
        claimByTokenIds(_stakerToTokenIds[msg.sender]);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = _stakerToTokenIds[staker];
        uint256 totalRewards = 0;
        for (uint256 i=0; i<tokenIds.length; i++) {
            totalRewards = totalRewards + _calculateRewardsById(tokenIds[i]);
        }
        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId) public view returns (uint256) {
        require(_tokenIdToStaker[tokenId] != nullAddress, "Token is not staked!");
        return _calculateRewardsById(tokenId);
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return _tokenIdToStaker[tokenId];
    }
    
    function setWhaleMakerAddress(address newAddress) public onlyOwner {
        whaleMakerAddress = newAddress;
    }
    function setAlphaPassAddress(address newAddress) public onlyOwner {
        alphaPassAddress = newAddress;
    }
    function setPodAddress(address newAddress) public onlyOwner {
        podAddress = newAddress;
    }
    function setStakeMasterAddress(address newAddress) public onlyOwner {
        stakeMasterAddress = newAddress;
    }
    function setMaxWalletStaked(uint256 newValue) public onlyOwner {
        maxWalletStaked = newValue;
    }
    function setClaimStartTime(uint256 newClaimStartTime) public onlyOwner {
        claimStartTime = newClaimStartTime;
    }
    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, "NO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }
}