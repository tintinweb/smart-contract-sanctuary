/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract VoteGame {
    address owner ; 
    string  candidateName_1 ; 
    string  candidateName_2 ;
    //候選人票數
    uint totalVoteCount1 ; 
    uint totalVoteCount2 ; 
    mapping (address => uint ) VoteTicketMap_1 ; 
    address[] VoteAddressArray_1 ; 
    mapping (address => uint ) VoteTicketMap_2 ; 
    address[] VoteAddressArray_2 ; 
    
    mapping ( address => uint ) Tickets;
    mapping ( address => bool ) isRegistered;
    address [] registeredMembers ; 
    
    //初始化，建構子
    constructor(string memory _candidate1 , string memory _candidate2)  {
        owner = msg.sender;
        candidateName_1  = _candidate1 ;
        candidateName_2  = _candidate2 ;
        totalVoteCount1 = 0 ;
        totalVoteCount2 = 0 ;
    }
    
    //事件
    event eventGetNewVoteResult(
        uint totalVoteCount1,
        uint totalVoteCount2
    );
    
    //已經註冊過才能執行
    modifier hasRegistered{
        require ( isRegistered [msg.sender] == true );
        _;
    }
    
    //合約擁有者才能執行
    modifier Onlyowner{
        require ( msg.sender == owner );
        _;
    }
        
    
    //查看目前候選人
    function GetCandidateName() public view returns(string memory, string memory){
        return (candidateName_1 , candidateName_2);
    }
    
    //拿取投票結果
    function GetVoteResult() public view returns(uint,uint){
        return (totalVoteCount1 , totalVoteCount2);
    }
    
    //查看投票人列表
    function GetVoteList() public view returns(address[] memory,address[] memory){
        return (VoteAddressArray_1 , VoteAddressArray_2);
    }
    
    //投票
    function Vote(uint _candidateNumber , uint _voteNumber) public hasRegistered {
        //檢查票數是否足夠 & 輸入的候選人是否正確
        require( (Tickets[msg.sender] >= _voteNumber) && ( _candidateNumber== 1 || _candidateNumber == 2 ));
        if( _candidateNumber == 1 ){
            
            if( VoteTicketMap_1[msg.sender] == 0 ){
                // 如果沒有投過票，就先放進陣列
                VoteAddressArray_1.push(msg.sender);
            }
            VoteTicketMap_1[msg.sender] += _voteNumber ; 
            totalVoteCount1 += _voteNumber ; 
            
        }
        if ( _candidateNumber == 2 ){
            if(VoteTicketMap_2[msg.sender] == 0 ){
                VoteAddressArray_2.push(msg.sender);
            }
            VoteTicketMap_2[msg.sender] += _voteNumber;
            totalVoteCount2 += _voteNumber ;
        }
        //扣除投過得票數
        Tickets[msg.sender] -= _voteNumber ;
        
        //事件：新投票結果
        emit eventGetNewVoteResult(totalVoteCount1,totalVoteCount2);
    }
    
    
    

    //查看票券數量
    function check() public hasRegistered view returns(uint) {
        return Tickets [ msg.sender] ; 
    }
    
    //是否有註冊
    function isRegister() public view returns (bool){
        return isRegistered[msg.sender];
    }
    
    //註冊，並給500張
    function signup() public {
        require(isRegistered[msg.sender] == false);
        registeredMembers.push(msg.sender) ;
        Tickets[msg.sender] = 500 ; 
        isRegistered[msg.sender] = true ;
    }
    
    //結束遊戲，並分配獎金
    function EndVoteAndCreateNewGame(string memory _candidate1,string memory _candidate2) Onlyowner public{
        uint totalVoteCount = totalVoteCount1 + totalVoteCount2 ; 
        if(totalVoteCount1 > totalVoteCount2){
            for(uint i=0 ; i< VoteAddressArray_1.length ; i++){
               Tickets[VoteAddressArray_1[i]] += (totalVoteCount*9/10) * VoteTicketMap_1[VoteAddressArray_1[i]] / totalVoteCount1 ; 
            }
        }
        if(totalVoteCount2 > totalVoteCount1){
            for(uint i=0 ; i< VoteAddressArray_2.length ; i++){
               Tickets[VoteAddressArray_2[i]] += (totalVoteCount*9/10) * VoteTicketMap_2[VoteAddressArray_2[i]] / totalVoteCount2 ; 
            }
        }
        totalVoteCount1 = 0 ;
        totalVoteCount2 = 0 ;
        
        for(uint i=0 ; i<VoteAddressArray_1.length ; i++){
            delete VoteTicketMap_1[VoteAddressArray_1[i]];
        }
        delete VoteAddressArray_1;
        
        for(uint i=0 ; i<VoteAddressArray_2.length ; i++){
            delete VoteTicketMap_2[VoteAddressArray_2[i]];
        }
        delete VoteAddressArray_2;
        
        candidateName_1 = _candidate1;
        candidateName_2 = _candidate2;
        
    }
    
    
    
}