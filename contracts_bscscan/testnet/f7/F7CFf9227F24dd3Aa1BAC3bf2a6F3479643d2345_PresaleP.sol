/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: CORECIS

pragma solidity ^0.8.0;

interface IERC20 {
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
    function decimals() external view returns (uint);

    function balanceOf(address _user) external view returns (uint);

    // /**
    //  * @dev Returns the amount of tokens in existence.
    //  */
    // function totalSupply() external view returns (uint256);

    // /**
    //  * @dev Returns the amount of tokens owned by `account`.
    //  */s
    // function balanceOf(address account) external view returns (uint256);

    // /**
    //  * @dev Moves `amount` tokens from the caller's account to `recipient`.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    function transfer(address recipient, uint256 amount) external returns (bool);

    // /**
    //  * @dev Returns the remaining number of tokens that `spender` will be
    //  * allowed to spend on behalf of `owner` through {transferFrom}. This is
    //  * zero by default.
    //  *
    //  * This value changes when {approve} or {transferFrom} are called.
    //  */
    function allowance(address owner, address spender) external view returns (uint256);

    // /**
    //  * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * IMPORTANT: Beware that changing an allowance with this method brings the risk
    //  * that someone may use both the old and the new allowance by unfortunate
    //  * transaction ordering. One possible solution to mitigate this race
    //  * condition is to first reduce the spender's allowance to 0 and set the
    //  * desired value afterwards:
    //  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    //  *
    //  * Emits an {Approval} event.
    //  */
    // function approve(address spender, uint256 amount) external returns (bool);

    // /**
    //  * @dev Moves `amount` tokens from `sender` to `recipient` using the
    //  * allowance mechanism. `amount` is then deducted from the caller's
    //  * allowance.
    //  *
    //  * Returns a boolean value indicating whether the operation succeeded.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // /**
    //  * @dev Emitted when `value` tokens are moved from one account (`from`) to
    //  * another (`to`).
    //  *
    //  * Note that `value` may be zero.
    //  */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // /**
    //  * @dev Emitted when the allowance of a `spender` for an `owner` is set by
    //  * a call to {approve}. `value` is the new allowance.
    //  */
    // event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract PresaleP{
    // state variables
    IERC20 public BUSD;
    IERC20 public FHL; 
    address owner;
    bool public manual = false; 
    uint public priceOne = 400;
    uint public priceTwo = 200;
    uint public priceThree = 20;
    uint public priceFour = 10;
    uint public priceFive = 4;
    uint public priceSix = 2;
    uint public priceSeven = 1;
    
    uint One;
    uint Two;
    uint Three;
    uint Four;
    uint Five;
    uint Six;
    uint Seven;

    //structs


    // constructor
    constructor(address _owner, IERC20 _busd, IERC20 _FHL){
        owner = _owner;
        BUSD = IERC20(_busd);
        FHL = IERC20 (_FHL);
    }
    // modifers
    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can run this function ! ");
        _;
    }

    // functions 
    

    function Buy(address _user, uint _amount)external{
        if(manual == false){
            _buy( _user, _amount);
        }
        // else {
        //     buy_( _user,_amount);
        // }
    }

    function _buy(address _user, uint _amount) internal{
        uint time = block.timestamp;
        if(time <= One ){
            uint tokens =_amount*(priceOne*2);
            BUSD.transferFrom(_user, address(FHL) , _amount);
            FHL.transferFrom(address(this),_user,tokens);
        }else if(time <= Two && time >= One){
            uint tokens =_amount*priceTwo;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }else if(time <= Three && time >= Two){
            uint tokens =_amount*priceThree;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }else if(time <= Four && time >= Three){
            uint tokens =_amount*priceFour;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }else if(time <= Five && time >= Four){
            uint tokens =_amount*priceFive;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }else if(time <= Six && time >= Five){
            uint tokens =_amount*priceSix;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }else if(time <= Seven && time >= Six){
            uint tokens =_amount*priceSeven;
            FHL.transfer(_user,tokens);
            BUSD.transferFrom(_user, address(FHL), _amount);
        }
    }
    // function buy_(address _user, uint _amount)internal {
        
    // }

    function start() public onlyOwner {
        One = block.timestamp+518400; // 29 days
        Two = One+604800; //7 => 31 Days 
        Three = Two+604800; //7 => 22 Days
        Four = Three+691200; //8 => 31 Days
        Five = Four+518400; //6 => 30 Days 
        Six = Five+604800; //7 => 31 Days 
        Seven = Six+1036800; // => 30 days
    }
    function ManualSwitch()public onlyOwner {
        if(manual == false ){
            manual = true;
        }else if(manual == true){
            manual = false;
        }
    }
    function timeTester()public view returns(uint ,uint ,uint, uint ,uint ,uint ,uint){
        return (One,Two,Three,Four,Five,Six,Seven);
    }
    function withdrawTokens()public onlyOwner {
        uint bal = FHL.balanceOf(address(this));
        FHL.transfer(msg.sender,bal);
    }
}