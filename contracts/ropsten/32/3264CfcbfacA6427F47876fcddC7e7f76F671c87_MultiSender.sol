/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-2.0-or-later



pragma solidity =0.7.6;

interface IERC20Minimal {
    
    function balanceOf(address account) external view returns (uint256);

  
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

   
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

contract MultiSender is Owned{


    function mutiSendETHWithDifferentValue( address[] memory _to,  uint[] memory _value) payable public {
        require(_to.length == _value.length);
        for (uint8 i = 0; i < _to.length; i++) {
			 TransferHelper.safeTransferETH(_to[i], _value[i]);
		}
	}

    function mutiSendTokenWithDifferentValue(address token, address[] memory _to,  uint[] memory _value) payable public {
        require(_to.length == _value.length);
        for (uint8 i = 0; i < _to.length; i++) {
			 TransferHelper.safeTransferFrom(token,msg.sender,_to[i], _value[i]);
		}
	}

    function withdrawETH() public onlyOwner{
        TransferHelper.safeTransferETH( msg.sender, address(this).balance);
    }

    function withdrawToken(address addr) public onlyOwner{
        TransferHelper.safeTransfer(addr, msg.sender,IERC20Minimal(addr).balanceOf(address(this)));
    }

}