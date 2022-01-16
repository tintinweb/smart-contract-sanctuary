// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EnergySistem {
    IERC20 public buyToken;
    address public owner;
    address public feeWallet;
    uint public pricePerDay;

    // Addres del (user => fecha en segudos donde se le termina la energia al user)
    mapping (address=> uint256) public userEnergy;
    
    mapping (address => bool) public vipList;
    //TODO> mapping add=>bool) ownersEnergyFuLL;

    constructor (uint _price, address _feeWallet){
        owner = msg.sender; 
        feeWallet = _feeWallet;
        pricePerDay = _price * 1 ether;
        vipList[msg.sender] = true;
    }
    
    function buyDay(uint _days) public {
        uint _price = pricePerDay * _days;
        //require(checkUser(msg.sender) == false, "Ya tiene tiempo comprado." );
        require(buyToken.balanceOf(msg.sender) >= _price, "Fondos insuficientes.");
        require(buyToken.allowance(msg.sender, address(this)) > _price, "Aprovar mas uso de tokens");
        buyToken.transferFrom(msg.sender,feeWallet, _price);        
        userEnergy[msg.sender] = (block.timestamp + howTimeLeft(msg.sender)) + (_days * 1 days);        
    }

    function checkUser(address _user) public view returns(bool){
        if((userEnergy[_user]> block.timestamp) || vipList[_user]){
            return true;
        }else {
            return false;
        } //todo: agregar la comprobacion de la lista de usuarios vips
    }

    function setBuyToken(address _buyToken) public {
        require (msg.sender == owner , "NO eres el owner");
        buyToken = IERC20(_buyToken);
    }

    //price in wai
    function setPricePerDay (uint _pricePerDayInWai) public {
        require (msg.sender == owner , "NO eres el owner");
        pricePerDay = _pricePerDayInWai * 1 ether;
    }

    //Function: Regresar tiempo en segundos restantes de energia.
    function howTimeLeft(address _user) public view returns(uint){
        if(block.timestamp>userEnergy[_user]  ){
            return block.timestamp;
        }else {
            return userEnergy[_user] - block.timestamp;
        }
    }

    function addVIP(address _vipAddress) public {
        require (msg.sender == owner , "NO eres el owner");
        vipList[_vipAddress] = true;
    }

    function setWalletFee(address _wallet) public {
        require (msg.sender == owner , "NO eres el owner");
        feeWallet = _wallet;
    }
 
        /* TODO:
        * Fction: SetToken, SetPricem, checker (done)(tested)
        * Fuctions: Para que generar una lista de vips free uso. (done)
        * Function: Regresar tiempo en segundos restantes de energia. (done)
        * Replantear: Comprar 2 veces seguidas y sumar el tiempo.(done)
        * Generar que los de la lista siempre de true. (done)
        * Function : SetWalletFee (done)
        */

    // ---- GETTERS
    function getVipChek(address _user) public view returns(bool){
        return  vipList[_user];
    }

}

// SPDX-License-Identifier: MIT
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