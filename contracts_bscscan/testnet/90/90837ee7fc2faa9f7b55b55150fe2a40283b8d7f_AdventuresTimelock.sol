/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: MIT

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ver 1.7.16

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
    
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event Donate_amount(address sender, uint256 value); 
    event withdraw_Partner(address sender, uint256 amount256, bool success, bytes indexed data);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint payableValue, string functionSignature, bytes data, uint eta);

    address public pendingAdmin;
    uint public delay = 1 days; 
    uint public constant GRACE_PERIOD = 14 days;
    
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
    uint public queuedsInfoLength = 1;
    mapping (uint => QUEUE) public queuedsInfo;
    
    mapping (bytes32 => bool) public queuedTransactions;


    constructor()   { 
        pendingAdmin = msg.sender;
    }

    receive() external payable { }
    
    
    function setDelay(uint delay_) public onlyOwner{  
        require(msg.sender==pendingAdmin, "Timelock::setDelay require pendingAdmin.");
        delay = delay_;
        emit NewDelay(delay);
    }    
     
    function renouncePendingAdmin() public onlyOwner { 
        pendingAdmin = address(0);
        emit NewPendingAdmin(pendingAdmin);
    } 
    
    
    function Donate() external payable {    
        emit Donate_amount(msg.sender, msg.value);
    }
      
    function withdrawPartner(uint256 _amount) external onlyAdmin {   
        uint256 amount256 = address(this).balance; 
        require(amount256>_amount, "Timelock::executeTransaction: no BNB balance.");
        (bool success, bytes memory data) = msg.sender.call{value:_amount}(new bytes(0));
        emit withdraw_Partner(msg.sender, _amount, success, data);
    }
    
    function get_data(address _address) public pure returns(bytes memory){ 
        bytes memory data = new bytes(32);
        bytes memory d =  abi.encodePacked(_address);
        for(uint i = 0; i<20; i++) data[i+12] = d[i];
        return data;
    }
    function get_eta() public view returns(uint eta){
        eta = block.timestamp+delay;
    }
    
    function get_queueId_txHash(bytes32 _txHash) public view returns(uint id){
        for(uint i=queuedsInfoLength-1;i>0;i--){
            QUEUE memory q = queuedsInfo[i];
            if(q.txHash==_txHash){
                return i;
            }
        }
        return 0;
    }
     
 
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public onlyPartner returns (bytes32)  {
    
        require(eta >= block.timestamp+delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        uint queueId = queuedsInfoLength++;
        QUEUE storage q = queuedsInfo[queueId];
        q.queueId = queueId;
        q.target = target;
        q.payableValue= value;
        q.functionSignature = signature;
        q.data = data;
        q.eta = eta; 
        q.permit = eta + GRACE_PERIOD; 
        q.queueing = true;
        q.txHash = keccak256(abi.encode(target, value, signature, data, q.eta));
        
        queuedTransactions[q.txHash] = true;
        
        emit QueueTransaction(q.txHash, target, value, signature, data, q.eta);
        return q.txHash;
        
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;
        uint queueId = get_queueId_txHash(txHash);
        if(queueId>0) {
            QUEUE storage q = queuedsInfo[queueId];
            q.queueing = false;
        } 
        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }
      
    
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable onlyPartner returns (bytes memory) {

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(block.timestamp <= eta+GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");
        
        uint queueId = get_queueId_txHash(txHash);
        if(queueId>0) {
            QUEUE storage q = queuedsInfo[queueId];
            q.queueing = false;
        } 

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
    
  
}