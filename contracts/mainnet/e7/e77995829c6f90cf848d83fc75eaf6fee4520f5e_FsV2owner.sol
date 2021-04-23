/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT





abstract contract Context {
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
    constructor () {
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



interface IFsV2owner {
    function setFswFactor(uint _amount) external;
    function setFsBalanceAddress(address _address) external;
    function setEncAddress(address _address) external;
    function setFeeAddress(address payable _address) external;
    function setDexAddress(address _address) external;
    function setRelayer(address _relayer, bool _status) external;
    function enableToken(address _token) external;
    function disableToken(address _token) external;
    function enableBulkToken(address[] calldata _tokens) external;
    function disableBulkToken(address[] calldata _tokens) external;
    function withdrawFsPool(address _token, address payable _to, uint _amount) external;
    
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    
    function fsbalance(address _token) external view returns(uint);
}




contract FsV2owner is Ownable {
    IFsV2owner public fsV2;
    mapping(address => bool) public admins;
    
    modifier onlyAdmins() {
        require(admins[_msgSender()], "caller is not the admin");
        _;
    }
    
    
    constructor (address _fsV2){
        fsV2 = IFsV2owner(_fsV2);
    }
    
    
    function fsbalance(address _token) external view returns(uint) {
        return fsV2.fsbalance(_token);
    }
    
    function setAdmin(address _address, bool _status) external onlyOwner {
        admins[_address] = _status;
    }
    
    function setFsV2(address _address) external onlyOwner {
        fsV2 = IFsV2owner(_address);
    }
    
    function enableToken(address _token) external onlyAdmins {
        fsV2.enableToken(_token);
    }
    
    function disableToken(address _token) external onlyAdmins {
        fsV2.disableToken(_token);
    }
    
    function enableBulkToken(address[] calldata _tokens) external onlyAdmins {
        fsV2.enableBulkToken(_tokens);
    }
    
    function disableBulkToken(address[] calldata _tokens) external onlyAdmins {
        fsV2.disableBulkToken(_tokens);
    }
    
    function setFswFactor(uint _amount) external onlyOwner {
        fsV2.setFswFactor(_amount);
    }
    
    function setFsBalanceAddress(address _address) external onlyOwner {
        fsV2.setFsBalanceAddress(_address);
    }
    
    function setEncAddress(address _address) external onlyOwner {
        fsV2.setEncAddress(_address);
    }
    
    function setFeeAddress(address payable _address) external onlyOwner {
        fsV2.setFeeAddress(_address);
    }
    
    function setDexAddress(address _address) external onlyOwner {
        fsV2.setDexAddress(_address);
    }
    
    function setRelayer(address _relayer, bool _status) external onlyOwner {
        fsV2.setRelayer(_relayer, _status);
    }
    
    function withdrawFsPool(address _token, address payable _to, uint _amount) external onlyOwner {
        fsV2.withdrawFsPool(_token, _to, _amount);
    }
    
    function renounceOwnershipFsV2() external onlyOwner {
        fsV2.renounceOwnership();
    }
    
    function transferOwnershipFsV2(address newOwner) external onlyOwner {
        fsV2.transferOwnership(newOwner);
    }
}