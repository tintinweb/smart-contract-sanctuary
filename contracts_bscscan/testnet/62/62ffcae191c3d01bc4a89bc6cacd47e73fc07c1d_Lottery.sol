/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;
pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}
interface NFT {
    function mint(address to, uint seri,
        uint startTime,
        uint endTime,
        uint result,
        uint status,
        uint winTickets,
        address buyer,
        uint buyTickets,
        string calldata asset) external returns (uint256);
    function metadatas(uint _tokenId) external view returns (uint seri,
        uint startTime,
        uint endTime,
        uint result,
        uint status,
        uint winTickets,
        address buyer,
        uint buyTickets,
        string memory asset);
    function burn(uint256 tokenId) external;
}
interface Stake {
    function depositProfit(address _bep20, uint _amount) external;
}
contract Lottery is Ownable {
    using SafeMath for uint256;
    uint constant public MAX_LOOP = 100;
    address public signer = 0x7a7f38737BFCD8a1301Dd262a226780350980eA3;
    uint public currentSignTime;
    string[] public priceFeeds = ['BNB','BUSD','BTCB','BSC-USD','ETH','USDC','XRP'];
    struct asset {
        string symbol;
        address asset;
        AggregatorV3Interface priceFeed;
    }
    mapping(string => asset) assets;
    address payable public operator = 0x2076A228E6eB670fd1C604DE574d555476520DB7;
    address payable public affiliateAddress = 0x2076A228E6eB670fd1C604DE574d555476520DB7;
    address payable public stake = 0x847163fCc6ff24bCA0e8BA9e7d568158c0141645;
    address payable public purchase = 0x2076A228E6eB670fd1C604DE574d555476520DB7;
    address payable public carryOver = 0x2076A228E6eB670fd1C604DE574d555476520DB7;
    NFT public nft = NFT(0x00037aD800e657fe545110D2454a606A3B9596a8);
    
    uint public price = 100 ether; // number of token per 1 ether BUSD;
    uint public share2Stake = 2;
    uint public share2Purchase = 2;
    uint public share2affiliate = 40;
    uint public share2Operator = 16;
    uint public expiredPeriod = 259200;
    struct seri {
        uint price;
        uint soldTicket; 
        uint[] assetIndex;
        uint result;
        uint status; // status - index 0 open; 1 close; 2 win; 3 lose
        uint[] winners; // NFT token Id
        uint endTime;
        uint[] prizetaked;
        bool takeAssetExpired;
        uint max2sale;
        uint totalWin;
    }
    struct ticket {
        uint number;
        uint buyTicket;
    }
    mapping(uint => seri) public series;
    mapping(uint => mapping(uint => uint)) public seriAssetSoldTotal; // seri => asset index => total
    mapping(uint => mapping(uint => uint)) public seriAssetRemain; // seri => asset index => remain
    mapping(uint => mapping(address => ticket[])) public userTickets; // seri => user => ticket[]
    
    event OpenSeri(uint _seri, uint _price);
    event CloseSeri(uint _seri, uint _endTime);
    event OpenResult(uint _seri, bool _isWin);
   
    constructor () public {
        assets['BNB'] = asset('BNB', address(0), AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526));
        assets['BUSD'] = asset('BUSD', 0x10297304eEA4223E870069325A2EEA7ca4Cd58b4, AggregatorV3Interface(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa));
        assets['BTCB'] = asset('BTCB', 0xf6f3F4f5d68Ddb61135fbbde56f404Ebd4b984Ee, AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C));
        assets['BSC-USD'] = asset('BSC-USD', 0x013345B20fe7Cf68184005464FBF204D9aB88227, AggregatorV3Interface(0xEca2605f0BCF2BA5966372C99837b1F182d3D620));
        assets['ETH'] = asset('ETH', 0x979Db64D8cD5Fed9f1B62558547316aFEdcf4dBA, AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7));
        assets['USDC'] = asset('USDC', 0xF53E2228ff7F680D4677878eeA2c7814a5233C85, AggregatorV3Interface(0x90c069C4538adAc136E051052E14c1cD799C41B7));
        assets['XRP'] = asset('XRP', 0xd2926D1f868Ba1E81325f0206A4449Da3fD8FB62, AggregatorV3Interface(0x4046332373C24Aed1dC8bAd489A04E187833B28d));
    }
    function permit1(bytes32 digest, uint8 v, bytes32 r, bytes32 s) public view returns (address recoveredAddress){
        recoveredAddress = ecrecover(digest, v, r, s);
    }
    function permit(string memory _result, uint _currentSignTime, uint8 v, bytes32 r, bytes32 s) public returns (bool isValid){
        require(_currentSignTime <= block.timestamp && _currentSignTime > currentSignTime, 'NFTLottery: Invalid Time');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                _result,
                _currentSignTime)
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        isValid = recoveredAddress != address(0) && recoveredAddress == operator;
        if(isValid) currentSignTime = _currentSignTime;
    }
    function getPriceFeeds() public view returns(string[] memory _symbols) {
        return priceFeeds;
    }
    function getAsset(string memory _symbol) public view returns(asset memory _asset) {
        return assets[_symbol];
    }
    function getSeries(uint _seri) public view returns(seri memory) {
        return series[_seri];
    }
    function getSeriesAssets(uint _seri) public view returns(uint[] memory) {
        return series[_seri].assetIndex;
    }
    function metadatas(uint _tokenId) external view returns (uint,
        uint,
        uint,
        uint,
        uint,
        uint,
        address,
        uint,
        string memory){
            return nft.metadatas(_tokenId);
    }
        
    function getUserTickets(uint _seri, address _user) public view returns(ticket[] memory) {
        return userTickets[_seri][_user];
    }
    function getLatestPrice(string memory _symbol) public view returns (int) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = assets[_symbol].priceFeed.latestRoundData();
        return price * 10**10;
    }
    function asset2USD(string memory _symbol) public view returns (uint _amountUsd){
        return uint(getLatestPrice(_symbol));
    }
    function ticket2Asset(uint seri, string memory _symbol) public view returns(uint _amountUsd){
        uint256 expectedRate = asset2USD(_symbol);
        return series[seri].price.mul(1 ether).div(expectedRate);
    }
    function openSeri(uint _seri, uint _max2sale) public onlyOwner {
        require(series[_seri].price == 0, 'seri existed');
        series[_seri].price = price;
        series[_seri].max2sale = _max2sale;
        emit OpenSeri(_seri, price);
    }
    function takeAsset2CarryOver(uint _seri) internal {
        for(uint i = 0; i < series[_seri].assetIndex.length; i++) {
            if(seriAssetSoldTotal[_seri][series[_seri].assetIndex[i]] > 0) {
                uint takeAmount = seriAssetSoldTotal[_seri][series[_seri].assetIndex[i]];
                if(series[_seri].assetIndex[i] == 0) carryOver.transfer(takeAmount);
                else {
                    string memory _symbol = priceFeeds[series[_seri].assetIndex[i]];
                    IBEP20 _asset = IBEP20(assets[_symbol].asset);
                    require(_asset.transfer(carryOver, takeAmount), 'insufficient-allowance');
                }
                seriAssetRemain[_seri][series[_seri].assetIndex[i]] = 0;
            }
        }
    }
    function closeSeri(uint _seri) public onlyOwner {
        require(series[_seri].status == 0, 'seri not open');
        require(series[_seri].soldTicket == series[_seri].max2sale, 'Tickets are not sold out yet');
        series[_seri].status = 1;
        emit CloseSeri(_seri, now);
    }
    function openResult(uint _seri, bool _isWin, uint _result, uint _totalWin) public onlyOwner {
        require(series[_seri].status == 1, 'seri not close');
        series[_seri].result = _result;
        if(_isWin) {
            series[_seri].status = 2;
            series[_seri].totalWin = _totalWin;
        }
        else  {
            takeAsset2CarryOver(_seri);
            series[_seri].status = 3;
        }
        emit OpenResult(_seri, _isWin);
    }
    function setWinners(uint _seri, uint startTime, address[] memory _winners, uint[] memory _buyTickets, string[] memory _assets) public onlyOwner {
        seri storage sr = series[_seri];
        require(sr.status == 2, 'seri not winner');
        require(_winners.length <= MAX_LOOP, 'Over max loop');
        for(uint i = 0; i < _winners.length; i++) {
            for(uint j = 0; j < _buyTickets[i]; j++) {
                series[_seri].winners.push(nft.mint(_winners[i], _seri, startTime, now, sr.result, 2, sr.totalWin, _winners[i], 1, _assets[i]));
            }
        }
    }
    function takeAsset(uint _seri, uint _winTickets, uint _buyTickets) internal {
        for(uint i = 0; i < series[_seri].assetIndex.length; i++) {
            if(seriAssetSoldTotal[_seri][series[_seri].assetIndex[i]] > 0) {
                uint takeAmount = seriAssetSoldTotal[_seri][series[_seri].assetIndex[i]].mul(_buyTickets).div(_winTickets);
                if(series[_seri].assetIndex[i] == 0) msg.sender.transfer(takeAmount);
                else {
                    string memory _symbol = priceFeeds[series[_seri].assetIndex[i]];
                    IBEP20 _asset = IBEP20(assets[_symbol].asset);
                    require(_asset.transferFrom(address(this), msg.sender, takeAmount), 'insufficient-allowance');
                }
                seriAssetRemain[_seri][series[_seri].assetIndex[i]] = seriAssetSoldTotal[_seri][series[_seri].assetIndex[i]].sub(takeAmount);
            }
        }
    }
    function takePrize(uint _nftId) public {
        uint _seri;
        uint _winTickets;
        uint _buyTickets;
        (_seri,,,,,_winTickets,,_buyTickets,) = nft.metadatas(_nftId);
        require(series[_seri].status == 2, 'seri not winner');
        require(series[_seri].endTime.add(expiredPeriod) > now, 'Ticket Expired');
        series[_seri].prizetaked.push(_nftId);
        takeAsset(_seri, _winTickets, _buyTickets);
        nft.burn(_nftId);
        
    }
    function _takePrizeExpired(uint _seri) internal {
        for(uint i = 0; i < series[_seri].assetIndex.length; i++) {
            if(seriAssetRemain[_seri][series[_seri].assetIndex[i]] > 0) {
                uint takeAmount = seriAssetRemain[_seri][series[_seri].assetIndex[i]];
                if(series[_seri].assetIndex[i] == 0) operator.transfer(takeAmount);
                else {
                    string memory _symbol = priceFeeds[series[_seri].assetIndex[i]];
                    IBEP20 _asset = IBEP20(assets[_symbol].asset);
                    require(_asset.transfer(operator, takeAmount), 'insufficient-allowance');
                }
                seriAssetRemain[_seri][series[_seri].assetIndex[i]] = 0;
            }
        }
        
    }
    function takePrizeExpired(uint _seri) public onlyOwner {
        require(series[_seri].status == 3, 'seri have winner');
        require(!series[_seri].takeAssetExpired, 'Taked');
        require(series[_seri].endTime.add(expiredPeriod) < now, 'Ticket not Expired');
        
        _takePrizeExpired(_seri);
        series[_seri].takeAssetExpired = true;
    }
    function buy(uint _seri, uint[] memory _number, uint[] memory _numTicket, uint _assetIndex) public payable{
        require(_number.length == _numTicket.length, 'invalid array length');
        uint assetPerTicket = ticket2Asset(_seri, priceFeeds[_assetIndex]);
        
        uint totalTicket;
        for(uint i = 0; i < _number.length; i++) {
            totalTicket += _numTicket[i];
            userTickets[_seri][msg.sender].push(ticket(_number[i], _numTicket[i]));
        }
        require(series[_seri].soldTicket + totalTicket <= series[_seri].max2sale, 'over max2sale');
        uint assetAmount = assetPerTicket.mul(totalTicket);
        uint shareStakeAmount = assetAmount.mul(share2Stake).div(100);
        uint sharePurchaseAmount = assetAmount.mul(share2Purchase).div(100);
        uint shareAffiliateAmount = assetAmount.mul(share2affiliate).div(100);
        uint takeTokenAmount = assetAmount.mul(share2Operator).div(100);
        if(_assetIndex == 0) {
            require(msg.value >= assetAmount, 'insufficient-balance');
            stake.transfer(shareStakeAmount);
            purchase.transfer(sharePurchaseAmount);
            affiliateAddress.transfer(shareAffiliateAmount);
            operator.transfer(takeTokenAmount);
        }
        else {
            string memory _symbol = priceFeeds[_assetIndex];
            IBEP20 _asset = IBEP20(assets[_symbol].asset);
            require(_asset.transferFrom(msg.sender, address(this), assetAmount), 'insufficient-allowance');
            _asset.approve(address(stake), shareStakeAmount);
            Stake stakeContract = Stake(stake);
            stakeContract.depositProfit(assets[_symbol].asset, shareStakeAmount);
            require(_asset.transfer(purchase, sharePurchaseAmount), 'insufficient-allowance');
            require(_asset.transfer(affiliateAddress, shareAffiliateAmount), 'insufficient-allowance');
            require(_asset.transfer(operator, takeTokenAmount), 'insufficient-allowance');
        }
        
        if(seriAssetSoldTotal[_seri][_assetIndex] == 0) series[_seri].assetIndex.push(_assetIndex);
        uint assetRemain = assetAmount.sub(shareStakeAmount).sub(sharePurchaseAmount).sub(shareAffiliateAmount).sub(takeTokenAmount);
        seriAssetSoldTotal[_seri][_assetIndex] = seriAssetSoldTotal[_seri][_assetIndex].add(assetRemain);
        seriAssetRemain[_seri][_assetIndex] = seriAssetSoldTotal[_seri][_assetIndex];
        series[_seri].soldTicket += totalTicket;
        
    }
    function setAssets(AggregatorV3Interface[] memory _priceFeeds, string[] memory _symbols, address[] memory _bep20s) public onlyOwner {
        require(_priceFeeds.length == _symbols.length && _symbols.length == _bep20s.length, 'invalid length');
        for(uint i = 0; i < _symbols.length; i++) {
            assets[_symbols[i]] = asset(_symbols[i], _bep20s[i], _priceFeeds[i]);
        }
        priceFeeds = _symbols;
    }
    function configAddress(address payable _stake, address payable _purchase, address payable _operator, address payable _affiliateAddress, NFT _nft, address _signer) public onlyOwner {
        stake = _stake;
        purchase = _purchase;
        operator = _operator;
        affiliateAddress = _affiliateAddress;
        nft = _nft;
        signer = _signer;
    }
    function config(uint _price, uint _expiredPeriod, uint _share2Stake, uint _share2Purchase, uint _share2affiliate, uint _share2Operator) public onlyOwner {
        require(_share2Stake + _share2Purchase + _share2affiliate + _share2Operator < 100, 'invalid percent');
        price = _price;
        expiredPeriod = _expiredPeriod;
        share2Stake = _share2Stake;
        share2Purchase = _share2Purchase;
        share2affiliate = _share2affiliate;
        share2Operator = _share2Operator;
    }
    function getRemainingToken(IBEP20 _token) public view returns (uint) {
        return _token.balanceOf(address(this));
    }
}