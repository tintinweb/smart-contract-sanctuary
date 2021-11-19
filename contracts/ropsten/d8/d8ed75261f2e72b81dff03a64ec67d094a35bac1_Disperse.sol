/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}


contract Disperse is Ownable {
    
    
    uint256 public commision = 5 ether;


    function changeyCommision(uint256 _value) public payable onlyOwner{
        commision = _value;
    }
    
    
    function payCommision() public {
        payable(owner()).transfer(commision);
    }
    
    // 
    modifier isLength(uint256 _amount, uint256 length){
        require(_amount == length, "length of the lists must be the same");
        _;
    }
    
    modifier isCommision(uint256 _value){
        require(_value >= commision, "msg.value must be >= 500000000000000000");
        payCommision();
        _;
        require(address(this).balance == 0, "Contract balance must be zero");
    }
    
    
    // Disperse ETH
   function disperseEth(address payable[] calldata  _addrList, uint256[] calldata _amount) isLength(_addrList.length, _amount.length) isCommision(msg.value)  public payable{
    
        for(uint256 i = 0; i< _addrList.length; i++ ){
               _addrList[i].transfer(_amount[i]);
        }
    }
    
    
    // Disperse IERC20 tokens
     function disperseToken(address payable[] calldata  _addrList, uint256[] calldata _amount, address _tokenAddr) isLength(_addrList.length, _amount.length) isCommision(msg.value) public payable  {
        for(uint256 i = 0; i< _addrList.length; i++ ){
            IERC20(_tokenAddr).transferFrom(msg.sender, _addrList[i], _amount[i]);
        }
    }
    
    // Withdraw tokens
    function withdrawTokens(address _tokenAddr) public payable onlyOwner{
        require(_tokenAddr == address(0), "Zero address");
        uint256 tokenAmount = IERC20(_tokenAddr).balanceOf(address(this));
        if (tokenAmount !=0 ){
            IERC20(_tokenAddr).transfer(msg.sender, tokenAmount);
        }
        
    }
    
    function getTokenBalance(address _tokenAddr) onlyOwner public view returns(uint256){
        return IERC20(_tokenAddr).balanceOf(address(this));
    }
    
    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function contractAddr() public view returns(address){
        return address(this);
    }
    
     function ownerBalance() public view onlyOwner returns(uint256) {
        return msg.sender.balance;
    }
    
    
}