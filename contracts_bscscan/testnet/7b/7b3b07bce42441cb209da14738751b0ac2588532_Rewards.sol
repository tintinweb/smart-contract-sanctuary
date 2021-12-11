// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./Initializable.sol";

contract Rewards is Initializable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}    

    // shard price
    uint256 private _shardPrice;

    // used for what token should be used for purchasing a sealed nft
    address private _tokenAddress;

    // used for receiving the token (REWARDS AND POOL CONTRA)
    address private _rewardPoolAddress;

    event ShardSold(
        address indexed buyer,
        uint256 indexed shardPrice,
        uint256 indexed shardQty
    );

    struct ShardsPool {
        uint256 total;
        uint256 totalRemaining;
        uint256 totalMinted;
    }

    // total circulating shards on item shop
    mapping (uint256=>ShardsPool) private _shardsPool;

    // current shard index;
    uint256 private _currentShardsPoolIndex;

    event CreatedNewShardsPool(
        uint256 poolIndex,
        uint256 indexed total,
        uint256 indexed totalRemaining,
        uint256 indexed totalMinted
    );
    event UpdatedShardsPool(
        uint256 poolIndex,
        uint256 indexed total,
        uint256 indexed totalRemaining,
        uint256 indexed totalMinted
    );

    uint256 private _gCoinExchangePrice; //  1 OCA$H = 100 gcoin, value should be in 100 gcoin

    event ExchangeToken(
        uint256 gCoinAmount,
        uint256 tokenAmount,
        address userAddress,
        uint256 gCoinExchangePrice,
        uint256 fee
    );

    // mapping if an address is allowed to exchange
    mapping (address => bool) public whitelistedExchanger;

    uint256 public totalTokenReleased;
    uint256 public totalGCoinExchanged;

    uint256 private _exchangeFee;

    mapping(uint256 => bool) usedNonces;

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();

        _shardPrice = 1 * 10 ** 18; // set shard price to 1 token

        _rewardPoolAddress = address(this);

        _currentShardsPoolIndex = 0;

        _createNewShardsPool(56868750); // 30% of initial supply of timeshards

        _exchangeFee = 45; //45% will be the exchange fee

        _gCoinExchangePrice = 100; //gcoin exchange price
    }

    function setExchangeFee(uint256 exchangeFee) public onlyOwner {
        require(exchangeFee > 0,"Exchange Price should be greater than zero");
        _exchangeFee = exchangeFee;
    }

    function getExchangeFee() external view returns (uint256) {
        return _exchangeFee;
    }

    function _createNewShardsPool(uint256 _shardsSupply) public onlyOwner {
        require(_shardsSupply>0 ,"Total should be greater than zero");
        require(_shardsPool[_currentShardsPoolIndex].totalRemaining == 0,"Total Remaining shards should be zero");

        _currentShardsPoolIndex = _currentShardsPoolIndex.add(1);

        _shardsPool[_currentShardsPoolIndex] = ShardsPool(_shardsSupply, _shardsSupply, 0);

        emit CreatedNewShardsPool(_currentShardsPoolIndex, _shardsPool[_currentShardsPoolIndex].total, _shardsPool[_currentShardsPoolIndex].totalRemaining, _shardsPool[_currentShardsPoolIndex].totalMinted);
    }

    function updateCurrentShardsPool(uint256 total_, uint256 totalRemaining_, uint256 totalMinted_) external onlyOwner {
        require(total_>0 ,"Total should be greater than zero");
        require(total_>= totalRemaining_,"Total should be greater than or equal to total remaining");
        require(total_>= totalMinted_,"Total should be greater than or equal to total minted");

        _shardsPool[_currentShardsPoolIndex] = ShardsPool(total_, totalRemaining_, totalMinted_);

        emit UpdatedShardsPool(_currentShardsPoolIndex, _shardsPool[_currentShardsPoolIndex].total, _shardsPool[_currentShardsPoolIndex].totalRemaining, _shardsPool[_currentShardsPoolIndex].totalMinted);
    }

    function getShardsPool(uint256 shardsIndex_) external view returns (ShardsPool memory) {
        return _shardsPool[shardsIndex_];
    }

    function currentShardsPoolIndex() external view returns (uint256 ){
        return _currentShardsPoolIndex;
    }

    // token address
    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address _token) external onlyOwner {
        _tokenAddress = _token;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function buyShards(uint256 shardQty) external whenNotPaused {
        require(shardQty > 0 ,"Shard Quantity should be greater than zero");
        require(_rewardPoolAddress != address(0),"Reward pool address not set");
        require(_tokenAddress != address(0),"Token address not set");
        require(_shardsPool[_currentShardsPoolIndex].total >= _shardsPool[_currentShardsPoolIndex].totalMinted.add(shardQty),"Total shards minted reached");
        uint256 totalShardPrice = _shardPrice.mul(shardQty);
        
        _shardsPool[_currentShardsPoolIndex].totalMinted = _shardsPool[_currentShardsPoolIndex].totalMinted.add(shardQty);

        _shardsPool[_currentShardsPoolIndex].totalRemaining = _shardsPool[_currentShardsPoolIndex].totalRemaining.sub(shardQty);
        
        require(IERC20Upgradeable(_tokenAddress).allowance(_msgSender() , address(this))>=totalShardPrice,"Token amount allowance is not enough to buy shards");

        // transfer the token amount to the reward pool address
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(_msgSender(), _rewardPoolAddress, totalShardPrice);

        // emit an event that a shard sold
        emit ShardSold(_msgSender(),_shardPrice, shardQty);
    }

    function shardPrice() external view returns (uint256) {
        return _shardPrice;
    }
    function setShardPrice(uint256 shardPrice_) external onlyOwner {
        _shardPrice = shardPrice_;
    }

    function setGCoinExchangePrice(uint256 _newExchangePrice) external onlyOwner {
        require(_newExchangePrice > 0,"Exchange Price should be greater than zero");
        _gCoinExchangePrice = _newExchangePrice;
    }

    function getGCoinExchangePrice() external view returns (uint256) {
        return _gCoinExchangePrice;
    }

    
    modifier onlyExchanger() {
        require(whitelistedExchanger[_msgSender()],"Not whitelisted as exchanger");
        _;
    }

    function setExchanger(address _exchanger, bool _whitelisted) external onlyOwner {
        require(whitelistedExchanger[_exchanger] != _whitelisted,"Invalid value for _exchanger");
        whitelistedExchanger[_exchanger] = _whitelisted;
    }

    function isExchanger(address _exchanger) external view returns (bool) {
        return whitelistedExchanger[_exchanger];
    }
    
    function exchangeToken(uint256 gCoinAmount, address userAddress, bool hasFee) external onlyExchanger {
        require(gCoinAmount > 0, "GCoin amount should be greater than zero");
        require(_gCoinExchangePrice > 0,"GCoin exchange price should be greater than zero");
        require(_exchangeFee > 0,"Exchange Fee should be greater than zero");
        

        uint256 tokenAmount = gCoinAmount.mul(10**18).div(_gCoinExchangePrice);

        uint256 fee = 0;
        if(hasFee){
            fee = tokenAmount.mul(_exchangeFee).div(100);
            tokenAmount = tokenAmount.sub(fee);
        }
        require(IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) >= tokenAmount, "Reward pool does not have enough token balance");

        
        IERC20Upgradeable(_tokenAddress).safeTransfer(userAddress, tokenAmount);

        totalTokenReleased = totalTokenReleased.add(tokenAmount);

        totalGCoinExchanged = totalGCoinExchanged.add(gCoinAmount);

        emit ExchangeToken(gCoinAmount, tokenAmount, userAddress, _gCoinExchangePrice, fee);
    }

    function exchangeTokenSecured(uint256 _gAmount,bool _hasFee, uint256 nonce, bytes memory sig, bytes memory walletSig) external {

        require(!usedNonces[nonce],"Used nonce");
        usedNonces[nonce] = true;

        require(isValidData(_gAmount, _hasFee, nonce, sig, walletSig)==true,"Invalid data");

        uint256 gCoinAmount = _gAmount;
        require(gCoinAmount > 0, "GCoin amount should be greater than zero");
        require(_gCoinExchangePrice > 0,"GCoin exchange price should be greater than zero");
        require(_exchangeFee > 0,"Exchange Fee should be greater than zero");



        uint256 tokenAmount = gCoinAmount.mul(10**18).div(_gCoinExchangePrice);

        uint256 fee = 0;
        if(_hasFee){
            fee = tokenAmount.mul(_exchangeFee).div(100);
            tokenAmount = tokenAmount.sub(fee);
        }
        require(IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) >= tokenAmount, "Reward pool does not have enough token balance");

        address userAddress = _msgSender();
        
        IERC20Upgradeable(_tokenAddress).safeTransfer(userAddress, tokenAmount);

        totalTokenReleased = totalTokenReleased.add(tokenAmount);

        totalGCoinExchanged = totalGCoinExchanged.add(gCoinAmount);

        emit ExchangeToken(gCoinAmount, tokenAmount, userAddress, _gCoinExchangePrice, fee);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
 
    function isValidData(uint256 _gAmount, bool _hasFee, uint256 _nonce, bytes memory sig, bytes memory walletSig) public view returns(bool){
        address _walletAddress = _msgSender();
        require(_walletAddress==_msgSender(),"Not signed by the user");
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(_gAmount, _walletAddress, _hasFee, _nonce, sig))
        );
        require(recoverSigner(message, walletSig)==_msgSender(),"Not signed by the user"); // verify that the wallet signed the message

        bytes32 signedMessage = keccak256(abi.encodePacked(_gAmount, _walletAddress, _hasFee, _nonce));
        require(whitelistedExchanger[recoverSigner(signedMessage, sig)]==true, "Not signed by the authority");

        return true;
    }

   function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}