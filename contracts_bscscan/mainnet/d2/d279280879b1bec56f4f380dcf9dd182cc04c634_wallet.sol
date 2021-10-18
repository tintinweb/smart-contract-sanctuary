/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

contract wallet{
    
    bool public contract_is_active = true;
    address[4] private boardMember;
    address public dev_address;
    mapping( address => mapping(address => mapping(uint256 => uint256))) private allowed_amount;
 
    constructor( address member_1, address member_2, address member_3, address member_4) public {
        boardMember[0] = member_1;
        boardMember[1] = member_2;
        boardMember[2] = member_3;
        boardMember[3] = member_4;
        dev_address = msg.sender;

    }
    
    function pause ( bool _isActive) public{
           require(dev_address == msg.sender);
           contract_is_active = _isActive;
    }
        
    function vote (address token_contract_address, address _to, uint256 _amount) public{
     
        if(boardMember[0]== msg.sender){
            allowed_amount[token_contract_address][_to][0]=_amount;
            return();
        }
        if(boardMember[1]== msg.sender){
            allowed_amount[token_contract_address][_to][1]=_amount;
            return();
        }
        if(boardMember[2]== msg.sender){
            allowed_amount[token_contract_address][_to][2]=_amount;
            return();
        }
        if(boardMember[3]== msg.sender){
            allowed_amount[token_contract_address][_to][3]=_amount;
            return();
        }

    }
    
    function check_allowence (address token_contract_address, address _to, uint256 _amount) public view returns(bool){
        
        uint256 approved_vote = 0;
        if(allowed_amount[token_contract_address][_to][0]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][1]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][2]>= _amount){
            approved_vote+=1;
           
        }
        if(allowed_amount[token_contract_address][_to][3]>= _amount){
            approved_vote+=1;
           
        }
        
       if (approved_vote>=3){
           return(true);
       }
    
        return(false);
            
        
    }
    
    function transferToken (address token_contract_address, address _to, uint256 _amount) public{
        require(contract_is_active == true);
        require(msg.sender == dev_address);
        require(check_allowence(token_contract_address, _to, _amount) == true);
        allowed_amount[token_contract_address][_to][0]=0;
        allowed_amount[token_contract_address][_to][1]=0;
        allowed_amount[token_contract_address][_to][2]=0;
        allowed_amount[token_contract_address][_to][3]=0;
                             
        TransferHelper.safeTransfer(token_contract_address, _to, _amount);
    }
}