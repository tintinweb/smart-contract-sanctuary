/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity >=0.7.0 <0.8.0;

contract SmartMatrixStarry{
    struct User{
        address Id;
        address Introducer;
    }
    
    struct Table{
        uint Fee;
        uint Bonus;
    }

    struct TableDetail{
        uint TableId;
        address A;
        address B;
        address C;
        address D;
        address E;
        address F;
        address G;
        uint Fee;
        uint Bonus;
        uint Status;
    }

    mapping(uint => Table) tables;
    mapping(uint => TableDetail) tableDetails;
    mapping(address => User) users;
    
    address payable _owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint detailId = 0;
    
    function init() public{
        tables[1] = Table(1,2);
        tables[2] = Table(10,20);
        
        detailId += 1;
        tableDetails[detailId] = TableDetail(1,address(0),address(0),address(0),address(0),address(0),address(0),address(0),tables[1].Fee,tables[1].Bonus,0);
        detailId += 1;
        tableDetails[detailId] = TableDetail(2,address(0),address(0),address(0),address(0),address(0),address(0),address(0),tables[1].Fee,tables[1].Bonus,0);
    }

    function register(address introducer) public {
        users[address(this)] = User(address(this),introducer);
    }
    
    function openTable(address user,uint tableId) public{
        address introducer = users[user].Introducer;
        require(introducer == address(0), "user is not exists.");
        
        active(tables[tableId].Fee);
        
        for(uint i = 1;i<=detailId;i++){
            if(tableDetails[i].Status == 0 && tableDetails[i].TableId == tableId &&
               (tableDetails[i].A == introducer ||
                tableDetails[i].B == introducer ||
                tableDetails[i].C == introducer ||
                tableDetails[i].D == introducer ||
                tableDetails[i].E == introducer ||
                tableDetails[i].F == introducer)){
                    if(tableDetails[i].D == address(0)){
                        tableDetails[i].D = user;
                    }else if(tableDetails[i].E == address(0)){
                        tableDetails[i].E= user;
                    }else if(tableDetails[i].F == address(0)){
                        tableDetails[i].F = user;
                    }else{
                        tableDetails[i].G = user;
                        tableDetails[i].Status = 1;
                        //finished 
                        detailId +=1;
                        tableDetails[detailId].A = tableDetails[i].B;
                        tableDetails[detailId].B = tableDetails[i].D;
                        tableDetails[detailId].C = tableDetails[i].E;
                        tableDetails[detailId].Fee = tables[tableId].Fee;
                        tableDetails[detailId].Bonus = tables[tableId].Bonus;
                        
                        detailId +=1;
                        tableDetails[detailId].A = tableDetails[i].C;
                        tableDetails[detailId].B = tableDetails[i].F;
                        tableDetails[detailId].C = tableDetails[i].G;
                        tableDetails[detailId].Fee = tables[tableId].Fee;
                        tableDetails[detailId].Bonus = tables[tableId].Bonus;
                        
                        sendBonus(tableDetails[i].Bonus,tableDetails[i].A) ;
                        
                        if(tableId == 1){
                            openTable(tableDetails[i].A,2);
                        }else{
                            openTable(tableDetails[i].A,tableId);
                        }
                    }
                }
        }
    }
    
    function sendBonus(uint bonus,address user)  public{
         address(uint160(user)).transfer(bonus);
    }
    
    function active(uint fee) public {
        _owner.transfer(fee);
    }
}