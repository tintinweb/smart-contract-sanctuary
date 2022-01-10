/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.5.0;

contract Funding {

    uint public ps=0;       // projcet table size
    uint public TS;    // transactions size 

      constructor() public {
       
    }


    struct Project { 
        uint projectID;
        string projectTitle;
        string projectDescription;
        uint projectFundingAmount;       // to poso pou stelni o xristis  xriazete id tu project j require.value   
        address payable projectOwner;
        uint projectFunding;    // avxanete me vasi to projectFundingAmount 
        bool completed;

    } Project[] project;



    struct Transactions {

        uint transactionID;  
        uint projectID;
        address sender;
        //address receiver;
        uint amount;

    } Transactions[] transactions;



    function createproject( string memory _projectTitle, string memory _projectDescription, uint _projectFundingAmount /* , uint _projectFunding  */ ) public {  // creat a project function 

        ps = project.length++;
        
        project[project.length-1].projectID= ps;
        project[project.length-1].projectTitle = _projectTitle;
        project[project.length-1].projectDescription = _projectDescription;
        project[project.length-1].projectFundingAmount = _projectFundingAmount;    // amount needed for the project .
        project[project.length-1].projectOwner = msg.sender;           
        project[project.length-1].projectFunding = 0 ;             // balance of the funding 
        project[project.length-1].completed = false;
        
        
    }


       function fundingTransaction(uint _projectID )  public payable {

        TS = transactions.length++;
        uint _amount = msg.value;
        transactions[transactions.length-1].transactionID= TS+1;
        transactions[transactions.length-1].projectID = _projectID;
        
        transactions[transactions.length-1].amount = _amount;   
        transactions[transactions.length-1].sender = msg.sender;

        for(uint i=0; i<=ps; i++){
            if(transactions[transactions.length-1].projectID==project[i].projectID){
                require(project[i].completed==false , 'The project is completed.');
                project[i].projectOwner.transfer(_amount);
                project[i].projectFunding = project[i].projectFunding + _amount;
                if(project[i].projectFunding>=project[i].projectFundingAmount){
                    project[i].completed = true;
                }
            }
        }   
    }
    

    function searchproject(uint _id) public view returns(uint, string memory, string memory, uint,address,uint,bool){   // read function 
        uint index =0;
        for (uint i=0; i<=ps; i++){
            if (project[i].projectID == _id){   // search 
                index=i;
            }
        }
        return (project[index].projectID, project[index].projectTitle, project[index].projectDescription, project[index].projectFundingAmount, project[index].projectOwner, project[index].projectFunding, project[index].completed);   // view all info from the struct . 
    }

    function readfunction() public view returns(uint, string memory, string memory, uint,address,uint,bool){   // read function 
        
        for (uint i=0; i<=ps; i++){
           return (project[i].projectID, project[i].projectTitle, project[i].projectDescription, project[i].projectFundingAmount, project[i].projectOwner, project[i].projectFunding, project[i].completed); 
        }
        
    }

}