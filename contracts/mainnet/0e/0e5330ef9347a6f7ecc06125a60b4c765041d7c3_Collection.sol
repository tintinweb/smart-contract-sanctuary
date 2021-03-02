/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.5.0;


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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



contract TrbInterface {
    function getUintVar(bytes32 _data) view public returns(uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function submitMiningSolution(string calldata _nonce,uint256[5] calldata _requestId, uint256[5] calldata _value) external;
    function addTip(uint256 _requestId, uint256 _tip) external;
}

contract Collection is Ownable {
    
    address createAddress;
    address trbAddress = 0x0Ba45A8b5d5575935B8158a88C631E9F9C95a2e5;
    
    TrbInterface trbContract = TrbInterface(trbAddress);
    
    constructor() public {
        createAddress = msg.sender;
    }
    
    function() external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
    }
    
    function finalize() external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
    }
    
    function getCreate() public view returns(address){
        return createAddress;
    }
    
    //ETH
    function withdrawEth(uint _amount) public onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        msg.sender.transfer(_amount);
    }
    
    function withdrawTrb(uint _amount) public onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.transfer(msg.sender, _amount);
    }
    
    function withdrawTrbByAddress(address _transaddress,uint _amount) public onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.transfer(_transaddress, _amount);
    }
    
    function depositStake() external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.depositStake();
    }
    
    function requestStakingWithdraw() external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.requestStakingWithdraw();
    }
    
    function withdrawStake() external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.withdrawStake();
    }
    
    function submitMiningSolution(string calldata _nonce, uint256[5] calldata _requestId, uint256[5] calldata _value) external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        
        if (gasleft() <= 10**6){
            bytes32 slotProgress =0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a;
            uint256 tmpSlot = trbContract.getUintVar(slotProgress);
            require(tmpSlot < 4, "Z");
        }
        
        trbContract.submitMiningSolution(_nonce, _requestId, _value);
    }
    
    function addTip(uint256 _requestId, uint256 _tip) external onlyOwner payable{
        require(createAddress == msg.sender, "author no");
        trbContract.addTip(_requestId, _tip);
    }
    
    function getUintVar(bytes32 _data) public onlyOwner view returns (uint256){
        require(createAddress == msg.sender, "author no");
        //bytes32 slotProgress =0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a;
        
        return trbContract.getUintVar(_data);
    }
    
}