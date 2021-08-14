// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "SafeMath.sol";

contract SirioDevWallet {
    using SafeMath for uint;
    
    address [] devs;
    mapping (address => bool) isDev;
    mapping (bytes32 => mapping (address => bool)) signatures;
    mapping (bytes32 => bool) operations;
    
    constructor (address [] memory _devs){
        devs=_devs;
        for(uint i=0;i<devs.length;i++){
            isDev[devs[i]]=true;
        }
    }
    
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);
    
    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data
    );
    
    function addDev(address _dev) public{
        require(msg.sender==address(this),"this function can be called only by this contract");
        devs.push(_dev);
        isDev[_dev]=true;
    }
    
    function removeDev(address _dev) public{
        require(msg.sender==address(this),"this function can be called only by this contract");
        require(isDev[_dev],"he is not a dev");
        uint index;
        for(uint i=0;i<devs.length;i++){
            if(devs[i]==_dev)
                index=i;
        }
        devs[index]=devs[devs.length];
        devs.pop();
        isDev[_dev]=false;
    }
    
    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, salt));
    }
    
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) public{
        bytes32 id = hashOperation(target, value, data, salt);
        require(isDev[msg.sender],"you are not a dev");
        _schedule(id);
        emit CallScheduled(id, 0, target, value, data);
    }
    
    /**
     * @dev Schedule an operation that is to becomes valid after all signatures.
     */
    function _schedule(bytes32 id) private {
        require(!operations[id], "TimelockController: operation already scheduled");
        signatures[id][msg.sender]=true;
    }
    
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) public payable{
        bytes32 id = hashOperation(target, value, data, salt);
        uint number=0;
        for(uint i=0;i<devs.length;i++){
            if(signatures[id][devs[i]])
                number++;
        }
        uint perc=80;
        require(number>=perc.mul(devs.length).div(100),"80% of devs have to sign");
        _call(id, 0, target, value, data);
    }
    
    function getHash(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) public view returns(bytes32){
        bytes32 id = hashOperation(target, value, data, salt);
        return id;
    }
    
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }
    
    function sign(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    )public {
        require (isDev[msg.sender],"you are not a dev");
        bytes32 id = hashOperation(target, value, data, salt);
        signatures[id][msg.sender]=true;
    }

    receive() external payable {}
}