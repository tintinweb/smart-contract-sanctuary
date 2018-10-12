pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// Fxxx Land Rush Contract - Purchase land parcels with GZE and ETH
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for GazeCoin 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    bool private initialised;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised);
        owner = _owner;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function max(uint a, uint b) internal pure returns (uint c) {
        c = a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint c) {
        c = a <= b ? a : b;
    }
}

// ----------------------------------------------------------------------------
// BokkyPooBah&#39;s Token Teleportation Service Interface v1.10
//
// https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// Contracts that can have tokens approved, and then a function executed
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// BokkyPooBah&#39;s Token Teleportation Service Interface v1.10
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSTokenInterface is ERC20Interface {
    uint public constant bttsVersion = 110;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function symbol() public view returns (string);
    function name() public view returns (string);
    function decimals() public view returns (uint8);

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

    // ------------------------------------------------------------------------
    // signed{X} functions
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;

    // ------------------------------------------------------------------------
    // signed{X}Check return status
    // ------------------------------------------------------------------------
    enum CheckResult {
        Success,                           // 0 Success
        NotTransferable,                   // 1 Tokens not transferable yet
        AccountLocked,                     // 2 Account locked
        SignerMismatch,                    // 3 Mismatch in signing account
        InvalidNonce,                      // 4 Invalid nonce
        InsufficientApprovedTokens,        // 5 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 6 Insufficient approved tokens for fees
        InsufficientTokens,                // 7 Insufficient tokens
        InsufficientTokensForFees,         // 8 Insufficient tokens for fees
        OverflowError                      // 9 Overflow error
    }
}

// ----------------------------------------------------------------------------
// PriceFeed Interface - _live is true if the rate is valid, false if invalid
// ----------------------------------------------------------------------------
contract PriceFeedInterface {
    function name() public view returns (string);
    function getRate() public view returns (uint _rate, bool _live);
}

// ----------------------------------------------------------------------------
// Bonus List interface
// ----------------------------------------------------------------------------
contract BonusListInterface {
    function isInBonusList(address account) public view returns (bool);
}


