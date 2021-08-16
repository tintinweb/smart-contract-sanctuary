/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

// File: contracts/PaymentSplitterNoMint.sol
pragma solidity ^0.8.0;




/**
* @title AuthToken
* @dev based on ERC20, but non-transferable. Should have balanceOf not changed
 */
interface AuthToken{
    function balanceOf(address) external returns(uint256);
}

/**
* @dev to mint POE tokens
 */
interface PoExtended{
    function mint(address) external returns (bool);
}

/**
* @title PriceCurve
* @dev PriceCurve contract can be made to calculate price curve in funky ways. Optional
 */
interface PriceCurve{
    function getPrice(uint256, address) external returns(uint256);
}

/**
* @title NFT
* @dev ERC721 contract that holds the bonus NFTs
 */
interface NFT{
    function ownerOf(uint256) external view returns (address);
}

/**
* @title PaymentSlitter
* @author Carson Case > [email protected]
* @dev is ownable. For now, by deployer, but can be changed to DAO
 */
contract PaymentSplitter is Ownable, Pausable{

    //Treasury address
    address payable public treasury;

    //Base commission rate for refferals. Decimal expressed as an interger with decimal at 10^18 place.
    uint256 public baseCommission;

    //Auth token address
    address authTokenAddress;

    //xGDAO address
    address xGDAO;

    //Price curve address
    address priceCurveAddress;

    //NFT bonus address
    address bonusNFTAddress;

    //Lookup if address has already purchased
    mapping(address => bool) public hasPurchased;

    //Keep track of who has referred how many people
    mapping(address => uint) public referallCount;

    //Referrer whitelist
    mapping(address => bool) public referrerWhitelist;

    //Count the total buyers
    uint256 public buyerCount = 1;

    //Max referrals
    uint256 public maxReferrals = 0;

    //Free if a users holds this much xGDAO or more
    uint256 minXGDAOFree;

    //Nft bonus info
    struct nftBonus{
        uint128 id;
        //Decimal expressed as an interger with decimal at 10^18 place.
        uint128 multiplier;
    }

    //Array of NFT bonus info
    nftBonus[] bonusNFTs; 

    /**
    * @notice arrays must have the same length 
    * @param _treasury address to receive payments
    * @param _authTokenAddress to confirm authorized
    * @param _priceCurveAddress to calculate price curve. OPTIONAL: pass 0 address if you want to use default Z curve. See get Price funciton
    * @param _bonusNFTAddress to look up bonus NFTs
    * @param _commission base referral commission before bonus
    * @param _bonusNFTIDs ids of bonus NFTs (length must match multipliers)
    * @param _bonusNFTMultipliers multipliers of bonus NFTs (length must match IDs) 100% is 10^18
     */
    constructor(
        address payable _treasury,
        address _authTokenAddress,
        address _xGDAOAddress,
        address _priceCurveAddress,
        address _bonusNFTAddress,
        uint256 _commission,
        uint128[] memory _bonusNFTIDs,
        uint128[] memory _bonusNFTMultipliers
        ) 
        Ownable()
        {
        bonusNFTAddress = _bonusNFTAddress;
        _addBonusNFTs(_bonusNFTIDs, _bonusNFTMultipliers);

        treasury = _treasury;
        authTokenAddress = _authTokenAddress;
        xGDAO = _xGDAOAddress;
        priceCurveAddress = _priceCurveAddress;
        baseCommission = _commission;

    }

    /// @dev set xGDAO address
    function setXGDAOAddress(address _new) external onlyOwner{
        xGDAO = _new;
    }

    /// @dev set maxReferrals. If zero, no max
    function setMaxReferrals(uint _new) external onlyOwner{
        maxReferrals = _new;
    }

    /// @dev set minXGDAO. If zero, no free amount
    function steMinXGDAOFree(uint _new) external onlyOwner{
        minXGDAOFree = _new;
    }

    /// @dev add referrers to a whitelist
    function addToReferrerWhitelist(address[] memory _list) external onlyOwner{
        for(uint i = 0; i < _list.length; i++){
            referrerWhitelist[_list[i]] = true;
        }
    }

    /// @dev remove referrers from whitelist
    function removeFromeReferrerWhitelist(address[] memory _list) external onlyOwner{
        for(uint i = 0; i < _list.length; i++){
            referrerWhitelist[_list[i]] = false;
        }
    }


    /**
    * @notice purchase function. Can only be called once by an address
    * @param _referrer must have an auth token. Pass 0 address if no referrer
     */
    function purchasePOE(address payable _referrer) external payable {
        //If the referrer is not authenticated treat the call as if there is no referrer
        if(AuthToken(authTokenAddress).balanceOf(_referrer) != 1){
            _referrer = payable(0);
        }

        uint256 price = getPrice(buyerCount, address(_referrer));
        if(minXGDAOFree != 0 && IERC20(xGDAO).balanceOf(msg.sender) >= minXGDAOFree){
            price = 0;
        }

        require(msg.value == price, "You must pay the exact price to purchase. Call the getPrice() function to see the price in wei");
        require(!hasPurchased[msg.sender],"You may only purchase once per address");


        referallCount[_referrer]++;
        //If there is a referrer send them commission. If free then don't bother with commissions
        if(price > 0){
            //Give commisson if there's a referrer and he hasn't surpassed max, if he's not whitelisted, or of course, there is no max
            if(
            _referrer != address(0) && 
            (
            referrerWhitelist[_referrer] ||
            maxReferrals == 0 ||
            referallCount[_referrer] < maxReferrals
            )
            ){
                uint256 rebate = (price * 5) / 100;         //5% rebate if using a referrer
                price = price - rebate;
                payable(msg.sender).transfer(rebate);
                //Calculate commission and subtract from price to avoid rounding errors
                uint256 commission = getCommission(price, _referrer);
                _referrer.transfer(commission);
                treasury.transfer(price-commission);
                //If not, treasury gets all the price
            }else{
                treasury.transfer(price);
            }
        }

        //Mark buyer as having purchased
        hasPurchased[msg.sender] == true;
        
        // Only increase buyer count if not paused
        if(!paused()){
            buyerCount++;
        }
    }

    /**
    * @notice for owner to change base commission
    * @param _new is new commission
     */
    function changeBaseCommission(uint256 _new) external onlyOwner {
        baseCommission = _new;
    }

    /**
    * @notice for owner to change the price curve contract address
    * @param _new is the new address
     */
    function changeCurve(address _new) external onlyOwner{
        priceCurveAddress = _new;
    }

    /**
    * @notice for owner to add some new bonus NFTs
    * @dev see _addBonusNFTs
    * @param _bonusNFTIDs array of IDs
    * @param  _bonusNFTMultipliers array of multipliers
     */
    function addBonusNFTs(uint128[] memory _bonusNFTIDs, uint128[] memory _bonusNFTMultipliers) public onlyOwner{
        _addBonusNFTs(_bonusNFTIDs, _bonusNFTMultipliers);
    }

    /**
    * @notice function to return the current price based on buyer count
    * @dev if priceCurveAddress is 0 address use the default z curve. If not use that contracts price curve function
    * @return the price
     */
    function getPrice(uint _buyerCount, address _referrer) public returns(uint256) {
        // Only charge a price if the free buyer period is over.
        // Still in free period if buyer count is not increasing from it's start: 1
        if(_buyerCount > 1){
            //If no custom priceCurve specified, use the default 'price Z'
            if(priceCurveAddress == address(0)){
                //Price Z. Flat rate for under 1,000 users and over 10,000 users. In between variable rate
                if(_buyerCount < 1000){
                    return 10**16;
                }else if(_buyerCount < 10000){
                    return (10**16 * (_buyerCount - 1000) * 10**13) / 10**18;
                }else{
                    return 10**17;
                }
            }else{
                return PriceCurve(priceCurveAddress).getPrice(_buyerCount, _referrer);
            }
        }else{
            return 0;
        }
    }

    /**
    * @notice function returns the commission based on base commission rate, NFT bonus, and price
    * @param _price is passed in, but should be calculated with getPrice()
    * @param _referrer is to look up NFT bonuses
    * @return the commission ammount
     */
    function getCommission(uint256 _price, address _referrer) internal view returns(uint256){
        uint128 bonus = getNFTBonus(_referrer);
        uint256 commission;
        if(bonus != 0){
            commission = (baseCommission * bonus)/10**18;
        }else{
            commission = baseCommission;
        }      
        return((_price * commission) / 1 ether);
    }

    /**
    * @notice function to get the NFT bonus of a person
    * @param _referrer is the referrer address
    * @return the sum of bonuses they own
     */
    function getNFTBonus(address _referrer) public view returns(uint128){
        uint128 bonus = 0;
        NFT nft = NFT(bonusNFTAddress);
        //Loop through nfts and add up bonuses that the referrer owns
        for(uint8 i = 0; i < bonusNFTs.length; i++){
            if(nft.ownerOf(bonusNFTs[i].id) == _referrer){
                bonus += bonusNFTs[i].multiplier;
            }
        }
        return bonus;
    }

    /**
    * @notice private function to add new NFTs as bonuses 
    * @param _bonusNFTIDs array of ids matching multipliers
    * @param _bonusNFTMultipliers array of multipliers matching ids
     */
    function _addBonusNFTs(uint128[] memory _bonusNFTIDs, uint128[] memory _bonusNFTMultipliers) private{
        require(_bonusNFTIDs.length == _bonusNFTMultipliers.length, "The array parameters must have the same length");
        //Add all the NFTs
        for(uint8 i = 0; i < _bonusNFTIDs.length; i++){
            bonusNFTs.push(
                nftBonus(_bonusNFTIDs[i],_bonusNFTMultipliers[i])
            );
        }
    }

}