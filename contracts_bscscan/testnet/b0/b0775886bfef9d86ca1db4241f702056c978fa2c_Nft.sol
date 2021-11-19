/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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

// File: contracts/nft.sol


//import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Nft {
    
    string public name;
    string public symbol;
    string public baseUrl;
    uint160 public supply = 1000;
    uint160 public totalMinted = 1;
    
    // constructor(
    //      string memory _name,
    //      string memory _symbol,
    //      string memory _baseUrl
    //     ) ERC1155 (_baseUrl) {
    //         name = _name;
    //         symbol = _symbol;
    //         baseUrl = _baseUrl;
    //     }
        
    
    function getTokenIdea(address _contract,address _receive) public returns (bool success, bytes memory result){
         bytes memory method=abi.encodeWithSignature("balanceOf(address)",_receive);
        (success,result)=_contract.call(method);
        
       // IERC20 token = IERC20(_contract);
       // return IERC20(_contract).balanceOf(_receive);
        
        
    }
    
     function checkBal(address token, address holder) public returns(uint) {
        IERC20 token = IERC20(token);
        return token.balanceOf(msg.sender);
    }
    
}