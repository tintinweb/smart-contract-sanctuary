/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IArcadeToken {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Tetris is Ownable{

    //Account Structure for their own game
    struct accountGame {
        address connectedAccount1;
        address connectedAccount2;
        uint256 betAmount;
    }
    
    IArcadeToken tokenAddr;

    //Store the accounts as the game ID
    mapping(uint => accountGame) public gameControl;

    //Store the amount following address to the betANTamount
    mapping(address => uint256) public betANTamount;

    //Using isbetting mapping for the flag of the bet performance
    mapping(address => bool) public isbetting;

    //Contract comision
    uint16 feePercent;

    //Event return token to the Owner
    event ReturnToOwner(uint256 amount);

    //Event return token to the Winner
    event WithDraw(address winner, uint256 amount);

    //transaction successfully performed and receive ANT
    event Received (address , uint);
    
    constructor(IArcadeToken _tokenAddr, uint8 _feePercent) {
        tokenAddr = _tokenAddr;
        feePercent = _feePercent;
    }

    //Return the GameState as the GameID
    function getGameState(uint gameID) public view returns(address account1, address account2, uint256 amount ) {
        accountGame memory accountGameById = gameControl[gameID];
        return (accountGameById.connectedAccount1, accountGameById.connectedAccount2, accountGameById.betAmount);
    }
    
    //Create the Game and Set GameID
    function createGame(uint gameID, address account1, address account2) public returns(bool) {
        accountGame memory newGame = accountGame(account1, account2, 0);
        gameControl[gameID] = newGame;
        return true;
    }
    //Transform the ANT from account to the SC
    function transferANT(uint256 gameID, uint256 _tokenAmount) public returns(bool){
        gameControl[gameID].betAmount += _tokenAmount;
        betANTamount[msg.sender] = _tokenAmount;
        tokenAddr.transferFrom(msg.sender, address(this), _tokenAmount);
        emit Received(address(this), _tokenAmount);
        return true;
    }
    
    //Transform all of the SC's ANT.---for the test deploy.
    function returnToOwner() public{
        tokenAddr.transferFrom(address(this), owner(), address(this).balance);
        emit ReturnToOwner(address(this).balance);
    }

    //Return the ANT to the winner, some comision to the owner.
    function withdraw(uint gameID) external payable {
        tokenAddr.transfer(msg.sender, gameControl[gameID].betAmount*(100-feePercent)/(100));
        tokenAddr.transfer(owner(),  gameControl[gameID].betAmount*feePercent/(100));
        emit WithDraw(msg.sender, gameControl[gameID].betAmount*(100-feePercent)/(100));
    }
}