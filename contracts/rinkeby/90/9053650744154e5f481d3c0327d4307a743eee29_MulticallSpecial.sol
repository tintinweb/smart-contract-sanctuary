/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: Mutlicall with Approve and Whitelist
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {function transfer(address recipient, uint256 amount) external returns (bool); function balanceOf(address account) external view returns (uint256);function approve(address spender, uint256 amount) external returns (bool);}

contract MulticallSpecial {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }
    
    constructor() {
        owner = msg.sender;
        //whitelist owner on creation
        whitelist[owner] = true;
    }
    
    address public owner;
    bool public disableWhiteList;

    modifier onlyOwner {
        require(msg.sender == owner,"ow");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "not whitelisted");
        _;
    }

    function approve(address _spender, address _token, uint256 _amount) external onlyOwner{
        IERC20(_token).approve(_spender, _amount);
    }

    function turnOffWhiteList(bool _disableWhiteList) external onlyOwner{
        disableWhiteList = _disableWhiteList;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return (disableWhiteList || whitelist[_address]);
    }
        
    function addWhiteList(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removewhiteList(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function aggregate(Call[] memory calls) external onlyWhitelisted returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    function tryAggregate(bool requireSuccess, Call[] memory calls) external onlyWhitelisted returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }

    function retrieveExcess(address _tokenContract, uint256 _amount) external onlyOwner{
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, _amount);
    }

}