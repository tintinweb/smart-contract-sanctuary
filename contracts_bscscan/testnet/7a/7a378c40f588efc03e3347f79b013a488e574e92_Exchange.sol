/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
    function decimals() external view returns (uint8);
}

// File: contracts/SafeTransfer.sol


pragma solidity ^0.8.0;



contract SafeTransfer is Ownable {
    function _safeTransferToken(address _token) internal virtual onlyOwner {
        IERC20Metadata token = IERC20Metadata(_token);
        uint amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }
    function safeTransferToken(address _token) public onlyOwner {
        _safeTransferToken(_token);
    }
    function safeTransferTokenWithAmount(address _token, uint _amount) public onlyOwner {
        IERC20Metadata token = IERC20Metadata(_token);
        token.transfer(msg.sender, _amount*10**token.decimals());
    }
}

// File: contracts/BabyShiba.sol


pragma solidity ^0.8.0;



contract Exchange is SafeTransfer {

    uint256 public aSBlock;
    uint256 public aEBlock;
    uint256 public aCap;
    uint256 public aTot;
    uint256 public aAmt;
    uint256 public sSBlock;
    uint256 public sEBlock;
    uint256 public sPrice;
    uint256 public sCap;
    uint256 public sTot;
    // uint public percent = 10;
    
    // token address of the token
    address public tokenAddress;
    
    // check if the someone has claimed the tokens
    mapping(address=>bool) public airdropClaimed;

    function start(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        IERC20Metadata _token = IERC20Metadata(tokenAddress);
        startAirdrop(1,999999999,10*10**_token.decimals(),2000000000000);
        startSale(1, 999999999, 1000*10**_token.decimals(), 2000000000000);
        // startAirdrop(1,999999999,10*10**_token.decimals(),3);
        // startSale(1, 999999999, 1000*10**_token.decimals(), 3);
    }

    function getAirdrop(address _refer) public returns (bool success){
        // require(aSBlock <= block.number && block.number <= aEBlock);
        require(aSBlock <= block.number ,"Airdrop not started yet");
        require(block.number <= aEBlock ,"Airdrop ended");
        require(!airdropClaimed[_msgSender()],"has claimed before");
        require(aTot < aCap || aCap == 0);
        IERC20Metadata _token = IERC20Metadata(tokenAddress);
        aTot ++;
        if(msg.sender != _refer && _token.balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
          _token.transfer(_refer, aAmt);
        }
        _token.transfer(msg.sender, aAmt);
        airdropClaimed[_msgSender()]=true;
        return true;
    }

    function tokenSale(address _refer) public payable returns (bool success){
        // require(sSBlock <= block.number && block.number <= sEBlock);
        require(sSBlock <= block.number,"tokenSale has not started yet");
        require(block.number <= sEBlock,"tokenSale ended");
        require(sTot < sCap || sCap == 0);
        IERC20Metadata _tokenInterface = IERC20Metadata(tokenAddress);
        uint256 _eth = msg.value;
        uint256 _tkns;
        _tkns = (sPrice*_eth) / 1 ether;
        sTot ++;
        if(msg.sender != _refer && _tokenInterface.balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
            _tokenInterface.transfer(_refer, _tkns);
        }
        _tokenInterface.transfer(msg.sender, _tkns);
        return true;
    }
    
    // withdraw all tokens from the contract
    // function withdrawTokens() public onlyOwner returns (bool success){
    //     IERC20Metadata _token = IERC20Metadata(tokenAddress);
    //     // uint256 totalAmountTokens=_token.balanceOf(address(this));
        
    //     uint256 totalAmountTokens=tokenBalance();
    //     require(totalAmountTokens>0,"the contract has zero tokens to withdraw");
    //     _token.transfer(owner(), totalAmountTokens);
    //     return true;
    // }
    
    // added by me
    function tokenBalance(address _tokenAddress) public view returns (uint){
        IERC20Metadata _token = IERC20Metadata(_tokenAddress);
        return _token.balanceOf(address(this));
    }

    function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
        return(aSBlock, aEBlock, aCap, aTot, aAmt);
    }
    
    function viewSale() public view returns(uint StartBlock, uint EndBlock, uint Price,uint Cap, uint Total){
        return (sSBlock, sEBlock,sPrice, sCap, sTot);
    }

    function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
        aSBlock = _aSBlock;
        aEBlock = _aEBlock;
        aAmt = _aAmt;
        aCap = _aCap;
        aTot = 0;
    }
    
    function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sPrice, uint256 _sCap) public onlyOwner{
        sSBlock = _sSBlock;
        sEBlock = _sEBlock;
        sPrice = _sPrice;
        sCap = _sCap;
        sTot = 0;
    }
    
    // get the amount of native currency
    function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
}