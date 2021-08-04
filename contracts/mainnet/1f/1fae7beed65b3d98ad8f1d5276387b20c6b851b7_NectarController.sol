/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface INEC {

    function burningEnabled() external returns(bool);

    function controller() external returns(address);

    function enableBurning(bool _burningEnabled) external;

    function burnAndRetrieve(uint256 _tokensToBurn) external returns (bool success);

    function totalPledgedFees() external view returns (uint);

    function totalSupply() external view returns (uint);

    function destroyTokens(address _owner, uint _amount
      ) external returns (bool);

    function generateTokens(address _owner, uint _amount
      ) external returns (bool);

    function changeController(address _newController) external;

    function balanceOf(address owner) external returns(uint256);

    function transfer(address owner, uint amount) external returns(bool);
}

contract TokenController {

    function proxyPayment(address _owner) public payable returns(bool);

    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);

    function onBurn(address payable _owner, uint _amount) public returns(bool);
}


contract NectarController is TokenController, Ownable {

    INEC public tokenContract;   // The new token for this Campaign
    
    event UpgradedController (address newAddress);

    /// @dev There are several checks to make sure the parameters are acceptable
    /// @param _tokenAddress Address of the token contract this contract controls

    constructor (
        address _tokenAddress
    ) public {
        tokenContract = INEC(_tokenAddress); // The Deployed Token Contract
    }

/////////////////
// TokenController interface
/////////////////

    /// @notice `proxyPayment()` allows the caller to send ether to the Campaign
    /// but does not create tokens. This functions the same as the fallback function.
    /// @param _owner Does not do anything, but preserved because of MiniMe standard function.
    function proxyPayment(address _owner) public payable returns(bool) {
        require(false);
        return false;
    }


    /// @notice Notifies the controller about a transfer.
    /// Transfers can only happen to whitelisted addresses
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
        return true;
    }

    /// @notice Notifies the controller about an approval, for this Campaign all
    ///  approvals are allowed by default and no extra notifications are needed
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool)
    {
        return true;
    }

    /// @notice Notifies the controller about a burn attempt. Initially all burns are disabled.
    /// Upgraded Controllers in the future will allow token holders to claim the pledged ETH
    /// @param _owner The address that calls `burn()`
    /// @param _tokensToBurn The amount in the `burn()` call
    /// @return False if the controller does not authorize the approval
    function onBurn(address payable _owner, uint _tokensToBurn) public
        returns(bool)
    {
        // This plugin can only be called by the token contract
        require(msg.sender == address(tokenContract));

        require (tokenContract.destroyTokens(_owner, _tokensToBurn));

        return true;
    }

    /// @notice `onlyOwner` can upgrade the controller contract
    /// @param _newControllerAddress The address that will have the token control logic
    function upgradeController(address _newControllerAddress) public onlyOwner {
        tokenContract.changeController(_newControllerAddress);
        emit UpgradedController(_newControllerAddress);
    }
    
    
    function deleteAndReplaceTokens(address _currentOwner, address _newOwner) public onlyOwner returns(bool) {
        
        uint256 tokenBalance = tokenContract.balanceOf(_currentOwner);
        
        require(tokenContract.destroyTokens(_currentOwner, tokenBalance));
        require(tokenContract.generateTokens(_newOwner, tokenBalance));
        
        return true;
    }

}