/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract Context {
  constructor() {}
  // solhint-disable-previous-line no-empty-blocks
  function _msgSender() internal view returns(address payable) {
    return msg.sender;
  }
}
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

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract swapping is Ownable
{
    address tokenv1;
    address tokenv2;
    bool continueswapping;
    constructor(address _tokenv1,address _tokenv2)
    {
          tokenv1 =_tokenv1;
          tokenv2 =_tokenv2;
          continueswapping = true;
    }
    
    function getSwappingStatus() external view returns (bool) {
        return continueswapping;
    }
	
	function migratetoken(address token , uint256 amount) external
    {
        require(continueswapping,"Swapping is disabled");
        require(token==tokenv1,"Incorrect token Address");
        require(IERC20(tokenv1).transferFrom(msg.sender,owner(),amount),"Unable to transfer from caller to owner");
        require(IERC20(tokenv2).transferFrom(owner(),msg.sender,amount),"Unable to transfer from owner to caller");
    }
    
    function changeSwappingState(bool _allowSwapping) external onlyOwner{
        continueswapping = _allowSwapping;
    }
    
    
}