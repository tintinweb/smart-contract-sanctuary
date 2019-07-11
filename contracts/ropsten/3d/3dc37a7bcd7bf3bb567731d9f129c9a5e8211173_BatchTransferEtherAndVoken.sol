/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity ^0.5.7;


// Batch transfer Ether and Voken
// 
// More info:
//   https://vision.network
//   https://voken.io
//
// Contact us:
//   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="473432373728353307312e342e2829692922333028352c">[email&#160;protected]</a>
//   <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="780b0d0808170a0c380e17131d16561117">[email&#160;protected]</a>


/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract
     * to the sender account.
     */
    constructor () internal {
        _owner = msg.sender;
    }

    /**
     * @return The address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
    }

    /**
     * @dev Rescue compatible ERC20 Token
     *
     * @param tokenAddr ERC20 The address of the ERC20 token contract
     * @param receiver The address of the receiver
     * @param amount uint256
     */
    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 __token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 __balance = __token.balanceOf(address(this));
        
        require(__balance >= amount);
        assert(__token.transfer(receiver, amount));
    }
}


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


/**
 * @title Batch Transfer Ether And Voken
 */
contract BatchTransferEtherAndVoken is Ownable{
    using SafeMath256 for uint256;
    
    IERC20 VOKEN = IERC20(0x0eACD9F66941D7d1885d5854F5b92575CE9eD5fd);

    /**
     * @dev Batch transfer both.
     */
    function batchTransfer(address payable[] memory accounts, uint256 etherValue, uint256 vokenValue) public payable {
        uint256 __etherBalance = address(this).balance;
        uint256 __vokenAllowance = VOKEN.allowance(msg.sender, address(this));

        require(__etherBalance >= etherValue.mul(accounts.length));
        require(__vokenAllowance >= vokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue);
            assert(VOKEN.transferFrom(msg.sender, accounts[i], vokenValue));
        }
    }

    /**
     * @dev Batch transfer Ether.
     */
    function batchTtransferEther(address payable[] memory accounts, uint256 etherValue) public payable {
        uint256 __etherBalance = address(this).balance;

        require(__etherBalance >= etherValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            accounts[i].transfer(etherValue);
        }
    }

    /**
     * @dev Batch transfer Voken.
     */
    function batchTransferVoken(address[] memory accounts, uint256 vokenValue) public {
        uint256 __vokenAllowance = VOKEN.allowance(msg.sender, address(this));

        require(__vokenAllowance >= vokenValue.mul(accounts.length));

        for (uint256 i = 0; i < accounts.length; i++) {
            assert(VOKEN.transferFrom(msg.sender, accounts[i], vokenValue));
        }
    }
}