pragma solidity ^0.5.0;

import './GenArtMultiMinter.sol';
import './GenArtMinterState.sol';

contract GenArtMinterCustom_DoodleLabs is GenArtMultiMinter, GenArtMinterState {
    using SafeMath for uint256;

    event AddWhitelist();
    event Redeem(uint256 projectId);

    mapping(uint256 => mapping(address => uint256)) public whitelist;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    modifier notRedemptionState(uint256 projectId) {
        require(uint256(state[projectId]) != uint256(SaleState.REDEMPTION), "can not purchase in redemption phase");
        _;
    }

    modifier onlyRedemptionState(uint256 projectId) {
        require(uint256(state[projectId]) == uint256(SaleState.REDEMPTION), "not in redemption phase");
        _;
    }

    constructor(address _genArtCore) GenArtMultiMinter(_genArtCore) public {}

    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount) {
        return whitelist[projectId][user];
    }

    function setStateFamilyCollectors(uint256 projectId) public onlyWhitelisted {
        _setStateFamilyCollectors(projectId);
    }

    function setStateRedemption(uint256 projectId) public onlyWhitelisted {
        _setStateRedemption(projectId);
    }

    function setStatePublic(uint256 projectId) public onlyWhitelisted {
       _setStatePublic(projectId);
    }

    function setPurchaseManyLimit(uint256 projectId, uint256 limit) public onlyWhitelisted {
        _setPurchaseManyLimit(projectId, limit);
    }

    function addWhitelist(uint256 projectId, address[] memory users, uint256[] memory amounts) public onlyWhitelisted {
        require(users.length == amounts.length, 'users amounts array mismatch');

        for (uint i = 0; i < users.length; i++) {
            whitelist[projectId][users[i]] = amounts[i];
        }
        emit AddWhitelist();
    }

    function purchaseMany(uint256 projectId, uint256 amount) public payable notRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        return _purchaseMany(projectId, amount);
    }

    function purchase(uint256 _projectId) public payable notRedemptionState(_projectId) returns (uint256 _tokenId) {
        if (uint256(state[_projectId]) == uint256(SaleState.FAMILY_COLLECTORS) && msg.value > 0) {
            require(false, 'ETH not accepted at this time');
        }
        return _purchase(_projectId);
    }

    function redeemMany(uint256 projectId, uint256 amount) public payable returns (uint256[] memory _tokenIds) {
        require(amount <= purchaseLimit[projectId], 'Max purchase many limit reached');
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
        require(whitelist[projectId][to] > 0, "user has nothing to redeem");
        whitelist[projectId][to] = whitelist[projectId][to].sub(1);
        emit Redeem(projectId);
        return purchaseTo(to, projectId, isDeferredRefund);
    }

}