// ----------------------------------------------------------------------------
// FxxxLandRush Contract
// ----------------------------------------------------------------------------
contract FxxxLandRush is Owned, ApproveAndCallFallBack {
    using SafeMath for uint;

    uint private constant TENPOW18 = 10 ** 18;

    BTTSTokenInterface public parcelToken;
    BTTSTokenInterface public gzeToken;
    PriceFeedInterface public ethUsdPriceFeed;
    PriceFeedInterface public gzeEthPriceFeed;
    BonusListInterface public bonusList;

    address public wallet;
    uint public startDate;
    uint public endDate;
    uint public maxParcels;
    uint public parcelUsd;                  // USD per parcel, e.g., USD 1,500 * 10^18
    uint public usdLockAccountThreshold;    // e.g., USD 7,000 * 10^18
    uint public gzeBonusOffList;            // e.g., 20 = 20% bonus
    uint public gzeBonusOnList;             // e.g., 30 = 30% bonus

    uint public parcelsSold;
    uint public contributedGze;
    uint public contributedEth;
    bool public finalised;

    event WalletUpdated(address indexed oldWallet, address indexed newWallet);
    event StartDateUpdated(uint oldStartDate, uint newStartDate);
    event EndDateUpdated(uint oldEndDate, uint newEndDate);
    event MaxParcelsUpdated(uint oldMaxParcels, uint newMaxParcels);
    event ParcelUsdUpdated(uint oldParcelUsd, uint newParcelUsd);
    event UsdLockAccountThresholdUpdated(uint oldUsdLockAccountThreshold, uint newUsdLockAccountThreshold);
    event GzeBonusOffListUpdated(uint oldGzeBonusOffList, uint newGzeBonusOffList);
    event GzeBonusOnListUpdated(uint oldGzeBonusOnList, uint newGzeBonusOnList);
    event Purchased(address indexed addr, uint parcels, uint gzeToTransfer, uint ethToTransfer, uint parcelsSold, uint contributedGze, uint contributedEth, bool lockAccount);

    constructor(address _parcelToken, address _gzeToken, address _ethUsdPriceFeed, address _gzeEthPriceFeed, address _bonusList, address _wallet, uint _startDate, uint _endDate, uint _maxParcels, uint _parcelUsd, uint _usdLockAccountThreshold, uint _gzeBonusOffList, uint _gzeBonusOnList) public {
        require(_parcelToken != address(0) && _gzeToken != address(0));
        require(_ethUsdPriceFeed != address(0) && _gzeEthPriceFeed != address(0) && _bonusList != address(0));
        require(_wallet != address(0));
        require(_startDate >= now && _endDate > _startDate);
        require(_maxParcels > 0 && _parcelUsd > 0);
        initOwned(msg.sender);
        parcelToken = BTTSTokenInterface(_parcelToken);
        gzeToken = BTTSTokenInterface(_gzeToken);
        ethUsdPriceFeed = PriceFeedInterface(_ethUsdPriceFeed);
        gzeEthPriceFeed = PriceFeedInterface(_gzeEthPriceFeed);
        bonusList = BonusListInterface(_bonusList);
        wallet = _wallet;
        startDate = _startDate;
        endDate = _endDate;
        maxParcels = _maxParcels;
        parcelUsd = _parcelUsd;
        usdLockAccountThreshold = _usdLockAccountThreshold;
        gzeBonusOffList = _gzeBonusOffList;
        gzeBonusOnList = _gzeBonusOnList;
    }
    function setWallet(address _wallet) public onlyOwner {
        require(!finalised);
        require(_wallet != address(0));
        emit WalletUpdated(wallet, _wallet);
        wallet = _wallet;
    }
    function setStartDate(uint _startDate) public onlyOwner {
        require(!finalised);
        require(_startDate >= now);
        emit StartDateUpdated(startDate, _startDate);
        startDate = _startDate;
    }
    function setEndDate(uint _endDate) public onlyOwner {
        require(!finalised);
        require(_endDate > startDate);
        emit EndDateUpdated(endDate, _endDate);
        endDate = _endDate;
    }
    function setMaxParcels(uint _maxParcels) public onlyOwner {
        require(!finalised);
        require(_maxParcels >= parcelsSold);
        emit MaxParcelsUpdated(maxParcels, _maxParcels);
        maxParcels = _maxParcels;
    }
    function setParcelUsd(uint _parcelUsd) public onlyOwner {
        require(!finalised);
        require(_parcelUsd > 0);
        emit ParcelUsdUpdated(parcelUsd, _parcelUsd);
        parcelUsd = _parcelUsd;
    }
    function setUsdLockAccountThreshold(uint _usdLockAccountThreshold) public onlyOwner {
        require(!finalised);
        emit UsdLockAccountThresholdUpdated(usdLockAccountThreshold, _usdLockAccountThreshold);
        usdLockAccountThreshold = _usdLockAccountThreshold;
    }
    function setGzeBonusOffList(uint _gzeBonusOffList) public onlyOwner {
        require(!finalised);
        emit GzeBonusOffListUpdated(gzeBonusOffList, _gzeBonusOffList);
        gzeBonusOffList = _gzeBonusOffList;
    }
    function setGzeBonusOnList(uint _gzeBonusOnList) public onlyOwner {
        require(!finalised);
        emit GzeBonusOnListUpdated(gzeBonusOnList, _gzeBonusOnList);
        gzeBonusOnList = _gzeBonusOnList;
    }

    function symbol() public view returns (string _symbol) {
        _symbol = parcelToken.symbol();
    }
    function name() public view returns (string _name) {
        _name = parcelToken.name();
    }

    // USD per ETH, e.g., 221.99 * 10^18
    function ethUsd() public view returns (uint _rate, bool _live) {
        return ethUsdPriceFeed.getRate();
    }
    // ETH per GZE, e.g., 0.00004366 * 10^18
    function gzeEth() public view returns (uint _rate, bool _live) {
        return gzeEthPriceFeed.getRate();
    }
    // USD per GZE, e.g., 0.0096920834 * 10^18
    function gzeUsd() public view returns (uint _rate, bool _live) {
        uint _ethUsd;
        bool _ethUsdLive;
        (_ethUsd, _ethUsdLive) = ethUsdPriceFeed.getRate();
        uint _gzeEth;
        bool _gzeEthLive;
        (_gzeEth, _gzeEthLive) = gzeEthPriceFeed.getRate();
        if (_ethUsdLive && _gzeEthLive) {
            _live = true;
            _rate = _ethUsd.mul(_gzeEth).div(TENPOW18);
        }
    }
    // ETH per parcel, e.g., 6.757061128879679264 * 10^18
    function parcelEth() public view returns (uint _rate, bool _live) {
        uint _ethUsd;
        (_ethUsd, _live) = ethUsd();
        if (_live) {
            _rate = parcelUsd.mul(TENPOW18).div(_ethUsd);
        }
    }
    // GZE per parcel, without bonus, e.g., 154765.486231783766945298 * 10^18
    function parcelGzeWithoutBonus() public view returns (uint _rate, bool _live) {
        uint _gzeUsd;
        (_gzeUsd, _live) = gzeUsd();
        if (_live) {
            _rate = parcelUsd.mul(TENPOW18).div(_gzeUsd);
        }
    }
    // GZE per parcel, with bonus but not on bonus list, e.g., 128971.238526486472454415 * 10^18
    function parcelGzeWithBonusOffList() public view returns (uint _rate, bool _live) {
        uint _parcelGzeWithoutBonus;
        (_parcelGzeWithoutBonus, _live) = parcelGzeWithoutBonus();
        if (_live) {
            _rate = _parcelGzeWithoutBonus.mul(100).div(gzeBonusOffList.add(100));
        }
    }
    // GZE per parcel, with bonus and on bonus list, e.g., 119050.374024449051496383 * 10^18
    function parcelGzeWithBonusOnList() public view returns (uint _rate, bool _live) {
        uint _parcelGzeWithoutBonus;
        (_parcelGzeWithoutBonus, _live) = parcelGzeWithoutBonus();
        if (_live) {
            _rate = _parcelGzeWithoutBonus.mul(100).div(gzeBonusOnList.add(100));
        }
    }

    // Account contributes by:
    // 1. calling GZE.approve(landRushAddress, tokens)
    // 2. calling this.purchaseWithGze(tokens)
    function purchaseWithGze(uint256 tokens) public {
        require(gzeToken.allowance(msg.sender, this) >= tokens);
        receiveApproval(msg.sender, tokens, gzeToken, "");
    }
    // Account contributes by calling GZE.approveAndCall(landRushAddress, tokens, "")
    function receiveApproval(address from, uint256 tokens, address token, bytes /* data */) public {
        require(now >= startDate && now <= endDate);
        require(token == address(gzeToken));
        uint _parcelGze;
        bool _live;
        if (bonusList.isInBonusList(from)) {
            (_parcelGze, _live) = parcelGzeWithBonusOnList();
        } else {
            (_parcelGze, _live) = parcelGzeWithBonusOffList();
        }
        require(_live);
        uint parcels = tokens.div(_parcelGze);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        uint gzeToTransfer = parcels.mul(_parcelGze);
        contributedGze = contributedGze.add(gzeToTransfer);
        require(ERC20Interface(token).transferFrom(from, wallet, gzeToTransfer));
        bool lock = mintParcelTokens(from, parcels);
        emit Purchased(from, parcels, gzeToTransfer, 0, parcelsSold, contributedGze, contributedEth, lock);
    }
    // Account contributes by sending ETH
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint _parcelEth;
        bool _live;
        (_parcelEth, _live) = parcelEth();
        require(_live);
        uint parcels = msg.value.div(_parcelEth);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        uint ethToTransfer = parcels.mul(_parcelEth);
        contributedEth = contributedEth.add(ethToTransfer);
        uint ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToRefund > 0) {
            msg.sender.transfer(ethToRefund);
        }
        bool lock = mintParcelTokens(msg.sender, parcels);
        emit Purchased(msg.sender, parcels, 0, ethToTransfer, parcelsSold, contributedGze, contributedEth, lock);
    }
    // Contract owner allocates parcels to tokenOwner for offline purchase
    function offlinePurchase(address tokenOwner, uint parcels) public onlyOwner {
        require(!finalised);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        bool lock = mintParcelTokens(tokenOwner, parcels);
        emit Purchased(tokenOwner, parcels, 0, 0, parcelsSold, contributedGze, contributedEth, lock);
    }
    // Internal function to mint tokens and disable minting if maxParcels sold
    function mintParcelTokens(address account, uint parcels) internal returns (bool _lock) {
        require(parcels > 0);
        parcelsSold = parcelsSold.add(parcels);
        _lock = parcelToken.balanceOf(account).add(parcelUsd.mul(parcels)) >= usdLockAccountThreshold;
        require(parcelToken.mint(account, parcelUsd.mul(parcels), _lock));
        if (parcelsSold >= maxParcels) {
            parcelToken.disableMinting();
            finalised = true;
        }
    }
    // Contract owner finalises to disable parcel minting
    function finalise() public onlyOwner {
        require(!finalised);
        require(now > endDate || parcelsSold >= maxParcels);
        parcelToken.disableMinting();
        finalised = true;
    }
}