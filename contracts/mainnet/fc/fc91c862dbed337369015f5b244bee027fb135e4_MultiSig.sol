/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental SMTChecker;


interface ERC20If {
  function balanceOf(address _who) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
}

contract MultiSig{
    receive() external payable {}

    uint256 public nonce = 0;

    int private withdrawFlag1 = 0;
    int private withdrawFlag2 = 0;
    int private withdrawFlag3 = 0;

    int private closeFlag1 = 0;
    int private closeFlag2 = 0;
    int private closeFlag3 = 0;

    address[] private owners=new address[](3);

    constructor(address _owner1,address _owner2,address _owner3)
    {
        require(_owner1!=_owner2);
        require(_owner1!=_owner3);
        require(_owner2!=_owner3);

        owners[0] = _owner1;
        owners[1] = _owner2;
        owners[2] = _owner3;
    }

    fallback() external payable {}

    function getMessageToSignature(address payable[] memory dests, uint256[] memory values) private view returns (bytes memory) {
        return abi.encode(nonce, dests, values, this);
    }

//测试使用
//    function testABIEncode(address[] memory dests, uint256[] memory values,
  //                  uint8 v1, bytes32 r1, bytes32 s1,
    //                uint8 v2, bytes32 r2, bytes32 s2) public view returns (bytes memory) {
      //  return abi.encode(dests, values,v1,r1, s1, v2, r2, s2);
    //}

    function recoverAddress(bytes32 message, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
        return ecrecover(message, v, r, s);
    }

    function hash(bytes memory data) private pure returns (bytes32) {
        return sha256(data);
    }

    function _validAddress(address addr) private view returns (bool) {
        return owners[0] == addr || owners[1] == addr || owners[2] == addr;
    }

    function spend(address payable[] memory dests, uint256[] memory values,
                    uint8 v1, bytes32 r1, bytes32 s1,
                    uint8 v2, bytes32 r2, bytes32 s2) public payable {
        require(dests.length > 0 && dests.length == values.length);
        uint256  value;
        for (uint i = 0; i < values.length; ++i){
            value += values[i];
            assert(value >= values[i]);
        }
        require(address(this).balance >= value, "insufficient funds");

        bytes32 h=hash((getMessageToSignature(dests, values)));
        address addr1=recoverAddress(h, v1, r1, s1);
        address addr2=recoverAddress(h, v2, r2, s2);
        require(addr1 != addr2, "failed to recover address");
        require(_validAddress(addr1), "invalid address");
        require(_validAddress(addr2), "invalid address");
        nonce = nonce + 1;

        for (uint i = 0; i < dests.length; ++i) {
            // dests[i].transfer(values[i]);
            (bool success, ) =dests[i].call{value:values[i]}("");
            require(success, "transfer failed.");
        }
    }

    function withdrawAll() public payable {
        require(_validAddress(msg.sender), "invalid address");
        if (msg.sender == owners[0]) {
            withdrawFlag1 = 1;
        }
        else if (msg.sender == owners[1]) {
            withdrawFlag2 = 1;
        }
        else if (msg.sender == owners[2]) {
            withdrawFlag3 = 1;
        }
        else {
                assert(false);
        }

        if ((withdrawFlag1+withdrawFlag2+withdrawFlag3)>=2) {
            withdrawFlag1 = 0;
            withdrawFlag2 = 0;
            withdrawFlag3 = 0;
            (bool success, ) = msg.sender.call{value:address(this).balance}("");
            if (!success) {
               revert("withdraw all failed");
            }
        }
    }

    function close() public payable {
        require(_validAddress(msg.sender), "invalid address");
        if (msg.sender == owners[0]) {
            closeFlag1 = 1;
        }
        else if (msg.sender == owners[1]) {
            closeFlag2 = 1;
        }
        else if (msg.sender == owners[2]) {
            closeFlag3 = 1;
        }
        else {
                assert(false);
            }

        if ((closeFlag1+closeFlag2+closeFlag3)>=2){
            selfdestruct(msg.sender);
        }
    }

    function transferERC20(address payable[] memory dests, uint256[] memory values,
                    uint8 v1, bytes32 r1, bytes32 s1,
                    uint8 v2, bytes32 r2, bytes32 s2, address erc20Token) public  {
        require(dests.length > 0 && dests.length == values.length);
        uint256  value;
        for (uint i = 0; i < values.length; ++i){
            value += values[i];
            assert(value >= values[i]);
        }
        ERC20If _erc20=(ERC20If)(erc20Token);
        require(_erc20.balanceOf(address(this)) >= value, "insufficient ERC20 funds");

        require(
            verifySignature4ERC20Token(dests,values,v1,r1,s1,v2,r2,s2,erc20Token),
            "invalid signature.");

        nonce = nonce + 1;

        for (uint i = 0; i < dests.length; ++i) {
            require(
                (_erc20).transfer(dests[i],values[i]),
                 "transfer erc20Token failed");
        }
    }

    function verifySignature4ERC20Token(address payable[] memory dests, uint256[] memory values,
                    uint8 v1, bytes32 r1, bytes32 s1,
                    uint8 v2, bytes32 r2, bytes32 s2, address erc20) private view returns (bool) {
        bytes32 h=hash(getMessageToSignature4ERC20Token(dests, values,erc20));
        address addr1=recoverAddress(h, v1, r1, s1);
        address addr2=recoverAddress(h, v2, r2, s2);
        require(addr1 != addr2, "failed to recover address");
        require(_validAddress(addr1), "invalid address");
        require(_validAddress(addr2), "invalid address");
        return true;
    }

    function getMessageToSignature4ERC20Token(address payable[] memory dests,
    uint256[] memory values, address erc20) public view returns (bytes memory) {
        return abi.encode(nonce, dests, values, erc20);
    }
}