/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: UNLICENSED

contract HodlBank {
    
    mapping(address => Deposit[]) private accounts;
    
    struct Deposit {
        uint balance;
        uint withdrawTime;
    }
    
    function deposit(uint256 delay) payable public {
        require(msg.value > 0, "You have to deposit some ether...");
        Deposit memory newDeposit = Deposit(msg.value, block.timestamp + delay);
        accounts[msg.sender].push(newDeposit);
    }
    
    function getRemainingDeposits() public view returns(Deposit[] memory){
        return accounts[msg.sender];
    }
    
    function withdraw() payable public {
        Deposit[] memory deposits = accounts[msg.sender];
        require(deposits.length > 0, "You have no deposit...");
        uint lowest = deposits[0].withdrawTime;
        uint lowestIndex;
        for (uint i = 1; i < deposits.length; i++) {
            if(deposits[i].withdrawTime < lowest) {
                lowest = deposits[i].withdrawTime;
                lowestIndex = i;
            }
        }
        require(deposits[lowestIndex].withdrawTime < block.timestamp, 
            string(abi.encodePacked("You have to wait ", 
            uint2str(deposits[lowestIndex].withdrawTime - block.timestamp),
            "s to withdraw first deposit.",
            " All deposits: ",
            uint2str(deposits.length))));
        payable(msg.sender).transfer(deposits[lowestIndex].balance * (1 wei));
        removeDeposit(lowestIndex);
    }
    
    function removeDeposit(uint index) private {
        uint length = accounts[msg.sender].length;
        require(index < length);
        accounts[msg.sender][index] = accounts[msg.sender][length-1];
        accounts[msg.sender].pop();
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}