/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

library CompareString {
    function comparefunction(string memory x) internal pure returns (uint output){
        if (keccak256(abi.encodePacked(x))==keccak256(abi.encodePacked("A"))){
            output=1;
        }else if (keccak256(abi.encodePacked(x))==keccak256(abi.encodePacked("B"))){
            output=2;
        }else if (keccak256(abi.encodePacked(x))==keccak256(abi.encodePacked("D"))){
            output=3;
        }else if (keccak256(abi.encodePacked(x))==keccak256(abi.encodePacked())){
            output=4;
        }
    }
}

contract Bet {
    using CompareString for string;
    
    mapping(address => uint) balancesA;
    mapping(address => uint) balancesB;
    uint totalA;
    uint totalB;
    string result;
    uint amount;
    uint total;
    address mslot;
    address payable [] participant_add;
    uint repeat;
    address payable refund_add;
    string question;
    string option1;
    string option2;
    uint[] clientamount;
    uint clientnumber;
    
    function input_question(string memory _question, string memory _option1 , string memory _option2) public check_description{
        question=_question;
        option1=_option1;
        option2=_option2;
    }
    
    function return_question() public view returns(string memory, string memory, string memory){
        return (question, option1, option2);
    }
    
    function input_result(string memory _result) public check_inputresult{
        require(_result.comparefunction()==1 || _result.comparefunction()==2 || _result.comparefunction()==3, "Input wrong.");
        result = _result;
    }
    
    function betA(uint stakeA) payable public check_betac{
        //payable(address(this)).transfer(stakeA);
        balancesA[msg.sender] += stakeA;
        totalA+=stakeA;
        total+=stakeA;
        repeat=0;
        for(uint i = 0; i < participant_add.length; i++){
            if (participant_add[i]==msg.sender){
                repeat=1;
            }
        }
        if (repeat==0){
            participant_add.push(msg.sender);
        }
    }

    function betB(uint stakeB) payable public check_betac{
        //payable(address(this)).transfer(msg.value);
        balancesB[msg.sender] += stakeB;
        totalB+=stakeB;
        total+=stakeB;
        repeat=0;
        for(uint i = 0; i < participant_add.length; i++){
            if (participant_add[i]==msg.sender){
                repeat=1;
            }
        }
        if (repeat==0){
            participant_add.push(msg.sender);
        }
    }
    
    function cal_settle() public payable check_resultnull {
        for(uint i = 0; i < participant_add.length; i++){
            amount=0;
            refund_add=participant_add[i];
            if (result.comparefunction()==1 && balancesA[refund_add] != 0){ //加totalA和totalB為0時的情況
                if (totalA !=0){
                    amount=balancesA[refund_add]*totalB/totalA+balancesA[refund_add];
                }else{
                    amount=balancesA[refund_add];
                }
            } else if (result.comparefunction()==2 && balancesB[refund_add] != 0){
                if (totalB !=0){
                    amount=balancesB[refund_add]*totalA/totalB+balancesB[refund_add];
                }else{
                    amount=balancesB[refund_add];
                }
            } else if (result.comparefunction()==3){
                amount=balancesA[refund_add]+balancesB[refund_add];
            }
            balancesA[refund_add]=0;
            balancesB[refund_add]=0;
            total-=amount;
            clientnumber=i;
            clientamount.push(amount);
            //refund_add.transfer(amount);
        }
        amount=total;
        total=0;
        //msg.sender.transfer(amount);
    }
    
    function get_data() public view returns(uint [] memory, uint, address payable [] memory, uint){
        return (clientamount, clientnumber, participant_add, amount);
    }
    
    function transfer(address payable to, uint value) public payable returns(bool) {
        //if(balances[msg.sender] < value) throw;
        //balances[msg.sender] -= value;
        to.transfer(value);
        //LogTransfer(msg.sender, to, value);
        return true;
    }
    
    function refundMslot(address payable to, uint value) public payable returns(bool) {
        //if(balances[msg.sender] < value) throw;
        //balances[msg.sender] -= value;
        to.transfer(value);
        //LogTransfer(msg.sender, to, value);
        return true;
    }
    
    modifier check_inputresult{
        require(msg.sender == mslot, "Only MSlot can set the results.");
        require(question.comparefunction()!=4 && option1.comparefunction()!=4 && option2.comparefunction()!=4, "No question.");
        require(result.comparefunction()==4, "Contract end.");
        _;
    }
    
    modifier check_betac{
        require(msg.sender != mslot, "MSlot can't bet.");
        require(question.comparefunction()!=4 && option1.comparefunction()!=4 && option2.comparefunction()!=4, "No question.");
        require(result.comparefunction()==4, "Contract end.");
        _;
    }
    
    modifier check_resultnull{
        require(msg.sender == mslot, "Only MSlot can settle.");
        //require(question.comparefunction()!=4 && option1.comparefunction()!=4 && option2.comparefunction()!=4, "No question.");
        //require(result.comparefunction()!=4, "No result.");
        //require(total != 0, "No balance due.");
        _;
    }
    
    modifier check_description{
        //require(msg.sender == mslot, "Only MSlot can input question.");
        //require(question.comparefunction()==4 && option1.comparefunction()==4 && option2.comparefunction()==4, "Can't repeat.");
        _;
    }
    
    fallback() external payable {}
    receive() external payable {}
}