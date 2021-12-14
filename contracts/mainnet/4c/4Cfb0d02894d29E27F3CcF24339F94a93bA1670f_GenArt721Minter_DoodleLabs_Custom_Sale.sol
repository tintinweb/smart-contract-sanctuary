pragma solidity ^0.5.0;

import './GenArt721Minter_DoodleLabs_MultiMinter.sol';

interface IGenArt721Minter_DoodleLabs_Config {
    function getPurchaseManyLimit(uint256 projectId) external view returns (uint256 limit);
    function getState(uint256 projectId) external view returns (uint256 _state);
    function setStateFamilyCollectors(uint256 projectId) external;
    function setStateRedemption(uint256 projectId) external;
    function setStatePublic(uint256 projectId) external;
}

interface IGenArt721Minter_DoodleLabs_WhiteList {
    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount);
    function addWhitelist(uint256 projectId, address[] calldata users, uint256[] calldata amounts) external;
    function decreaseAmount(uint256 projectId, address to) external;
}

contract GenArt721Minter_DoodleLabs_Custom_Sale is GenArt721Minter_DoodleLabs_MultiMinter {
    using SafeMath for uint256;

    event Redeem(uint256 projectId);

    // Must match what is on the GenArtMinterV2_State contract
    enum SaleState {
        FAMILY_COLLECTORS,
        REDEMPTION,
        PUBLIC
    }

    IGenArt721Minter_DoodleLabs_WhiteList public activeWhitelist;
    IGenArt721Minter_DoodleLabs_Config public minterState;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    modifier notRedemptionState(uint256 projectId) {
        require(uint256(minterState.getState(projectId)) != uint256(SaleState.REDEMPTION), "can not purchase in redemption phase");
        _;
    }

    modifier onlyRedemptionState(uint256 projectId) {
        require(uint256(minterState.getState(projectId)) == uint256(SaleState.REDEMPTION), "not in redemption phase");
        _;
    }

    constructor(address _genArtCore, address _minterStateAddress) GenArt721Minter_DoodleLabs_MultiMinter(_genArtCore) public {
        minterState = IGenArt721Minter_DoodleLabs_Config(_minterStateAddress);
    }

    function setActiveWhitelist(address whitelist) public onlyWhitelisted {
        activeWhitelist = IGenArt721Minter_DoodleLabs_WhiteList(whitelist);
    }

    function purchaseMany(uint256 projectId, uint256 amount) public payable notRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(amount <= minterState.getPurchaseManyLimit(projectId), 'Max purchase many limit reached');
        return _purchaseMany(projectId, amount);
    }

    function purchase(uint256 _projectId) public payable notRedemptionState(_projectId) returns (uint256 _tokenId) {
        if (uint256(minterState.getState(_projectId)) == uint256(SaleState.FAMILY_COLLECTORS) && msg.value > 0) {
            require(false, 'ETH not accepted at this time');
        }
        return _purchase(_projectId);
    }

    function redeemMany(uint256 projectId, uint256 amount) public payable onlyRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(amount <= minterState.getPurchaseManyLimit(projectId), 'Max purchase many limit reached');
        uint256[] memory tokenIds = new uint256[](amount);
        bool isDeferredRefund = false;

        // Refund ETH if user accidentially overpays
        // This is not needed for ERC20 tokens
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(projectId);
            uint256 refund = msg.value.sub(pricePerTokenInWei.mul(amount));
            isDeferredRefund = true;

            if (refund > 0) {
                msg.sender.transfer(refund);
            }
        }

        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = redeemTo(msg.sender, projectId, isDeferredRefund);
            emit Purchase(projectId);
        }

        return tokenIds;
    }

    function redeem(uint256 projectId) public payable onlyRedemptionState(projectId) returns (uint256 _tokenId) {
        return redeemTo(msg.sender, projectId, false);
    }

    function redeemTo(address to, uint256 projectId, bool isDeferredRefund) public payable onlyRedemptionState(projectId) returns (uint256 _tokenId) {
        activeWhitelist.decreaseAmount(projectId, to);
        emit Redeem(projectId);
        return purchaseTo(to, projectId, isDeferredRefund);
    }

}