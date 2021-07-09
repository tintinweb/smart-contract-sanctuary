pragma solidity 0.8.0;

import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";

contract ClaimApp is DataStorage, Access, Events, Manageable {
    using SafeMath for uint256;

    constructor(address payable _feeWallet) public {
        owner = msg.sender;
        feeWallet = _feeWallet;
        reentryStatus = ENTRY_ENABLED;
    }

    function setAddTokenClaimFee(uint256 _fee) external onlyAdmins {
        addTokenClaimFee = _fee;
    }

    function setClaimFee(uint256 _fee) external onlyAdmins {
        claimFee = _fee;
    }

    function stopCampaign(uint256 campaignId, address _token) external {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.owner == msg.sender,
            "Required: Only owner can change status"
        );
        Campaign[] storage currentCampaigns = bep20Tokens[_token].campaigns;
        for (uint256 index = 0; index < currentCampaigns.length; index++) {
            if(currentCampaigns[index].id == campaignId) {
                currentCampaigns[index].isStopped =  true;
            }
        }
        for (uint256 index = 0; index < totalCampaigns.length; index++) {
            if(totalCampaigns[index].id == campaignId) {
                totalCampaigns[index].isStopped =  true;
            }
        }
        campaigns[campaignId].isStopped = true;
    }

    function setFeeWallet(address payable _feeWallet) external onlyAdmins {
        feeWallet = _feeWallet;
    }

    function addTokenClaim(
        address _token,
        uint256 _totalAirdrop,
        uint256 _amountPerClaim,
        string calldata _nameCampaign
    ) external payable blockReEntry() {
        _addTokenClaim(
            _token,
            _totalAirdrop,
            _amountPerClaim,
            _nameCampaign,
            msg.sender,
            msg.value
        );
    }

    function _addTokenClaim(
        address _bep20,
        uint256 _totalAirdrop,
        uint256 _amountPerClaim,
        string calldata _nameCampaign,
        address userAddress,
        uint256 _amount
    ) internal {
        IBEP20 claimToken = IBEP20(_bep20);
        require(
            claimToken.allowance(userAddress, address(this)) >= _totalAirdrop,
            "Token allowance too low"
        );
        require(_amount == addTokenClaimFee, "Required: Fee is required");
        BEP20Token storage bep20Token = bep20Tokens[_bep20];
        bool isStopped = true;
        for (uint256 index = 0; index < bep20Token.campaigns.length; index++) {
            if(!bep20Token.campaigns[index].isStopped) {
                isStopped = false;
                break;
            }
        }
        require(isStopped,"Only start one campaign at the moment");
        if (addTokenClaimFee > 0) {
            feeWallet.transfer(_amount);
            emit FeePayed(userAddress, _amount);
        }

        _safeTransferFrom(
            claimToken,
            userAddress,
            address(this),
            _totalAirdrop
        );
        uint256 campaignId = block.timestamp;
        Creator storage creator = creators[userAddress];
        Campaign memory currentCampaign = Campaign(
            campaignId,
            _nameCampaign,
            userAddress,
            _totalAirdrop,
            _bep20,
            _amountPerClaim,
            0,
            false
        );
        creator.campaigns.push(currentCampaign);
        bep20Token.campaigns.push(currentCampaign);
        campaigns[campaignId] = currentCampaign;
        totalCampaigns.push(currentCampaign);
        emit CreateCampaign(
            currentCampaign.id,
            currentCampaign.name,
            currentCampaign.owner,
            currentCampaign.totalAmount,
            currentCampaign.token,
            currentCampaign.amountPerClaim,
            currentCampaign.isStopped
        );
    }

    function claimToken(address _token) external payable blockReEntry() {
        require(msg.value == claimFee, "Required: Claim Fee is required");
        if (claimFee > 0) {
            feeWallet.transfer(msg.value);
            emit FeePayed(msg.sender, msg.value);
        }
        _claimToken(_token, msg.sender);
    }

    function _claimToken(address _token, address userAddress) internal {
        Campaign[] storage currentCampaigns = bep20Tokens[_token].campaigns;
        User storage user = users[userAddress];
        bool isClaimed = false;
        bool isStopped = false;
        bool isEnough = false;
        uint256 campaignId = 0;
        for (uint256 index = 0; index < currentCampaigns.length; index++) {
            if (
                user.campaigns.length > 0 && !currentCampaigns[index].isStopped
            ) {
                for (uint256 i = 0; i < user.campaigns.length; i++) {
                    if (currentCampaigns[index].id == user.campaigns[i].id) {
                        isClaimed = true;
                    }else{
                        isClaimed = false;
                    }
                }
            }
            if (currentCampaigns[index].isStopped) {
                isStopped = true;
            }else {
                isStopped = false;
            }
            if (
                !currentCampaigns[index].isStopped &&
                currentCampaigns[index].totalClaimed.add(
                    currentCampaigns[index].amountPerClaim
                ) <=
                currentCampaigns[index].totalAmount
            ) {
                campaignId = currentCampaigns[index].id;
                isEnough = true;
                if(!isClaimed && !isStopped && isEnough) {
                    currentCampaigns[index].totalClaimed = currentCampaigns[index].totalClaimed.add(
                        currentCampaigns[index].amountPerClaim
                    );
                    campaigns[campaignId].totalClaimed = campaigns[campaignId].totalClaimed.add(currentCampaigns[index].amountPerClaim);
                }
            }
        }
        Campaign memory campaign = campaigns[campaignId];
        require(!isClaimed && !isStopped && isEnough, "Campaign not availble for you");
        for (uint256 index = 0; index < totalCampaigns.length; index++) {
            if(totalCampaigns[index].id == campaignId) {
                totalCampaigns[index].totalClaimed =  totalCampaigns[index].totalClaimed.add(campaign.amountPerClaim);
            }
        }
        user.campaigns.push(campaigns[campaignId]);
        IBEP20(_token).transfer(userAddress, campaign.amountPerClaim);
        emit Claimed(campaignId, userAddress, campaign.amountPerClaim);
    }

    function getCampaignById(uint256 _campaignId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            address owner,
            uint256 totalAmount,
            address token,
            uint256 amountPerClaim,
            uint256 totalClaimed,
            bool isStopped
        )
    {
        id = campaigns[_campaignId].id;
        name = campaigns[_campaignId].name;
        owner = campaigns[_campaignId].owner;
        totalAmount = campaigns[_campaignId].totalAmount;
        token = campaigns[_campaignId].token;
        amountPerClaim = campaigns[_campaignId].amountPerClaim;
        totalClaimed = campaigns[_campaignId].totalClaimed;
        isStopped = campaigns[_campaignId].isStopped;
    }

    function getHistoryClaimed(address userAddress, uint256 _index)
        public
        view
        returns (
            uint256 id,
            string memory name,
            address owner,
            uint256 totalAmount,
            address token,
            uint256 amountPerClaim        
        )
    {
        User storage user = users[userAddress];
        id = user.campaigns[_index].id;
        name = user.campaigns[_index].name;
        owner = user.campaigns[_index].owner;
        totalAmount = user.campaigns[_index].totalAmount;
        token = user.campaigns[_index].token;
        amountPerClaim = user.campaigns[_index].amountPerClaim;        
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return totalCampaigns;
    }

    function getAllCampaignsByToken(address _token)
        public
        view
        returns (Campaign[] memory)
    {
        Campaign[] memory allCampaign = new Campaign[](totalCampaigns.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalCampaigns.length; index++) {
            if (totalCampaigns[index].token == _token) {
                allCampaign[count] = totalCampaigns[index];
                ++count;
            }
        }
        return allCampaign;
    }

    function handleForfeitedBalanceToken(
        address payable _addr,
        uint256 _amount,
        address _token
    ) external {
        require((msg.sender == feeWallet), "Restricted Access!");
        IBEP20(_token).transfer(_addr, _amount);
    }

    function handleForfeitedBalanceBNB(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == feeWallet), "Restricted Access!");
        (bool success, ) = _addr.call{value: _amount}("");

        require(success, "Failed");
    }

    function _safeTransferFrom(
        IBEP20 _token,
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        bool sent = _token.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }
}