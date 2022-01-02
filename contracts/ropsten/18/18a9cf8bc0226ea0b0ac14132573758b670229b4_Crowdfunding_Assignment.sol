/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.5.0;
contract Crowdfunding_Assignment{         
    
               
    uint  projectsize; 
    uint  transize; 
    uint  projectid_increment;         //number of student's added .
    uint  transid_increment;
   
    struct project {           //struct for student's info 
        uint projectID;
        string projectTitle;
        string projectDescription;
        uint projectFundingAmount;
        address payable projectOwner;
        uint projectFunding;
        bool completed;
        uint transcount;

    }
    project[] Projects;

    struct transactions{
        uint transactionID;
        uint projectID;
        address receiver;
        address sender;
        uint amount;
        uint transcount;
        address tHash;
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
    

    function writeTransactions(uint _projectID , address  _receiver, address _sender, uint _amount, uint _transcount) private {            //add user function
        transize = Transactions.length++;  
        transid_increment++;                                            //go to next 
        Transactions[Transactions.length - 1].transactionID = transid_increment;               //insert id
        Transactions[Transactions.length - 1].projectID = _projectID;           //insert name
        Transactions[Transactions.length - 1].receiver = _receiver;         //insert email
        Transactions[Transactions.length - 1].sender = _sender;         //insert programme
        Transactions[Transactions.length - 1].amount = _amount; 
        Transactions[Transactions.length - 1].transcount = _transcount;    
    }

    function writeTransactionHash(uint _projectindex, uint _projectran, address _tHash) private {            //add user function
       for (uint i = 0; i <= transize; i++){   // check all rows
            if(_projectindex == Transactions[i].projectID && _projectran == Transactions[i].transcount){ //target the student's id
                Transactions[i].tHash = _tHash;
            }
        }    
    }

    
    
    function showTransaction(uint projectindex, uint projectran) public view returns(uint _transactionID, uint _projectID, address _receiver,
                                                                                    address _sender, uint _amount, uint _projectran, address _tHash) {    //get student's info function
        for (uint i = 0; i <= transize; i++){   // check all rows
            if(projectindex == Transactions[i].projectID && projectran == Transactions[i].transcount){ //target the student's id
                return (Transactions[i].transactionID, Transactions[i].projectID, Transactions[i].receiver,
                        Transactions[i].sender, Transactions[i].amount, Transactions[i].transcount, Transactions[i].tHash); //print students info
            }
        }
    }

    function showProject(uint index) public view returns(uint _projectID, string memory _projectTitle, string memory _projectDescription,
                                                         uint _projectFundingAmount, address _projectOwner, uint _projectFunding,
                                                         bool _completed, uint _transcount) {    //get student's info function
        for (uint i = 0; i <= projectsize; i++){   // check all rows
            if(index == Projects[i].projectID){ //target the student's id
                return (Projects[i].projectID, Projects[i].projectTitle, Projects[i].projectDescription, Projects[i].projectFundingAmount,
                         Projects[i].projectOwner, Projects[i].projectFunding, Projects[i].completed, Projects[i].transcount); //print students info
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
                        Projects[i].transcount ++;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, msg.value, Projects[i].transcount);
                    }else if((Projects[i].projectFundingAmount - Projects[i].projectFunding)  == msg.value){
                        Projects[i].projectOwner.transfer(msg.value);
                        Projects[i].projectFunding = Projects[i].projectFundingAmount;
                        Projects[i].completed = true;
                        Projects[i].transcount ++;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, msg.value, Projects[i].transcount);          
                    }else{
                        Projects[i].projectOwner.transfer(Projects[i].projectFundingAmount - Projects[i].projectFunding);
                        Projects[i].projectFunding = Projects[i].projectFundingAmount;
                        Projects[i].completed = true;
                        Projects[i].transcount ++;
                        writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender,
                                         (Projects[i].projectFundingAmount - Projects[i].projectFunding), Projects[i].transcount);             
                    }
                }
            }
        }       
    }
}