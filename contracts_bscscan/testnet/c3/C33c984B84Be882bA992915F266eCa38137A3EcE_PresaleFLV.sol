/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;









library SafeMath {
    
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}








abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}










interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}








interface ICreamery {
    function initialize(address ownableFlavors) external;

    function burnItAllDown_OO() external;

    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    function updateOwnable_OAD(address new_ownableFlavors) external;

    function deposit(string memory note) external payable;
    function spiltMilk(uint256 value) external;
}








interface IFlavors {

  function presaleClaim(address presaleContract, uint256 amount) external;
  function spiltMilk(uint256 amount) external;
  function creamAndFreeze() external payable;


  function setBalance_OB(address holder,uint256 amount) external returns (bool);
  function addBalance_OB(address holder,uint256 amount) external returns (bool);
  function subBalance_OB(address holder,uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);





  function fees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function gas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  function burnItAllDown_OO() external;

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}



contract FlavorsAccess is Context {
    address internal iceCreamMan;
    address internal pendingICM;
    address internal flavorsToken;
    address internal creamery;
    mapping(address => bool) private authorizations;
    function grantAuthorization(address authorizedAddress)
        external
        onlyIceCreamMan
    {
        require(
            _grantAuthorization(authorizedAddress),
            "PRESALE FLV: grantAuthorization() = internal call failed"
        );
    }

    function _grantAuthorization(address authorizedAddress)
        internal
        returns (bool)
    {
        authorizations[authorizedAddress] = true;
        return true;
    }

    function revokeAuthorization(address revokedAddress)
        external
        onlyIceCreamMan
    {
        require(
            _revokeAuthorization(revokedAddress),
            "PRESALE FLV: revokeAuthorization() = internal call failed"
        );
    }

    function _revokeAuthorization(address revokedAddress)
        internal
        returns (bool)
    {
        authorizations[revokedAddress] = false;
        return true;
    }

    function isAuthorized(address addr) internal view returns (bool) {
        return authorizations[addr];
    }

    function transferICM(address new_iceCreamMan) external onlyIceCreamMan {
        require(
            _transferICM(new_iceCreamMan),
            "PRESALE FLV: transferICM() = internal call to _transferICM failed"
        );
    }

    function _transferICM(address new_iceCreamMan) internal returns (bool) {
        pendingICM = new_iceCreamMan;
        return true;
    }

    function acceptIceCreamMan() external onlyPendingIceCreamMan {
        require(
            _acceptIceCreamMan(),
            "PRESALE FLV: acceptIceCreamMan() = internal call failed"
        );
    }

    function _acceptIceCreamMan() internal returns (bool) {
        iceCreamMan = pendingICM;
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        return true;
    }

    modifier onlyAuthorized() {
        require(
            isAuthorized(_msgSender()),
            "PRESALE FLV: onlyAuthorized() = caller not authorized"
        );
        _;
    }

    modifier onlyPendingIceCreamMan() {
        require(
            pendingICM == _msgSender(),
            "PRESALE FLV: onlyPendingIceCreamMan() = caller not pendingICM"
        );
        _;
    }

    modifier onlyCreamery() {
        require(
            creamery == _msgSender(),
            "PRESALE FLV: onlyCreamery() = caller not creamery"
        );
        _;
    }

    modifier onlyFlavorsToken() {
        require(
            flavorsToken == _msgSender(),
            "PRESALE FLV: onlyFlavorsToken() = caller not flavorsToken"
        );
        _;
    }

    modifier onlyIceCreamMan() {
        require(
            iceCreamMan == _msgSender(),
            "PRESALE FLV: onlyIceCreamMan() = caller not iceCreamMan"
        );
        _;
    }
}

