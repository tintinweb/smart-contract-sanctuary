/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: UNLICENSED
// File: contracts/Mediator.sol


pragma solidity ^0.8.7;


contract FatherOfMediators {
    address private owner;
    address private payout;
    address private manager;
    address[] public mediators;
    
    modifier isOwner(){
        require(msg.sender == owner, "For Owner only");
        _;
    }
    
    modifier isOwnerOrManager(){
        require(msg.sender == owner || msg.sender == manager, "For Owner or Manager only");
        _;
    }
    
    function deployMediators(uint n) internal {
        for (uint i=0; i<n; i++) {
            Mediator mediator = new Mediator(address(this));
            mediators.push(address(mediator));
        }
    }

    constructor() {
        owner = msg.sender;
        payout = msg.sender;
        manager = msg.sender;
        deployMediators(1);
    }
    
    function cloneMediators(uint n) external isOwnerOrManager {
        for (uint i=0; i<n; i++) {
            address clone = createClone(mediators[0]);
            IMediator(clone).init(address(this));
            mediators.push(clone);
        }
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
          let clone := mload(0x40)
          mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
          mstore(add(clone, 0x14), targetBytes)
          mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
          result := create(0, clone, 0x37)
        }
    }

    function setOwner(address newOwner) external isOwner {
        owner = newOwner;
    }

    function setPayout(address newPayout) external isOwner {
        payout = newPayout;
    }
    
    function setManager(address newManager) external isOwner {
        manager = newManager;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getPayout() external view returns (address) {
        return payout;
    }
    
    function getManager() external view returns (address) {
        return manager;
    }

    function length() external view returns (uint) {
        return mediators.length;
    }

    function balanceOf(address token) external view returns (uint amount, uint count) {
        IERC20 erc20 = IERC20(token);
        for (uint i=0; i<mediators.length; i++) {
            uint balance = erc20.balanceOf(mediators[i]);
            if (balance > 0) {
                amount += balance;
                count += 1;
            }
        }
    }
    
    function poolOf(address[] calldata tokens) external view returns (address[] memory pool, uint[] memory amounts) {
        address[] memory tmp = new address[](mediators.length);
        uint count = 0;
        for (uint i=0; i<mediators.length; i++) {
            bool crossing = true;
            for (uint j=0; j<tokens.length; j++) {
                if (IERC20(tokens[j]).balanceOf(mediators[i]) == 0) {
                    crossing = false;
                    break;
                }
                
            }
            if (crossing) {
                tmp[count] = mediators[i];
                count += 1;
            }
        }
        amounts = new uint[](tokens.length);
        pool = new address[](count);
        for (uint i=0; i<count; i++) {
            pool[i] = tmp[i];
            for (uint j=0; j<tokens.length; j++) {
                amounts[j] += IERC20(tokens[j]).balanceOf(tmp[i]);
            }
        }
    }
    
    function grabERC20Batch(address[] calldata tokens, address[] calldata childs) external isOwnerOrManager returns (uint[] memory result) {
        result = new uint[](tokens.length);
        for (uint i=0; i<tokens.length; i++) {
            IERC20 erc20 = IERC20(tokens[i]);
            for (uint j=0; j<childs.length; j++) {
                uint balance = erc20.balanceOf(childs[j]);
                if (balance > 0) {
                    result[i] += balance;
                    IMediator(childs[j]).withdrawERC20(tokens[i], payout, balance);
                }
            }
        }
    }

}

interface IFatherOfMediators {
    function getPayout() external view returns (address payable);
}

interface IMediator {
    function withdrawERC20(address token, address payout, uint amount) external returns (uint);
    function init(address a) external;
}

contract Mediator {

    address public father;

    constructor(address a) {
        father = a;
    }

    function init(address a) external {
        require(father == address(0));
        father = a;
    }

    modifier isFather(){
        require(msg.sender == father, "For Father only");
        _;
    }

    function withdrawERC20(address token, address payout, uint amount) external isFather returns (uint) {
        IERC20 erc20 = IERC20(token);
        if (amount == 0) {
            amount = erc20.balanceOf(address(this));
        }
        if (amount > 0) {
            SafeERC20.safeTransfer(erc20, payout, amount);
        }
        return amount;
    }


    receive() external payable {
        Address.sendValue(IFatherOfMediators(father).getPayout(), msg.value);
    }
}

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}