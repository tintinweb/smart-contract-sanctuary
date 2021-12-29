/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.5.0;
contract SolidityTest {         
    address  owner;           
    uint  projectsize; 
    uint  transize; 
    uint  projectid_increment;         //number of student's added .
    uint  transid_increment;
    constructor() public{
        owner = msg.sender;         //get owners address
    }
    struct project {           //struct for student's info 
        uint projectID;
        string projectTitle;
        string projectDescription;
        uint projectFundingAmount;
        address payable projectOwner;
        uint projectFunding;
        bool completed;

    }
    project[] Projects;

    struct transactions{
        uint transactionID;
        uint projectID;
        address receiver;
        address sender;
        uint amount;
    }
    transactions[] Transactions;


    function insertProjects(string memory _projectTitle , string memory _projectDescription, uint _projectFundingAmount) public {            //add user function
        projectsize = Projects.length++;  
        projectid_increment++;                                            //go to next 
        Projects[Projects.length - 1].projectID = projectid_increment;               //insert id
        Projects[Projects.length - 1].projectTitle = _projectTitle;           //insert name
        Projects[Projects.length - 1].projectDescription = _projectDescription;         //insert email
        Projects[Projects.length - 1].projectFundingAmount = _projectFundingAmount;         //insert programme
        Projects[Projects.length - 1].projectOwner = msg.sender;
    }
    

    function writeTransactions(uint _projectID , address  _receiver, address _sender, uint _amount) private {            //add user function
        transize = Transactions.length++;  
        transid_increment++;                                            //go to next 
        Transactions[Transactions.length - 1].transactionID = transid_increment;               //insert id
        Transactions[Transactions.length - 1].projectID = _projectID;           //insert name
        Transactions[Transactions.length - 1].receiver = _receiver;         //insert email
        Transactions[Transactions.length - 1].sender = _sender;         //insert programme
        Transactions[Transactions.length - 1].amount = _amount;     
    }

    function showProject(uint index) public view returns(uint _projectID, string memory _projectTitle, string memory _projectDescription, uint _projectFundingAmount, address _projectOwner, uint _projectFunding, bool _completed) {    //get student's info function
        for (uint i = 0; i <= projectsize; i++){   // check all rows
            if(index == Projects[i].projectID){ //target the student's id
                return (Projects[i].projectID, Projects[i].projectTitle, Projects[i].projectDescription, Projects[i].projectFundingAmount, Projects[i].projectOwner, Projects[i].projectFunding, Projects[i].completed); //print students info
            }
        }
    }
    function showTransaction(uint index) public view returns(uint _transactionID, uint _projectID, address _receiver, address _sender, uint _amount) {    //get student's info function
        for (uint i = 0; i <= transize; i++){   // check all rows
            if(index == Transactions[i].transactionID){ //target the student's id
                return (Transactions[i].transactionID, Transactions[i].projectID, Transactions[i].receiver, Transactions[i].sender, Transactions[Transactions.length - 1].amount); //print students info
            }
        }
    }

    function funding(uint index) public payable  {
        for (uint i = 0; i <= projectsize; i++){   // check all rows   
            if(index == Projects[i].projectID){ //target the student's id
                if(Projects[i].completed == false){
                    if((Projects[i].projectFundingAmount - Projects[i].projectFunding)  > msg.value){
                        Projects[i].projectOwner.transfer(msg.value);
                        Projects[i].projectFunding += msg.value;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, msg.value);
                    }else if((Projects[i].projectFundingAmount - Projects[i].projectFunding)  == msg.value){
                        Projects[i].projectOwner.transfer(msg.value);
                        Projects[i].projectFunding = Projects[i].projectFundingAmount;
                        Projects[i].completed = true;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, msg.value);          
                    }else{
                        Projects[i].projectOwner.transfer(Projects[i].projectFundingAmount - Projects[i].projectFunding);
                        Projects[i].projectFunding = Projects[i].projectFundingAmount;
                        Projects[i].completed = true;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, (Projects[i].projectFundingAmount - Projects[i].projectFunding));             
                    }
                }
            }else{
                //return "The Project has reached goal amount";
            }
        }       
    }
}