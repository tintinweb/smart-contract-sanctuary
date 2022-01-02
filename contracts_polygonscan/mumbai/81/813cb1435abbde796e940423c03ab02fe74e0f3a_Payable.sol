/**
 *Submitted for verification at polygonscan.com on 2022-01-01
*/

pragma solidity ^0.8.11;


contract Payable
{
    struct VerificationData
    {
        address UserAddress;

        string UserID;

    }

    struct Goal
    {

        uint Id;

        string Titles;
        string Body;
        bool Important;



        bool IsDonate;
        string DonateValue;
        address PublicAddress;

        uint StageImplementation;

        address User;

    }

    function toString(uint256 x)internal pure returns (string memory)
    {
        if (x == 0)
        {
            return "0";
        }
        uint256 j = x;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = x;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

    function toString(bool x) internal pure returns (string memory)
    {
        if(x==true)
        {
            return "true";
        }
        else
        {
            return "false";
        }
    }

    function toString(address x) internal pure returns (string memory) 
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) 
        {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) 
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    
    
    address payable owner;
    uint public price;
    VerificationData[] VerificationUserId;
    Goal[] Goals;



    constructor(uint verificationCost) payable
    {
        owner = payable(msg.sender);

        price = verificationCost;
    }

    function OwnerVerification(uint goalId,address sender) internal 
    { 
     

        if(goalId<=Goals.length)
        {
            if(Goals[goalId-1].User!=sender)
            {
                require(false, "Sender not owner");
            }
            

        }
        else
        {

            require(false, "Goal not found");
        }
    
    }


    function AddVerifyProfile(string memory UserID) public payable
    {

        require (msg.value >= price,"insufficient funds");
        require (bytes(UserID).length == 36,"invalid id");


        VerificationData memory newVerificationData = VerificationData(payable(msg.sender),UserID);
        VerificationUserId.push(newVerificationData);

    }

    function allVerificationUser() external view returns(string memory)
    {
        string memory allJsonIDstring;
        for (uint i = 0; i < VerificationUserId.length; i++)
        {
            string memory Addressw=toString(VerificationUserId[i].UserAddress);
            

            string memory userAddressJson=string(abi.encodePacked("{\"VerificationAddress\":\"",Addressw,"\","));

            string memory userIDJson=string(abi.encodePacked("\"VerificationUser\":\"",VerificationUserId[i].UserID,"\"}\n\r")); 
        
        
            string memory json=string(abi.encodePacked(userAddressJson,userIDJson));
           
                                
            allJsonIDstring=string(abi.encodePacked(allJsonIDstring,json));
        }
        
        


        return allJsonIDstring;
    }
    
 

    function AddDonateGoal
    (
        string memory Titles,
        string memory Body,
        bool Important,
        bool IsDonate,
        string memory DonateValue,
        address PublicAddress,
        uint StageImplementation
    ) public payable
    {
        address User = payable(msg.sender);
        uint Id=Goals.length+1;
        Goal memory NewGoal = Goal(Id,Titles,Body,Important,IsDonate,DonateValue,PublicAddress,StageImplementation,User);
        Goals.push(NewGoal);
    }

    function allGoals() external view returns(string memory)
    {
        string memory allJsonGoals;
        
        for (uint i = 0; i < Goals.length; i++)
        {
            string memory openJson="{";

            string memory IdJson=string(abi.encodePacked("\"Id\":",toString(Goals[i].Id),","));
            string memory TitlesJson=string(abi.encodePacked("\"Titles\":\"",Goals[i].Titles,"\","));
            string memory BodyJson=string(abi.encodePacked("\"Body\":\"",Goals[i].Body,"\","));
            string memory ImportantJson=string(abi.encodePacked("\"Important\":",toString(Goals[i].Important),","));
            string memory IsDonateJson=string(abi.encodePacked("\"IsDonate\":",toString(Goals[i].IsDonate),","));
            string memory DonateValueJson=string(abi.encodePacked("\"DonateValue\":\"",Goals[i].DonateValue,"\","));
            string memory PublicAddressJson=string(abi.encodePacked("\"PublicAddress\":\"",toString(Goals[i].PublicAddress),"\","));
            string memory StageImplementationJson=string(abi.encodePacked("\"StageImplementation\":",toString(Goals[i].StageImplementation),","));
            string memory UserJson=string(abi.encodePacked("\"User\":\"",toString(Goals[i].User),"\""));


            string memory closeJson="}\n\r";
            
            allJsonGoals=string(abi.encodePacked(allJsonGoals, 
                                                openJson,
                                                IdJson,
                                                TitlesJson,
                                                BodyJson,
                                                ImportantJson,
                                                IsDonateJson,
                                                DonateValueJson,
                                                PublicAddressJson,
                                                StageImplementationJson,
                                                UserJson,
                                                closeJson));
        }
       


        return allJsonGoals;
    }

    function DoImportant(uint goalId,bool important) public payable
    {
        address sender_=payable(msg.sender);
        
        OwnerVerification(goalId,sender_);
        
        Goals[goalId-1].Important=important;
      
    }

    function ChangeGoalStatus(uint goalId,uint status) public payable
    {
        address sender_=payable(msg.sender);
        
        OwnerVerification(goalId,sender_);
        require(status<3,"Eror");
        Goals[goalId-1].StageImplementation=status;
      
    }

    function withdraw() public
    {
        if(msg.sender == owner)
        {
            uint amount = address(this).balance;

            (bool success,) = owner.call{value: amount}("");
            require(success, "Failed to send Ether");

        }
        else
        {
            require(false, "Not owner");
        }
    }



}