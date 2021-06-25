/**
 *Submitted for verification at Etherscan.io on 2021-06-24
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

// File: contracts/PaymentSplitter.sol


/**
* @title AuthToken
* @dev based on ERC20, but non-transferable. Should have balanceOf not changed
 */
interface AuthToken{
    function balanceOf(address) external returns(uint256);
}

/**
* @title PriceCurve
* @dev PriceCurve contract can be made to calculate price curve in funky ways. Optional
 */
interface PriceCurve{
    function getPrice(uint256) external returns(uint256);
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
contract PaymentSplitter is Ownable{

    //Treasury address
    address payable public treasury;

    //Base commission rate for refferals. Decimal expressed as an interger with decimal at 10^18 place.
    uint256 public baseCommission;

    //Auth token address
    address authTokenAddress;

    //Price curve address
    address priceCurveAddress;

    //NFT bonus address
    address bonusNFTAddress;

    //Lookup if address has already purchased
    mapping(address => bool) public hasPurchased;

    //Count the total buyers
    uint256 public buyerCount;

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
    * @param _bonusNFTMultipliers multipliers of bonus NFTs (length must match IDs)
     */
    constructor(
        address payable _treasury,
        address _authTokenAddress,
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
        priceCurveAddress = _priceCurveAddress;
        baseCommission = _commission;

    }

    /**
    * @notice purchase function. Can only be called once by an address
    * @param _referrer must have an auth token. Pass 0 address if no referrer
     */
    function purchasePOE(address payable _referrer) external payable{
        uint256 price = getPrice();
        require(msg.value == price, "You must pay the exact price to purchase. Call the getPrice() function to see the price in wei");
        require(!hasPurchased[msg.sender],"You may only purchase once per address");

        require(AuthToken(authTokenAddress).balanceOf(_referrer) == 1 || 
        _referrer == address(0), 
        "Your referrer must be autheticated to receive referrals. Please try again with 0 address if you do not wish to use a referrer");

        //If there is a referrer send them commission
        if(_referrer != address(0)){
            //Calculate commission and subtract from price to avoid rounding errors
            uint256 commission = getCommission(price, _referrer);
            _referrer.transfer(commission);
            treasury.transfer(price-commission);
        //If not, treasury gets all the price
        }else{
            treasury.transfer(price);
        }

        //Mark buyer as having purchased
        hasPurchased[msg.sender] == true;
        buyerCount++;
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
    function getPrice() public returns(uint256) {
        //If no custom priceCurve specified, use the default 'price Z'
        if(priceCurveAddress == address(0)){
            //Price Z. Flat rate for under 1,000 users and over 10,000 users. In between variable rate
            if(buyerCount < 1000){
                return 10**16;
            }else if(buyerCount < 10000){
                return (10**16 * (buyerCount - 1000) * 10**13) / 10**18;
            }else{
                return 10**17;
            }
        }else{
            return PriceCurve(priceCurveAddress).getPrice(buyerCount);
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