contract PresaleFLV is FlavorsAccess {
    using SafeMath for uint256;

    bool internal initialized = false;
    bool internal claimsEnabled;
    bool internal contributionsEnabled;
    bool internal useTokensInContract = false;
    uint8 constant DECIMALS_BNB = 18;
    uint8 constant DECIMALS_FLV = 9;
    uint16 internal maxBatchLength = 100;
    uint64 constant BLOCKS_PER_DAY = 28800;

    uint256 internal globalTotal_claims;
    uint256 internal globalTotal_contributions;

    mapping(address => bool) internal _isOG;

    function isOG(address holder) external view onlyFlavorsToken returns (bool isOG_) {
        return _isOG[holder];
    }

    uint256 internal globalTotal_maxContribution = 0;
    uint256 internal maxHolderContribution = 8 ether;

    mapping(address => bool) internal whitelist;
    mapping(address => bool) internal blacklist;

    mapping(address => uint256) internal contributions;
    mapping(address => uint256) internal claimedFLV;

    mapping(address => bool) internal completedClaims;
    mapping(address => bool) internal completedContributions;

    uint256 internal flvPerNativeCoin = 105_000 * (10**DECIMALS_FLV);

    uint256 internal claimsEnabledOnBlockNumber;
    IFlavors internal FLV;
    ICreamery internal Creamery;


    function canISell() external view returns (bool canISell_) {
        if (1 <= getHoldersMaxSellAfterAlreadySold(_msgSender())) {
            return true;
        } else {
            return false;
        }
    }

    function canHolderSell(address holder, uint256 amount)
        external
        view
        onlyFlavorsToken
        returns (bool canHolderSell_)
    {
        return _canHolderSell(holder, amount);
    }

    function _canHolderSell(address holder, uint256 amount)
        internal
        view
        returns (bool canHolderSell_)
    {
        if (amount <= getHoldersMaxSellAfterAlreadySold(holder)) {
            return true;
        } else {
            return false;
        }
    }

    
    function dayNumber() internal view returns (uint256 dayNumber_) {
        if (claimsEnabled) {
            return (
                (
                    ((block.number).sub(claimsEnabledOnBlockNumber)).div(
                        BLOCKS_PER_DAY
                    )
                ).add(1)
            );
        } else {
            return 0;
        }
    }

    
    function getHoldersMaxSell(address holder) internal view returns (uint256) {
        return claimedFLV[holder].mul(dayNumber()).mul(10).div(100);
    }

    
    function getHoldersClaimsAlreadySold(address holder)
        internal
        view
        returns (uint256)
    {
        if (address(FLV) == address(0)) {
            return 0;
        } else if (FLV.balanceOf(holder) > claimedFLV[holder]) {
            return 0;
        } else {
            return claimedFLV[holder].sub(FLV.balanceOf(holder));
        }
    }

    
    function getHoldersMaxSellAfterAlreadySold(address holder)
        internal
        view
        returns (uint256)
    {
        uint256 holdersMaxSell = getHoldersMaxSell(holder);
        uint256 holdersClaimsAlreadySold = getHoldersClaimsAlreadySold(holder);
        if (holdersClaimsAlreadySold > holdersMaxSell) {
            return 0;
        } else {
            return (holdersMaxSell.sub(holdersClaimsAlreadySold));
        }
    }

    function getMaxClaimableFLV() internal view returns (uint256) {
        return
            (maxHolderContribution.mul(flvPerNativeCoin)).div(10**DECIMALS_BNB);
    }

    function getRemainingBNBcontribution(address holder)
        internal
        view
        returns (uint256)
    {
        if (whitelist[holder]) {
            return maxHolderContribution.sub(contributions[holder]);
        } else {
            return 0;
        }
    }

    function getRemainingMaxClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {
        if (whitelist[holder]) {
            return getMaxClaimableFLV().sub(claimedFLV[holder]);
        } else {
            return 0;
        }
    }

    function getHoldersClaimableFLV(address holder)
        internal
        view
        returns (uint256)
    {
        return (
            (contributions[holder].mul(flvPerNativeCoin).div(10**DECIMALS_BNB))
                .sub(claimedFLV[holder])
        );
    }

    bool firstClaimsToggle = true;

    function enableClaims_OFT() external onlyFlavorsToken {
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        claimsEnabled = true;
    }

    function forceClaimsEnabledBlockNumber_OICM(uint256 blockNumber)
        external
        onlyIceCreamMan
    {
        claimsEnabledOnBlockNumber = blockNumber;
    }

    function toggleClaims_OICM() external onlyIceCreamMan {
        if (firstClaimsToggle) {
            claimsEnabledOnBlockNumber = block.number;
            firstClaimsToggle = false;
        }
        claimsEnabled ? claimsEnabled = false : claimsEnabled = true;
    }

    function toggleContributions_OICM() external onlyIceCreamMan {
        contributionsEnabled
            ? contributionsEnabled = false
            : contributionsEnabled = true;
    }

    modifier checkClaimsEnabled() {
        require(
            claimsEnabled,
            "PRESALE FLV: checkClaimsEnabled() = Claiming FLV is not enabled."
        );
        _;
    }

    modifier checkContributionsEnabled() {
        require(
            contributionsEnabled,
            "PRESALE FLV: checkContributionsEnabled() = Contributions not enabled."
        );
        _;
    }

    

    function initialize(address iceCreamMan_) external {
        require(
            !initialized,
            "PRESALE FLV: initialize() = Already Initialized!"
        );
        pendingICM = address(0x000000000000000000000000000000000000dEaD);
        iceCreamMan = iceCreamMan_;
        _grantAuthorization(iceCreamMan);
        _grantAuthorization(address(this));
        initialized = true;
    }

    
    function getAddresses()
        external
        view
        returns (
            address presaleFLV,
            address flv,
            address creamery,
            address iceCreamMan_,
            address pendingICM_
        )
    {
        return (
            address(this),
            address(FLV),
            address(Creamery),
            iceCreamMan,
            pendingICM
        );
    }
    
    function getInfo()
        external
        view
        returns (
            uint256 claimsEnabledOnBlockNumber_,
            uint256 dayNumber_,
            uint256 globalTotal_maxContribution_,
            uint256 globalTotal_contributions_,
            uint256 globalTotal_claims_,
            uint256 flvPerNativeCoin_,
            bool claimsEnabled_,
            bool contributionsEnabled_
        )
    {
        return (
            claimsEnabledOnBlockNumber,
            dayNumber(),
            globalTotal_maxContribution,
            globalTotal_contributions,
            globalTotal_claims,
            flvPerNativeCoin,
            claimsEnabled,
            contributionsEnabled
        );
    }

    function getMyInfo()
        external
        view
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        return _getHolderInfo(_msgSender());
    }

    function getHolderInfo(address holder)
        external
        view        
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        return _getHolderInfo(holder);
    }

    
    
    function _getHolderInfo(address holder)
        internal
        view        
        returns (
            uint256 remainingBNBcontribution,
            uint256 holdersClaimableFLV,
            uint256 holdersCurrentMaxSell,
            uint256 holderContributions_,
            uint256 claimedFLV_,
            bool completedContributions_,
            bool completedClaims_
        )
    {
        if (_isOG[holder]) {
            return (
                maxHolderContribution.sub(contributions[holder]),
                getHoldersClaimableFLV(holder),
                getHoldersMaxSellAfterAlreadySold(holder),
                contributions[holder],
                claimedFLV[holder],
                completedContributions[holder],
                completedClaims[holder]
            );
        } else {
            return (0, 0, 0, 0, 0, false, false);
        }
    }

    
    function contribute() external payable checkContributionsEnabled {
        address holder = _msgSender();
        uint256 value = _msgValue();
        require(
            !blacklist[holder],
            "PRESALE FLV: contribute() = holder BLACKLISTED! What did you do?"
        );
        require(
            whitelist[holder],
            "PRESALE FLV: contribute() = NOT WHITELISTED! For info https://flavorsbsc.com/"
        );
        require(
            !completedContributions[holder],
            "PRESALE FLV: contribute() = holder already hit max contribution"
        );
        require(
            value <= getRemainingBNBcontribution(holder),
            "PRESALE FLV: contribute() = exceeds holder's allowed contribution"
        );
        _contribute(holder, value);
        delete holder;
        delete value;
    }

    
    function _contribute(address holder, uint256 amount) internal {
        contributions[holder] = contributions[holder].add(amount);
        globalTotal_contributions = globalTotal_contributions.add(amount);
        if (getRemainingBNBcontribution(holder) == 0) {
            completedContributions[holder] = true;
        }
        emit ContributionReceived(
            holder,
            amount,
            contributions[holder],
            getRemainingBNBcontribution(holder),
            globalTotal_contributions,
            "PRESALE FLV: Contribution Received"
        );
    }

    

    function claim() external checkClaimsEnabled {
        address holder = _msgSender();
        require(
            !blacklist[holder],
            "PRESALE FLV: claim() = WALLET BLACKLISTED! What did you do?"
        );
        require(
            whitelist[holder],
            "PRESALE FLV: claim() = NOT WHITELISTED! https://flavorsbsc.com/"
        );
        require(
            !completedClaims[holder],
            "PRESALE FLV: claim() = holder already hit max claims"
        );
        uint256 amount = getHoldersClaimableFLV(holder);
        require(
            amount > 0,
            "PRESALE FLV: claim() = holder has no tokens to claim"
        );

        _claim(holder, amount);
    }

    
    function _claim(address holder, uint256 amount) internal {
        require(
            amount <= getRemainingMaxClaimableFLV(holder),
            "PRESALE FLV: _claim() = claim exceeds remaining unclaimed FLV"
        );
        globalTotal_claims = globalTotal_claims.add(amount);
        claimedFLV[holder] = claimedFLV[holder].add(amount);
        require(
            claimedFLV[holder] <= getMaxClaimableFLV(),
            "PRESALE FLV: _claim() = Claim exceeds total claimable FLV"
        );
        if (getRemainingMaxClaimableFLV(holder) == 0) {
            completedClaims[holder] = true;
        }
        require(
            processClaim(holder, amount),
            "PRESALE FLV: _claim() = transfer of claimed tokens failed."
        );
    }

    

    
    function setUseTokensInContract(bool useTokensInContract_)
        external
        onlyIceCreamMan
    {
        useTokensInContract = useTokensInContract_;
    }

    
    function processClaim(address holder, uint256 amount)
        private
        returns (bool)
    {
        if (!useTokensInContract) {
            FLV.presaleClaim(address(this), amount);
        }
        return FLV.transfer(holder, amount);
    }

    
    function set(
        address flv,
        address creamery,
        uint16 maxBatchLength_,
        uint256 maxHolderContribution_,
        uint256 flvPerNativeCoin_
    ) external onlyIceCreamMan {
        setAddressFLV(flv);
        setAddressCreamery(creamery);
        setRateFLV(flvPerNativeCoin_);
        setMaxBatchLength(maxBatchLength_);
        setMaxHolderContribution(maxHolderContribution_);
    }

    function setMaxHolderContribution(uint256 value) internal {
        maxHolderContribution = value * 1 ether;
    }

    function setAddressCreamery(address creamery) internal {
        Creamery = ICreamery(creamery);
    }

    function setAddressFLV(address flavorsToken_) internal {
        flavorsToken = flavorsToken_;
        FLV = IFlavors(flavorsToken);
    }

    function setRateFLV(uint256 flvPerNativeCoin_) internal {
        flvPerNativeCoin = flvPerNativeCoin_.mul(10**DECIMALS_FLV);
    }

    function setMaxBatchLength(uint16 maxBatchLength_) internal {
        maxBatchLength = maxBatchLength_;
    }

    function toggleBlacklisted(address holder) external onlyAuthorized {
        blacklist[holder]
            ? setBlacklistedFalse(holder)
            : setBlacklistedTrue(holder);
    }

    function toggleWhitelisted(address holder) external onlyAuthorized {
        whitelist[holder]
            ? setWhitelistedFalse(holder)
            : setWhitelistedTrue(holder);
    }

    function setBlacklistedTrue(address holder) internal {
        if (!blacklist[holder]) {
            blacklist[holder] = true;
            globalTotal_maxContribution = globalTotal_maxContribution.add(
                maxHolderContribution
            );
            if (whitelist[holder]) {
                setWhitelistedFalse(holder);
            }
            setWhitelistedFalse(holder);
        }
    }

    function setBlacklistedFalse(address holder) internal {
        if (blacklist[holder]) {
            blacklist[holder] = false;
            globalTotal_maxContribution = globalTotal_maxContribution.sub(
                maxHolderContribution
            );
        }
    }

    function setWhitelistedTrue(address holder) internal {
        if (!whitelist[holder]) {
            _isOG[holder] = true;
            whitelist[holder] = true;
            globalTotal_maxContribution = globalTotal_maxContribution.add(
                maxHolderContribution
            );
            if (blacklist[holder]) {
                setBlacklistedFalse(holder);
            }
            emit WhitelistedHolder(holder);
        }
    }

    function setWhitelistedFalse(address holder) internal {
        if (whitelist[holder]) {
            _isOG[holder] = false;
            whitelist[holder] = false;
            globalTotal_maxContribution = globalTotal_maxContribution.sub(
                maxHolderContribution
            );
        }
    }

    

    function whitelistMultiple(
        address holder0,
        address holder1,
        address holder2,
        address holder3,
        address holder4,
        address holder5,
        address holder6,
        address holder7
    ) external onlyAuthorized {
        _whitelistMultiple(
            holder0,
            holder1,
            holder2,
            holder3,
            holder4,
            holder5,
            holder6,
            holder7
        );
    }

    function _whitelistMultiple(
        address holder0,
        address holder1,
        address holder2,
        address holder3,
        address holder4,
        address holder5,
        address holder6,
        address holder7
    ) internal {
        if (holder0 != address(0)) {
            setWhitelistedTrue(holder0);
        }
        if (holder1 != address(0)) {
            setWhitelistedTrue(holder1);
        }
        if (holder2 != address(0)) {
            setWhitelistedTrue(holder2);
        }
        if (holder3 != address(0)) {
            setWhitelistedTrue(holder3);
        }
        if (holder4 != address(0)) {
            setWhitelistedTrue(holder4);
        }
        if (holder5 != address(0)) {
            setWhitelistedTrue(holder5);
        }
        if (holder6 != address(0)) {
            setWhitelistedTrue(holder6);
        }
        if (holder7 != address(0)) {
            setWhitelistedTrue(holder7);
        }
    }

    function whitelistBatch(address[] memory holders) external onlyAuthorized {
        require(
            holders.length <= maxBatchLength,
            "PRESALE FLV: batchAddHolder() = list length exceeds max"
        );

        for (uint16 i = 0;i < holders.length;i++) {
            setWhitelistedTrue(holders[i]);
        }
    }

    
    event WhitelistedHolder(address holder);

    
    function contractTokenBalance(address token)
        external
        view
        returns (uint256 balance)
    {
        return IERC20(token).balanceOf(address(this));
    }

    
    function contractNativeCoinBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }

    
    function adminTokenWithdrawal(
        address token,
        uint256 amount,
        address to
    ) external onlyAuthorized returns (bool) {
        IERC20 ERC20Instance = IERC20(token);
        require(
            ERC20Instance.balanceOf(address(this)) > amount,
            "PRESALE FLV: adminTokenWithdrawal() = insufficient balance"
        );
        ERC20Instance.transfer(to, amount);
        emit AdminTokenWithdrawal(_msgSender(), amount, token);
        return true;
    }

    
    function transferContributedBNB() external onlyAuthorized {
        uint256 value = address(this).balance;
        (bool success, ) = payable(address(Creamery)).call{value: value}("");
        require(success, "PRESALE FLV: transferContributedBNB() = fail");
    }

    

    function setHolder(
        bool isOG_,
        bool blacklist_,
        bool whitelist_,
        bool completedClaims_,
        bool completedContributions_,
        address holder,
        uint256 claimedFLV_,
        uint256 contributions_
    ) external onlyIceCreamMan {
        completedClaims[holder] = completedClaims_;
        completedContributions[holder] = completedContributions_;
        contributions[holder] = contributions_;
        claimedFLV[holder] = claimedFLV_;
        _isOG[holder] = isOG_;
        whitelist[holder] = whitelist_;
        blacklist[holder] = blacklist_;
    }

    
    event AdminTokenWithdrawal(
        address indexed withdrawalBy,
        uint256 amount,
        address indexed token
    );

    
    event ContributionReceived(
        address indexed from,
        uint256 amount,
        uint256 holderTotalContributions,
        uint256 holderRemainingContributions,
        uint256 globalTotal_contributions,
        string indexed note
    );

    
    event HolderAdded(address indexed holder);
}