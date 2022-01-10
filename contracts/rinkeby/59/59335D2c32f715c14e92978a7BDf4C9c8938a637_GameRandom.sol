//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract GameRandom{
    uint public feePlay;
    address public creator;
    address public winer;
    address[] public players;
    constructor(){
        feePlay=1000000000;
        creator=msg.sender;
    }
    
    /*╔══════════════════════════════╗
      ║            EVENT             ║
      ╚══════════════════════════════╝*/
    event ChangeFree(
        uint newFree
    );
    event AddPlayer(
        address newPlayer
    );
    event GetWiner(
        address winer
    );
    event ConfirmWiner(
        address winer,
        uint amount
    );

    /*╔══════════════════════════════╗
      ║            MODIFER           ║
      ╚══════════════════════════════╝*/
    //Modifer onlyOwner 
    modifier _onlyCreator() {
        require(msg.sender==creator,"You don't creator");
    _;}
    /*╔══════════════════════════════╗
      ║            FUNCTIOM          ║
      ╚══════════════════════════════╝*/
    //function change fee play game
    function changeFeePlay(uint newFeePlay) public _onlyCreator()
    {
        require(newFeePlay != 0,"Fee must be greater than 0");
        feePlay=newFeePlay;
        emit ChangeFree(newFeePlay);
    }
    //add player 
    function addPlayer() public payable {
        require(msg.value>=feePlay,"Don't enought fee play game");
        players.push(msg.sender);
        emit AddPlayer(msg.sender);
    }
    //get palyer win using random array
    function getPlayerWin() public{
        require(winer==address(0),"The winners have not been awarded yet");
         uint index=_random()%players.length;
         winer=players[index];
         emit GetWiner(winer);
    }
    //random 
    function _random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    // Confirm winer and tranfer coin to winer
    function confirmWinerAndReward() public {
        require(msg.sender== winer,"You don't winer");
        require(winer != address(0),"Winer don't address 0 ");
        // pay to winner
        _payout(winer, address(this).balance);
        //emit
         emit ConfirmWiner(winer,address(this).balance);
        //reset winer
        winer=address(0);
        // delete list array
        delete players;
       
    }
    //function tranfer fee
    function _payout(
        address _recipient,
        uint256 _amount
    ) internal {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            require(success,"tranfer failed");
    }

}

    /*╔══════════════════════════════╗
      ║            END               ║
      ╚══════════════════════════════╝*/

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