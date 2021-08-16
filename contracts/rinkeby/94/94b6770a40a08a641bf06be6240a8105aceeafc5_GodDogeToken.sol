/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

/**
 *Submitted for verification at Etherscan.io on !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * 
 * @dev FYI: `SafeMath` is no longer needed starting with Solidity 0.8. 
 * The compiler now has the built in overflow checking.
 * Check: https://docs.soliditylang.org/en/v0.8.6/080-breaking-changes.html
 * 
 * That is why you see '+', '-', '*' etc operators instead of SafeMath;s 'add', 'sub', 'mul' etc respectively. It is SAFU :)
 * 
 * OpenZeppelin uses 'unchecked { ... }' where the values 100% will not overflow.
 * 
 */

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner is the zero address. Use the 'renounceOwnership()' function instead");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title Context
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
        return msg.data;
    }
}

/**
 * @title GodDogGame
 * These are just the basic functions that will be implemented in the game.
 * The real GodDogGame contract for sure extends this interface.
 * 
 * The reason why this block of code is included in the token contract is that
 * it is used in the 'redeemTokensForGame()' function. Plus we wanted to give you kinda sneak pic of a Game code.
 */
interface GodDogeGame {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    
    /**
     * Redeem your tokens for the game. Used in the end of the GodDogeToken contract.
     * Can be called only from this smart-contract — (address(this)).
     */
    function redeemTokensForGame(address receiver, uint256 amount) external returns(bool); 
    
    
    /**
     * Sends you the Pray NFT, gives the chance to win a lottery. Read more on our medium post.
     */
    function pray(uint256 churchId, uint256 cityOrVillageId) payable external returns (bool); 
    
    /**
     * Some basic things that could be done with Cities
     */
    function buildCity(uint256 x_coordinate, uint256 y_coordinate) external returns(bool); //payed with City NFT
    event CityBuilt(address cityOwner, uint256 x_coordinate, uint256 y_coordinate);
    
    function revokecity(uint256 cityId) external returns(bool); //sends your NFT back
    event CityRevoked(uint256 cityId);
    
    function settleInTheCity() external returns(uint256);
    event SettleInTheCity(address user, uint256 cityId);
    
    /**
     *  ... with Villages
     */
    function buildVillage(uint256 x_coordinate, uint256 y_coordinate) external returns(bool); //payed with Village NFT
    event VillageBuild(address villageOwner, uint256 x_coordinate, uint256 y_coordinate);
    
    function revokeVillage(uint256 villageId) external returns(bool);
    event VillageRevoked(uint256 villageId);
    
    function settleInTheVillage() external returns(uint256);
    event SettleInTheVillage(address user, uint256 villageId);
    
    /**
     *  ... Churches
     */
    function buildChurch(uint256 cityOrVillageId) external returns(bool);
    event ChurchBuild(address churchOwner, uint256 cityOrVillageId, uint256 churchId);
    
    function revokeChurch(uint256 churchId) external returns(bool);
    event ChurchRevoked(uint256 churchId);
    
    function joinChurch(uint256 churchId) external returns(bool);
    event ChurchJoin(address user, uint256 churchId);
    
    /**
     *  .... Monuments
     */
    function buildMonument(uint256 cityOrVillageId) external returns(bool);
    event MonumentBuild(address monumentOwner, uint256 cityOrVillageId, uint256 monumentId);
    
    function revokeMonument(uint256 monumentId) external returns(bool);
    event MonumentRevoked(uint256 monumentId);
    
    /**
     * Basic Marketplace finctions
     */
    function setOrder(uint256 NFTId, uint256 price, uint256 expiryDate) external returns(bool);
    event OrderSet(address seller, uint256 orderId, uint256 price);
    
    function buyOrder(uint256 orderId) payable external returns(bool);
    event OrderBought(address buyer, address seller, uint256 orderId, uint256 price);
    
    function cancelOrder(uint256 orderId, bytes32 sig) external returns(bool);
    event OrderCancelled(uint256 orderId);
    
    function ordersCanMatch(uint256 buyId, uint256 sellId) external view returns (bool);
    function executeFundsTransfer(uint256 buyerId, uint256 sellerId) external returns (uint);
   
    
    event ReceivedBNB(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * IERC20 interface
 * @dev Full version of IERC20 interface
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



contract GodDogeToken is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    bool private _isGodDogeGameDeployed;
    address private _GodDogeGameAddress;
    
    bool isAirdropEnded = false;
    uint256 private _alreadyAirdropped = 0;
    uint256 private _refererRevenue = 2500; // 25% or 0.001 BNB
    uint256 private _airdropFee = 4 * 10**15; // 0.004 BNB
    uint256 private _airdropAmount = 200 * 10**18; // 200 tokens
    
    address payable private _liquidityWallet; //the rokens will be locked by TrustSwap
    address private _communityIncentivesWallet; //the address rewards to the best shillers and community supporters will be distributed from 
    address private _teamWallet;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint256 supply, address payable liquidityWallet, address communityIncentivesWallet, address teamWallet) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = supply;
        
        _liquidityWallet = liquidityWallet;
        _communityIncentivesWallet = communityIncentivesWallet;
        _teamWallet = teamWallet;
        
