/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.5.0;

contract crowdfunding {
    
    uint projectid_increment;
    uint  size; 
    uint  transize;
    uint  transid_increment;
    constructor() public {
       
    }
    
    
    
    struct Projects {
        uint projectID;
        string projectTitle;
        string projectDescription;
        uint projectFundingAmount;
        address payable projectOwner;
        uint projectFunding;
    }
    
    Projects[] ProjectsRecords;

    struct transactions{
        uint transactionID;
        uint projectID;
        address pOwner;
        address donator;
        uint amount;
        
    }

    transactions[] Transactions;

    function registerProject(string memory _projectTitlte, string memory _projectDescription, uint _projectFundingAmount) public {
        
        size = ProjectsRecords.length++;
        projectid_increment++;
        ProjectsRecords[ProjectsRecords.length-1].projectID = projectid_increment;
        ProjectsRecords[ProjectsRecords.length-1].projectTitle = _projectTitlte;
        ProjectsRecords[ProjectsRecords.length-1].projectDescription = _projectDescription;
        ProjectsRecords[ProjectsRecords.length-1].projectFundingAmount = _projectFundingAmount;
        ProjectsRecords[ProjectsRecords.length-1].projectOwner = msg.sender;
    }

    function searchProject(uint _projectIDindex) public view returns(uint _projectID, string memory _projectTitlte, string memory _projectDescription,
                                                                 uint _projectFundingAmount, address _projectOwner, uint _projectFunding){
        uint index =0;
        for (uint i=0; i<=size; i++){
                if (ProjectsRecords[i].projectID == _projectIDindex){
                    index=i;
                    return (ProjectsRecords[index].projectID, ProjectsRecords[index].projectTitle, ProjectsRecords[index].projectDescription,
                ProjectsRecords[index].projectFundingAmount, ProjectsRecords[index].projectOwner, ProjectsRecords[index].projectFunding);
                }
            }
    }

    function writeTransactions(uint _projectID , address  _pOwner, address _donator, uint _amount) private {            //add user function
        transize = Transactions.length++;  
        transid_increment++;                                            //go to next 
        Transactions[Transactions.length - 1].transactionID = transid_increment;               //insert id
        Transactions[Transactions.length - 1].projectID = _projectID;           //insert name
        Transactions[Transactions.length - 1].pOwner = _pOwner;         //insert email
        Transactions[Transactions.length - 1].donator = _donator;         //insert programme
        Transactions[Transactions.length - 1].amount = _amount; 
            
    }




    function funding(uint index) public payable  {
        for (uint i = 0; i <= size; i++){   // check all rows   
            if(index == ProjectsRecords[i].projectID){ //target the project's id
                ProjectsRecords[i].projectOwner.transfer(msg.value);
                ProjectsRecords[i].projectFunding += msg.value;
                writeTransactions(ProjectsRecords[i].projectID, ProjectsRecords[i].projectOwner, msg.sender, msg.value);
                
            }
        }       
    }
   
}