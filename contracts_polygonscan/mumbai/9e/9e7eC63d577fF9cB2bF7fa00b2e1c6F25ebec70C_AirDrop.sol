/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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


contract AirDrop {
    /* the address of the token contract */
    IERC20 public dataGen;
    address public owner;

    mapping( string => uint256 ) referralCodes;
    mapping( address => uint256 ) claimedCount;
    event TransferredToken(address indexed to, uint256 value);
    event FailedTransfer(address indexed to, uint256 value);

    constructor ( IERC20 _dataGen ) {
        owner = msg.sender;
        dataGen = _dataGen;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
  
    function setReferralCode( string[] memory codes, uint256 value ) onlyOwner external {
        for( uint i = 0; i < codes.length; i++ ) {
            string memory myCode = codes[i];
            if( referralCodes[myCode] == 0 ) referralCodes[myCode] = value;
        }
    }

    function getAirdrop( string memory code ) external {
        require(claimedCount[msg.sender] < 2, "One wallet cann't get more than 2 airdrop");
        uint value = referralCodes[code];
        require( value > 0, "Code is incorrect or already used");
        uint256 toSend = value * 10 ** 18;
        referralCodes[code] = 0;
        claimedCount[msg.sender] ++;
        sendInternally(msg.sender, toSend, value);
    }

    function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
        if(recipient == address(0)) return;

        if(tokensAvailable() >= tokensToSend) {
            dataGen.transfer(recipient, tokensToSend);
            emit TransferredToken(recipient, valueToPresent);
        } else {
            emit FailedTransfer(recipient, valueToPresent); 
        }
    }
 
    function tokensAvailable() public view returns (uint256) {
        return dataGen.balanceOf(address(this));
    }

    function withdraw() external onlyOwner {
        uint256 balance = tokensAvailable();
        require (balance > 0);
        dataGen.transfer(owner, balance);
    }
}