/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.5.7;
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event Freeze(address indexed from, uint256 value);
    
    event Unfreeze(address indexed from, uint256 value);
}

contract ERC20BatchTransfer{
    address public contractOwner;
    bool isWorking = false;
    
    constructor() public{
        contractOwner = msg.sender;
    }
    
    function batchTransfer(IERC20 _contract, address[] memory _tos, uint256[] memory _values) public payable{
        require(_tos.length <= 100,"The number of addresses exceeds the limit");
        require(isWorking,"Contract is disenable");
        require(_tos.length == _values.length);
        uint256 sumTransferAmount = 0;
        for (uint i = 0; i < _values.length; i++){
            require(sumTransferAmount + _values[i] >= sumTransferAmount);
            sumTransferAmount += _values[i];
        }
        require(_contract.balanceOf(msg.sender) >= sumTransferAmount);
        require(_contract.allowance(msg.sender,address(this)) >= sumTransferAmount);
        
        for (uint i = 0; i < _tos.length; i++){
            _contract.transferFrom(msg.sender,_tos[i],_values[i]);
        }
    }
    
    function enable() public{
        require(msg.sender == contractOwner);
        isWorking = true;
    }
    
    function disenable() public{
        require(msg.sender == contractOwner);
        isWorking = false;
    }
}