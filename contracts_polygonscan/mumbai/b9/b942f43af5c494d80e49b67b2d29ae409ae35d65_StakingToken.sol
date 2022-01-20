/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/main.sol



pragma solidity 0.8.7;




contract StakingToken is  Ownable{

    address admin;
    uint256 public minimumInvestment ;
    uint256 public firstRefererReward ;
    uint256 public secondRefererReward ;
    uint256 public STARTERS_APY ;
    uint256 public RIDE_APY ;
    uint256 public FLIGHT_APY ;
    mapping(address => user) private user_list;


    struct user {
        address referer;
        uint256 accumulatedReward;
        uint256 stakedAmount;
        uint256 starttime; 
        uint256 package; // { STARTERS , RIDE, FLIGHT } 0,1,2 
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Not an Admin");
      _;
    }


    IERC20 agro = IERC20(0xedBe70ef62b74730215728eD6B3F1f8705E3c58B);



    constructor( )  { 
        admin = owner();
        minimumInvestment = 1000; // 1000 AMT tokens
        firstRefererReward = 2; 
        secondRefererReward = 1;
        STARTERS_APY = 5 ;
        RIDE_APY = 7;
        FLIGHT_APY = 10 ;
        
    }

    function set_admin(address _admin) public onlyOwner {
        admin = _admin ;
    }
    function set_minimumInvestment(uint256 temp) public onlyAdmin {
        minimumInvestment = temp;
    }
    function set_firstRefererReward(uint256 temp) public onlyAdmin {
        firstRefererReward = temp;
    }
    function set_secondRefererReward(uint256 temp) public onlyAdmin {
        secondRefererReward = temp;
    }
    function set_STARTERS_APY(uint256 temp) public onlyAdmin {
        STARTERS_APY = temp;
    }
    function set_RIDE_APY(uint256 temp) public onlyAdmin {
        RIDE_APY = temp;
    }
    function set_FLIGHT_APY(uint256 temp) public onlyAdmin {
        FLIGHT_APY = temp;
    }


    function stake(uint256 _stake, uint256 _package, address _referer) public {

        require (agro.allowance(msg.sender, address(this)) >= _stake, "Allowance not given" );
        require( _stake >= minimumInvestment, "Sent Less than Minimum investment");

        agro.transferFrom (msg.sender, address(this), _stake);

        _stake = distributeReward( _stake ); // gives reward to referer

        user_list[msg.sender].accumulatedReward += calculateReward(msg.sender) ; // saves any not withdrawn rewards before staking again

        user_list[msg.sender].starttime = block.timestamp;
        user_list[msg.sender].stakedAmount += _stake;
        user_list[msg.sender].referer = _referer;
        user_list[msg.sender].package = _package;
    
        
    }


    function unStake(uint256 _stake) public {
        require ( stakeOf(msg.sender) > 0 , "Nothing staked" ) ;
        require( (user_list[msg.sender].stakedAmount - _stake) >= 0 , "Cant remove more than stake");

        uint256 w_reward = user_list[msg.sender].accumulatedReward + calculateReward(msg.sender);
        
        user_list[msg.sender].stakedAmount -= _stake;
        user_list[msg.sender].accumulatedReward = 0;
        user_list[msg.sender].starttime = block.timestamp ;
    
        agro.transfer (msg.sender, _stake+w_reward);
    }

    // returns TVL in this contract
    function getTotalStaked() public view returns(uint256) {
        return agro.balanceOf(address(this) ) ;
    }


    function stakeOf(address _stakeholder) public view returns(uint256) {
        return user_list[_stakeholder].stakedAmount;
    }


    // calculates rewards based on packages
    function calculateReward (address _stakeholder) view internal returns (uint256){
            uint256 roi = 0;
            uint256 time = block.timestamp - user_list[_stakeholder].starttime;
            
            if (user_list[_stakeholder].package == 0 ) // STARTERS
            {
                require( time >= 90 days, "Lockup period not finished" ); // 3 months lock up
                roi = time / 30 days * ( user_list[_stakeholder].stakedAmount * STARTERS_APY/100 ) ;

            }
            if (user_list[_stakeholder].package == 1 ) // RIDE
            {
                require( time >= 180 days, "Lockup period not finished" ); // 6 months lock up
                roi = time / 30 days * ( user_list[_stakeholder].stakedAmount * RIDE_APY/100 ) ;

            }
            if (user_list[_stakeholder].package == 2 ) // FLIGHT
            {
                require( time >= 365 days, "Lockup period not finished" ); // 1 year lock up   
                roi = time / 30 days * ( user_list[_stakeholder].stakedAmount * FLIGHT_APY/100 ) ;
            }

            return roi; 

       }

    // gives rewards to referer
    function distributeReward (uint256 _stake) internal returns(uint256) {
        address t_ref = user_list[msg.sender].referer ; 
        if ( t_ref != address(0)) {
            agro.transfer ( t_ref , _stake * firstRefererReward /100 ); // referer of msg.sender

            t_ref = user_list[ t_ref ].referer ;
            if  ( t_ref != address(0) ){
                agro.transfer ( t_ref , _stake * secondRefererReward /100 ); // referer of referer
            }
            else
                return _stake - ( _stake * firstRefererReward /100 ); // when only first referer existed

            return _stake - ( _stake * firstRefererReward /100 ) - (_stake * secondRefererReward /100 ) ; // when both referers existed
    
        }
        else
        return _stake; //when no referer existed
    }       

     



}