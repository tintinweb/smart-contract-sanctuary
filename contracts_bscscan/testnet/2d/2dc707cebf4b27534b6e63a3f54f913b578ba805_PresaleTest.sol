/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

contract PresaleTest is Context{
    address private _owner;
    address private marketingWallet = 0x3F602089d2fD51D73EBfFCEBaD154A898B235A16;
    mapping(address=>uint256) public balances;
    
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function participateInPresale() public payable {
        require(msg.value <= 1 ether && msg.value >= 0.1 ether);
        require(address(this).balance + msg.value <= 5 ether);
        require(balances[msg.sender] + msg.value <= 1000000000000000000);
        
        balances[msg.sender] += msg.value; 
    }
    
    function sendMoneyToMarketingAddress() public onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }
    
    fallback() external {
    }
    
}