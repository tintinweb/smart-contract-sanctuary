/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.5.0;                     //compiler version
contract Crowdfunding_Assignment{           //contract creation       
    
               
    uint  projectsize;                  //count how many projects inserted in array
    uint  transize;                     //count how many transactions the whole dapp made
    uint  projectid_increment;         //the id of a project needs to be auto increament
    uint  transid_increment;            //the id of a transaction needs to be auto increament
   
    struct project {                            //struct for project's info 
        uint projectID;                         //unique number for project
        string projectTitle;                    //save project Title
        string projectDescription;              //save project Description
        uint projectFundingAmount;              //save project Goal Amount
        address payable projectOwner;           //save who is project Creator
        uint projectFunding;                    //save amount funded till now
        bool completed;                         //check if the goal amount reached
        uint transcount;                        //count how many times this project donated
        uint projectRemain;                     //save amount that is needed to reach goal amount
        

    }
    project[] Projects;                         //declare struct in array

    struct transactions{                        //struct for transaction's info 
        uint transactionID;                     //unique number for a transaction
        uint projectID;                         //unique number for project index
        address receiver;                       //save who is getting the amount
        address sender;                         //save who donated the project
        uint amount;                            //save how much was the donate
        uint transcount;                        //count how many times this project donated 
    }

    transactions[] Transactions;                //declare struct in array

    function insertProjects(string memory _projectTitle , string memory _projectDescription, uint _projectFundingAmount) public {            //add project function
        projectsize = Projects.length++;                                                    //increase project count
        projectid_increment++;                                                              //auto increase the id
        Projects[Projects.length - 1].projectID = projectid_increment;                      //insert id
        Projects[Projects.length - 1].projectTitle = _projectTitle;                         //insert title
        Projects[Projects.length - 1].projectDescription = _projectDescription;             //insert description
        Projects[Projects.length - 1].projectFundingAmount = _projectFundingAmount;         //insert goal amount
        Projects[Projects.length - 1].projectOwner = msg.sender;                            //insert the owners address(creator)
        Projects[Projects.length - 1].projectRemain = _projectFundingAmount;                //the remaining amount eq goal amount in start
    }
    

    function writeTransactions(uint _projectID , address  _receiver, address _sender, uint _amount, uint _transcount) private {            //write transaction function
        transize = Transactions.length++;                                                   //increase transaction count
        transid_increment++;                                                                //auto increase the id
        Transactions[Transactions.length - 1].transactionID = transid_increment;            //insert id
        Transactions[Transactions.length - 1].projectID = _projectID;                       //insert project's id
        Transactions[Transactions.length - 1].receiver = _receiver;                         //insert who is receiving the amount
        Transactions[Transactions.length - 1].sender = _sender;                             //insert who donated
        Transactions[Transactions.length - 1].amount = _amount;                             //insert how much donated
        Transactions[Transactions.length - 1].transcount = _transcount;                     //insert how many times this project donated
    }
    
    function showTransaction(uint projectindex) public view returns(uint _transactionID, uint _projectID, address _receiver,
                                                                                    address _sender, uint _amount, uint _projectran) {    //get transaction's info function
        for (uint i = 0; i <= transize; i++){                                                                                             // check all rows
            if(projectindex == Transactions[i].projectID){                                                                                //target the transactions of a specific project 
                return (Transactions[i].transactionID, Transactions[i].projectID, Transactions[i].receiver,
                        Transactions[i].sender, Transactions[i].amount, Transactions[i].transcount);                                    //print transaction's info
            }
        }
    }

    function showProject(uint index) public view returns(uint _projectID, string memory _projectTitle, string memory _projectDescription,
                                                         uint _projectFundingAmount, address _projectOwner, uint _projectFunding,
                                                         bool _completed, uint _transcount, uint _projectRemain, uint _projectsize) { //get project's info function
        for (uint i = 0; i <= projectsize; i++){                                                                                      // check all rows
            if(index == Projects[i].projectID){                                                                                       //target the project's id
                return (Projects[i].projectID, Projects[i].projectTitle, Projects[i].projectDescription, 
                        Projects[i].projectFundingAmount, Projects[i].projectOwner, Projects[i].projectFunding,
                        Projects[i].completed, Projects[i].transcount, Projects[i].projectRemain, projectsize);                       //print project's info
            }
        }
    }

    function funding(uint index) public payable  {                                                                                      //donate function
        for (uint i = 0; i <= projectsize; i++){                                                                                        // check all rows   
            if(index == Projects[i].projectID){                                                                                         //target the project's id we want to donate
                if(Projects[i].completed == false){                                                                                     //check if project has not reached the goal
                    require(msg.value <= Projects[i].projectRemain, 'Please donate lower of the remaining amount');                     //projects must not get donated more than the goal
                    Projects[i].projectOwner.transfer(msg.value);                                                                       //transfer the amount value to the project's owner address
                    Projects[i].projectFunding += msg.value;                                                                            //insert how much the project donated
                    Projects[i].transcount ++;                                                                                          //increase how many times the project donated
                    Projects[i].projectRemain = Projects[i].projectFundingAmount - Projects[i].projectFunding;                          //calculate the remaing amount to reach  the goal  
                    writeTransactions(Projects[i].projectID, Projects[i].projectOwner, msg.sender, msg.value, Projects[i].transcount);  //call writeTransactions function to save transactions info 
                }if(Projects[i].projectRemain  == 0){                                                                                   //if the goal amount reached write it down
                        Projects[i].completed = true;        
                }              
            }
        }       
    }
}