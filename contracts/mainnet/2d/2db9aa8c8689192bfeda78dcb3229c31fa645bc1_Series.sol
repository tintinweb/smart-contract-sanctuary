/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

contract Series is Ownable {
  string name;
  mapping(address=>address[]) plugins;

  constructor(string memory _name) public {
    name = _name;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}

contract OtoCorp is Ownable {
    
    uint256 private tknSeriesFee;
    IERC20 private tkn;
    uint private seriesIndex = 1;
    mapping(address=>address[]) seriesOfMembers;
    
    event TokenAddrChanged(address _oldTknAddr, address _newTknAddr);
    event ReceiveTokenFrom(address src, uint256 val);
    event NewSeriesCreated(address _contract, address _owner, string _name);
    event SeriesFeeChanged(uint256 _oldFee, uint256 _newFee);
    event TokenWithdrawn(address _owner, uint256 _total);
    
    constructor(IERC20 _tkn) public {
        tkn = _tkn;
        tknSeriesFee = 0**18;
    }
    
    function withdrawTkn() external onlyOwner {
        require(tkn.transfer(owner(), balanceTkn()));
        emit TokenWithdrawn(owner(), balanceTkn());
    }
    
    function createSeries(string memory seriesName) public payable {
        require(tkn.transferFrom(msg.sender, address(this), tknSeriesFee));
        emit ReceiveTokenFrom(msg.sender, tknSeriesFee);
        seriesName = string(abi.encodePacked(seriesName, ' - Series ', getIndex()));
        Series newContract = new Series(seriesName);
        seriesIndex ++;
        seriesOfMembers[msg.sender].push(address(newContract));
        newContract.transferOwnership(msg.sender);
        emit NewSeriesCreated(address(newContract), newContract.owner(), newContract.getName());
    }
    
    function changeTknAddr(IERC20 newTkn) external onlyOwner {
        address oldTknAddr = address(tkn);
        tkn = newTkn;
        emit TokenAddrChanged(oldTknAddr, address(tkn));
    }
    
    function changeSeriesFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = tknSeriesFee;
        tknSeriesFee = _newFee;
        emit SeriesFeeChanged(oldFee, tknSeriesFee);
    }
    
    function balanceTkn() public view returns (uint256){
        return tkn.balanceOf(address(this));
    }
    
    function isUnlockTkn() public view returns (bool){
        return tkn.allowance(msg.sender, address(this)) > 0;
    }
    
    function mySeries() public view returns (address[] memory) {
        return seriesOfMembers[msg.sender];
    }
    
    function getIndex() public view returns (string memory) {
        return uint2str(seriesIndex);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}