/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// SPDX-License-Identifier: MIT

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

pragma solidity =0.8.4;

abstract contract  Context {  
    
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 
abstract contract PartnerOwnable is Context {
    address private _owner;
    address private _admin;
    address private _partner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartnerTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        _admin = msgSender;
        _partner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function owner_admin() public view returns (address) {
        return _admin;
    }
    function owner_partner() public view returns (address) {
        return _partner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == _msgSender() || _admin == _msgSender() , 'Ownable: caller is not the partner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == _msgSender() || _admin == _msgSender() || _partner == _msgSender(), 'Ownable: caller is not the partner');
        _;
    }
    function transferPartner(address newOwner) public onlyPartner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function transferAdmin(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership(address newOwner) public onlyOwner { 
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract AdventuresTimelock  is Context, PartnerOwnable {
    
    event withdraw_Partner(address sender, uint256 value);
    event withdraw_Partner(address sender, uint256 amount256, bool success, bytes indexed data);
    event CancelTransaction(uint queueId,bytes32 indexed txHash, address indexed target, uint payableValue, string functionSignature,  bytes data, uint eta);
    event ExecuteTransaction(uint queueId,bytes32 indexed txHash, address indexed target, uint payableValue, string functionSignature,  bytes data, uint eta);
    event QueueTransaction(uint queueId,bytes32 indexed txHash, address indexed target, uint payableValue, string functionSignature, bytes data, uint eta);

    uint public delay = 24; 
    uint public grant = 14 days; 
    
    struct QUEUE {
        uint queueId;
        uint eta;
        bytes32 txHash;
        address target;
        uint payableValue;
        string functionSignature;
        bytes data;
        uint permit;
        bool queueing;
    }
    uint queueLength = 0;
    mapping (uint => QUEUE) public queuedTransactions;


    constructor()  payable {  }

    
    
    function Donate() external payable {    
        emit withdraw_Partner(msg.sender, msg.value);
    }
      
    function withdrawPartner(uint256 _amount) external onlyAdmin {   
        uint256 amount256 = address(this).balance; 
        require(amount256>_amount, "Timelock::executeTransaction: no BNB balance.");
        (bool success, bytes memory data) = address(this).call{value:_amount}(new bytes(0));
        emit withdraw_Partner(msg.sender, _amount, success, data);
    }
     

    function queueTransaction(address target, uint payableValue, string memory functionSignature, bytes memory data) public onlyPartner returns (uint)  {

        uint queueId = queueLength++;
        QUEUE storage q = queuedTransactions[queueId];
        q.target = target;
        q.payableValue= payableValue;
        q.functionSignature = functionSignature;
        q.data = data;
        q.eta = block.timestamp + delay; 
        q.permit = block.timestamp + grant; 
        q.queueing = true;
        q.txHash = keccak256(abi.encode(target, payableValue, functionSignature, data, q.eta));
        emit QueueTransaction(q.queueId, q.txHash, target, payableValue, functionSignature, data, q.eta);
        return queueId;
        
    }

    function cancelTransaction(uint256 queueId) public onlyPartner {
        
        QUEUE storage q = queuedTransactions[queueId];
        q.queueing = false;
        emit CancelTransaction(q.queueId, q.txHash, q.target, q.payableValue, q.functionSignature, q.data, q.eta);
        
    }

    function executeTransaction(uint256 queueId) public onlyPartner returns (bytes memory) {
         
        QUEUE storage q = queuedTransactions[queueId]; 
        require(q.queueing, "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= q.eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= q.permit, "Timelock::executeTransaction: Transaction is stale.");

        q.queueing = false; 

        bytes memory callData;

        if (bytes(q.functionSignature).length == 0) {
            callData = q.data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(q.functionSignature))), q.data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = q.target.call(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(q.queueId, q.txHash, q.target, q.payableValue, q.functionSignature, q.data, q.eta);

        return returnData;
    }
    
    function executeTransactionPayable(uint256 queueId) public onlyPartner payable returns (bytes memory) {
         
        QUEUE storage q = queuedTransactions[queueId]; 
        require(q.queueing, "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= q.eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= q.permit, "Timelock::executeTransaction: Transaction is stale.");

        q.queueing = false; 

        bytes memory callData;

        if (bytes(q.functionSignature).length == 0) {
            callData = q.data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(q.functionSignature))), q.data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = q.target.call{value:q.payableValue}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(q.queueId, q.txHash, q.target, q.payableValue, q.functionSignature, q.data, q.eta);

        return returnData;
    }
 
}