        _mint(_liquidityWallet, _totalSupply / 10); //10% of the supply, will be locked by TrustSwap
        _mint(_communityIncentivesWallet, _totalSupply / 20); //5% of the total supply, will be evenly distributed among the best shillers and community contributers&supporters
        _mint(_teamWallet, _totalSupply/20); //5% of the total supply
    }
    
    /**
     * @dev Tells whether the GodDogeGame have been already deployed.
     */
    function isGodDogeGameDeployed() public view virtual returns (bool) {
        return _isGodDogeGameDeployed;
    }
    
    /**
     * @dev Returns the GodDogeGame address.
     */
    function GodDogeGameAddress() public view virtual returns(address) {
        return _GodDogeGameAddress;
    }
    
    /**
     * Returns the liquidity wallet
     */
     
     function LiquidityWallet() public view virtual returns (address payable) {
        return _liquidityWallet;
    }
    
    /**
     * Returns the marketing wallet
     */
     
     function CommunityIncentivesWallet() public view virtual returns (address) {
         return _communityIncentivesWallet;
     }
     
     function TeamWallet() public view virtual returns (address) {
         return _teamWallet;
     }
    
    /**
     * @dev Returns amount a user needs to pay for getting the tokens.
     */
    function AirdropFee() public view virtual returns(uint256) {
        return _airdropFee;
    }
    
    /**
     * @dev Returns the revenue a referer gets for introducing the airdrop for other users.
     * Divide it by 10000 and get 0.3 or 30%.
     */
    function RefererRevenue() public view virtual returns(uint256) {
        return _refererRevenue;
    }
    
    /**
     * @dev Returns the amount each user gets for the airdrop. 200 tokens
     */
    function AirdropAmount() public view virtual returns(uint256) {
        return _airdropAmount;
    }
    
    /**
     * @dev Returns the amount of tokens that has already been distributed.
     */
    function AlreadyAirdropped() public view virtual returns(uint256) {
        return _alreadyAirdropped;
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    /** @dev Creates `amount` tokens and assigns them to `account`. Used by 'getAirdrop' function only.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual { //an internal function i.e. may be called only within the contract.It is used by the 'getAirdrop' function only
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * Transfers the accidentally sent BNB to this contract to the liquidity wallet
     */
    function BNBfromTheFallbackToLiquidity() public onlyOwner() {
        LiquidityWallet().transfer(address(this).balance);
    }
    
    /**
     * Checks whether all 80% of the total supply (8M tokens) have already been distributed;
     * If true, then finishes the airdrop;
     */
    function checkAirdropFinish() internal virtual{
        if (AlreadyAirdropped() >= 8 * 10**6 * 10**18){
            isAirdropEnded = true;
        }
        emit AirdropFinished();
    }
    /**
     * @dev This function is called by the owner with 'GameAddress' as a parameter which then will be used as a value
     * for the _GodDogeGameAddress attribute.
     * It also assigns _isGodDogeGameDeployed a 'true' value.
     *
     * Emits an {GameDeployed} event.
     *
     * Requirements:
     *
     * - `_isGodDogeGameDeployed` cannot be true.
     * - `_GodDogeGameAddress` must be the zero address.
     */
    function deployTheGodDogeGame(address GameAddress) public virtual onlyOwner() returns(bool){
        require(!isGodDogeGameDeployed() && GodDogeGameAddress() == address(0), "The Game has been already deployed");
        _GodDogeGameAddress = GameAddress;
        _isGodDogeGameDeployed = true;
        
        emit GameDeployed(GameAddress);
        return true;
    }
    
    /**
     * Sends 200 tokens directly to the user's address.
     * 
     * Requirements:
     * - 'isAirdropEnded' must be false
     * - 'msg.value' must be equal to '_airdropFee'
     */
    function getAirdrop(address payable referer) payable public returns(bool){
        require(!isAirdropEnded, "Airdrop is already ended. All 80% of total supply were airdropped to the community");
        require(msg.value == AirdropFee(),"Please, send a transaction with a sufficient fee as a message.value");
        
        uint256 amount = AirdropAmount(); 
        _mint(_msgSender(), amount); 
        _alreadyAirdropped += amount;
        emit Airdropped(_msgSender(), amount);
        
        uint256 liquidityFee = msg.value;
        if(referer != address(0)) {
            
            uint256 refererRevenue = AirdropFee() * RefererRevenue() / 10000; // * 0.25 or 25%
            liquidityFee -= refererRevenue;
            
            referer.transfer(refererRevenue);
        }
        
        LiquidityWallet().transfer(liquidityFee);
        
        checkAirdropFinish();
        
        return true;
    }
    
    /**
     * @dev This function is used to redeem the 'amount' tokens from this contract to the GodDogeGame smart-contract.
     *
     * Emits an {TokensRedeemed} event.
     *
     * Requirements:
     *
     * The GodDogeGameGame must be already deployed:
     *  - `_isGodDogeGameDeployed` must be true.
     *  - `_GodDogeGameAddress` cannot be the zero address.
     * 
     * - 'amount' must be lower or equal to the senders balance.
     */
    function redeemTokensForGame(uint256 amount) public virtual returns(bool){
        require(isGodDogeGameDeployed(), "The GodDogeGame has not been deployed yet");
        require(GodDogeGameAddress() != address(0), "The GodDogeGameAddress has not been set");
        require(_msgSender() != address(0), "Redeem from the zero address");
        
        uint256 senderBalance = _balances[_msgSender()];
        require(senderBalance >= amount, "Redeem amount exceeds balance");
        unchecked {
            _balances[_msgSender()] = senderBalance - amount;
        }
        
        GodDogeGame(GodDogeGameAddress()).redeemTokensForGame(_msgSender(), amount);
        emit TokensRedeemed(_msgSender(), amount);
        
        return true;
    }
    
    event AirdropFinished();
    event Airdropped(address receiver, uint256 amount);
    
    event GameDeployed(address GodDogeGameAddress);
    event TokensRedeemed(address user, uint256 amount);
    
    fallback() payable external {
    }

    receive() payable external {
    }
}